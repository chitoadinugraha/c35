use axum::{
    extract::{Query, State, WebSocketUpgrade},
    response::IntoResponse,
    routing::get,
    Router,
};
use c35_ctx::AppState;
use c35_mod_device::agent_session_resolve;
use serde::Deserialize;

use crate::{agent_session, session};

#[derive(Debug, Deserialize)]
pub struct WsQuery {
    pub jwt: Option<String>,
    pub since: Option<i64>,
    pub locale: Option<String>,
    pub tz: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct AgentWsQuery {
    pub session_key: String,
}

pub fn router(state: AppState) -> Router {
    Router::new()
        .route("/v1/ws", get(ws_handler))
        .route("/v1/agent/ws", get(agent_ws_handler))
        .with_state(state)
}

async fn ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
    Query(q): Query<WsQuery>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| session::handle(socket, state, q))
}

async fn agent_ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
    Query(q): Query<AgentWsQuery>,
) -> impl IntoResponse {
    let session_key = q.session_key.trim().to_string();
    if session_key.is_empty() {
        return axum::http::StatusCode::UNAUTHORIZED.into_response();
    }
    match agent_session_resolve(&state.pool, &session_key).await {
        Ok(Some(_)) => ws
            .on_upgrade(move |socket| agent_session::handle(socket, state, session_key))
            .into_response(),
        Ok(None) => axum::http::StatusCode::UNAUTHORIZED.into_response(),
        Err(_) => axum::http::StatusCode::INTERNAL_SERVER_ERROR.into_response(),
    }
}
