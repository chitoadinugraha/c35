use c35_mod_log::{log_put, LogPut};
use c35_proto::ResChannelWhatsappPair;
use serde::Serialize;
use sqlx::PgPool;
use tracing::{info, warn};

use crate::store::{
    bot_channel_get, bot_channel_pair_watch_touch, bot_channel_patch_session,
    bot_channel_upsert, bot_ensure, bot_linked_channel_get, channel_secret_generate,
    channel_whatsapp_deactivate_siblings, new_channel_id, phone_jid_display, ChannelDoc, ChannelSession,
    PROVIDER_LINKED, STATUS_DISCONNECTED, STATUS_PAIRING,
};

pub const SUBJ_PAIR: &str = "c35.act.channel.whatsapp.device.pair";

#[derive(Clone, Debug, Serialize)]
pub struct ActChannelWhatsappPair {
    pub bot_iid: i64,
    pub channel_id: String,
    pub owner_iid: i64,
}

fn pair_res_ok(bot_iid: i64, ch: &ChannelDoc) -> ResChannelWhatsappPair {
    ResChannelWhatsappPair {
        ok: true,
        error: String::new(),
        bot_iid,
        channel: Some(ch.to_proto()),
        qr_raw: ch.session.qr_raw.clone(),
        phone: if ch.phone.is_empty() {
            phone_jid_display(&ch.session.phone_jid)
        } else {
            ch.phone.clone()
        },
    }
}

fn pair_res_err(bot_iid: i64, message: &str) -> ResChannelWhatsappPair {
    ResChannelWhatsappPair {
        ok: false,
        error: message.to_string(),
        bot_iid,
        channel: None,
        qr_raw: String::new(),
        phone: String::new(),
    }
}

pub async fn worker_post(worker_url: &str, path: &str) -> Result<(), String> {
    let base = worker_url.trim().trim_end_matches('/');
    if base.is_empty() {
        warn!("[c35:whatsapp] WHATSAPP_WORKER_URL unset; skipping worker call {path}");
        return Ok(());
    }
    let url = format!("{base}{path}");
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(15))
        .build()
        .map_err(|e| e.to_string())?;
    let res = client.post(&url).send().await.map_err(|e| e.to_string())?;
    if !res.status().is_success() {
        let body = res.text().await.unwrap_or_default();
        return Err(format!("worker {path} failed: {body}"));
    }
    Ok(())
}

fn pair_publish_nats(nats: Option<&async_nats::Client>, act: ActChannelWhatsappPair) {
    if let Some(client) = nats {
        if let Ok(payload) = serde_json::to_vec(&act) {
            let client = client.clone();
            tokio::spawn(async move {
                if let Err(e) = client.publish(SUBJ_PAIR, payload.into()).await {
                    warn!("[c35:whatsapp] NATS pair publish failed channel_id={}: {e}", act.channel_id);
                }
            });
        }
    }
}

pub async fn channel_whatsapp_pair_start(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: i64,
    channel_id: &str,
    nats: Option<&async_nats::Client>,
    worker_url: &str,
) -> Result<ResChannelWhatsappPair, String> {
    if bot_iid <= 0 {
        return Err("bot_iid required".into());
    }
    let bot_iid = bot_ensure(pool, owner_iid, bot_iid, "Bot").await.map_err(|e| e.to_string())?;
    let channel_id = if channel_id.trim().is_empty() {
        new_channel_id()
    } else {
        channel_id.trim().to_string()
    };

    let existing = bot_channel_get(pool, bot_iid, &channel_id).await.map_err(|e| e.to_string())?;
    let channel = ChannelDoc {
        id: channel_id.clone(),
        platform: "whatsapp".into(),
        provider: PROVIDER_LINKED.into(),
        status: STATUS_PAIRING.into(),
        webhook_secret: existing
            .as_ref()
            .map(|c| c.webhook_secret.clone())
            .filter(|s| !s.is_empty())
            .unwrap_or_else(channel_secret_generate),
        verify_token: String::new(),
        bot_token: String::new(),
        bot_username: String::new(),
        phone_number_id: String::new(),
        access_token: String::new(),
        phone: String::new(),
        error_message: String::new(),
        session: ChannelSession {
            qr_raw: String::new(),
            phone_jid: String::new(),
            sqlite_session_b64: String::new(),
            pair_watch_until_ms: crate::store::pair_watch_until_ms(true),
            error_message: String::new(),
        },
    };
    bot_channel_upsert(pool, owner_iid, bot_iid, channel.clone())
        .await
        .map_err(|e| e.to_string())?;
    channel_whatsapp_deactivate_siblings(pool, owner_iid, bot_iid, &channel_id)
        .await
        .map_err(|e| e.to_string())?;

    let _ = log_put(
        pool,
        nats,
        LogPut {
            class: None,            owner_iid,
            kind: "system",
            topic: "pair_start",
            dv: "c35-server",
            req_id: None,
            chat_id: None,
            task_id: None,
            device_iid: None,
            text: "WhatsApp QR pairing started",
            model: "",
            tokens_in: 0,
            tokens_out: 0,
            duration_ms: 0,
            cost_usd: 0.0,
            meta: serde_json::json!({
                "platform": "whatsapp",
                "provider": PROVIDER_LINKED,
                "bot_iid": bot_iid,
                "channel_id": channel_id,
            }),
        },
    )
    .await;

    pair_publish_nats(
        nats,
        ActChannelWhatsappPair {
            bot_iid,
            channel_id: channel_id.clone(),
            owner_iid,
        },
    );

    if let Err(e) = worker_post(worker_url, &format!("/v1/channel/{bot_iid}/{channel_id}/restart")).await {
        warn!("[c35:whatsapp] worker restart failed channel_id={channel_id}: {e}");
    }

    info!("[c35:whatsapp] pair_start owner_iid={owner_iid} bot_iid={bot_iid} channel_id={channel_id}");
    let ch = bot_linked_channel_get(pool, owner_iid, bot_iid, &channel_id)
        .await
        .map_err(|e| e.to_string())?
        .ok_or_else(|| "channel not found after pair start".to_string())?;
    Ok(pair_res_ok(bot_iid, &ch))
}

pub async fn channel_whatsapp_pair_watch(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: i64,
    channel_id: &str,
) -> Result<ResChannelWhatsappPair, String> {
    if bot_iid <= 0 || channel_id.trim().is_empty() {
        return Err("bot_iid and channel_id required".into());
    }
    let channel_id = channel_id.trim();
    let ch = bot_linked_channel_get(pool, owner_iid, bot_iid, channel_id)
        .await
        .map_err(|e| e.to_string())?
        .ok_or_else(|| "WhatsApp linked channel not found".to_string())?;
    if ch.status == STATUS_PAIRING {
        bot_channel_pair_watch_touch(pool, owner_iid, bot_iid, channel_id, false)
            .await
            .map_err(|e| e.to_string())?;
    }
    let ch = bot_linked_channel_get(pool, owner_iid, bot_iid, channel_id)
        .await
        .map_err(|e| e.to_string())?
        .ok_or_else(|| "channel not found".to_string())?;
    Ok(pair_res_ok(bot_iid, &ch))
}

pub async fn channel_whatsapp_pair_abort(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: i64,
    channel_id: &str,
    nats: Option<&async_nats::Client>,
    worker_url: &str,
) -> Result<(), String> {
    if bot_iid <= 0 || channel_id.trim().is_empty() {
        return Err("bot_iid and channel_id required".into());
    }
    let channel_id = channel_id.trim();
    if bot_linked_channel_get(pool, owner_iid, bot_iid, channel_id)
        .await
        .map_err(|e| e.to_string())?
        .is_none()
    {
        return Err("WhatsApp linked channel not found".into());
    }

    bot_channel_patch_session(
        pool,
        owner_iid,
        bot_iid,
        channel_id,
        serde_json::json!({
            "qr_raw": "",
            "phone_jid": "",
            "sqlite_session_b64": "",
            "pair_watch_until_ms": 0,
            "error_message": ""
        }),
    )
    .await
    .map_err(|e| e.to_string())?;

    if let Some(mut ch) = bot_channel_get(pool, bot_iid, channel_id).await.map_err(|e| e.to_string())? {
        ch.status = STATUS_DISCONNECTED.into();
        ch.error_message.clear();
        ch.session = ChannelSession::default();
        bot_channel_upsert(pool, owner_iid, bot_iid, ch).await.map_err(|e| e.to_string())?;
    }

    let _ = log_put(
        pool,
        nats,
        LogPut {
            class: None,            owner_iid,
            kind: "system",
            topic: "pair_abort",
            dv: "c35-server",
            req_id: None,
            chat_id: None,
            task_id: None,
            device_iid: None,
            text: "WhatsApp QR pairing cancelled",
            model: "",
            tokens_in: 0,
            tokens_out: 0,
            duration_ms: 0,
            cost_usd: 0.0,
            meta: serde_json::json!({
                "platform": "whatsapp",
                "provider": PROVIDER_LINKED,
                "bot_iid": bot_iid,
                "channel_id": channel_id,
            }),
        },
    )
    .await;

    if let Err(e) = worker_post(worker_url, &format!("/v1/channel/{bot_iid}/{channel_id}/stop")).await {
        warn!("[c35:whatsapp] worker stop failed channel_id={channel_id}: {e}");
    }

    info!("[c35:whatsapp] pair_abort owner_iid={owner_iid} bot_iid={bot_iid} channel_id={channel_id}");
    Ok(())
}

pub fn pair_res_from_channel(bot_iid: i64, ch: &ChannelDoc) -> ResChannelWhatsappPair {
    pair_res_ok(bot_iid, ch)
}

pub fn pair_res_from_error(bot_iid: i64, message: &str) -> ResChannelWhatsappPair {
    pair_res_err(bot_iid, message)
}
