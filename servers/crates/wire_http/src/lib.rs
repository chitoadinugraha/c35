mod invoke;

use axum::{routing::get, Router};
use c35_ctx::AppState;
use c35_mod_identity::auth_router;

pub use invoke::dispatch_invoke;

pub fn router(state: AppState) -> Router {
    Router::new()
        .route("/health", get(|| async { "ok" }))
        .route("/livez", get(|| async { "ok" }))
        .merge(auth_router())
        .merge(invoke::invoke_router())
        .with_state(state)
}
