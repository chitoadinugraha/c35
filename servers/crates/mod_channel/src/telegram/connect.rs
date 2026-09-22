use c35_mod_log::{log_put, LogPut};
use c35_proto::{ReqChannelTelegramConnect, ResChannelTelegramConnect};
use serde::Deserialize;
use sqlx::PgPool;
use tracing::{info, warn};

use crate::store::{
    bot_channel_external_taken, bot_channel_find_telegram_token, bot_channel_upsert, bot_ensure,
    channel_external_key, channel_secret_generate, new_channel_id, telegram_webhook_url, ChannelDoc,
    ChannelSession,
};

const TG_API: &str = "https://api.telegram.org";

pub fn tg_api_base() -> String {
    std::env::var("TELEGRAM_API_BASE")
        .ok()
        .map(|s| s.trim().trim_end_matches('/').to_string())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| TG_API.into())
}

pub async fn tg_send_chat_action(
    client: &reqwest::Client,
    api_base: &str,
    token: &str,
    chat_id: &str,
    action: &str,
) -> Result<(), String> {
    let url = format!("{}/bot{token}/sendChatAction", api_base.trim_end_matches('/'));
    let res = client
        .post(&url)
        .json(&serde_json::json!({ "chat_id": chat_id, "action": action }))
        .send()
        .await
        .map_err(|e| e.to_string())?;
    let body: TgResponse<serde_json::Value> = res.json().await.map_err(|e| e.to_string())?;
    if !body.ok {
        return Err(body.description.unwrap_or_else(|| "sendChatAction failed".into()));
    }
    Ok(())
}

pub async fn tg_send_message(
    client: &reqwest::Client,
    api_base: &str,
    token: &str,
    chat_id: &str,
    text: &str,
    parse_mode: Option<&str>,
) -> Result<(), String> {
    let url = format!("{}/bot{token}/sendMessage", api_base.trim_end_matches('/'));
    let mut payload = serde_json::json!({ "chat_id": chat_id, "text": text });
    if let Some(mode) = parse_mode {
        payload["parse_mode"] = serde_json::json!(mode);
    }
    let res = client.post(&url).json(&payload).send().await.map_err(|e| e.to_string())?;
    let body: TgResponse<serde_json::Value> = res.json().await.map_err(|e| e.to_string())?;
    if !body.ok {
        return Err(body.description.unwrap_or_else(|| "sendMessage failed".into()));
    }
    Ok(())
}

pub async fn tg_send_voice_reply(
    client: &reqwest::Client,
    api_base: &str,
    token: &str,
    chat_id: &str,
    audio: &[u8],
    caption: &str,
) -> Result<(), String> {
    let voice_url = format!("{}/bot{token}/sendVoice", api_base.trim_end_matches('/'));
    let part = reqwest::multipart::Part::bytes(audio.to_vec())
        .file_name("voice.ogg")
        .mime_str("audio/ogg")
        .map_err(|e| e.to_string())?;
    let mut form = reqwest::multipart::Form::new()
        .text("chat_id", chat_id.to_string())
        .part("voice", part);
    if !caption.is_empty() {
        form = form.text("caption", caption.to_string());
    }
    let res = client.post(&voice_url).multipart(form).send().await.map_err(|e| e.to_string())?;
    let body: TgResponse<serde_json::Value> = res.json().await.map_err(|e| e.to_string())?;
    if body.ok {
        return Ok(());
    }
    let voice_err = body.description.unwrap_or_else(|| "sendVoice failed".into());

    let audio_url = format!("{}/bot{token}/sendAudio", api_base.trim_end_matches('/'));
    let part = reqwest::multipart::Part::bytes(audio.to_vec())
        .file_name("reply.mp3")
        .mime_str("audio/mpeg")
        .map_err(|e| e.to_string())?;
    let mut form = reqwest::multipart::Form::new()
        .text("chat_id", chat_id.to_string())
        .part("audio", part);
    if !caption.is_empty() {
        form = form.text("caption", caption.to_string());
    }
    let res = client.post(&audio_url).multipart(form).send().await.map_err(|e| e.to_string())?;
    let body: TgResponse<serde_json::Value> = res.json().await.map_err(|e| e.to_string())?;
    if !body.ok {
        return Err(format!(
            "{voice_err}; sendAudio: {}",
            body.description.unwrap_or_else(|| "sendAudio failed".into())
        ));
    }
    Ok(())
}

pub async fn tg_send_photo_url(
    client: &reqwest::Client,
    api_base: &str,
    token: &str,
    chat_id: &str,
    photo_url: &str,
    caption: &str,
) -> Result<(), String> {
    let url = format!("{}/bot{token}/sendPhoto", api_base.trim_end_matches('/'));
    let mut payload = serde_json::json!({
        "chat_id": chat_id,
        "photo": photo_url
    });
    if !caption.is_empty() {
        payload["caption"] = serde_json::json!(caption);
    }
    let res = client
        .post(&url)
        .json(&payload)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    let body: TgResponse<serde_json::Value> = res.json().await.map_err(|e| e.to_string())?;
    if !body.ok {
        return Err(body.description.unwrap_or_else(|| "sendPhoto failed".into()));
    }
    Ok(())
}

pub async fn tg_send_document_bytes(
    client: &reqwest::Client,
    api_base: &str,
    token: &str,
    chat_id: &str,
    bytes: &[u8],
    mime: &str,
    name: &str,
    caption: &str,
) -> Result<(), String> {
    let url = format!("{}/bot{token}/sendDocument", api_base.trim_end_matches('/'));
    let part = reqwest::multipart::Part::bytes(bytes.to_vec())
        .file_name(name.to_string())
        .mime_str(mime)
        .map_err(|e| e.to_string())?;
    let mut form = reqwest::multipart::Form::new()
        .text("chat_id", chat_id.to_string())
        .part("document", part);
    if !caption.is_empty() {
        form = form.text("caption", caption.to_string());
    }
    let res = client.post(&url).multipart(form).send().await.map_err(|e| e.to_string())?;
    let body: TgResponse<serde_json::Value> = res.json().await.map_err(|e| e.to_string())?;
    if !body.ok {
        return Err(body.description.unwrap_or_else(|| "sendDocument failed".into()));
    }
    Ok(())
}

#[derive(Debug, Deserialize)]
struct TgResponse<T> {
    ok: bool,
    result: Option<T>,
    description: Option<String>,
}

#[derive(Debug, Deserialize)]
struct TgUser {
    username: Option<String>,
    first_name: Option<String>,
}

fn tg_display_name(me: &TgUser) -> String {
    let first = me.first_name.as_deref().unwrap_or("").trim();
    if !first.is_empty() {
        return first.to_string();
    }
    let username = me.username.as_deref().unwrap_or("").trim();
    if !username.is_empty() {
        return format!("@{username}");
    }
    "Telegram Bot".into()
}

fn telegram_bot_token_normalize(raw: &str) -> String {
    raw.chars().filter(|c| !c.is_whitespace()).collect()
}

async fn tg_get_me(client: &reqwest::Client, token: &str) -> Result<TgUser, String> {
    let url = format!("{}/bot{token}/getMe", tg_api_base());
    let body: TgResponse<TgUser> = client.get(&url).send().await.map_err(|e| e.to_string())?.json().await.map_err(|e| e.to_string())?;
    if !body.ok {
        return Err(body.description.unwrap_or_else(|| "invalid bot token".into()));
    }
    body.result.ok_or_else(|| "empty getMe result".into())
}

async fn tg_set_webhook(client: &reqwest::Client, token: &str, hook_url: &str, secret: &str) -> Result<(), String> {
    let url = format!("{}/bot{token}/setWebhook", tg_api_base());
    let res = client
        .post(&url)
        .json(&serde_json::json!({
            "url": hook_url,
            "secret_token": secret,
            "drop_pending_updates": true,
        }))
        .send()
        .await
        .map_err(|e| e.to_string())?;
    let body: TgResponse<bool> = res.json().await.map_err(|e| e.to_string())?;
    if !body.ok {
        return Err(body.description.unwrap_or_else(|| "setWebhook failed".into()));
    }
    Ok(())
}

pub async fn channel_telegram_connect(
    pool: &PgPool,
    owner_iid: i64,
    public_origin: &str,
    req: ReqChannelTelegramConnect,
    nats: Option<&async_nats::Client>,
) -> Result<ResChannelTelegramConnect, String> {
    let token = telegram_bot_token_normalize(&req.bot_token);
    if token.is_empty() {
        return Err("bot token required".into());
    }
    if let Some((bot_iid, _)) = bot_channel_find_telegram_token(pool, &token).await.map_err(|e| e.to_string())? {
        let owner = crate::store::bot_owner_iid(pool, bot_iid).await.map_err(|e| e.to_string())?;
        if owner != Some(owner_iid) {
            return Err("this Telegram bot is already connected to another account".into());
        }
    }

    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()
        .map_err(|e| e.to_string())?;
    let me = tg_get_me(&client, &token).await?;
    let display_name = tg_display_name(&me);
    let username = me.username.unwrap_or_default();
    info!("[c35:telegram] getMe ok owner_iid={owner_iid} bot={display_name}");

    let bot_iid = bot_ensure(pool, owner_iid, req.bot_iid, &display_name).await.map_err(|e| e.to_string())?;
    let channel_id = new_channel_id();
    let webhook_secret = channel_secret_generate();
    let hook = telegram_webhook_url(public_origin, bot_iid, &channel_id, &webhook_secret);

    let channel = ChannelDoc {
        id: channel_id.clone(),
        platform: "telegram".into(),
        provider: String::new(),
        status: "pairing".into(),
        webhook_secret,
        verify_token: String::new(),
        bot_token: token.clone(),
        bot_username: username.clone(),
        phone_number_id: String::new(),
        access_token: String::new(),
        phone: String::new(),
        error_message: String::new(),
        session: ChannelSession::default(),
    };
    let ext_key = channel_external_key(&channel);
    if bot_channel_external_taken(pool, bot_iid, &ext_key, "")
        .await
        .map_err(|e| e.to_string())?
    {
        return Err("this Telegram bot is already connected to this chat bot".into());
    }

    bot_channel_upsert(pool, owner_iid, bot_iid, channel.clone())
        .await
        .map_err(|e| e.to_string())?;

    info!("[c35:telegram] setWebhook owner_iid={owner_iid} bot_iid={bot_iid} channel_id={channel_id}");
    if let Err(e) = tg_set_webhook(&client, &token, &hook, &channel.webhook_secret).await {
        warn!("[c35:telegram] setWebhook failed channel_id={channel_id}: {e}");
        let err_channel = ChannelDoc {
            status: "error".into(),
            ..channel
        };
        bot_channel_upsert(pool, owner_iid, bot_iid, err_channel).await.map_err(|e| e.to_string())?;
        let _ = log_put(
            pool,
            nats,
            LogPut {
                owner_iid,
                kind: "error",
                topic: "error",
                dv: "c35-server",
                req_id: None,
                chat_id: None,
                task_id: None,
                device_iid: None,
                text: "Telegram channel connect failed",
                model: "",
                tokens_in: 0,
                tokens_out: 0,
                duration_ms: 0,
                cost_usd: 0.0,
                meta: serde_json::json!({
                    "platform": "telegram",
                    "bot_iid": bot_iid,
                    "channel_id": channel_id,
                    "error": e,
                }),
            },
        )
        .await;
        return Err(e);
    }

    let connected = ChannelDoc {
        status: "connected".into(),
        ..channel
    };
    bot_channel_upsert(pool, owner_iid, bot_iid, connected.clone())
        .await
        .map_err(|e| e.to_string())?;

    let _ = log_put(
        pool,
        nats,
        LogPut {
            owner_iid,
            kind: "system",
            topic: "connected",
            dv: "c35-server",
            req_id: None,
            chat_id: None,
            task_id: None,
            device_iid: None,
            text: "Telegram channel connected",
            model: "",
            tokens_in: 0,
            tokens_out: 0,
            duration_ms: 0,
            cost_usd: 0.0,
            meta: serde_json::json!({
                "platform": "telegram",
                "bot_iid": bot_iid,
                "channel_id": channel_id,
            }),
        },
    )
    .await;

    Ok(ResChannelTelegramConnect {
        bot_iid,
        channel: Some(connected.to_proto()),
        webhook_url: hook,
    })
}
