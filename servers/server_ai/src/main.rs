mod boot;
mod config;

use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .without_time()
        .with_target(false)
        .compact()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .init();

    config::env_load();
    let cfg = config::Config::from_env()?;
    c35_trace::L!("c35 server_ai starting");

    let pool = c35_store::pool_connect().await?;
    if cfg.db_migrate {
        c35_store::migrate_apply(&pool).await?;
    }

    let app = boot::router(cfg.clone(), pool);
    let listener = tokio::net::TcpListener::bind(&cfg.listen).await?;
    c35_trace::L!(listen = %cfg.listen, "listening");
    axum::serve(listener, app).await?;
    Ok(())
}
