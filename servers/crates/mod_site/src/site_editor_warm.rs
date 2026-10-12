use anyhow::{anyhow, Result};
use c35_proto::{
    ReqSiteEditorWarm, ResSiteEditorWarm, SiteContact, SiteGrant, SiteLink, SiteObject, SitePost,
    SiteQueue, SiteWorkShift,
};
use sqlx::PgPool;

use crate::grant::site_grant_check;
use crate::rows::{contact_from_row, link_from_row, object_from_row, post_from_row, queue_from_row};
use crate::site_grant::site_grants_load_for_site;
use crate::site_hr::site_work_shifts_load;
use crate::site_draft::site_draft_ensure_product_grid;
use crate::site_product::site_product_list_page;

pub const SITE_EDITOR_WARM_PRODUCT_DEFAULT: i32 = 30;
pub const SITE_EDITOR_WARM_PRODUCT_MAX: i32 = 48;

/// Product page size for editor warm (default 30, capped at 48).
pub fn site_editor_warm_product_limit(product_limit: i32) -> i32 {
    if product_limit <= 0 {
        SITE_EDITOR_WARM_PRODUCT_DEFAULT
    } else {
        product_limit.min(SITE_EDITOR_WARM_PRODUCT_MAX)
    }
}

async fn link_rows(pool: &PgPool, site_iid: i64) -> Result<Vec<SiteLink>> {
    let rows = sqlx::query(
        r#"
        SELECT site_iid, link_id, sort_order, label, url, icon, is_pinned, active, display,
               created_ts, updated_ts, deleted_ts
        FROM site.link
        WHERE site_iid = $1 AND deleted_ts IS NULL
        ORDER BY sort_order, link_id
        "#,
    )
    .bind(site_iid)
    .fetch_all(pool)
    .await?;
    Ok(rows.iter().map(link_from_row).collect())
}

async fn contact_rows(pool: &PgPool, site_iid: i64) -> Result<Vec<SiteContact>> {
    let rows = sqlx::query(
        r#"
        SELECT site_iid, contact_id, name, phone, email, address, note,
               meta_json, is_archived, created_ts, updated_ts, deleted_ts
        FROM site.contact
        WHERE site_iid = $1 AND deleted_ts IS NULL
        ORDER BY name
        "#,
    )
    .bind(site_iid)
    .fetch_all(pool)
    .await?;
    Ok(rows.iter().map(contact_from_row).collect())
}

async fn post_rows(pool: &PgPool, site_iid: i64) -> Result<Vec<SitePost>> {
    let rows = sqlx::query(
        r#"
        SELECT site_iid, post_id, sort_order, title, caption, body, media_json,
               on_storefront, thumb, feed_kind, created_ts, updated_ts, deleted_ts
        FROM site.post
        WHERE site_iid = $1 AND deleted_ts IS NULL
        ORDER BY sort_order, post_id
        "#,
    )
    .bind(site_iid)
    .fetch_all(pool)
    .await?;
    Ok(rows.iter().map(post_from_row).collect())
}

async fn object_rows(pool: &PgPool, site_iid: i64) -> Result<Vec<SiteObject>> {
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
    .bind(site_iid)
    .fetch_all(pool)
    .await?;
    Ok(rows.iter().map(object_from_row).collect())
}

async fn queue_rows(pool: &PgPool, site_iid: i64) -> Result<Vec<SiteQueue>> {
    let rows = sqlx::query(
        r#"
        SELECT site_iid, queue_id, owner_iid, name, mode, prefix,
               last_ticket_no, serving_ticket_no, is_active, meta_json,
               created_ts, updated_ts, deleted_ts
        FROM site.queue
        WHERE site_iid = $1 AND deleted_ts IS NULL
        ORDER BY queue_id
        "#,
    )
    .bind(site_iid)
    .fetch_all(pool)
    .await?;
    Ok(rows.iter().map(queue_from_row).collect())
}

async fn grants_rows_if_manage(
    pool: &PgPool,
    site_iid: i64,
    manage_owner_iid: Option<i64>,
) -> Result<Vec<SiteGrant>> {
    match manage_owner_iid {
        Some(owner_iid) => site_grants_load_for_site(pool, site_iid, owner_iid).await,
        None => Ok(Vec::new()),
    }
}

async fn work_shifts_if_manage(
    pool: &PgPool,
    site_iid: i64,
    manage_owner_iid: Option<i64>,
) -> Result<Vec<SiteWorkShift>> {
    match manage_owner_iid {
        Some(_) => site_work_shifts_load(pool, site_iid).await,
        None => Ok(Vec::new()),
    }
}

pub async fn site_editor_warm(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteEditorWarm,
) -> Result<ResSiteEditorWarm> {
    let site_iid = req.site_iid;
    if site_iid <= 0 {
        return Err(anyhow!("site_iid required"));
    }
    let _ = site_grant_check(pool, caller_iid, site_iid, false).await?;
    let manage_owner_iid = site_grant_check(pool, caller_iid, site_iid, true).await.ok();
    let product_limit = site_editor_warm_product_limit(req.product_limit);

    let (links, contacts, posts, products_res, objects, queues, grants, shifts) = tokio::join!(
        link_rows(pool, site_iid),
        contact_rows(pool, site_iid),
        post_rows(pool, site_iid),
        site_product_list_page(pool, site_iid, product_limit, ""),
        object_rows(pool, site_iid),
        queue_rows(pool, site_iid),
        grants_rows_if_manage(pool, site_iid, manage_owner_iid),
        work_shifts_if_manage(pool, site_iid, manage_owner_iid),
    );

    let products_res = products_res?;
    if !products_res.products.is_empty() {
        let pool_bg = pool.clone();
        tokio::spawn(async move {
            let _ = site_draft_ensure_product_grid(&pool_bg, caller_iid, site_iid).await;
        });
    }
    Ok(ResSiteEditorWarm {
        links: links?,
        contacts: contacts?,
        posts: posts?,
        products: products_res.products,
        product_next_cursor: products_res.next_cursor,
        product_has_more: products_res.has_more,
        objs: objects?,
        grants: grants?,
        queues: queues?,
        work_shifts: shifts?,
    })
}
