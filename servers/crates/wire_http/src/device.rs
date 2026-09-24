use axum::extract::{Query, State};
use axum::http::{HeaderMap, StatusCode};
use axum::response::IntoResponse;
use axum::routing::{get, post};
use axum::{Json, Router};
use c35_ctx::AppState;
use c35_mod_device::{
    agent_session_resolve, device_pair_poll, device_pair_register, device_unpair,
};
use c35_proto::{ReqDevicePairPoll, ReqDevicePairRegister};
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize)]
pub struct DevicePairRegisterBody {
    pub device_name: String,
    #[serde(default)]
    pub device_type: String,
}

#[derive(Debug, Serialize)]
pub struct DevicePairRegisterRes {
    pub code: String,
    pub device_secret: String,
    pub expires_in_sec: i64,
}

#[derive(Debug, Deserialize)]
pub struct DevicePairPollQuery {
    pub secret: String,
}

#[derive(Debug, Serialize)]
pub struct DevicePairPollRes {
    pub status: String,
    #[serde(skip_serializing_if = "String::is_empty")]
    pub session_key: String,
    #[serde(skip_serializing_if = "is_zero")]
    pub device_iid: i64,
}

fn is_zero(v: &i64) -> bool {
    *v == 0
}

pub fn device_router() -> Router<AppState> {
    Router::new()
        .route("/v1/device/pair/register", post(pair_register))
        .route("/v1/device/pair/poll", get(pair_poll))
        .route("/v1/device/unpair", post(device_unpair_handler))
}

fn session_key_from_headers(headers: &HeaderMap) -> Option<&str> {
    headers
        .get("X-Device-Session")
        .or_else(|| headers.get("x-device-session"))
        .and_then(|v| v.to_str().ok())
        .map(str::trim)
        .filter(|s| !s.is_empty())
}

async fn device_unpair_handler(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> impl IntoResponse {
    let session_key = session_key_from_headers(&headers).unwrap_or("");
    let session = match agent_session_resolve(&st.pool, session_key).await {
        Ok(Some(s)) => s,
        Ok(None) => return (StatusCode::UNAUTHORIZED, "invalid session").into_response(),
        Err(e) => return (StatusCode::INTERNAL_SERVER_ERROR, e).into_response(),
    };
    match device_unpair(&st.pool, st.nats.as_ref(), session.device_iid).await {
        Ok(()) => (StatusCode::OK, Json(serde_json::json!({ "ok": true }))).into_response(),
        Err(e) => (StatusCode::BAD_REQUEST, e).into_response(),
    }
}

async fn pair_register(
    State(st): State<AppState>,
    Json(body): Json<DevicePairRegisterBody>,
) -> impl IntoResponse {
    let req = ReqDevicePairRegister {
        device_name: body.device_name,
        device_type: body.device_type,
    };
    match device_pair_register(&st.pool, req).await {
        Ok(res) => (
            StatusCode::OK,
            Json(DevicePairRegisterRes {
                code: res.code,
                device_secret: res.device_secret,
                expires_in_sec: res.expires_in_sec,
            }),
        )
            .into_response(),
        Err(msg) => (StatusCode::BAD_REQUEST, msg).into_response(),
    }
}

async fn pair_poll(
    State(st): State<AppState>,
    Query(q): Query<DevicePairPollQuery>,
) -> impl IntoResponse {
    let req = ReqDevicePairPoll {
        device_secret: q.secret,
    };
    match device_pair_poll(&st.pool, req).await {
        Ok(res) => (
            StatusCode::OK,
            Json(DevicePairPollRes {
                status: res.status,
                session_key: res.session_key,
                device_iid: res.device_iid,
            }),
        )
            .into_response(),
        Err(msg) => (StatusCode::INTERNAL_SERVER_ERROR, msg).into_response(),
    }
}
