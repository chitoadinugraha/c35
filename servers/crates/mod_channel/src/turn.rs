use std::sync::Arc;

use anyhow::Result;
use c35_ctx::AppState;
use c35_mod_chat::{channel_prompt_turn, gemini_api_key};
use reqwest::Client;

use crate::debounce::{debouncer_turn_finished, debouncer_turn_started};
use crate::hub::channel_hub;
use crate::limit::BOT_BUSY_REPLY;
use crate::outbound::{channel_reply_nats, channel_stub_reply, outbound_ctx_with_msg, ChannelCasCtx};
use crate::peer::chat_msg_assistant_put;
use crate::store::ChannelDoc;
use crate::typing::channel_typing_start;
use crate::types::ChannelInboundMessage;

pub struct ChannelTurnJob {
    pub bot_iid: i64,
    pub chat_id: i64,
    pub owner_iid: i64,
    pub peer_iid: i64,
    pub channel: ChannelDoc,
    pub inbound: ChannelInboundMessage,
    pub message: String,
    pub attachments_json: String,
    pub req_id: String,
}

pub async fn execute_channel_turn(state: Arc<AppState>, job: ChannelTurnJob) -> Result<()> {
    debouncer_turn_started(job.chat_id).await;
    let limiter = channel_hub().bot_limiter(job.bot_iid);
    let _guard = match limiter.acquire_turn(&state.pool).await {
        Ok(g) => g,
        Err(()) => {
            let client = http_client();
            let out_ctx = outbound_ctx_with_msg(
                &job.inbound.platform,
                &job.inbound.external_user_id,
                &job.channel,
                job.owner_iid,
                job.bot_iid,
                job.inbound.external_msg_id.clone(),
            );
            limiter.outbound_pace().await;
            let cas = ChannelCasCtx {
                pool: &state.pool,
                cas_dir: &state.cas_dir,
                cas_secret: &state.cas_secret,
            };
            channel_reply_nats(&client, state.nats.as_ref(), Some(&cas), &out_ctx, BOT_BUSY_REPLY, job.inbound.is_voice).await?;
            chat_msg_assistant_put(&state.pool, job.chat_id, job.owner_iid, job.bot_iid, &job.req_id, BOT_BUSY_REPLY).await?;
            debouncer_turn_finished(state, job.chat_id).await;
            return Ok(());
        }
    };

    let client = http_client();
    let out_ctx = outbound_ctx_with_msg(
        &job.inbound.platform,
        &job.inbound.external_user_id,
        &job.channel,
        job.owner_iid,
        job.bot_iid,
        job.inbound.external_msg_id.clone(),
    );

    let _typing_guard = channel_typing_start(
        client.clone(),
        state.nats.clone(),
        job.owner_iid,
        job.bot_iid,
        out_ctx.clone(),
        job.inbound.is_voice,
    );

    let reply = if gemini_api_key().is_empty() {
        channel_stub_reply(&job.message, job.inbound.is_voice)
    } else {
        match channel_prompt_turn(
            &state.pool,
            state.nats.as_ref(),
            job.bot_iid,
            job.chat_id,
            job.owner_iid,
            &job.message,
            &job.attachments_json,
            job.inbound.is_voice,
            &job.req_id,
        )
        .await
        {
            Ok((text, _, _, _, _)) => text,
            Err(e) => {
                tracing::warn!("[c35:channel] prompt_turn failed: {}", e);
                channel_stub_reply(&job.message, job.inbound.is_voice)
            }
        }
    };

    limiter.outbound_pace().await;
    let cas = ChannelCasCtx {
        pool: &state.pool,
        cas_dir: &state.cas_dir,
        cas_secret: &state.cas_secret,
    };
    channel_reply_nats(&client, state.nats.as_ref(), Some(&cas), &out_ctx, &reply, job.inbound.is_voice).await?;
    chat_msg_assistant_put(&state.pool, job.chat_id, job.owner_iid, job.bot_iid, &job.req_id, &reply).await?;
    debouncer_turn_finished(state, job.chat_id).await;
    Ok(())
}

fn http_client() -> Client {
    Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()
        .unwrap_or_else(|_| Client::new())
}
