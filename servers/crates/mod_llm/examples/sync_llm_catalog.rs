//! CLOUDFLARE_API_TOKEN=... DATABASE_URL=... cargo run -p c35_mod_llm --example sync_llm_catalog
use c35_mod_llm::{cf_gateway_config, cf_gateway_ready, llm_catalog_sync_force, runtime_config_reload};
use c35_store::pool_connect;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let pool = pool_connect().await?;
    runtime_config_reload(&pool).await;
    let cfg = cf_gateway_config();
    println!(
        "cf_gateway ready={} account_id={} token={}",
        cf_gateway_ready(),
        if cfg.account_id.is_empty() { "-" } else { &cfg.account_id },
        if cfg.api_token.is_empty() { "missing" } else { "set" }
    );
    let n = llm_catalog_sync_force(&pool).await?;
    println!("llm_catalog_sync_force: {} models", n);
    Ok(())
}
