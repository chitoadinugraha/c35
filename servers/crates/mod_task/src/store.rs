use c35_proto::{Task, TaskRun, TaskRunStatus};
use chrono::{DateTime, Utc};
use serde_json::Value;
use sqlx::{PgPool, Row};

fn ts_ms(opt: Option<DateTime<Utc>>) -> i64 {
    opt.map(|t| t.timestamp_millis()).unwrap_or(0)
}

fn status_from_db(s: &str) -> TaskRunStatus {
    match s {
        "queued" => TaskRunStatus::Queued,
        "leased" => TaskRunStatus::Leased,
        "running" => TaskRunStatus::Running,
        "done" => TaskRunStatus::Done,
        "failed" => TaskRunStatus::Failed,
        "cancelled" => TaskRunStatus::Cancelled,
        _ => TaskRunStatus::Unspecified,
    }
}

fn status_to_db(s: TaskRunStatus) -> &'static str {
    match s {
        TaskRunStatus::Queued => "queued",
        TaskRunStatus::Leased => "leased",
        TaskRunStatus::Running => "running",
        TaskRunStatus::Done => "done",
        TaskRunStatus::Failed => "failed",
        TaskRunStatus::Cancelled => "cancelled",
        _ => "queued",
    }
}

pub fn row_to_task_run(r: &sqlx::postgres::PgRow) -> TaskRun {
    let meta: Value = r.try_get("meta_json").unwrap_or(Value::Object(Default::default()));
    TaskRun {
        id: r.get("id"),
        owner_iid: r.get("owner_iid"),
        device_iid: r.get("device_iid"),
        task_id: r.get("task_id"),
        trigger_id: r.get("trigger_id"),
        chat_id: r.get("chat_id"),
        req_id: r.get("req_id"),
        status: status_from_db(&r.get::<String, _>("status")).into(),
        prompt: r.get("prompt"),
        skill_id: r.get("skill_id"),
        model: r.get("model"),
        step_index: r.get("step_index"),
        summary: r.get("summary"),
        error: r.get("error"),
        lease_pod: r.get("lease_pod"),
        lease_expires_ts_ms: ts_ms(r.get("lease_expires_ts")),
        started_ts_ms: ts_ms(r.get("started_ts")),
        finished_ts_ms: ts_ms(r.get("finished_ts")),
        created_ts_ms: ts_ms(r.get("created_ts")),
        updated_ts_ms: ts_ms(r.get("updated_ts")),
        deleted_ts_ms: ts_ms(r.get("deleted_ts")),
        meta_json: meta.to_string(),
        tokens_in: r.get("tokens_in"),
        tokens_out: r.get("tokens_out"),
        cost_usd: r.get::<f64, _>("cost_usd"),
        duration_ms: r.get("duration_ms"),
    }
}

pub async fn task_run_get(pool: &PgPool, owner_iid: i64, run_id: i64) -> Option<TaskRun> {
    let row = sqlx::query(
        r#"
        SELECT id, owner_iid, device_iid, task_id, trigger_id, chat_id, req_id, status,
               prompt, skill_id, model, step_index, summary, error, lease_pod,
               lease_expires_ts, started_ts, finished_ts, created_ts, updated_ts, deleted_ts,
               meta_json, tokens_in, tokens_out, cost_usd::float8 AS cost_usd, duration_ms
        FROM ai.task_run
        WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL
        "#,
    )
    .bind(run_id)
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten()?;
    Some(row_to_task_run(&row))
}

pub async fn task_run_update_progress(
    pool: &PgPool,
    run_id: i64,
    meta: &Value,
    summary: &str,
    step_index: i32,
) {
    let _ = sqlx::query(
        r#"
        UPDATE ai.task_run
        SET meta_json = $2::jsonb, summary = $3, step_index = $4, updated_ts = NOW()
        WHERE id = $1
        "#,
    )
    .bind(run_id)
    .bind(meta)
    .bind(summary)
    .bind(step_index)
    .execute(pool)
    .await;
}

pub async fn task_run_finish(
    pool: &PgPool,
    run_id: i64,
    status: TaskRunStatus,
    summary: &str,
    error: &str,
    meta: &Value,
    duration_ms: i64,
) {
    let st = status_to_db(status);
    let _ = sqlx::query(
        r#"
        UPDATE ai.task_run
        SET status = $2, summary = $3, error = $4, meta_json = $5::jsonb,
            finished_ts = NOW(), duration_ms = $6, updated_ts = NOW()
        WHERE id = $1
        "#,
    )
    .bind(run_id)
    .bind(st)
    .bind(summary)
    .bind(error)
    .bind(meta)
    .bind(duration_ms)
    .execute(pool)
    .await;
}

pub async fn task_run_set_running(pool: &PgPool, run_id: i64) {
    let _ = sqlx::query(
        r#"
        UPDATE ai.task_run
        SET status = 'running', started_ts = COALESCE(started_ts, NOW()), updated_ts = NOW()
        WHERE id = $1
        "#,
    )
    .bind(run_id)
    .execute(pool)
    .await;
}

pub async fn task_run_active_for_device(pool: &PgPool, owner_iid: i64, device_iid: i64) -> Vec<i64> {
    sqlx::query_scalar(
        r#"
        SELECT id FROM ai.task_run
        WHERE owner_iid = $1 AND device_iid = $2 AND deleted_ts IS NULL
          AND status IN ('queued', 'leased', 'running')
        ORDER BY created_ts
        "#,
    )
    .bind(owner_iid)
    .bind(device_iid)
    .fetch_all(pool)
    .await
    .unwrap_or_default()
}

pub async fn task_run_mark_cancelled(pool: &PgPool, run_id: i64) {
    let _ = sqlx::query(
        r#"
        UPDATE ai.task_run
        SET status = 'cancelled', finished_ts = NOW(), updated_ts = NOW(),
            summary = COALESCE(NULLIF(summary, ''), 'Cancelled')
        WHERE id = $1 AND status IN ('queued', 'leased', 'running')
        "#,
    )
    .bind(run_id)
    .execute(pool)
    .await;
}

// Task list/put minimal stubs for device scope
pub async fn task_list(
    pool: &PgPool,
    owner_iid: i64,
    device_iid: i64,
) -> Vec<Task> {
    let rows = sqlx::query(
        r#"
        SELECT id, owner_iid, device_iid, name, skill_id, prompt, model, is_active,
               created_ts, updated_ts, deleted_ts
        FROM ai.task
        WHERE owner_iid = $1 AND deleted_ts IS NULL
          AND ($2 = 0 OR device_iid = $2)
        ORDER BY updated_ts DESC
        LIMIT 200
        "#,
    )
    .bind(owner_iid)
    .bind(device_iid)
    .fetch_all(pool)
    .await
    .unwrap_or_default();
    rows.iter()
        .map(|r| Task {
            id: r.get("id"),
            owner_iid: r.get("owner_iid"),
            device_iid: r.get("device_iid"),
            name: r.get("name"),
            skill_id: r.get("skill_id"),
            prompt: r.get("prompt"),
            model: r.get("model"),
            is_active: r.get("is_active"),
            triggers: vec![],
            created_ts_ms: ts_ms(r.get("created_ts")),
            updated_ts_ms: ts_ms(r.get("updated_ts")),
            deleted_ts_ms: ts_ms(r.get("deleted_ts")),
        })
        .collect()
}

pub async fn task_put(pool: &PgPool, owner_iid: i64, task: &Task) -> Result<Task, String> {
    let id = if task.id > 0 {
        task.id
    } else {
        c35_store::snowflake_id() as i64
    };
    sqlx::query(
        r#"
        INSERT INTO ai.task (id, owner_iid, device_iid, scope, name, skill_id, prompt, model, is_active)
        VALUES ($1, $2, $3, 'device', $4, $5, $6, $7, $8)
        ON CONFLICT (id) DO UPDATE SET
            name = EXCLUDED.name, skill_id = EXCLUDED.skill_id, prompt = EXCLUDED.prompt,
            model = EXCLUDED.model, is_active = EXCLUDED.is_active, device_iid = EXCLUDED.device_iid,
            updated_ts = NOW()
        "#,
    )
    .bind(id)
    .bind(owner_iid)
    .bind(task.device_iid)
    .bind(&task.name)
    .bind(task.skill_id)
    .bind(&task.prompt)
    .bind(&task.model)
    .bind(task.is_active)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    let mut out = task.clone();
    out.id = id;
    out.owner_iid = owner_iid;
    Ok(out)
}

pub async fn task_run_list_for_task(pool: &PgPool, owner_iid: i64, task_id: i64, limit: i32) -> Vec<TaskRun> {
    let rows = sqlx::query(
        r#"
        SELECT id, owner_iid, device_iid, task_id, trigger_id, chat_id, req_id, status,
               prompt, skill_id, model, step_index, summary, error, lease_pod,
               lease_expires_ts, started_ts, finished_ts, created_ts, updated_ts, deleted_ts,
               meta_json, tokens_in, tokens_out, cost_usd::float8 AS cost_usd, duration_ms
        FROM ai.task_run
        WHERE owner_iid = $1 AND task_id = $2 AND deleted_ts IS NULL
        ORDER BY created_ts DESC
        LIMIT $3
        "#,
    )
    .bind(owner_iid)
    .bind(task_id)
    .bind(limit.max(1).min(100))
    .fetch_all(pool)
    .await
    .unwrap_or_default();
    rows.iter().map(row_to_task_run).collect()
}
