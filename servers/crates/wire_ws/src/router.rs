use axum::{
    extract::{Query, State, WebSocketUpgrade},
    http::HeaderMap,
    response::IntoResponse,
    routing::get,
    Router,
};
use c35_ctx::AppState;
use c35_mod_device::agent_session_resolve;
use serde::Deserialize;

use crate::live_ws;
use crate::{agent_session, session};

#[derive(Debug, Clone, Deserialize)]
pub struct WsQuery {
    pub jwt: Option<String>,
    pub since: Option<i64>,
    pub locale: Option<String>,
    pub tz: Option<String>,
    #[serde(alias = "v")]
    pub build: Option<i64>,
    pub version_name: Option<String>,
    /// Client platform id (3 = Windows desktop app).
    pub platform: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct AgentWsQuery {
    pub session_key: String,
    #[serde(alias = "v")]
    pub build: Option<i64>,
    pub version_name: Option<String>,
    pub browser_ready: Option<bool>,
    pub browser_engine: Option<String>,
    pub extension_install_version: Option<String>,
    #[serde(alias = "browser_install_version")]
    pub browser_install_version: Option<String>,
}

pub fn router(state: AppState) -> Router {
    Router::new()
        .route("/v1/ws", get(ws_handler))
        .route("/v1/live/ws", get(live_ws::live_ws_handler))
        .route("/v1/agent/ws", get(agent_ws_handler))
        .with_state(state)
}

async fn ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
    Query(q): Query<WsQuery>,
    headers: HeaderMap,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| session::handle(socket, state, q, headers))
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
    let agent_build = q.build.unwrap_or(0);
    let agent_version_name = q.version_name.clone().unwrap_or_default();
    let browser_meta = c35_mod_device::agent_browser_meta_from_json(&serde_json::json!({
        "browser_ready": q.browser_ready,
        "browser_engine": q.browser_engine,
        "extension_install_version": q.extension_install_version,
        "browser_install_version": q.browser_install_version,
    }));
    match agent_session_resolve(&state.pool, &session_key).await {
        Ok(Some(_)) => ws
            .on_upgrade(move |socket| {
                agent_session::handle(
                    socket,
                    state,
                    session_key,
                    agent_build,
                    agent_version_name,
                    browser_meta,
                )
            })
            .into_response(),
        Ok(None) => axum::http::StatusCode::UNAUTHORIZED.into_response(),
        Err(_) => axum::http::StatusCode::INTERNAL_SERVER_ERROR.into_response(),
    }
}
