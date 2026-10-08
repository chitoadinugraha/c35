//! FCM HTTP v1 data-only sender — JWT service account, no Admin SDK.
//!
//! Credentials: `FIREBASE_SERVICE_ACCOUNT_PATH`, else `GOOGLE_APPLICATION_CREDENTIALS_JSON`.
//! When neither is usable, [`Fcm::enabled`] is false and [`Fcm::send_data`] returns `Ok`
//! after logging once. There is no iOS VoIP / PushKit path.

use std::collections::HashMap;
use std::sync::{Arc, Once};
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use jsonwebtoken::{encode, Algorithm, EncodingKey, Header};
use serde::{Deserialize, Serialize};
use tokio::sync::Mutex;

const SCOPE: &str = "https://www.googleapis.com/auth/firebase.messaging";
const TOKEN_URL: &str = "https://oauth2.googleapis.com/token";

static DISABLED_LOG: Once = Once::new();

#[derive(Clone)]
pub struct Fcm {
    inner: Option<Arc<FcmInner>>,
}

struct FcmInner {
    project: String,
    client_email: String,
    encoding_key: EncodingKey,
    http: reqwest::Client,
    access: Mutex<CachedToken>,
}

struct CachedToken {
    value: String,
    expires_at: Instant,
}

#[derive(Deserialize)]
struct ServiceAccount {
    project_id: String,
    client_email: String,
    private_key: String,
}

#[derive(Serialize)]
struct JwtClaims<'a> {
    iss: &'a str,
    scope: &'a str,
    aud: &'a str,
    iat: u64,
    exp: u64,
}

#[derive(Deserialize)]
struct TokenResponse {
    access_token: String,
    expires_in: u64,
}

#[derive(Serialize)]
struct V1Req<'a> {
    message: V1Message<'a>,
}

#[derive(Serialize)]
struct V1Message<'a> {
    token: &'a str,
    data: &'a HashMap<String, String>,
    android: V1Android,
}

#[derive(Serialize)]
struct V1Android {
    priority: &'static str,
}

impl Fcm {
    /// Sender that never calls Google.
    pub fn disabled() -> Self {
        Self { inner: None }
    }

    /// Load a service account from the environment. Missing or invalid credentials
    /// yield a disabled sender.
    pub fn from_env() -> Self {
        match load_service_account_from_env() {
            Some(sa) => match Self::from_account(sa) {
                Ok(fcm) => fcm,
                Err(e) => {
                    tracing::warn!("[fcm] service account not loaded: {e}");
                    Self::disabled()
                }
            },
            None => Self::disabled(),
        }
    }

    pub fn enabled(&self) -> bool {
        self.inner.is_some()
    }

    /// Data-only FCM HTTP v1 send. `type` is always `user_notify`.
    /// Android priority is `high`. No notification block.
    pub async fn send_data(
        &self,
        tokens: &[String],
        data: HashMap<String, String>,
    ) -> Result<(), String> {
        let Some(inner) = self.inner.clone() else {
            DISABLED_LOG.call_once(|| {
                tracing::warn!("[fcm] credentials unavailable; send_data is a no-op");
            });
            return Ok(());
        };
        if tokens.is_empty() {
            return Ok(());
        }
        let payload = user_notify_data(data);
        let mut errors = Vec::new();
        for token in tokens {
            let tok = token.trim();
            if tok.is_empty() {
                continue;
            }
            if let Err(e) = inner.send_one(tok, &payload).await {
                tracing::warn!("[fcm] send: {e}");
                errors.push(e);
            }
        }
        if errors.is_empty() {
            Ok(())
        } else {
            Err(errors.join("; "))
        }
    }

    fn from_account(sa: ServiceAccount) -> Result<Self, String> {
        if sa.project_id.is_empty() || sa.client_email.is_empty() || sa.private_key.is_empty() {
            return Err("invalid service account json".into());
        }
        let encoding_key =
            EncodingKey::from_rsa_pem(sa.private_key.as_bytes()).map_err(|e| e.to_string())?;
        let http = reqwest::Client::builder()
            .timeout(Duration::from_secs(15))
            .build()
            .map_err(|e| e.to_string())?;
        tracing::info!("[fcm] sender ready project={}", sa.project_id);
        Ok(Self {
            inner: Some(Arc::new(FcmInner {
                project: sa.project_id,
                client_email: sa.client_email,
                encoding_key,
                http,
                access: Mutex::new(CachedToken {
                    value: String::new(),
                    expires_at: Instant::now(),
                }),
            })),
        })
    }
}

fn user_notify_data(mut data: HashMap<String, String>) -> HashMap<String, String> {
    data.insert("type".into(), "user_notify".into());
    data
}

fn message_body<'a>(token: &'a str, data: &'a HashMap<String, String>) -> V1Req<'a> {
    V1Req {
        message: V1Message {
            token,
            data,
            android: V1Android { priority: "high" },
        },
    }
}

/// Prefer the Firebase file path. Fall through to the shared Google JSON env
/// when the path is unset or unusable.
fn load_service_account_from_env() -> Option<ServiceAccount> {
    if let Some(sa) = service_account_from_firebase_path() {
        return Some(sa);
    }
    service_account_from_google_json()
}

fn service_account_from_firebase_path() -> Option<ServiceAccount> {
    let Ok(path) = std::env::var("FIREBASE_SERVICE_ACCOUNT_PATH") else {
        return None;
    };
    let path = path.trim();
    if path.is_empty() {
        return None;
    }
    let raw = match std::fs::read_to_string(path) {
        Ok(raw) => raw,
        Err(e) => {
            tracing::warn!("[fcm] FIREBASE_SERVICE_ACCOUNT_PATH unreadable ({path}): {e}");
            return None;
        }
    };
    match parse_service_account(&raw) {
        Ok(sa) => Some(sa),
        Err(e) => {
            tracing::warn!("[fcm] FIREBASE_SERVICE_ACCOUNT_PATH unusable ({path}): {e}");
            None
        }
    }
}

fn service_account_from_google_json() -> Option<ServiceAccount> {
    let Ok(json) = std::env::var("GOOGLE_APPLICATION_CREDENTIALS_JSON") else {
        return None;
    };
    if json.trim().is_empty() {
        return None;
    }
    match parse_service_account(&json) {
        Ok(sa) => Some(sa),
        Err(e) => {
            tracing::warn!("[fcm] GOOGLE_APPLICATION_CREDENTIALS_JSON unusable: {e}");
            None
        }
    }
}

fn parse_service_account(raw: &str) -> Result<ServiceAccount, String> {
    serde_json::from_str(raw).map_err(|e| e.to_string())
}

impl FcmInner {
    async fn access_token(&self) -> Result<String, String> {
        {
            let cached = self.access.lock().await;
            if !cached.value.is_empty() && Instant::now() < cached.expires_at {
                return Ok(cached.value.clone());
            }
        }
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        let claims = JwtClaims {
            iss: &self.client_email,
            scope: SCOPE,
            aud: TOKEN_URL,
            iat: now,
            exp: now + 3600,
        };
        let mut header = Header::new(Algorithm::RS256);
        header.typ = Some("JWT".into());
        let assertion = encode(&header, &claims, &self.encoding_key).map_err(|e| e.to_string())?;
        let res = self
            .http
            .post(TOKEN_URL)
            .form(&[
                ("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer"),
                ("assertion", assertion.as_str()),
            ])
            .send()
            .await
            .map_err(|e| e.to_string())?;
        if !res.status().is_success() {
            let status = res.status();
            let text = res.text().await.unwrap_or_default();
            return Err(format!("oauth {status} {text}"));
        }
        let tok: TokenResponse = res.json().await.map_err(|e| e.to_string())?;
        let ttl = tok.expires_in.saturating_sub(60).max(30);
        let mut cached = self.access.lock().await;
        cached.value = tok.access_token.clone();
        cached.expires_at = Instant::now() + Duration::from_secs(ttl);
        Ok(tok.access_token)
    }

    async fn send_one(&self, token: &str, data: &HashMap<String, String>) -> Result<(), String> {
        let bearer = self.access_token().await?;
        let url = format!(
            "https://fcm.googleapis.com/v1/projects/{}/messages:send",
            self.project
        );
        let res = self
            .http
            .post(&url)
            .bearer_auth(bearer)
            .json(&message_body(token, data))
            .send()
            .await
            .map_err(|e| e.to_string())?;
        if res.status().as_u16() >= 300 {
            let status = res.status();
            let text = res.text().await.unwrap_or_default();
            return Err(format!("status {status} {text}"));
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_data() -> HashMap<String, String> {
        let mut data = HashMap::new();
        data.insert("title".into(), "Done".into());
        data.insert("body".into(), "The turn finished".into());
        data.insert("notify_id".into(), "42".into());
        data.insert("route_json".into(), r#"{"chat_id":7}"#.into());
        data
    }

    #[tokio::test]
    async fn disabled_send_data_returns_ok_without_http() {
        let fcm = Fcm::disabled();
        assert!(!fcm.enabled());
        let result = fcm
            .send_data(&["token-should-not-be-sent".into()], sample_data())
            .await;
        assert!(result.is_ok());
    }

    #[test]
    fn data_message_omits_notification_and_sets_android_high() {
        let payload = user_notify_data(sample_data());
        let body = serde_json::to_value(message_body("tok", &payload)).expect("serialize");
        let message = &body["message"];
        assert!(message.get("notification").is_none());
        assert!(message.get("apns").is_none());
        assert_eq!(message["token"], "tok");
        assert_eq!(message["android"]["priority"], "high");
        assert_eq!(message["data"]["type"], "user_notify");
        assert_eq!(message["data"]["title"], "Done");
        assert_eq!(message["data"]["body"], "The turn finished");
        assert_eq!(message["data"]["notify_id"], "42");
        assert_eq!(message["data"]["route_json"], r#"{"chat_id":7}"#);
    }
}
