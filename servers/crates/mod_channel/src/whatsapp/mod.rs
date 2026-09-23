mod connect;
mod pair;

pub use connect::channel_whatsapp_meta_connect;
pub use pair::{
    channel_whatsapp_pair_abort, channel_whatsapp_pair_start, channel_whatsapp_pair_watch,
    pair_res_from_channel, pair_res_from_error, worker_post, ActChannelWhatsappPair, SUBJ_PAIR,
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
    } else if let Some(doc) = msg.get("document") {
        let name = doc.get("filename").and_then(|c| c.as_str()).unwrap_or("document");
        text = doc.get("caption").and_then(|c| c.as_str()).unwrap_or("[document]").to_string();
        attachments.push(meta_media_attachment(doc, name, doc.get("mime_type").and_then(|c| c.as_str()).unwrap_or("application/octet-stream")));
    } else if let Some(audio) = msg.get("audio") {
        text = "[audio]".to_string();
        attachments.push(meta_media_attachment(audio, "audio.ogg", audio.get("mime_type").and_then(|c| c.as_str()).unwrap_or("audio/ogg")));
    } else if let Some(video) = msg.get("video") {
        text = video.get("caption").and_then(|c| c.as_str()).unwrap_or("[video]").to_string();
        attachments.push(meta_media_attachment(video, "video.mp4", video.get("mime_type").and_then(|c| c.as_str()).unwrap_or("video/mp4")));
    } else if let Some(sticker) = msg.get("sticker") {
        text = "[sticker]".to_string();
        attachments.push(meta_media_attachment(sticker, "sticker.webp", sticker.get("mime_type").and_then(|c| c.as_str()).unwrap_or("image/webp")));
    } else if let Some(location) = msg.get("location") {
        let lat = location.get("latitude").and_then(|v| v.as_f64()).unwrap_or_default();
        let long = location.get("longitude").and_then(|v| v.as_f64()).unwrap_or_default();
        let name = location.get("name").and_then(|v| v.as_str()).unwrap_or("");
        text = format!("[location: {lat}, {long} {name}]").trim().to_string();
    } else if let Some(reaction) = msg.get("reaction") {
        let emoji = reaction.get("emoji").and_then(|v| v.as_str()).unwrap_or("");
        text = format!("[reaction: {emoji}]");
    } else {
        text = "[unsupported message]".to_string();
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

pub fn meta_graph_base() -> String {
    std::env::var("META_GRAPH_API_BASE")
        .ok()
        .filter(|s| !s.trim().is_empty())
        .unwrap_or_else(|| "https://graph.facebook.com/v21.0".to_string())
        .trim_end_matches('/')
        .to_string()
}

pub async fn fetch_meta_cloud_media(
    client: &reqwest::Client,
    access_token: &str,
    media_id: &str,
) -> Result<(Vec<u8>, String), String> {
    let graph = meta_graph_base();
    let meta_url = format!("{graph}/{media_id}");
    let meta_res = client
        .get(&meta_url)
        .header("Authorization", format!("Bearer {access_token}"))
        .send()
        .await
        .map_err(|e| format!("meta media metadata request failed: {e}"))?;
    if !meta_res.status().is_success() {
        return Err(format!("meta media metadata status {}", meta_res.status()));
    }
    let json: serde_json::Value = meta_res
        .json()
        .await
        .map_err(|e| format!("meta media json parse failed: {e}"))?;
    let media_url = json
        .get("url")
        .and_then(|u| u.as_str())
        .ok_or_else(|| "missing url in meta media metadata".to_string())?;
    let dl_mime = json
        .get("mime_type")
        .and_then(|m| m.as_str())
        .unwrap_or("application/octet-stream")
        .to_string();
    let dl_res = client
        .get(media_url)
        .header("Authorization", format!("Bearer {access_token}"))
        .send()
        .await
        .map_err(|e| format!("meta media download request failed: {e}"))?;
    if !dl_res.status().is_success() {
        return Err(format!("meta media download status {}", dl_res.status()));
    }
    let bytes = dl_res
        .bytes()
        .await
        .map_err(|e| format!("meta media download body failed: {e}"))?
        .to_vec();
    Ok((bytes, dl_mime))
}

pub async fn wa_cloud_upload_media(
    client: &reqwest::Client,
    phone_number_id: &str,
    access_token: &str,
    bytes: &[u8],
    mime: &str,
    name: &str,
) -> Result<String, String> {
    let graph = meta_graph_base();
    let url = format!("{graph}/{phone_number_id}/media");
    let part = reqwest::multipart::Part::bytes(bytes.to_vec())
        .file_name(name.to_string())
        .mime_str(mime)
        .map_err(|e| e.to_string())?;
    let form = reqwest::multipart::Form::new()
        .text("messaging_product", "whatsapp")
        .text("type", mime.to_string())
        .part("file", part);
    let res = client
        .post(&url)
        .header("Authorization", format!("Bearer {access_token}"))
        .multipart(form)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    let body: serde_json::Value = res.json().await.map_err(|e| e.to_string())?;
    body.get("id")
        .and_then(|v| v.as_str())
        .map(str::to_string)
        .ok_or_else(|| format!("Meta upload missing id: {body}"))
}

pub async fn wa_cloud_send_audio(
    client: &reqwest::Client,
    phone_number_id: &str,
    access_token: &str,
    to: &str,
    audio: &[u8],
    mime: &str,
    is_voice: bool,
) -> Result<(), String> {
    let media_id = wa_cloud_upload_media(client, phone_number_id, access_token, audio, mime, "reply.mp3").await?;
    let graph = meta_graph_base();
    let url = format!("{graph}/{phone_number_id}/messages");
    let res = client
        .post(&url)
        .header("Authorization", format!("Bearer {access_token}"))
        .json(&serde_json::json!({
            "messaging_product": "whatsapp",
            "to": to,
            "type": "audio",
            "audio": { "id": media_id, "voice": is_voice }
        }))
        .send()
        .await
        .map_err(|e| e.to_string())?;
    if !res.status().is_success() {
        return Err(format!("Meta Cloud audio failed: {}", res.text().await.unwrap_or_default()));
    }
    Ok(())
}

pub async fn wa_cloud_send_media(
    client: &reqwest::Client,
    phone_number_id: &str,
    access_token: &str,
    to: &str,
    bytes: &[u8],
    mime: &str,
    name: &str,
    caption: &str,
    is_image: bool,
) -> Result<(), String> {
    let media_id = wa_cloud_upload_media(client, phone_number_id, access_token, bytes, mime, name).await?;
    let graph = meta_graph_base();
    let url = format!("{graph}/{phone_number_id}/messages");
    let body = if is_image {
        serde_json::json!({
            "messaging_product": "whatsapp",
            "to": to,
            "type": "image",
            "image": { "id": media_id, "caption": caption }
        })
    } else {
        serde_json::json!({
            "messaging_product": "whatsapp",
            "to": to,
            "type": "document",
            "document": { "id": media_id, "caption": caption, "filename": name }
        })
    };
    let res = client
        .post(&url)
        .header("Authorization", format!("Bearer {access_token}"))
        .json(&body)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    if !res.status().is_success() {
        return Err(format!("Meta Cloud media failed: {}", res.text().await.unwrap_or_default()));
    }
    Ok(())
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
    fn parse_meta_document_message() {
        let bytes = serde_json::json!({
            "object": "whatsapp_business_account",
            "entry": [{
                "changes": [{
                    "value": {
                        "contacts": [{ "profile": { "name": "Budi" } }],
                        "messages": [{
                            "from": "628123456789",
                            "id": "wamid.doc",
                            "document": {
                                "id": "doc456",
                                "filename": "report.pdf",
                                "caption": "monthly report",
                                "mime_type": "application/pdf"
                            }
                        }]
                    }
                }]
            }]
        })
        .to_string()
        .into_bytes();
        let inbound = parse_whatsapp_payload(&bytes).unwrap();
        assert_eq!(inbound.text, "monthly report");
        assert_eq!(inbound.attachments.len(), 1);
        assert_eq!(inbound.attachments[0].media_id, "doc456");
        assert_eq!(inbound.attachments[0].name, "report.pdf");
        assert_eq!(inbound.attachments[0].mime, "application/pdf");
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
