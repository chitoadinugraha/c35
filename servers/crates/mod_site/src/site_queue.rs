use anyhow::{anyhow, Result};
use c35_proto::{
    ReqSiteQueueAdvance, ReqSiteQueueList, ReqSiteQueuePut, ResSiteQueueAdvance, ResSiteQueueList,
    ResSiteQueuePut,
};
use c35_store::snowflake_id;
use serde_json::{json, Value};
use sqlx::{PgPool, Row};

use crate::grant::site_grant_check;
use crate::rows::queue_from_row;
use crate::site_config::{site_capabilities_get, site_capability_enabled};
use crate::site_publish::site_published;

const DEFAULT_QUEUE_ID: i64 = 1;

pub async fn site_queue_list(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteQueueList,
) -> Result<ResSiteQueueList> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, false).await?;
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
    .bind(req.site_iid)
    .fetch_all(pool)
    .await?;
    Ok(ResSiteQueueList {
        queues: rows.iter().map(queue_from_row).collect(),
    })
}

pub async fn site_queue_put(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteQueuePut,
) -> Result<ResSiteQueuePut> {
    let queue = req.queue.ok_or_else(|| anyhow!("queue required"))?;
    let site_iid = req.site_iid;
    let owner_iid = site_grant_check(pool, caller_iid, site_iid, true).await?;
    let queue_id = if queue.queue_id > 0 { queue.queue_id } else { DEFAULT_QUEUE_ID };
    let meta_json = if queue.meta_json.trim().is_empty() { "{}" } else { queue.meta_json.as_str() };
    sqlx::query(
        r#"
        INSERT INTO site.queue (
            site_iid, queue_id, owner_iid, name, mode, prefix,
            last_ticket_no, serving_ticket_no, is_active, meta_json,
            created_ts, updated_ts
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10::jsonb, NOW(), NOW())
        ON CONFLICT (site_iid, queue_id) DO UPDATE SET
            name = EXCLUDED.name,
            mode = EXCLUDED.mode,
            prefix = EXCLUDED.prefix,
            is_active = EXCLUDED.is_active,
            meta_json = EXCLUDED.meta_json,
            updated_ts = NOW(),
            deleted_ts = NULL
        "#,
    )
    .bind(site_iid)
    .bind(queue_id)
    .bind(owner_iid)
    .bind(queue.name.trim())
    .bind(if queue.mode.is_empty() { "fifo" } else { queue.mode.as_str() })
    .bind(&queue.prefix)
    .bind(queue.last_ticket_no)
    .bind(queue.serving_ticket_no)
    .bind(queue.is_active)
    .bind(meta_json)
    .execute(pool)
    .await?;
    Ok(ResSiteQueuePut { queue_id })
}

pub async fn site_queue_advance_serving(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteQueueAdvance,
) -> Result<ResSiteQueueAdvance> {
    let site_iid = req.site_iid;
    let _owner_iid = site_grant_check(pool, caller_iid, site_iid, true).await?;
    let queue_id = if req.queue_id > 0 { req.queue_id } else { DEFAULT_QUEUE_ID };
    let row = sqlx::query(
        r#"
        UPDATE site.queue
        SET serving_ticket_no = serving_ticket_no + 1, updated_ts = NOW()
        WHERE site_iid = $1 AND queue_id = $2 AND deleted_ts IS NULL
        RETURNING serving_ticket_no
        "#,
    )
    .bind(site_iid)
    .bind(queue_id)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("queue not found"))?;
    Ok(ResSiteQueueAdvance {
        serving_ticket_no: row.get("serving_ticket_no"),
    })
}

pub struct GuestQueueTakeResult {
    pub ok: bool,
    pub ticket_id: i64,
    pub ticket_no: i32,
    pub queue_id: i64,
    pub serving_ticket_no: i32,
    pub error: String,
}

pub struct GuestQueueGetResult {
    pub ok: bool,
    pub ticket_id: i64,
    pub ticket_no: i32,
    pub queue_id: i64,
    pub status: String,
    pub serving_ticket_no: i32,
    pub error: String,
}

pub async fn guest_queue_take(
    pool: &PgPool,
    site_iid: i64,
    queue_id: i64,
    guest_name: &str,
    guest_phone: &str,
) -> Result<GuestQueueTakeResult> {
    if site_iid <= 0 {
        return Ok(err_take("site_iid required"));
    }
    if !site_published(pool, site_iid).await? {
        return Ok(err_take("site not published"));
    }
    let caps = site_capabilities_get(pool, site_iid).await;
    if !site_capability_enabled(&caps, "queue") {
        return Ok(err_take("queue not enabled"));
    }
    let qid = if queue_id > 0 { queue_id } else { DEFAULT_QUEUE_ID };
    let owner_iid = guest_site_owner(pool, site_iid).await?;
    ensure_default_queue(pool, site_iid, owner_iid, qid).await?;

    let mut tx = pool.begin().await?;
    let row = sqlx::query(
        r#"
        UPDATE site.queue
        SET last_ticket_no = last_ticket_no + 1, updated_ts = NOW()
        WHERE site_iid = $1 AND queue_id = $2 AND deleted_ts IS NULL AND is_active = TRUE
        RETURNING last_ticket_no, serving_ticket_no
        "#,
    )
    .bind(site_iid)
    .bind(qid)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or_else(|| anyhow!("queue not found"))?;
    let ticket_no: i32 = row.get("last_ticket_no");
    let serving_ticket_no: i32 = row.get("serving_ticket_no");
    let ticket_id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO site.queue_ticket (
            site_iid, ticket_id, queue_id, owner_iid, ticket_no,
            guest_name, guest_phone, status, created_ts, updated_ts
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, 'waiting', NOW(), NOW())
        "#,
    )
    .bind(site_iid)
    .bind(ticket_id)
    .bind(qid)
    .bind(owner_iid)
    .bind(ticket_no)
    .bind(guest_name.trim())
    .bind(guest_phone.trim())
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    Ok(GuestQueueTakeResult {
        ok: true,
        ticket_id,
        ticket_no,
        queue_id: qid,
        serving_ticket_no,
        error: String::new(),
    })
}

pub async fn guest_queue_get(
    pool: &PgPool,
    site_iid: i64,
    queue_id: i64,
    ticket_id: i64,
) -> Result<GuestQueueGetResult> {
    if site_iid <= 0 || ticket_id <= 0 {
        return Ok(err_get("site_iid and ticket_id required"));
    }
    if !site_published(pool, site_iid).await? {
        return Ok(err_get("site not published"));
    }
    let caps = site_capabilities_get(pool, site_iid).await;
    if !site_capability_enabled(&caps, "queue") {
        return Ok(err_get("queue not enabled"));
    }
    let qid = if queue_id > 0 { queue_id } else { DEFAULT_QUEUE_ID };
    let ticket = sqlx::query(
        r#"
        SELECT t.ticket_no, t.status, q.serving_ticket_no
        FROM site.queue_ticket t
        JOIN site.queue q ON q.site_iid = t.site_iid AND q.queue_id = t.queue_id
        WHERE t.site_iid = $1 AND t.ticket_id = $2 AND t.queue_id = $3 AND t.deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .bind(ticket_id)
    .bind(qid)
    .fetch_optional(pool)
    .await?;
    let row = match ticket {
        Some(r) => r,
        None => return Ok(err_get("ticket not found")),
    };
    Ok(GuestQueueGetResult {
        ok: true,
        ticket_id,
        ticket_no: row.get("ticket_no"),
        queue_id: qid,
        status: row.get::<String, _>("status"),
        serving_ticket_no: row.get("serving_ticket_no"),
        error: String::new(),
    })
}

pub fn guest_queue_take_json(res: &GuestQueueTakeResult) -> Value {
    json!({
        "ok": res.ok,
        "ticket_id": res.ticket_id,
        "ticket_no": res.ticket_no,
        "queue_id": res.queue_id,
        "serving_ticket_no": res.serving_ticket_no,
        "error": res.error,
    })
}

pub fn guest_queue_get_json(res: &GuestQueueGetResult) -> Value {
    json!({
        "ok": res.ok,
        "ticket_id": res.ticket_id,
        "ticket_no": res.ticket_no,
        "queue_id": res.queue_id,
        "status": res.status,
        "serving_ticket_no": res.serving_ticket_no,
        "error": res.error,
    })
}

async fn ensure_default_queue(pool: &PgPool, site_iid: i64, owner_iid: i64, queue_id: i64) -> Result<()> {
    sqlx::query(
        r#"
        INSERT INTO site.queue (site_iid, queue_id, owner_iid, name, created_ts, updated_ts)
        VALUES ($1, $2, $3, 'Main', NOW(), NOW())
        ON CONFLICT (site_iid, queue_id) DO NOTHING
        "#,
    )
    .bind(site_iid)
    .bind(queue_id)
    .bind(owner_iid)
    .execute(pool)
    .await?;
    Ok(())
}

async fn guest_site_owner(pool: &PgPool, site_iid: i64) -> Result<i64> {
    let row = sqlx::query(
        r#"SELECT owner_iid FROM ai.identity WHERE id = $1 AND kind = 'site' AND deleted_ts IS NULL"#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("site not found"))?;
    Ok(row.get("owner_iid"))
}

fn err_take(msg: &str) -> GuestQueueTakeResult {
    GuestQueueTakeResult {
        ok: false,
        ticket_id: 0,
        ticket_no: 0,
        queue_id: 0,
        serving_ticket_no: 0,
        error: msg.into(),
    }
}

fn err_get(msg: &str) -> GuestQueueGetResult {
    GuestQueueGetResult {
        ok: false,
        ticket_id: 0,
        ticket_no: 0,
        queue_id: 0,
        status: String::new(),
        serving_ticket_no: 0,
        error: msg.into(),
    }
}
