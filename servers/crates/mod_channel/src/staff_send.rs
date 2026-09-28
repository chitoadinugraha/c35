use anyhow::Result;
use c35_ctx::AppState;
use c35_mod_chat::BOT_APP_CHANNEL_ID;
use reqwest::Client;
use sqlx::Row;
use crate::outbound::{channel_reply_nats_payload, outbound_ctx_with_msg, ChannelCasCtx};
use crate::render::{outbound_payload_parse, OutboundMedia, OutboundMediaKind};
use crate::store::bot_channel_get;

pub async fn bot_peer_staff_channel_deliver(
    state: &AppState,
    chat_id: i64,
    text: &str,
    attachments_json: &str,
) -> Result<()> {
    let text = text.trim();
    let mut payload = outbound_payload_parse(text);
    if let Ok(val) = serde_json::from_str::<serde_json::Value>(attachments_json) {
        if let Some(arr) = val.as_array() {
            for item in arr {
                let hash = item.get("hash").and_then(|v| v.as_str()).unwrap_or_default();
                if hash.is_empty() {
                    continue;
                }
                let mime = item.get("mime").and_then(|v| v.as_str()).unwrap_or("application/octet-stream");
                let name = item.get("name").and_then(|v| v.as_str()).unwrap_or("attachment");
                let kind = if mime.starts_with("image/") {
                    OutboundMediaKind::Image
                } else if mime.starts_with("audio/") {
                    OutboundMediaKind::Audio
                } else {
                    OutboundMediaKind::Document
                };
                if !payload.media.iter().any(|m| m.hash == hash) {
                    payload.media.push(OutboundMedia {
                        kind,
                        hash: hash.to_string(),
                        mime: mime.to_string(),
                        name: name.to_string(),
                    });
                }
            }
        }
    }
    if payload.text.trim().is_empty() && payload.media.is_empty() {
        return Ok(());
    }
    let row = sqlx::query(
        r#"
        SELECT owner_iid, bot_iid, channel_id, peer_key
        FROM ai.chat
        WHERE id = $1 AND kind = 'bot_peer' AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(chat_id)
    .fetch_optional(&state.pool)
    .await?;
    let Some(row) = row else { return Ok(()); };
    let channel_id: String = row.get("channel_id");
    if channel_id == BOT_APP_CHANNEL_ID {
        return Ok(());
    }
    let bot_iid: i64 = row.get("bot_iid");
    let owner_iid: i64 = row.get("owner_iid");
    let peer_key: String = row.get("peer_key");
    let Some(channel) = bot_channel_get(&state.pool, bot_iid, &channel_id).await? else {
        return Ok(());
    };
    let platform = if channel.platform.is_empty() {
        channel_id.clone()
    } else {
        channel.platform.clone()
    };
    let client = Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()
        .unwrap_or_else(|_| Client::new());
    let out_ctx = outbound_ctx_with_msg(&platform, &peer_key, &channel, owner_iid, bot_iid, None);
    let cas = ChannelCasCtx {
        pool: &state.pool,
        cas_dir: &state.cas_dir,
        cas_secret: &state.cas_secret,
    };
    channel_reply_nats_payload(&client, state.nats.as_ref(), Some(&cas), &out_ctx, &payload, false).await?;
    Ok(())
}
