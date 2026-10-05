use anyhow::{bail, Context, Result};
use base64::Engine;
use reqwest::Client;
use serde_json::{json, Value};
use tokio::time::Duration;

pub const LYRIA_MODEL_DEFAULT: &str = "lyria-3-clip-preview";

fn extract_lyria_audio_bytes(v: &Value) -> Option<Vec<u8>> {
    if let Some(b64) = v.pointer("/output_audio/data").and_then(|s| s.as_str()) {
        if let Ok(bytes) = base64::engine::general_purpose::STANDARD.decode(b64) {
            if !bytes.is_empty() {
                return Some(bytes);
            }
        }
    }
    if let Some(steps) = v.get("steps").and_then(|s| s.as_array()) {
        for step in steps.iter().rev() {
            if let Some(b64) = step.pointer("/output_audio/data").and_then(|s| s.as_str()) {
                if let Ok(bytes) = base64::engine::general_purpose::STANDARD.decode(b64) {
                    if !bytes.is_empty() {
                        return Some(bytes);
                    }
                }
            }
        }
    }
    None
}

pub async fn lyria_run(client: &Client, api_key: &str, prompt: &str) -> Result<(Vec<u8>, String)> {
    if api_key.trim().is_empty() {
        bail!("GEMINI_API_KEY not configured");
    }
    let model = LYRIA_MODEL_DEFAULT;
    let url = format!("https://generativelanguage.googleapis.com/v1beta/interactions?key={}", api_key.trim());
    let body = json!({
        "model": model,
        "input": prompt,
        "response_format": {
            "type": "audio",
            "mime_type": "audio/wav"
        }
    });
    let res = client
        .post(&url)
        .timeout(Duration::from_secs(120))
        .json(&body)
        .send()
        .await
        .context("lyria interactions")?;
    let status = res.status();
    let v: Value = res.json().await.context("lyria json")?;
    if !status.is_success() {
        bail!("lyria HTTP {status}: {v}");
    }
    let bytes = extract_lyria_audio_bytes(&v)
        .ok_or_else(|| anyhow::anyhow!("lyria: no audio bytes: {v}"))?;
    Ok((bytes, model.to_string()))
}
