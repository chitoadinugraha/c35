use anyhow::{bail, Context, Result};
use base64::Engine;
use reqwest::Client;
use serde_json::{json, Value};
use tokio::time::Duration;

use crate::runtime_config::{cf_gateway_config, cf_gateway_ready};

fn grok_model_for_quality(quality: &str) -> &'static str {
    if quality.eq_ignore_ascii_case("hd") {
        "xai/grok-imagine-image-2.0"
    } else {
        "xai/grok-imagine-image"
    }
}

fn grok_resolution_for_quality(quality: &str) -> &'static str {
    if quality.eq_ignore_ascii_case("hd") {
        "2k"
    } else {
        "1k"
    }
}

fn extract_cf_image_bytes(v: &Value) -> Option<Vec<u8>> {
    if let Some(b64) = v.pointer("/result/b64_json").and_then(|x| x.as_str()) {
        if let Ok(bytes) = base64::engine::general_purpose::STANDARD.decode(b64) {
            if !bytes.is_empty() {
                return Some(bytes);
            }
        }
    }
    if let Some(b64) = v.pointer("/result/data").and_then(|x| x.as_str()) {
        if let Ok(bytes) = base64::engine::general_purpose::STANDARD.decode(b64) {
            if !bytes.is_empty() {
                return Some(bytes);
            }
        }
    }
    if let Some(arr) = v.pointer("/result/images").and_then(|x| x.as_array()) {
        for item in arr {
            if let Some(b64) = item.get("b64_json").and_then(|x| x.as_str()) {
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

pub fn cf_image_provider_enabled() -> bool {
    std::env::var("C35_IMG_PROVIDER")
        .ok()
        .map(|v| v.trim().eq_ignore_ascii_case("grok"))
        .unwrap_or(false)
        && cf_gateway_ready()
}

pub async fn cf_grok_image_run(
    client: &Client,
    prompt: &str,
    aspect_ratio: &str,
    quality: &str,
    source: Option<(Vec<u8>, String)>,
) -> Result<(Vec<u8>, String)> {
    if !cf_gateway_ready() {
        bail!("CF AI Gateway not configured");
    }
    let cfg = cf_gateway_config();
    if cfg.account_id.is_empty() || cfg.api_token.is_empty() {
        bail!("CLOUDFLARE_ACCOUNT_ID or CLOUDFLARE_API_TOKEN missing");
    }
    let model = grok_model_for_quality(quality);
    let url = format!(
        "https://api.cloudflare.com/client/v4/accounts/{}/ai/run",
        cfg.account_id
    );
    let mut input = json!({
        "prompt": prompt,
        "aspect_ratio": aspect_ratio,
        "resolution": grok_resolution_for_quality(quality),
        "response_format": "b64_json"
    });
    if let Some((bytes, mime)) = source {
        input["image"] = json!({
            "data": base64::engine::general_purpose::STANDARD.encode(&bytes),
            "mime_type": mime
        });
    }
    let body = json!({ "model": model, "input": input });
    let res = client
        .post(&url)
        .header("Authorization", format!("Bearer {}", cfg.api_token))
        .header("Content-Type", "application/json")
        .timeout(Duration::from_secs(90))
        .json(&body)
        .send()
        .await
        .context("cf grok image request")?;
    let status = res.status();
    let v: Value = res.json().await.context("cf grok image json")?;
    if !status.is_success() {
        bail!("cf grok image HTTP {status}: {v}");
    }
    if v.get("success").and_then(|x| x.as_bool()) == Some(false) {
        bail!("cf grok image failed: {v}");
    }
    let payload = v.get("result").cloned().unwrap_or(v.clone());
    let bytes = extract_cf_image_bytes(&json!({ "result": payload }))
        .or_else(|| extract_cf_image_bytes(&v))
        .ok_or_else(|| anyhow::anyhow!("cf grok image: no bytes in response: {v}"))?;
    Ok((bytes, model.to_string()))
}
