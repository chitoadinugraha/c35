use axum::extract::ws::WebSocket;
use axum::extract::{Query, State, WebSocketUpgrade};
use axum::http::HeaderMap;
use axum::response::IntoResponse;
use c35_ctx::AppState;
use c35_mod_live::{live_proxy_run, live_session_take};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct LiveWsQuery {
    pub jwt: Option<String>,
    pub sid: Option<String>,
    pub token: Option<String>,
}

pub async fn live_ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
    Query(q): Query<LiveWsQuery>,
    headers: HeaderMap,
) -> impl IntoResponse {
    let token = match q.jwt.as_deref() {
        Some(t) if !t.is_empty() => t,
        _ => return axum::http::StatusCode::UNAUTHORIZED.into_response(),
    };
    let sid = q.sid.as_deref().unwrap_or("").trim();
    let live_token = q.token.as_deref().unwrap_or("").trim();
    if sid.is_empty() || live_token.is_empty() {
        return axum::http::StatusCode::BAD_REQUEST.into_response();
    }

    let caller_iid = match c35_mod_identity::auth_session_resolve(&state.pool, token).await {
        Ok(Some(i)) if i > 0 => i,
        _ => return axum::http::StatusCode::UNAUTHORIZED.into_response(),
    };

    let Some(ticket) = live_session_take(&state.pool, sid, live_token, caller_iid).await else {
        return axum::http::StatusCode::FORBIDDEN.into_response();
    };

    let _ = c35_mod_identity::identity_geo_from_headers(&headers);
    let pool = state.pool.clone();
    let nats = state.nats.clone();
    ws.on_upgrade(move |socket: WebSocket| async move {
        live_proxy_run(pool, nats, ticket, socket).await;
    })
    .into_response()
}
