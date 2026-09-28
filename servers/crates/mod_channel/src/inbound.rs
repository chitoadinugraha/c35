use std::sync::Arc;

use anyhow::{anyhow, Result};
use c35_ctx::AppState;
use c35_mod_chat::{
    bot_active_load, bot_peer_msg_fanout, prompt_followup_active_req, prompt_followup_enabled, prompt_followup_put,
};
use c35_proto::PromptFollowupKind;
use c35_mod_log::{log_put, LogPut};
use reqwest::Client;
use tracing::info;

use crate::dedup::{channel_dedup_try_mark, channel_inbound_msg_put};
use crate::hub::channel_hub_init;
use crate::media::channel_voice_placeholder;
use crate::outbound::{channel_reply_nats, outbound_ctx_with_msg, ChannelCasCtx};
use crate::peer::{
    bot_peer_chat_resolve, chat_ai_reply_enabled, chat_msg_assistant_put, chat_msg_external_put, peer_iid_resolve,
};
use crate::welcome::channel_welcome_deliver;
use crate::policy::{
    inbound_attachments_filter, inbound_had_blocked_media, CHANNEL_UNSUPPORTED_REPLY,
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
    let (chat_id, chat_is_new) =
        bot_peer_chat_resolve(&state.pool, owner_iid, bot_iid, &channel.id, inbound).await?;
    if chat_is_new {
        if let Err(e) = channel_welcome_deliver(state, bot_iid, owner_iid, chat_id, channel, inbound).await {
            tracing::warn!("[c35:channel] welcome deliver failed chat_id={chat_id}: {e:#}");
        }
    }

    let blocked_media = inbound_had_blocked_media(inbound);
    let mut message = inbound.text.clone();
    if channel_voice_placeholder(&message) {
        message.clear();
    }

    let mut attachments = inbound.attachments.clone();
    inbound_attachments_filter(&mut attachments);

    if !attachments.is_empty() {
        let client = http_client();
        crate::media::resolve_inbound_attachments_cas(&client, state, channel, &mut attachments).await;
        attachments.retain(|a| !a.hash.is_empty());
    }

    let unsupported_only =
        blocked_media && message.trim().is_empty() && attachments.is_empty();

    if message.trim().is_empty() && attachments.is_empty() && !unsupported_only {
        return Err(anyhow!("empty channel message"));
    }

    if message.trim().is_empty() && unsupported_only {
        message = "[unsupported media]".into();
    }

    let atts_val = serde_json::Value::Array(
        attachments
            .iter()
            .map(|a| {
                serde_json::json!({
                    "hash": a.hash,
                    "name": if a.name.is_empty() { "photo.jpg".to_string() } else { a.name.clone() },
                    "mime": if a.mime.is_empty() { "image/jpeg".to_string() } else { a.mime.clone() },
                    "url": format!("/fs/{}", a.hash),
                })
            })
            .collect(),
    );
    let attachments_json = serde_json::to_string(&attachments).unwrap_or_else(|_| "[]".into());

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
            class: None,
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
        Some(&atts_val),
    )
    .await?;
    let should_reply = chat_ai_reply_enabled(&state.pool, chat_id).await
        && bot_active_load(&state.pool, bot_iid).await;

    if inbound.platform != "app" && should_reply && !unsupported_only {
        let nats = state.nats.clone();
        let owner = owner_iid;
        let cid = chat_id;
        tokio::spawn(async move {
            let _ = c35_mod_chat::bot_peer_typing_fanout(nats.as_ref(), owner, cid, "peer", true).await;
        });
    }
    let _ = bot_peer_msg_fanout(
        &state.pool,
        state.nats.as_ref(),
        owner_iid,
        chat_id,
        user_msg_id,
    )
    .await;
    if inbound.platform == "app" {
        let _ = sqlx::query(
            "UPDATE ai.chat SET ai_reply_enabled = TRUE, updated_ts = NOW() WHERE id = $1 AND kind = 'bot_peer' AND ai_reply_enabled = FALSE",
        )
        .bind(chat_id)
        .execute(&state.pool)
        .await;
    }
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

    if inbound.platform != "app" && !chat_ai_reply_enabled(&state.pool, chat_id).await {
        return Ok((chat_id, peer_iid));
    }

    if !bot_active_load(&state.pool, bot_iid).await {
        return Ok((chat_id, peer_iid));
    }

    if unsupported_only {
        channel_static_reply(state, bot_iid, channel, inbound, chat_id, owner_iid, &req_id, CHANNEL_UNSUPPORTED_REPLY)
            .await?;
        return Ok((chat_id, peer_iid));
    }

    if prompt_followup_enabled() && inbound.platform != "app" {
        if let Ok(Some(active_req)) = prompt_followup_active_req(&state.pool, chat_id).await {
            let dedup = inbound
                .external_msg_id
                .as_deref()
                .filter(|s| !s.is_empty())
                .map(|id| format!("{}:{}:{}:{}", inbound.platform, bot_iid, channel.id, id));
            let steer = prompt_followup_put(
                &state.pool,
                owner_iid,
                chat_id,
                &active_req,
                &message,
                "[]",
                PromptFollowupKind::Steer as i32,
                "channel",
                dedup.as_deref(),
            )
            .await;
            if steer.as_ref().map(|r| r.rejected).unwrap_or(true) {
                let _ = prompt_followup_put(
                    &state.pool,
                    owner_iid,
                    chat_id,
                    &active_req,
                    &message,
                    "[]",
                    PromptFollowupKind::Queue as i32,
                    "channel",
                    dedup.as_deref(),
                )
                .await;
            }
            return Ok((chat_id, peer_iid));
        }
    }

    let mut inbound_job = inbound.clone();
    inbound_job.is_voice = false;
    let hub = channel_hub_init();
    let job = ChannelTurnJob {
        bot_iid,
        chat_id,
        owner_iid,
        peer_iid,
        channel: channel.clone(),
        inbound: inbound_job,
        message,
        attachments_json,
        req_id,
    };
    let state_arc = Arc::new(state.clone());
    if inbound.platform == "app" {
        tokio::spawn(async move {
            if let Err(e) = super::turn::execute_channel_turn(state_arc, job).await {
                tracing::error!("[c35:channel] app turn failed chat_id={}: {e:#}", chat_id);
            }
        });
    } else {
        hub.debouncer
            .lock()
            .await
            .schedule(state_arc, job);
    }

    Ok((chat_id, peer_iid))
}

async fn channel_static_reply(
    state: &AppState,
    bot_iid: i64,
    channel: &ChannelDoc,
    inbound: &ChannelInboundMessage,
    chat_id: i64,
    owner_iid: i64,
    req_id: &str,
    text: &str,
) -> Result<()> {
    let client = http_client();
    let out_ctx = outbound_ctx_with_msg(
        &inbound.platform,
        &inbound.external_user_id,
        channel,
        owner_iid,
        bot_iid,
        inbound.external_msg_id.clone(),
    );
    let cas = ChannelCasCtx {
        pool: &state.pool,
        cas_dir: &state.cas_dir,
        cas_secret: &state.cas_secret,
    };
    channel_reply_nats(&client, state.nats.as_ref(), Some(&cas), &out_ctx, text, false).await?;
    chat_msg_assistant_put(&state.pool, chat_id, owner_iid, bot_iid, req_id, text).await?;
    Ok(())
}

pub fn channel_app_doc() -> ChannelDoc {
    ChannelDoc {
        id: "app".into(),
        platform: "app".into(),
        provider: String::new(),
        status: "connected".into(),
        webhook_secret: String::new(),
        verify_token: String::new(),
        bot_token: String::new(),
        bot_username: String::new(),
        phone_number_id: String::new(),
        access_token: String::new(),
        phone: String::new(),
        error_message: String::new(),
        session: Default::default(),
    }
}

pub async fn channel_app_peer_send(
    state: &AppState,
    bot_iid: i64,
    peer_key: &str,
    peer_name: &str,
    text: &str,
    attachments_json: &str,
) -> Result<(i64, i64)> {
    let attachments: Vec<crate::types::ChannelInboundAttachment> =
        serde_json::from_str(attachments_json).unwrap_or_default();
    let inbound = ChannelInboundMessage {
        platform: "app".into(),
        external_user_id: peer_key.to_string(),
        display_name: peer_name.to_string(),
        text: text.to_string(),
        external_msg_id: Some(format!("app-{}", c35_store::snowflake_id())),
        attachments,
        is_voice: false,
        quoted_msg_id: String::new(),
        quoted_text: String::new(),
        avatar_hash: String::new(),
        platform_user_id: String::new(),
    };
    channel_inbound_handle(state, bot_iid, &channel_app_doc(), &inbound).await
}

fn truncate_log_text(s: &str) -> String {
    const MAX: usize = 120;
    if s.chars().count() <= MAX {
        return s.to_string();
    }
    format!("{}...", s.chars().take(MAX).collect::<String>())
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
