use c35_mod_log::{log_put, LogPut};
use c35_proto::{ReqChannelWhatsappMetaConnect, ResChannelWhatsappMetaConnect};
use serde::Deserialize;
use sqlx::PgPool;
use tracing::info;

use crate::store::{
    bot_channel_upsert, bot_ensure, channel_secret_generate, channel_whatsapp_deactivate_siblings,
    new_channel_id, whatsapp_webhook_url, ChannelDoc, ChannelSession,
};

#[derive(Debug, Deserialize)]
struct MetaPhoneResponse {
    display_phone_number: Option<String>,
    verified_name: Option<String>,
}

pub async fn channel_whatsapp_meta_connect(
    pool: &PgPool,
    owner_iid: i64,
    public_origin: &str,
    req: ReqChannelWhatsappMetaConnect,
    nats: Option<&async_nats::Client>,
) -> Result<ResChannelWhatsappMetaConnect, String> {
    let access_token = req.access_token.trim();
    let phone_number_id = req.phone_number_id.trim();
    if access_token.is_empty() || phone_number_id.is_empty() {
        return Err("access_token and phone_number_id required".into());
    }
    let graph = std::env::var("META_GRAPH_API_BASE")
        .ok()
        .filter(|s| !s.trim().is_empty())
        .unwrap_or_else(|| "https://graph.facebook.com/v21.0".to_string())
        .trim_end_matches('/')
        .to_string();
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()
        .map_err(|e| e.to_string())?;
    let url = format!("{graph}/{phone_number_id}?fields=display_phone_number,verified_name");
    let res = client
        .get(&url)
        .header("Authorization", format!("Bearer {access_token}"))
        .send()
        .await
        .map_err(|e| e.to_string())?;
    if !res.status().is_success() {
        let body = res.text().await.unwrap_or_default();
        let msg = format!("Meta Cloud API rejected credentials: {body}");
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
                text: "WhatsApp Meta channel connect failed",
                model: "",
                tokens_in: 0,
                tokens_out: 0,
                duration_ms: 0,
                cost_usd: 0.0,
                meta: serde_json::json!({
                    "platform": "whatsapp",
                    "provider": "meta_api",
                    "bot_iid": req.bot_iid,
                }),
            },
        )
        .await;
        return Err(msg);
    }
    let phone: MetaPhoneResponse = res.json().await.map_err(|e| e.to_string())?;
    let display_phone = phone.display_phone_number.filter(|s| !s.is_empty()).unwrap_or_else(|| phone_number_id.to_string());
    let verified_name = phone.verified_name.filter(|s| !s.is_empty()).unwrap_or_else(|| "WhatsApp".into());

    let bot_iid = bot_ensure(pool, owner_iid, req.bot_iid, &verified_name).await.map_err(|e| e.to_string())?;
    let channel_id = new_channel_id();
    let verify_token = channel_secret_generate();
    let hook = whatsapp_webhook_url(public_origin, bot_iid, &channel_id);
    let verify_token_out = verify_token.clone();
    info!("[c35:whatsapp] meta connect owner_iid={owner_iid} bot_iid={bot_iid} channel_id={channel_id}");

    let channel = ChannelDoc {
        id: channel_id.clone(),
        platform: "whatsapp".into(),
        provider: "meta_api".into(),
        status: "connected".into(),
        webhook_secret: String::new(),
        verify_token,
        bot_token: String::new(),
        bot_username: String::new(),
        phone_number_id: phone_number_id.to_string(),
        access_token: access_token.to_string(),
        phone: display_phone,
        error_message: String::new(),
        session: ChannelSession::default(),
    };
    bot_channel_upsert(pool, owner_iid, bot_iid, channel.clone())
        .await
        .map_err(|e| e.to_string())?;
    channel_whatsapp_deactivate_siblings(pool, owner_iid, bot_iid, &channel.id)
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
            text: "WhatsApp Meta channel connected",
            model: "",
            tokens_in: 0,
            tokens_out: 0,
            duration_ms: 0,
            cost_usd: 0.0,
            meta: serde_json::json!({
                "platform": "whatsapp",
                "provider": "meta_api",
                "bot_iid": bot_iid,
                "channel_id": channel_id,
            }),
        },
    )
    .await;

    Ok(ResChannelWhatsappMetaConnect {
        bot_iid,
        channel: Some(channel.to_proto()),
        webhook_url: hook,
        verify_token: verify_token_out,
    })
}
