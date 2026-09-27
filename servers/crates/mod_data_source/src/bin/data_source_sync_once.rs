//! One-shot: upsert a google_sheet data_source and run sync (dev / smoke).
use anyhow::{Context, Result};
use c35_mod_data_source::{
    config_merge_sheet_url, data_source_put, data_source_sync_run, sync_row_get, SOURCE_KIND_GOOGLE_SHEET,
};
use c35_store::{pool_connect, snowflake_id};
use reqwest::Client;
use serde_json::json;
use std::time::Duration;

#[tokio::main]
async fn main() -> Result<()> {
    let sheet_url = std::env::args().nth(1).unwrap_or_else(|| {
        "https://docs.google.com/spreadsheets/d/10irW_az5QXTV62A2YmHbfZLFofAQNQ9Xdr8XYgA6ge0/edit?usp=sharing"
            .into()
    });
    let owner_iid: i64 = std::env::var("C35_TEST_OWNER_IID")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(99000);
    let pool = pool_connect().await?;
    let http = Client::builder().timeout(Duration::from_secs(60)).build()?;
    let mut config = json!({});
    config_merge_sheet_url(&mut config, &sheet_url).context("parse sheet url")?;
    let id = snowflake_id();
    let id = data_source_put(
        &pool,
        owner_iid,
        id,
        None,
        SOURCE_KIND_GOOGLE_SHEET,
        "CLI sync smoke",
        &config,
    )
    .await?;
    data_source_sync_run(&http, &pool, id).await.context("sync_run")?;
    let meta = sync_row_get(&pool, id).await?.context("sync row missing after run")?;
    println!(
        "ok data_source_id={} owner_iid={} snapshot_hash={} row_count={}",
        id,
        owner_iid,
        meta.0,
        meta.1
    );
    Ok(())
}