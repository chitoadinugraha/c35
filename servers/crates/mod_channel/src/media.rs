use anyhow::{Context, Result};
use c35_mod_chat::audio::{self, transcript_valid};
use c35_mod_file::cas_bytes_get;
use reqwest::Client;
use sqlx::PgPool;
use tracing::warn;

use crate::telegram::tg_api_base;
use crate::types::ChannelInboundAttachment;

pub fn channel_voice_placeholder(text: &str) -> bool {
    matches!(text.trim().to_lowercase().as_str(), "[voice]" | "[audio]" | "[sticker]")
}

pub async fn transcribe_cas_attachments(
    client: &Client,
    pool: &PgPool,
    cas_dir: &std::path::Path,
    items: &[ChannelInboundAttachment],
) -> Result<String> {
    let mut parts = Vec::new();
    for item in items {
        if item.hash.is_empty() || !item.mime.starts_with("audio/") {
            continue;
        }
        let (bytes, mime) = cas_bytes_get(pool, cas_dir, &item.hash)
            .await
            .with_context(|| format!("cas read hash={}", item.hash))?;
        let mime = audio::audio_mime_resolve(&item.mime, &mime, &bytes);
        let transcript = audio::transcribe_audio(client, &bytes, &mime)
            .await
            .with_context(|| format!("transcribe hash={}", item.hash))?;
        let t = transcript.trim();
        if transcript_valid(t) {
            parts.push(t.to_string());
        }
    }
    Ok(parts.join(" "))
}

pub async fn transcribe_telegram_voice(
    client: &Client,
    bot_token: &str,
    items: &[ChannelInboundAttachment],
) -> Result<String> {
    let mut parts = Vec::new();
    for item in items {
        if item.media_id.is_empty() || !item.mime.starts_with("audio/") {
            continue;
        }
        let (bytes, dl_mime) = tg_file_download(client, bot_token, &item.media_id)
            .await
            .with_context(|| format!("telegram download file_id={}", item.media_id))?;
        let mime = audio::audio_mime_resolve(&item.mime, &dl_mime, &bytes);
        let transcript = audio::transcribe_audio(client, &bytes, &mime)
            .await
            .with_context(|| format!("transcribe file_id={}", item.media_id))?;
        let t = transcript.trim();
        if transcript_valid(t) {
            parts.push(t.to_string());
        }
    }
    Ok(parts.join(" "))
}

pub async fn transcribe_voice_logged(
    client: &Client,
    pool: &PgPool,
    cas_dir: &std::path::Path,
    bot_token: &str,
    items: &[ChannelInboundAttachment],
) -> String {
    if !bot_token.is_empty() {
        if let Ok(t) = transcribe_telegram_voice(client, bot_token, items).await {
            if !t.trim().is_empty() {
                return t;
            }
        }
    }
    match transcribe_cas_attachments(client, pool, cas_dir, items).await {
        Ok(t) => t,
        Err(e) => {
            warn!("[c35:channel] voice transcribe failed: {e:#}");
            String::new()
        }
    }
}

async fn tg_file_download(client: &Client, bot_token: &str, file_id: &str) -> Result<(Vec<u8>, String)> {
    let api_base = tg_api_base();
    let file_path = tg_file_path(client, &api_base, bot_token, file_id).await?;
    let url = format!("{api_base}/file/bot{bot_token}/{file_path}");
    let res = client.get(&url).send().await.context("telegram file download")?;
    if !res.status().is_success() {
        return Err(anyhow::anyhow!("telegram file download status {}", res.status()));
    }
    let mime = res
        .headers()
        .get(reqwest::header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("audio/ogg")
        .split(';')
        .next()
        .unwrap_or("audio/ogg")
        .to_string();
    let bytes = res.bytes().await.context("telegram file body")?.to_vec();
    Ok((bytes, mime))
}

async fn tg_file_path(client: &Client, api_base: &str, bot_token: &str, file_id: &str) -> Result<String> {
    let url = format!("{api_base}/bot{bot_token}/getFile");
    let res = client.post(&url).json(&serde_json::json!({ "file_id": file_id })).send().await.context("telegram getFile")?;
    let body: serde_json::Value = res.json().await.context("telegram getFile json")?;
    if body.get("ok").and_then(|v| v.as_bool()) != Some(true) {
        let desc = body.get("description").and_then(|d| d.as_str()).unwrap_or("getFile failed");
        return Err(anyhow::anyhow!("{desc}"));
    }
    body.get("result")
        .and_then(|r| r.get("file_path"))
        .and_then(|p| p.as_str())
        .map(str::to_string)
        .ok_or_else(|| anyhow::anyhow!("getFile missing file_path"))
}
