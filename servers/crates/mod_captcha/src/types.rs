use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum CaptchaKind {
    RecaptchaV2,
    RecaptchaV3,
    Hcaptcha,
    Image,
}

impl CaptchaKind {
    pub fn parse(s: &str) -> Option<Self> {
        match s.trim().to_ascii_lowercase().as_str() {
            "recaptcha_v2" | "recaptcha2" | "browser" | "userrecaptcha" => {
                Some(CaptchaKind::RecaptchaV2)
            }
            "recaptcha_v3" | "recaptcha3" | "userrecaptchav3" => Some(CaptchaKind::RecaptchaV3),
            "hcaptcha" => Some(CaptchaKind::Hcaptcha),
            "image" | "base64" => Some(CaptchaKind::Image),
            _ => None,
        }
    }

    pub fn twocaptcha_method(self) -> &'static str {
        match self {
            CaptchaKind::RecaptchaV2 => "userrecaptcha",
            CaptchaKind::RecaptchaV3 => "userrecaptchav3",
            CaptchaKind::Hcaptcha => "hcaptcha",
            CaptchaKind::Image => "base64",
        }
    }

    pub fn billing_kind_key(self) -> &'static str {
        match self {
            CaptchaKind::RecaptchaV2 => "recaptcha_v2",
            CaptchaKind::RecaptchaV3 => "recaptcha_v3",
            CaptchaKind::Hcaptcha => "hcaptcha",
            CaptchaKind::Image => "image",
        }
    }
}

#[derive(Debug, Clone)]
pub struct SolveRequest {
    pub kind: CaptchaKind,
    pub sitekey: String,
    pub page_url: String,
    pub image_b64: Option<String>,
    pub action: Option<String>,
    pub min_score: Option<f64>,
    pub proxy: Option<String>,
    pub proxy_type: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
pub struct SolveResult {
    pub token: String,
    pub task_id: String,
    pub kind: String,
    pub wholesale_usd: f64,
}

#[derive(Debug, Clone)]
pub enum CaptchaSolveError {
    NotConfigured,
    SubmitFailed(String),
    PollFailed(String),
    Timeout,
    ProviderError(String),
}

impl CaptchaSolveError {
    pub fn code(&self) -> &'static str {
        match self {
            CaptchaSolveError::NotConfigured => "not_configured",
            CaptchaSolveError::SubmitFailed(_) => "submit_failed",
            CaptchaSolveError::PollFailed(_) => "poll_failed",
            CaptchaSolveError::Timeout => "timeout",
            CaptchaSolveError::ProviderError(_) => "provider_error",
        }
    }

    pub fn message(&self) -> String {
        match self {
            CaptchaSolveError::NotConfigured => {
                "Captcha solver is not configured on the server".into()
            }
            CaptchaSolveError::SubmitFailed(m) => m.clone(),
            CaptchaSolveError::PollFailed(m) => m.clone(),
            CaptchaSolveError::Timeout => "Captcha solve timed out".into(),
            CaptchaSolveError::ProviderError(m) => m.clone(),
        }
    }
}
