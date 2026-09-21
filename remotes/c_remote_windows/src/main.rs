use tracing::info;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt, EnvFilter};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::registry()
        .with(EnvFilter::try_from_default_env().unwrap_or_else(|_| "info,c_remote_windows=debug".into()))
        .with(tracing_subscriber::fmt::layer().with_target(true))
        .init();

    let cli = std::env::args().any(|a| a == "--cli");
    info!("c_remote_windows cli={}", cli);
    c_remote_windows::pair_loop::pair_loop_run(cli).await?;
    Ok(())
}
