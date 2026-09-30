use std::sync::Arc;
use std::time::Instant;

use async_nats::Client;
use c35_mod_device::remote_device_browser_invoke;
use serde_json::{json, Value};
use sqlx::PgPool;
use tokio::sync::Semaphore;
use tokio::task::JoinSet;

use crate::cancel::task_run_cancel_check;
use crate::store::task_run_update_progress;
use crate::worker::{DEFAULT_MAX_ROWS, DEFAULT_MAX_WALL_MS, MAX_PARALLEL_CAP};

pub struct RecipeOutcome {
    pub summary: String,
    pub meta: Value,
}

pub async fn run(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    device_iid: i64,
    run_id: i64,
    recipe: &Value,
    started: Instant,
) -> Result<RecipeOutcome, String> {
    task_run_cancel_check(run_id)?;
    if started.elapsed().as_millis() as i64 > DEFAULT_MAX_WALL_MS {
        return Err("max wall time exceeded".into());
    }
    let tab_id = recipe
        .get("tab_id")
        .and_then(|v| v.as_str())
        .ok_or("tab_id required")?;
    let parallel = recipe
        .get("parallel")
        .and_then(|v| v.as_i64())
        .unwrap_or(1)
        .clamp(1, MAX_PARALLEL_CAP as i64) as usize;
    let max_rows = recipe
        .get("limits")
        .and_then(|l| l.get("max_rows_per_run"))
        .and_then(|v| v.as_i64())
        .unwrap_or(DEFAULT_MAX_ROWS as i64)
        .clamp(1, 500) as i32;
    let from_row = recipe
        .get("sheet")
        .and_then(|s| s.get("from_row"))
        .and_then(|v| v.as_i64())
        .unwrap_or(3) as i64;
    let _sheet = recipe.get("sheet").cloned().unwrap_or(json!({}));

    let read = remote_device_browser_invoke(
        pool,
        nats,
        owner_iid,
        device_iid,
        "sheets.range_read",
        json!({
            "tab_id": tab_id,
            "from_row": from_row,
            "start_col": "B",
            "columns": 11,
            "read_mode": "export"
        }),
        90,
    )
    .await?;
    if read.get("ok").and_then(|v| v.as_bool()) == Some(false) {
        return Err(read
            .get("error")
            .and_then(|v| v.as_str())
            .unwrap_or("range_read failed")
            .into());
    }
    let rows = read
        .get("rows")
        .or_else(|| read.get("data"))
        .and_then(|v| v.as_array())
        .cloned()
        .unwrap_or_default();
    let mut work: Vec<(i64, String, String)> = vec![];
    for row in rows.iter().take(max_rows as usize) {
        let row_num = row.get("row").and_then(|v| v.as_i64()).unwrap_or(0);
        if row_num < from_row {
            continue;
        }
        let key = row
            .get("B")
            .or_else(|| row.get("key"))
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .trim()
            .to_string();
        let kartu = row
            .get("C")
            .or_else(|| row.get("kartu"))
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .trim()
            .to_string();
        if kartu.is_empty() {
            continue;
        }
        let empty_gl = ["G", "H", "I", "J", "K", "L"]
            .iter()
            .any(|c| row.get(*c).and_then(|v| v.as_str()).unwrap_or("").trim().is_empty());
        if empty_gl {
            work.push((row_num, key, kartu));
        }
    }
    let total = work.len();
    if total == 0 {
        let meta = json!({ "total": 0, "done": 0, "pct": 100.0, "parallel": parallel });
        return Ok(RecipeOutcome {
            summary: "No rows to fill".into(),
            meta,
        });
    }

    let mut done = 0i32;
    let mut failed = 0i32;
    let sem = Arc::new(Semaphore::new(parallel));
    let mut set = JoinSet::new();
    let mut meta = json!({
        "recipe": "browser.sheet_row_backfill",
        "parallel": parallel,
        "total": total,
        "done": 0,
        "failed": 0,
        "skipped": 0,
        "pct": 0.0,
        "current_rows": []
    });

    let nats_client = nats.cloned();
    for (row_num, key, kartu) in work {
        task_run_cancel_check(run_id)?;
        if started.elapsed().as_millis() as i64 > DEFAULT_MAX_WALL_MS {
            break;
        }
        let permit = sem.clone().acquire_owned().await.map_err(|e| e.to_string())?;
        let pool = pool.clone();
        let recipe = recipe.clone();
        let tab_id = tab_id.to_string();
        let nats_row = nats_client.clone();
        set.spawn(async move {
            let _p = permit;
            let url_tpl = recipe
                .get("epus")
                .and_then(|e| e.get("search_url_template"))
                .and_then(|v| v.as_str())
                .unwrap_or("");
            let url = url_tpl.replace("{kartu}", &kartu);
            let req_prefix = format!("task_run.{run_id}.row.{row_num}");
            let row_res = async {
                if !url.is_empty() {
                    let _ = remote_device_browser_invoke(
                        &pool,
                        nats_row.as_ref(),
                        owner_iid,
                        device_iid,
                        "tabs",
                        json!({ "op": "new", "url": url }),
                        60,
                    )
                    .await;
                }
                let _ = req_prefix;
                remote_device_browser_invoke(
                    &pool,
                    nats_row.as_ref(),
                    owner_iid,
                    device_iid,
                    "sheets.row_set",
                    json!({
                        "tab_id": tab_id,
                        "row": row_num,
                        "key": key,
                        "values": ["TBD", "", "", "TBD", "TBD", "TBD"]
                    }),
                    120,
                )
                .await
            }
            .await;
            (row_num, row_res)
        });
    }

    while let Some(joined) = set.join_next().await {
        task_run_cancel_check(run_id)?;
        let (row_num, row_res) = joined.map_err(|e| e.to_string())?;
        match row_res {
            Ok(v) if v.get("ok").and_then(|x| x.as_bool()) != Some(false) => done += 1,
            _ => failed += 1,
        }
        let pct = (done as f64 / total as f64) * 100.0;
        meta["done"] = json!(done);
        meta["failed"] = json!(failed);
        meta["pct"] = json!(pct);
        meta["current_rows"] = json!([]);
        let summary = format!("{done}/{total} ({pct:.0}%)");
        task_run_update_progress(pool, run_id, &meta, &summary, row_num as i32).await;
    }

    let pct = if total > 0 {
        (done as f64 / total as f64) * 100.0
    } else {
        100.0
    };
    meta["pct"] = json!(pct);
    Ok(RecipeOutcome {
        summary: format!("{done}/{total} ({pct:.0}%)"),
        meta,
    })
}
