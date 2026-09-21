use axum::Router;
use c35_ctx::{AppState, OAuthStore};
use c35_store::PgPool;
use std::sync::Arc;
use tower_http::cors::CorsLayer;

use crate::config::Config;

pub fn router(cfg: Config, pool: PgPool, nats: Option<async_nats::Client>) -> Router {
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
    Router::new()
        .merge(c35_wire_http::router(state.clone()))
        .merge(c35_wire_ws::router(state))
        .layer(CorsLayer::permissive())
}
