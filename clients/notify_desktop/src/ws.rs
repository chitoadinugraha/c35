use std::sync::Arc;
use std::time::Duration;

use anyhow::Context;
use c35_proto::{
    pb_decode, pb_encode, ws_req, ws_res, NotifyPush, ReqAppPresence, WsReq, WsRes,
};
use futures_util::{SinkExt, StreamExt};
use tokio_tungstenite::connect_async;
use tokio_tungstenite::tungstenite::Message;
use tracing::{info, warn};

use crate::config::{api_base, client_id, ws_url};
use crate::state::AppState;
use crate::toast;

pub async fn ws_run_loop(state: Arc<AppState>) {
    let mut jwt_rx = state.jwt_watch();
    let mut backoff = Duration::from_secs(2);
    loop {
        let jwt = jwt_rx.borrow_and_update().clone();
        let jwt = match jwt {
            Some(j) => j,
            None => {
                info!("ws idle: no JWT (set C35_NOTIFY_JWT, jwt file, or IPC set_jwt)");
                if jwt_rx.changed().await.is_err() {
                    break;
                }
                continue;
            }
        };

        match ws_session(&state, &jwt).await {
            Ok(()) => backoff = Duration::from_secs(2),
            Err(e) => {
                warn!("ws session ended: {e:#}");
                tokio::time::sleep(backoff).await;
                backoff = (backoff * 2).min(Duration::from_secs(60));
            }
        }

        if jwt_rx.changed().await.is_err() {
            break;
        }
    }
}

async fn ws_session(state: &Arc<AppState>, jwt: &str) -> anyhow::Result<()> {
    let url = ws_url(&api_base(), jwt);
    info!(url = %redact_jwt_url(&url), "ws connecting");
    let (ws, _) = connect_async(&url).await.context("connect /v1/ws")?;
    let (mut write, mut read) = ws.split();
    info!("ws connected");

    let client_id = client_id();
    let mut presence = tokio::time::interval(Duration::from_secs(20));
    presence.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Delay);
    presence.tick().await;

    let mut jwt_rx = state.jwt_watch();
    loop {
        tokio::select! {
            _ = presence.tick() => {
                let resumed = state.resumed();
                let req = WsReq {
                    req_id: uuid::Uuid::new_v4().to_string(),
                    body: Some(ws_req::Body::AppPresence(ReqAppPresence {
                        client_id: client_id.clone(),
                        resumed,
                    })),
                };
                if write.send(Message::Binary(pb_encode(&req))).await.is_err() {
                    break;
                }
                tracing::trace!(client_id = %client_id, resumed, "app presence heartbeat");
            }
            changed = jwt_rx.changed() => {
                if changed.is_ok() {
                    let new = jwt_rx.borrow().clone();
                    if new.as_deref() != Some(jwt) {
                        info!("jwt changed; reconnecting ws");
                        return Ok(());
                    }
                }
            }
            incoming = read.next() => {
                match incoming {
                    Some(Ok(Message::Binary(data))) => {
                        if let Err(e) = handle_ws_frame(state, &data) {
                            warn!("ws frame: {e:#}");
                        }
                    }
                    Some(Ok(Message::Ping(p))) => {
                        if write.send(Message::Pong(p)).await.is_err() {
                            break;
                        }
                    }
                    Some(Ok(Message::Pong(_))) => {}
                    Some(Ok(Message::Close(_))) => break,
                    Some(Ok(_)) => {}
                    Some(Err(e)) => {
                        warn!("ws read error: {e}");
                        break;
                    }
                    None => break,
                }
            }
        }
    }
    Ok(())
}

fn handle_ws_frame(state: &Arc<AppState>, data: &[u8]) -> anyhow::Result<()> {
    let res = pb_decode::<WsRes>(data).context("decode WsRes")?;
    match res.body {
        Some(ws_res::Body::NotifyPush(push)) => on_notify_push(state, push),
        _ => Ok(()),
    }
}

fn on_notify_push(state: &Arc<AppState>, push: NotifyPush) -> anyhow::Result<()> {
    info!(id = push.id, title = %push.title, "NotifyPush");
    let show = state.resumed()
        || state
            .focused
            .load(std::sync::atomic::Ordering::Relaxed);
    if show {
        if let Err(e) = toast::show_toast(&push.title, &push.body) {
            warn!("toast failed: {e:#}");
        }
    } else {
        tracing::debug!("skip toast (not resumed/focused)");
    }

    let json = serde_json::json!({
        "id": push.id,
        "title": push.title,
        "body": push.body,
        "route_json": push.route_json,
    });
    let line = format!("notify_push {}", json);
    state.broadcast_ipc(line);
    Ok(())
}

fn redact_jwt_url(url: &str) -> String {
    if let Some(i) = url.find("jwt=") {
        let start = i + 4;
        let end = url[start..].find('&').map(|j| start + j).unwrap_or(url.len());
        let mut s = url.to_string();
        s.replace_range(start..end, "***");
        return s;
    }
    url.to_string()
}
