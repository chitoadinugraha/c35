use anyhow::{bail, Result};
use base64::Engine;
use c35_mod_file::{cas_dir_default, cas_put};
use serde_json::{json, Value};
use sqlx::PgPool;
use tokio::time::Duration;

use crate::prompt::gemini::gemini_api_key;

const IMAGE_MODELS: &[&str] = &[
    "gemini-3.1-flash-image",
    "gemini-2.5-flash-image",
    "gemini-2.0-flash-preview-image-generation",
    "imagen-3.0-generate-002",
];

fn cas_secret_from_env() -> String {
    ["CAS_HMAC_SECRET", "C35_JWT_SECRET", "AGENT_SECRET_KEY"]
        .into_iter()
        .find_map(|k| std::env::var(k).ok())
        .unwrap_or_default()
}

pub fn infer_mime(bytes: &[u8]) -> &'static str {
    match bytes {
        [0xFF, 0xD8, ..] => "image/jpeg",
        [0x89, b'P', b'N', b'G', ..] => "image/png",
        [b'R', b'I', b'F', b'F', ..] => "image/webp",
        _ => "image/jpeg",
    }
}

pub fn enhance_prompt(prompt: &str) -> String {
    let trimmed = prompt.trim();
    let lower = trimmed.to_lowercase();
    if lower.contains("masterpiece")
        || lower.contains("ultra premium")
        || lower.contains("vector art")
        || lower.contains("photorealistic")
    {
        return trimmed.to_string();
    }
    if lower.contains("icon")
        || lower.contains("ikon")
        || lower.contains("logo")
        || lower.contains("symbol")
        || lower.contains("badge")
        || lower.contains("app icon")
    {
        return format!(
            "{trimmed}, clean vector graphic, modern minimalist design, sharp bold outlines, iconic silhouette, professional UI asset, high contrast, crisp rendering, dark background"
        );
    }
    if lower.contains("photo")
        || lower.contains("foto")
        || lower.contains("realistic")
        || lower.contains("portrait")
        || lower.contains("scenery")
        || lower.contains("landscape")
        || lower.contains("nature")
    {
        return format!(
            "{trimmed}, 8k UHD resolution, highly detailed photorealistic, exquisite natural lighting, cinematic composition, sharp focus, professional photography"
        );
    }
    format!(
        "{trimmed}, highly detailed digital artwork, masterpiece quality, vibrant rich colors, exquisite lighting, artistic composition, sharp focus"
    )
}

pub fn extract_image_bytes(v: &serde_json::Value) -> Option<Vec<u8>> {
    if let Some(parts) = v
        .get("candidates")
        .and_then(|c| c.get(0))
        .and_then(|c0| c0.get("content"))
        .and_then(|c| c.get("parts"))
        .and_then(|p| p.as_array())
    {
        for part in parts {
            if let Some(b64) = part
                .get("inlineData")
                .and_then(|d| d.get("data"))
                .and_then(|s| s.as_str())
            {
                if let Ok(bytes) = base64::engine::general_purpose::STANDARD.decode(b64) {
                    if !bytes.is_empty() {
                        return Some(bytes);
                    }
                }
            }
        }
    }
    if let Some(predictions) = v.get("predictions").and_then(|p| p.as_array()) {
        for pred in predictions {
            if let Some(b64) = pred.get("bytesBase64Encoded").and_then(|s| s.as_str()) {
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

pub async fn gemini_image_generate(
    client: &reqwest::Client,
    prompt: &str,
    _aspect_ratio: &str,
) -> Result<Vec<u8>> {
    let key = gemini_api_key();
    if key.is_empty() {
        bail!("GEMINI_API_KEY not configured");
    }
    let refined = enhance_prompt(prompt);
    let body = json!({
        "contents": [{ "parts": [{ "text": refined }] }],
        "generationConfig": { "responseModalities": ["IMAGE", "TEXT"] }
    });
    let mut last_err = String::new();
    for model in IMAGE_MODELS {
        let url = format!(
            "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
        );
        match client.post(&url).timeout(Duration::from_secs(90)).json(&body).send().await {
            Ok(res) if res.status().is_success() => match res.json::<serde_json::Value>().await {
                Ok(v) => {
                    if let Some(bytes) = extract_image_bytes(&v) {
                        return Ok(bytes);
                    }
                    last_err = format!("model {model}: no image bytes in response");
                }
                Err(e) => last_err = format!("model {model}: json parse error: {e}"),
            },
            Ok(res) => {
                let status = res.status();
                let body_text = res.text().await.unwrap_or_default();
                last_err = format!("model {model}: HTTP {status}: {body_text}");
            }
            Err(e) => last_err = format!("model {model}: request error: {e}"),
        }
    }
    bail!("image generation failed across models. Last error: {last_err}")
}

pub async fn img_generate_exec(
    pool: &PgPool,
    _owner_iid: i64,
    client: &reqwest::Client,
    prompt: &str,
    aspect_ratio: &str,
    _quality: &str,
) -> Result<Value> {
    let prompt = prompt.trim();
    if prompt.is_empty() {
        bail!("image prompt cannot be empty");
    }
    let ar = if aspect_ratio.trim().is_empty() {
        "1:1"
    } else {
        aspect_ratio.trim()
    };
    let bytes = gemini_image_generate(client, prompt, ar).await?;
    let mime = infer_mime(&bytes);
    let secret = cas_secret_from_env();
    let cas_dir = cas_dir_default();
    let put = cas_put(pool, &cas_dir, &secret, &bytes, mime).await?;
    Ok(json!({
        "ok": true,
        "runner": "cluster",
        "tool": "img.generate",
        "file_hash": put.hash,
        "preview_url": put.url,
        "mime": put.mime_type,
        "prompt": prompt,
        "aspect_ratio": ar,
        "block": {
            "kind": "image",
            "hash": put.hash,
            "url": put.url,
            "mime": put.mime_type,
            "prompt": prompt,
        }
    }))
}
