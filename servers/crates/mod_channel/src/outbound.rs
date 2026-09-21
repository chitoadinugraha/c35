use anyhow::Result;
use c35_store::snowflake_id;
use reqwest::Client;

use crate::format::channel_text_format;
use crate::store::ChannelDoc;
use crate::telegram::{tg_api_base, tg_send_message};
use crate::thought::thought_strip;

pub struct OutboundCtx {
    pub platform: String,
    pub peer_id: String,
    pub channel: ChannelDoc,
}

pub fn outbound_ctx_from_channel(platform: &str, peer_id: &str, channel: &ChannelDoc) -> OutboundCtx {
    OutboundCtx {
        platform: platform.to_string(),
        peer_id: peer_id.to_string(),
        channel: channel.clone(),
    }
}

pub async fn channel_reply(client: &Client, ctx: &OutboundCtx, reply_text: &str, speak: bool) -> Result<()> {
    let visible = thought_strip(reply_text);
    if visible.trim().is_empty() {
        return Ok(());
    }
    let formatted = channel_text_format(&ctx.platform, &visible);
    if ctx.platform == "telegram" {
        return deliver_telegram(client, ctx, &formatted, &visible).await;
    }
    if ctx.platform == "whatsapp" {
        return deliver_whatsapp_meta(client, ctx, &formatted, speak).await;
    }
    Ok(())
}

async fn deliver_telegram(client: &Client, ctx: &OutboundCtx, html: &str, plain: &str) -> Result<()> {
    if ctx.peer_id.is_empty() || ctx.channel.bot_token.is_empty() {
        anyhow::bail!("telegram channel missing peer or token");
    }
    let api = tg_api_base();
    if tg_send_message(client, &api, &ctx.channel.bot_token, &ctx.peer_id, html, Some("HTML"))
        .await
        .is_ok()
    {
        return Ok(());
    }
    tg_send_message(client, &api, &ctx.channel.bot_token, &ctx.peer_id, plain, None)
        .await
        .map_err(|e| anyhow::anyhow!(e))
}

async fn deliver_whatsapp_meta(client: &Client, ctx: &OutboundCtx, text: &str, _speak: bool) -> Result<()> {
    if ctx.channel.phone_number_id.is_empty() || ctx.channel.access_token.is_empty() {
        anyhow::bail!("whatsapp meta channel missing credentials");
    }
    let to = ctx.peer_id.split('@').next().unwrap_or(&ctx.peer_id);
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
    Ok(())
}

const WA_CLOUD_TEXT_MAX: usize = 4096;

fn wa_text_chunks(text: &str) -> Vec<&str> {
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
    fn thought_stripped_in_reply_path() {
        let raw = "<thought>plan</thought>\nHello **there**";
        assert_eq!(thought_strip(raw), "Hello **there**");
    }
}
