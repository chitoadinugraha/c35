use serde_json::Value;
use tracing::warn;

pub async fn log_push(
    base_url: &str,
    session_key: &str,
    kind: &str,
    topic: &str,
    text: &str,
    meta: Option<Value>,
) {
    let url = format!("{}/v1/agent/log", base_url.trim_end_matches('/'));
    let client = reqwest::Client::new();
    let body = serde_json::json!({
        "kind": kind,
        "topic": topic,
        "text": text,
        "meta": meta,
    });
    let res = client
        .post(&url)
        .header("X-Device-Session", session_key)
        .json(&body)
        .send()
        .await;
    match res {
        Ok(r) if r.status().is_success() => {}
        Ok(r) => warn!("log_push status {} topic={}", r.status(), topic),
        Err(e) => warn!("log_push failed topic={}: {e}", topic),
    }
}
