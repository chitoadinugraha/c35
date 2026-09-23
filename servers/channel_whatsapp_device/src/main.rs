mod config;
mod db;
mod manager;
mod media;
mod nats;
mod outbound;
mod routes;

use anyhow::Result;
use axum::Router;
use config::Config;
use manager::ChannelManager;
use nats::NatsService;
use routes::router;
use c35_store::pool_connect_url;
use std::sync::Arc;
use tokio::net::TcpListener;
use tower_http::cors::CorsLayer;
use tower_http::trace::TraceLayer;
use tracing::{info, warn};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt, EnvFilter};

#[derive(Clone)]
pub struct AppState {
    pub manager: ChannelManager,
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::registry()
        .with(EnvFilter::try_from_default_env().unwrap_or_else(|_| {
            "info,c35_channel_whatsapp_device=debug,whatsapp_rust=debug".into()
        }))
        .with(tracing_subscriber::fmt::layer().with_target(true))
        .init();

    info!("[wa-device] starting channel-whatsapp-device");
    let cfg = Config::from_env();
    info!(
        "[wa-device] config http={} sessions_dir={} poll={}s db={}",
        cfg.http_addr,
        cfg.sessions_dir,
        cfg.poll_interval_secs,
        cfg.yb_database
    );

    tokio::fs::create_dir_all(&cfg.sessions_dir).await?;

    let pool = pool_connect_url(&cfg.db_url()).await?;
    info!("[wa-device] Yugabyte connected");

    let nats = match NatsService::connect(
        &cfg.nats_url,
        cfg.nats_user.as_deref(),
        cfg.nats_pass.as_deref(),
        cfg.nats_ca.as_deref(),
    )
    .await
    {
        Ok(n) => Some(n),
        Err(e) => {
            warn!("[wa-device] NATS unavailable: {e:#}");
            None
        }
    };

    let manager = ChannelManager::new(pool, nats, cfg.sessions_dir.clone());
    manager.spawn_background_tasks(cfg.poll_interval_secs);

    let state = Arc::new(AppState { manager });
    let app: Router = router(state).layer(CorsLayer::permissive()).layer(TraceLayer::new_for_http());

    let listener = TcpListener::bind(&cfg.http_addr).await?;
    info!("[wa-device] listening on {}", cfg.http_addr);
    axum::serve(listener, app).await?;
    Ok(())
}
