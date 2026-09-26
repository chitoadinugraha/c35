use crate::channel_event::channel_disconnected_emit;
use c35_proto::{ReqChannelDisconnect, ResChannelDisconnect};
use sqlx::PgPool;
use tracing::info;

use crate::store::{bot_channel_get, bot_channel_remove, bot_owner_iid};
use crate::telegram::tg_api_base;
use crate::whatsapp::worker_post;

async fn tg_delete_webhook(token: &str) -> Result<(), String> {
    if token.trim().is_empty() {
        return Ok(());
    }
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(15))
        .build()
        .map_err(|e| e.to_string())?;
    let url = format!("{}/bot{token}/deleteWebhook", tg_api_base());
    let res = client.post(&url).send().await.map_err(|e| e.to_string())?;
    if !res.status().is_success() {
        let body = res.text().await.unwrap_or_default();
        return Err(format!("deleteWebhook failed: {body}"));
    }
    Ok(())
}

pub async fn channel_disconnect(
    pool: &PgPool,
    owner_iid: i64,
    req: ReqChannelDisconnect,
    nats: Option<&async_nats::Client>,
    worker_url: &str,
) -> ResChannelDisconnect {
    let bot_iid = req.bot_iid;
    let channel_id = req.channel_id.trim();
    if bot_iid <= 0 || channel_id.is_empty() {
        return ResChannelDisconnect {
            ok: false,
            error: "bot_iid and channel_id required".into(),
            bot_iid,
            channel_id: channel_id.to_string(),
        };
    }
    let owner = bot_owner_iid(pool, bot_iid).await.unwrap_or(None);
    if owner != Some(owner_iid) {
        return ResChannelDisconnect {
            ok: false,
            error: "forbidden".into(),
            bot_iid,
            channel_id: channel_id.to_string(),
        };
    }
    let ch = match bot_channel_get(pool, bot_iid, channel_id).await {
        Ok(Some(doc)) => doc,
        Ok(None) => {
            return ResChannelDisconnect {
                ok: false,
                error: "channel not found".into(),
                bot_iid,
                channel_id: channel_id.to_string(),
            };
        }
        Err(e) => {
            return ResChannelDisconnect {
                ok: false,
                error: e.to_string(),
                bot_iid,
                channel_id: channel_id.to_string(),
            };
        }
    };

    if ch.platform == "telegram" && !ch.bot_token.is_empty() {
        if let Err(e) = tg_delete_webhook(&ch.bot_token).await {
            tracing::warn!("[c35:telegram] deleteWebhook failed channel_id={channel_id}: {e}");
        }
    }
    if ch.is_linked_whatsapp() {
        if let Err(e) = worker_post(worker_url, &format!("/v1/channel/{bot_iid}/{channel_id}/stop")).await {
            tracing::warn!("[c35:whatsapp] worker stop failed channel_id={channel_id}: {e}");
        }
    }

    if let Err(e) = bot_channel_remove(pool, owner_iid, bot_iid, channel_id).await {
        return ResChannelDisconnect {
            ok: false,
            error: e.to_string(),
            bot_iid,
            channel_id: channel_id.to_string(),
        };
    }

    channel_disconnected_emit(
        pool,
        nats,
        owner_iid,
        &ch.platform,
        channel_id,
        serde_json::json!({
            "platform": ch.platform,
            "bot_iid": bot_iid,
            "channel_id": channel_id,
        }),
    )
    .await;

    info!("[c35:channel] disconnect owner_iid={owner_iid} bot_iid={bot_iid} channel_id={channel_id}");
    ResChannelDisconnect {
        ok: true,
        error: String::new(),
        bot_iid,
        channel_id: channel_id.to_string(),
    }
}

pub async fn bot_channels_disconnect_all(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: i64,
    nats: Option<&async_nats::Client>,
    worker_url: &str,
) -> Result<(), String> {
    let channels = crate::store::bot_channel_list(pool, owner_iid, bot_iid)
        .await
        .map_err(|e| e.to_string())?;
    for ch in channels {
        let _ = channel_disconnect(
            pool,
            owner_iid,
            ReqChannelDisconnect {
                bot_iid,
                channel_id: ch.id.clone(),
            },
            nats,
            worker_url,
        )
        .await;
    }
    Ok(())
}
