use anyhow::{anyhow, Result};
use c35_proto::{
    ReqSiteLinkDelete, ReqSiteLinkList, ReqSiteLinkPut, ResSiteLinkDelete, ResSiteLinkList,
    ResSiteLinkPut, SiteLink, sync_push,
};
use sqlx::PgPool;
use tokio::sync::mpsc;

use crate::grant::site_grant_check;
use crate::rows::link_from_row;
use crate::sync_push::site_sync_push;
use c35_proto::WsRes;
use c35_store::snowflake_id;

pub async fn site_link_list(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteLinkList,
) -> Result<ResSiteLinkList> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, false).await?;
    let rows = sqlx::query(
        r#"
        SELECT site_iid, link_id, sort_order, label, url, icon, is_pinned, active,
               created_ts, updated_ts, deleted_ts
        FROM site.link
        WHERE site_iid = $1 AND deleted_ts IS NULL
        ORDER BY sort_order, link_id
        "#,
    )
    .bind(req.site_iid)
    .fetch_all(pool)
    .await?;
    Ok(ResSiteLinkList {
        links: rows.iter().map(link_from_row).collect(),
    })
}

pub async fn site_link_upsert(
    pool: &PgPool,
    owner_iid: i64,
    site_iid: i64,
    link: &SiteLink,
    out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<i64> {
    let link_id = if link.link_id > 0 { link.link_id } else { snowflake_id() };
    let mut tx = pool.begin().await?;
    sqlx::query(
        r#"
        INSERT INTO site.link (
            site_iid, link_id, owner_iid, sort_order, label, url, icon,
            is_pinned, active, created_ts, updated_ts
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())
        ON CONFLICT (site_iid, link_id) DO UPDATE SET
          sort_order = EXCLUDED.sort_order, label = EXCLUDED.label, url = EXCLUDED.url,
          icon = EXCLUDED.icon, is_pinned = EXCLUDED.is_pinned, active = EXCLUDED.active,
          updated_ts = NOW(), deleted_ts = NULL
        "#,
    )
    .bind(site_iid)
    .bind(link_id)
    .bind(owner_iid)
    .bind(link.sort_order)
    .bind(&link.label)
    .bind(&link.url)
    .bind(&link.icon)
    .bind(link.is_pinned)
    .bind(link.active)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    if let Some(tx) = out_tx {
        site_sync_push(
            tx,
            sync_push::Body::SiteLink(SiteLink {
                site_iid,
                link_id,
                ..link.clone()
            }),
        );
    }
    Ok(link_id)
}

pub async fn site_link_put(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteLinkPut,
    out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<ResSiteLinkPut> {
    let link = req.link.ok_or_else(|| anyhow!("link required"))?;
    let site_iid = req.site_iid;
    let owner_iid = site_grant_check(pool, caller_iid, site_iid, true).await?;
    let link_id = site_link_upsert(pool, owner_iid, site_iid, &link, out_tx).await?;
    Ok(ResSiteLinkPut { link_id })
}

pub async fn site_link_delete(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteLinkDelete,
    out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<ResSiteLinkDelete> {
    let site_iid = req.site_iid;
    let link_id = req.link_id;
    if site_iid <= 0 || link_id <= 0 {
        return Err(anyhow!("site_iid and link_id required"));
    }
    let _owner_iid = site_grant_check(pool, caller_iid, site_iid, true).await?;
    let row = sqlx::query(
        r#"
        UPDATE site.link
        SET deleted_ts = NOW(), updated_ts = NOW()
        WHERE site_iid = $1 AND link_id = $2 AND deleted_ts IS NULL
        RETURNING site_iid, link_id, sort_order, label, url, icon, is_pinned, active,
                  created_ts, updated_ts, deleted_ts
        "#,
    )
    .bind(site_iid)
    .bind(link_id)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("link {link_id} not found or already deleted"))?;
    let deleted = link_from_row(&row);
    if let Some(tx) = out_tx {
        site_sync_push(tx, sync_push::Body::SiteLink(deleted));
    }
    Ok(ResSiteLinkDelete { link_id, ok: true })
}

pub async fn site_link_boot_rows(pool: &PgPool, site_iid: i64) -> Result<Vec<SiteLink>> {
    let rows = sqlx::query(
        r#"
        SELECT site_iid, link_id, sort_order, label, url, icon, is_pinned, active,
               created_ts, updated_ts, deleted_ts
        FROM site.link
        WHERE site_iid = $1 AND deleted_ts IS NULL AND active = TRUE
        ORDER BY sort_order, link_id
        "#,
    )
    .bind(site_iid)
    .fetch_all(pool)
    .await?;
    Ok(rows.iter().map(link_from_row).collect())
}
