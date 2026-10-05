use anyhow::{bail, Result};
use c35_mod_billing::video_tool_wholesale_usd;
use c35_mod_file::{cas_dir_default, cas_put};
use c35_mod_llm::cf_video_run;
use serde_json::{json, Value};
use sqlx::PgPool;

use crate::generation::{generation_prefs_get, provider_normalize, video_retail_quote};

#[derive(Debug, Clone)]
pub struct VideoRunMeta {
    pub media_provider: String,
    pub media_model: String,
    pub wholesale_usd: f64,
}

fn cas_secret_from_env() -> String {
    ["CAS_HMAC_SECRET", "C35_JWT_SECRET", "AGENT_SECRET_KEY"]
        .into_iter()
        .find_map(|k| std::env::var(k).ok())
        .unwrap_or_default()
}

async fn video_provider_for(owner_iid: i64, pool: &PgPool, override_provider: &str) -> String {
    if !override_provider.trim().is_empty() {
        return provider_normalize(override_provider);
    }
    if owner_iid <= 0 {
        return "auto".into();
    }
    generation_prefs_get(pool, owner_iid)
        .await
        .map(|p| p.video)
        .unwrap_or_else(|_| "auto".into())
}

fn effective_video_provider(provider: &str) -> String {
    if provider == "auto" {
        "seedance".into()
    } else {
        provider.to_string()
    }
}

pub async fn vid_generate_exec(
    pool: &PgPool,
    owner_iid: i64,
    client: &reqwest::Client,
    prompt: &str,
    aspect_ratio: &str,
    provider_override: &str,
) -> Result<Value> {
    let prompt = prompt.trim();
    if prompt.is_empty() {
        bail!("video prompt cannot be empty");
    }
    let ar = if aspect_ratio.trim().is_empty() { "16:9" } else { aspect_ratio.trim() };
    let provider = video_provider_for(owner_iid, pool, provider_override).await;
    if provider_normalize(&provider) == "gemini" {
        bail!("Gemini Veo video is not enabled yet; choose Auto or Seedance.");
    }
    let (bytes, model) = cf_video_run(client, prompt, ar, None).await?;
    let media_provider = effective_video_provider(&provider);
    let meta = VideoRunMeta {
        media_provider: media_provider.clone(),
        media_model: model.clone(),
        wholesale_usd: video_tool_wholesale_usd(&media_provider, &model),
    };
    let mime = "video/mp4";
    let secret = cas_secret_from_env();
    let put = cas_put(pool, &cas_dir_default(), &secret, &bytes, mime).await?;
    Ok(vid_tool_response("vid.generate", &put, prompt, ar, &meta))
}

fn vid_tool_response(tool: &str, put: &c35_mod_file::CasPutResult, prompt: &str, aspect_ratio: &str, meta: &VideoRunMeta) -> Value {
    json!({
        "ok": true,
        "runner": "cluster",
        "tool": tool,
        "file_hash": put.hash,
        "preview_url": put.url,
        "mime": put.mime_type,
        "prompt": prompt,
        "aspect_ratio": aspect_ratio,
        "media_provider": meta.media_provider,
        "media_model": meta.media_model,
        "wholesale_usd": meta.wholesale_usd,
        "block": {
            "kind": "video",
            "collapsed": false,
            "body": {
                "hash": put.hash,
                "url": put.url,
                "mime": put.mime_type,
                "prompt": prompt,
                "aspect_ratio": aspect_ratio,
                "media_provider": meta.media_provider,
                "media_model": meta.media_model,
                "tool": tool,
            }
        }
    })
}

pub fn vid_retail_estimate(provider: &str, model: &str) -> f64 {
    video_retail_quote(provider, model)
}
