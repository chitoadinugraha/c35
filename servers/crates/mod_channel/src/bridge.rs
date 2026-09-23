use std::sync::Arc;

use anyhow::Result;
use c35_ctx::AppState;
use futures_util::StreamExt;
use serde::{Deserialize, Serialize};
use tracing::{error, info, warn};

use crate::inbound::channel_inbound_handle;
use crate::store::{bot_channel_get, STATUS_CONNECTED};
use crate::types::{ChannelInboundAttachment, ChannelInboundMessage};

pub const SUBJ_MSG_IN_WILDCARD: &str = "c35.ev.channel.*.*.*.msg.in";

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

pub fn ev_msg_in_to_channel_inbound(ev: &EvChannelMsgIn) -> ChannelInboundMessage {
    let display_name = ev
        .peer_name
        .as_deref()
        .filter(|s| !s.is_empty())
        .or(ev.peer_username.as_deref().filter(|s| !s.is_empty()))
        .unwrap_or(&ev.peer_id)
        .to_string();
    ChannelInboundMessage {
        platform: "whatsapp".to_string(),
        external_user_id: ev.peer_id.clone(),
        display_name,
        text: ev.text.clone(),
        external_msg_id: (!ev.msg_id.is_empty()).then_some(ev.msg_id.clone()),
        attachments: ev
            .attachments
            .iter()
            .map(|a| ChannelInboundAttachment {
                hash: a.hash.clone(),
                name: a.name.clone(),
                mime: a.mime.clone(),
                media_id: String::new(),
                url: String::new(),
            })
            .collect(),
        is_voice: ev.is_voice,
        quoted_msg_id: ev.quoted_msg_id.clone(),
        quoted_text: ev.quoted_text.clone(),
        avatar_hash: ev.peer_avatar_hash.clone(),
        platform_user_id: ev.peer_username.clone().unwrap_or_default(),
    }
}

pub async fn start_channel_inbound_subscriber(state: Arc<AppState>) {
    let nats = match state.nats.clone() {
        Some(c) => c,
        None => {
            warn!("[c35:channel] NATS unavailable, inbound subscriber disabled");
            return;
        }
    };
    let mut sub = match nats
        .queue_subscribe(
            SUBJ_MSG_IN_WILDCARD.to_string(),
            "c35-server-channel-inbound".to_string(),
        )
        .await
    {
        Ok(s) => s,
        Err(e) => {
            warn!("[c35:channel] NATS queue_subscribe {SUBJ_MSG_IN_WILDCARD}: {e}");
            return;
        }
    };
    info!("[c35:channel] NATS queue_subscribed subject={SUBJ_MSG_IN_WILDCARD} queue=c35-server-channel-inbound");

    while let Some(msg) = sub.next().await {
        let ev = match serde_json::from_slice::<EvChannelMsgIn>(&msg.payload) {
            Ok(v) => v,
            Err(e) => {
                warn!(
                    "[c35:channel] invalid msg.in payload subject={}: {e}",
                    msg.subject
                );
                continue;
            }
        };
        let state = state.clone();
        tokio::spawn(async move {
            if let Err(e) = handle_ev_channel_msg_in(&state, ev).await {
                error!("[c35:channel] inbound handle failed: {e:#}");
            }
        });
    }
}

async fn handle_ev_channel_msg_in(state: &AppState, ev: EvChannelMsgIn) -> Result<()> {
    let channel = bot_channel_get(&state.pool, ev.bot_iid, &ev.channel_id).await?;
    let channel = match channel {
        Some(c) => c,
        None => return Ok(()),
    };
    if channel.status != STATUS_CONNECTED {
        return Ok(());
    }
    let inbound = ev_msg_in_to_channel_inbound(&ev);
    channel_inbound_handle(state, ev.bot_iid, &channel, &inbound).await?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ev_msg_in_deserializes_and_maps_to_channel_inbound() {
        let json = r#"{
            "bot_iid": 1001,
            "channel_id": "ch-abc",
            "channel_type": "whatsapp",
            "owner_iid": 2002,
            "peer_id": "628123456789@s.whatsapp.net",
            "peer_username": "628123456789@s.whatsapp.net",
            "peer_name": "Budi",
            "msg_id": "msg-xyz",
            "text": "hello",
            "timestamp": 1700000000,
            "attachments": [{"hash": "abc123", "name": "photo.jpg", "mime": "image/jpeg"}],
            "is_voice": false,
            "quoted_msg_id": "q1",
            "quoted_text": "prev",
            "peer_avatar_hash": "av1"
        }"#;
        let ev: EvChannelMsgIn = serde_json::from_str(json).expect("deserialize");
        assert_eq!(ev.bot_iid, 1001);
        assert_eq!(ev.channel_id, "ch-abc");
        assert_eq!(ev.attachments.len(), 1);
        assert_eq!(ev.attachments[0].hash, "abc123");

        let inbound = ev_msg_in_to_channel_inbound(&ev);
        assert_eq!(inbound.platform, "whatsapp");
        assert_eq!(inbound.external_user_id, "628123456789@s.whatsapp.net");
        assert_eq!(inbound.display_name, "Budi");
        assert_eq!(inbound.text, "hello");
        assert_eq!(inbound.external_msg_id.as_deref(), Some("msg-xyz"));
        assert_eq!(inbound.attachments.len(), 1);
        assert_eq!(inbound.attachments[0].hash, "abc123");
        assert_eq!(inbound.attachments[0].name, "photo.jpg");
        assert_eq!(inbound.attachments[0].mime, "image/jpeg");
        assert!(inbound.attachments[0].media_id.is_empty());
        assert!(!inbound.is_voice);
        assert_eq!(inbound.quoted_msg_id, "q1");
        assert_eq!(inbound.quoted_text, "prev");
        assert_eq!(inbound.avatar_hash, "av1");
        assert_eq!(inbound.platform_user_id, "628123456789@s.whatsapp.net");
    }
}
