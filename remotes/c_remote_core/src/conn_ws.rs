use std::sync::Arc;
use std::time::Duration;

use futures_util::{SinkExt, StreamExt};
use tokio_tungstenite::connect_async;
use tokio_tungstenite::tungstenite::Message;
use tracing::{info, warn};

use crate::log_push;
use crate::webrtc::WebrtcHub;

pub fn is_invalid_session(err: &anyhow::Error) -> bool {
    let msg = err.to_string().to_ascii_lowercase();
    msg.contains("401") || msg.contains("unauthorized") || msg.contains("invalid session")
}

pub fn agent_ws_url(server_url: &str, session_key: &str) -> String {
    let base = server_url.trim_end_matches('/');
    let ws_base = if base.starts_with("https://") {
        format!("wss://{}", base.trim_start_matches("https://"))
    } else if base.starts_with("http://") {
        format!("ws://{}", base.trim_start_matches("http://"))
    } else {
        format!("wss://{}", base.trim_start_matches('/'))
    };
    format!(
        "{}/v1/agent/ws?session_key={}",
        ws_base,
        urlencoding::encode(session_key)
    )
}

pub async fn conn_ws_run(
    server_url: &str,
    session_key: &str,
    device_iid: i64,
) -> anyhow::Result<()> {
    let url = agent_ws_url(server_url, session_key);
    info!(device_iid, url = %url, "connecting agent ws");

    let (ws, _) = connect_async(&url).await?;
    let (mut write, mut read) = ws.split();

    let (out_tx, mut out_rx) = tokio::sync::mpsc::unbounded_channel::<Vec<u8>>();
    let dispatch_ctx = Arc::new(crate::skill_dispatch::DispatchCtx {
        server_url: server_url.to_string(),
        session_key: session_key.to_string(),
        device_iid,
        skill_store: crate::skill_store::new_store(),
    });
    let webrtc = WebrtcHub::new(device_iid, out_tx, dispatch_ctx);

    log_push::log_push(
        server_url,
        session_key,
        "conn",
        "agent.ws",
        "connected",
        Some(serde_json::json!({ "device_iid": device_iid })),
    )
    .await;

    let mut ping = tokio::time::interval(Duration::from_secs(30));
    ping.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Delay);

    loop {
        tokio::select! {
            _ = ping.tick() => {
                if write.send(Message::Ping(vec![])).await.is_err() {
                    break;
                }
            }
            Some(frame) = out_rx.recv() => {
                if write.send(Message::Binary(frame)).await.is_err() {
                    break;
                }
            }
            incoming = read.next() => {
                match incoming {
                    Some(Ok(Message::Ping(p))) => {
                        if write.send(Message::Pong(p)).await.is_err() {
                            break;
                        }
                    }
                    Some(Ok(Message::Pong(_))) => {}
                    Some(Ok(Message::Binary(data))) => {
                        webrtc.handle_frame(&data).await;
                    }
                    Some(Ok(Message::Close(frame))) => {
                        info!(?frame, "agent ws closed by server");
                        break;
                    }
                    Some(Ok(_)) => {}
                    Some(Err(e)) => {
                        warn!("agent ws read error: {e}");
                        break;
                    }
                    None => break,
                }
            }
        }
    }

    log_push::log_push(
        server_url,
        session_key,
        "conn",
        "agent.ws",
        "disconnected",
        Some(serde_json::json!({ "device_iid": device_iid })),
    )
    .await;

    Ok(())
}

pub async fn conn_ws_run_reconnect(
    server_url: &str,
    session_key: &str,
    device_iid: i64,
) -> anyhow::Result<()> {
    let mut backoff = Duration::from_secs(2);
    loop {
        match conn_ws_run(server_url, session_key, device_iid).await {
            Ok(()) => backoff = Duration::from_secs(2),
            Err(e) if is_invalid_session(&e) => return Err(e),
            Err(e) => {
                warn!("agent ws error: {e}; retry in {backoff:?}");
                log_push::log_push(
                    server_url,
                    session_key,
                    "error",
                    "agent.ws",
                    &e.to_string(),
                    Some(serde_json::json!({ "device_iid": device_iid })),
                )
                .await;
                tokio::time::sleep(backoff).await;
                backoff = (backoff * 2).min(Duration::from_secs(60));
            }
        }
    }
}
