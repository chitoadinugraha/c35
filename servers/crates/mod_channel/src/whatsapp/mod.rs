mod connect;
mod pair;

pub use connect::channel_whatsapp_meta_connect;
pub use pair::{
    channel_whatsapp_pair_abort, channel_whatsapp_pair_start, channel_whatsapp_pair_watch,
    pair_res_from_channel, pair_res_from_error, ActChannelWhatsappPair, SUBJ_PAIR,
};

use crate::types::ChannelInboundAttachment;
use anyhow::{Context, Result};

pub fn parse_whatsapp_payload(bytes: &[u8]) -> Result<crate::types::ChannelInboundMessage> {
    let v: serde_json::Value = serde_json::from_slice(bytes)?;
    if v.get("object").and_then(|o| o.as_str()) == Some("whatsapp_business_account") {
        return parse_meta_cloud_payload(&v);
    }
    anyhow::bail!("Unrecognized WhatsApp payload structure")
}

pub fn parse_meta_cloud_payload(v: &serde_json::Value) -> Result<crate::types::ChannelInboundMessage> {
    let entry = v
        .get("entry")
        .and_then(|e| e.as_array())
        .and_then(|a| a.first())
        .context("meta cloud missing entry")?;
    let change = entry
        .get("changes")
        .and_then(|c| c.as_array())
        .and_then(|a| a.first())
        .context("meta cloud missing changes")?;
    let value = change.get("value").context("meta cloud missing value")?;
    let msg = value
        .get("messages")
        .and_then(|m| m.as_array())
        .and_then(|a| a.first())
        .context("meta cloud missing messages")?;
    let from = msg.get("from").and_then(|f| f.as_str()).context("meta cloud missing from")?;
    let msg_id = msg.get("id").and_then(|f| f.as_str()).unwrap_or_default();
    let profile_name = value
        .get("contacts")
        .and_then(|c| c.as_array())
        .and_then(|a| a.first())
        .and_then(|c| c.get("profile"))
        .and_then(|p| p.get("name"))
        .and_then(|n| n.as_str())
        .unwrap_or("WhatsApp User");
    let text;
    let mut attachments = Vec::new();
    if let Some(body) = msg.get("text").and_then(|t| t.get("body")).and_then(|b| b.as_str()) {
        text = body.to_string();
    } else if let Some(img) = msg.get("image") {
        text = img.get("caption").and_then(|c| c.as_str()).unwrap_or("[image]").to_string();
        attachments.push(meta_media_attachment(img, "image.jpg", "image/jpeg"));
    } else if let Some(audio) = msg.get("audio") {
        text = "[audio]".to_string();
        attachments.push(meta_media_attachment(audio, "audio.ogg", audio.get("mime_type").and_then(|c| c.as_str()).unwrap_or("audio/ogg")));
    } else {
        anyhow::bail!("meta cloud unsupported message type");
    }
    let quoted_msg_id = msg
        .get("context")
        .and_then(|c| c.get("id"))
        .and_then(|v| v.as_str())
        .unwrap_or_default()
        .to_string();
    Ok(crate::types::ChannelInboundMessage {
        platform: "whatsapp".to_string(),
        external_user_id: format!("{from}@s.whatsapp.net"),
        display_name: profile_name.to_string(),
        text,
        external_msg_id: Some(msg_id.to_string()),
        attachments,
        is_voice: msg.get("audio").and_then(|a| a.get("voice")).and_then(|v| v.as_bool()).unwrap_or(false),
        quoted_msg_id,
        quoted_text: String::new(),
        avatar_hash: String::new(),
        platform_user_id: String::new(),
    })
}

fn meta_media_attachment(part: &serde_json::Value, name: &str, mime: &str) -> ChannelInboundAttachment {
    ChannelInboundAttachment {
        hash: String::new(),
        name: name.to_string(),
        mime: mime.to_string(),
        media_id: part.get("id").and_then(|c| c.as_str()).unwrap_or_default().to_string(),
        url: String::new(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_meta_text_message() {
        let bytes = serde_json::json!({
            "object": "whatsapp_business_account",
            "entry": [{
                "changes": [{
                    "value": {
                        "contacts": [{ "profile": { "name": "Budi" } }],
                        "messages": [{
                            "from": "628123456789",
                            "id": "wamid.abc",
                            "text": { "body": "halo" }
                        }]
                    }
                }]
            }]
        })
        .to_string()
        .into_bytes();
        let inbound = parse_whatsapp_payload(&bytes).unwrap();
        assert_eq!(inbound.display_name, "Budi");
        assert_eq!(inbound.text, "halo");
        assert_eq!(inbound.external_user_id, "628123456789@s.whatsapp.net");
        assert_eq!(inbound.external_msg_id.as_deref(), Some("wamid.abc"));
    }

    #[test]
    fn parse_meta_voice_message() {
        let bytes = serde_json::json!({
            "object": "whatsapp_business_account",
            "entry": [{
                "changes": [{
                    "value": {
                        "contacts": [{ "profile": { "name": "Budi" } }],
                        "messages": [{
                            "from": "628123456789",
                            "id": "wamid.voice",
                            "audio": { "id": "media123", "voice": true, "mime_type": "audio/ogg" }
                        }]
                    }
                }]
            }]
        })
        .to_string()
        .into_bytes();
        let inbound = parse_whatsapp_payload(&bytes).unwrap();
        assert!(inbound.is_voice);
        assert_eq!(inbound.attachments.len(), 1);
        assert_eq!(inbound.attachments[0].media_id, "media123");
    }
}
