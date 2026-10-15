use async_nats::Client;
use c35_mod_log::{log_put, LogPut};
use serde_json::{json, Value};
use sqlx::PgPool;
use tracing::warn;

/// User-visible Live failure: `tracing` + durable `ai.log` (`topic=live_error`, `class=error`).
pub async fn live_error_record(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    req_id: Option<&str>,
    chat_id: Option<i64>,
    stage: &str,
    message: &str,
    detail: Option<&str>,
    meta: Value,
) {
    let stage = stage.trim();
    let message = message.trim();
    if message.is_empty() {
        return;
    }
    let detail_s = detail.map(str::trim).filter(|s| !s.is_empty());
    warn!(
        owner_iid,
        req_id = req_id.unwrap_or(""),
        chat_id = chat_id.unwrap_or(0),
        stage,
        message,
        detail = detail_s.unwrap_or(""),
        "live: client error"
    );
    let meta = json!({
        "topic": "live_error",
        "stage": stage,
        "message": message,
    })
    .as_object()
    .map(|base| {
        let mut m = base.clone();
        if let Some(d) = detail_s {
            m.insert("detail".into(), json!(d));
        }
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
            class: Some("error"),
            owner_iid,
            kind: "system",
            topic: "live_error",
            dv: "",
            req_id,
            chat_id,
            task_id: None,
            device_iid: None,
            text: message,
            model: "",
            tokens_in: 0,
            tokens_out: 0,
            duration_ms: 0,
            cost_usd: 0.0,
            meta,
        },
    )
    .await;
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn live_error_meta_merges_stage_and_detail() {
        let meta = json!({
            "topic": "live_error",
            "stage": "live_start",
            "message": "quota",
        })
        .as_object()
        .map(|base| {
            let mut m = base.clone();
            m.insert("detail".into(), json!("insufficient balance"));
            m.insert("offer_id".into(), json!("gemini-live"));
            Value::Object(m)
        })
        .unwrap();
        assert_eq!(meta["stage"], "live_start");
        assert_eq!(meta["detail"], "insufficient balance");
    }
}

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
