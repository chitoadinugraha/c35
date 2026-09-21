use reqwest::Client;

use crate::outbound::OutboundCtx;
use crate::telegram::{tg_api_base, tg_send_chat_action};

pub async fn channel_typing_pulse(client: &Client, ctx: &OutboundCtx, speak: bool, active: bool) {
    if !active {
        return;
    }
    if ctx.platform == "telegram" {
        if ctx.channel.bot_token.is_empty() {
            return;
        }
        let action = if speak { "record_voice" } else { "typing" };
        let _ = tg_send_chat_action(
            client,
            &tg_api_base(),
            &ctx.channel.bot_token,
            &ctx.peer_id,
            action,
        )
        .await;
        return;
    }
    if ctx.platform == "whatsapp" && ctx.channel.provider == "meta_api" {
        if ctx.channel.phone_number_id.is_empty() || ctx.channel.access_token.is_empty() {
            return;
        }
        let to = ctx.peer_id.split('@').next().unwrap_or(&ctx.peer_id);
        let _ = wa_cloud_send_typing(client, &ctx.channel.phone_number_id, &ctx.channel.access_token, to).await;
    }
}

async fn wa_cloud_send_typing(
    client: &Client,
    phone_number_id: &str,
    access_token: &str,
    to: &str,
) -> Result<(), String> {
    let graph = std::env::var("META_GRAPH_API_BASE")
        .ok()
        .filter(|s| !s.trim().is_empty())
        .unwrap_or_else(|| "https://graph.facebook.com/v21.0".to_string())
        .trim_end_matches('/')
        .to_string();
    let url = format!("{graph}/{phone_number_id}/messages");
    let res = client
        .post(&url)
        .header("Authorization", format!("Bearer {access_token}"))
        .json(&serde_json::json!({
            "messaging_product": "whatsapp",
            "to": to,
            "typing_indicator": { "type": "text" }
        }))
        .send()
        .await
        .map_err(|e| e.to_string())?;
    if !res.status().is_success() {
        let body = res.text().await.unwrap_or_default();
        return Err(format!("Meta Cloud typing failed: {body}"));
    }
    Ok(())
}
