//! Publish one guest site from draft → site.render (recompile HTML).
//!   cd servers
//!   $env:C35_TEST_DB='1'
//!   cargo run --example publish_site_guest -p c35_mod_site -- natepaperie 99000

use c35_mod_site::site_publish_from_draft;
use c35_store::pool_connect;
use sqlx::Row;

const DEFAULT_CALLER: i64 = 99_000;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    if std::env::var("C35_TEST_DB").ok().as_deref() != Some("1") {
        anyhow::bail!("set C35_TEST_DB=1 to run against the configured YB database");
    }
    let mut args: Vec<String> = std::env::args().skip(1).collect();
    let alien_id = args
        .first()
        .cloned()
        .ok_or_else(|| anyhow::anyhow!("usage: publish_site_guest <alien_id> [caller_iid]"))?;
    let caller_iid = args
        .get(1)
        .and_then(|s| s.parse().ok())
        .unwrap_or(DEFAULT_CALLER);

    let pool = pool_connect().await?;
    let row = sqlx::query(
        r#"
        SELECT id FROM ai.identity
        WHERE alien_id = $1 AND kind = 'site' AND deleted_ts IS NULL
        "#,
    )
    .bind(&alien_id)
    .fetch_optional(&pool)
    .await?
    .ok_or_else(|| anyhow::anyhow!("site not found: {alien_id}"))?;
    let site_iid: i64 = row.get("id");

    println!("publishing site_iid={site_iid} alien_id={alien_id} caller_iid={caller_iid} ...");
    let published = site_publish_from_draft(&pool, caller_iid, site_iid).await?;
    println!(
        "ok version_id={} render_hash={}",
        published.version_id,
        published.render_hash
    );
    Ok(())
}
