use std::sync::Arc;

use anyhow::{anyhow, Result};
use c35_ctx::AppState;
use c35_mod_log::{log_put, LogPut};
use reqwest::Client;
use tracing::info;

use crate::dedup::{channel_dedup_try_mark, channel_inbound_msg_put};
use crate::hub::channel_hub_init;
use crate::media::{channel_voice_placeholder, transcribe_voice_logged};
use crate::peer::{
    bot_peer_chat_resolve, chat_ai_reply_enabled, chat_msg_external_put, peer_iid_resolve,
};
use crate::store::{bot_channel_get, bot_owner_iid, ChannelDoc};
use crate::turn::ChannelTurnJob;
use crate::types::ChannelInboundMessage;

pub fn channel_runtime_init() {
    let _ = channel_hub_init();
}

pub async fn channel_inbound_handle(
    state: &AppState,
    bot_iid: i64,
    channel: &ChannelDoc,
    inbound: &ChannelInboundMessage,
) -> Result<(i64, i64)> {
    if let Some(msg_id) = inbound.external_msg_id.as_deref().filter(|s| !s.is_empty()) {
        if !channel_dedup_try_mark(&state.pool, bot_iid, &channel.id, msg_id).await {
            return Ok((0, 0));
        }
    }

    let owner_iid = bot_owner_iid(&state.pool, bot_iid)
        .await?
        .ok_or_else(|| anyhow!("bot owner not found"))?;
    let peer_iid = peer_iid_resolve(&state.pool, inbound).await?;
    let chat_id = bot_peer_chat_resolve(&state.pool, owner_iid, bot_iid, &channel.id, inbound).await?;

    let mut message = inbound.text.clone();
    if channel_voice_placeholder(&message) {
        message.clear();
    }
    if inbound.is_voice && !inbound.attachments.is_empty() {
        let client = http_client();
        let transcript = transcribe_voice_logged(
            &client,
            &state.pool,
            &state.cas_dir,
            &channel.bot_token,
            &inbound.attachments,
        )
        .await;
        if !transcript.trim().is_empty() {
            message = transcript;
        } else if message.trim().is_empty() {
            message = "[voice message - transcription failed]".into();
        }
    } else if inbound.is_voice && message.trim().is_empty() {
        message = "[voice note]".into();
    }
    if message.trim().is_empty() && inbound.attachments.is_empty() {
        return Err(anyhow!("empty channel message"));
    }

    let req_id = crate::outbound::channel_req_id(&inbound.platform);
    let log_preview = if message.trim().is_empty() {
        "[attachment]".to_string()
    } else {
        message.clone()
    };
    let log_text = format!("Inbound {}: {}", inbound.platform, log_preview);
    let _ = log_put(
        &state.pool,
        state.nats.as_ref(),
        LogPut {
            owner_iid,
            kind: "system",
            topic: "msg_received",
            dv: "c35-server",
            req_id: Some(&req_id),
            chat_id: Some(chat_id),
            task_id: None,
            device_iid: None,
            text: &truncate_log_text(&log_text),
            model: "",
            tokens_in: 0,
            tokens_out: 0,
            duration_ms: 0,
            cost_usd: 0.0,
            meta: serde_json::json!({
                "channel": {
                    "bot_iid": bot_iid,
                    "channel_id": channel.id,
                    "event": "msg_received",
                    "msg_id": inbound.external_msg_id,
                    "peer_id": inbound.external_user_id,
                }
            }),
        },
    )
    .await;
    let user_msg_id = chat_msg_external_put(
        &state.pool,
        chat_id,
        owner_iid,
        peer_iid,
        &req_id,
        &message,
    )
    .await?;
    if let Some(ext_id) = inbound.external_msg_id.as_deref().filter(|s| !s.is_empty()) {
        channel_inbound_msg_put(
            &state.pool,
            bot_iid,
            &channel.id,
            ext_id,
            chat_id,
            user_msg_id,
            &message,
        )
        .await;
    }

    info!(
        "[c35:channel] inbound platform={} bot_iid={} channel_id={} chat_id={} text_len={}",
        inbound.platform,
        bot_iid,
        channel.id,
        chat_id,
        message.len()
    );

    if !chat_ai_reply_enabled(&state.pool, chat_id).await {
        return Ok((chat_id, peer_iid));
    }

    let attachments_json = serde_json::to_string(&inbound.attachments).unwrap_or_else(|_| "[]".into());
    let hub = channel_hub_init();
    let job = ChannelTurnJob {
        bot_iid,
        chat_id,
        owner_iid,
        peer_iid,
        channel: channel.clone(),
        inbound: inbound.clone(),
        message,
        attachments_json,
        req_id,
    };
    hub.debouncer
        .lock()
        .await
        .schedule(Arc::new(state.clone()), job);

    Ok((chat_id, peer_iid))
}

fn truncate_log_text(s: &str) -> String {
    const MAX: usize = 120;
    if s.chars().count() <= MAX {
        return s.to_string();
    }
    format!("{}…", s.chars().take(MAX).collect::<String>())
}

fn http_client() -> Client {
    Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()
        .unwrap_or_else(|_| Client::new())
}

pub async fn channel_inbound_from_webhook(
    state: &AppState,
    bot_iid: i64,
    channel_id: &str,
    inbound: &ChannelInboundMessage,
) -> Result<(i64, i64)> {
    let channel = bot_channel_get(&state.pool, bot_iid, channel_id)
        .await?
        .ok_or_else(|| anyhow!("channel not found"))?;
    if channel.status != "connected" {
        return Err(anyhow!("channel not connected"));
    }
    channel_inbound_handle(state, bot_iid, &channel, inbound).await
}
