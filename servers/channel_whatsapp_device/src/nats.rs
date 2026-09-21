use anyhow::{Context, Result};
use async_nats::Client as NatsClient;
use serde::{Deserialize, Serialize};
use tracing::{debug, info};

pub const SUBJ_PAIR: &str = "c35.act.channel.whatsapp.device.pair";
pub const SUBJ_PAIR_EV_PREFIX: &str = "c35.ev.channel";
pub const SUBJ_MSG_IN_PREFIX: &str = "c35.ev.channel";
pub const SUBJ_MSG_SEND_WILDCARD: &str = "c35.act.channel.*.*.*.msg.send";
pub const SUBJ_MSG_TYPING_WILDCARD: &str = "c35.act.channel.*.*.*.msg.typing";
pub const QUEUE_OUTBOUND: &str = "channel-whatsapp-device-senders";

pub fn pair_ev_subject(owner_iid: i64, bot_iid: i64, channel_id: &str) -> String {
    format!("{SUBJ_PAIR_EV_PREFIX}.{owner_iid}.{bot_iid}.{channel_id}.pair")
}

pub fn msg_in_subject(owner_iid: i64, bot_iid: i64, channel_id: &str) -> String {
    format!("{SUBJ_MSG_IN_PREFIX}.{owner_iid}.{bot_iid}.{channel_id}.msg.in")
}

pub fn msg_send_subject(owner_iid: i64, bot_iid: i64, channel_id: &str) -> String {
    format!("c35.act.channel.{owner_iid}.{bot_iid}.{channel_id}.msg.send")
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct EvChannelPairUpdate {
    pub bot_iid: i64,
    pub channel_id: String,
    pub owner_iid: i64,
    pub status: String,
    pub qr_raw: String,
    pub error_message: String,
    pub phone_jid: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ActChannelWhatsappPair {
    pub bot_iid: i64,
    pub channel_id: String,
    pub owner_iid: i64,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct EvChannelAttachment {
    pub hash: String,
    pub name: String,
    pub mime: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct EvChannelMsgIn {
    pub bot_iid: i64,
    pub channel_id: String,
    pub channel_type: String,
    pub owner_iid: i64,
    pub peer_id: String,
    pub peer_username: Option<String>,
    pub peer_name: Option<String>,
    pub msg_id: String,
    pub text: String,
    pub timestamp: i64,
    #[serde(default)]
    pub attachments: Vec<EvChannelAttachment>,
    #[serde(default)]
    pub is_voice: bool,
    #[serde(default)]
    pub quoted_msg_id: String,
    #[serde(default)]
    pub quoted_text: String,
    #[serde(default)]
    pub peer_avatar_hash: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ActChannelMediaItem {
    pub kind: String,
    pub hash: String,
    pub mime: String,
    pub name: String,
    pub caption: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ActChannelMsgSend {
    pub bot_iid: i64,
    pub channel_id: String,
    pub recipient_id: String,
    pub text: String,
    pub op_id: Option<String>,
    #[serde(default)]
    pub media: Vec<ActChannelMediaItem>,
    #[serde(default)]
    pub speak: bool,
    #[serde(default)]
    pub stream_part: bool,
    #[serde(default)]
    pub quote_msg_id: String,
    #[serde(default)]
    pub quote_text: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ActChannelMsgTyping {
    pub bot_iid: i64,
    pub channel_id: String,
    pub recipient_id: String,
    pub active: bool,
    #[serde(default)]
    pub speak: bool,
}

#[derive(Clone)]
pub struct NatsService {
    client: NatsClient,
}

impl NatsService {
    pub async fn connect(url: &str, user: Option<&str>, pass: Option<&str>, ca: Option<&str>) -> Result<Self> {
        let mut opts = async_nats::ConnectOptions::new();
        if let (Some(u), Some(p)) = (user, pass) {
            opts = opts.user_and_password(u.to_string(), p.to_string());
        }
        if let Some(path) = ca {
            if std::path::Path::new(path).exists() {
                opts = opts.add_root_certificates(std::path::PathBuf::from(path));
            }
        }
        let client = opts.connect(url).await.with_context(|| format!("NATS connect failed: {url}"))?;
        info!("[wa-device] NATS connected url={url}");
        Ok(Self { client })
    }

    pub fn client(&self) -> &NatsClient {
        &self.client
    }

    pub async fn publish_msg_in(&self, ev: &EvChannelMsgIn) -> Result<()> {
        let subject = msg_in_subject(ev.owner_iid, ev.bot_iid, &ev.channel_id);
        let payload = serde_json::to_vec(ev)?;
        debug!("[wa-device] NATS publish subject={subject} bytes={}", payload.len());
        self.client.publish(subject, bytes::Bytes::from(payload)).await?;
        Ok(())
    }

    pub async fn publish_pair_update(&self, ev: &EvChannelPairUpdate) -> Result<()> {
        let subject = pair_ev_subject(ev.owner_iid, ev.bot_iid, &ev.channel_id);
        let payload = serde_json::to_vec(ev)?;
        self.client.publish(subject, bytes::Bytes::from(payload)).await?;
        Ok(())
    }
}
