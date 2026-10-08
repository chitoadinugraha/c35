use c35_proto::{Task, TaskRun, TaskRunStatus, TaskTrigger};
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
        duration_ms: r
            .try_get::<i32, _>("duration_ms")
            .map(|v| v as i64)
            .or_else(|_| r.try_get::<i64, _>("duration_ms"))
            .unwrap_or(0),
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
    .bind(duration_ms as i32)
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

fn trigger_kind_to_db(kind: i32) -> &'static str {
    match kind {
        1 => "once",
        2 => "cron",
        3 => "webhook",
        _ => "once",
    }
}

fn trigger_kind_from_db(kind: &str) -> i32 {
    match kind {
        "once" => 1,
        "cron" => 2,
        "webhook" => 3,
        _ => 1,
    }
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

    let mut tasks: Vec<Task> = rows.iter()
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
        .collect();

    let task_ids: Vec<i64> = tasks.iter().map(|t| t.id).collect();
    if !task_ids.is_empty() {
        let trigger_rows = sqlx::query(
            r#"
            SELECT id, task_id, owner_iid, kind, label, cron_expr, timezone, run_at, is_active,
                   created_ts, updated_ts, deleted_ts
            FROM ai.task_trigger
            WHERE owner_iid = $1 AND deleted_ts IS NULL AND task_id = ANY($2)
            ORDER BY created_ts ASC
            "#,
        )
        .bind(owner_iid)
        .bind(&task_ids)
        .fetch_all(pool)
        .await
        .unwrap_or_default();

        for tr in trigger_rows {
            let tid: i64 = tr.get("task_id");
            let kind_str: String = tr.get("kind");
            let trigger = TaskTrigger {
                id: tr.get("id"),
                task_id: tid,
                owner_iid: tr.get("owner_iid"),
                kind: trigger_kind_from_db(&kind_str),
                label: tr.get("label"),
                cron_expr: tr.get("cron_expr"),
                timezone: tr.get("timezone"),
                run_at_ms: ts_ms(tr.get("run_at")),
                webhook_secret: String::new(),
                is_active: tr.get("is_active"),
                created_ts_ms: ts_ms(tr.get("created_ts")),
                updated_ts_ms: ts_ms(tr.get("updated_ts")),
                deleted_ts_ms: ts_ms(tr.get("deleted_ts")),
            };
            if let Some(t) = tasks.iter_mut().find(|t| t.id == tid) {
                t.triggers.push(trigger);
            }
        }
    }

    tasks
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

    let mut saved_triggers = Vec::new();
    for trigger in &task.triggers {
        let trigger_id = if trigger.id > 0 {
            trigger.id
        } else {
            c35_store::snowflake_id() as i64
        };
        let kind_str = trigger_kind_to_db(trigger.kind);
        let run_at = if trigger.run_at_ms > 0 {
            DateTime::from_timestamp_millis(trigger.run_at_ms)
        } else {
            None
        };
        sqlx::query(
            r#"
            INSERT INTO ai.task_trigger (
                id, task_id, owner_iid, kind, label, cron_expr, timezone, run_at, is_active
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            ON CONFLICT (id) DO UPDATE SET
                label = EXCLUDED.label, cron_expr = EXCLUDED.cron_expr,
                timezone = EXCLUDED.timezone, run_at = EXCLUDED.run_at,
                is_active = EXCLUDED.is_active, updated_ts = NOW()
            "#,
        )
        .bind(trigger_id)
        .bind(id)
        .bind(owner_iid)
        .bind(kind_str)
        .bind(&trigger.label)
        .bind(&trigger.cron_expr)
        .bind(&trigger.timezone)
        .bind(run_at)
        .bind(trigger.is_active)
        .execute(pool)
        .await
        .map_err(|e| e.to_string())?;

        let mut st = trigger.clone();
        st.id = trigger_id;
        st.task_id = id;
        st.owner_iid = owner_iid;
        saved_triggers.push(st);
    }

    let mut out = task.clone();
    out.id = id;
    out.owner_iid = owner_iid;
    out.triggers = saved_triggers;
    Ok(out)
}

pub async fn task_delete(pool: &PgPool, owner_iid: i64, task_id: i64) -> Result<Vec<i64>, String> {
    sqlx::query(
        r#"
        UPDATE ai.task
        SET deleted_ts = NOW(), updated_ts = NOW()
        WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL
        "#,
    )
    .bind(task_id)
    .bind(owner_iid)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;

    let trigger_ids = sqlx::query_scalar::<_, i64>(
        r#"
        UPDATE ai.task_trigger
        SET deleted_ts = NOW(), updated_ts = NOW(), is_active = FALSE
        WHERE task_id = $1 AND owner_iid = $2 AND deleted_ts IS NULL
        RETURNING id
        "#,
    )
    .bind(task_id)
    .bind(owner_iid)
    .fetch_all(pool)
    .await
    .unwrap_or_default();

    Ok(trigger_ids)
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
