use anyhow::{bail, Result};
use c35_mod_billing::music_tool_wholesale_usd;
use c35_mod_file::{cas_dir_default, cas_put};
use c35_mod_llm::{cf_music_run, lyria_run, CF_MUSIC_DURATION_SEC_DEFAULT};
use serde_json::{json, Value};
use sqlx::PgPool;

use crate::generation::{generation_prefs_get, music_retail_quote, provider_normalize};
use crate::prompt::gemini::gemini_api_key;

#[derive(Debug, Clone)]
pub struct MusicRunMeta {
    pub media_provider: String,
    pub media_model: String,
    pub duration_sec: i32,
    pub wholesale_usd: f64,
}

fn cas_secret_from_env() -> String {
    ["CAS_HMAC_SECRET", "C35_JWT_SECRET", "AGENT_SECRET_KEY"]
        .into_iter()
        .find_map(|k| std::env::var(k).ok())
        .unwrap_or_default()
}

async fn music_provider_for(owner_iid: i64, pool: &PgPool, override_provider: &str) -> String {
    if !override_provider.trim().is_empty() {
        return provider_normalize(override_provider);
    }
    if owner_iid <= 0 {
        return "auto".into();
    }
    generation_prefs_get(pool, owner_iid)
        .await
        .map(|p| p.music)
        .unwrap_or_else(|_| "auto".into())
}

fn effective_music_provider(provider: &str) -> String {
    match provider_normalize(provider).as_str() {
        "auto" | "" => "elevenlabs".into(),
        "gemini" | "lyria" => "gemini".into(),
        other => other.to_string(),
    }
}

fn cf_music_model(provider: &str) -> Option<&'static str> {
    match provider_normalize(provider).as_str() {
        "minimax" => Some("minimax/music-2.6"),
        _ => None,
    }
}

pub async fn music_generate_exec(
    pool: &PgPool,
    owner_iid: i64,
    client: &reqwest::Client,
    prompt: &str,
    duration_sec: i32,
    instrumental: bool,
    provider_override: &str,
) -> Result<Value> {
    let prompt = prompt.trim();
    if prompt.is_empty() {
        bail!("music prompt cannot be empty");
    }
    let provider = music_provider_for(owner_iid, pool, provider_override).await;
    let media_provider = effective_music_provider(&provider);
    let duration = if duration_sec > 0 {
        duration_sec
    } else {
        CF_MUSIC_DURATION_SEC_DEFAULT
    };
    let backend = provider_normalize(&provider);
    let (bytes, model, mime) = if backend == "gemini" || backend == "lyria" {
        let (b, m) = lyria_run(client, &gemini_api_key(), prompt).await?;
        (b, m, "audio/mpeg")
    } else {
        let cf_model = cf_music_model(&backend);
        let (b, m) = cf_music_run(client, prompt, duration, instrumental, cf_model).await?;
        (b, m, "audio/mpeg")
    };
    let meta = MusicRunMeta {
        media_provider: media_provider.clone(),
        media_model: model.clone(),
        duration_sec: duration,
        wholesale_usd: music_tool_wholesale_usd(&media_provider, &model, duration),
    };
    let secret = cas_secret_from_env();
    let put = cas_put(pool, &cas_dir_default(), &secret, &bytes, mime).await?;
    Ok(music_tool_response(
        "music.generate",
        &put,
        prompt,
        duration,
        instrumental,
        &meta,
    ))
}

fn music_tool_response(
    tool: &str,
    put: &c35_mod_file::CasPutResult,
    prompt: &str,
    duration_sec: i32,
    instrumental: bool,
    meta: &MusicRunMeta,
) -> Value {
    json!({
        "ok": true,
        "runner": "cluster",
        "tool": tool,
        "file_hash": put.hash,
        "preview_url": put.url,
        "mime": put.mime_type,
        "prompt": prompt,
        "duration_sec": duration_sec,
        "instrumental": instrumental,
        "media_provider": meta.media_provider,
        "media_model": meta.media_model,
        "wholesale_usd": meta.wholesale_usd,
        "block": {
            "kind": "music",
            "collapsed": false,
            "body": {
                "hash": put.hash,
                "url": put.url,
                "mime": put.mime_type,
                "prompt": prompt,
                "duration_sec": duration_sec,
                "instrumental": instrumental,
                "media_provider": meta.media_provider,
                "media_model": meta.media_model,
                "tool": tool,
            }
        }
    })
}

pub fn music_retail_estimate(provider: &str, model: &str, duration_sec: i32) -> f64 {
    music_retail_quote(provider, model, duration_sec)
}
