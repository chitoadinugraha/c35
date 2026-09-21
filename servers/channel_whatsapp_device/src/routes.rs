use crate::db;
use crate::AppState;
use axum::extract::{Path, State};
use axum::response::IntoResponse;
use axum::routing::{get, post};
use axum::{Json, Router};
use serde::Serialize;
use std::sync::Arc;
use tracing::info;

#[derive(Serialize)]
struct StatusResponse {
    bot_iid: i64,
    channel_id: String,
    status: String,
    phone_jid: String,
    qr_raw: String,
    error_message: String,
}

pub fn router(state: Arc<AppState>) -> Router {
    Router::new()
        .route("/healthz", get(|| async { "OK (channel-whatsapp-device)" }))
        .route("/livez", get(|| async { "OK" }))
        .route("/v1/channel/{bot_iid}/{channel_id}/status", get(channel_status))
        .route("/v1/channel/{bot_iid}/{channel_id}/restart", post(channel_restart))
        .route("/v1/channel/{bot_iid}/{channel_id}/stop", post(channel_stop))
        .with_state(state)
}

async fn channel_status(
    State(state): State<Arc<AppState>>,
    Path((bot_iid, channel_id)): Path<(i64, String)>,
) -> impl IntoResponse {
    let row = db::channel_get(&state.manager.pool, bot_iid, &channel_id).await.ok().flatten();
    match row {
        Some(r) => Json(StatusResponse {
            bot_iid: r.bot_iid,
            channel_id: r.channel_id,
            status: r.status,
            phone_jid: r.phone_jid,
            qr_raw: r.qr_raw,
            error_message: r.error_message,
        }),
        None => Json(StatusResponse {
            bot_iid,
            channel_id,
            status: "missing".into(),
            phone_jid: String::new(),
            qr_raw: String::new(),
            error_message: "channel not found".into(),
        }),
    }
}

async fn channel_restart(
    State(state): State<Arc<AppState>>,
    Path((bot_iid, channel_id)): Path<(i64, String)>,
) -> impl IntoResponse {
    info!("[wa-device] http restart bot_iid={bot_iid} channel_id={channel_id}");
    state.manager.restart_channel(bot_iid, channel_id.clone());
    Json(serde_json::json!({ "ok": true, "bot_iid": bot_iid, "channel_id": channel_id }))
}

async fn channel_stop(
    State(state): State<Arc<AppState>>,
    Path((bot_iid, channel_id)): Path<(i64, String)>,
) -> impl IntoResponse {
    info!("[wa-device] http stop bot_iid={bot_iid} channel_id={channel_id}");
    state.manager.stop_channel(bot_iid, channel_id.clone());
    Json(serde_json::json!({ "ok": true, "bot_iid": bot_iid, "channel_id": channel_id }))
}
