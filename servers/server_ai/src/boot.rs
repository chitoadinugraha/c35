use axum::Router;
use c35_ctx::{AppState, OAuthStore};
use c35_mod_billing::{billing_http_client, billing_runtime_init, BillingRuntime};
use c35_store::PgPool;
use std::sync::Arc;
use tower_http::cors::CorsLayer;

use crate::config::Config;

pub fn router(cfg: Config, pool: PgPool, nats: Option<async_nats::Client>) -> Router {
    billing_runtime_init(BillingRuntime {
        midtrans_server_key: cfg.midtrans_server_key.clone(),
        midtrans_client_key: cfg.midtrans_client_key.clone(),
        midtrans_is_production: cfg.midtrans_is_production,
        midtrans_usd_idr: cfg.midtrans_usd_idr,
        http: billing_http_client(),
    });
    let cas_dir = cfg.cas_dir.clone();
    let _ = std::fs::create_dir_all(&cas_dir);
    let state = AppState {
        pool,
        nats,
        jwt_secret: cfg.jwt_secret,
        oauth: Arc::new(OAuthStore::default()),
        cas_secret: cfg.cas_secret,
        cas_dir,
        public_origin: cfg.public_origin,
    };
    c35_mod_channel::channel_runtime_init();
    c35_mod_mail::init();
    Router::new()
        .merge(c35_wire_http::router(state.clone()))
        .merge(c35_wire_ws::router(state))
        .layer(CorsLayer::permissive())
}
