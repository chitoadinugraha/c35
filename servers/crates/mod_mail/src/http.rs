use axum::{extract::State, http::{HeaderMap, StatusCode}, response::IntoResponse, routing::post, Router};
use c35_ctx::AppState;
use tracing::warn;

use crate::attachments::MailCas;
use crate::inbound::inbound_webhook;

pub fn mail_router() -> Router<AppState> {
    Router::new().route("/v1/mail/inbound", post(mail_inbound_post))
}

async fn mail_inbound_post(State(state): State<AppState>, headers: HeaderMap, body: axum::body::Bytes) -> impl IntoResponse {
    let authorization = headers.get(axum::http::header::AUTHORIZATION).and_then(|v| v.to_str().ok());
    let signature = headers.get("x-mail-signature").or_else(|| headers.get("X-Mail-Signature")).and_then(|v| v.to_str().ok());
    let cas = MailCas { pool: state.pool.clone(), cas_dir: state.cas_dir.clone(), cas_secret: state.cas_secret.clone() };
    match inbound_webhook(&state.pool, Some(cas), body.to_vec(), authorization, signature).await {
        Ok(message_id) => (StatusCode::OK, format!(r#"{{"ok":true,"message_id":{message_id}}}"#)).into_response(),
        Err(e) => {
            warn!("[c35:mail] inbound: {e}");
            let status = if e.contains("unauthorized") { StatusCode::UNAUTHORIZED }
                else if e.contains("invalid json") || e.contains("missing to") { StatusCode::BAD_REQUEST }
                else { StatusCode::INTERNAL_SERVER_ERROR };
            (status, e).into_response()
        }
    }
}
