use std::path::Path;

use anyhow::Result;
use c35_store::snowflake_id;
use reqwest::Client;
use sqlx::PgPool;

use crate::format::channel_text_format;
use crate::render::{fs_public_url, media_mime_resolve, outbound_payload_parse, OutboundMediaKind, OutboundPayload};
use crate::speech::{is_ogg_audio, speech_lang_tts_code, speech_text_clean, web_tts_logged};
use crate::store::{ChannelDoc, PROVIDER_LINKED};
use crate::telegram::{tg_api_base, tg_send_document_bytes, tg_send_message, tg_send_photo_url, tg_send_voice_reply};
use crate::whatsapp::{wa_cloud_send_audio, wa_cloud_send_media};

pub struct ChannelCasCtx<'a> {
    pub pool: &'a PgPool,
    pub cas_dir: &'a Path,
    pub cas_secret: &'a str,
}

#[derive(Clone)]
pub struct OutboundCtx {
    pub platform: String,
    pub peer_id: String,
    pub channel: ChannelDoc,
    pub owner_iid: i64,
    pub bot_iid: i64,
}

pub fn outbound_ctx_from_channel(platform: &str, peer_id: &str, channel: &ChannelDoc) -> OutboundCtx {
    OutboundCtx {
        platform: platform.to_string(),
        peer_id: peer_id.to_string(),
        channel: channel.clone(),
        owner_iid: 0,
        bot_iid: 0,
    }
}

pub fn outbound_ctx_new(
    platform: &str,
    peer_id: &str,
    channel: &ChannelDoc,
    owner_iid: i64,
    bot_iid: i64,
) -> OutboundCtx {
    OutboundCtx {
        platform: platform.to_string(),
        peer_id: peer_id.to_string(),
        channel: channel.clone(),
        owner_iid,
        bot_iid,
    }
}

pub async fn channel_reply(client: &Client, ctx: &OutboundCtx, reply_text: &str, speak: bool) -> Result<()> {
    channel_reply_nats(client, None, None, ctx, reply_text, speak).await
}

pub async fn channel_reply_nats(
    client: &Client,
    nats: Option<&async_nats::Client>,
    cas: Option<&ChannelCasCtx<'_>>,
    ctx: &OutboundCtx,
    reply_text: &str,
    speak: bool,
) -> Result<()> {
    let payload = outbound_payload_parse(reply_text);
    if payload.text.trim().is_empty() && payload.media.is_empty() {
        return Ok(());
    }
    let plain = payload.text.clone();
    let formatted = if speak { plain.clone() } else { channel_text_format(&ctx.platform, &plain) };
    if ctx.platform == "telegram" {
        return deliver_telegram(client, cas, ctx, &payload, &formatted, &plain, speak).await;
    }
    if ctx.platform == "whatsapp" {
        return deliver_whatsapp(client, nats, cas, ctx, &payload, &formatted, &plain, speak).await;
    }
    Ok(())
}

pub const TG_TEXT_MAX: usize = 4096;

pub fn tg_text_chunks(text: &str) -> Vec<&str> {
    if text.chars().count() <= TG_TEXT_MAX {
        return vec![text];
    }
    let mut out = Vec::new();
    let mut start = 0usize;
    let chars: Vec<(usize, char)> = text.char_indices().collect();
    while start < chars.len() {
        let end = (start + TG_TEXT_MAX).min(chars.len());
        let mut cut = end;
        if end < chars.len() {
            if let Some(i) = (start..end).rev().find(|&i| chars[i].1 == '\n') {
                cut = i + 1;
            } else if let Some(i) = (start..end).rev().find(|&i| chars[i].1.is_whitespace()) {
                cut = i + 1;
            }
        }
        let byte_start = chars[start].0;
        let byte_end = if cut >= chars.len() { text.len() } else { chars[cut].0 };
        let part = text[byte_start..byte_end].trim();
        if !part.is_empty() {
            out.push(part);
        }
        start = cut;
    }
    if out.is_empty() { vec![text] } else { out }
}

async fn deliver_telegram(
    client: &Client,
    cas: Option<&ChannelCasCtx<'_>>,
    ctx: &OutboundCtx,
    payload: &OutboundPayload,
    html: &str,
    plain: &str,
    speak: bool,
) -> Result<()> {
    if ctx.peer_id.is_empty() || ctx.channel.bot_token.is_empty() {
        anyhow::bail!("telegram channel missing peer or token");
    }
    let api = tg_api_base();
    let caption = speech_text_clean(plain);

    if speak && !caption.is_empty() {
        let lang = speech_lang_tts_code(&caption);
        if let Some(audio) = web_tts_logged(client, &caption, lang).await {
            if tg_send_voice_reply(client, &api, &ctx.channel.bot_token, &ctx.peer_id, &audio, &caption)
                .await
                .is_ok()
            {
                send_telegram_media(client, cas, ctx, payload, "").await?;
                return Ok(());
            }
        }
    }

    if !html.is_empty() {
        let plain_chunks = tg_text_chunks(plain);
        let html_chunks = tg_text_chunks(html);
        for (i, part_html) in html_chunks.into_iter().enumerate() {
            let fallback = plain_chunks.get(i).copied().unwrap_or(part_html);
            if tg_send_message(client, &api, &ctx.channel.bot_token, &ctx.peer_id, part_html, Some("HTML"))
                .await
                .is_err()
            {
                tg_send_message(client, &api, &ctx.channel.bot_token, &ctx.peer_id, fallback, None)
                    .await
                    .map_err(|e| anyhow::anyhow!(e))?;
            }
        }
    }
    send_telegram_media(client, cas, ctx, payload, &caption).await?;
    Ok(())
}

async fn send_telegram_media(
    client: &Client,
    cas: Option<&ChannelCasCtx<'_>>,
    ctx: &OutboundCtx,
    payload: &OutboundPayload,
    caption: &str,
) -> Result<()> {
    if payload.media.is_empty() {
        return Ok(());
    }
    let cas_ctx = cas.ok_or_else(|| anyhow::anyhow!("cas context required for telegram media"))?;
    let api = tg_api_base();
    for item in &payload.media {
        if item.hash.is_empty() {
            continue;
        }
        let mime = media_mime_resolve(cas_ctx.pool, &item.hash, &item.mime).await;
        match item.kind {
            OutboundMediaKind::Image => {
                let _ = tg_send_photo_url(
                    client,
                    &api,
                    &ctx.channel.bot_token,
                    &ctx.peer_id,
                    &fs_public_url(&item.hash),
                    caption,
                )
                .await;
            }
            OutboundMediaKind::Audio | OutboundMediaKind::Document => {
                if let Ok((bytes, _)) =
                    c35_mod_file::cas_bytes_get(cas_ctx.pool, cas_ctx.cas_dir, &item.hash).await
                {
                    let _ = tg_send_document_bytes(
                        client,
                        &api,
                        &ctx.channel.bot_token,
                        &ctx.peer_id,
                        &bytes,
                        &mime,
                        &item.name,
                        caption,
                    )
                    .await;
                }
            }
        }
    }
    Ok(())
}

async fn deliver_whatsapp(
    client: &Client,
    nats: Option<&async_nats::Client>,
    cas: Option<&ChannelCasCtx<'_>>,
    ctx: &OutboundCtx,
    payload: &OutboundPayload,
    formatted: &str,
    plain: &str,
    speak: bool,
) -> Result<()> {
    if ctx.channel.provider == PROVIDER_LINKED {
        return deliver_whatsapp_device(client, nats, cas, ctx, payload, formatted, plain, speak).await;
    }
    deliver_whatsapp_meta(client, cas, ctx, payload, formatted, plain, speak).await
}

async fn tts_audio_hash(client: &Client, cas: &ChannelCasCtx<'_>, caption: &str) -> Option<String> {
    let lang = speech_lang_tts_code(caption);
    let audio = web_tts_logged(client, caption, lang).await?;
    let put = c35_mod_file::cas_put(cas.pool, cas.cas_dir, cas.cas_secret, &audio, "audio/mpeg")
        .await
        .ok()?;
    Some(put.hash)
}

async fn whatsapp_media_json(
    cas: &ChannelCasCtx<'_>,
    payload: &OutboundPayload,
    caption: &str,
) -> Vec<serde_json::Value> {
    let mut out = Vec::new();
    for item in &payload.media {
        if item.hash.is_empty() {
            continue;
        }
        let mime = media_mime_resolve(cas.pool, &item.hash, &item.mime).await;
        out.push(serde_json::json!({
            "kind": match item.kind {
                OutboundMediaKind::Image => "image",
                OutboundMediaKind::Audio => "audio",
                OutboundMediaKind::Document => "document",
            },
            "hash": item.hash,
            "mime": mime,
            "name": item.name,
            "caption": caption,
        }));
    }
    out
}

async fn deliver_whatsapp_device(
    client: &Client,
    nats: Option<&async_nats::Client>,
    cas: Option<&ChannelCasCtx<'_>>,
    ctx: &OutboundCtx,
    payload: &OutboundPayload,
    text: &str,
    plain: &str,
    speak: bool,
) -> Result<()> {
    let nats_client = nats.ok_or_else(|| anyhow::anyhow!("NATS client unavailable for whatsapp linked reply"))?;
    let caption = speech_text_clean(plain);
    let mut media = if let Some(cas_ctx) = cas {
        whatsapp_media_json(cas_ctx, payload, &caption).await
    } else {
        Vec::new()
    };
    if speak && !caption.is_empty() {
        if let Some(cas_ctx) = cas {
            if let Some(hash) = tts_audio_hash(client, cas_ctx, &caption).await {
                media.insert(
                    0,
                    serde_json::json!({
                        "kind": "audio",
                        "hash": hash,
                        "mime": "audio/mpeg",
                        "name": "reply.mp3",
                        "caption": caption,
                    }),
                );
            }
        }
    }
    let act = serde_json::json!({
        "bot_iid": ctx.bot_iid,
        "channel_id": ctx.channel.id,
        "recipient_id": ctx.peer_id,
        "text": text,
        "media": media,
        "speak": speak,
        "stream_part": false,
        "quote_msg_id": "",
        "quote_text": "",
    });
    let subject = format!("c35.act.channel.{}.{}.{}.msg.send", ctx.owner_iid, ctx.bot_iid, ctx.channel.id);
    let payload = serde_json::to_vec(&act)?;
    nats_client
        .publish(subject, payload.into())
        .await
        .map_err(|e| anyhow::anyhow!("NATS publish failed: {e}"))?;
    Ok(())
}

async fn deliver_whatsapp_meta(
    client: &Client,
    cas: Option<&ChannelCasCtx<'_>>,
    ctx: &OutboundCtx,
    payload: &OutboundPayload,
    text: &str,
    plain: &str,
    speak: bool,
) -> Result<()> {
    if ctx.channel.phone_number_id.is_empty() || ctx.channel.access_token.is_empty() {
        anyhow::bail!("whatsapp meta channel missing credentials");
    }
    let to = ctx.peer_id.split('@').next().unwrap_or(&ctx.peer_id);
    let caption = speech_text_clean(plain);

    if speak && !caption.is_empty() {
        let lang = speech_lang_tts_code(&caption);
        if let Some(audio) = web_tts_logged(client, &caption, lang).await {
            let voice = is_ogg_audio("audio/mpeg", &audio);
            if wa_cloud_send_audio(
                client,
                &ctx.channel.phone_number_id,
                &ctx.channel.access_token,
                to,
                &audio,
                if voice { "audio/ogg" } else { "audio/mpeg" },
                voice,
            )
            .await
            .is_ok()
            {
                send_whatsapp_meta_media(client, cas, ctx, payload, "", to).await?;
                if voice {
                    return Ok(());
                }
            }
        }
    }

    if !text.is_empty() {
        for part in wa_text_chunks(text) {
            wa_cloud_send_text(
                client,
                &ctx.channel.phone_number_id,
                &ctx.channel.access_token,
                to,
                part,
            )
            .await
            .map_err(|e| anyhow::anyhow!(e))?;
        }
    }
    send_whatsapp_meta_media(client, cas, ctx, payload, &caption, to).await?;
    Ok(())
}

async fn send_whatsapp_meta_media(
    client: &Client,
    cas: Option<&ChannelCasCtx<'_>>,
    ctx: &OutboundCtx,
    payload: &OutboundPayload,
    caption: &str,
    to: &str,
) -> Result<()> {
    if payload.media.is_empty() {
        return Ok(());
    }
    let cas_ctx = cas.ok_or_else(|| anyhow::anyhow!("cas context required for whatsapp media"))?;
    for item in &payload.media {
        if item.hash.is_empty() {
            continue;
        }
        let mime = media_mime_resolve(cas_ctx.pool, &item.hash, &item.mime).await;
        let (bytes, _) = c35_mod_file::cas_bytes_get(cas_ctx.pool, cas_ctx.cas_dir, &item.hash)
            .await
            .map_err(|e| anyhow::anyhow!("{e}"))?;
        wa_cloud_send_media(
            client,
            &ctx.channel.phone_number_id,
            &ctx.channel.access_token,
            to,
            &bytes,
            &mime,
            &item.name,
            caption,
            item.kind == OutboundMediaKind::Image,
        )
        .await
        .map_err(|e| anyhow::anyhow!(e))?;
    }
    Ok(())
}

const WA_CLOUD_TEXT_MAX: usize = 4096;

pub fn wa_text_chunks(text: &str) -> Vec<&str> {
    if text.chars().count() <= WA_CLOUD_TEXT_MAX {
        return vec![text];
    }
    let mut out = Vec::new();
    let mut start = 0usize;
    let chars: Vec<(usize, char)> = text.char_indices().collect();
    while start < chars.len() {
        let end = (start + WA_CLOUD_TEXT_MAX).min(chars.len());
        let mut cut = end;
        if end < chars.len() {
            if let Some(i) = (start..end).rev().find(|&i| chars[i].1.is_whitespace()) {
                cut = i + 1;
            }
        }
        let byte_start = chars[start].0;
        let byte_end = if cut >= chars.len() { text.len() } else { chars[cut].0 };
        let part = text[byte_start..byte_end].trim();
        if !part.is_empty() {
            out.push(part);
        }
        start = cut;
    }
    if out.is_empty() { vec![text] } else { out }
}

async fn wa_cloud_send_text(
    client: &Client,
    phone_number_id: &str,
    access_token: &str,
    to: &str,
    text: &str,
) -> Result<(), String> {
    let graph = meta_graph_base();
    let url = format!("{graph}/{phone_number_id}/messages");
    let res = client
        .post(&url)
        .header("Authorization", format!("Bearer {access_token}"))
        .json(&serde_json::json!({
            "messaging_product": "whatsapp",
            "to": to,
            "type": "text",
            "text": { "body": text }
        }))
        .send()
        .await
        .map_err(|e| e.to_string())?;
    if !res.status().is_success() {
        let body = res.text().await.unwrap_or_default();
        return Err(format!("Meta Cloud send failed: {body}"));
    }
    Ok(())
}

fn meta_graph_base() -> String {
    std::env::var("META_GRAPH_API_BASE")
        .ok()
        .filter(|s| !s.trim().is_empty())
        .unwrap_or_else(|| "https://graph.facebook.com/v21.0".to_string())
        .trim_end_matches('/')
        .to_string()
}

pub fn channel_stub_reply(inbound_text: &str, speak: bool) -> String {
    let prefix = if speak { "(voice) " } else { "" };
    format!("{prefix}Echo: {}", inbound_text.trim())
}

pub fn channel_req_id(platform: &str) -> String {
    format!("chan_{}_{}", platform, snowflake_id())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn wa_chunks_long_text() {
        let text = "word ".repeat(900);
        let chunks = wa_text_chunks(text.trim());
        assert!(chunks.len() > 1);
        for part in chunks {
            assert!(part.chars().count() <= WA_CLOUD_TEXT_MAX);
        }
    }

    #[test]
    fn tg_chunks_long_text() {
        let text = "sentence here. \n".repeat(300);
        let chunks = tg_text_chunks(text.trim());
        assert!(chunks.len() > 1);
        for part in chunks {
            assert!(part.chars().count() <= TG_TEXT_MAX);
        }
    }

    #[test]
    fn thought_stripped_in_reply_path() {
        use crate::render::outbound_payload_parse;
        let raw = "<thought>plan</thought>\nHello **there**";
        let p = outbound_payload_parse(raw);
        assert_eq!(p.text, "Hello **there**");
    }
}
