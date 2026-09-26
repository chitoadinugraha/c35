use anyhow::Result;
use async_nats::Client;
use c35_proto::{Log, LogPush};
use c35_store::snowflake_id;
use prost::Message;
use serde_json::Value;
use sqlx::PgPool;
use tracing::warn;

const REDACTED: &str = "[redacted]";

fn key_sensitive(key: &str) -> bool {
    let k = key.to_ascii_lowercase();
    if k == "sess_id" || k == "conn_id" {
        return false;
    }
    ["token", "secret", "password", "api_key", "authorization", "session", "credential", "private_key"]
        .iter()
        .any(|s| k.contains(s))
}

fn meta_sanitize(v: &Value) -> Value {
    match v {
        Value::Object(map) => Value::Object(
            map.iter()
                .map(|(k, v)| {
                    let val = if key_sensitive(k) {
                        Value::String(REDACTED.into())
                    } else {
                        meta_sanitize(v)
                    };
                    (k.clone(), val)
                })
                .collect(),
        ),
        Value::Array(a) => Value::Array(a.iter().map(meta_sanitize).collect()),
        _ => v.clone(),
    }
}

fn text_sanitize(s: &str) -> String {
    if s.contains("Bearer ") {
        return s.split("Bearer ").next().unwrap_or(s).to_string() + "Bearer [redacted]";
    }
    s.to_string()
}

pub struct LogPut<'a> {
    pub owner_iid: i64,
    /// `trace` (default) | `event` | `error` — only non-trace rows publish on legacy `log.*` NATS.
    pub class: Option<&'a str>,
    pub kind: &'a str,
    pub topic: &'a str,
    pub dv: &'a str,
    pub req_id: Option<&'a str>,
    pub chat_id: Option<i64>,
    pub task_id: Option<i64>,
    pub device_iid: Option<i64>,
    pub text: &'a str,
    pub model: &'a str,
    pub tokens_in: i32,
    pub tokens_out: i32,
    pub duration_ms: i32,
    pub cost_usd: f64,
    pub meta: serde_json::Value,
}

pub async fn log_put(pool: &PgPool, nats: Option<&Client>, row: LogPut<'_>) -> Result<i64> {
    let id = snowflake_id();
    let req_id = row.req_id.unwrap_or("");
    let now_ms = chrono::Utc::now().timestamp_millis();
    let text = text_sanitize(row.text);
    let meta = meta_sanitize(&row.meta);
    let meta_json = meta.to_string();
    let class = row.class.unwrap_or("trace");

    sqlx::query(
        r#"
        INSERT INTO ai.log (
            id, owner_iid, kind, topic, dv, req_id, chat_id, task_id, device_iid,
            text, model, tokens_in, tokens_out, duration_ms, cost_usd, meta,
            event_kind, subject, class, created_ts, updated_ts
        )
        VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9,
            $10, $11, $12, $13, $14, $15, $16::jsonb,
            '', '', $17, NOW(), NOW()
        )
        "#,
    )
    .bind(id)
    .bind(row.owner_iid)
    .bind(row.kind)
    .bind(row.topic)
    .bind(row.dv)
    .bind(req_id)
    .bind(row.chat_id)
    .bind(row.task_id)
    .bind(row.device_iid)
    .bind(&text)
    .bind(row.model)
    .bind(row.tokens_in)
    .bind(row.tokens_out)
    .bind(row.duration_ms)
    .bind(row.cost_usd)
    .bind(&meta)
    .bind(class)
    .execute(pool)
    .await?;

    let publish_nats = class != "trace";
    let pb_row = Log {
        id,
        owner_iid: row.owner_iid,
        kind: row.kind.to_string(),
        topic: row.topic.to_string(),
        dv: row.dv.to_string(),
        req_id: req_id.to_string(),
        chat_id: row.chat_id.unwrap_or(0),
        task_id: row.task_id.unwrap_or(0),
        device_iid: row.device_iid.unwrap_or(0),
        text,
        model: row.model.to_string(),
        tokens_in: row.tokens_in,
        tokens_out: row.tokens_out,
        duration_ms: row.duration_ms,
        cost_usd: row.cost_usd,
        meta_json,
        created_ts_ms: now_ms,
        updated_ts_ms: now_ms,
        deleted_ts_ms: 0,
        event_kind: String::new(),
        class: class.to_string(),
        subject: String::new(),
    };
    if publish_nats {
        let subject = format!("log.{}.{}.{}", row.owner_iid, row.dv, row.topic);
        let payload = LogPush { row: Some(pb_row) }.encode_to_vec();
        match nats {
            Some(client) => {
                if let Err(e) = client.publish(subject, payload.into()).await {
                    warn!(error = %e, "log_put: nats publish failed");
                }
            }
            None => warn!("log_put: nats unavailable, row inserted only"),
        }
    }

    Ok(id)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn meta_sanitize_redacts_sensitive_keys() {
        let raw = serde_json::json!({
            "bot_token": "123:SECRET",
            "nested": { "api_key": "sk-live" },
            "ok": "visible",
        });
        let out = meta_sanitize(&raw);
        assert_eq!(out["bot_token"], REDACTED);
        assert_eq!(out["nested"]["api_key"], REDACTED);
        assert_eq!(out["ok"], "visible");
    }

    #[test]
    fn text_sanitize_redacts_bearer() {
        assert_eq!(
            text_sanitize("Auth: Bearer abc123xyz"),
            "Auth: Bearer [redacted]"
        );
    }
}
