mod agent;
mod app_web;
mod catalog;
mod device;
mod guest_order;
mod invoke;
mod locale;
mod mcp_agent;
mod status;
mod version;
mod web;

use axum::{
    extract::Query,
    http::HeaderMap,
    routing::get,
    Json, Router,
};
use c35_ctx::AppState;
use serde::Deserialize;
use c35_mod_channel::channel_router;
use c35_mod_file::file_router;
use c35_mod_identity::{auth_router, oauth_router};

pub use invoke::dispatch_invoke;
pub use locale::detect_locale;
pub use status::status_probe_spawn;
pub use web::web_root_dir;

fn mcp_agent_router() -> Router<AppState> {
    if mcp_agent::mcp_agent_enabled() {
        mcp_agent::mcp_agent_router()
    } else {
        Router::new()
    }
}

#[derive(Deserialize)]
struct LocaleQuery {
    lang: Option<String>,
}

async fn locale_detect(headers: HeaderMap, Query(q): Query<LocaleQuery>) -> Json<serde_json::Value> {
    let lang = locale::detect_locale(&headers, q.lang.as_deref());
    Json(serde_json::json!({ "lang": lang }))
}

pub fn router(state: AppState) -> Router {
    Router::new()
        .route("/", get(web::root_get))
        .route("/health", get(|| async { "ok" }))
        .route("/livez", get(|| async { "ok" }))
        .route("/locale/detect", get(locale_detect))
        .route("/v1/system/status", get(status::status_handler))
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
        .merge(mcp_agent_router())
        .merge(catalog::catalog_router())
        .merge(invoke::invoke_router())
        .merge(c35_mod_billing::billing_webhook_router())
        .merge(c35_mod_mail::mail_router())
        .merge(guest_order::guest_order_router())
        .with_state(state)
}
