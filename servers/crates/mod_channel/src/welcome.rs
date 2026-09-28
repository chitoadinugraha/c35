use anyhow::Result;
use c35_ctx::AppState;
use c35_mod_chat::bot_welcome_text;
use c35_store::snowflake_id;
use reqwest::Client;

use crate::outbound::{channel_reply_nats, outbound_ctx_with_msg, ChannelCasCtx};
use crate::peer::chat_msg_assistant_put;
use crate::store::ChannelDoc;
use crate::types::ChannelInboundMessage;

pub async fn channel_welcome_deliver(
    state: &AppState,
    bot_iid: i64,
    owner_iid: i64,
    chat_id: i64,
    channel: &ChannelDoc,
    inbound: &ChannelInboundMessage,
) -> Result<()> {
    let Some(text) = bot_welcome_text(&state.pool, bot_iid).await else {
        return Ok(());
    };
    let req_id = format!("welcome-{}", snowflake_id());
    let client = Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()
        .unwrap_or_else(|_| Client::new());
    let out_ctx = outbound_ctx_with_msg(
        &inbound.platform,
        &inbound.external_user_id,
        channel,
        owner_iid,
        bot_iid,
        None,
    );
    let cas = ChannelCasCtx {
        pool: &state.pool,
        cas_dir: &state.cas_dir,
        cas_secret: &state.cas_secret,
    };
    if inbound.platform != "app" {
        channel_reply_nats(&client, state.nats.as_ref(), Some(&cas), &out_ctx, &text, false).await?;
    }
    let msg_id = chat_msg_assistant_put(
        &state.pool,
        chat_id,
        owner_iid,
        bot_iid,
        &req_id,
        &text,
    )
    .await?;
    let _ = c35_mod_chat::bot_peer_msg_fanout(
        &state.pool,
        state.nats.as_ref(),
        owner_iid,
        chat_id,
        msg_id,
    )
    .await;
    Ok(())
}