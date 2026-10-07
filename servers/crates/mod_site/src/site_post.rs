use anyhow::{anyhow, Result};
use c35_proto::{
    ReqSitePostDelete, ReqSitePostList, ReqSitePostPut, ResSitePostDelete, ResSitePostList,
    ResSitePostPut, SitePost,
};
use serde_json::{json, Value};
use sqlx::{PgPool, Row};
use tokio::sync::mpsc;

use crate::grant::site_grant_check;
use crate::rows::post_from_row;
use c35_proto::WsRes;
use c35_store::snowflake_id;

pub const SITE_POST_BOOT_CAP: i32 = 20;

pub async fn site_post_list(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSitePostList,
) -> Result<ResSitePostList> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, false).await?;
    let rows = sqlx::query(
        r#"
        SELECT site_iid, post_id, sort_order, title, caption, body, media_json,
               on_storefront, thumb, feed_kind, created_ts, updated_ts, deleted_ts
        FROM site.post
        WHERE site_iid = $1 AND deleted_ts IS NULL
        ORDER BY sort_order, post_id
        "#,
    )
    .bind(req.site_iid)
    .fetch_all(pool)
    .await?;
    Ok(ResSitePostList {
        posts: rows.iter().map(post_from_row).collect(),
    })
}

pub async fn site_post_upsert(
    pool: &PgPool,
    owner_iid: i64,
    site_iid: i64,
    post: &SitePost,
) -> Result<i64> {
    let post_id = if post.post_id > 0 { post.post_id } else { snowflake_id() };
    let media_json: Value = if post.media_json.is_empty() {
        json!([])
    } else {
        serde_json::from_str(&post.media_json).unwrap_or(json!([]))
    };
    if post.title.len() > 200 {
        return Err(anyhow!("title max 200 chars"));
    }
    if media_json.as_array().map(|a| a.len()).unwrap_or(0) > 10 {
        return Err(anyhow!("media max 10 items"));
    }
    let feed_kind = if post.feed_kind.is_empty() { "post" } else { post.feed_kind.as_str() };
    sqlx::query(
        r#"
        INSERT INTO site.post (
            site_iid, post_id, owner_iid, sort_order, title, caption, body,
            media_json, on_storefront, thumb, feed_kind, created_ts, updated_ts
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW(), NOW())
        ON CONFLICT (site_iid, post_id) DO UPDATE SET
          sort_order = EXCLUDED.sort_order, title = EXCLUDED.title, caption = EXCLUDED.caption,
          body = EXCLUDED.body, media_json = EXCLUDED.media_json,
          on_storefront = EXCLUDED.on_storefront, thumb = EXCLUDED.thumb,
          feed_kind = EXCLUDED.feed_kind, updated_ts = NOW(), deleted_ts = NULL
        "#,
    )
    .bind(site_iid)
    .bind(post_id)
    .bind(owner_iid)
    .bind(post.sort_order)
    .bind(&post.title)
    .bind(&post.caption)
    .bind(&post.body)
    .bind(media_json)
    .bind(post.on_storefront)
    .bind(&post.thumb)
    .bind(feed_kind)
    .execute(pool)
    .await?;
    Ok(post_id)
}

pub async fn site_post_put(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSitePostPut,
    _out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<ResSitePostPut> {
    let post = req.post.ok_or_else(|| anyhow!("post required"))?;
    let site_iid = req.site_iid;
    let owner_iid = site_grant_check(pool, caller_iid, site_iid, true).await?;
    let post_id = site_post_upsert(pool, owner_iid, site_iid, &post).await?;
    Ok(ResSitePostPut { post_id })
}

pub async fn site_post_delete(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSitePostDelete,
    _out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<ResSitePostDelete> {
    let site_iid = req.site_iid;
    let post_id = req.post_id;
    if site_iid <= 0 || post_id <= 0 {
        return Err(anyhow!("site_iid and post_id required"));
    }
    let _owner = site_grant_check(pool, caller_iid, site_iid, true).await?;
    let row = sqlx::query(
        r#"
        UPDATE site.post
        SET deleted_ts = NOW(), updated_ts = NOW()
        WHERE site_iid = $1 AND post_id = $2 AND deleted_ts IS NULL
        RETURNING site_iid, post_id
        "#,
    )
    .bind(site_iid)
    .bind(post_id)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("post {post_id} not found or already deleted"))?;
    let _: i64 = row.get("site_iid");
    Ok(ResSitePostDelete { post_id, ok: true })
}

pub async fn site_post_boot_summaries(pool: &PgPool, site_iid: i64) -> Result<Vec<SitePost>> {
    let rows = sqlx::query(
        r#"
        SELECT site_iid, post_id, sort_order, title, caption, body, media_json,
               on_storefront, thumb, feed_kind, created_ts, updated_ts, deleted_ts
        FROM site.post
        WHERE site_iid = $1 AND deleted_ts IS NULL AND on_storefront = TRUE
        ORDER BY sort_order, post_id
        LIMIT $2
        "#,
    )
    .bind(site_iid)
    .bind(SITE_POST_BOOT_CAP)
    .fetch_all(pool)
    .await?;
    Ok(rows.iter().map(post_from_row).collect())
}

pub async fn site_post_get_storefront(
    pool: &PgPool,
    site_iid: i64,
    post_id: i64,
) -> Result<Option<SitePost>> {
    let row = sqlx::query(
        r#"
        SELECT site_iid, post_id, sort_order, title, caption, body, media_json,
               on_storefront, thumb, feed_kind, created_ts, updated_ts, deleted_ts
        FROM site.post
        WHERE site_iid = $1 AND post_id = $2 AND deleted_ts IS NULL AND on_storefront = TRUE
        "#,
    )
    .bind(site_iid)
    .bind(post_id)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(|r| post_from_row(&r)))
}

pub async fn site_post_storefront_ids(pool: &PgPool, site_iid: i64) -> Result<Vec<i64>> {
    let rows = sqlx::query(
        r#"
        SELECT post_id FROM site.post
        WHERE site_iid = $1 AND deleted_ts IS NULL AND on_storefront = TRUE
        ORDER BY sort_order, post_id
        "#,
    )
    .bind(site_iid)
    .fetch_all(pool)
    .await?;
    Ok(rows.iter().map(|r| r.get::<i64, _>("post_id")).collect())
}

pub fn post_boot_summary_json(post: &SitePost) -> Value {
    let media = if post.media_json.is_empty() {
        json!([])
    } else {
        serde_json::from_str(&post.media_json).unwrap_or(json!([]))
    };
    let media_count = media.as_array().map(|a| a.len()).unwrap_or(0) as i64;
    let feed_kind = if post.feed_kind.is_empty() { "post" } else { post.feed_kind.as_str() };
    json!({
        "post_id": post.post_id,
        "title": post.title,
        "caption": post.caption,
        "thumb": post.thumb,
        "feed_kind": feed_kind,
        "media_count": media_count,
    })
}
