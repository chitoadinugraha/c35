use anyhow::{anyhow, Result};
use c35_proto::{
    ReqSiteDraftGet, ReqSiteDraftPut, ResSiteDraftGet, ResSiteDraftPut, SiteConfig, SiteDoc,
    SiteDraft, sync_push,
};
use chrono::Utc;
use sqlx::{PgPool, Row};
use tokio::sync::mpsc;

use crate::doc::{
    site_doc_ensure_product_grid, site_doc_from_json, site_doc_migrate_legacy_blocks, site_doc_to_json,
    site_doc_validate,
};
use crate::grant::site_grant_check;
use crate::site_config::{site_capabilities_get, site_capability_enabled};
use crate::site_publish::site_publish_pending_for_draft;
use crate::sync_push::site_sync_push;
use c35_proto::WsRes;

fn ts_ms(t: Option<chrono::DateTime<Utc>>) -> i64 {
    t.map(|x| x.timestamp_millis()).unwrap_or(0)
}

/// In-memory only: home `product_grid` when commerce is on and sellable products exist.
/// Matches editor preview (`siteEditorPreviewSyncCommerceCatalog`) without persisting draft.
pub async fn site_draft_prepare_commerce_grid_doc(pool: &PgPool, site_iid: i64, doc: &mut SiteDoc) {
    site_doc_migrate_legacy_blocks(doc);
    let caps = site_capabilities_get(pool, site_iid).await;
    if !site_capability_enabled(&caps, "commerce") {
        return;
    }
    if !site_has_sellable_products(pool, site_iid)
        .await
        .unwrap_or(false)
    {
        return;
    }
    site_doc_ensure_product_grid(doc);
}

async fn site_has_sellable_products(pool: &PgPool, site_iid: i64) -> Result<bool> {
    let exists = sqlx::query_scalar::<_, bool>(
        r#"
        SELECT EXISTS(
            SELECT 1 FROM site.product
            WHERE site_iid = $1 AND deleted_ts IS NULL
              AND is_archived = FALSE AND can_sell = TRUE
        )
        "#,
    )
    .bind(site_iid)
    .fetch_one(pool)
    .await?;
    Ok(exists)
}

/// When commerce is on and the site has sellable products, persist a home `product_grid` block if missing.
pub async fn site_draft_ensure_product_grid(
    pool: &PgPool,
    caller_iid: i64,
    site_iid: i64,
) -> Result<bool> {
    if site_iid <= 0 {
        return Ok(false);
    }
    let caps = site_capabilities_get(pool, site_iid).await;
    if !site_capability_enabled(&caps, "commerce") {
        return Ok(false);
    }
    if !site_has_sellable_products(pool, site_iid).await? {
        return Ok(false);
    }
    let owner_iid = match site_grant_check(pool, caller_iid, site_iid, true).await {
        Ok(o) => o,
        Err(_) => return Ok(false),
    };
    let draft_row = sqlx::query(
        r#"
        SELECT doc_json FROM site.draft
        WHERE site_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?;
    let doc_json: serde_json::Value = draft_row
        .map(|r| r.get("doc_json"))
        .unwrap_or_else(|| serde_json::json!({ "pages": [], "theme": {}, "meta": {} }));
    let mut doc = site_doc_from_json(&doc_json);
    if !site_doc_ensure_product_grid(&mut doc) {
        return Ok(false);
    }
    site_doc_validate(&doc)?;
    let next_json = site_doc_to_json(&doc)?;
    sqlx::query(
        r#"
        INSERT INTO site.config (site_iid, owner_iid, created_ts, updated_ts)
        VALUES ($1, $2, NOW(), NOW())
        ON CONFLICT (site_iid) DO NOTHING
        "#,
    )
    .bind(site_iid)
    .bind(owner_iid)
    .execute(pool)
    .await?;
    sqlx::query(
        r#"
        INSERT INTO site.draft (site_iid, owner_iid, doc_json, created_ts, updated_ts)
        VALUES ($1, $2, $3, NOW(), NOW())
        ON CONFLICT (site_iid) DO UPDATE SET
          doc_json = EXCLUDED.doc_json,
          owner_iid = EXCLUDED.owner_iid,
          updated_ts = NOW(),
          deleted_ts = NULL
        "#,
    )
    .bind(site_iid)
    .bind(owner_iid)
    .bind(next_json)
    .execute(pool)
    .await?;
    Ok(true)
}

pub async fn site_draft_get(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteDraftGet,
) -> Result<ResSiteDraftGet> {
    let owner_iid = site_grant_check(pool, caller_iid, req.site_iid, false).await?;
    let draft_row = sqlx::query(
        r#"
        SELECT site_iid, owner_iid, doc_json, created_ts, updated_ts, deleted_ts
        FROM site.draft WHERE site_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(req.site_iid)
    .fetch_optional(pool)
    .await?;
    let (draft_doc_json, draft) = if let Some(r) = draft_row {
        let doc_json: serde_json::Value = r.get("doc_json");
        let draft = SiteDraft {
            site_iid: r.get("site_iid"),
            owner_iid: r.get("owner_iid"),
            doc: Some(site_doc_from_json(&doc_json)),
            created_ts_ms: ts_ms(Some(r.get("created_ts"))),
            updated_ts_ms: ts_ms(Some(r.get("updated_ts"))),
            deleted_ts_ms: ts_ms(r.get("deleted_ts")),
        };
        (doc_json, draft)
    } else {
        let doc_json = serde_json::json!({
            "pages": [],
            "theme": {},
            "meta": {}
        });
        let draft = SiteDraft {
            site_iid: req.site_iid,
            owner_iid,
            doc: Some(site_doc_from_json(&doc_json)),
            ..Default::default()
        };
        (doc_json, draft)
    };
    let (publish_pending, draft_render_hash, published_render_hash) = site_publish_pending_for_draft(
        pool,
        req.site_iid,
        &draft_doc_json,
        draft.updated_ts_ms,
    )
    .await?;
    let config_row = sqlx::query(
        r#"
        SELECT site_iid, owner_iid, published_version_id, inventory_costing_method, tz,
               payroll_policy_json, presence_policy_json, capabilities_json,
               assistant_bot_iid, alien_id_changed_ts, created_ts, updated_ts, deleted_ts
        FROM site.config WHERE site_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(req.site_iid)
    .fetch_optional(pool)
    .await?;
    let config = config_row
        .map(|r| SiteConfig {
            site_iid: r.get("site_iid"),
            owner_iid: r.get("owner_iid"),
            published_version_id: r
                .try_get::<Option<String>, _>("published_version_id")
                .ok()
                .flatten()
                .unwrap_or_default(),
            inventory_costing_method: r.get("inventory_costing_method"),
            tz: r.get("tz"),
            payroll_policy_json: r.get::<serde_json::Value, _>("payroll_policy_json").to_string(),
            presence_policy_json: r
                .get::<serde_json::Value, _>("presence_policy_json")
                .to_string(),
            capabilities_json: r.get::<serde_json::Value, _>("capabilities_json").to_string(),
            assistant_bot_iid: crate::site_assistant::site_config_assistant_bot_iid_from_row(&r),
            alien_id_changed_ts_ms: ts_ms(r.get("alien_id_changed_ts")),
            created_ts_ms: ts_ms(Some(r.get("created_ts"))),
            updated_ts_ms: ts_ms(Some(r.get("updated_ts"))),
            deleted_ts_ms: ts_ms(r.get("deleted_ts")),
        })
        .unwrap_or_else(|| SiteConfig {
            site_iid: req.site_iid,
            owner_iid,
            ..Default::default()
        });
    Ok(ResSiteDraftGet {
        draft: Some(draft),
        config: Some(config),
        publish_pending,
        draft_render_hash,
        published_render_hash,
    })
}

pub async fn site_draft_put(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteDraftPut,
    out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<ResSiteDraftPut> {
    let draft = req
        .draft
        .ok_or_else(|| anyhow!("draft required"))?;
    let site_iid = draft.site_iid;
    if site_iid <= 0 {
        return Err(anyhow!("site_iid required"));
    }
    let owner_iid = site_grant_check(pool, caller_iid, site_iid, true).await?;
    let mut doc = draft
        .doc
        .ok_or_else(|| anyhow!("doc required"))?;
    if site_capability_enabled(
        &site_capabilities_get(pool, site_iid).await,
        "commerce",
    ) && site_has_sellable_products(pool, site_iid).await?
    {
        site_doc_ensure_product_grid(&mut doc);
    }
    site_doc_validate(&doc)?;
    let doc_json = site_doc_to_json(&doc)?;
    let mut tx = pool.begin().await?;
    sqlx::query(
        r#"
        INSERT INTO site.config (site_iid, owner_iid, created_ts, updated_ts)
        VALUES ($1, $2, NOW(), NOW())
        ON CONFLICT (site_iid) DO NOTHING
        "#,
    )
    .bind(site_iid)
    .bind(owner_iid)
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        r#"
        INSERT INTO site.draft (site_iid, owner_iid, doc_json, created_ts, updated_ts)
        VALUES ($1, $2, $3, NOW(), NOW())
        ON CONFLICT (site_iid) DO UPDATE SET
          doc_json = EXCLUDED.doc_json,
          owner_iid = EXCLUDED.owner_iid,
          updated_ts = NOW(),
          deleted_ts = NULL
        "#,
    )
    .bind(site_iid)
    .bind(owner_iid)
    .bind(doc_json)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    if let Some(tx) = out_tx {
        site_sync_push(
            tx,
            sync_push::Body::SiteDraft(SiteDraft {
                site_iid,
                owner_iid,
                doc: Some(doc),
                updated_ts_ms: Utc::now().timestamp_millis(),
                ..Default::default()
            }),
        );
    }
    Ok(ResSiteDraftPut { site_iid })
}
