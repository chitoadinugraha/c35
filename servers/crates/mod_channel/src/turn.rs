use std::sync::Arc;

use anyhow::Result;
use c35_ctx::AppState;
use c35_mod_chat::{
    bot_auto_block_enabled, bot_peer_msg_fanout, bot_turn_meta_load, channel_prompt_turn, gemini_api_key,
    prompt_followup_mark_queue_delivered, prompt_followup_next_queued, prompt_run_finish,
    prompt_run_insert, prompt_run_row_channel,
};
use reqwest::Client;

use crate::debounce::{debouncer_turn_finished, debouncer_turn_started};
use crate::hub::channel_hub;
use crate::limit::BOT_BUSY_REPLY;
use crate::outbound::{channel_reply_nats, channel_stub_reply, outbound_ctx_with_msg, ChannelCasCtx};
use crate::peer::{
    chat_msg_assistant_put, chat_msg_assistant_put_usage, chat_msg_usage_sync_from_log, chat_strict_oos_apply,
};
use crate::policy::reply_oos_strip;
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
    if job.inbound.platform != "app" {
        let _ = c35_mod_chat::bot_peer_typing_fanout(
            state.nats.as_ref(),
            job.owner_iid,
            job.chat_id,
            "peer",
            false,
        )
        .await;
    }
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
            channel_reply_nats(&client, state.nats.as_ref(), Some(&cas), &out_ctx, BOT_BUSY_REPLY, false).await?;
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

    let channel_row = prompt_run_row_channel(&job.req_id, job.owner_iid, job.chat_id, &job.message, "");
    if let Err(e) = prompt_run_insert(&state.pool, &channel_row).await {
        tracing::warn!("[c35:channel] prompt_run insert failed: {e:#}");
    }

    let _ = c35_mod_chat::bot_peer_typing_fanout(state.nats.as_ref(), job.owner_iid, job.chat_id, "peer", false).await;
    let _typing_guard = channel_typing_start(
        client.clone(),
        state.nats.clone(),
        job.owner_iid,
        job.bot_iid,
        job.chat_id,
        out_ctx.clone(),
        false,
    );

    let mut turn_usage: Option<(i32, i32, f64, String, i32)> = None;

    let mut reply = if gemini_api_key().is_empty() {
        channel_stub_reply(&job.message, false)
    } else {
        match channel_prompt_turn(
            &state.pool,
            state.nats.as_ref(),
            job.bot_iid,
            job.chat_id,
            job.owner_iid,
            &job.message,
            &job.attachments_json,
            false,
            &job.req_id,
        )
        .await
        {
            Ok((text, tin, tout, cost, model, duration_ms)) => {
                turn_usage = Some((tin, tout, cost, model, duration_ms));
                text
            }
            Err(e) => {
                tracing::warn!("[c35:channel] prompt_turn failed: {}", e);
                channel_stub_reply(&job.message, false)
            }
        }
    };

    let (clean, was_oos) = reply_oos_strip(&reply);
    reply = clean;

    let turn_meta = bot_turn_meta_load(&state.pool, job.bot_iid).await;
    if bot_auto_block_enabled(&turn_meta) {
        let apply = chat_strict_oos_apply(
            &state.pool,
            state.nats.as_ref(),
            job.owner_iid,
            job.bot_iid,
            job.chat_id,
            was_oos,
            true,
        )
        .await?;
        if apply.newly_blocked {
            tracing::info!(
                "[c35:channel] auto-blocked chat_id={} bot_iid={} strict_oos_count={}",
                job.chat_id,
                job.bot_iid,
                apply.count
            );
        }
    }

    limiter.outbound_pace().await;
    let cas = ChannelCasCtx {
        pool: &state.pool,
        cas_dir: &state.cas_dir,
        cas_secret: &state.cas_secret,
    };
    channel_reply_nats(&client, state.nats.as_ref(), Some(&cas), &out_ctx, &reply, false).await?;
    let (tin, tout, cost, model, duration_ms) = turn_usage
        .as_ref()
        .map(|(a, b, c, m, d)| (*a, *b, *c, m.clone(), *d))
        .unwrap_or((0, 0, 0.0, String::new(), 0));
    if !model.is_empty() {
        let _ = sqlx::query("UPDATE ai.chat SET model = $2, updated_ts = NOW() WHERE id = $1")
            .bind(job.chat_id)
            .bind(&model)
            .execute(&state.pool)
            .await;
    }
    let assistant_msg_id = chat_msg_assistant_put_usage(
        &state.pool,
        job.chat_id,
        job.owner_iid,
        job.bot_iid,
        &job.req_id,
        &reply,
        tin,
        tout,
        duration_ms,
        cost,
    )
    .await?;
    let _ = chat_msg_usage_sync_from_log(&state.pool, assistant_msg_id, &job.req_id).await;
    let _ = bot_peer_msg_fanout(
        &state.pool,
        state.nats.as_ref(),
        job.owner_iid,
        job.chat_id,
        assistant_msg_id,
    )
    .await;
    let _ = prompt_run_finish(&state.pool, &job.req_id, "done", tin, tout, cost, duration_ms, None, None).await;
    let queued = prompt_followup_next_queued(&state.pool, &job.req_id).await?;
    if let Some(q) = queued {
        let _ = prompt_followup_mark_queue_delivered(&state.pool, &q.id).await;
        let follow_job = ChannelTurnJob {
            bot_iid: job.bot_iid,
            chat_id: job.chat_id,
            owner_iid: job.owner_iid,
            peer_iid: job.peer_iid,
            channel: job.channel.clone(),
            inbound: job.inbound.clone(),
            message: q.text,
            attachments_json: q.attachments_json,
            req_id: crate::outbound::channel_req_id(&job.inbound.platform),
        };
        debouncer_turn_finished(state.clone(), job.chat_id).await;
        crate::hub::channel_hub()
            .debouncer
            .lock()
            .await
            .schedule(state, follow_job);
        return Ok(());
    }
    debouncer_turn_finished(state, job.chat_id).await;
    Ok(())
}

fn http_client() -> Client {
    Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()
        .unwrap_or_else(|_| Client::new())
}
