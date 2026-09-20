use axum::Router;
use c35_ctx::AppState;
use c35_store::PgPool;
use tower_http::cors::CorsLayer;

use crate::config::Config;

pub fn router(cfg: Config, pool: PgPool) -> Router {
    let state = AppState {
        pool,
        jwt_secret: cfg.jwt_secret,
    };
    Router::new()
        .merge(c35_wire_http::router(state.clone()))
        .merge(c35_wire_ws::router(state))
        .layer(CorsLayer::permissive())
}
