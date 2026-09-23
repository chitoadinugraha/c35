use async_nats::Client;
use c35_mod_log::{log_put, LogPut};
use serde_json::{json, Value};
use sqlx::PgPool;

pub async fn agent_log_put(
    pool: &PgPool,
    nats: Option<&Client>,
    device_iid: i64,
    owner_iid: i64,
    kind: &str,
    topic: &str,
    text: &str,
    meta: Option<Value>,
) -> Result<i64, String> {
    log_put(
        pool,
        nats,
        LogPut {
            owner_iid,
            kind,
            topic,
            dv: "",
            req_id: None,
            chat_id: None,
            task_id: None,
            device_iid: Some(device_iid),
            text,
            model: "",
            tokens_in: 0,
            tokens_out: 0,
            duration_ms: 0,
            cost_usd: 0.0,
            meta: meta.unwrap_or_else(|| json!({ "source": "agent" })),
        },
    )
    .await
    .map_err(|e| e.to_string())
}
