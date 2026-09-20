use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};

use c35_wire::{WireErr, WireResult};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionJwtClaims {
    pub sub: String,
    pub name: String,
    #[serde(rename = "handle")]
    pub handle: String,
    pub pic: String,
    pub exp: i64,
    pub iat: i64,
    pub jti: String,
}

impl SessionJwtClaims {
    pub fn iid(&self) -> Option<i64> {
        self.sub.parse().ok()
    }
}

pub fn jwt_looks_like(token: &str) -> bool {
    let t = token.trim();
    t.matches('.').count() == 2 && !t.is_empty()
}

fn jwt_secrets() -> Vec<Vec<u8>> {
    let mut out = Vec::new();
    for key in ["C35_JWT_SECRET", "AGENT_SECRET_KEY", "CAS_HMAC_SECRET"] {
        if let Ok(v) = std::env::var(key) {
            let t = v.trim();
            if !t.is_empty() && !out.iter().any(|b| b == t.as_bytes()) {
                out.push(t.as_bytes().to_vec());
            }
        }
    }
    if let Ok(extra) = std::env::var("C35_JWT_SECRETS").or_else(|_| std::env::var("AGENT_JWT_SECRETS")) {
        for part in extra.split(',') {
            let t = part.trim();
            if !t.is_empty() && !out.iter().any(|b| b == t.as_bytes()) {
                out.push(t.as_bytes().to_vec());
            }
        }
    }
    if out.is_empty() {
        out.push(b"dev-change-me".to_vec());
    }
    out
}

fn jwt_secret() -> Vec<u8> {
    jwt_secrets()
        .into_iter()
        .find(|s| s.as_slice() != b"dev-change-me" && s.as_slice() != b"dev-agent-secret")
        .unwrap_or_else(|| b"dev-change-me".to_vec())
}

pub fn jwt_issue(iid: i64, name: &str, handle: &str, pic: &str, jti: i64) -> Result<String, WireErr> {
    let now = chrono::Utc::now();
    let claims = SessionJwtClaims {
        sub: iid.to_string(),
        name: name.to_string(),
        handle: handle.to_string(),
        pic: pic.to_string(),
        iat: now.timestamp(),
        exp: (now + chrono::Duration::days(30)).timestamp(),
        jti: jti.to_string(),
    };
    encode(
        &Header::new(Algorithm::HS256),
        &claims,
        &EncodingKey::from_secret(&jwt_secret()),
    )
    .map_err(|e| WireErr::Internal(e.to_string()))
}

pub fn jwt_verify(token: &str) -> WireResult<Option<SessionJwtClaims>> {
    if !jwt_looks_like(token) {
        return Ok(None);
    }
    let mut validation = Validation::new(Algorithm::HS256);
    validation.validate_exp = true;
    for secret in jwt_secrets() {
        match decode::<SessionJwtClaims>(
            token.trim(),
            &DecodingKey::from_secret(&secret),
            &validation,
        ) {
            Ok(data) => return Ok(Some(data.claims)),
            Err(e) => match e.kind() {
                jsonwebtoken::errors::ErrorKind::ExpiredSignature => return Ok(None),
                jsonwebtoken::errors::ErrorKind::InvalidToken
                | jsonwebtoken::errors::ErrorKind::InvalidSignature => {}
                _ => return Err(WireErr::Internal(e.to_string())),
            },
        }
    }
    Ok(None)
}

pub fn jwt_decode(token: &str, _secret: &str) -> WireResult<SessionJwtClaims> {
    jwt_verify(token)?.ok_or(WireErr::Unauthorized)
}

pub fn jwt_caller_iid(claims: &SessionJwtClaims) -> WireResult<i64> {
    claims.iid().filter(|&id| id > 0).ok_or(WireErr::Unauthorized)
}
