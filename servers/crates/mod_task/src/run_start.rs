use async_nats::Client;
use c35_mod_billing::{billing_account_ensure, billing_gate_with_hold_custom};
use c35_proto::{pb_encode, ActDeviceTaskRun, ReqTaskRunStart};
use sqlx::PgPool;
use tracing::warn;

use crate::push::task_run_push;
use crate::recipes::registry::spawn_recipe_worker;
use crate::store::{task_run_get, task_run_set_running};
use crate::worker::TASK_RUN_HOLD_USD;

fn is_server_only_recipe(recipe_name: &str) -> bool {
    matches!(recipe_name, "task.chunk_fanout" | "data.shell_chunk")
}

/// Start a task run (billing, insert, agent notify, recipe worker). Returns `run_id`.
pub async fn task_run_start_core(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    req: ReqTaskRunStart,
) -> Result<i64, String> {
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
    let parent_run_id = req.parent_run_id;
    let source_msg_id = req.source_msg_id;
    sqlx::query(
        r#"
        INSERT INTO ai.task_run (
            id, owner_iid, device_iid, task_id, chat_id, req_id, status, prompt, skill_id, model,
            parent_run_id, source_msg_id
        ) VALUES ($1, $2, $3, $4, $5, $6, 'queued', $7, $8, $9, $10, $11)
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
    .bind(parent_run_id)
    .bind(source_msg_id)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;

    let recipe: serde_json::Value = serde_json::from_str(&prompt).unwrap_or(serde_json::Value::Null);
    let recipe_name = recipe.get("recipe").and_then(|v| v.as_str()).unwrap_or("");
    if req.skill_id > 0 || !is_server_only_recipe(recipe_name) {
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
    }

    let pool_arc = std::sync::Arc::new(pool.clone());
    let nats_arc = nats.cloned().map(std::sync::Arc::new);
    if !spawn_recipe_worker(
        pool_arc,
        nats_arc,
        owner_iid,
        device_iid,
        run_id,
        req_id,
        prompt,
        &recipe,
    ) {
        task_run_set_running(pool, run_id).await;
    }

    if let Some(run) = task_run_get(pool, owner_iid, run_id).await {
        task_run_push(nats, owner_iid, &run);
    }

    Ok(run_id)
}
