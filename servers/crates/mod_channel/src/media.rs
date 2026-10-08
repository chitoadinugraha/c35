use anyhow::{Context, Result};
use c35_ctx::AppState;
use reqwest::Client;
use tracing::warn;

use crate::store::ChannelDoc;
use crate::telegram::tg_api_base;
use crate::types::ChannelInboundAttachment;

pub fn channel_voice_placeholder(text: &str) -> bool {
    matches!(text.trim().to_lowercase().as_str(), "[voice]" | "[audio]" | "[sticker]")
}

pub async fn resolve_inbound_attachments_cas(
    client: &Client,
    state: &AppState,
    channel: &ChannelDoc,
    items: &mut [ChannelInboundAttachment],
) {
    for item in items.iter_mut() {
        if !item.hash.is_empty() || item.media_id.is_empty() {
            continue;
        }
        let fetched = if channel.platform == "telegram" && !channel.bot_token.is_empty() {
            tg_file_download(client, &channel.bot_token, &item.media_id).await.ok()
        } else if channel.platform == "whatsapp" && !channel.access_token.is_empty() {
            crate::whatsapp::fetch_meta_cloud_media(client, &channel.access_token, &item.media_id).await.ok()
        } else {
            None
        };
        if let Some((bytes, dl_mime)) = fetched {
            let mime = if item.mime.is_empty() || item.mime == "application/octet-stream" {
                dl_mime
            } else {
                item.mime.clone()
            };
            if !crate::policy::inbound_attachment_allowed(&mime, &item.name, bytes.len()) {
                warn!(
                    "[c35:channel] inbound attachment rejected media_id={} bytes={} mime={}",
                    item.media_id,
                    bytes.len(),
                    mime
                );
                continue;
            }
            if let Ok(put) = c35_mod_file::cas_put(&state.pool, &state.cas_dir, &state.cas_secret, &bytes, &mime).await {
                item.hash = put.hash;
                item.mime = mime;
            }
        }
    }
}

pub async fn tg_file_download(client: &Client, bot_token: &str, file_id: &str) -> Result<(Vec<u8>, String)> {
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
