use std::sync::OnceLock;
use std::time::{Duration, Instant};

use c35_mod_billing::BillingRow;
use dashmap::DashMap;
use serde::{Deserialize, Serialize};
use sqlx::PgPool;

use c35_mod_chat::LiveOwnerHydrate;

use crate::catalog::LiveOfferRow;

#[derive(Clone, Debug)]
pub struct GuestLiveMeta {
    pub site_iid: i64,
    pub visitor_id: String,
    pub data_mode: String,
    pub guest_system_prompt: String,
}

#[derive(Clone)]
pub struct LiveSessionTicket {
    pub owner_iid: i64,
    pub token: String,
    pub offer: LiveOfferRow,
    pub req_id: String,
    pub billing_row: BillingRow,
    pub chat_id: Option<i64>,
    pub mention_ids: Vec<String>,
    pub hydrate: Option<LiveOwnerHydrate>,
    pub guest: Option<GuestLiveMeta>,
    pub created: Instant,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct LiveTicketClaims {
    pub sid: String,
    pub owner_iid: i64,
    pub offer_id: String,
    pub req_id: String,
    pub chat_id: Option<i64>,
    pub mention_ids: Vec<String>,
    pub exp: i64,
    #[serde(default)]
    pub scope: String,
    #[serde(default)]
    pub site_iid: Option<i64>,
    #[serde(default)]
    pub visitor_id: Option<String>,
    #[serde(default)]
    pub data_mode: Option<String>,
    #[serde(default)]
    pub guest_system_prompt: Option<String>,
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
    hydrate: Option<LiveOwnerHydrate>,
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
        scope: "app_live".to_string(),
        site_iid: None,
        visitor_id: None,
        data_mode: None,
        guest_system_prompt: None,
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
            hydrate,
            guest: None,
            created: Instant::now(),
        },
    );
    token
}

pub fn guest_live_session_register(
    sid: &str,
    owner_iid: i64,
    offer: LiveOfferRow,
    req_id: String,
    billing_row: BillingRow,
    site_iid: i64,
    visitor_id: String,
    data_mode: String,
    guest_system_prompt: String,
) -> (String, String) {
    let exp = chrono::Utc::now().timestamp() + 600;
    let prompt_snap = if guest_system_prompt.len() > 32_000 {
        guest_system_prompt.chars().take(32_000).collect::<String>()
    } else {
        guest_system_prompt.clone()
    };
    let claims = LiveTicketClaims {
        sid: sid.to_string(),
        owner_iid,
        offer_id: offer.id.clone(),
        req_id: req_id.clone(),
        chat_id: None,
        mention_ids: Vec::new(),
        exp,
        scope: "site_guest".to_string(),
        site_iid: Some(site_iid),
        visitor_id: Some(visitor_id.clone()),
        data_mode: Some(data_mode.clone()),
        guest_system_prompt: Some(prompt_snap),
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
            chat_id: None,
            mention_ids: Vec::new(),
            hydrate: None,
            guest: Some(GuestLiveMeta {
                site_iid,
                visitor_id,
                data_mode,
                guest_system_prompt,
            }),
            created: Instant::now(),
        },
    );
    let ws_path = format!("/v1/live/ws?sid={sid}&token={token}");
    (token, ws_path)
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
        hydrate: None,
        guest: None,
        created: Instant::now(),
    })
}

pub async fn live_guest_session_take(
    pool: &PgPool,
    sid: &str,
    token: &str,
) -> Option<LiveSessionTicket> {
    let sid = sid.trim();
    let token = token.trim();
    if sid.is_empty() || token.is_empty() {
        return None;
    }

    // Verify token signature, expiration, sid and scope == "site_guest"
    let claims = live_ticket_verify(token)?;
    if claims.sid != sid || claims.scope != "site_guest" {
        return None;
    }

    // 1. Fast in-memory path (same pod)
    if let Some((_, row)) = sessions().remove(sid) {
        if row.guest.is_some() && (row.token == token || row.token.starts_with(token) || token.starts_with(&row.token)) {
            if row.created.elapsed() <= LIVE_TICKET_TTL {
                return Some(row);
            }
        }
    }

    // 2. Stateless cross-pod verification
    let site_iid = claims.site_iid?;
    let visitor_id = claims.visitor_id.unwrap_or_default();
    let data_mode = claims.data_mode.unwrap_or_else(|| "published".to_string());
    let guest_system_prompt = claims.guest_system_prompt.unwrap_or_default();

    // Verify billing reservation status in DB
    let res_status: Option<(String,)> = sqlx::query_as(
        "SELECT status FROM ai.billing_reservation WHERE req_id = $1 AND owner_iid = $2",
    )
    .bind(&claims.req_id)
    .bind(claims.owner_iid)
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
    let billing_row = c35_mod_billing::billing_account_ensure(pool, claims.owner_iid).await.ok()?;

    Some(LiveSessionTicket {
        owner_iid: claims.owner_iid,
        token: token.to_string(),
        offer,
        req_id: claims.req_id,
        billing_row,
        chat_id: None,
        mention_ids: Vec::new(),
        hydrate: None,
        guest: Some(GuestLiveMeta {
            site_iid,
            visitor_id,
            data_mode,
            guest_system_prompt,
        }),
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
            ..Default::default()
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
    fn guest_live_ticket_verify() {
        test_guest_live_ticket_sign_and_verify();
    }

    #[test]
    fn test_guest_live_ticket_sign_and_verify() {
        let claims = LiveTicketClaims {
            sid: "guest-sid-456".into(),
            owner_iid: 88000,
            offer_id: "live.alienai".into(),
            req_id: "req-456".into(),
            chat_id: None,
            mention_ids: vec![],
            exp: chrono::Utc::now().timestamp() + 300,
            scope: "site_guest".to_string(),
            site_iid: Some(12345),
            visitor_id: Some("vis-xyz".to_string()),
            data_mode: Some("draft".to_string()),
            guest_system_prompt: Some("You are a helpful assistant".to_string()),
        };
        let token = live_ticket_sign(&claims);
        assert!(!token.is_empty());

        let verified = live_ticket_verify(&token).expect("guest ticket verification should succeed");
        assert_eq!(verified.sid, "guest-sid-456");
        assert_eq!(verified.scope, "site_guest");
        assert_eq!(verified.site_iid, Some(12345));
        assert_eq!(verified.visitor_id.as_deref(), Some("vis-xyz"));
        assert_eq!(verified.data_mode.as_deref(), Some("draft"));
        assert_eq!(verified.guest_system_prompt.as_deref(), Some("You are a helpful assistant"));
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
            ..Default::default()
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
            ..Default::default()
        };
        let token = live_ticket_sign(&claims);
        assert!(live_ticket_verify(&token).is_none());
    }

    #[tokio::test]
    async fn test_guest_live_session_register_and_in_memory_take() {
        let dummy_pool = sqlx::PgPool::connect_lazy("postgres://unused").expect("lazy pool");
        let offer = LiveOfferRow {
            id: "live.alienai".into(),
            family: "google".into(),
            provider: "google".into(),
            provider_model: "gemini-2.5-flash".into(),
            inst_id: "inst.site.guest.call".into(),
            label_key: "live.alienai".into(),
            input_usd_per_min: 0.01,
            output_usd_per_min: 0.03,
            video_usd_per_min: 0.02,
            enabled: true,
            sort: 1,
            tool_topics: vec!["site.guest".into()],
        };
        let billing_row = c35_mod_billing::BillingRow {
            id: 1,
            owner_iid: 99000,
            plan_tier: "free".into(),
            balance_usd: 10.0,
            alien_allow_5h_used: 0.0,
            alien_allow_5h_limit: 100.0,
            alien_allow_weekly_used: 0.0,
            alien_allow_weekly_limit: 500.0,
            window_5h_start: chrono::Utc::now(),
            window_weekly_start: chrono::Utc::now(),
        };

        let sid = "test-guest-sid-take-1";
        let (token, ws_path) = guest_live_session_register(
            sid,
            99000,
            offer.clone(),
            "req-guest-take-1".into(),
            billing_row,
            12345,
            "vis-guest-1".into(),
            "draft".into(),
            "Welcome to the store".into(),
        );

        assert!(ws_path.contains(sid));
        assert!(ws_path.contains(&token));

        // Attempt take with wrong token should fail
        let wrong_take = live_guest_session_take(&dummy_pool, sid, "invalid.token").await;
        assert!(wrong_take.is_none());

        // Valid take
        let ticket = live_guest_session_take(&dummy_pool, sid, &token)
            .await
            .expect("in-memory guest take must succeed");
        assert_eq!(ticket.owner_iid, 99000);
        assert_eq!(ticket.offer.id, "live.alienai");
        let guest_meta = ticket.guest.expect("guest meta must be Some");
        assert_eq!(guest_meta.site_iid, 12345);
        assert_eq!(guest_meta.visitor_id, "vis-guest-1");
        assert_eq!(guest_meta.data_mode, "draft");
        assert_eq!(guest_meta.guest_system_prompt, "Welcome to the store");

        // Second take should return None since single-use take removed it
        let second_take = live_guest_session_take(&dummy_pool, sid, &token).await;
        // Without DB it won't find it in-memory
        assert!(second_take.is_none());
    }

    #[tokio::test]
    async fn test_guest_live_session_take_rejects_app_live_scope() {
        let dummy_pool = sqlx::PgPool::connect_lazy("postgres://unused").expect("lazy pool");
        let claims = LiveTicketClaims {
            sid: "user-sid-789".into(),
            owner_iid: 99000,
            offer_id: "live.alienai".into(),
            req_id: "req-789".into(),
            chat_id: Some(1),
            mention_ids: vec![],
            exp: chrono::Utc::now().timestamp() + 300,
            scope: "app_live".to_string(),
            ..Default::default()
        };
        let token = live_ticket_sign(&claims);

        // Attempting to take an app_live scoped ticket via live_guest_session_take must return None
        let take_res = live_guest_session_take(&dummy_pool, "user-sid-789", &token).await;
        assert!(take_res.is_none());
    }

    #[tokio::test]
    async fn guest_ws_take_without_jwt() {
        let dummy_pool = sqlx::PgPool::connect_lazy("postgres://unused").expect("lazy pool");
        let offer = LiveOfferRow {
            id: "live.alienai".into(),
            family: "google".into(),
            provider: "google".into(),
            provider_model: "gemini-2.5-flash".into(),
            inst_id: "inst.site.guest.call".into(),
            label_key: "live.alienai".into(),
            input_usd_per_min: 0.01,
            output_usd_per_min: 0.03,
            video_usd_per_min: 0.02,
            enabled: true,
            sort: 1,
            tool_topics: vec!["site.guest".into()],
        };
        let billing_row = c35_mod_billing::BillingRow {
            id: 1,
            owner_iid: 99000,
            plan_tier: "free".into(),
            balance_usd: 10.0,
            alien_allow_5h_used: 0.0,
            alien_allow_5h_limit: 100.0,
            alien_allow_weekly_used: 0.0,
            alien_allow_weekly_limit: 500.0,
            window_5h_start: chrono::Utc::now(),
            window_weekly_start: chrono::Utc::now(),
        };

        let sid = "test-guest-no-jwt-sid";
        let (token, ws_path) = guest_live_session_register(
            sid,
            99000,
            offer.clone(),
            "req-guest-no-jwt".into(),
            billing_row,
            12345,
            "vis-guest-no-jwt".into(),
            "draft".into(),
            "Guest instructions".into(),
        );

        // Guest ws_path connects without user JWT (only sid and ticket token)
        assert!(ws_path.contains("/live/ws?sid="));
        assert!(ws_path.contains(&format!("sid={sid}")));
        assert!(ws_path.contains(&format!("token={token}")));
        assert!(!ws_path.contains("jwt="));

        // Attempting to take without JWT succeeds because scope is site_guest
        let ticket = live_guest_session_take(&dummy_pool, sid, &token)
            .await
            .expect("guest WS ticket take without user JWT must succeed");
        assert_eq!(ticket.owner_iid, 99000);
        let guest_meta = ticket.guest.expect("guest metadata must be populated");
        assert_eq!(guest_meta.site_iid, 12345);
        assert_eq!(guest_meta.visitor_id, "vis-guest-no-jwt");
    }
}

