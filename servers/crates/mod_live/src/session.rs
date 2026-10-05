use std::sync::OnceLock;
use std::time::{Duration, Instant};

use c35_mod_billing::BillingRow;
use dashmap::DashMap;
use rand::Rng;

use crate::catalog::LiveOfferRow;

#[derive(Clone)]
pub struct LiveSessionTicket {
    pub owner_iid: i64,
    pub token: String,
    pub offer: LiveOfferRow,
    pub req_id: String,
    pub billing_row: BillingRow,
    pub created: Instant,
}

fn sessions() -> &'static DashMap<String, LiveSessionTicket> {
    static LIVE_SESSIONS: OnceLock<DashMap<String, LiveSessionTicket>> = OnceLock::new();
    LIVE_SESSIONS.get_or_init(DashMap::new)
}

const LIVE_TICKET_TTL: Duration = Duration::from_secs(600);

pub fn live_session_register(
    sid: &str,
    owner_iid: i64,
    offer: LiveOfferRow,
    req_id: String,
    billing_row: BillingRow,
) -> String {
    let token: String = rand::thread_rng()
        .sample_iter(&rand::distributions::Alphanumeric)
        .take(32)
        .map(char::from)
        .collect();
    sessions().insert(
        sid.to_string(),
        LiveSessionTicket {
            owner_iid,
            token: token.clone(),
            offer,
            req_id,
            billing_row,
            created: Instant::now(),
        },
    );
    token
}

pub fn live_session_take(sid: &str, token: &str, owner_iid: i64) -> Option<LiveSessionTicket> {
    let sid = sid.trim();
    let token = token.trim();
    if sid.is_empty() || token.is_empty() {
        return None;
    }
    let row = sessions().remove(sid)?.1;
    if row.owner_iid != owner_iid || row.token != token {
        return None;
    }
    if row.created.elapsed() > LIVE_TICKET_TTL {
        return None;
    }
    Some(row)
}

pub fn live_session_drop(sid: &str) {
    sessions().remove(sid.trim());
}
