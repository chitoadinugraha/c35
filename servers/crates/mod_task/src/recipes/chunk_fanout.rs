use std::sync::Arc;
use std::time::{Duration, Instant};

use async_nats::Client;
use c35_proto::{ReqTaskRunStart, TaskRunStatus};
use serde_json::{json, Value};
use sqlx::PgPool;
use tokio::sync::Semaphore;
use tokio::task::JoinSet;

use crate::cancel::task_run_cancel_check;
use crate::recipes::sheet_row_backfill::RecipeOutcome;
use crate::run_start::task_run_start_core;
use crate::store::{task_run_get, task_run_update_progress};
use crate::worker::DEFAULT_MAX_WALL_MS;

const MAX_CHUNKS: i64 = 10_000;
const MAX_PARALLEL_CHILDREN: usize = 5;

pub async fn run(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    device_iid: i64,
    parent_run_id: i64,
    recipe: &Value,
    started: Instant,
) -> Result<RecipeOutcome, String> {
    task_run_cancel_check(parent_run_id)?;
    let total = recipe
        .get("total")
        .and_then(|v| v.as_i64())
        .filter(|&t| t > 0)
        .ok_or("total required")?;
    let chunk_size = recipe
        .get("chunk_size")
        .and_then(|v| v.as_i64())
        .unwrap_or(500)
        .clamp(1, 500);
    let parallel_children = recipe
        .get("parallel_children")
        .and_then(|v| v.as_i64())
        .unwrap_or(1)
        .clamp(1, MAX_PARALLEL_CHILDREN as i64) as usize;
    let stagger_ms = recipe
        .get("stagger_ms")
        .and_then(|v| v.as_i64())
        .unwrap_or(500)
        .max(0) as u64;
    let child_recipe = recipe
        .get("child_recipe")
        .and_then(|v| v.as_str())
        .ok_or("child_recipe required")?;
    let child_params = recipe.get("child_params").cloned().unwrap_or(json!({}));
    let dev = recipe
        .get("device_iid")
        .and_then(|v| v.as_i64())
        .filter(|&d| d > 0)
        .unwrap_or(device_iid);

    let num_chunks = ((total + chunk_size - 1) / chunk_size).min(MAX_CHUNKS);
    let parent = task_run_get(pool, owner_iid, parent_run_id)
        .await
        .ok_or("parent run missing")?;
    let source_msg_id = parent.source_msg_id;
    let parent_req_id = parent.req_id.clone();

    let mut meta = json!({
        "role": "orchestrator",
        "total_chunks": num_chunks,
        "done_chunks": 0,
        "failed_chunks": 0,
        "pct": 0,
        "child_recipe": child_recipe,
    });
    task_run_update_progress(
        pool,
        parent_run_id,
        &meta,
        &format!("0/{num_chunks} chunks"),
        0,
    )
    .await;

    let sem = Arc::new(Semaphore::new(parallel_children));
    let mut join = JoinSet::new();

    for chunk_idx in 0..num_chunks {
        task_run_cancel_check(parent_run_id)?;
        if started.elapsed().as_millis() as i64 > DEFAULT_MAX_WALL_MS {
            return Err("max wall time exceeded".into());
        }
        let offset = chunk_idx * chunk_size;
        let limit = chunk_size.min(total - offset);
        let child_prompt = build_child_prompt(child_recipe, &child_params, offset, limit)?;

        let permit = sem.clone().acquire_owned().await.map_err(|e| e.to_string())?;
        let pool_c = pool.clone();
        let nats_c = nats.cloned();
        let req_id = format!("{parent_req_id}.chunk.{chunk_idx}");
        let req = ReqTaskRunStart {
            device_iid: dev,
            task_id: 0,
            prompt: child_prompt,
            skill_id: 0,
            model: String::new(),
            chat_id: parent.chat_id,
            req_id,
            parent_run_id,
            source_msg_id,
        };
        let child_run_id = task_run_start_core(&pool_c, nats_c.as_ref(), owner_iid, req).await?;
        if stagger_ms > 0 {
            tokio::time::sleep(Duration::from_millis(stagger_ms)).await;
        }

        join.spawn(async move {
            let _permit = permit;
            let status = wait_child_terminal(&pool_c, owner_iid, child_run_id).await;
            status
        });
    }

    let mut done_chunks = 0i64;
    let mut failed_chunks = 0i64;
    while let Some(res) = join.join_next().await {
        done_chunks += 1;
        let ok = matches!(res, Ok(TaskRunStatus::Done));
        if !ok {
            failed_chunks += 1;
        }
        let pct = if num_chunks > 0 {
            (done_chunks * 100 / num_chunks) as i32
        } else {
            100
        };
        meta["done_chunks"] = json!(done_chunks);
        meta["failed_chunks"] = json!(failed_chunks);
        meta["pct"] = json!(pct);
        task_run_update_progress(
            pool,
            parent_run_id,
            &meta,
            &format!("{done_chunks}/{num_chunks} chunks ({pct}%)"),
            0,
        )
        .await;
    }

    let summary = format!(
        "Orchestrator finished: {done_chunks}/{num_chunks} chunks, {failed_chunks} failed"
    );
    if failed_chunks > 0 {
        return Err(summary);
    }
    Ok(RecipeOutcome { summary, meta })
}

fn build_child_prompt(
    child_recipe: &str,
    child_params: &Value,
    offset: i64,
    limit: i64,
) -> Result<String, String> {
    let mut obj = match child_params {
        Value::Object(m) => m.clone(),
        _ => serde_json::Map::new(),
    };
    obj.insert("recipe".into(), json!(child_recipe));
    match child_recipe {
        "browser.sheet_row_backfill" => {
            let sheet = obj
                .entry("sheet")
                .or_insert(json!({}))
                .as_object_mut()
                .ok_or("sheet must be object")?;
            let base_from = sheet
                .get("from_row")
                .and_then(|v| v.as_i64())
                .unwrap_or(3);
            sheet.insert("from_row".into(), json!(base_from + offset));
            let limits = obj
                .entry("limits")
                .or_insert(json!({}))
                .as_object_mut()
                .ok_or("limits must be object")?;
            limits.insert("max_rows_per_run".into(), json!(limit));
        }
        "data.shell_chunk" => {
            obj.insert("offset".into(), json!(offset));
            obj.insert("limit".into(), json!(limit));
        }
        _ => return Err(format!("unsupported child_recipe: {child_recipe}")),
    }
    Ok(Value::Object(obj).to_string())
}

async fn wait_child_terminal(pool: &PgPool, owner_iid: i64, child_run_id: i64) -> TaskRunStatus {
    for _ in 0..3600 {
        if let Some(run) = task_run_get(pool, owner_iid, child_run_id).await {
            match run.status() {
                TaskRunStatus::Done => return TaskRunStatus::Done,
                TaskRunStatus::Failed | TaskRunStatus::Cancelled => return run.status(),
                _ => {}
            }
        }
        tokio::time::sleep(Duration::from_secs(2)).await;
    }
    TaskRunStatus::Failed
}

#[cfg(test)]
mod tests {
    use super::build_child_prompt;
    use serde_json::json;

    #[test]
    fn shell_chunk_offsets() {
        let p = build_child_prompt("data.shell_chunk", &json!({}), 3000, 500).unwrap();
        let v: serde_json::Value = serde_json::from_str(&p).unwrap();
        assert_eq!(v["offset"], 3000);
        assert_eq!(v["limit"], 500);
    }
}
