use axum::{
    body::Bytes,
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::post,
    Router,
};
use c35_ctx::AppState;
use tracing::warn;

use crate::billing_midtrans::{signature_verify, Notification};
use crate::billing_runtime::billing_runtime;
use crate::billing_topup::billing_topup_settle;

pub fn billing_webhook_router() -> Router<AppState> {
    Router::new().route("/v1/billing/webhook/midtrans", post(webhook_midtrans))
}

pub async fn webhook_midtrans(State(state): State<AppState>, body: Bytes) -> impl IntoResponse {
    match webhook_midtrans_inner(&state.pool, &body).await {
        Ok(msg) => (StatusCode::OK, msg).into_response(),
        Err((code, msg)) => {
            warn!("[c35:billing] webhook: {msg}");
            (code, msg).into_response()
        }
    }
}

async fn webhook_midtrans_inner(
    pool: &sqlx::PgPool,
    body: &[u8],
) -> std::result::Result<String, (StatusCode, String)> {
    let n: Notification = serde_json::from_slice(body)
        .map_err(|e| (StatusCode::BAD_REQUEST, format!("invalid json: {e}")))?;
    let rt = billing_runtime();
    if rt.midtrans_server_key.is_empty() {
        warn!("[c35:billing] webhook received but MIDTRANS_SERVER_KEY is unset");
        return Err((StatusCode::SERVICE_UNAVAILABLE, "MIDTRANS_SERVER_KEY unset".into()));
    }
    if !signature_verify(
        &n.order_id,
        &n.status_code,
        &n.gross_amount,
        &rt.midtrans_server_key,
        &n.signature_key,
    ) {
        return Err((StatusCode::FORBIDDEN, "invalid signature".into()));
    }
    billing_topup_settle(pool, &n, body)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e))
}
