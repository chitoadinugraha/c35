use c35_mod_billing::FxRateFetchTask;
use c35_mod_chat::ContextIdleFetchTask;
use c35_mod_fetch::{fetcher_run, FetchCtx, FetchTask};
use c35_mod_llm::LlmCatalogFetchTask;
use c35_mod_platform::{cf_vendor_from_env, env_enabled, gcp_from_env, oci_from_env, wasabi_from_env};
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
    if oci_from_env().is_none() && env_enabled("OCI_VENDOR_BILL_ENABLED") {
        tracing::warn!("vendor_bill_oci skipped: check OCI_* env and OCI_PRIVATE_KEY_PATH");
    }
    for task in [
        oci_from_env(),
        gcp_from_env(),
        cf_vendor_from_env(),
        wasabi_from_env(),
    ]
    .into_iter()
    .flatten()
    {
        tracing::info!(task = task.name(), "vendor bill task registered");
        tasks.push(Box::new(task));
    }
    tracing::info!(tasks = tasks.len(), "c35_fetcher starting");
    fetcher_run(ctx, tasks).await;
}
