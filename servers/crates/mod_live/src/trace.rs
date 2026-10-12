use async_nats::Client;
use c35_mod_log::{log_put, LogPut};
use serde_json::{json, Value};
use sqlx::PgPool;

pub async fn live_setup_trace_put(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    req_id: &str,
    duration_ms: i64,
    meta: Value,
) {
    let meta = json!({
        "topic": "trace_live_setup",
        "req_id": req_id,
    })
    .as_object()
    .map(|base| {
        let mut m = base.clone();
        if let Some(obj) = meta.as_object() {
            for (k, v) in obj {
                m.insert(k.clone(), v.clone());
            }
        }
        Value::Object(m)
    })
    .unwrap_or(meta);

    let _ = log_put(
        pool,
        nats,
        LogPut {
            class: Some("trace"),
            owner_iid,
            kind: "system",
            topic: "trace_live_setup",
            dv: "",
            req_id: Some(req_id),
            chat_id: None,
            task_id: None,
            device_iid: None,
            text: "live setup",
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
