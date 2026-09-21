use crate::db;
use crate::manager::ChannelManager;
use crate::nats::{ActChannelMediaItem, ActChannelMsgSend, ActChannelMsgTyping, NatsService, QUEUE_OUTBOUND, SUBJ_MSG_SEND_WILDCARD, SUBJ_MSG_TYPING_WILDCARD};
use futures_util::StreamExt;
use std::str::FromStr;
use tracing::{error, info, warn};
use wa_rs::Jid;
use wa_rs::upload::UploadResponse;
use wa_rs_core::download::MediaType;
use wa_rs_core::proto_helpers::{build_quote_context, MessageExt};
use wa_rs::wa_rs_proto::whatsapp as wa;

async fn wa_outbound_log(
    pool: &sqlx::PgPool,
    nats: Option<&async_nats::Client>,
    bot_iid: i64,
    channel_id: &str,
    topic: &str,
    text: &str,
    meta: serde_json::Value,
) {
    let Ok(Some(row)) = db::channel_get(pool, bot_iid, channel_id).await else { return };
    let _ = db::channel_log(pool, nats, row.owner_iid, bot_iid, channel_id, topic, text, meta).await;
}

pub async fn start_outbound_worker(mgr: ChannelManager, nats: NatsService) {
    let client = nats.client().clone();
    let nats_log = Some(client.clone());
    let pool = mgr.pool.clone();
    let http = reqwest::Client::new();
    let mut send_sub = match client.queue_subscribe(SUBJ_MSG_SEND_WILDCARD.to_string(), QUEUE_OUTBOUND.to_string()).await {
        Ok(s) => s,
        Err(e) => {
            error!("[wa-device] outbound subscribe failed: {e}");
            return;
        }
    };
    let mut typing_sub = match client.queue_subscribe(SUBJ_MSG_TYPING_WILDCARD.to_string(), format!("{QUEUE_OUTBOUND}-typing")).await {
        Ok(s) => s,
        Err(e) => {
            error!("[wa-device] typing subscribe failed: {e}");
            return;
        }
    };
    info!("[wa-device] outbound worker listening subject={SUBJ_MSG_SEND_WILDCARD} queue={QUEUE_OUTBOUND}");

    loop {
        tokio::select! {
            Some(msg) = send_sub.next() => {
                let act = match serde_json::from_slice::<ActChannelMsgSend>(&msg.payload) {
                    Ok(v) => v,
                    Err(e) => {
                        warn!("[wa-device] invalid msg.send payload: {e}");
                        continue;
                    }
                };
                let Some(wa_client) = mgr.client_for(&act.channel_id) else {
                    warn!("[wa-device] skip send — no client channel_id={}", act.channel_id);
                    wa_outbound_log(
                        &pool,
                        nats_log.as_ref(),
                        act.bot_iid,
                        &act.channel_id,
                        "error",
                        "Send skipped — WhatsApp not connected",
                        serde_json::json!({ "recipient_id": act.recipient_id }),
                    )
                    .await;
                    continue;
                };
                let jid = match Jid::from_str(&act.recipient_id) {
                    Ok(j) => j,
                    Err(e) => {
                        warn!("[wa-device] bad recipient jid={} err={e}", act.recipient_id);
                        continue;
                    }
                };
                if let Err(e) = send_outbound(&http, &wa_client, jid, &act).await {
                    error!("[wa-device] send failed channel_id={}: {e:#}", act.channel_id);
                    wa_outbound_log(
                        &pool,
                        nats_log.as_ref(),
                        act.bot_iid,
                        &act.channel_id,
                        "error",
                        &format!("Send failed: {e:#}"),
                        serde_json::json!({ "recipient_id": act.recipient_id }),
                    )
                    .await;
                } else {
                    let preview = if act.text.trim().is_empty() {
                        "[media]".to_string()
                    } else {
                        act.text.clone()
                    };
                    wa_outbound_log(
                        &pool,
                        nats_log.as_ref(),
                        act.bot_iid,
                        &act.channel_id,
                        "msg_sent",
                        &format!("Outbound to {}: {}", act.recipient_id, preview),
                        serde_json::json!({
                            "recipient_id": act.recipient_id,
                            "op_id": act.op_id,
                            "media_count": act.media.len(),
                        }),
                    )
                    .await;
                }
            }
            Some(msg) = typing_sub.next() => {
                let act = match serde_json::from_slice::<ActChannelMsgTyping>(&msg.payload) {
                    Ok(v) => v,
                    Err(e) => {
                        warn!("[wa-device] invalid msg.typing payload: {e}");
                        continue;
                    }
                };
                let Some(wa_client) = mgr.client_for(&act.channel_id) else { continue; };
                let jid = match Jid::from_str(&act.recipient_id) {
                    Ok(j) => j,
                    Err(_) => continue,
                };
                if act.active {
                    let chatstate = wa_client.chatstate();
                    let res = if act.speak { chatstate.send_recording(&jid).await } else { chatstate.send_composing(&jid).await };
                    if let Err(e) = res { warn!("[wa-device] typing active failed: {e:#}"); }
                } else if let Err(e) = wa_client.chatstate().send_paused(&jid).await {
                    warn!("[wa-device] typing paused failed: {e:#}");
                }
            }
        }
    }
}

async fn send_outbound(http: &reqwest::Client, wa_client: &wa_rs::Client, jid: Jid, act: &ActChannelMsgSend) -> anyhow::Result<()> {
    let mut quote = quote_context(act);
    for item in &act.media {
        let q = quote.take();
        if let Err(e) = send_media_item(http, wa_client, jid.clone(), item, q.as_ref()).await {
            warn!("[wa-device] media send failed kind={}: {e:#}", item.kind);
        }
    }
    if !act.text.trim().is_empty() {
        for (i, part) in wa_text_parts(&act.text).into_iter().enumerate() {
            let q = if i == 0 { quote.take() } else { None };
            wa_client.send_message(jid.clone(), wa_text_message(part, q.as_ref())).await?;
        }
    }
    Ok(())
}

fn quote_context(act: &ActChannelMsgSend) -> Option<wa::ContextInfo> {
    if act.quote_msg_id.is_empty() {
        return None;
    }
    let quoted = wa::Message { conversation: Some(act.quote_text.clone()), ..Default::default() };
    Some(build_quote_context(act.quote_msg_id.clone(), act.recipient_id.clone(), &quoted))
}

fn wa_text_message(text: &str, quote: Option<&wa::ContextInfo>) -> wa::Message {
    match quote {
        Some(ctx) => wa::Message {
            extended_text_message: Some(Box::new(wa::message::ExtendedTextMessage {
                text: Some(text.to_string()),
                context_info: Some(Box::new(ctx.clone())),
                ..Default::default()
            })),
            ..Default::default()
        },
        None => wa::Message { conversation: Some(text.to_string()), ..Default::default() },
    }
}

fn wa_text_parts(text: &str) -> Vec<&str> {
    const MAX: usize = 4096;
    if text.chars().count() <= MAX {
        return vec![text];
    }
    let mut out = Vec::new();
    let mut start = 0usize;
    let chars: Vec<(usize, char)> = text.char_indices().collect();
    while start < chars.len() {
        let end = (start + MAX).min(chars.len());
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

async fn send_media_item(
    http: &reqwest::Client,
    wa_client: &wa_rs::Client,
    jid: Jid,
    item: &ActChannelMediaItem,
    quote: Option<&wa::ContextInfo>,
) -> anyhow::Result<()> {
    if item.hash.is_empty() {
        return Ok(());
    }
    let bytes = fs_download(http, &item.hash).await?;
    let media_type = match item.kind.as_str() {
        "image" => MediaType::Image,
        "audio" => MediaType::Audio,
        _ => MediaType::Document,
    };
    let upload = wa_client.upload(bytes, media_type).await?;
    let mut msg = build_media_message(item, upload);
    if let Some(ctx) = quote {
        let _ = msg.set_context_info(ctx.clone());
    }
    wa_client.send_message(jid, msg).await?;
    Ok(())
}

fn build_media_message(item: &ActChannelMediaItem, upload: UploadResponse) -> wa::Message {
    match item.kind.as_str() {
        "image" => wa::Message {
            image_message: Some(Box::new(wa::message::ImageMessage {
                mimetype: Some(item.mime.clone()),
                caption: Some(item.caption.clone()),
                url: Some(upload.url),
                direct_path: Some(upload.direct_path),
                media_key: Some(upload.media_key),
                file_enc_sha256: Some(upload.file_enc_sha256),
                file_sha256: Some(upload.file_sha256),
                file_length: Some(upload.file_length),
                ..Default::default()
            })),
            ..Default::default()
        },
        "audio" => wa::Message {
            audio_message: Some(Box::new(wa::message::AudioMessage {
                mimetype: Some(if item.mime.contains("ogg") || item.mime.contains("opus") {
                    "audio/ogg; codecs=opus".into()
                } else {
                    item.mime.clone()
                }),
                url: Some(upload.url),
                direct_path: Some(upload.direct_path),
                media_key: Some(upload.media_key),
                file_enc_sha256: Some(upload.file_enc_sha256),
                file_sha256: Some(upload.file_sha256),
                file_length: Some(upload.file_length),
                ptt: Some(item.mime.contains("ogg") || item.mime.contains("opus")),
                ..Default::default()
            })),
            ..Default::default()
        },
        _ => wa::Message {
            document_message: Some(Box::new(wa::message::DocumentMessage {
                mimetype: Some(item.mime.clone()),
                file_name: Some(item.name.clone()),
                caption: Some(item.caption.clone()),
                url: Some(upload.url),
                direct_path: Some(upload.direct_path),
                media_key: Some(upload.media_key),
                file_enc_sha256: Some(upload.file_enc_sha256),
                file_sha256: Some(upload.file_sha256),
                file_length: Some(upload.file_length),
                ..Default::default()
            })),
            ..Default::default()
        },
    }
}

async fn fs_download(http: &reqwest::Client, hash: &str) -> anyhow::Result<Vec<u8>> {
    let base = std::env::var("CS_PUBLIC_ORIGIN")
        .or_else(|_| std::env::var("WHATSAPP_MEDIA_UPLOAD_BASE"))
        .ok()
        .map(|s| s.trim().trim_end_matches('/').to_string())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| "http://cs-server.cs-bots.svc.cluster.local:8080".to_string());
    let url = format!("{base}/fs/{hash}");
    let res = http.get(url).send().await?;
    Ok(res.error_for_status()?.bytes().await?.to_vec())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn wa_text_message_quotes_with_context_info() {
        let ctx = wa::ContextInfo {
            stanza_id: Some("SID".into()),
            participant: Some("123@s.whatsapp.net".into()),
            quoted_message: Some(Box::new(wa::Message {
                conversation: Some("hi".into()),
                ..Default::default()
            })),
            ..Default::default()
        };
        let msg = wa_text_message("halo", Some(&ctx));
        let ext = msg.extended_text_message.expect("quoted replies use extended text");
        assert_eq!(ext.text.as_deref(), Some("halo"));
        assert_eq!(ext.context_info.unwrap().stanza_id.as_deref(), Some("SID"));
        assert!(msg.conversation.is_none());
    }

    #[test]
    fn wa_text_message_plain_without_quote() {
        let msg = wa_text_message("halo", None);
        assert_eq!(msg.conversation.as_deref(), Some("halo"));
        assert!(msg.extended_text_message.is_none());
    }

    #[test]
    fn quote_context_none_when_id_empty() {
        let act = ActChannelMsgSend {
            bot_iid: 1,
            channel_id: "ch1".into(),
            recipient_id: "123@s.whatsapp.net".into(),
            text: "halo".into(),
            op_id: None,
            media: vec![],
            speak: false,
            stream_part: false,
            quote_msg_id: String::new(),
            quote_text: "hi".into(),
        };
        assert!(quote_context(&act).is_none());
    }

    #[test]
    fn quote_context_sets_stanza_and_participant() {
        let act = ActChannelMsgSend {
            bot_iid: 1,
            channel_id: "ch1".into(),
            recipient_id: "123@s.whatsapp.net".into(),
            text: "halo".into(),
            op_id: None,
            media: vec![],
            speak: false,
            stream_part: false,
            quote_msg_id: "SID".into(),
            quote_text: "hi".into(),
        };
        let ctx = quote_context(&act).expect("quote");
        assert_eq!(ctx.stanza_id.as_deref(), Some("SID"));
        assert_eq!(ctx.participant.as_deref(), Some("123@s.whatsapp.net"));
        assert_eq!(ctx.quoted_message.unwrap().conversation.as_deref(), Some("hi"));
    }
}
