//! Seed grosirprakarya.com test site + domain verify + publish.
//!   $env:C35_TEST_DB='1'; cd servers; cargo run --example grosir_domain_setup -p c35_mod_site

use c35_mod_site::{site_domain_put, site_domain_verify, site_draft_put, site_publish_from_draft};
use c35_proto::{ReqSiteDomainPut, ReqSiteDomainVerify, ReqSiteDraftPut, SiteBlock, SiteDoc, SiteDomain, SiteDraft, SitePage};
use c35_store::{pool_connect, snowflake_id};
use sqlx::PgPool;

const OWNER: i64 = 99000;
const HOST: &str = "grosirprakarya.com";
const ALIEN: &str = "grosirprakarya";

async fn ensure_site(pool: &PgPool) -> Result<i64, String> {
    if let Some(id) = sqlx::query_scalar(
        "SELECT id FROM ai.identity WHERE alien_id = $1 AND kind = 'site' AND deleted_ts IS NULL",
    )
    .bind(ALIEN)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    {
        return Ok(id);
    }
    let site_iid = snowflake_id();
    sqlx::query(
        "INSERT INTO ai.identity (id, kind, type, alien_id, name, owner_iid, locale, tz, meta, is_active, created_ts, updated_ts)
         VALUES ($1,'site','', $2, 'Grosir Prakarya', $3, 'id_ID', 'Asia/Jakarta', '{}'::jsonb, TRUE, NOW(), NOW())",
    )
    .bind(site_iid)
    .bind(ALIEN)
    .bind(OWNER)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    let grant_id = snowflake_id();
    sqlx::query(
        "INSERT INTO ai.identity_grant (id, resource_iid, grantee_iid, role, is_pinned, created_ts, updated_ts)
         VALUES ($1, $2, $3, 'owner', TRUE, NOW(), NOW()) ON CONFLICT (resource_iid, grantee_iid) DO NOTHING",
    )
    .bind(grant_id)
    .bind(site_iid)
    .bind(OWNER)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    sqlx::query(
        "INSERT INTO site.config (site_iid, owner_iid, created_ts, updated_ts) VALUES ($1, $2, NOW(), NOW()) ON CONFLICT DO NOTHING",
    )
    .bind(site_iid)
    .bind(OWNER)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(site_iid)
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    if std::env::var("C35_TEST_DB").ok().as_deref() != Some("1") {
        anyhow::bail!("set C35_TEST_DB=1");
    }
    let pool = pool_connect().await?;
    let site_iid = ensure_site(&pool).await.map_err(|e| anyhow::anyhow!(e))?;
    println!("site_iid={} alien_id={}", site_iid, ALIEN);

    let doc = SiteDoc {
        pages: vec![SitePage {
            path: "/".into(),
            title: "Grosir Prakarya".into(),
            blocks: vec![
                SiteBlock {
                    id: "hero1".into(),
                    r#type: "hero".into(),
                    props_json: r#"{"title":"Grosir Prakarya","subtitle":"c35 custom domain test"}"#.into(),
                },
            ],
        }],
        theme_json: r##"{"accent":"#2563eb"}"##.into(),
        meta_json: "{}".into(),
    };
    site_draft_put(
        &pool,
        OWNER,
        ReqSiteDraftPut {
            skip_publish: false,
            draft: Some(SiteDraft {
                site_iid,
                doc: Some(doc),
                ..Default::default()
            }),
        },
        None,
    )
    .await?;
    let published = site_publish_from_draft(&pool, OWNER, site_iid).await?;
    println!("published version={} hash={}", published.version_id, published.render_hash);

    let domain_id = snowflake_id();
    site_domain_put(
        &pool,
        OWNER,
        ReqSiteDomainPut {
            site_iid,
            domain: Some(SiteDomain {
                id: domain_id,
                site_iid,
                hostname: HOST.into(),
                is_primary: true,
                ..Default::default()
            }),
        },
        None,
    )
    .await?;
    let ver = site_domain_verify(
        &pool,
        OWNER,
        ReqSiteDomainVerify {
            site_iid,
            domain_id,
            force_tls: true,
        },
        None,
    )
    .await?;
    println!(
        "verify dns={} tls={} err={}",
        ver.dns_verified,
        ver.tls_status,
        ver.error
    );
    if !ver.dns_verified {
        anyhow::bail!("DNS verify failed: {}", ver.error);
    }
    Ok(())
}
