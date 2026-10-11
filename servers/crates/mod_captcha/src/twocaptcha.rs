use std::time::Duration;

use reqwest::Client;
use tokio::time::sleep;
use tracing::debug;

use crate::billing::captcha_wholesale_usd;
use crate::types::{CaptchaKind, CaptchaSolveError, SolveRequest, SolveResult};

const DEFAULT_IN_URL: &str = "https://2captcha.com/in.php";
const DEFAULT_RES_URL: &str = "https://2captcha.com/res.php";
const POLL_INTERVAL: Duration = Duration::from_secs(5);
const MAX_WAIT: Duration = Duration::from_secs(120);

#[derive(Debug, Clone)]
pub struct TwoCaptchaConfig {
    pub api_key: String,
    pub in_url: String,
    pub res_url: String,
}

impl TwoCaptchaConfig {
    pub fn from_env() -> Option<Self> {
        let key = std::env::var("C35_2CAPTCHA_API_KEY")
            .ok()
            .map(|s| s.trim().to_string())
            .filter(|s| !s.is_empty())?;
        Some(Self {
            api_key: key,
            in_url: std::env::var("C35_2CAPTCHA_IN_URL")
                .ok()
                .filter(|s| !s.trim().is_empty())
                .unwrap_or_else(|| DEFAULT_IN_URL.to_string()),
            res_url: std::env::var("C35_2CAPTCHA_RES_URL")
                .ok()
                .filter(|s| !s.trim().is_empty())
                .unwrap_or_else(|| DEFAULT_RES_URL.to_string()),
        })
    }
}

pub struct TwoCaptchaClient {
    cfg: TwoCaptchaConfig,
    http: Client,
}

impl TwoCaptchaClient {
    pub fn new(cfg: TwoCaptchaConfig) -> Self {
        Self {
            cfg,
            http: Client::builder()
                .timeout(Duration::from_secs(30))
                .build()
                .unwrap_or_default(),
        }
    }

    pub fn from_env() -> Option<Self> {
        TwoCaptchaConfig::from_env().map(Self::new)
    }

    pub async fn solve(&self, req: SolveRequest) -> Result<SolveResult, CaptchaSolveError> {
        self.validate_request(&req)?;
        let task_id = self.submit(&req).await?;
        let token = self.poll_result(&task_id).await?;
        Ok(SolveResult {
            token,
            task_id,
            kind: req.kind.billing_kind_key().to_string(),
            wholesale_usd: captcha_wholesale_usd(req.kind),
        })
    }

    fn validate_request(&self, req: &SolveRequest) -> Result<(), CaptchaSolveError> {
        match req.kind {
            CaptchaKind::Image => {
                if req.image_b64.as_ref().map(|s| s.trim().is_empty()).unwrap_or(true) {
                    return Err(CaptchaSolveError::SubmitFailed(
                        "image_b64 required for image captcha".into(),
                    ));
                }
            }
            _ => {
                if req.sitekey.trim().is_empty() {
                    return Err(CaptchaSolveError::SubmitFailed("sitekey required".into()));
                }
                if req.page_url.trim().is_empty() {
                    return Err(CaptchaSolveError::SubmitFailed("page_url required".into()));
                }
            }
        }
        Ok(())
    }

    async fn submit(&self, req: &SolveRequest) -> Result<String, CaptchaSolveError> {
        let mut params: Vec<(&str, String)> = vec![
            ("key", self.cfg.api_key.clone()),
            ("json", "1".into()),
            ("method", req.kind.twocaptcha_method().into()),
        ];
        match req.kind {
            CaptchaKind::Image => {
                params.push(("body", req.image_b64.clone().unwrap_or_default()));
            }
            CaptchaKind::RecaptchaV3 => {
                params.push(("googlekey", req.sitekey.clone()));
                params.push(("pageurl", req.page_url.clone()));
                params.push((
                    "action",
                    req.action.clone().unwrap_or_else(|| "verify".into()),
                ));
                if let Some(score) = req.min_score {
                    params.push(("min_score", score.to_string()));
                }
            }
            CaptchaKind::RecaptchaV2 | CaptchaKind::Hcaptcha => {
                params.push(("googlekey", req.sitekey.clone()));
                params.push(("pageurl", req.page_url.clone()));
            }
        }
        if let Some(proxy) = &req.proxy {
            if !proxy.trim().is_empty() {
                params.push(("proxy", proxy.clone()));
                params.push((
                    "proxytype",
                    req.proxy_type
                        .clone()
                        .unwrap_or_else(|| "HTTPS".into()),
                ));
            }
        }

        let resp = self
            .http
            .post(&self.cfg.in_url)
            .form(&params)
            .send()
            .await
            .map_err(|e| CaptchaSolveError::SubmitFailed(e.to_string()))?;
        let body: serde_json::Value = resp
            .json()
            .await
            .map_err(|e| CaptchaSolveError::SubmitFailed(e.to_string()))?;
        parse_submit_json(body)
    }

    async fn poll_result(&self, task_id: &str) -> Result<String, CaptchaSolveError> {
        let started = std::time::Instant::now();
        while started.elapsed() < MAX_WAIT {
            let resp = self
                .http
                .get(&self.cfg.res_url)
                .query(&[
                    ("key", self.cfg.api_key.as_str()),
                    ("action", "get"),
                    ("id", task_id),
                    ("json", "1"),
                ])
                .send()
                .await
                .map_err(|e| CaptchaSolveError::PollFailed(e.to_string()))?;
            let body: serde_json::Value = resp
                .json()
                .await
                .map_err(|e| CaptchaSolveError::PollFailed(e.to_string()))?;
            match parse_poll_json(body) {
                Ok(Some(token)) => return Ok(token),
                Ok(None) => {
                    debug!(task_id, "captcha not ready, polling");
                    sleep(POLL_INTERVAL).await;
                }
                Err(e) => return Err(e),
            }
        }
        Err(CaptchaSolveError::Timeout)
    }
}

fn parse_submit_json(body: serde_json::Value) -> Result<String, CaptchaSolveError> {
    if body.get("status").and_then(|v| v.as_i64()) == Some(1) {
        let id = body
            .get("request")
            .and_then(|v| v.as_str())
            .ok_or_else(|| CaptchaSolveError::SubmitFailed("missing task id".into()))?;
        return Ok(id.to_string());
    }
    let err = body
        .get("request")
        .and_then(|v| v.as_str())
        .unwrap_or("submit failed");
    Err(CaptchaSolveError::ProviderError(err.to_string()))
}

fn parse_poll_json(body: serde_json::Value) -> Result<Option<String>, CaptchaSolveError> {
    if body.get("status").and_then(|v| v.as_i64()) == Some(1) {
        let token = body
            .get("request")
            .and_then(|v| v.as_str())
            .ok_or_else(|| CaptchaSolveError::PollFailed("missing solution".into()))?;
        return Ok(Some(token.to_string()));
    }
    let req = body
        .get("request")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    if req.eq_ignore_ascii_case("CAPCHA_NOT_READY") || req.contains("NOT_READY") {
        return Ok(None);
    }
    Err(CaptchaSolveError::ProviderError(req.to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_submit_ok() {
        let id = parse_submit_json(serde_json::json!({ "status": 1, "request": "99" })).unwrap();
        assert_eq!(id, "99");
    }

    #[test]
    fn parse_poll_not_ready() {
        assert!(
            parse_poll_json(serde_json::json!({ "status": 0, "request": "CAPCHA_NOT_READY" }))
                .unwrap()
                .is_none()
        );
    }

    #[test]
    fn parse_poll_solution() {
        let tok = parse_poll_json(serde_json::json!({ "status": 1, "request": "token123" }))
            .unwrap()
            .unwrap();
        assert_eq!(tok, "token123");
    }
}
