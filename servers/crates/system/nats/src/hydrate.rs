use anyhow::Context as _;
use async_nats::header::HeaderMap;
use async_nats::jetstream;
use async_nats::Client;
use chrono::{DateTime, Utc};
use sqlx::PgPool;

use super::streams::STREAM_TASK_SCHEDULE;

pub const HYDRATE_LOCK_K1: i32 = 0xC35;
pub const HYDRATE_LOCK_K2: i32 = 0x4E41;

#[derive(Debug, Default, Clone, Copy)]
pub struct HydrateCounts {
    pub schedules: u32,
    pub prompt_replay: u32,
    pub task_replay: u32,
}

pub async fn try_advisory_lock(pool: &PgPool) -> anyhow::Result<bool> {
    let row = sqlx::query_scalar::<_, bool>("SELECT pg_try_advisory_lock($1, $2)")
        .bind(HYDRATE_LOCK_K1)
        .bind(HYDRATE_LOCK_K2)
        .fetch_one(pool)
        .await?;
    Ok(row)
}

pub async fn advisory_unlock(pool: &PgPool) {
    let _ = sqlx::query("SELECT pg_advisory_unlock($1, $2)")
        .bind(HYDRATE_LOCK_K1)
        .bind(HYDRATE_LOCK_K2)
        .execute(pool)
        .await;
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

    let js = jetstream::new(client.clone());
    let mut count = 0u32;
    for row in rows {
        let schedule = match row.schedule_header() {
            Some(s) => s,
            None => continue,
        };
        let subject = format!("c35.schedule.task.{}", row.id);
        let target = format!("c35.task.fire.{}", row.id);
        let payload = serde_json::json!({
            "trigger_id": row.id,
            "task_id": row.task_id,
            "owner_iid": row.owner_iid,
            "device_iid": row.device_iid,
        });
        let mut headers = HeaderMap::new();
        headers.insert("Nats-Schedule", schedule);
        if row.kind == "cron" && !row.timezone.is_empty() {
            headers.insert("Nats-Schedule-Time-Zone", row.timezone.as_str());
        }
        headers.insert("Nats-Schedule-Target", target.as_str());
        headers.insert("Nats-Schedule-TTL", "24h");
        js.publish_with_headers(subject, headers, serde_json::to_vec(&payload)?.into())
            .await
            .with_context(|| format!("schedule publish trigger_id={}", row.id))?
            .await
            .with_context(|| format!("schedule ack trigger_id={} stream={}", row.id, STREAM_TASK_SCHEDULE))?;
        count += 1;
    }
    Ok(count)
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

impl TaskTriggerRow {
    fn schedule_header(&self) -> Option<String> {
        match self.kind.as_str() {
            "cron" if !self.cron_expr.is_empty() => Some(self.cron_expr.clone()),
            "once" => self
                .run_at
                .map(|t| format!("@at {}", t.to_rfc3339())),
            _ => None,
        }
    }
}
