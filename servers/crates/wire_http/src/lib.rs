mod agent;
mod app_web;
mod catalog;
mod device;
mod guest_order;
mod invoke;
mod version;
mod web;

use axum::{
    routing::get,
    Router,
};
use c35_ctx::AppState;
use c35_mod_channel::channel_router;
use c35_mod_file::file_router;
use c35_mod_identity::{auth_router, oauth_router};

pub use invoke::dispatch_invoke;
pub use web::web_root_dir;

pub fn router(state: AppState) -> Router {
    Router::new()
        .route("/", get(web::root_get))
        .route("/health", get(|| async { "ok" }))
        .route("/livez", get(|| async { "ok" }))
        .merge(web::web_router())
        .merge(app_web::app_web_router())
        .merge(c35_mod_site::site_render_router())
        .merge(auth_router())
        .merge(oauth_router())
        .merge(file_router())
        .merge(channel_router())
        .merge(version::version_router())
        .merge(device::device_router())
        .merge(agent::agent_router())
        .merge(catalog::catalog_router())
        .merge(invoke::invoke_router())
        .merge(guest_order::guest_order_router())
        .with_state(state)
}
