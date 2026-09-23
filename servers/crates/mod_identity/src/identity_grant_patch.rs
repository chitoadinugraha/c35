use anyhow::{anyhow, Result};
use c35_proto::{ReqIdentityGrantPatch, ResIdentityGrantPatch};
use c35_store::snowflake_id;
use serde_json::{json, Value};
use sqlx::{PgPool, Row};

use crate::identity_list::identity_list_row_get;

pub async fn identity_grant_patch(pool: &PgPool, caller_iid: i64, req: ReqIdentityGrantPatch) -> Result<ResIdentityGrantPatch> {
    let resource_iid = req.resource_iid;
    if resource_iid == 0 {
        return Err(anyhow!("resource_iid required"));
    }

    let row = sqlx::query(
        r#"
        SELECT i.owner_iid, i.kind,
               g.id AS grant_id, g.role, g.is_pinned, g.meta AS grant_meta
        FROM ai.identity i
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $2 AND g.deleted_ts IS NULL
        WHERE i.id = $1 AND i.deleted_ts IS NULL
        "#,
    )
    .bind(resource_iid)
    .bind(caller_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("identity not found"))?;

    let owner_iid: i64 = row.get("owner_iid");
    let kind: String = row.get("kind");
    let grant_id: Option<i64> = row.try_get("grant_id").ok();
    if owner_iid != caller_iid && grant_id.is_none() {
        return Err(anyhow!("identity not found"));
    }

    let grant_id = grant_id.unwrap_or_else(snowflake_id);
    let role: String = row
        .try_get::<Option<String>, _>("role")
        .ok()
        .flatten()
        .unwrap_or_else(|| if owner_iid == caller_iid { "admin".into() } else { "member".into() });
    let mut is_pinned: bool = row.try_get("is_pinned").unwrap_or(false);
    let mut grant_meta: Value = row
        .try_get::<Option<Value>, _>("grant_meta")
        .ok()
        .flatten()
        .unwrap_or_else(|| json!({}));

    if let Some(pinned) = req.is_pinned {
        is_pinned = pinned;
    }
    if let Some(sort_order) = req.sort_order {
        grant_meta["sort_order"] = json!(sort_order);
    }
    if let Some(archived) = req.archived {
        if archived {
            grant_meta["archived_ts_ms"] = json!(chrono::Utc::now().timestamp_millis());
        } else if let Some(obj) = grant_meta.as_object_mut() {
            obj.remove("archived_ts_ms");
        }
    }

    sqlx::query(
        r#"
        INSERT INTO ai.identity_grant (id, resource_iid, grantee_iid, role, is_pinned, meta, created_ts, updated_ts)
        VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
        ON CONFLICT (resource_iid, grantee_iid) DO UPDATE SET
            is_pinned = EXCLUDED.is_pinned,
            meta = EXCLUDED.meta,
            updated_ts = NOW(),
            deleted_ts = NULL
        "#,
    )
    .bind(grant_id)
    .bind(resource_iid)
    .bind(caller_iid)
    .bind(&role)
    .bind(is_pinned)
    .bind(&grant_meta)
    .execute(pool)
    .await?;

    if kind == "site" {
        let _ = c35_mod_hint::hint_invalidate(pool, caller_iid).await;
    }

    let row = identity_list_row_get(pool, caller_iid, resource_iid).await?;
    Ok(ResIdentityGrantPatch { row: Some(row) })
}
