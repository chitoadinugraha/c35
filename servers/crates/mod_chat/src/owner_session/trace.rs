use async_nats::Client;
use c35_mod_log::{log_put, LogPut};
use serde_json::json;
use sqlx::PgPool;

use crate::turn_tracer::StageClock;

pub async fn session_warmup_trace_put(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    conn_id: &str,
    run_id: &str,
    duration_ms: i64,
    clock: &StageClock,
    cancelled: bool,
) {
    let req_id = format!("warmup:{conn_id}:{run_id}");
    let stages = clock.rows();
    let meta = json!({
        "topic": "trace_session_warmup",
        "conn_id": conn_id,
        "run_id": run_id,
        "cancelled": cancelled,
        "stages": stages,
    });
    let _ = log_put(
        pool,
        nats,
        LogPut {
            class: Some("trace"),
            owner_iid,
            kind: "system",
            topic: "trace_session_warmup",
            dv: "",
            req_id: Some(&req_id),
            chat_id: None,
            task_id: None,
            device_iid: None,
            text: "session warmup",
            model: "",
            tokens_in: 0,
            tokens_out: 0,
            duration_ms: duration_ms.clamp(0, i32::MAX as i64) as i32,
            cost_usd: 0.0,
            meta,
        },
    )
    .await;
}

/// Prompt blocked on owner bundle; not included in `trace_stages` / `trace_prepare`.
pub async fn session_bundle_wait_trace_put(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    req_id: &str,
    wait_ms: u64,
    bundle_ready: bool,
) {
    let meta = json!({
        "topic": "trace_session_bundle_wait",
        "wait_ms": wait_ms,
        "bundle_ready": bundle_ready,
    });
    let _ = log_put(
        pool,
        nats,
        LogPut {
            class: Some("trace"),
            owner_iid,
            kind: "system",
            topic: "trace_session_bundle_wait",
            dv: "",
            req_id: Some(req_id),
            chat_id: None,
            task_id: None,
            device_iid: None,
            text: if bundle_ready {
                "session bundle wait (ready)"
            } else {
                "session bundle wait (timeout)"
            },
            model: "",
            tokens_in: 0,
            tokens_out: 0,
            duration_ms: wait_ms.min(i32::MAX as u64) as i32,
            cost_usd: 0.0,
            meta,
        },
    )
    .await;
}
