use std::sync::Arc;
use std::time::Instant;

use async_nats::Client;
use c35_proto::TaskRunStatus;
use serde_json::Value;
use sqlx::PgPool;
use tracing::warn;

use crate::cancel::{task_run_cancel_check, task_run_cancel_clear, task_run_cancel_register};
use crate::metrics::task_run_metrics_persist;
use crate::recipes::sheet_row_backfill;
use crate::store::{task_run_finish, task_run_set_running};
use crate::task_run_push;

pub const DEFAULT_MAX_WALL_MS: i64 = 30 * 60 * 1000;
pub const DEFAULT_MAX_ROWS: i32 = 200;
pub const MAX_PARALLEL_CAP: i32 = 10;
pub const TASK_RUN_HOLD_USD: f64 = 0.05;

pub fn task_worker_spawn(
    pool: Arc<PgPool>,
    nats: Option<Arc<Client>>,
    owner_iid: i64,
    device_iid: i64,
    run_id: i64,
    req_id: String,
    prompt: String,
) {
    task_run_cancel_register(run_id);
    tokio::spawn(async move {
        let started = Instant::now();
        task_run_set_running(&pool, run_id).await;
        if let Some(run) = crate::store::task_run_get(&pool, owner_iid, run_id).await {
            task_run_push(nats.as_deref(), owner_iid, &run);
        }
        let recipe: Value = serde_json::from_str(&prompt).unwrap_or(Value::Null);
        let recipe_name = recipe
            .get("recipe")
            .and_then(|v| v.as_str())
            .unwrap_or("");
        let result = match recipe_name {
            "browser.sheet_row_backfill" => {
                sheet_row_backfill::run(&pool, nats.as_deref(), owner_iid, device_iid, run_id, &recipe, started).await
            }
            _ => Err(format!("unknown or missing recipe (got '{recipe_name}')")),
        };
        let duration_ms = started.elapsed().as_millis() as i64;
        let (tokens_in, tokens_out, cost_usd) =
            task_run_metrics_persist(&pool, run_id, owner_iid, duration_ms).await;
        crate::metrics::task_run_billing_settle(&pool, owner_iid, &req_id, cost_usd).await;
        let (status, summary, error, meta) = match result {
            Ok(m) => (TaskRunStatus::Done, m.summary, String::new(), m.meta),
            Err(e) => {
                let cancelled = e == "cancelled";
                (
                    if cancelled {
                        TaskRunStatus::Cancelled
                    } else {
                        TaskRunStatus::Failed
                    },
                    if cancelled {
                        "Cancelled".into()
                    } else {
                        e.clone()
                    },
                    if cancelled { String::new() } else { e },
                    Value::Object(Default::default()),
                )
            }
        };
        task_run_finish(&pool, run_id, status, &summary, &error, &meta, duration_ms).await;
        task_run_cancel_clear(run_id);
        if let Some(mut run) = crate::store::task_run_get(&pool, owner_iid, run_id).await {
            run.tokens_in = tokens_in;
            run.tokens_out = tokens_out;
            run.cost_usd = cost_usd;
            run.duration_ms = duration_ms;
            task_run_push(nats.as_deref(), owner_iid, &run);
        }
        if let Err(e) = task_run_cancel_check(run_id) {
            warn!(run_id, "worker end: {e}");
        }
    });
}
