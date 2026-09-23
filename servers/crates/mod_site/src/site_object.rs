use anyhow::{anyhow, Result};
use c35_proto::{
    ReqSiteObjectList, ReqSiteObjectPut, ResSiteObjectList, ResSiteObjectPut, SiteObject, sync_push,
};
use sqlx::PgPool;
use tokio::sync::mpsc;

use crate::grant::site_grant_check;
use crate::rows::object_from_row;
use crate::sync_push::site_sync_push;
use c35_proto::WsRes;
use c35_store::snowflake_id;

pub async fn site_object_list(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteObjectList,
) -> Result<ResSiteObjectList> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, false).await?;
    let rows = sqlx::query(
        r#"
        SELECT id, site_iid, client_id, name, code, kind, product_id,
               can_order, can_be_reserved, is_active, "desc", pic, meta_json,
               created_ts, updated_ts, deleted_ts
        FROM site.object
        WHERE site_iid = $1 AND deleted_ts IS NULL
        ORDER BY sort_order, id
        "#,
    )
    .bind(req.site_iid)
    .fetch_all(pool)
    .await?;
    Ok(ResSiteObjectList {
        objs: rows.iter().map(object_from_row).collect(),
    })
}

pub async fn site_object_upsert(
    pool: &PgPool,
    owner_iid: i64,
    site_iid: i64,
    obj: &SiteObject,
    out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<i64> {
    let id = if obj.id > 0 { obj.id } else { snowflake_id() };
    let meta_json: serde_json::Value = if obj.meta_json.is_empty() {
        serde_json::json!({})
    } else {
        serde_json::from_str(&obj.meta_json).unwrap_or(serde_json::json!({}))
    };
    let product_id = if obj.product_id > 0 {
        Some(obj.product_id)
    } else {
        None
    };
    let mut tx = pool.begin().await?;
    sqlx::query(
        r#"
        INSERT INTO site.object (
            id, site_iid, owner_iid, client_id, name, code, kind, product_id,
            can_order, can_be_reserved, is_active, "desc", pic, meta_json,
            created_ts, updated_ts
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, NOW(), NOW())
        ON CONFLICT (id) DO UPDATE SET
          client_id = EXCLUDED.client_id, name = EXCLUDED.name, code = EXCLUDED.code,
          kind = EXCLUDED.kind, product_id = EXCLUDED.product_id,
          can_order = EXCLUDED.can_order, can_be_reserved = EXCLUDED.can_be_reserved,
          is_active = EXCLUDED.is_active, "desc" = EXCLUDED.desc, pic = EXCLUDED.pic,
          meta_json = EXCLUDED.meta_json, updated_ts = NOW(), deleted_ts = NULL
        "#,
    )
    .bind(id)
    .bind(site_iid)
    .bind(owner_iid)
    .bind(&obj.client_id)
    .bind(&obj.name)
    .bind(&obj.code)
    .bind(&obj.kind)
    .bind(product_id)
    .bind(obj.can_order)
    .bind(obj.can_be_reserved)
    .bind(obj.is_active)
    .bind(&obj.desc)
    .bind(&obj.pic)
    .bind(meta_json)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    if let Some(tx) = out_tx {
        site_sync_push(
            tx,
            sync_push::Body::SiteObject(SiteObject {
                id,
                site_iid,
                ..obj.clone()
            }),
        );
    }
    Ok(id)
}

pub async fn site_object_put(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteObjectPut,
    out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<ResSiteObjectPut> {
    let obj = req.obj.ok_or_else(|| anyhow!("obj required"))?;
    let site_iid = req.site_iid;
    let owner_iid = site_grant_check(pool, caller_iid, site_iid, true).await?;
    let id = site_object_upsert(pool, owner_iid, site_iid, &obj, out_tx).await?;
    Ok(ResSiteObjectPut { id })
}
