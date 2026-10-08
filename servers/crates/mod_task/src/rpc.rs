use async_nats::Client;
use c35_mod_billing::{billing_account_ensure, billing_gate_with_hold_custom};
use c35_nats::user_app_subject_task_run;
use c35_proto::{
    pb_encode, ReqTaskList, ReqTaskPut, ReqTaskRunCancel, ReqTaskRunCancelDevice, ReqTaskRunList,
    ReqTaskRunStart, ResTaskList, ResTaskPut, ResTaskRunCancel, ResTaskRunCancelDevice,
    ResTaskRunList, ResTaskRunStart, TaskRun, TaskRunPush,
};
use c35_proto::ActDeviceTaskRun;
use sqlx::PgPool;
use tracing::warn;

use crate::cancel::task_run_cancel_signal;
use crate::store::{
    task_delete, task_list, task_put, task_run_active_for_device, task_run_finish,
    task_run_get, task_run_list_for_task, task_run_mark_cancelled, task_run_update_progress,
};
use crate::worker::{task_worker_spawn, TASK_RUN_HOLD_USD};

pub fn task_run_push(nats: Option<&Client>, owner_iid: i64, run: &TaskRun) {
    if let Some(nc) = nats {
        let push = TaskRunPush { run: Some(run.clone()) };
        let subject = user_app_subject_task_run(owner_iid);
        let bytes = pb_encode(&push).into();
        let nc = nc.clone();
        tokio::spawn(async move {
            if let Err(e) = nc.publish(subject, bytes).await {
                warn!("task_run_push: {e}");
            }
        });
    }
}

pub async fn task_list_rpc(pool: &PgPool, owner_iid: i64, req: ReqTaskList) -> ResTaskList {
    let device_iid = req.device_iid;
    let tasks = task_list(pool, owner_iid, device_iid).await;
    ResTaskList { tasks }
}

pub async fn task_put_rpc(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    req: ReqTaskPut,
) -> Result<ResTaskPut, String> {
    let task = task_put(pool, owner_iid, req.task.as_ref().ok_or("task required")?).await?;
    if let Some(nc) = nats {
        for tr in &task.triggers {
            if tr.is_active {
                let schedule = match tr.kind {
                    2 if !tr.cron_expr.is_empty() => {
                        c35_nats::format_schedule_pattern("cron", &tr.cron_expr, None)
                    }
                    1 if tr.run_at_ms > 0 => {
                        let dt = chrono::DateTime::from_timestamp_millis(tr.run_at_ms);
                        c35_nats::format_schedule_pattern("once", "", dt)
                    }
                    _ => None,
                };
                if let Some(sched) = schedule {
                    if let Err(e) = c35_nats::task_schedule_arm(
                        nc,
                        tr.id,
                        task.id,
                        owner_iid,
                        task.device_iid,
                        &sched,
                        &tr.timezone,
                    )
                    .await
                    {
                        tracing::warn!(trigger_id = tr.id, error = format!("{:#}", e), "task_schedule_arm failed");
                    }
                }
            } else {
                let _ = c35_nats::task_schedule_disarm(nc, tr.id).await;
            }
        }
    }
    Ok(ResTaskPut { task: Some(task) })
}

pub async fn task_delete_rpc(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    task_id: i64,
) -> Result<bool, String> {
    let trigger_ids = task_delete(pool, owner_iid, task_id).await?;
    if let Some(nc) = nats {
        for tid in trigger_ids {
            let _ = c35_nats::task_schedule_disarm(nc, tid).await;
        }
    }
    Ok(true)
}

pub async fn task_run_start_rpc(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    req: ReqTaskRunStart,
) -> Result<ResTaskRunStart, String> {
    let device_iid = req.device_iid;
    if device_iid <= 0 {
        return Err("device_iid required".into());
    }
    let req_id = if req.req_id.is_empty() {
        format!("task_run.{}", c35_store::snowflake_id())
    } else {
        req.req_id.clone()
    };
    let billing_row = billing_account_ensure(pool, owner_iid)
        .await
        .map_err(|e| e.to_string())?;
    if let Err(e) =
        billing_gate_with_hold_custom(pool, owner_iid, &billing_row, &req_id, TASK_RUN_HOLD_USD).await
    {
        return Err(e.to_string());
    }
    let prompt = if !req.prompt.is_empty() {
        req.prompt.clone()
    } else if req.task_id > 0 {
        let row = sqlx::query_scalar::<_, String>(
            "SELECT prompt FROM ai.task WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL",
        )
        .bind(req.task_id)
        .bind(owner_iid)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
        row.ok_or("task not found")?
    } else {
        return Err("prompt or task_id required".into());
    };
    let run_id = c35_store::snowflake_id() as i64;
    sqlx::query(
        r#"
        INSERT INTO ai.task_run (
            id, owner_iid, device_iid, task_id, chat_id, req_id, status, prompt, skill_id, model
        ) VALUES ($1, $2, $3, $4, $5, $6, 'queued', $7, $8, $9)
        "#,
    )
    .bind(run_id)
    .bind(owner_iid)
    .bind(device_iid)
    .bind(req.task_id)
    .bind(req.chat_id)
    .bind(&req_id)
    .bind(&prompt)
    .bind(req.skill_id)
    .bind(&req.model)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;

    let act = ActDeviceTaskRun {
        run_id,
        device_iid,
        owner_iid,
        task_id: req.task_id,
        req_id: req_id.clone(),
        prompt: prompt.clone(),
        skill_id: req.skill_id,
        model: req.model.clone(),
        step_index: 0,
        chat_id: req.chat_id,
    };
    if let Some(nc) = nats {
        if let Err(e) = c35_mod_device::remote_agent_send_raw(Some(nc), device_iid, pb_encode(&act)).await {
            warn!("ActDeviceTaskRun notify: {e}");
        }
    }

    let recipe: serde_json::Value = serde_json::from_str(&prompt).unwrap_or(serde_json::Value::Null);
    let recipe_name = recipe.get("recipe").and_then(|v| v.as_str()).unwrap_or("");
    if recipe_name == "browser.sheet_row_backfill" {
        let pool_arc = std::sync::Arc::new(pool.clone());
        let nats_arc = nats.cloned().map(std::sync::Arc::new);
        task_worker_spawn(pool_arc, nats_arc, owner_iid, device_iid, run_id, req_id, prompt);
    } else {
        crate::store::task_run_set_running(pool, run_id).await;
    }

    let run = task_run_get(pool, owner_iid, run_id)
        .await
        .ok_or("run missing after insert")?;
    task_run_push(nats, owner_iid, &run);
    Ok(ResTaskRunStart { run: Some(run) })
}

pub async fn task_run_finish_rpc(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    run_id: i64,
    status: c35_proto::TaskRunStatus,
    summary: &str,
    error: &str,
) {
    let started_ts = sqlx::query_scalar::<_, Option<chrono::DateTime<chrono::Utc>>>(
        "SELECT started_ts FROM ai.task_run WHERE id = $1",
    )
    .bind(run_id)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten()
    .flatten();
    let duration_ms = started_ts
        .map(|t| (chrono::Utc::now() - t).num_milliseconds().max(0))
        .unwrap_or(0);

    task_run_finish(
        pool,
        run_id,
        status,
        summary,
        error,
        &serde_json::json!({}),
        duration_ms,
    )
    .await;

    let req_id = sqlx::query_scalar::<_, String>(
        "SELECT req_id FROM ai.task_run WHERE id = $1",
    )
    .bind(run_id)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten()
    .unwrap_or_default();
    if !req_id.is_empty() {
        let _ = crate::metrics::task_run_billing_settle(pool, owner_iid, &req_id, 0.0).await;
    }

    if let Some(run) = task_run_get(pool, owner_iid, run_id).await {
        task_run_push(nats, owner_iid, &run);
    }
}

pub async fn task_run_progress_store(
    pool: &PgPool,
    run_id: i64,
    meta: &serde_json::Value,
    summary: &str,
    step_index: i32,
) {
    task_run_update_progress(pool, run_id, meta, summary, step_index).await;
}

pub async fn task_run_cancel_rpc(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    req: ReqTaskRunCancel,
) -> Result<ResTaskRunCancel, String> {
    task_run_cancel_signal(req.run_id);
    task_run_mark_cancelled(pool, req.run_id).await;
    let run = task_run_get(pool, owner_iid, req.run_id)
        .await
        .ok_or("run not found")?;
    task_run_push(nats, owner_iid, &run);
    Ok(ResTaskRunCancel { run: Some(run) })
}

pub async fn task_run_cancel_device_rpc(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    req: ReqTaskRunCancelDevice,
) -> Result<ResTaskRunCancelDevice, String> {
    let ids = task_run_active_for_device(pool, owner_iid, req.device_iid).await;
    let mut runs = vec![];
    for id in ids {
        task_run_cancel_signal(id);
        task_run_mark_cancelled(pool, id).await;
        if let Some(run) = task_run_get(pool, owner_iid, id).await {
            task_run_push(nats, owner_iid, &run);
            runs.push(run);
        }
    }
    Ok(ResTaskRunCancelDevice {
        cancelled_count: runs.len() as i32,
        runs,
    })
}

pub async fn task_run_list_rpc(pool: &PgPool, owner_iid: i64, req: ReqTaskRunList) -> ResTaskRunList {
    let limit = if req.limit > 0 { req.limit } else { 20 };
    let runs = if req.task_id > 0 {
        task_run_list_for_task(pool, owner_iid, req.task_id, limit).await
    } else if req.device_iid > 0 {
        sqlx::query(
            r#"
            SELECT id, owner_iid, device_iid, task_id, trigger_id, chat_id, req_id, status,
                   prompt, skill_id, model, step_index, summary, error, lease_pod,
                   lease_expires_ts, started_ts, finished_ts, created_ts, updated_ts, deleted_ts,
                   meta_json, tokens_in, tokens_out, cost_usd::float8 AS cost_usd, duration_ms
            FROM ai.task_run
            WHERE owner_iid = $1 AND device_iid = $2 AND deleted_ts IS NULL
            ORDER BY created_ts DESC
            LIMIT $3
            "#,
        )
        .bind(owner_iid)
        .bind(req.device_iid)
        .bind(limit)
        .fetch_all(pool)
        .await
        .unwrap_or_default()
        .iter()
        .map(crate::store::row_to_task_run)
        .collect()
    } else {
        task_run_list_for_task(pool, owner_iid, 0, limit).await
    };
    ResTaskRunList { runs }
}
