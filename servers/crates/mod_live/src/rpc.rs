use c35_proto::{ReqLiveStart, ResLiveStart};
use c35_store::snowflake_id;
use sqlx::PgPool;

use crate::billing::{live_billing_abort, live_billing_gate, live_req_id};
use crate::catalog::live_offer_resolve;
use crate::session::live_session_register;

fn live_enabled() -> bool {
    match std::env::var("C35_LIVE_ENABLED")
        .ok()
        .map(|v| v.trim().to_ascii_lowercase())
        .as_deref()
    {
        Some("1" | "true" | "yes" | "on") => true,
        Some("0" | "false" | "no" | "off") => false,
        _ => cfg!(debug_assertions),
    }
}

pub async fn live_start_rpc(pool: &PgPool, owner_iid: i64, req: ReqLiveStart) -> ResLiveStart {
    let offer_id = req.offer_id.trim();
    if offer_id.is_empty() {
        return ResLiveStart {
            error: "offer_id required".into(),
            ..Default::default()
        };
    }
    let Some(offer) = live_offer_resolve(pool, offer_id).await else {
        return ResLiveStart {
            error: "Unknown live offer".into(),
            ..Default::default()
        };
    };
    if !offer.enabled {
        return ResLiveStart {
            error: "This live call option is not available yet".into(),
            ..Default::default()
        };
    }
    if !live_enabled() {
        return ResLiveStart {
            error: "Live call is not available yet".into(),
            ..Default::default()
        };
    }
    let sid = snowflake_id().to_string();
    let req_id = live_req_id(&req.req_id, &sid);
    let billing_row = match live_billing_gate(pool, owner_iid, &req_id, &offer).await {
        Ok(r) => r,
        Err(e) => {
            return ResLiveStart {
                error: e.to_string(),
                ..Default::default()
            };
        }
    };
    let token = live_session_register(&sid, owner_iid, offer, req_id, billing_row);
    ResLiveStart {
        live_session_id: sid.clone(),
        ws_path: format!("/v1/live/ws?sid={sid}&token={token}"),
        ..Default::default()
    }
}

pub async fn live_start_abort_unconnected(pool: &PgPool, sid: &str, req_id: &str) {
    let _ = live_billing_abort(pool, req_id).await;
    crate::session::live_session_drop(sid);
}
