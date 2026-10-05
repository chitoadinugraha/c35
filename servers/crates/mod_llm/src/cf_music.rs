use anyhow::{bail, Context, Result};
use base64::Engine;
use reqwest::Client;
use serde_json::{json, Value};
use tokio::time::Duration;

use crate::runtime_config::{cf_gateway_config, cf_gateway_ready};

pub const CF_MUSIC_MODEL_DEFAULT: &str = "elevenlabs/music-v2";
pub const CF_MUSIC_DURATION_SEC_DEFAULT: i32 = 30;

fn extract_cf_audio_bytes(v: &Value) -> Option<Vec<u8>> {
    if let Some(b64) = v.pointer("/result/b64_json").and_then(|x| x.as_str()) {
        if let Ok(bytes) = base64::engine::general_purpose::STANDARD.decode(b64) {
            if !bytes.is_empty() {
                return Some(bytes);
            }
        }
    }
    if let Some(b64) = v.pointer("/result/audio").and_then(|x| x.as_str()) {
        if let Ok(bytes) = base64::engine::general_purpose::STANDARD.decode(b64) {
            if !bytes.is_empty() {
                return Some(bytes);
            }
        }
    }
    None
}

pub async fn cf_music_run(
    client: &Client,
    prompt: &str,
    duration_sec: i32,
    instrumental: bool,
    model: Option<&str>,
) -> Result<(Vec<u8>, String)> {
    if !cf_gateway_ready() {
        bail!("CF AI Gateway not configured");
    }
    let cfg = cf_gateway_config();
    if cfg.account_id.is_empty() || cfg.api_token.is_empty() {
        bail!("CLOUDFLARE_ACCOUNT_ID or CLOUDFLARE_API_TOKEN missing");
    }
    let model = model
        .filter(|m| !m.trim().is_empty())
        .unwrap_or(CF_MUSIC_MODEL_DEFAULT);
    let duration = if duration_sec > 0 { duration_sec } else { CF_MUSIC_DURATION_SEC_DEFAULT };
    let url = format!(
        "https://api.cloudflare.com/client/v4/accounts/{}/ai/run",
        cfg.account_id
    );
    let input = json!({
        "prompt": prompt,
        "duration": duration,
        "instrumental": instrumental,
        "response_format": "b64_json"
    });
    let body = json!({ "model": model, "input": input });
    let res = client
        .post(&url)
        .header("Authorization", format!("Bearer {}", cfg.api_token))
        .header("Content-Type", "application/json")
        .timeout(Duration::from_secs(120))
        .json(&body)
        .send()
        .await
        .context("cf music request")?;
    let status = res.status();
    let v: Value = res.json().await.context("cf music json")?;
    if !status.is_success() {
        bail!("cf music HTTP {status}: {v}");
    }
    if v.get("success").and_then(|x| x.as_bool()) == Some(false) {
        bail!("cf music failed: {v}");
    }
    let bytes = extract_cf_audio_bytes(&v)
        .ok_or_else(|| anyhow::anyhow!("cf music: no bytes in response: {v}"))?;
    Ok((bytes, model.to_string()))
}
