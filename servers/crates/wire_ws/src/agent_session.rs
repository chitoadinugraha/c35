use std::time::Duration;

use axum::body::Bytes;
use axum::extract::ws::{Message, WebSocket};
use c35_ctx::AppState;
use c35_mod_device::{
    agent_log_put, agent_presence_put, agent_session_resolve, remote_signaling_agent_frame,
    remote_signaling_agent_register, remote_signaling_agent_unregister, AgentVersionReport,
};
use futures_util::StreamExt;
use tokio::sync::mpsc;
use tracing::{info, warn};

pub async fn handle(
    mut socket: WebSocket,
    state: AppState,
    session_key: String,
    agent_build: i64,
    agent_version_name: String,
) {
    let session = match agent_session_resolve(&state.pool, &session_key).await {
        Ok(Some(s)) => s,
        Ok(None) => return,
        Err(e) => {
            warn!("agent_session_resolve: {e}");
            return;
        }
    };

    info!(
        device_iid = session.device_iid,
        owner_iid = session.owner_iid,
        name = %session.device_name,
        "agent ws connected"
    );

    let version = if agent_build > 0 {
        Some(AgentVersionReport {
            build: agent_build,
            version_name: agent_version_name,
        })
    } else {
        None
    };
    let _ = agent_presence_put(&state.pool, session.device_iid, true, version).await;
    let _ = agent_log_put(
        &state.pool,
        state.nats.as_ref(),
        session.device_iid,
        session.owner_iid,
        "conn",
        "agent.ws",
        "connected",
        None,
    )
    .await;

    let (agent_out_tx, mut agent_out_rx) = mpsc::unbounded_channel::<Vec<u8>>();
    remote_signaling_agent_register(session.device_iid, agent_out_tx.clone());

    if let Some(nats) = state.nats.as_ref() {
        let nats_sub = nats.clone();
        let device_iid = session.device_iid;
        let tx = agent_out_tx.clone();
        tokio::spawn(async move {
            let subject = format!("c35.signal.device.{device_iid}");
            if let Ok(mut sub) = nats_sub.subscribe(subject).await {
                while let Some(msg) = sub.next().await {
                    if tx.send(msg.payload.to_vec()).is_err() {
                        break;
                    }
                }
            }
        });

        let nats_release = nats.clone();
        let tx_release = agent_out_tx.clone();
        tokio::spawn(async move {
            let subject = "c35.release.remote-windows";
            if let Ok(mut sub) = nats_release.subscribe(subject.to_string()).await {
                while let Some(msg) = sub.next().await {
                    let notification = if msg.payload.is_empty() {
                        b"c35.release:remote-windows".to_vec()
                    } else {
                        msg.payload.to_vec()
                    };
                    if tx_release.send(notification).is_err() {
                        break;
                    }
                }
            }
        });
    }

    let mut ping = tokio::time::interval(Duration::from_secs(30));
    ping.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Delay);

    loop {
        tokio::select! {
            _ = ping.tick() => {
                if socket.send(Message::Ping(Bytes::new())).await.is_err() {
                    break;
                }
            }
            Some(frame) = agent_out_rx.recv() => {
                if socket.send(Message::Binary(frame.into())).await.is_err() {
                    break;
                }
            }
            incoming = socket.next() => {
                match incoming {
                    Some(Ok(Message::Binary(data))) => {
                        if let Err(e) = remote_signaling_agent_frame(state.nats.as_ref(), session.device_iid, &data).await {
                            warn!(device_iid = session.device_iid, "agent signaling frame: {e}");
                        }
                    }
                    Some(Ok(Message::Ping(p))) => {
                        if socket.send(Message::Pong(p)).await.is_err() {
                            break;
                        }
                    }
                    Some(Ok(Message::Pong(_))) => {}
                    Some(Ok(Message::Close(_))) | None => break,
                    Some(Err(e)) => {
                        warn!("agent ws read error: {e}");
                        break;
                    }
                    _ => {}
                }
            }
        }
    }

    remote_signaling_agent_unregister(session.device_iid);

    let _ = agent_presence_put(&state.pool, session.device_iid, false, None).await;
    let _ = agent_log_put(
        &state.pool,
        state.nats.as_ref(),
        session.device_iid,
        session.owner_iid,
        "conn",
        "agent.ws",
        "disconnected",
        None,
    )
    .await;
    info!(device_iid = session.device_iid, "agent ws disconnected");
}
