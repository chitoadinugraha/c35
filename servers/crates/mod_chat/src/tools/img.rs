use anyhow::{bail, Result};
use base64::Engine;
use c35_mod_billing::image_tool_wholesale_usd;
use c35_mod_file::{cas_bytes_get, cas_dir_default, cas_image_bytes_fit_inline, cas_put};
use c35_mod_llm::{cf_grok_image_run, cf_image_provider_enabled};
use serde_json::{json, Value};
use sqlx::PgPool;
use tokio::time::Duration;

use crate::prompt::gemini::gemini_api_key;
use crate::tools::image_tier::{image_default_draft_tier, image_tier_resolve, ImageTier, MODEL_IMAGEN};

#[derive(Debug, Clone)]
pub struct ImageRunMeta {
    pub image_tier: String,
    pub provider_model: String,
    pub image_size: String,
    pub wholesale_usd: f64,
}

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

pub fn image_size_for_quality(quality: &str) -> &'static str {
    if quality.eq_ignore_ascii_case("hd") {
        "2K"
    } else {
        "1K"
    }
}

pub fn photo_hashes_from_attachments(attachments_json: &str) -> Vec<String> {
    let Ok(v) = serde_json::from_str::<Vec<serde_json::Value>>(attachments_json) else {
        return vec![];
    };
    let mut out = Vec::new();
    for a in v.iter() {
        let mime = a.get("mime").and_then(|x| x.as_str()).unwrap_or("");
        let hash = a.get("hash").and_then(|x| x.as_str()).unwrap_or("");
        if mime.starts_with("image/") && !hash.is_empty() && !out.contains(&hash.to_string()) {
            out.push(hash.to_string());
        }
    }
    out
}

pub async fn img_load_cas(pool: &PgPool, hash: &str) -> Result<(Vec<u8>, String)> {
    if hash.trim().is_empty() {
        bail!("source image hash required");
    }
    let (bytes, mime) = cas_bytes_get(pool, &cas_dir_default(), hash.trim())
        .await
        .map_err(|e| anyhow::anyhow!(e.to_string()))?;
    let mime = if mime.is_empty() { infer_mime(&bytes).to_string() } else { mime };
    Ok((bytes, mime))
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
    if let Some(b64) = v.pointer("/output_image/data").and_then(|s| s.as_str()) {
        if let Ok(bytes) = base64::engine::general_purpose::STANDARD.decode(b64) {
            if !bytes.is_empty() {
                return Some(bytes);
            }
        }
    }
    if let Some(steps) = v.get("steps").and_then(|s| s.as_array()) {
        for step in steps.iter().rev() {
            if let Some(b64) = step.pointer("/output_image/data").and_then(|s| s.as_str()) {
                if let Ok(bytes) = base64::engine::general_purpose::STANDARD.decode(b64) {
                    if !bytes.is_empty() {
                        return Some(bytes);
                    }
                }
            }
        }
    }
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

fn build_interaction_input(prompt: &str, source: Option<(Vec<u8>, String)>) -> Value {
    let Some((bytes, mime)) = source else {
        return json!(prompt);
    };
    json!([
        { "type": "text", "text": prompt },
        {
            "type": "image",
            "data": base64::engine::general_purpose::STANDARD.encode(&bytes),
            "mime_type": mime
        }
    ])
}

fn build_generate_content_body(
    prompt: &str,
    aspect_ratio: &str,
    image_size: &str,
    source: Option<(Vec<u8>, String)>,
) -> Value {
    let mut parts = Vec::new();
    if let Some((bytes, mime)) = source {
        parts.push(json!({
            "inlineData": {
                "mimeType": mime,
                "data": base64::engine::general_purpose::STANDARD.encode(&bytes)
            }
        }));
    }
    parts.push(json!({ "text": prompt }));
    json!({
        "contents": [{ "role": "user", "parts": parts }],
        "generationConfig": {
            "responseModalities": ["IMAGE", "TEXT"],
            "imageConfig": {
                "aspectRatio": aspect_ratio,
                "imageSize": image_size
            }
        }
    })
}

async fn gemini_interactions_run(
    client: &reqwest::Client,
    key: &str,
    model: &str,
    prompt: &str,
    aspect_ratio: &str,
    image_size: &str,
    source: Option<(Vec<u8>, String)>,
) -> Result<Vec<u8>> {
    let url = format!("https://generativelanguage.googleapis.com/v1beta/interactions?key={key}");
    let body = json!({
        "model": model,
        "input": build_interaction_input(prompt, source),
        "response_format": {
            "type": "image",
            "mime_type": "image/jpeg",
            "aspect_ratio": aspect_ratio,
            "image_size": image_size
        }
    });
    let res = client.post(&url).timeout(Duration::from_secs(90)).json(&body).send().await?;
    let status = res.status();
    let v: Value = res.json().await?;
    if !status.is_success() {
        bail!("interactions HTTP {status}: {v}");
    }
    extract_image_bytes(&v).ok_or_else(|| anyhow::anyhow!("interactions: no image bytes: {v}"))
}

async fn gemini_generate_content_run(
    client: &reqwest::Client,
    key: &str,
    model: &str,
    prompt: &str,
    aspect_ratio: &str,
    image_size: &str,
    source: Option<(Vec<u8>, String)>,
) -> Result<Vec<u8>> {
    let url = format!(
        "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
    );
    let body = build_generate_content_body(prompt, aspect_ratio, image_size, source);
    let res = client.post(&url).timeout(Duration::from_secs(90)).json(&body).send().await?;
    let status = res.status();
    let v: Value = res.json().await?;
    if !status.is_success() {
        bail!("generateContent HTTP {status}: {v}");
    }
    extract_image_bytes(&v).ok_or_else(|| anyhow::anyhow!("generateContent: no image bytes: {v}"))
}

async fn gemini_image_run(
    client: &reqwest::Client,
    prompt: &str,
    aspect_ratio: &str,
    tier: &ImageTier,
    source: Option<(Vec<u8>, String)>,
) -> Result<(Vec<u8>, ImageRunMeta)> {
    let key = gemini_api_key();
    if key.is_empty() {
        bail!("GEMINI_API_KEY not configured");
    }
    let refined = enhance_prompt(prompt);
    let ar = if aspect_ratio.trim().is_empty() {
        "1:1"
    } else {
        aspect_ratio.trim()
    };
    let mut last_err = String::new();
    for model in tier.models() {
        let size = if model == MODEL_IMAGEN { "1K" } else { tier.image_size };
        match gemini_interactions_run(client, &key, model, &refined, ar, size, source.clone()).await {
            Ok(bytes) => {
                return Ok((
                    bytes,
                    ImageRunMeta {
                        image_tier: tier.id.to_string(),
                        provider_model: model.to_string(),
                        image_size: size.to_string(),
                        wholesale_usd: image_tool_wholesale_usd(tier.quality, model),
                    },
                ));
            }
            Err(e) => last_err = format!("interactions {model}: {e:#}"),
        }
        match gemini_generate_content_run(client, &key, model, &refined, ar, size, source.clone()).await
        {
            Ok(bytes) => {
                return Ok((
                    bytes,
                    ImageRunMeta {
                        image_tier: tier.id.to_string(),
                        provider_model: model.to_string(),
                        image_size: size.to_string(),
                        wholesale_usd: image_tool_wholesale_usd(tier.quality, model),
                    },
                ));
            }
            Err(e) => last_err = format!("{last_err}; generateContent {model}: {e:#}"),
        }
    }
    bail!("image generation failed across models. Last error: {last_err}")
}

async fn image_run(
    client: &reqwest::Client,
    prompt: &str,
    aspect_ratio: &str,
    tier: &ImageTier,
    source: Option<(Vec<u8>, String)>,
) -> Result<(Vec<u8>, ImageRunMeta)> {
    if tier.id == "lite_draft"
        && cf_image_provider_enabled()
        && source.is_none()
    {
        match cf_grok_image_run(client, prompt, aspect_ratio, tier.quality, None).await {
            Ok((bytes, model)) => {
                return Ok((
                    bytes,
                    ImageRunMeta {
                        image_tier: "grok_draft".into(),
                        provider_model: model.clone(),
                        image_size: tier.image_size.to_string(),
                        wholesale_usd: image_tool_wholesale_usd(tier.quality, &model),
                    },
                ));
            }
            Err(e) => tracing::warn!(error = %e, "grok image failed; falling back to gemini"),
        }
    }
    gemini_image_run(client, prompt, aspect_ratio, tier, source).await
}

fn img_tool_response(
    tool: &str,
    put: &c35_mod_file::CasPutResult,
    prompt: &str,
    source_hash: &str,
    aspect_ratio: &str,
    quality: &str,
    meta: &ImageRunMeta,
) -> Value {
    let mut out = json!({
        "ok": true,
        "runner": "cluster",
        "tool": tool,
        "file_hash": put.hash,
        "preview_url": put.url,
        "mime": put.mime_type,
        "prompt": prompt,
        "aspect_ratio": aspect_ratio,
        "quality": quality,
        "image_tier": meta.image_tier,
        "provider_model": meta.provider_model,
        "image_size": meta.image_size,
        "wholesale_usd": meta.wholesale_usd,
        "block": {
            "kind": "image",
            "collapsed": false,
            "body": {
                "hash": put.hash,
                "url": put.url,
                "mime": put.mime_type,
                "prompt": prompt,
                "quality": quality,
                "image_size": meta.image_size,
            }
        }
    });
    if !source_hash.is_empty() {
        out["source_hash"] = json!(source_hash);
    }
    out
}

pub async fn img_generate_exec(
    pool: &PgPool,
    _owner_iid: i64,
    client: &reqwest::Client,
    prompt: &str,
    aspect_ratio: &str,
    quality: &str,
    mention_ids: &[String],
    user_text: &str,
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
    let q = if quality.trim().is_empty() { "draft" } else { quality.trim() };
    let default_draft = image_default_draft_tier(pool).await;
    let tier = image_tier_resolve(mention_ids, user_text, prompt, q, false, &default_draft);
    let (bytes, meta) = image_run(client, prompt, ar, &tier, None).await?;
    let mime = infer_mime(&bytes);
    let (bytes, mime) = cas_image_bytes_fit_inline(bytes, mime).map_err(|e| anyhow::anyhow!(e))?;
    let secret = cas_secret_from_env();
    let put = cas_put(pool, &cas_dir_default(), &secret, &bytes, &mime).await?;
    Ok(img_tool_response(
        "img.generate",
        &put,
        prompt,
        "",
        ar,
        tier.quality,
        &meta,
    ))
}

pub async fn img_edit_exec(
    pool: &PgPool,
    _owner_iid: i64,
    client: &reqwest::Client,
    prompt: &str,
    source_hash: &str,
    attachments_json: &str,
    aspect_ratio: &str,
    quality: &str,
    mention_ids: &[String],
    user_text: &str,
) -> Result<Value> {
    let prompt = prompt.trim();
    if prompt.is_empty() {
        bail!("edit prompt cannot be empty");
    }
    let mut hash = source_hash.trim().to_string();
    if hash.is_empty() {
        hash = photo_hashes_from_attachments(attachments_json)
            .into_iter()
            .next()
            .unwrap_or_default();
    }
    if hash.is_empty() {
        bail!("source image required: attach an image or pass source_hash");
    }
    let ar = if aspect_ratio.trim().is_empty() {
        "1:1"
    } else {
        aspect_ratio.trim()
    };
    let q = if quality.trim().is_empty() { "draft" } else { quality.trim() };
    let default_draft = image_default_draft_tier(pool).await;
    let tier = image_tier_resolve(mention_ids, user_text, prompt, q, true, &default_draft);
    let (source_bytes, source_mime) = img_load_cas(pool, &hash).await?;
    let (bytes, meta) = image_run(
        client,
        prompt,
        ar,
        &tier,
        Some((source_bytes, source_mime)),
    )
    .await?;
    let mime = infer_mime(&bytes);
    let (bytes, mime) = cas_image_bytes_fit_inline(bytes, mime).map_err(|e| anyhow::anyhow!(e))?;
    let secret = cas_secret_from_env();
    let put = cas_put(pool, &cas_dir_default(), &secret, &bytes, &mime).await?;
    Ok(img_tool_response(
        "img.edit",
        &put,
        prompt,
        &hash,
        ar,
        tier.quality,
        &meta,
    ))
}
