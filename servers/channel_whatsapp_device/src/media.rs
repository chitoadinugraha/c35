use anyhow::{Context, Result};
use dashmap::DashMap;
use serde::Serialize;
use std::str::FromStr;
use std::sync::OnceLock;
use std::time::{Duration, Instant};
use tracing::warn;
use wa_rs::Jid;

#[derive(Debug, Clone, Serialize)]
pub struct UploadedMedia {
    pub hash: String,
    pub name: String,
    pub mime: String,
}

#[derive(Debug, Clone)]
pub struct InboundPayload {
    pub text: String,
    pub attachments: Vec<UploadedMedia>,
    pub is_voice: bool,
    pub quoted_msg_id: String,
    pub quoted_text: String,
}

impl InboundPayload {
    fn with_quote(mut self, msg: &wa_rs::wa_rs_proto::whatsapp::Message) -> Self {
        let (id, text) = inbound_quote(msg);
        self.quoted_msg_id = id;
        self.quoted_text = text;
        self
    }
}

fn inbound_quote(msg: &wa_rs::wa_rs_proto::whatsapp::Message) -> (String, String) {
    let ctx = message_context_info(msg);
    (
        ctx.and_then(|c| c.stanza_id.clone()).unwrap_or_default(),
        ctx.and_then(|c| c.quoted_message.as_ref()).map(|q| quoted_body(q)).unwrap_or_default(),
    )
}

fn message_context_info(msg: &wa_rs::wa_rs_proto::whatsapp::Message) -> Option<&wa_rs::wa_rs_proto::whatsapp::ContextInfo> {
    msg.extended_text_message.as_ref().and_then(|m| m.context_info.as_deref())
        .or_else(|| msg.image_message.as_ref().and_then(|m| m.context_info.as_deref()))
        .or_else(|| msg.video_message.as_ref().and_then(|m| m.context_info.as_deref()))
        .or_else(|| msg.document_message.as_ref().and_then(|m| m.context_info.as_deref()))
        .or_else(|| msg.audio_message.as_ref().and_then(|m| m.context_info.as_deref()))
        .or_else(|| msg.sticker_message.as_ref().and_then(|m| m.context_info.as_deref()))
}

fn quoted_body(msg: &wa_rs::wa_rs_proto::whatsapp::Message) -> String {
    msg.conversation.clone()
        .or_else(|| msg.extended_text_message.as_ref().and_then(|m| m.text.clone()))
        .or_else(|| msg.image_message.as_ref().and_then(|m| m.caption.clone()))
        .or_else(|| msg.video_message.as_ref().and_then(|m| m.caption.clone()))
        .or_else(|| msg.document_message.as_ref().and_then(|m| m.caption.clone()))
        .unwrap_or_default()
}

pub async fn upload_channel_media(
    http: &reqwest::Client,
    bot_iid: i64,
    channel_id: &str,
    secret: &str,
    name: &str,
    mime: &str,
    bytes: &[u8],
) -> Result<UploadedMedia> {
    if secret.is_empty() {
        anyhow::bail!("media upload disabled — no webhook secret");
    }
    let base = media_upload_base();
    let url = format!("{base}/v1/channels/whatsapp/webhook/{bot_iid}/{channel_id}/media");
    let res = http
        .post(url)
        .header("content-type", mime)
        .header("x-file-name", name)
        .body(bytes.to_vec())
        .send()
        .await
        .context("media upload request")?;
    if !res.status().is_success() {
        let body = res.text().await.unwrap_or_default();
        anyhow::bail!("media upload failed: {body}");
    }
    let json: serde_json::Value = res.json().await.context("media upload json")?;
    Ok(UploadedMedia {
        hash: json.get("hash").and_then(|v| v.as_str()).unwrap_or_default().to_string(),
        name: json.get("name").and_then(|v| v.as_str()).unwrap_or(name).to_string(),
        mime: json.get("mime").and_then(|v| v.as_str()).unwrap_or(mime).to_string(),
    })
}

fn media_upload_base() -> String {
    std::env::var("C35_PUBLIC_ORIGIN")
        .or_else(|_| std::env::var("CS_PUBLIC_ORIGIN"))
        .or_else(|_| std::env::var("WHATSAPP_MEDIA_UPLOAD_BASE"))
        .ok()
        .map(|s| s.trim().trim_end_matches('/').to_string())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| "http://c35-server.c35.svc.cluster.local:8080".to_string())
}

const AVATAR_CACHE_TTL: Duration = Duration::from_secs(24 * 60 * 60);

fn avatar_cache() -> &'static DashMap<String, (String, Instant)> {
    static CACHE: OnceLock<DashMap<String, (String, Instant)>> = OnceLock::new();
    CACHE.get_or_init(DashMap::new)
}

/// Fetch peer profile picture (preview), upload to CAS via media webhook, return blake3 hash.
/// Cached per peer for 24h. Best-effort — returns empty string on failure.
pub async fn peer_avatar_hash(
    http: &reqwest::Client,
    client: &wa_rs::Client,
    bot_iid: i64,
    channel_id: &str,
    webhook_secret: &str,
    peer_id: &str,
) -> String {
    let peer_id = peer_id.trim();
    if peer_id.is_empty() || webhook_secret.is_empty() {
        return String::new();
    }
    let cache_key = format!("{channel_id}:{peer_id}");
    if let Some(entry) = avatar_cache().get(&cache_key) {
        let (hash, at) = entry.value();
        if at.elapsed() < AVATAR_CACHE_TTL && !hash.is_empty() {
            return hash.clone();
        }
    }
    match peer_avatar_fetch_upload(http, client, bot_iid, channel_id, webhook_secret, peer_id).await {
        Ok(hash) if !hash.is_empty() => {
            avatar_cache().insert(cache_key, (hash.clone(), Instant::now()));
            hash
        }
        Ok(_) => String::new(),
        Err(e) => {
            warn!("[wa-device] peer avatar failed channel_id={channel_id} peer={peer_id}: {e:#}");
            String::new()
        }
    }
}

async fn peer_avatar_fetch_upload(
    http: &reqwest::Client,
    client: &wa_rs::Client,
    bot_iid: i64,
    channel_id: &str,
    webhook_secret: &str,
    peer_id: &str,
) -> Result<String> {
    let jid = Jid::from_str(peer_id).context("peer jid")?;
    let Some(pic) = client.contacts().get_profile_picture(&jid, true).await.context("get_profile_picture")? else {
        return Ok(String::new());
    };
    if pic.url.trim().is_empty() {
        return Ok(String::new());
    }
    let res = http.get(&pic.url).send().await.context("avatar download")?;
    if !res.status().is_success() {
        anyhow::bail!("avatar download status {}", res.status());
    }
    let mime = res
        .headers()
        .get(reqwest::header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("image/jpeg")
        .split(';')
        .next()
        .unwrap_or("image/jpeg")
        .to_string();
    let mime = if mime.starts_with("image/") { mime } else { "image/jpeg".into() };
    let bytes = res.bytes().await.context("avatar body")?;
    if bytes.is_empty() {
        return Ok(String::new());
    }
    let uploaded = upload_channel_media(http, bot_iid, channel_id, webhook_secret, "avatar.jpg", &mime, &bytes).await?;
    Ok(uploaded.hash)
}

pub async fn extract_message_payload(
    http: &reqwest::Client,
    client: &wa_rs::Client,
    bot_iid: i64,
    channel_id: &str,
    webhook_secret: &str,
    msg: &wa_rs::wa_rs_proto::whatsapp::Message,
) -> Option<InboundPayload> {
    let text = msg
        .conversation
        .clone()
        .or_else(|| {
            msg.extended_text_message
                .as_ref()
                .and_then(|m| m.text.clone())
        })
        .unwrap_or_default();
    let mut attachments = Vec::new();
    if let Some(img) = msg.image_message.as_ref() {
        if let Ok(bytes) = client.download(img.as_ref()).await {
            let name = "image.jpg";
            let mime = img.mimetype.as_deref().unwrap_or("image/jpeg");
            match upload_channel_media(http, bot_iid, channel_id, webhook_secret, name, mime, &bytes).await {
                Ok(att) => attachments.push(att),
                Err(e) => warn!("[wa-channel] image upload failed channel_id={channel_id}: {e:#}"),
            }
        }
        let caption = img.caption.as_deref().unwrap_or("[image]").to_string();
        return Some(InboundPayload {
            text: if text.is_empty() { caption } else { text },
            attachments,
            is_voice: false,
            quoted_msg_id: String::new(),
            quoted_text: String::new(),
        }.with_quote(msg));
    }
    if let Some(doc) = msg.document_message.as_ref() {
        if let Ok(bytes) = client.download(doc.as_ref()).await {
            let name = doc.file_name.as_deref().unwrap_or("document");
            let mime = doc.mimetype.as_deref().unwrap_or("application/octet-stream");
            match upload_channel_media(http, bot_iid, channel_id, webhook_secret, name, mime, &bytes).await {
                Ok(att) => attachments.push(att),
                Err(e) => warn!("[wa-channel] document upload failed channel_id={channel_id}: {e:#}"),
            }
        }
        let caption = doc.caption.as_deref().unwrap_or("[document]").to_string();
        return Some(InboundPayload {
            text: if text.is_empty() { caption } else { text },
            attachments,
            is_voice: false,
            quoted_msg_id: String::new(),
            quoted_text: String::new(),
        }.with_quote(msg));
    }
    if let Some(audio) = msg.audio_message.as_ref() {
        let is_voice = audio.ptt == Some(true);
        if let Ok(bytes) = client.download(audio.as_ref()).await {
            let mime = audio.mimetype.as_deref().unwrap_or("audio/ogg");
            let name = if is_voice { "voice.ogg" } else { "audio.mp3" };
            match upload_channel_media(http, bot_iid, channel_id, webhook_secret, name, mime, &bytes).await {
                Ok(att) => attachments.push(att),
                Err(e) => warn!("[wa-channel] audio upload failed channel_id={channel_id}: {e:#}"),
            }
        }
        let fallback = if is_voice { "[voice]" } else { "[audio]" };
        return Some(InboundPayload {
            text: if text.is_empty() { fallback.into() } else { text },
            attachments,
            is_voice,
            quoted_msg_id: String::new(),
            quoted_text: String::new(),
        }.with_quote(msg));
    }
    if let Some(video) = msg.video_message.as_ref() {
        if let Ok(bytes) = client.download(video.as_ref()).await {
            let mime = video.mimetype.as_deref().unwrap_or("video/mp4");
            match upload_channel_media(http, bot_iid, channel_id, webhook_secret, "video.mp4", mime, &bytes).await {
                Ok(att) => attachments.push(att),
                Err(e) => warn!("[wa-channel] video upload failed channel_id={channel_id}: {e:#}"),
            }
        }
        let caption = video.caption.as_deref().unwrap_or("[video]").to_string();
        return Some(InboundPayload {
            text: if text.is_empty() { caption } else { text },
            attachments,
            is_voice: false,
            quoted_msg_id: String::new(),
            quoted_text: String::new(),
        }.with_quote(msg));
    }
    if let Some(sticker) = msg.sticker_message.as_ref() {
        if let Ok(bytes) = client.download(sticker.as_ref()).await {
            let mime = sticker.mimetype.as_deref().unwrap_or("image/webp");
            match upload_channel_media(http, bot_iid, channel_id, webhook_secret, "sticker.webp", mime, &bytes).await {
                Ok(att) => attachments.push(att),
                Err(e) => warn!("[wa-channel] sticker upload failed channel_id={channel_id}: {e:#}"),
            }
        }
        return Some(InboundPayload {
            text: if text.is_empty() { "[sticker]".into() } else { text },
            attachments,
            is_voice: false,
            quoted_msg_id: String::new(),
            quoted_text: String::new(),
        }.with_quote(msg));
    }
    if text.is_empty() {
        None
    } else {
        Some(InboundPayload {
            text,
            attachments,
            is_voice: false,
            quoted_msg_id: String::new(),
            quoted_text: String::new(),
        }.with_quote(msg))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use wa_rs::wa_rs_proto::whatsapp as wa;

    #[test]
    fn inbound_quote_from_extended_text() {
        let msg = wa::Message {
            extended_text_message: Some(Box::new(wa::message::ExtendedTextMessage {
                text: Some("reply".into()),
                context_info: Some(Box::new(wa::ContextInfo {
                    stanza_id: Some("SID".into()),
                    quoted_message: Some(Box::new(wa::Message {
                        conversation: Some("original".into()),
                        ..Default::default()
                    })),
                    ..Default::default()
                })),
                ..Default::default()
            })),
            ..Default::default()
        };
        let (id, text) = inbound_quote(&msg);
        assert_eq!(id, "SID");
        assert_eq!(text, "original");
    }

    #[test]
    fn inbound_quote_empty_without_context() {
        let msg = wa::Message { conversation: Some("hi".into()), ..Default::default() };
        assert_eq!(inbound_quote(&msg), (String::new(), String::new()));
    }
}
