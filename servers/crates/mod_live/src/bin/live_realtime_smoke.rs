use anyhow::Context;
use std::path::PathBuf;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let repo = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../..");
    let _ = dotenvy::from_path(repo.join(".env.local"));
    let _ = dotenvy::from_path(repo.join(".env"));
    let _ = dotenvy::dotenv();
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(120))
        .build()
        .context("http client")?;
    let rows = c35_mod_live::smoke::run_all_parallel(&client).await?;
    if rows.iter().any(|r| !r.ok) {
        std::process::exit(1);
    }
    Ok(())
}