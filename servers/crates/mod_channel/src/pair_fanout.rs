use c35_proto::{ChannelPairPush, WsRes, ws_res};
use futures_util::StreamExt;
use serde::Deserialize;
use sqlx::PgPool;
use tokio::sync::mpsc;
use tracing::warn;

use crate::store::{bot_channel_apply_pair_update, phone_jid_display};

#[derive(Clone, Debug, Deserialize)]
pub struct EvChannelPairUpdate {
    pub bot_iid: i64,
    pub channel_id: String,
    pub owner_iid: i64,
    pub status: String,
    pub qr_raw: String,
    pub error_message: String,
    pub phone_jid: String,
}

pub async fn channel_pair_nats_fanout(
    pool: PgPool,
    nats: async_nats::Client,
    owner_iid: i64,
    out_tx: mpsc::UnboundedSender<WsRes>,
) {
    let subject = format!("c35.ev.channel.{owner_iid}.>");
    let mut sub = match nats.subscribe(subject).await {
        Ok(s) => s,
        Err(e) => {
            warn!("[c35:channel] pair nats subscribe: {e}");
            return;
        }
    };
    while let Some(msg) = sub.next().await {
        if !msg.subject.as_str().ends_with(".pair") {
            continue;
        }
        let ev = match serde_json::from_slice::<EvChannelPairUpdate>(&msg.payload) {
            Ok(v) => v,
            Err(e) => {
                warn!("[c35:channel] invalid pair ev payload: {e}");
                continue;
            }
        };
        if ev.owner_iid != owner_iid {
            continue;
        }
        let _ = bot_channel_apply_pair_update(
            &pool,
            owner_iid,
            ev.bot_iid,
            &ev.channel_id,
            &ev.status,
            &ev.qr_raw,
            &ev.error_message,
            &ev.phone_jid,
        )
        .await;
        let phone = phone_jid_display(&ev.phone_jid);
        let push = ChannelPairPush {
            bot_iid: ev.bot_iid,
            channel_id: ev.channel_id,
            status: ev.status,
            qr_raw: ev.qr_raw,
            phone,
            error_message: ev.error_message,
        };
        let _ = out_tx.send(WsRes {
            req_id: String::new(),
            body: Some(ws_res::Body::ChannelPairPush(push)),
        });
    }
}
