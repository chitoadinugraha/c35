use std::sync::Arc;

use async_nats::Client;
use serde_json::Value;
use sqlx::PgPool;

use crate::worker::task_worker_spawn;

/// Returns true when a server-side recipe worker was spawned for this prompt.
pub fn spawn_recipe_worker(
    pool: Arc<PgPool>,
    nats: Option<Arc<Client>>,
    owner_iid: i64,
    device_iid: i64,
    run_id: i64,
    req_id: String,
    prompt: String,
    recipe: &Value,
) -> bool {
    let recipe_name = recipe
        .get("recipe")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    match recipe_name {
        "browser.sheet_row_backfill" | "task.chunk_fanout" | "data.shell_chunk" => {
            task_worker_spawn(pool, nats, owner_iid, device_iid, run_id, req_id, prompt);
            true
        }
        _ => false,
    }
}
