use axum::{routing::get, Router};
use c35_ctx::AppState;

pub fn router(state: AppState) -> Router {
    Router::new()
        .route("/health", get(|| async { "ok" }))
        .route("/livez", get(|| async { "ok" }))
        .with_state(state)
}
