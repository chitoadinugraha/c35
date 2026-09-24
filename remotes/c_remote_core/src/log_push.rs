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
    if session_key.trim().is_empty() || base_url.trim().is_empty() {
        return;
    }
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

/// Helper to asynchronously dispatch a server log entry in the background (fire-and-forget).
pub fn spawn_log_push(
    base_url: String,
    session_key: String,
    kind: String,
    topic: String,
    text: String,
    meta: Option<Value>,
) {
    if session_key.trim().is_empty() || base_url.trim().is_empty() {
        return;
    }
    tokio::spawn(async move {
        log_push(&base_url, &session_key, &kind, &topic, &text, meta).await;
    });
}

/// Unified logging helper: outputs cleanly to local tracing (console + file)
/// and asynchronously pushes to the server if a session key is provided.
pub fn log_event(
    base_url: Option<&str>,
    session_key: Option<&str>,
    kind: &str,
    topic: &str,
    text: &str,
    meta: Option<Value>,
) {
    match kind {
        "error" => tracing::error!(topic = topic, "{text}"),
        "warn" => tracing::warn!(topic = topic, "{text}"),
        _ => tracing::info!(topic = topic, "{text}"),
    }
    if let (Some(url), Some(key)) = (base_url, session_key) {
        if !url.trim().is_empty() && !key.trim().is_empty() {
            spawn_log_push(
                url.to_string(),
                key.to_string(),
                kind.to_string(),
                topic.to_string(),
                text.to_string(),
                meta,
            );
        }
    }
}
