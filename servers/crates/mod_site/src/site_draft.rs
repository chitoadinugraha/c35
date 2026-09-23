use anyhow::{anyhow, Result};
use c35_proto::{
    ReqSiteDraftGet, ReqSiteDraftPut, ResSiteDraftGet, ResSiteDraftPut, SiteConfig, SiteDraft,
    sync_push,
};
use chrono::Utc;
use sqlx::{PgPool, Row};
use tokio::sync::mpsc;

use crate::doc::{site_doc_from_json, site_doc_to_json, site_doc_validate};
use crate::grant::site_grant_check;
use crate::sync_push::site_sync_push;
use c35_proto::WsRes;

fn ts_ms(t: Option<chrono::DateTime<Utc>>) -> i64 {
    t.map(|x| x.timestamp_millis()).unwrap_or(0)
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
    let draft = if let Some(r) = draft_row {
        let doc_json: serde_json::Value = r.get("doc_json");
        SiteDraft {
            site_iid: r.get("site_iid"),
            owner_iid: r.get("owner_iid"),
            doc: Some(site_doc_from_json(&doc_json)),
            created_ts_ms: ts_ms(Some(r.get("created_ts"))),
            updated_ts_ms: ts_ms(Some(r.get("updated_ts"))),
            deleted_ts_ms: ts_ms(r.get("deleted_ts")),
        }
    } else {
        SiteDraft {
            site_iid: req.site_iid,
            owner_iid,
            doc: Some(site_doc_from_json(&serde_json::json!({
                "pages": [],
                "theme": {},
                "meta": {}
            }))),
            ..Default::default()
        }
    };
    let config_row = sqlx::query(
        r#"
        SELECT site_iid, owner_iid, published_version_id, inventory_costing_method, tz,
               payroll_policy_json, presence_policy_json, capabilities_json,
               alien_id_changed_ts, created_ts, updated_ts, deleted_ts
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
    let doc = draft
        .doc
        .ok_or_else(|| anyhow!("doc required"))?;
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
