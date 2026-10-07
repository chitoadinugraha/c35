use std::sync::OnceLock;
use std::time::{Duration, Instant};

use c35_mod_billing::BillingRow;
use dashmap::DashMap;
use serde::{Deserialize, Serialize};
use sqlx::PgPool;

use crate::catalog::LiveOfferRow;

#[derive(Clone)]
pub struct LiveSessionTicket {
    pub owner_iid: i64,
    pub token: String,
    pub offer: LiveOfferRow,
    pub req_id: String,
    pub billing_row: BillingRow,
    pub chat_id: Option<i64>,
    pub mention_ids: Vec<String>,
    pub created: Instant,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LiveTicketClaims {
    pub sid: String,
    pub owner_iid: i64,
    pub offer_id: String,
    pub req_id: String,
    pub chat_id: Option<i64>,
    pub mention_ids: Vec<String>,
    pub exp: i64,
}

fn sessions() -> &'static DashMap<String, LiveSessionTicket> {
    static LIVE_SESSIONS: OnceLock<DashMap<String, LiveSessionTicket>> = OnceLock::new();
    LIVE_SESSIONS.get_or_init(DashMap::new)
}

const LIVE_TICKET_TTL: Duration = Duration::from_secs(600);

pub fn live_ticket_secret() -> Vec<u8> {
    for key in ["C35_JWT_SECRET", "CAS_HMAC_SECRET", "AGENT_SECRET_KEY"] {
        if let Ok(v) = std::env::var(key) {
            let t = v.trim();
            if !t.is_empty() {
                return t.as_bytes().to_vec();
            }
        }
    }
    b"c35-live-ticket-dev-secret".to_vec()
}

pub fn live_ticket_sign(claims: &LiveTicketClaims) -> String {
    use base64::Engine as _;
    let payload = serde_json::to_vec(claims).unwrap_or_default();
    let p_b64 = base64::engine::general_purpose::URL_SAFE_NO_PAD.encode(&payload);
    let key = *blake3::hash(&live_ticket_secret()).as_bytes();
    let mac = blake3::keyed_hash(&key, p_b64.as_bytes());
    let sig_b64 = base64::engine::general_purpose::URL_SAFE_NO_PAD.encode(mac.as_bytes());
    format!("{p_b64}.{sig_b64}")
}

pub fn live_ticket_verify(token: &str) -> Option<LiveTicketClaims> {
    use base64::Engine as _;
    let (p_b64, sig_b64) = token.split_once('.')?;
    let key = *blake3::hash(&live_ticket_secret()).as_bytes();
    let expected_mac = blake3::keyed_hash(&key, p_b64.as_bytes());
    let sig_bytes = base64::engine::general_purpose::URL_SAFE_NO_PAD.decode(sig_b64).ok()?;
    if sig_bytes.as_slice() != expected_mac.as_bytes() {
        return None;
    }
    let payload = base64::engine::general_purpose::URL_SAFE_NO_PAD.decode(p_b64).ok()?;
    let claims: LiveTicketClaims = serde_json::from_slice(&payload).ok()?;
    if claims.exp < chrono::Utc::now().timestamp() {
        return None;
    }
    Some(claims)
}

pub fn live_session_register(
    sid: &str,
    owner_iid: i64,
    offer: LiveOfferRow,
    req_id: String,
    billing_row: BillingRow,
    chat_id: Option<i64>,
    mention_ids: Vec<String>,
) -> String {
    let exp = chrono::Utc::now().timestamp() + 600;
    let claims = LiveTicketClaims {
        sid: sid.to_string(),
        owner_iid,
        offer_id: offer.id.clone(),
        req_id: req_id.clone(),
        chat_id,
        mention_ids: mention_ids.clone(),
        exp,
    };
    let token = live_ticket_sign(&claims);
    sessions().insert(
        sid.to_string(),
        LiveSessionTicket {
            owner_iid,
            token: token.clone(),
            offer,
            req_id,
            billing_row,
            chat_id,
            mention_ids,
            created: Instant::now(),
        },
    );
    token
}

pub async fn live_session_take(
    pool: &PgPool,
    sid: &str,
    token: &str,
    owner_iid: i64,
) -> Option<LiveSessionTicket> {
    let sid = sid.trim();
    let token = token.trim();
    if sid.is_empty() || token.is_empty() {
        return None;
    }
    // 1. Fast in-memory path (same pod)
    if let Some((_, row)) = sessions().remove(sid) {
        if row.owner_iid == owner_iid && (row.token == token || row.token.starts_with(token) || token.starts_with(&row.token)) {
            if row.created.elapsed() <= LIVE_TICKET_TTL {
                return Some(row);
            }
        }
    }
    // 2. Stateless cross-pod verification
    let claims = live_ticket_verify(token)?;
    if claims.sid != sid || claims.owner_iid != owner_iid {
        return None;
    }

    // Verify billing reservation status in DB to ensure it was legitimately held and not yet settled/aborted
    let res_status: Option<(String,)> = sqlx::query_as(
        "SELECT status FROM ai.billing_reservation WHERE req_id = $1 AND owner_iid = $2",
    )
    .bind(&claims.req_id)
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();

    let Some((status,)) = res_status else {
        return None;
    };
    if status != "held" {
        return None;
    }

    let offer = crate::catalog::live_offer_resolve(pool, &claims.offer_id).await?;
    let billing_row = c35_mod_billing::billing_account_ensure(pool, owner_iid).await.ok()?;

    Some(LiveSessionTicket {
        owner_iid,
        token: token.to_string(),
        offer,
        req_id: claims.req_id,
        billing_row,
        chat_id: claims.chat_id,
        mention_ids: claims.mention_ids,
        created: Instant::now(),
    })
}

pub fn live_session_drop(sid: &str) {
    sessions().remove(sid.trim());
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_live_ticket_sign_and_verify() {
        let claims = LiveTicketClaims {
            sid: "test-sid-123".into(),
            owner_iid: 99000,
            offer_id: "live.alienai".into(),
            req_id: "live-test-sid-123".into(),
            chat_id: Some(42),
            mention_ids: vec!["dev-1".into()],
            exp: chrono::Utc::now().timestamp() + 300,
        };
        let token = live_ticket_sign(&claims);
        assert!(!token.is_empty());
        assert!(token.contains('.'));

        let verified = live_ticket_verify(&token).expect("verification should succeed");
        assert_eq!(verified.sid, "test-sid-123");
        assert_eq!(verified.owner_iid, 99000);
        assert_eq!(verified.offer_id, "live.alienai");
        assert_eq!(verified.req_id, "live-test-sid-123");
        assert_eq!(verified.chat_id, Some(42));
        assert_eq!(verified.mention_ids, vec!["dev-1"]);
    }

    #[test]
    fn test_live_ticket_tamper_rejected() {
        let claims = LiveTicketClaims {
            sid: "test-sid-123".into(),
            owner_iid: 99000,
            offer_id: "live.alienai".into(),
            req_id: "live-test-sid-123".into(),
            chat_id: None,
            mention_ids: vec![],
            exp: chrono::Utc::now().timestamp() + 300,
        };
        let mut token = live_ticket_sign(&claims);
        token.push('x');
        assert!(live_ticket_verify(&token).is_none());
    }

    #[test]
    fn test_live_ticket_expired_rejected() {
        let claims = LiveTicketClaims {
            sid: "test-sid-123".into(),
            owner_iid: 99000,
            offer_id: "live.alienai".into(),
            req_id: "live-test-sid-123".into(),
            chat_id: None,
            mention_ids: vec![],
            exp: chrono::Utc::now().timestamp() - 10,
        };
        let token = live_ticket_sign(&claims);
        assert!(live_ticket_verify(&token).is_none());
    }
}
