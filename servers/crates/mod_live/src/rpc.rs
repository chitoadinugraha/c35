use async_nats::Client;
use c35_mod_chat::owner_session_prepare_for_live;
use c35_proto::{ReqLiveStart, ResLiveStart};
use c35_store::snowflake_id;
use serde_json::json;
use sqlx::PgPool;

use crate::billing::{live_billing_gate_nats_cached, live_req_id};
use crate::catalog::live_offer_resolve;
use crate::session::live_session_register;
use crate::trace::live_error_record;

pub fn live_enabled() -> bool {
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

fn live_start_log_req_id(client_req_id: &str) -> String {
    let t = client_req_id.trim();
    if t.is_empty() {
        format!("live_start:{}", snowflake_id())
    } else {
        t.to_string()
    }
}

async fn live_start_fail(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    log_req_id: &str,
    chat_id: Option<i64>,
    offer_id: &str,
    error: &str,
    detail: Option<&str>,
) -> ResLiveStart {
    live_error_record(
        pool,
        nats,
        owner_iid,
        Some(log_req_id),
        chat_id,
        "live_start",
        error,
        detail,
        json!({ "offer_id": offer_id }),
    )
    .await;
    ResLiveStart {
        error: error.into(),
        ..Default::default()
    }
}

pub async fn live_start_rpc(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    req: ReqLiveStart,
) -> ResLiveStart {
    let chat_id = (req.chat_id > 0).then_some(req.chat_id);
    let log_req_id = live_start_log_req_id(&req.req_id);
    let offer_id = req.offer_id.trim();
    if offer_id.is_empty() {
        return live_start_fail(
            pool,
            nats,
            owner_iid,
            &log_req_id,
            chat_id,
            "",
            "offer_id required",
            None,
        )
        .await;
    }
    let Some(offer) = live_offer_resolve(pool, offer_id).await else {
        return live_start_fail(
            pool,
            nats,
            owner_iid,
            &log_req_id,
            chat_id,
            offer_id,
            "Unknown live offer",
            None,
        )
        .await;
    };
    if !offer.enabled {
        return live_start_fail(
            pool,
            nats,
            owner_iid,
            &log_req_id,
            chat_id,
            offer_id,
            "This live call option is not available yet",
            None,
        )
        .await;
    }
    if !live_enabled() {
        return live_start_fail(
            pool,
            nats,
            owner_iid,
            &log_req_id,
            chat_id,
            offer_id,
            "Live call is not available yet",
            Some("C35_LIVE_ENABLED is off"),
        )
        .await;
    }
    let sid = snowflake_id().to_string();
    let req_id = live_req_id(&req.req_id, &sid);
    let (_session, hydrate) =
        owner_session_prepare_for_live(pool, nats, owner_iid, &req_id).await;
    let billing_row = match live_billing_gate_nats_cached(
        pool,
        nats,
        owner_iid,
        &req_id,
        &offer,
        hydrate.billing.as_ref(),
    )
    .await
    {
        Ok(r) => r,
        Err(e) => {
            let detail = e.to_string();
            return live_start_fail(
                pool,
                nats,
                owner_iid,
                &req_id,
                chat_id,
                offer_id,
                &detail,
                Some(&detail),
            )
            .await;
        }
    };
    let mention_ids = live_mention_ids_resolve(pool, owner_iid, chat_id, &req.mention_ids).await;
    let token = live_session_register(
        &sid,
        owner_iid,
        offer,
        req_id,
        billing_row,
        chat_id,
        mention_ids,
        Some(hydrate),
    );
    ResLiveStart {
        live_session_id: sid.clone(),
        ws_path: format!("/v1/live/ws?sid={sid}&token={token}"),
        ..Default::default()
    }
}

/// Request `mention_ids` win. Otherwise use the chat's sticky mentions and bound device.
pub async fn live_mention_ids_resolve(
    pool: &PgPool,
    owner_iid: i64,
    chat_id: Option<i64>,
    requested: &[String],
) -> Vec<String> {
    let explicit: Vec<String> = requested
        .iter()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();
    if !explicit.is_empty() {
        return explicit;
    }
    let Some(chat_id) = chat_id.filter(|id| *id > 0) else {
        return Vec::new();
    };
    let row: Option<(i64, serde_json::Value)> = sqlx::query_as(
        "SELECT COALESCE(bound_device_iid, 0), COALESCE(meta, '{}'::jsonb) \
         FROM ai.chat WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL",
    )
    .bind(chat_id)
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();
    let Some((bound, meta)) = row else {
        return Vec::new();
    };
    let mut ids: Vec<String> = meta
        .get("sticky_mention_ids")
        .and_then(|v| serde_json::from_value(v.clone()).ok())
        .unwrap_or_default();
    if bound > 0 {
        let id = format!("iid:{bound}");
        if !ids.iter().any(|x| x == &id) {
            ids.insert(0, id);
        }
    }
    ids
}
