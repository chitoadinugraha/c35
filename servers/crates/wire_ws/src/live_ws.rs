use axum::extract::ws::WebSocket;
use axum::extract::{Query, State, WebSocketUpgrade};
use axum::http::HeaderMap;
use axum::response::IntoResponse;
use c35_ctx::AppState;
use c35_mod_live::{live_guest_session_take, live_proxy_run, live_session_take};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct LiveWsQuery {
    pub jwt: Option<String>,
    pub sid: Option<String>,
    pub token: Option<String>,
    pub ticket: Option<String>,
}

pub async fn live_ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
    Query(q): Query<LiveWsQuery>,
    headers: HeaderMap,
) -> impl IntoResponse {
    let sid = q.sid.as_deref().unwrap_or("").trim();
    let live_token = q
        .token
        .as_deref()
        .or(q.ticket.as_deref())
        .unwrap_or("")
        .trim();

    if sid.is_empty() || live_token.is_empty() {
        return axum::http::StatusCode::BAD_REQUEST.into_response();
    }

    let mut ticket_opt = None;

    // 1. Authenticated user path if jwt is present
    if let Some(user_jwt) = q.jwt.as_deref().filter(|s| !s.trim().is_empty()) {
        if let Ok(Some(caller_iid)) = c35_mod_identity::auth_session_resolve(&state.pool, user_jwt).await {
            if caller_iid > 0 {
                ticket_opt = live_session_take(&state.pool, sid, live_token, caller_iid).await;
            }
        }
    }

    // 2. Guest path when jwt is absent or invalid: allow anonymous guest WebSocket
    if ticket_opt.is_none() {
        if let Some(guest_ticket) = live_guest_session_take(&state.pool, sid, live_token).await {
            if guest_ticket.guest.is_some() {
                ticket_opt = Some(guest_ticket);
            }
        }
    }

    let Some(ticket) = ticket_opt else {
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
