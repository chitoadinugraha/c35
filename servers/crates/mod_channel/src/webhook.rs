use axum::{
    extract::{Path, Query, State},
    http::{HeaderMap, StatusCode},
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use c35_ctx::AppState;
use serde::Deserialize;
use serde::Serialize;
use tracing::warn;

use crate::inbound::channel_inbound_from_webhook;
use crate::store::{bot_channel_get, STATUS_CONNECTED};
use crate::telegram::parse_telegram_payload;
use crate::whatsapp::parse_whatsapp_payload;

#[derive(Serialize)]
struct WebhookJsonRes {
    status: String,
    message: String,
    chat_id: i64,
    peer_iid: i64,
}

pub fn channel_router() -> Router<AppState> {
    Router::new()
        .route(
            "/v1/channels/telegram/webhook/{bot_iid}/{channel_id}/{secret}",
            post(telegram_webhook_scoped),
        )
        .route(
            "/v1/channels/whatsapp/webhook/{bot_iid}/{channel_id}",
            get(whatsapp_webhook_verify).post(whatsapp_webhook_scoped),
        )
        .route(
            "/v1/channels/whatsapp/webhook/{bot_iid}/{channel_id}/media",
            post(whatsapp_media_upload),
        )
}

#[derive(Serialize)]
struct MediaUploadRes {
    hash: String,
    mime: String,
    name: String,
    size_bytes: i64,
}

async fn telegram_webhook_scoped(
    Path((bot_iid, channel_id, secret)): Path<(i64, String, String)>,
    State(state): State<AppState>,
    headers: HeaderMap,
    body: axum::body::Bytes,
) -> impl IntoResponse {
    let channel = match crate::store::bot_channel_get_by_secret(&state.pool, bot_iid, &channel_id, &secret).await {
        Ok(Some(ch)) => ch,
        Ok(None) => return webhook_err(StatusCode::NOT_FOUND, "Unknown channel".into()),
        Err(e) => return webhook_err(StatusCode::INTERNAL_SERVER_ERROR, format!("Channel lookup failed: {e:#}")),
    };
    if let Some(header_secret) = headers.get("x-telegram-bot-api-secret-token") {
        if header_secret.to_str().ok() != Some(secret.as_str()) {
            return webhook_err(StatusCode::UNAUTHORIZED, "Invalid webhook secret".into());
        }
    }
    if channel.status != "connected" {
        return webhook_err(StatusCode::SERVICE_UNAVAILABLE, "Channel not active".into());
    }
    let inbound = match parse_telegram_payload(&body) {
        Ok(v) => v,
        Err(e) => return webhook_err(StatusCode::BAD_REQUEST, format!("Payload parse error: {e:#}")),
    };
    match channel_inbound_from_webhook(&state, bot_iid, &channel_id, &inbound).await {
        Ok((chat_id, peer_iid)) => webhook_ok(chat_id, peer_iid),
        Err(e) => {
            warn!("[c35:channel] telegram inbound failed: {e:#}");
            webhook_err(StatusCode::INTERNAL_SERVER_ERROR, format!("{e:#}"))
        }
    }
}

#[derive(Debug, Deserialize)]
struct WhatsappVerifyQuery {
    #[serde(rename = "hub.mode")]
    hub_mode: Option<String>,
    #[serde(rename = "hub.verify_token")]
    hub_verify_token: Option<String>,
    #[serde(rename = "hub.challenge")]
    hub_challenge: Option<String>,
}

async fn whatsapp_webhook_verify(
    Path((bot_iid, channel_id)): Path<(i64, String)>,
    State(state): State<AppState>,
    Query(q): Query<WhatsappVerifyQuery>,
) -> impl IntoResponse {
    if q.hub_mode.as_deref() != Some("subscribe") {
        return StatusCode::BAD_REQUEST.into_response();
    }
    let channel = match bot_channel_get(&state.pool, bot_iid, &channel_id).await {
        Ok(Some(ch)) => ch,
        _ => return StatusCode::NOT_FOUND.into_response(),
    };
    if q.hub_verify_token.as_deref() == Some(channel.verify_token.as_str()) {
        return q.hub_challenge.unwrap_or_default().into_response();
    }
    StatusCode::FORBIDDEN.into_response()
}

async fn whatsapp_media_upload(
    Path((bot_iid, channel_id)): Path<(i64, String)>,
    State(state): State<AppState>,
    headers: HeaderMap,
    body: axum::body::Bytes,
) -> impl IntoResponse {
    if body.is_empty() {
        return StatusCode::BAD_REQUEST.into_response();
    }
    let channel = match bot_channel_get(&state.pool, bot_iid, &channel_id).await {
        Ok(Some(ch)) => ch,
        Ok(None) => return StatusCode::NOT_FOUND.into_response(),
        Err(e) => {
            warn!("[c35:channel] media upload channel lookup failed: {e:#}");
            return StatusCode::INTERNAL_SERVER_ERROR.into_response();
        }
    };
    if channel.status != STATUS_CONNECTED {
        return StatusCode::SERVICE_UNAVAILABLE.into_response();
    }
    let mime = headers
        .get("content-type")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("application/octet-stream")
        .split(';')
        .next()
        .unwrap_or("application/octet-stream")
        .trim()
        .to_string();
    let name = headers
        .get("x-file-name")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("")
        .to_string();
    match c35_mod_file::cas_put(&state.pool, &state.cas_dir, &state.cas_secret, &body, &mime).await {
        Ok(put) => (
            StatusCode::OK,
            Json(MediaUploadRes {
                hash: put.hash,
                mime: put.mime_type,
                name,
                size_bytes: put.size_bytes,
            }),
        )
            .into_response(),
        Err(e) => {
            warn!("[c35:channel] media upload cas_put failed: {e:#}");
            StatusCode::INTERNAL_SERVER_ERROR.into_response()
        }
    }
}

async fn whatsapp_webhook_scoped(
    Path((bot_iid, channel_id)): Path<(i64, String)>,
    State(state): State<AppState>,
    body: axum::body::Bytes,
) -> impl IntoResponse {
    let channel = match bot_channel_get(&state.pool, bot_iid, &channel_id).await {
        Ok(Some(ch)) => ch,
        Ok(None) => return webhook_err(StatusCode::NOT_FOUND, "Unknown channel".into()),
        Err(e) => return webhook_err(StatusCode::INTERNAL_SERVER_ERROR, format!("Channel lookup failed: {e:#}")),
    };
    if channel.status != "connected" {
        return webhook_err(StatusCode::SERVICE_UNAVAILABLE, "Channel not active".into());
    }
    let inbound = match parse_whatsapp_payload(&body) {
        Ok(v) => v,
        Err(e) => return webhook_err(StatusCode::BAD_REQUEST, format!("Payload parse error: {e:#}")),
    };
    match channel_inbound_from_webhook(&state, bot_iid, &channel_id, &inbound).await {
        Ok((chat_id, peer_iid)) => webhook_ok(chat_id, peer_iid),
        Err(e) => {
            warn!("[c35:channel] whatsapp inbound failed: {e:#}");
            webhook_err(StatusCode::INTERNAL_SERVER_ERROR, format!("{e:#}"))
        }
    }
}

fn webhook_ok(chat_id: i64, peer_iid: i64) -> axum::response::Response {
    (
        StatusCode::OK,
        Json(WebhookJsonRes {
            status: "ok".into(),
            message: "Message received".into(),
            chat_id,
            peer_iid,
        }),
    )
        .into_response()
}

fn webhook_err(status: StatusCode, message: String) -> axum::response::Response {
    (
        status,
        Json(WebhookJsonRes {
            status: "error".into(),
            message,
            chat_id: 0,
            peer_iid: 0,
        }),
    )
        .into_response()
}
