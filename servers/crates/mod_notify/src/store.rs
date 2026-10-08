use anyhow::{bail, Result};
use chrono::{DateTime, Duration, Utc};
use serde_json::Value;
use sqlx::{PgPool, Row};

use crate::bus::NotifyNats;
use crate::deliver::notify_deliver;
use crate::validate::{validate_notify_put, NotifyPut, NotifyWhen};
use crate::FcmSend;
use c35_store::snowflake_id;

#[derive(Clone, Debug)]
pub struct NotifyItem {
    pub id: i64,
    pub owner_iid: i64,
    pub title: String,
    pub body: String,
    pub fire_at: DateTime<Utc>,
    pub status: String,
    pub channels: String,
    pub route_json: Value,
    pub req_id: String,
    pub created_ts: DateTime<Utc>,
    pub updated_ts: DateTime<Utc>,
    pub sent_ts: Option<DateTime<Utc>>,
    pub read_ts: Option<DateTime<Utc>>,
}

pub type NotifyRow = NotifyItem;

const ITEM_COLS: &str = "\
id, owner_iid, title, body, fire_at, status, channels, route_json::text AS route_text, \
req_id, created_ts, updated_ts, sent_ts, read_ts";

fn map_item(row: &sqlx::postgres::PgRow) -> Result<NotifyItem, sqlx::Error> {
    let route_text: String = row.try_get("route_text")?;
    let route_json = serde_json::from_str(&route_text).unwrap_or(Value::Null);
    Ok(NotifyItem {
        id: row.try_get("id")?,
        owner_iid: row.try_get("owner_iid")?,
        title: row.try_get("title")?,
        body: row.try_get("body")?,
        fire_at: row.try_get("fire_at")?,
        status: row.try_get("status")?,
        channels: row.try_get("channels")?,
        route_json,
        req_id: row.try_get("req_id")?,
        created_ts: row.try_get("created_ts")?,
        updated_ts: row.try_get("updated_ts")?,
        sent_ts: row.try_get("sent_ts")?,
        read_ts: row.try_get("read_ts")?,
    })
}

pub fn clamp_limit(limit: i32) -> i64 {
    if limit <= 0 {
        20
    } else {
        i64::from(limit).clamp(1, 50)
    }
}

pub async fn notify_put(
    pool: &PgPool,
    nats: Option<&c35_nats::Client>,
    fcm: &dyn FcmSend,
    put: NotifyPut,
) -> Result<NotifyRow> {
    validate_notify_put(&put)?;
    let id = snowflake_id();
    let now = Utc::now();
    match put.when {
        NotifyWhen::Turn => insert_row(pool, id, &put, now, "waiting", &put.req_id).await,
        NotifyWhen::Delay => {
            let immediate = put.delay_sec == 0 && put.fire_at.is_none();
            let fire_at = put
                .fire_at
                .unwrap_or_else(|| now + Duration::seconds(i64::from(put.delay_sec)));
            let row = insert_row(pool, id, &put, fire_at, "scheduled", &put.req_id).await?;
            if immediate {
                notify_deliver(pool, nats, fcm, id).await?;
                return load_row(pool, id)
                    .await?
                    .ok_or_else(|| anyhow::anyhow!("notify {id} missing after deliver"));
            }
            if let Some(bus) = nats {
                if let Err(e) = bus.publish_schedule(id, fire_at).await {
                    tracing::warn!(notify_id = id, error = %e, "notify schedule publish failed");
                }
            }
            Ok(row)
        }
    }
}

async fn insert_row(
    pool: &PgPool,
    id: i64,
    put: &NotifyPut,
    fire_at: DateTime<Utc>,
    status: &str,
    req_id: &str,
) -> Result<NotifyRow> {
    let route = put.route_json.to_string();
    let sql = format!(
        "INSERT INTO ai.notify \
            (id, owner_iid, title, body, fire_at, status, channels, route_json, req_id) \
         VALUES ($1, $2, $3, $4, $5, $6, '', $7::jsonb, $8) \
         RETURNING {ITEM_COLS}"
    );
    let row = sqlx::query(&sql)
        .bind(id)
        .bind(put.owner_iid)
        .bind(&put.title)
        .bind(&put.body)
        .bind(fire_at)
        .bind(status)
        .bind(&route)
        .bind(req_id)
        .fetch_one(pool)
        .await?;
    Ok(map_item(&row)?)
}

pub async fn load_row(pool: &PgPool, id: i64) -> Result<Option<NotifyRow>> {
    let sql = format!("SELECT {ITEM_COLS} FROM ai.notify WHERE id = $1 AND deleted_ts IS NULL");
    let row = sqlx::query(&sql).bind(id).fetch_optional(pool).await?;
    row.map(|r| map_item(&r).map_err(anyhow::Error::from))
        .transpose()
}

pub async fn notify_list(
    pool: &PgPool,
    owner_iid: i64,
    limit: i32,
    unread_only: bool,
) -> Result<Vec<NotifyItem>> {
    let limit = clamp_limit(limit);
    let sql = if unread_only {
        format!(
            "SELECT {ITEM_COLS} FROM ai.notify \
             WHERE owner_iid = $1 AND deleted_ts IS NULL AND status = 'sent' \
             ORDER BY created_ts DESC, id DESC \
             LIMIT $2"
        )
    } else {
        format!(
            "SELECT {ITEM_COLS} FROM ai.notify \
             WHERE owner_iid = $1 AND deleted_ts IS NULL \
             ORDER BY created_ts DESC, id DESC \
             LIMIT $2"
        )
    };
    let rows = sqlx::query(&sql)
        .bind(owner_iid)
        .bind(limit)
        .fetch_all(pool)
        .await?;
    rows.iter()
        .map(|r| map_item(r).map_err(anyhow::Error::from))
        .collect()
}

pub async fn notify_mark_read(pool: &PgPool, owner_iid: i64, ids: &[i64]) -> Result<i32> {
    let result = if ids.is_empty() {
        sqlx::query(
            "UPDATE ai.notify \
             SET status = 'read', read_ts = NOW(), updated_ts = NOW() \
             WHERE owner_iid = $1 AND status = 'sent' AND deleted_ts IS NULL",
        )
        .bind(owner_iid)
        .execute(pool)
        .await?
    } else {
        sqlx::query(
            "UPDATE ai.notify \
             SET status = 'read', read_ts = NOW(), updated_ts = NOW() \
             WHERE owner_iid = $1 AND id = ANY($2) AND status = 'sent' AND deleted_ts IS NULL",
        )
        .bind(owner_iid)
        .bind(ids)
        .execute(pool)
        .await?
    };
    Ok(i32::try_from(result.rows_affected()).unwrap_or(i32::MAX))
}

pub async fn notify_cancel(pool: &PgPool, owner_iid: i64, id: i64) -> Result<bool> {
    let row = sqlx::query(
        "UPDATE ai.notify \
         SET status = 'cancelled', updated_ts = NOW() \
         WHERE id = $1 AND owner_iid = $2 \
           AND status IN ('scheduled', 'waiting') \
           AND deleted_ts IS NULL \
         RETURNING id",
    )
    .bind(id)
    .bind(owner_iid)
    .fetch_optional(pool)
    .await?;
    Ok(row.is_some())
}

pub async fn app_presence_put(
    pool: &PgPool,
    owner_iid: i64,
    client_id: &str,
    resumed: bool,
) -> Result<()> {
    if client_id.is_empty() {
        bail!("empty client_id");
    }
    sqlx::query(
        "INSERT INTO ai.app_conn (owner_iid, client_id, resumed, updated_ts) \
         VALUES ($1, $2, $3, NOW()) \
         ON CONFLICT (owner_iid, client_id) DO UPDATE \
         SET resumed = EXCLUDED.resumed, updated_ts = NOW()",
    )
    .bind(owner_iid)
    .bind(client_id)
    .bind(resumed)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn app_presence_delete(pool: &PgPool, owner_iid: i64, client_id: &str) -> Result<()> {
    sqlx::query("DELETE FROM ai.app_conn WHERE owner_iid = $1 AND client_id = $2")
        .bind(owner_iid)
        .bind(client_id)
        .execute(pool)
        .await?;
    Ok(())
}

pub async fn fcm_token_put(
    pool: &PgPool,
    owner_iid: i64,
    client_id: &str,
    token: &str,
    platform: &str,
) -> Result<()> {
    if client_id.is_empty() {
        bail!("empty client_id");
    }
    if token.is_empty() {
        bail!("empty token");
    }
    if platform != "android" && platform != "ios" {
        bail!("platform must be android or ios");
    }
    sqlx::query(
        "INSERT INTO ai.fcm_token (owner_iid, client_id, token, platform, updated_ts) \
         VALUES ($1, $2, $3, $4, NOW()) \
         ON CONFLICT (owner_iid, client_id) DO UPDATE \
         SET token = EXCLUDED.token, platform = EXCLUDED.platform, updated_ts = NOW()",
    )
    .bind(owner_iid)
    .bind(client_id)
    .bind(token)
    .bind(platform)
    .execute(pool)
    .await?;
    Ok(())
}
