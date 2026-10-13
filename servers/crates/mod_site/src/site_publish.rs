use anyhow::{anyhow, Result};
use blake3;
use c35_proto::{ReqSitePublish, ResSitePublish, SitePublish, sync_push};
use chrono::Utc;
use sqlx::{PgPool, Row};
use std::collections::HashMap;
use std::sync::{LazyLock, Mutex};
use tokio::sync::mpsc;

use crate::doc::site_doc_from_json;
use crate::grant::site_grant_check;
use crate::guest_renderer::guest_renderer_version_effective;
use crate::render::{publish_doc_render, render_etag};

pub fn render_bundle_hash(pages: &[(String, String)]) -> String {
    let mut hasher = blake3::Hasher::new();
    for (key, html) in pages {
        hasher.update(key.as_bytes());
        hasher.update(html.as_bytes());
    }
    hasher.finalize().to_hex().to_string()
}

async fn site_name_for_render(pool: &PgPool, site_iid: i64) -> String {
    let name_row = sqlx::query(
        r#"SELECT name FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL"#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();
    name_row
        .map(|r| r.get::<String, _>("name"))
        .unwrap_or_else(|| "Site".into())
}

/// Blake3 bundle hash for a draft doc (matches site.publish.render_hash on publish).
pub async fn site_draft_render_hash(
    pool: &PgPool,
    site_iid: i64,
    doc_json: &serde_json::Value,
) -> Result<String> {
    let site_name = site_name_for_render(pool, site_iid).await;
    let pages = publish_doc_render(pool, site_iid, doc_json, &site_name).await?;
    Ok(render_bundle_hash(&pages))
}

static DRAFT_RENDER_HASH_CACHE: LazyLock<Mutex<HashMap<(i64, i64), String>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));
const DRAFT_RENDER_HASH_CACHE_MAX: usize = 256;

async fn site_draft_render_hash_cached(
    pool: &PgPool,
    site_iid: i64,
    doc_json: &serde_json::Value,
    draft_updated_ts_ms: i64,
) -> Result<String> {
    if draft_updated_ts_ms > 0 {
        if let Some(hit) = DRAFT_RENDER_HASH_CACHE
            .lock()
            .ok()
            .and_then(|c| c.get(&(site_iid, draft_updated_ts_ms)).cloned())
        {
            return Ok(hit);
        }
    }
    let hash = site_draft_render_hash(pool, site_iid, doc_json).await?;
    if draft_updated_ts_ms > 0 {
        if let Ok(mut cache) = DRAFT_RENDER_HASH_CACHE.lock() {
            if cache.len() >= DRAFT_RENDER_HASH_CACHE_MAX {
                cache.clear();
            }
            cache.insert((site_iid, draft_updated_ts_ms), hash.clone());
        }
    }
    Ok(hash)
}

/// Stable fingerprint for draft doc JSON (used in unit tests; publish pending uses render hashes).
#[allow(dead_code)]
pub fn doc_json_fingerprint(doc_json: &serde_json::Value) -> String {
    let canonical = serde_json::to_string(doc_json).unwrap_or_default();
    blake3::hash(canonical.as_bytes()).to_hex().to_string()
}

pub async fn active_publish_render_hash(pool: &PgPool, site_iid: i64) -> Result<String> {
    let row = sqlx::query(
        r#"
        SELECT render_hash FROM site.publish
        WHERE site_iid = $1 AND is_active = TRUE AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?;
    Ok(row
        .map(|r| r.get::<String, _>("render_hash"))
        .unwrap_or_default())
}

/// Read-only publish status for the editor (draft render bundle vs active publish).
pub async fn site_publish_pending_for_draft(
    pool: &PgPool,
    site_iid: i64,
    doc_json: &serde_json::Value,
    draft_updated_ts_ms: i64,
) -> Result<(bool, String, String)> {
    let published_render_hash = active_publish_render_hash(pool, site_iid).await?;
    let draft_render_hash =
        site_draft_render_hash_cached(pool, site_iid, doc_json, draft_updated_ts_ms).await?;
    let publish_pending = if published_render_hash.is_empty() {
        true
    } else {
        draft_render_hash != published_render_hash
    };
    Ok((publish_pending, draft_render_hash, published_render_hash))
}
use crate::sync_push::site_sync_push;
use c35_proto::WsRes;
use c35_store::snowflake_id;

pub struct SitePublishFromDraftResult {
    pub version_id: String,
    pub render_hash: String,
    pub doc_json: serde_json::Value,
    pub owner_iid: i64,
}

pub async fn site_publish_from_draft(
    pool: &PgPool,
    caller_iid: i64,
    site_iid: i64,
) -> Result<SitePublishFromDraftResult> {
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
    let site_name = site_name_for_render(pool, site_iid).await;
    let version_id = format!("v{}", snowflake_id());
    let pages = publish_doc_render(pool, site_iid, &doc_json, &site_name).await?;
    let bundle_hash = render_bundle_hash(&pages);
    let guest_render_version = guest_renderer_version_effective(pool).await?;
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
        INSERT INTO site.config (site_iid, owner_iid, published_version_id, guest_render_version, created_ts, updated_ts)
        VALUES ($1, $2, $3, $4, NOW(), NOW())
        ON CONFLICT (site_iid) DO UPDATE SET
          published_version_id = EXCLUDED.published_version_id,
          guest_render_version = EXCLUDED.guest_render_version,
          updated_ts = NOW()
        "#,
    )
    .bind(site_iid)
    .bind(owner_iid)
    .bind(&version_id)
    .bind(guest_render_version)
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
    Ok(SitePublishFromDraftResult {
        version_id,
        render_hash: bundle_hash,
        doc_json,
        owner_iid,
    })
}

pub async fn site_publish(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSitePublish,
    out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<ResSitePublish> {
    let site_iid = req.site_iid;
    let result = site_publish_from_draft(pool, caller_iid, site_iid).await?;
    let doc = site_doc_from_json(&result.doc_json);
    let published_ts = Utc::now();
    let publish = SitePublish {
        site_iid,
        version_id: result.version_id.clone(),
        doc: Some(doc),
        render_hash: result.render_hash.clone(),
        published_ts_ms: published_ts.timestamp_millis(),
        is_active: true,
        ..Default::default()
    };
    if let Some(tx) = out_tx {
        site_sync_push(tx, sync_push::Body::SiteDraft(c35_proto::SiteDraft {
            site_iid,
            owner_iid: result.owner_iid,
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

pub fn guest_alien_id_key(alien_id: &str) -> String {
    alien_id.trim().trim_start_matches('@').to_lowercase()
}

pub async fn resolve_site_by_alien_id(pool: &PgPool, alien_id: &str) -> Result<i64> {
    let key = guest_alien_id_key(alien_id);
    if key.is_empty() {
        return Err(anyhow!("site not found"));
    }
    let row = sqlx::query(
        r#"
        SELECT id FROM ai.identity
        WHERE kind = 'site' AND alien_id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(&key)
    .fetch_optional(pool)
    .await?;
    if let Some(row) = row {
        return Ok(row.get("id"));
    }
    if let Ok(site_id) = key.parse::<i64>() {
        if let Some(row) = sqlx::query(
            r#"
            SELECT id FROM ai.identity
            WHERE kind = 'site' AND id = $1 AND deleted_ts IS NULL
            "#,
        )
        .bind(site_id)
        .fetch_optional(pool)
        .await?
        {
            return Ok(row.get("id"));
        }
    }
    Err(anyhow!("site not found"))
}

#[cfg(test)]
mod pending_tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn doc_json_fingerprint_stable() {
        let a = json!({"pages": [], "meta": {}});
        let b = json!({"pages": [], "meta": {}});
        assert_eq!(doc_json_fingerprint(&a), doc_json_fingerprint(&b));
        let c = json!({"pages": [{"path": "/"}], "meta": {}});
        assert_ne!(doc_json_fingerprint(&a), doc_json_fingerprint(&c));
    }

    #[test]
    fn guest_alien_id_key_normalizes() {
        assert_eq!(guest_alien_id_key(" NatePaperie "), "natepaperie");
        assert_eq!(guest_alien_id_key("@natepaperie"), "natepaperie");
    }
}
