use async_nats::Client;
use c35_proto::{
    ReqTaskList, ReqTaskPut, ReqTaskRunCancel, ReqTaskRunCancelDevice, ReqTaskRunList,
    ReqTaskRunStart, ResTaskList, ResTaskPut, ResTaskRunCancel, ResTaskRunCancelDevice,
    ResTaskRunList, ResTaskRunStart,
};
use sqlx::PgPool;

use crate::cancel::task_run_cancel_signal;
use crate::run_start::task_run_start_core;
use crate::store::{
    task_delete, task_list, task_put, task_run_active_children, task_run_active_for_device,
    task_run_finish, task_run_get, task_run_list_children, task_run_list_for_task,
    task_run_mark_cancelled, task_run_update_progress, TASK_RUN_SELECT,
};
pub use crate::push::task_run_push;

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
    let run_id = task_run_start_core(pool, nats, owner_iid, req).await?;
    let run = task_run_get(pool, owner_iid, run_id)
        .await
        .ok_or("run missing after insert")?;
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

async fn cancel_run_tree(pool: &PgPool, nats: Option<&Client>, owner_iid: i64, run_id: i64) {
    for child_id in task_run_active_children(pool, run_id).await {
        task_run_cancel_signal(child_id);
        task_run_mark_cancelled(pool, child_id).await;
        if let Some(run) = task_run_get(pool, owner_iid, child_id).await {
            task_run_push(nats, owner_iid, &run);
        }
    }
}

pub async fn task_run_cancel_rpc(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    req: ReqTaskRunCancel,
) -> Result<ResTaskRunCancel, String> {
    task_run_cancel_signal(req.run_id);
    cancel_run_tree(pool, nats, owner_iid, req.run_id).await;
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
        cancel_run_tree(pool, nats, owner_iid, id).await;
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
    let runs = if req.parent_run_id > 0 {
        task_run_list_children(pool, owner_iid, req.parent_run_id, limit).await
    } else if req.task_id > 0 {
        task_run_list_for_task(pool, owner_iid, req.task_id, limit).await
    } else if req.device_iid > 0 {
        sqlx::query(&format!(
            "{} WHERE owner_iid = $1 AND device_iid = $2 AND deleted_ts IS NULL
            ORDER BY created_ts DESC
            LIMIT $3",
            TASK_RUN_SELECT.trim()
        ))
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
