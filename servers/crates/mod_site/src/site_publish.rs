use anyhow::{anyhow, Result};
use blake3;
use c35_proto::{ReqSitePublish, ResSitePublish, SitePublish, sync_push};
use chrono::Utc;
use sqlx::{PgPool, Row};
use tokio::sync::mpsc;

use crate::doc::site_doc_from_json;
use crate::grant::site_grant_check;
use crate::render::{publish_doc_render, render_etag};
use crate::sync_push::site_sync_push;
use c35_proto::WsRes;
use c35_store::snowflake_id;

pub async fn site_publish(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSitePublish,
    out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<ResSitePublish> {
    let site_iid = req.site_iid;
    let owner_iid = site_grant_check(pool, caller_iid, site_iid, true).await?;
    let draft_row = sqlx::query(
        r#"
        SELECT doc_json FROM site.draft
        WHERE site_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("draft not found"))?;
    let doc_json: serde_json::Value = draft_row.get("doc_json");
    let name_row = sqlx::query(
        r#"SELECT name FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL"#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?;
    let site_name = name_row
        .map(|r| r.get::<String, _>("name"))
        .unwrap_or_else(|| "Site".into());
    let version_id = format!("v{}", snowflake_id());
    let pages = publish_doc_render(pool, site_iid, &doc_json, &site_name).await?;
    let bundle_hash = {
        let mut hasher = blake3::Hasher::new();
        for (key, html) in &pages {
            hasher.update(key.as_bytes());
            hasher.update(html.as_bytes());
        }
        hasher.finalize().to_hex().to_string()
    };
    let doc = site_doc_from_json(&doc_json);
    let published_ts = Utc::now();
    let mut tx = pool.begin().await?;
    sqlx::query(
        r#"
        UPDATE site.publish SET is_active = FALSE, updated_ts = NOW()
        WHERE site_iid = $1 AND is_active = TRUE AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        r#"
        INSERT INTO site.publish (
            site_iid, version_id, owner_iid, doc_json, render_hash,
            published_ts, is_active, created_ts, updated_ts
        ) VALUES ($1, $2, $3, $4, $5, $6, TRUE, NOW(), NOW())
        "#,
    )
    .bind(site_iid)
    .bind(&version_id)
    .bind(owner_iid)
    .bind(&doc_json)
    .bind(&bundle_hash)
    .bind(published_ts)
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        r#"
        INSERT INTO site.config (site_iid, owner_iid, published_version_id, created_ts, updated_ts)
        VALUES ($1, $2, $3, NOW(), NOW())
        ON CONFLICT (site_iid) DO UPDATE SET
          published_version_id = EXCLUDED.published_version_id,
          updated_ts = NOW()
        "#,
    )
    .bind(site_iid)
    .bind(owner_iid)
    .bind(&version_id)
    .execute(&mut *tx)
    .await?;
    for (render_key, html) in &pages {
        let etag = render_etag(html);
        sqlx::query(
            r#"
            INSERT INTO site.render (site_iid, render_key, content_type, body, etag, created_ts, updated_ts)
            VALUES ($1, $2, 'text/html; charset=utf-8', $3, $4, NOW(), NOW())
            ON CONFLICT (site_iid, render_key) DO UPDATE SET
              body = EXCLUDED.body, etag = EXCLUDED.etag, updated_ts = NOW()
            "#,
        )
        .bind(site_iid)
        .bind(render_key)
        .bind(html.as_bytes())
        .bind(&etag)
        .execute(&mut *tx)
        .await?;
    }
    tx.commit().await?;
    let _ = c35_mod_hint::hint_invalidate_for_asset(pool, site_iid).await;
    let publish = SitePublish {
        site_iid,
        version_id,
        doc: Some(doc),
        render_hash: bundle_hash,
        published_ts_ms: published_ts.timestamp_millis(),
        is_active: true,
        ..Default::default()
    };
    if let Some(tx) = out_tx {
        site_sync_push(tx, sync_push::Body::SiteDraft(c35_proto::SiteDraft {
            site_iid,
            owner_iid,
            doc: publish.doc.clone(),
            updated_ts_ms: published_ts.timestamp_millis(),
            ..Default::default()
        }));
    }
    Ok(ResSitePublish {
        publish: Some(publish),
    })
}

pub async fn render_get(
    pool: &PgPool,
    site_iid: i64,
    render_key: &str,
) -> Result<Option<(Vec<u8>, String, String)>> {
    let row = sqlx::query(
        r#"
        SELECT body, etag, content_type FROM site.render
        WHERE site_iid = $1 AND render_key = $2
        "#,
    )
    .bind(site_iid)
    .bind(render_key)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(|r| {
        let body: Option<Vec<u8>> = r.get("body");
        (
            body.unwrap_or_default(),
            r.get::<String, _>("etag"),
            r.get::<String, _>("content_type"),
        )
    }))
}

pub async fn site_published(pool: &PgPool, site_iid: i64) -> Result<bool> {
    let row = sqlx::query(
        r#"
        SELECT 1 FROM site.publish
        WHERE site_iid = $1 AND is_active = TRUE AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?;
    Ok(row.is_some())
}

pub async fn resolve_site_by_alien_id(pool: &PgPool, alien_id: &str) -> Result<i64> {
    let row = sqlx::query(
        r#"
        SELECT id FROM ai.identity
        WHERE kind = 'site' AND alien_id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(alien_id)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("site not found"))?;
    Ok(row.get("id"))
}
