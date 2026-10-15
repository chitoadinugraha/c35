use anyhow::{anyhow, Result};
use chrono::{DateTime, Datelike, NaiveTime, TimeZone, Timelike, Utc};
use chrono_tz::Tz;
use c35_proto::{
    ReqSiteQueueAdvance, ReqSiteQueueBoard, ReqSiteQueueCallNext, ReqSiteQueueList,
    ReqSiteQueuePut, ReqSiteQueueReset, ReqSiteQueueTicketList, ReqSiteQueueTicketSetStatus,
    ResSiteQueueAdvance, ResSiteQueueBoard, ResSiteQueueCallNext, ResSiteQueueList,
    ResSiteQueuePut, ResSiteQueueReset, ResSiteQueueTicketList, ResSiteQueueTicketSetStatus,
    SiteQueueBoard, SiteQueueRun, SiteQueueTicket,
};
use c35_store::snowflake_id;
use rand::Rng;
use serde_json::{json, Map, Value};
use sqlx::{PgPool, Row, Transaction};

use crate::grant::{site_grant_check, site_role_rank};
use crate::ts::{ts_ms, ts_ms_opt};
use crate::rows::queue_from_row;
use crate::site_config::{site_capabilities_get, site_capability_enabled};
use crate::site_publish::site_published;

const DEFAULT_QUEUE_ID: i64 = 1;
const QUEUE_SELECT: &str = r#"
    SELECT site_iid, queue_id, owner_iid, name, description, mode, prefix,
           last_ticket_no, serving_ticket_no, is_active, fields, take_online,
           reset_policy, sort_order, meta_json,
           created_ts, updated_ts, deleted_ts
    FROM site.queue
"#;

pub fn display_label_for_ticket(prefix: &str, ticket_no: i32) -> String {
    let num = format!("{:03}", ticket_no.max(0));
    let p = prefix.trim();
    if p.is_empty() { num } else { format!("{p}-{num}") }
}

pub fn validate_queue_answers(fields: &Value, answers: &Map<String, Value>) -> Result<(), String> {
    for field in fields.as_array().cloned().unwrap_or_default() {
        let name = field.get("name").and_then(|v| v.as_str()).unwrap_or("").trim();
        if name.is_empty() {
            continue;
        }
        let required = field.get("required").and_then(|v| v.as_bool()).unwrap_or(false);
        let text = answers.get(name).and_then(|v| v.as_str()).map(|s| s.trim()).unwrap_or("");
        if required && text.is_empty() {
            let label = field.get("label").and_then(|v| v.as_str()).unwrap_or(name);
            return Err(format!("{label} wajib diisi"));
        }
    }
    Ok(())
}

fn new_track_token() -> String {
    let id = snowflake_id();
    let suffix: u64 = rand::thread_rng().gen();
    format!("qt_{id:x}{suffix:016x}")
}

fn resolve_queue_id(queue_id: i64) -> i64 {
    if queue_id > 0 { queue_id } else { DEFAULT_QUEUE_ID }
}

pub async fn site_queue_list(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteQueueList,
) -> Result<ResSiteQueueList> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, false).await?;
    let rows = sqlx::query(
        r#"
        SELECT site_iid, queue_id, owner_iid, name, description, mode, prefix,
               last_ticket_no, serving_ticket_no, is_active, fields, take_online,
               reset_policy, sort_order, meta_json,
               created_ts, updated_ts, deleted_ts
        FROM site.queue
        WHERE site_iid = $1 AND deleted_ts IS NULL
        ORDER BY sort_order, queue_id
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
    let fields_json = if queue.fields_json.trim().is_empty() { "[]" } else { queue.fields_json.as_str() };
    let reset_json = if queue.reset_policy_json.trim().is_empty() {
        r#"{"mode":"daily","at":"00:00","timezone":"Asia/Jakarta"}"#
    } else {
        queue.reset_policy_json.as_str()
    };
    sqlx::query(
        r#"
        INSERT INTO site.queue (
            site_iid, queue_id, owner_iid, name, description, mode, prefix,
            last_ticket_no, serving_ticket_no, is_active, fields, take_online,
            reset_policy, sort_order, meta_json, created_ts, updated_ts
        ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11::jsonb,$12,$13::jsonb,$14,$15::jsonb,NOW(),NOW())
        ON CONFLICT (site_iid, queue_id) DO UPDATE SET
            name = EXCLUDED.name, description = EXCLUDED.description, mode = EXCLUDED.mode,
            prefix = EXCLUDED.prefix, is_active = EXCLUDED.is_active, fields = EXCLUDED.fields,
            take_online = EXCLUDED.take_online, reset_policy = EXCLUDED.reset_policy,
            sort_order = EXCLUDED.sort_order, meta_json = EXCLUDED.meta_json,
            updated_ts = NOW(), deleted_ts = NULL
        "#,
    )
    .bind(site_iid)
    .bind(queue_id)
    .bind(owner_iid)
    .bind(queue.name.trim())
    .bind(queue.description.trim())
    .bind(if queue.mode.is_empty() { "fifo" } else { queue.mode.as_str() })
    .bind(&queue.prefix)
    .bind(queue.last_ticket_no)
    .bind(queue.serving_ticket_no)
    .bind(queue.is_active)
    .bind(fields_json)
    .bind(queue.take_online)
    .bind(reset_json)
    .bind(queue.sort_order)
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
    let res = site_queue_call_next(
        pool,
        caller_iid,
        ReqSiteQueueCallNext {
            site_iid: req.site_iid,
            queue_id: req.queue_id,
        },
    )
    .await?;
    Ok(ResSiteQueueAdvance {
        serving_ticket_no: res.ticket.map(|t| t.ticket_no).unwrap_or(0),
    })
}

pub async fn site_queue_board(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteQueueBoard,
) -> Result<ResSiteQueueBoard> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, false).await?;
    Ok(ResSiteQueueBoard {
        board: Some(board_build(pool, req.site_iid, resolve_queue_id(req.queue_id)).await?),
    })
}

pub async fn site_queue_call_next(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteQueueCallNext,
) -> Result<ResSiteQueueCallNext> {
    let site_iid = req.site_iid;
    let owner_iid = site_grant_queue_staff(pool, caller_iid, site_iid).await?;
    let queue_id = resolve_queue_id(req.queue_id);
    let qrow = load_queue_row(pool, site_iid, queue_id).await?;
    let run = ensure_open_run(pool, site_iid, queue_id, owner_iid, &qrow.get::<Value, _>("reset_policy")).await?;
    let mut tx = pool.begin().await?;
    sqlx::query(
        "UPDATE site.queue_ticket SET status='skipped', done_at=NOW(), updated_ts=NOW()
         WHERE site_iid=$1 AND queue_id=$2 AND run_id=$3 AND status IN ('called','serving') AND deleted_ts IS NULL",
    )
    .bind(site_iid)
    .bind(queue_id)
    .bind(run.run_id)
    .execute(&mut *tx)
    .await?;
    let row = sqlx::query(
        "SELECT ticket_id, ticket_no, display_label, guest_name, guest_phone, answers, status, track_token,
                called_at, done_at, created_ts, updated_ts FROM site.queue_ticket
         WHERE site_iid=$1 AND queue_id=$2 AND run_id=$3 AND status='waiting' AND deleted_ts IS NULL
         ORDER BY ticket_no ASC LIMIT 1 FOR UPDATE SKIP LOCKED",
    )
    .bind(site_iid)
    .bind(queue_id)
    .bind(run.run_id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or_else(|| anyhow!("no waiting tickets"))?;
    let ticket_id: i64 = row.get("ticket_id");
    let ticket_no: i32 = row.get("ticket_no");
    sqlx::query("UPDATE site.queue_ticket SET status='called', called_at=NOW(), updated_ts=NOW() WHERE site_iid=$1 AND ticket_id=$2")
        .bind(site_iid)
        .bind(ticket_id)
        .execute(&mut *tx)
        .await?;
    set_run_serving(&mut tx, site_iid, run.run_id, queue_id, ticket_no).await?;
    tx.commit().await?;
    Ok(ResSiteQueueCallNext {
        ticket: Some(ticket_from_row(&row, site_iid, queue_id, run.run_id)),
    })
}

pub async fn site_queue_ticket_set_status(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteQueueTicketSetStatus,
) -> Result<ResSiteQueueTicketSetStatus> {
    let _ = site_grant_queue_staff(pool, caller_iid, req.site_iid).await?;
    let queue_id = resolve_queue_id(req.queue_id);
    let status = req.status.trim().to_lowercase();
    let row = sqlx::query(
        "UPDATE site.queue_ticket SET status=$4, updated_ts=NOW(),
         called_at=CASE WHEN $4 IN ('called','serving') AND called_at IS NULL THEN NOW() ELSE called_at END,
         done_at=CASE WHEN $4 IN ('done','skipped','cancelled') THEN NOW() ELSE done_at END
         WHERE site_iid=$1 AND ticket_id=$2 AND queue_id=$3 AND deleted_ts IS NULL
         RETURNING ticket_id, ticket_no, run_id, display_label, guest_name, guest_phone, answers, status,
                   track_token, called_at, done_at, created_ts, updated_ts",
    )
    .bind(req.site_iid)
    .bind(req.ticket_id)
    .bind(queue_id)
    .bind(&status)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("ticket not found"))?;
    let run_id: i64 = row.get("run_id");
    let ticket_no: i32 = row.get("ticket_no");
    if status == "called" || status == "serving" {
        let mut tx = pool.begin().await?;
        set_run_serving(&mut tx, req.site_iid, run_id, queue_id, ticket_no).await?;
        tx.commit().await?;
    }
    Ok(ResSiteQueueTicketSetStatus {
        ticket: Some(ticket_from_row(&row, req.site_iid, queue_id, run_id)),
    })
}

pub async fn site_queue_reset(pool: &PgPool, caller_iid: i64, req: ReqSiteQueueReset) -> Result<ResSiteQueueReset> {
    let owner_iid = site_grant_check(pool, caller_iid, req.site_iid, true).await?;
    let run = open_new_run(pool, req.site_iid, resolve_queue_id(req.queue_id), owner_iid, "manual").await?;
    Ok(ResSiteQueueReset { run_id: run.run_id })
}

pub async fn site_queue_ticket_list(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteQueueTicketList,
) -> Result<ResSiteQueueTicketList> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, false).await?;
    let queue_id = resolve_queue_id(req.queue_id);
    let limit = if req.limit <= 0 { 50 } else { req.limit.min(200) };
    let rows = sqlx::query(
        "SELECT ticket_id, ticket_no, run_id, display_label, guest_name, guest_phone, answers, status,
                track_token, called_at, done_at, created_ts, updated_ts
         FROM site.queue_ticket WHERE site_iid=$1 AND queue_id=$2 AND deleted_ts IS NULL
         ORDER BY ticket_no DESC LIMIT $3",
    )
    .bind(req.site_iid)
    .bind(queue_id)
    .bind(limit)
    .fetch_all(pool)
    .await?;
    Ok(ResSiteQueueTicketList {
        tickets: rows
            .iter()
            .map(|r| ticket_from_row(r, req.site_iid, queue_id, r.get("run_id")))
            .collect(),
    })
}

pub struct GuestQueueTakeResult {
    pub ok: bool,
    pub ticket_id: i64,
    pub ticket_no: i32,
    pub queue_id: i64,
    pub serving_ticket_no: i32,
    pub display_label: String,
    pub track_token: String,
    pub error: String,
}

pub struct GuestQueueGetResult {
    pub ok: bool,
    pub ticket_id: i64,
    pub ticket_no: i32,
    pub queue_id: i64,
    pub status: String,
    pub serving_ticket_no: i32,
    pub display_label: String,
    pub track_token: String,
    pub error: String,
}

pub struct GuestQueueTrackResult {
    pub ok: bool,
    pub ticket_id: i64,
    pub ticket_no: i32,
    pub queue_id: i64,
    pub status: String,
    pub serving_number: i32,
    pub position_ahead: i32,
    pub display_label: String,
    pub error: String,
}

pub async fn guest_queue_take(
    pool: &PgPool,
    site_iid: i64,
    queue_id: i64,
    guest_name: &str,
    guest_phone: &str,
    answers_json: &str,
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
    let qid = resolve_queue_id(queue_id);
    let owner_iid = guest_site_owner(pool, site_iid).await?;
    ensure_default_queue(pool, site_iid, owner_iid, qid).await?;
    let qrow = load_queue_row(pool, site_iid, qid).await?;
    if !qrow.get::<bool, _>("is_active") {
        return Ok(err_take("queue inactive"));
    }
    if !qrow.get::<bool, _>("take_online") {
        return Ok(err_take("queue take disabled"));
    }
    let answers: Map<String, Value> = if answers_json.trim().is_empty() {
        Map::new()
    } else {
        serde_json::from_str(answers_json).unwrap_or_default()
    };
    if let Err(msg) = validate_queue_answers(&qrow.get::<Value, _>("fields"), &answers) {
        return Ok(err_take(&msg));
    }
    let run = ensure_open_run(pool, site_iid, qid, owner_iid, &qrow.get::<Value, _>("reset_policy")).await?;
    let ticket_no = run.next_number;
    let display_label = display_label_for_ticket(&qrow.get::<String, _>("prefix"), ticket_no);
    let track_token = new_track_token();
    let ticket_id = snowflake_id();
    let mut tx = pool.begin().await?;
    sqlx::query(
        "INSERT INTO site.queue_ticket (site_iid, ticket_id, queue_id, run_id, owner_iid, ticket_no, track_token,
         display_label, guest_name, guest_phone, answers, status, created_ts, updated_ts)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11::jsonb,'waiting',NOW(),NOW())",
    )
    .bind(site_iid)
    .bind(ticket_id)
    .bind(qid)
    .bind(run.run_id)
    .bind(owner_iid)
    .bind(ticket_no)
    .bind(&track_token)
    .bind(&display_label)
    .bind(guest_name.trim())
    .bind(guest_phone.trim())
    .bind(Value::Object(answers).to_string())
    .execute(&mut *tx)
    .await?;
    bump_run_after_ticket(&mut tx, site_iid, run.run_id, ticket_no, qid).await?;
    tx.commit().await?;
    Ok(GuestQueueTakeResult {
        ok: true,
        ticket_id,
        ticket_no,
        queue_id: qid,
        serving_ticket_no: run.serving_number,
        display_label,
        track_token,
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
    let qid = resolve_queue_id(queue_id);
    let ticket = sqlx::query(
        "SELECT t.ticket_no, t.status, t.display_label, t.track_token, r.serving_number
         FROM site.queue_ticket t JOIN site.queue_run r ON r.site_iid=t.site_iid AND r.run_id=t.run_id
         WHERE t.site_iid=$1 AND t.ticket_id=$2 AND t.queue_id=$3 AND t.deleted_ts IS NULL",
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
        serving_ticket_no: row.get("serving_number"),
        display_label: row.get("display_label"),
        track_token: row.get("track_token"),
        error: String::new(),
    })
}

pub async fn guest_queue_track(pool: &PgPool, site_iid: i64, track_token: &str) -> Result<GuestQueueTrackResult> {
    let token = track_token.trim();
    if site_iid <= 0 || token.is_empty() {
        return Ok(err_track("site_iid and track_token required"));
    }
    if !site_published(pool, site_iid).await? {
        return Ok(err_track("site not published"));
    }
    if !site_capability_enabled(&site_capabilities_get(pool, site_iid).await, "queue") {
        return Ok(err_track("queue not enabled"));
    }
    let row = sqlx::query(
        "SELECT t.ticket_id, t.ticket_no, t.queue_id, t.status, t.display_label, t.run_id, r.serving_number
         FROM site.queue_ticket t JOIN site.queue_run r ON r.site_iid=t.site_iid AND r.run_id=t.run_id
         WHERE t.site_iid=$1 AND t.track_token=$2 AND t.deleted_ts IS NULL",
    )
    .bind(site_iid)
    .bind(token)
    .fetch_optional(pool)
    .await?;
    let row = match row {
        Some(r) => r,
        None => return Ok(err_track("ticket not found")),
    };
    let ticket_no: i32 = row.get("ticket_no");
    let ahead: i64 = sqlx::query_scalar(
        "SELECT COUNT(*)::bigint FROM site.queue_ticket WHERE site_iid=$1 AND queue_id=$2 AND run_id=$3
         AND status='waiting' AND ticket_no < $4 AND deleted_ts IS NULL",
    )
    .bind(site_iid)
    .bind(row.get::<i64, _>("queue_id"))
    .bind(row.get::<i64, _>("run_id"))
    .bind(ticket_no)
    .fetch_one(pool)
    .await?;
    Ok(GuestQueueTrackResult {
        ok: true,
        ticket_id: row.get("ticket_id"),
        ticket_no,
        queue_id: row.get("queue_id"),
        status: row.get("status"),
        serving_number: row.get("serving_number"),
        position_ahead: ahead as i32,
        display_label: row.get("display_label"),
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
        "display_label": res.display_label,
        "track_token": res.track_token,
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
        "display_label": res.display_label,
        "track_token": res.track_token,
        "error": res.error,
    })
}

pub fn guest_queue_track_json(res: &GuestQueueTrackResult) -> Value {
    json!({
        "ok": res.ok,
        "ticket_id": res.ticket_id,
        "ticket_no": res.ticket_no,
        "queue_id": res.queue_id,
        "status": res.status,
        "serving_number": res.serving_number,
        "position_ahead": res.position_ahead,
        "display_label": res.display_label,
        "error": res.error,
    })
}

struct OpenRun {
    run_id: i64,
    next_number: i32,
    serving_number: i32,
}

async fn load_queue_row(pool: &PgPool, site_iid: i64, queue_id: i64) -> Result<sqlx::postgres::PgRow> {
    sqlx::query(&format!("{QUEUE_SELECT} WHERE site_iid=$1 AND queue_id=$2 AND deleted_ts IS NULL"))
        .bind(site_iid)
        .bind(queue_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| anyhow!("queue not found"))
}

async fn ensure_open_run(pool: &PgPool, site_iid: i64, queue_id: i64, owner_iid: i64, policy: &Value) -> Result<OpenRun> {
    maybe_daily_reset(pool, site_iid, queue_id, owner_iid, policy).await?;
    if let Some(r) = sqlx::query(
        "SELECT run_id, next_number, serving_number FROM site.queue_run
         WHERE site_iid=$1 AND queue_id=$2 AND status='open' AND closed_ts IS NULL ORDER BY created_ts DESC LIMIT 1",
    )
    .bind(site_iid)
    .bind(queue_id)
    .fetch_optional(pool)
    .await?
    {
        return Ok(OpenRun {
            run_id: r.get("run_id"),
            next_number: r.get("next_number"),
            serving_number: r.get("serving_number"),
        });
    }
    open_new_run(pool, site_iid, queue_id, owner_iid, "open").await
}

async fn open_new_run(pool: &PgPool, site_iid: i64, queue_id: i64, owner_iid: i64, reason: &str) -> Result<OpenRun> {
    let mut tx = pool.begin().await?;
    sqlx::query(
        "UPDATE site.queue_run SET status='closed', closed_ts=NOW(), updated_ts=NOW(), reset_reason=$3
         WHERE site_iid=$1 AND queue_id=$2 AND status='open' AND closed_ts IS NULL",
    )
    .bind(site_iid)
    .bind(queue_id)
    .bind(reason)
    .execute(&mut *tx)
    .await?;
    let run_id = snowflake_id();
    sqlx::query(
        "INSERT INTO site.queue_run (site_iid, run_id, queue_id, owner_iid, next_number, serving_number, status, reset_reason, created_ts, updated_ts)
         VALUES ($1,$2,$3,$4,1,0,'open',$5,NOW(),NOW())",
    )
    .bind(site_iid)
    .bind(run_id)
    .bind(queue_id)
    .bind(owner_iid)
    .bind(reason)
    .execute(&mut *tx)
    .await?;
    sqlx::query("UPDATE site.queue SET last_ticket_no=0, serving_ticket_no=0, updated_ts=NOW() WHERE site_iid=$1 AND queue_id=$2")
        .bind(site_iid)
        .bind(queue_id)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    Ok(OpenRun {
        run_id,
        next_number: 1,
        serving_number: 0,
    })
}

async fn maybe_daily_reset(pool: &PgPool, site_iid: i64, queue_id: i64, owner_iid: i64, policy: &Value) -> Result<()> {
    if policy.get("mode").and_then(|v| v.as_str()) != Some("daily") {
        return Ok(());
    }
    let tz: Tz = policy
        .get("timezone")
        .and_then(|v| v.as_str())
        .unwrap_or("Asia/Jakarta")
        .parse()
        .unwrap_or(chrono_tz::Asia::Jakarta);
    let at = policy.get("at").and_then(|v| v.as_str()).unwrap_or("00:00");
    let boundary = day_boundary(tz, at)?;
    let created: DateTime<Utc> = sqlx::query_scalar(
        "SELECT created_ts FROM site.queue_run WHERE site_iid=$1 AND queue_id=$2 AND status='open' AND closed_ts IS NULL ORDER BY created_ts DESC LIMIT 1",
    )
    .bind(site_iid)
    .bind(queue_id)
    .fetch_optional(pool)
    .await?
    .unwrap_or_else(Utc::now);
    if created.with_timezone(&tz) < boundary {
        let _ = open_new_run(pool, site_iid, queue_id, owner_iid, "daily").await?;
    }
    Ok(())
}

fn day_boundary(tz: Tz, at_hhmm: &str) -> Result<DateTime<Tz>> {
    let t = NaiveTime::parse_from_str(at_hhmm, "%H:%M").or_else(|_| NaiveTime::parse_from_str(at_hhmm, "%H:%M:%S"))?;
    let now = Utc::now().with_timezone(&tz);
    let today = tz
        .with_ymd_and_hms(now.year(), now.month(), now.day(), t.hour(), t.minute(), 0)
        .single()
        .ok_or_else(|| anyhow!("bad boundary"))?;
    if now >= today {
        Ok(today)
    } else {
        let y = now.date_naive() - chrono::Duration::days(1);
        tz.with_ymd_and_hms(y.year(), y.month(), y.day(), t.hour(), t.minute(), 0)
            .single()
            .ok_or_else(|| anyhow!("bad boundary"))
    }
}

async fn bump_run_after_ticket(
    tx: &mut Transaction<'_, sqlx::Postgres>,
    site_iid: i64,
    run_id: i64,
    ticket_no: i32,
    queue_id: i64,
) -> Result<()> {
    sqlx::query("UPDATE site.queue_run SET next_number=GREATEST(next_number,$3+1), updated_ts=NOW() WHERE site_iid=$1 AND run_id=$2")
        .bind(site_iid)
        .bind(run_id)
        .bind(ticket_no)
        .execute(&mut **tx)
        .await?;
    sqlx::query("UPDATE site.queue SET last_ticket_no=GREATEST(last_ticket_no,$3), updated_ts=NOW() WHERE site_iid=$1 AND queue_id=$2")
        .bind(site_iid)
        .bind(queue_id)
        .bind(ticket_no)
        .execute(&mut **tx)
        .await?;
    Ok(())
}

async fn set_run_serving(
    tx: &mut Transaction<'_, sqlx::Postgres>,
    site_iid: i64,
    run_id: i64,
    queue_id: i64,
    ticket_no: i32,
) -> Result<()> {
    sqlx::query("UPDATE site.queue_run SET serving_number=$3, updated_ts=NOW() WHERE site_iid=$1 AND run_id=$2")
        .bind(site_iid)
        .bind(run_id)
        .bind(ticket_no)
        .execute(&mut **tx)
        .await?;
    sqlx::query("UPDATE site.queue SET serving_ticket_no=$3, updated_ts=NOW() WHERE site_iid=$1 AND queue_id=$2")
        .bind(site_iid)
        .bind(queue_id)
        .bind(ticket_no)
        .execute(&mut **tx)
        .await?;
    Ok(())
}

async fn board_build(pool: &PgPool, site_iid: i64, queue_id: i64) -> Result<SiteQueueBoard> {
    let qrow = load_queue_row(pool, site_iid, queue_id).await?;
    let queue = queue_from_row(&qrow);
    let owner_iid: i64 = qrow.get("owner_iid");
    let run = ensure_open_run(pool, site_iid, queue_id, owner_iid, &qrow.get::<Value, _>("reset_policy")).await?;
    let run_row = sqlx::query(
        "SELECT run_id, next_number, serving_number, status, reset_reason, created_ts, updated_ts, closed_ts
         FROM site.queue_run WHERE site_iid=$1 AND run_id=$2",
    )
    .bind(site_iid)
    .bind(run.run_id)
    .fetch_one(pool)
    .await?;
    let waiting = sqlx::query(
        "SELECT ticket_id, ticket_no, display_label, guest_name, guest_phone, answers, status, track_token,
                called_at, done_at, created_ts, updated_ts
         FROM site.queue_ticket WHERE site_iid=$1 AND queue_id=$2 AND run_id=$3 AND status='waiting' AND deleted_ts IS NULL
         ORDER BY ticket_no ASC LIMIT 100",
    )
    .bind(site_iid)
    .bind(queue_id)
    .bind(run.run_id)
    .fetch_all(pool)
    .await?
    .iter()
    .map(|r| ticket_from_row(r, site_iid, queue_id, run.run_id))
    .collect();
    Ok(SiteQueueBoard {
        queue: Some(queue),
        run: Some(run_from_row(&run_row, site_iid, queue_id)),
        waiting,
        called: latest_ticket(pool, site_iid, queue_id, run.run_id, "called").await?,
        serving: latest_ticket(pool, site_iid, queue_id, run.run_id, "serving").await?,
    })
}

async fn latest_ticket(
    pool: &PgPool,
    site_iid: i64,
    queue_id: i64,
    run_id: i64,
    status: &str,
) -> Result<Option<SiteQueueTicket>> {
    let row = sqlx::query(
        "SELECT ticket_id, ticket_no, display_label, guest_name, guest_phone, answers, status, track_token,
                called_at, done_at, created_ts, updated_ts
         FROM site.queue_ticket WHERE site_iid=$1 AND queue_id=$2 AND run_id=$3 AND status=$4 AND deleted_ts IS NULL
         ORDER BY ticket_no DESC LIMIT 1",
    )
    .bind(site_iid)
    .bind(queue_id)
    .bind(run_id)
    .bind(status)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(|r| ticket_from_row(&r, site_iid, queue_id, run_id)))
}

fn ticket_from_row(r: &sqlx::postgres::PgRow, site_iid: i64, queue_id: i64, run_id: i64) -> SiteQueueTicket {
    SiteQueueTicket {
        site_iid,
        ticket_id: r.get("ticket_id"),
        queue_id,
        run_id,
        ticket_no: r.get("ticket_no"),
        display_label: r.try_get("display_label").unwrap_or_default(),
        status: r.get("status"),
        guest_name: r.try_get("guest_name").unwrap_or_default(),
        guest_phone: r.try_get("guest_phone").unwrap_or_default(),
        answers_json: r
            .try_get::<Value, _>("answers")
            .ok()
            .map(|v| v.to_string())
            .unwrap_or_else(|| "{}".into()),
        track_token: r.try_get("track_token").unwrap_or_default(),
        called_at_ms: ts_ms_opt(r.try_get("called_at").ok().flatten()),
        done_at_ms: ts_ms_opt(r.try_get("done_at").ok().flatten()),
        created_ts_ms: ts_ms(r.get("created_ts")),
        updated_ts_ms: ts_ms(r.get("updated_ts")),
    }
}

fn run_from_row(r: &sqlx::postgres::PgRow, site_iid: i64, queue_id: i64) -> SiteQueueRun {
    SiteQueueRun {
        site_iid,
        run_id: r.get("run_id"),
        queue_id,
        next_number: r.get("next_number"),
        serving_number: r.get("serving_number"),
        status: r.get("status"),
        reset_reason: r.get("reset_reason"),
        created_ts_ms: ts_ms(r.get("created_ts")),
        updated_ts_ms: ts_ms(r.get("updated_ts")),
        closed_ts_ms: ts_ms_opt(r.try_get("closed_ts").ok().flatten()),
    }
}

async fn site_grant_queue_staff(pool: &PgPool, caller_iid: i64, site_iid: i64) -> Result<i64> {
    let row = sqlx::query(
        "SELECT i.owner_iid, g.role FROM ai.identity i
         LEFT JOIN ai.identity_grant g ON g.resource_iid=i.id AND g.grantee_iid=$2 AND g.deleted_ts IS NULL
         WHERE i.id=$1 AND i.kind='site' AND i.deleted_ts IS NULL",
    )
    .bind(site_iid)
    .bind(caller_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("site not found"))?;
    let owner_iid: i64 = row.get("owner_iid");
    if owner_iid == caller_iid {
        return Ok(owner_iid);
    }
    let role: Option<String> = row.try_get("role").ok().flatten();
    if site_role_rank(role.as_deref().unwrap_or("")) >= site_role_rank("staff") {
        return Ok(owner_iid);
    }
    Err(anyhow!("forbidden"))
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
        display_label: String::new(),
        track_token: String::new(),
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
        display_label: String::new(),
        track_token: String::new(),
        error: msg.into(),
    }
}

fn err_track(msg: &str) -> GuestQueueTrackResult {
    GuestQueueTrackResult {
        ok: false,
        ticket_id: 0,
        ticket_no: 0,
        queue_id: 0,
        status: String::new(),
        serving_number: 0,
        position_ahead: 0,
        display_label: String::new(),
        error: msg.into(),
    }
}
