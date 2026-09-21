mod catalog;
mod invoke;
mod version;

use axum::{routing::get, Router};
use c35_ctx::AppState;
use c35_mod_channel::channel_router;
use c35_mod_file::file_router;
use c35_mod_identity::{auth_router, oauth_router};

pub use invoke::dispatch_invoke;

pub fn router(state: AppState) -> Router {
    Router::new()
        .route("/health", get(|| async { "ok" }))
        .route("/livez", get(|| async { "ok" }))
        .merge(auth_router())
        .merge(oauth_router())
        .merge(file_router())
        .merge(channel_router())
        .merge(version::version_router())
        .merge(catalog::catalog_router())
        .merge(invoke::invoke_router())
        .with_state(state)
}
