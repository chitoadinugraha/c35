mod connect;

pub use connect::channel_telegram_connect;
pub use connect::{
    tg_api_base, tg_send_chat_action, tg_send_document_bytes, tg_send_message, tg_send_photo_url,
    tg_send_voice_reply,
};

use crate::types::ChannelInboundAttachment;
use anyhow::Result;

pub fn parse_telegram_payload(bytes: &[u8]) -> Result<crate::types::ChannelInboundMessage> {
    let v: serde_json::Value = serde_json::from_slice(bytes)?;
    let msg = v
        .get("message")
        .or_else(|| v.get("edited_message"))
        .or_else(|| v.get("channel_post"))
        .ok_or_else(|| anyhow::anyhow!("No message object in Telegram update"))?;

    let text = msg
        .get("text")
        .or_else(|| msg.get("caption"))
        .and_then(|t| t.as_str())
        .unwrap_or_default();

    let from = msg.get("from").ok_or_else(|| anyhow::anyhow!("No from object in Telegram message"))?;
    let tg_id = from
        .get("id")
        .and_then(|i| i.as_i64())
        .ok_or_else(|| anyhow::anyhow!("No user ID in Telegram message from"))?;
    let peer_id = msg
        .get("chat")
        .and_then(|c| c.get("id"))
        .and_then(|i| i.as_i64())
        .unwrap_or(tg_id);

    let first_name = from.get("first_name").and_then(|f| f.as_str()).unwrap_or("Telegram User");
    let last_name = from.get("last_name").and_then(|l| l.as_str()).unwrap_or("");
    let display_name = if last_name.is_empty() {
        first_name.to_string()
    } else {
        format!("{} {}", first_name, last_name)
    };

    let msg_id = msg.get("message_id").map(|m| m.to_string());
    let mut attachments = Vec::new();
    let mut is_voice = false;
    if let Some(voice) = msg.get("voice") {
        is_voice = true;
        if let Some(file_id) = voice.get("file_id").and_then(|f| f.as_str()) {
            attachments.push(telegram_audio_attachment(
                file_id,
                voice.get("mime_type").and_then(|m| m.as_str()),
                "voice.ogg",
            ));
        }
    } else if let Some(audio) = msg.get("audio") {
        is_voice = true;
        if let Some(file_id) = audio.get("file_id").and_then(|f| f.as_str()) {
            attachments.push(telegram_audio_attachment(
                file_id,
                audio.get("mime_type").and_then(|m| m.as_str()),
                audio
                    .get("file_name")
                    .and_then(|n| n.as_str())
                    .unwrap_or("audio.m4a"),
            ));
        }
    } else if let Some(photos) = msg.get("photo").and_then(|p| p.as_array()) {
        if let Some(largest) = photos.last() {
            if let Some(file_id) = largest.get("file_id").and_then(|f| f.as_str()) {
                attachments.push(ChannelInboundAttachment {
                    hash: String::new(),
                    name: "photo.jpg".into(),
                    mime: "image/jpeg".into(),
                    media_id: file_id.to_string(),
                    url: String::new(),
                });
            }
        }
    } else if let Some(doc) = msg.get("document") {
        if let Some(file_id) = doc.get("file_id").and_then(|f| f.as_str()) {
            let name = doc.get("file_name").and_then(|n| n.as_str()).unwrap_or("document");
            let mime = doc.get("mime_type").and_then(|m| m.as_str()).unwrap_or("application/octet-stream");
            attachments.push(ChannelInboundAttachment {
                hash: String::new(),
                name: name.to_string(),
                mime: mime.to_string(),
                media_id: file_id.to_string(),
                url: String::new(),
            });
        }
    } else if let Some(vid) = msg.get("video") {
        if let Some(file_id) = vid.get("file_id").and_then(|f| f.as_str()) {
            let name = vid.get("file_name").and_then(|n| n.as_str()).unwrap_or("video.mp4");
            let mime = vid.get("mime_type").and_then(|m| m.as_str()).unwrap_or("video/mp4");
            attachments.push(ChannelInboundAttachment {
                hash: String::new(),
                name: name.to_string(),
                mime: mime.to_string(),
                media_id: file_id.to_string(),
                url: String::new(),
            });
        }
    } else if let Some(vnote) = msg.get("video_note") {
        if let Some(file_id) = vnote.get("file_id").and_then(|f| f.as_str()) {
            attachments.push(ChannelInboundAttachment {
                hash: String::new(),
                name: "video_note.mp4".into(),
                mime: "video/mp4".into(),
                media_id: file_id.to_string(),
                url: String::new(),
            });
        }
    } else if let Some(anim) = msg.get("animation") {
        if let Some(file_id) = anim.get("file_id").and_then(|f| f.as_str()) {
            let name = anim.get("file_name").and_then(|n| n.as_str()).unwrap_or("animation.mp4");
            let mime = anim.get("mime_type").and_then(|m| m.as_str()).unwrap_or("video/mp4");
            attachments.push(ChannelInboundAttachment {
                hash: String::new(),
                name: name.to_string(),
                mime: mime.to_string(),
                media_id: file_id.to_string(),
                url: String::new(),
            });
        }
    } else if let Some(sticker) = msg.get("sticker") {
        if let Some(file_id) = sticker.get("file_id").and_then(|f| f.as_str()) {
            attachments.push(ChannelInboundAttachment {
                hash: String::new(),
                name: "sticker.webp".into(),
                mime: "image/webp".into(),
                media_id: file_id.to_string(),
                url: String::new(),
            });
        }
    }

    Ok(crate::types::ChannelInboundMessage {
        platform: "telegram".to_string(),
        external_user_id: peer_id.to_string(),
        display_name,
        text: text.to_string(),
        external_msg_id: msg_id,
        attachments,
        is_voice,
        quoted_msg_id: String::new(),
        quoted_text: String::new(),
        avatar_hash: String::new(),
        platform_user_id: tg_id.to_string(),
    })
}

fn telegram_audio_attachment(file_id: &str, mime: Option<&str>, name: &str) -> ChannelInboundAttachment {
    ChannelInboundAttachment {
        hash: String::new(),
        name: name.into(),
        mime: mime.unwrap_or("audio/ogg").to_string(),
        media_id: file_id.to_string(),
        url: String::new(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn update(chat_id: i64, from_id: i64, text: &str) -> Vec<u8> {
        serde_json::json!({
            "update_id": 1,
            "message": {
                "message_id": 9,
                "from": { "id": from_id, "first_name": "Ada", "last_name": "Lovelace" },
                "chat": { "id": chat_id, "type": "private" },
                "text": text
            }
        })
        .to_string()
        .into_bytes()
    }

    #[test]
    fn parse_uses_chat_id_for_outbound_peer() {
        let inbound = parse_telegram_payload(&update(881234567, 1001, "hi")).unwrap();
        assert_eq!(inbound.external_user_id, "881234567");
        assert_eq!(inbound.display_name, "Ada Lovelace");
        assert_eq!(inbound.text, "hi");
        assert_eq!(inbound.external_msg_id.as_deref(), Some("9"));
    }

    #[test]
    fn parse_voice_note_sets_is_voice_and_file_id() {
        let bytes = serde_json::json!({
            "update_id": 2,
            "message": {
                "message_id": 10,
                "from": { "id": 1001, "first_name": "Ada" },
                "chat": { "id": 881234567, "type": "private" },
                "voice": { "file_id": "AwADBAADbXXXXXXXXXXX2EE", "mime_type": "audio/ogg", "duration": 3 },
                "caption": "optional caption"
            }
        })
        .to_string()
        .into_bytes();
        let inbound = parse_telegram_payload(&bytes).unwrap();
        assert!(inbound.is_voice);
        assert_eq!(inbound.text, "optional caption");
        assert_eq!(inbound.attachments.len(), 1);
        assert_eq!(inbound.attachments[0].media_id, "AwADBAADbXXXXXXXXXXX2EE");
    }
}
