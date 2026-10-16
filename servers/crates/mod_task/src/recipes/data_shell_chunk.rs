use std::time::Instant;

use serde_json::{json, Value};
use sqlx::PgPool;

use crate::cancel::task_run_cancel_check;
use crate::recipes::sheet_row_backfill::RecipeOutcome;
use crate::store::task_run_update_progress;
use crate::worker::DEFAULT_MAX_WALL_MS;

/// Deterministic chunk processor (offset/limit). v1 simulates work on the server;
/// extend to agent `shell` invoke when a command template is configured.
pub async fn run(
    pool: &PgPool,
    _owner_iid: i64,
    run_id: i64,
    recipe: &Value,
    started: Instant,
) -> Result<RecipeOutcome, String> {
    task_run_cancel_check(run_id)?;
    if started.elapsed().as_millis() as i64 > DEFAULT_MAX_WALL_MS {
        return Err("max wall time exceeded".into());
    }
    let offset = recipe.get("offset").and_then(|v| v.as_i64()).unwrap_or(0);
    let limit = recipe
        .get("limit")
        .and_then(|v| v.as_i64())
        .unwrap_or(500)
        .clamp(1, 5000);
    let cmd = recipe
        .get("command_template")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .trim();
    if !cmd.is_empty() {
        return Err(
            "data.shell_chunk: command_template requires agent shell bridge (not wired in v1)".into(),
        );
    }
    let done = limit;
    let meta = json!({
        "role": "chunk",
        "offset": offset,
        "limit": limit,
        "done": done,
        "total": limit,
        "pct": 100
    });
    task_run_update_progress(pool, run_id, &meta, &format!("Simulated {done} rows @ offset {offset}"), 0)
        .await;
    Ok(RecipeOutcome {
        summary: format!("Processed rows [{offset}, {offset}+{done})"),
        meta,
    })
}
