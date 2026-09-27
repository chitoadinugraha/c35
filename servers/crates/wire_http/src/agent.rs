use axum::extract::State;
use axum::http::{HeaderMap, StatusCode};
use axum::response::IntoResponse;
use axum::routing::{get, post};
use axum::{Json, Router};
use c35_ctx::AppState;
use c35_mod_device::{agent_log_put, agent_profile_get, agent_session_resolve};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct AgentLogBody {
    pub kind: String,
    pub topic: String,
    pub text: String,
    #[serde(default)]
    pub meta: Option<serde_json::Value>,
}

pub fn agent_router() -> Router<AppState> {
    Router::new()
        .route("/v1/agent/log", post(agent_log))
        .route("/v1/agent/profile", get(agent_profile))
}

fn session_key_from_headers(headers: &HeaderMap) -> Option<&str> {
    headers
        .get("X-Device-Session")
        .or_else(|| headers.get("x-device-session"))
        .and_then(|v| v.to_str().ok())
        .map(str::trim)
        .filter(|s| !s.is_empty())
}

async fn agent_profile(State(st): State<AppState>, headers: HeaderMap) -> impl IntoResponse {
    let session_key = session_key_from_headers(&headers).unwrap_or("");
    let session = match agent_session_resolve(&st.pool, session_key).await {
        Ok(Some(s)) => s,
        Ok(None) => return (StatusCode::UNAUTHORIZED, "invalid session").into_response(),
        Err(e) => return (StatusCode::INTERNAL_SERVER_ERROR, e).into_response(),
    };
    match agent_profile_get(&st.pool, &session).await {
        Ok(profile) => Json(profile).into_response(),
        Err(e) => (StatusCode::NOT_FOUND, e).into_response(),
    }
}

async fn agent_log(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(body): Json<AgentLogBody>,
) -> impl IntoResponse {
    let session_key = session_key_from_headers(&headers).unwrap_or("");
    let session = match agent_session_resolve(&st.pool, session_key).await {
        Ok(Some(s)) => s,
        Ok(None) => return (StatusCode::UNAUTHORIZED, "invalid session").into_response(),
        Err(e) => return (StatusCode::INTERNAL_SERVER_ERROR, e).into_response(),
    };
    match agent_log_put(
        &st.pool,
        st.nats.as_ref(),
        session.device_iid,
        session.owner_iid,
        &body.kind,
        &body.topic,
        &body.text,
        body.meta,
    )
    .await
    {
        Ok(_) => StatusCode::OK.into_response(),
        Err(e) => (StatusCode::BAD_REQUEST, e).into_response(),
    }
}
