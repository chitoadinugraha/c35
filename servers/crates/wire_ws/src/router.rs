use axum::{
    extract::{Query, State, WebSocketUpgrade},
    response::IntoResponse,
    routing::get,
    Router,
};
use c35_ctx::AppState;
use serde::Deserialize;

use crate::session;

#[derive(Debug, Deserialize)]
pub struct WsQuery {
    pub jwt: Option<String>,
    pub since: Option<i64>,
    pub locale: Option<String>,
    pub tz: Option<String>,
}

pub fn router(state: AppState) -> Router {
    Router::new().route("/v1/ws", get(ws_handler)).with_state(state)
}

async fn ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
    Query(q): Query<WsQuery>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| session::handle(socket, state, q))
}
