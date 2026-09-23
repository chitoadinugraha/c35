use reqwest::Client;
use serde::Serialize;
use tokio::sync::watch;

use crate::outbound::OutboundCtx;
use crate::store::is_linked_provider;
use crate::telegram::{tg_api_base, tg_send_chat_action};

#[derive(Clone, Debug, Serialize)]
pub struct ActChannelMsgTyping {
    pub bot_iid: i64,
    pub channel_id: String,
    pub recipient_id: String,
    pub active: bool,
    pub speak: bool,
}

pub struct ChannelTypingGuard {
    stop: watch::Sender<bool>,
    task: tokio::task::JoinHandle<()>,
}

impl Drop for ChannelTypingGuard {
    fn drop(&mut self) {
        let _ = self.stop.send(true);
        self.task.abort();
    }
}

pub fn channel_typing_start(
    client: Client,
    nats: Option<async_nats::Client>,
    owner_iid: i64,
    bot_iid: i64,
    ctx: OutboundCtx,
    speak: bool,
) -> ChannelTypingGuard {
    let (stop_tx, mut stop_rx) = watch::channel(false);
    let ctx_clone = ctx.clone();
    let nats_clone = nats.clone();
    let client_clone = client.clone();
    let task = tokio::spawn(async move {
        let mut tick = tokio::time::interval(std::time::Duration::from_secs(4));
        tick.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Skip);
        channel_typing_pulse(&client_clone, nats_clone.as_ref(), owner_iid, bot_iid, &ctx_clone, speak, true).await;
        loop {
            tokio::select! {
                _ = tick.tick() => {
                    if *stop_rx.borrow() {
                        break;
                    }
                    channel_typing_pulse(&client_clone, nats_clone.as_ref(), owner_iid, bot_iid, &ctx_clone, speak, true).await;
                }
                changed = stop_rx.changed() => {
                    if changed.is_ok() && *stop_rx.borrow() {
                        break;
                    }
                }
            }
        }
        if ctx_clone.platform == "whatsapp" && is_linked_provider(&ctx_clone.channel.provider) {
            channel_typing_pulse(&client_clone, nats_clone.as_ref(), owner_iid, bot_iid, &ctx_clone, speak, false).await;
        }
    });
    ChannelTypingGuard { stop: stop_tx, task }
}

pub async fn channel_typing_pulse(
    client: &Client,
    nats: Option<&async_nats::Client>,
    owner_iid: i64,
    bot_iid: i64,
    ctx: &OutboundCtx,
    speak: bool,
    active: bool,
) {
    if ctx.platform == "telegram" {
        if ctx.channel.bot_token.is_empty() || !active {
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
    if ctx.platform == "whatsapp" {
        if ctx.channel.provider == "meta_api" {
            if !active || ctx.channel.phone_number_id.is_empty() || ctx.channel.access_token.is_empty() {
                return;
            }
            let _ = wa_cloud_send_typing(
                client,
                &ctx.channel.phone_number_id,
                &ctx.channel.access_token,
                ctx.msg_id.as_deref(),
            )
            .await;
            return;
        }
        if is_linked_provider(&ctx.channel.provider) {
            if let Some(nats_client) = nats {
                let act = ActChannelMsgTyping {
                    bot_iid,
                    channel_id: ctx.channel.id.clone(),
                    recipient_id: ctx.peer_id.clone(),
                    active,
                    speak,
                };
                let subject = format!("c35.act.channel.{owner_iid}.{bot_iid}.{}.msg.typing", ctx.channel.id);
                if let Ok(payload) = serde_json::to_vec(&act) {
                    let _ = nats_client.publish(subject, payload.into()).await;
                }
            }
        }
    }
}

pub async fn wa_cloud_send_typing(
    client: &Client,
    phone_number_id: &str,
    access_token: &str,
    msg_id: Option<&str>,
) -> Result<(), String> {
    let Some(id) = msg_id.filter(|s| !s.trim().is_empty()) else {
        return Ok(());
    };
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
            "status": "read",
            "message_id": id,
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
