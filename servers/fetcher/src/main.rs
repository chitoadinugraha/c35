use c35_mod_billing::FxRateFetchTask;
use c35_mod_chat::ContextIdleFetchTask;
use c35_mod_fetch::{fetcher_run, FetchCtx, FetchTask};
use c35_mod_llm::LlmCatalogFetchTask;
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")))
        .init();
    dotenvy::dotenv().ok();
    let pool = c35_store::pool_connect().await?;
    let nats = c35_nats::connect()
        .await
        .ok_or_else(|| anyhow::anyhow!("NATS required for c35_fetcher"))?;
    let http = reqwest::Client::new();
    let ctx = FetchCtx { pool, nats, http };
    let mut tasks: Vec<Box<dyn FetchTask>> = Vec::new();
    tasks.push(Box::new(FxRateFetchTask::from_env()));
    tasks.push(Box::new(LlmCatalogFetchTask));
    tasks.push(Box::new(ContextIdleFetchTask));
    tracing::info!(tasks = tasks.len(), "c35_fetcher starting");
    fetcher_run(ctx, tasks).await;
}
