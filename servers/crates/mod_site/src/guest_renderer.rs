//! Guest HTML compiler generation -- independent of server deploy version.
//!
//! Bump [`GUEST_RENDERER_VERSION`] when guest compile output can change:
//! `mod_site` render/boot paths, `clients/web/static/site-guest/*`, overlay effects wired into guest HTML.

use anyhow::{anyhow, Result};
use sqlx::{PgPool, Row};
use tracing::warn;

use crate::render::{publish_doc_render, render_etag};
use crate::site_publish::render_bundle_hash;

/// Cluster target generation. Increment by 1 when guest renderer assets change; deploy syncs `ai.config`.
pub const GUEST_RENDERER_VERSION: i32 = 11;

pub const GUEST_RENDERER_CONFIG_KEY: &str = "site.guest_renderer_version";

/// Effective cluster generation: max(code constant, `ai.config` `version` field).
pub async fn guest_renderer_version_effective(pool: &PgPool) -> Result<i32> {
    let cfg: Option<i32> = sqlx::query_scalar(
        r#"SELECT (value->>'version')::int FROM ai.config WHERE key = $1"#,
    )
    .bind(GUEST_RENDERER_CONFIG_KEY)
    .fetch_optional(pool)
    .await?;
    Ok(cfg
        .map(|v| v.max(GUEST_RENDERER_VERSION))
        .unwrap_or(GUEST_RENDERER_VERSION))
}

/// Upsert `ai.config` to at least [`GUEST_RENDERER_VERSION`] (server boot).
pub async fn guest_renderer_sync_config(pool: &PgPool) -> Result<()> {
    let value = serde_json::json!({ "version": GUEST_RENDERER_VERSION });
    sqlx::query(
        r#"
        INSERT INTO ai.config (key, value, updated_at)
        VALUES ($1, $2, NOW())
        ON CONFLICT (key) DO UPDATE SET
          value = CASE
            WHEN (ai.config.value->>'version')::int IS NULL
              OR (ai.config.value->>'version')::int < $3
            THEN EXCLUDED.value
            ELSE ai.config.value
          END,
          updated_at = CASE
            WHEN (ai.config.value->>'version')::int IS NULL
              OR (ai.config.value->>'version')::int < $3
            THEN NOW()
            ELSE ai.config.updated_at
          END
        "#,
    )
    .bind(GUEST_RENDERER_CONFIG_KEY)
    .bind(value)
    .bind(GUEST_RENDERER_VERSION)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn site_guest_render_version_stored(pool: &PgPool, site_iid: i64) -> Result<i32> {
    let row: Option<i32> = sqlx::query_scalar(
        r#"SELECT guest_render_version FROM site.config WHERE site_iid = $1 AND deleted_ts IS NULL"#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?;
    Ok(row.unwrap_or(0))
}

/// Recompile all published HTML keys from the active `site.publish` snapshot and bump per-site version.
pub async fn site_render_refresh_published_bundle(
    pool: &PgPool,
    site_iid: i64,
    target_version: i32,
) -> Result<()> {
    let pub_row = sqlx::query(
        r#"
        SELECT doc_json, owner_iid FROM site.publish
        WHERE site_iid = $1 AND is_active = TRUE AND deleted_ts IS NULL
        ORDER BY published_ts DESC
        LIMIT 1
        "#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("published snapshot not found"))?;
    let doc_json: serde_json::Value = pub_row.get("doc_json");
    let owner_iid: i64 = pub_row.get("owner_iid");
    let site_name_row = sqlx::query(
        r#"SELECT name FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL"#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?;
    let site_name = site_name_row
        .map(|r| r.get::<String, _>("name"))
        .unwrap_or_else(|| "Site".into());
    let pages = publish_doc_render(pool, site_iid, &doc_json, &site_name).await?;
    let bundle_hash = render_bundle_hash(&pages);
    let mut tx = pool.begin().await?;
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
    sqlx::query(
        r#"
        UPDATE site.publish SET render_hash = $2, updated_ts = NOW()
        WHERE site_iid = $1 AND is_active = TRUE AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .bind(&bundle_hash)
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        r#"
        INSERT INTO site.config (site_iid, owner_iid, guest_render_version, created_ts, updated_ts)
        VALUES ($1, $2, $3, NOW(), NOW())
        ON CONFLICT (site_iid) DO UPDATE SET
          guest_render_version = EXCLUDED.guest_render_version,
          updated_ts = NOW()
        "#,
    )
    .bind(site_iid)
    .bind(owner_iid)
    .bind(target_version)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    Ok(())
}

/// Lazy upgrade: first visit after cluster renderer bump recompiles `site.render` for this site.
pub async fn site_guest_render_ensure_current(pool: &PgPool, site_iid: i64) -> Result<()> {
    let target = guest_renderer_version_effective(pool).await?;
    let stored = site_guest_render_version_stored(pool, site_iid).await?;
    if stored >= target {
        return Ok(());
    }
    let locked: bool = sqlx::query_scalar("SELECT pg_try_advisory_lock($1)")
        .bind(site_iid)
        .fetch_one(pool)
        .await?;
    if !locked {
        return Ok(());
    }
    let outcome = async {
        let stored = site_guest_render_version_stored(pool, site_iid).await?;
        if stored >= target {
            return Ok(());
        }
        site_render_refresh_published_bundle(pool, site_iid, target).await?;
        Ok(())
    }
    .await;
    let _ = sqlx::query("SELECT pg_advisory_unlock($1)")
        .bind(site_iid)
        .execute(pool)
        .await;
    if let Err(e) = outcome {
        warn!(
            "guest render refresh failed site_iid={} target_version={}: {:#}",
            site_iid, target, e
        );
        return Err(e);
    }
    Ok(())
}