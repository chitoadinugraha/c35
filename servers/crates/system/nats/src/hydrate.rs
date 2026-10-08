use anyhow::Context as _;
use async_nats::header::HeaderMap;
use async_nats::jetstream;
use async_nats::Client;
use chrono::{DateTime, Utc};
use sqlx::pool::PoolConnection;
use sqlx::{PgPool, Postgres};

use super::streams::STREAM_TASK_SCHEDULE;

pub const HYDRATE_LOCK_K1: i32 = 0xC35;
pub const HYDRATE_LOCK_K2: i32 = 0x4E41;

#[derive(Debug, Default, Clone, Copy)]
pub struct HydrateCounts {
    pub schedules: u32,
    pub prompt_replay: u32,
    pub task_replay: u32,
}

/// Session-scoped advisory lock — unlock must use the same connection that acquired it.
pub struct HydrateAdvisoryLock {
    conn: PoolConnection<Postgres>,
}

impl HydrateAdvisoryLock {
    pub async fn try_acquire(pool: &PgPool) -> anyhow::Result<Option<Self>> {
        let mut conn = pool.acquire().await?;
        let got = sqlx::query_scalar::<_, bool>("SELECT pg_try_advisory_lock($1, $2)")
            .bind(HYDRATE_LOCK_K1)
            .bind(HYDRATE_LOCK_K2)
            .fetch_one(&mut *conn)
            .await?;
        Ok(got.then_some(Self { conn }))
    }

    pub async fn release(&mut self) {
        let _ = sqlx::query("SELECT pg_advisory_unlock($1, $2)")
            .bind(HYDRATE_LOCK_K1)
            .bind(HYDRATE_LOCK_K2)
            .execute(&mut *self.conn)
            .await;
    }
}

pub async fn try_advisory_lock(pool: &PgPool) -> anyhow::Result<bool> {
    Ok(HydrateAdvisoryLock::try_acquire(pool).await?.is_some())
}

pub async fn advisory_unlock(_pool: &PgPool) {
    tracing::debug!("advisory_unlock(pool) is deprecated; use HydrateAdvisoryLock::release on the lock holder");
}

fn table_missing(err: &sqlx::Error) -> bool {
    err.to_string().contains("does not exist")
}

pub async fn hydrate_task_schedules(client: &Client, pool: &PgPool) -> anyhow::Result<u32> {
    let rows = match sqlx::query_as::<_, TaskTriggerRow>(
        r#"
        SELECT
            tt.id,
            tt.task_id,
            tt.owner_iid,
            COALESCE(t.device_iid, 0) AS device_iid,
            tt.kind,
            tt.cron_expr,
            tt.timezone,
            tt.run_at
        FROM ai.task_trigger tt
        LEFT JOIN ai.task t ON t.id = tt.task_id
        WHERE tt.kind IN ('cron', 'once')
          AND tt.is_active
          AND tt.deleted_ts IS NULL
        "#,
    )
    .fetch_all(pool)
    .await
    {
        Ok(rows) => rows,
        Err(e) if table_missing(&e) => return Ok(0),
        Err(e) => return Err(e.into()),
    };

    let mut count = 0u32;
    for row in rows {
        let schedule = match row.schedule_header() {
            Some(s) => s,
            None => continue,
        };
        if let Err(e) = task_schedule_arm(
            client,
            row.id,
            row.task_id,
            row.owner_iid,
            row.device_iid,
            &schedule,
            &row.timezone,
        )
        .await
        {
            tracing::warn!(trigger_id = row.id, error = %e, "hydrate schedule publish failed");
            continue;
        }
        count += 1;
    }
    Ok(count)
}

pub async fn task_schedule_arm(
    client: &Client,
    trigger_id: i64,
    task_id: i64,
    owner_iid: i64,
    device_iid: i64,
    schedule: &str,
    timezone: &str,
) -> anyhow::Result<()> {
    let js = jetstream::new(client.clone());
    let subject = format!("c35.schedule.task.{}", trigger_id);
    let target = format!("c35.task.fire.{}", trigger_id);
    let payload = serde_json::json!({
        "trigger_id": trigger_id,
        "task_id": task_id,
        "owner_iid": owner_iid,
        "device_iid": device_iid,
    });
    let mut headers = HeaderMap::new();
    headers.insert("Nats-Schedule", schedule);
    if !timezone.is_empty() {
        headers.insert("Nats-Schedule-Time-Zone", timezone);
    }
    headers.insert("Nats-Schedule-Target", target.as_str());
    headers.insert("Nats-Schedule-TTL", "24h");
    js.publish_with_headers(subject, headers, serde_json::to_vec(&payload)?.into())
        .await
        .with_context(|| format!("schedule publish trigger_id={}", trigger_id))?
        .await
        .with_context(|| format!("schedule ack trigger_id={} stream={}", trigger_id, STREAM_TASK_SCHEDULE))?;
    Ok(())
}

pub async fn task_schedule_disarm(client: &Client, trigger_id: i64) -> anyhow::Result<()> {
    let js = jetstream::new(client.clone());
    let subject = format!("c35.schedule.task.{}", trigger_id);
    let config = serde_json::json!({
        "filter": subject,
    });
    let purge_subject = format!("STREAM.PURGE.{}", STREAM_TASK_SCHEDULE);
    let _: Result<serde_json::Value, _> = js.request(purge_subject, &config).await;
    Ok(())
}

struct TaskTriggerRow {
    id: i64,
    task_id: i64,
    owner_iid: i64,
    device_iid: i64,
    kind: String,
    cron_expr: String,
    timezone: String,
    run_at: Option<DateTime<Utc>>,
}

impl sqlx::FromRow<'_, sqlx::postgres::PgRow> for TaskTriggerRow {
    fn from_row(row: &sqlx::postgres::PgRow) -> sqlx::Result<Self> {
        use sqlx::Row;
        Ok(Self {
            id: row.try_get("id")?,
            task_id: row.try_get("task_id")?,
            owner_iid: row.try_get("owner_iid")?,
            device_iid: row.try_get("device_iid")?,
            kind: row.try_get("kind")?,
            cron_expr: row.try_get("cron_expr")?,
            timezone: row.try_get("timezone")?,
            run_at: row.try_get("run_at")?,
        })
    }
}

pub fn format_schedule_pattern(
    kind: &str,
    cron_expr: &str,
    run_at: Option<DateTime<Utc>>,
) -> Option<String> {
    match kind {
        "cron" => {
            let expr = cron_expr.trim();
            if expr.is_empty() {
                return None;
            }
            if expr.starts_with('@') {
                return Some(expr.to_string());
            }
            let parts: Vec<&str> = expr.split_whitespace().collect();
            if parts.len() == 5 {
                Some(format!("0 {}", expr))
            } else {
                Some(expr.to_string())
            }
        }
        "once" => run_at.map(|t| t.format("%S %M %H %d %m *").to_string()),
        _ => None,
    }
}

impl TaskTriggerRow {
    fn schedule_header(&self) -> Option<String> {
        format_schedule_pattern(&self.kind, &self.cron_expr, self.run_at)
    }
}
