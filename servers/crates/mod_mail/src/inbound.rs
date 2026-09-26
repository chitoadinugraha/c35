use hmac::{Hmac, Mac};
use serde::Deserialize;
use sha2::Sha256;

type HmacSha256 = Hmac<Sha256>;

#[derive(Debug, Deserialize)]
pub struct MailInboundAttachment {
    pub name: Option<String>,
    pub mime: Option<String>,
    pub data: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct MailInboundPayload {
    pub from: Option<String>,
    pub to: Option<String>,
    pub subject: Option<String>,
    pub text: Option<String>,
    pub html: Option<String>,
    #[serde(rename = "message_id")]
    pub external_id: Option<String>,
    #[serde(default)]
    pub attachments: Option<Vec<MailInboundAttachment>>,
}

pub fn verify_inbound_signature(secret: &str, body: &[u8], signature_header: &str) -> bool {
    let secret = secret.trim();
    if secret.is_empty() { return false; }
    let sig = signature_header.trim();
    let expected = sig.strip_prefix("sha256=").or_else(|| sig.strip_prefix("SHA256=")).unwrap_or(sig);
    let Ok(mut mac) = HmacSha256::new_from_slice(secret.as_bytes()) else { return false; };
    mac.update(body);
    constant_time_eq(expected.as_bytes(), hex::encode(mac.finalize().into_bytes()).as_bytes())
}

pub async fn inbound_webhook(
    pool: &sqlx::PgPool,
    cas: Option<crate::attachments::MailCas>,
    body: Vec<u8>,
    authorization: Option<&str>,
    signature: Option<&str>,
) -> Result<i64, String> {
    let secret = std::env::var("MAIL_INBOUND_SECRET").map_err(|_| "MAIL_INBOUND_SECRET not configured".to_string())?;
    if !auth_ok(&secret, &body, authorization, signature)? { return Err("unauthorized: invalid signature".into()); }
    let payload: MailInboundPayload = serde_json::from_slice(&body).map_err(|e| format!("invalid json: {e}"))?;
    crate::service::MailService::new(pool.clone(), cas).inbound(payload).await
}

fn auth_ok(secret: &str, body: &[u8], authorization: Option<&str>, signature: Option<&str>) -> Result<bool, String> {
    if secret.trim().is_empty() { return Ok(false); }
    if let Some(auth) = authorization {
        if let Some(token) = auth.trim().strip_prefix("Bearer ") {
            if constant_time_eq(token.trim().as_bytes(), secret.trim().as_bytes()) { return Ok(true); }
        }
    }
    if let Some(sig) = signature {
        if verify_inbound_signature(secret, body, sig) { return Ok(true); }
    }
    Ok(false)
}

fn constant_time_eq(a: &[u8], b: &[u8]) -> bool {
    a.len() == b.len() && a.iter().zip(b.iter()).fold(0u8, |acc, (x, y)| acc | (x ^ y)) == 0
}
