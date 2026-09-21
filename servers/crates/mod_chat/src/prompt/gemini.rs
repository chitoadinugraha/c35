use std::sync::OnceLock;
use std::time::Duration;

use anyhow::Result;
use futures_util::StreamExt;
use reqwest::Client;
use serde_json::{json, Value};
use tokio_util::sync::CancellationToken;

use c35_mod_llm::alien_default_model;
use super::thought::{gemini_thinking_config, parse_candidate};

fn gemini_http() -> &'static Client {
    static CLIENT: OnceLock<Client> = OnceLock::new();
    CLIENT.get_or_init(|| {
        Client::builder()
            .timeout(Duration::from_secs(60))
            .build()
            .unwrap_or_else(|_| Client::new())
    })
}

pub fn gemini_api_key() -> String {
    ["GEMINI_API_KEY", "GOOGLE_API_KEY"]
        .iter()
        .find_map(|k| std::env::var(k).ok())
        .unwrap_or_default()
        .trim()
        .to_string()
}

pub fn gemini_model(model: &str) -> String {
    let m = model.trim().to_ascii_lowercase();
    if m.is_empty() || m == "alienai" || m == "auto" {
        return alien_default_model();
    }
    let bare = m.strip_prefix("models/").unwrap_or(&m);
    if bare.contains("gemini") {
        return bare.to_string();
    }
    if m.contains("2.5-pro") || (m.contains("pro") && !m.contains("flash")) {
        return "gemini-2.5-pro".into();
    }
    if m.contains("2.5") {
        return "gemini-2.5-flash".into();
    }
    alien_default_model()
}

pub async fn gemini_generate(
    contents: &[Value],
    tools: &Value,
    thinking: &str,
    model: &str,
    system: &str,
) -> Result<super::thought::ParseOut> {
    let key = gemini_api_key();
    if key.is_empty() {
        anyhow::bail!("GEMINI_API_KEY missing");
    }
    let mut body = json!({
        "contents": contents,
        "generationConfig": { "maxOutputTokens": 2048, "temperature": 0.2, "thinkingConfig": gemini_thinking_config(model, thinking) }
    });
    if !system.trim().is_empty() {
        body["systemInstruction"] = json!({ "parts": [{ "text": system }] });
    }
    if !tools.is_null() && tools.as_array().map(|a| !a.is_empty()).unwrap_or(true) && tools != &json!([]) {
        body["tools"] = tools.clone();
        body["toolConfig"] = json!({ "functionCallingConfig": { "mode": "AUTO" } });
    }
    let url = format!("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}");
    let v: Value = gemini_http().post(&url).json(&body).send().await?.error_for_status()?.json().await?;
    Ok(parse_candidate(&v))
}

fn gemini_stream_emit(v: &Value, on_delta: &mut (dyn FnMut(bool, String) + Send)) {
    let parts = v["candidates"][0]["content"]["parts"].as_array().cloned().unwrap_or_default();
    for part in parts {
        if let Some(t) = part["text"].as_str() {
            if !t.is_empty() {
                on_delta(false, t.to_string());
            }
        }
        if let Some(t) = part.get("thought").and_then(|x| x.as_str()) {
            if !t.is_empty() {
                on_delta(true, t.to_string());
            }
        }
    }
}

pub async fn gemini_generate_stream(
    contents: &[Value],
    tools: &Value,
    thinking: &str,
    model: &str,
    system: &str,
    on_delta: &mut (dyn FnMut(bool, String) + Send),
    cancel: &CancellationToken,
) -> Result<super::thought::ParseOut> {
    let key = gemini_api_key();
    if key.is_empty() {
        anyhow::bail!("GEMINI_API_KEY missing");
    }
    let mut body = json!({
        "contents": contents,
        "generationConfig": { "maxOutputTokens": 2048, "temperature": 0.2, "thinkingConfig": gemini_thinking_config(model, thinking) }
    });
    if !system.trim().is_empty() {
        body["systemInstruction"] = json!({ "parts": [{ "text": system }] });
    }
    if !tools.is_null() && tools.as_array().map(|a| !a.is_empty()).unwrap_or(true) && tools != &json!([]) {
        body["tools"] = tools.clone();
        body["toolConfig"] = json!({ "functionCallingConfig": { "mode": "AUTO" } });
    }
    let url = format!("https://generativelanguage.googleapis.com/v1beta/models/{model}:streamGenerateContent?alt=sse&key={key}");
    let mut stream = gemini_http().post(&url).json(&body).send().await?.error_for_status()?.bytes_stream();
    let mut buf = String::new();
    let mut last = json!({});
    while let Some(chunk) = stream.next().await {
        if cancel.is_cancelled() {
            anyhow::bail!("aborted");
        }
        buf.push_str(&String::from_utf8_lossy(&chunk?));
        while let Some(pos) = buf.find("\n\n") {
            let block = buf[..pos].to_string();
            buf = buf[pos + 2..].to_string();
            for line in block.lines() {
                let line = line.trim();
                if !line.starts_with("data: ") {
                    continue;
                }
                let payload = line[6..].trim();
                if payload.is_empty() || payload == "[DONE]" {
                    continue;
                }
                if let Ok(v) = serde_json::from_str::<Value>(payload) {
                    gemini_stream_emit(&v, on_delta);
                    last = v;
                }
            }
        }
    }
    Ok(parse_candidate(&last))
}
