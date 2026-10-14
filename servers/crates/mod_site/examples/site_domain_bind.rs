//! Attach + verify a custom domain on an existing site.
//!   $env:C35_TEST_DB='1'; cd servers
//!   cargo run --example site_domain_bind -p c35_mod_site -- grosirprakarya grosirprakarya.com 99000

use c35_mod_site::{site_domain_put, site_domain_verify};
use c35_proto::{ReqSiteDomainPut, ReqSiteDomainVerify, SiteDomain};
use c35_store::{pool_connect, snowflake_id};
use sqlx::Row;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    if std::env::var("C35_TEST_DB").ok().as_deref() != Some("1") {
        anyhow::bail!("set C35_TEST_DB=1");
    }
    let args: Vec<String> = std::env::args().skip(1).collect();
    let alien_id = args
        .first()
        .ok_or_else(|| anyhow::anyhow!("usage: site_domain_bind <alien_id> <hostname> [caller_iid]"))?;
    let hostname = args
        .get(1)
        .ok_or_else(|| anyhow::anyhow!("hostname required"))?;
    let caller_iid: i64 = args.get(2).and_then(|s| s.parse().ok()).unwrap_or(99_000);

    let pool = pool_connect().await?;
    let row = sqlx::query(
        "SELECT id FROM ai.identity WHERE alien_id = $1 AND kind = 'site' AND deleted_ts IS NULL",
    )
    .bind(alien_id)
    .fetch_optional(&pool)
    .await?
    .ok_or_else(|| anyhow::anyhow!("site not found: {alien_id}"))?;
    let site_iid: i64 = row.get("id");

    let existing = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT id FROM site.domain
        WHERE site_iid = $1 AND LOWER(hostname) = LOWER($2) AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(site_iid)
    .bind(hostname)
    .fetch_optional(&pool)
    .await?;

    let domain_id = if let Some(id) = existing {
        id
    } else {
        let id = snowflake_id();
        site_domain_put(
            &pool,
            caller_iid,
            ReqSiteDomainPut {
                site_iid,
                domain: Some(SiteDomain {
                    id,
                    site_iid,
                    hostname: hostname.clone(),
                    is_primary: true,
                    ..Default::default()
                }),
            },
            None,
        )
        .await?;
        id
    };

    let ver = site_domain_verify(
        &pool,
        caller_iid,
        ReqSiteDomainVerify {
            site_iid,
            domain_id,
            force_tls: true,
        },
        None,
    )
    .await?;
    println!(
        "site_iid={} domain_id={} dns={} tls={} err={}",
        site_iid,
        domain_id,
        ver.dns_verified,
        ver.tls_status,
        ver.error
    );
    if !ver.dns_verified {
        anyhow::bail!("DNS verify failed: {}", ver.error);
    }
    Ok(())
}
