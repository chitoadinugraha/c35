use std::time::Duration;

use axum::body::Bytes;
use axum::extract::ws::{Message, WebSocket};
use c35_ctx::AppState;
use c35_mod_device::{
    agent_log_put, agent_presence_heartbeat, agent_presence_put, agent_session_resolve,
    device_release_platform_key, release_config_get, release_needs_update,
    remote_signaling_agent_frame, remote_signaling_agent_register, remote_signaling_agent_unregister,
    remote_signaling_agent_connected, AgentVersionReport,
};
use serde_json::Value;
use futures_util::StreamExt;
use tokio::sync::mpsc;
use tracing::{info, warn};

const RELEASE_NUDGE_PAYLOAD: &[u8] = b"c35.release:remote-windows";
const REMOTE_ANDROID_NUDGE_PAYLOAD: &[u8] = b"c35.release:remote-android";
const REMOTE_BROWSER_NUDGE_PAYLOAD: &[u8] = b"c35.release:remote-browser";
const CHROME_EXTENSION_NUDGE_PAYLOAD: &[u8] = b"c35.release:chrome-extension";
const FFMPEG_RELEASE_NUDGE_PAYLOAD: &[u8] = b"c35.release:ffmpeg-windows";
const RELEASE_NUDGE_INTERVAL: Duration = Duration::from_secs(90);

async fn remote_device_type_meta(pool: &sqlx::PgPool, device_iid: i64) -> (String, Value) {
    let row = sqlx::query_as::<_, (String, Value)>(
        r#"
        SELECT type, COALESCE(meta, '{}'::jsonb)
        FROM ai.identity
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(device_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();
    row.unwrap_or_else(|| (String::new(), Value::Object(Default::default())))
}

fn release_nudge_payload(platform: &str) -> &'static [u8] {
    match platform {
        "chrome-extension" => CHROME_EXTENSION_NUDGE_PAYLOAD,
        "remote-browser" => REMOTE_BROWSER_NUDGE_PAYLOAD,
        "remote-android" => REMOTE_ANDROID_NUDGE_PAYLOAD,
        _ => RELEASE_NUDGE_PAYLOAD,
    }
}

fn release_nats_subject(platform: &str) -> &'static str {
    match platform {
        "chrome-extension" => "c35.release.chrome-extension",
        "remote-browser" => "c35.release.remote-browser",
        "remote-android" => "c35.release.remote-android",
        _ => "c35.release.remote-windows",
    }
}

fn spawn_release_nudge_loop(
    pool: sqlx::PgPool,
    agent_build: i64,
    platform: &'static str,
    nudge_payload: &'static [u8],
    tx: mpsc::UnboundedSender<Vec<u8>>,
) {
    if agent_build <= 0 {
        return;
    }
    tokio::spawn(async move {
        loop {
            let needs = match release_config_get(&pool, platform).await {
                Ok(Some(rel)) => release_needs_update(agent_build, &rel),
                _ => false,
            };
            if !needs {
                break;
            }
            if tx.send(nudge_payload.to_vec()).is_err() {
                break;
            }
            tokio::time::sleep(RELEASE_NUDGE_INTERVAL).await;
        }
    });
}

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
    let _ = agent_presence_put(
        &state.pool,
        state.nats.as_ref(),
        session.device_iid,
        true,
        version,
    )
    .await;
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
    let agent_conn_id =
        remote_signaling_agent_register(session.device_iid, agent_out_tx.clone());

    let (device_type, device_meta) =
        remote_device_type_meta(&state.pool, session.device_iid).await;
    let release_platform = device_release_platform_key(&device_type, &device_meta);
    let nudge_payload = release_nudge_payload(release_platform);
    spawn_release_nudge_loop(
        state.pool.clone(),
        agent_build,
        release_platform,
        nudge_payload,
        agent_out_tx.clone(),
    );

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
        let subject = release_nats_subject(release_platform);
        let default_nudge = nudge_payload;
        tokio::spawn(async move {
            if let Ok(mut sub) = nats_release.subscribe(subject.to_string()).await {
                while let Some(msg) = sub.next().await {
                    let notification = if msg.payload.is_empty() {
                        default_nudge.to_vec()
                    } else {
                        msg.payload.to_vec()
                    };
                    if tx_release.send(notification).is_err() {
                        break;
                    }
                }
            }
        });

        let nats_drive = nats.clone();
        let tx_drive = agent_out_tx.clone();
        let owner_iid = session.owner_iid;
        tokio::spawn(async move {
            let subject = format!("c35.user.{owner_iid}.drive-sync");
            if let Ok(mut sub) = nats_drive.subscribe(subject).await {
                while let Some(msg) = sub.next().await {
                    if tx_drive.send(msg.payload.to_vec()).is_err() {
                        break;
                    }
                }
            }
        });

        let nats_ffmpeg = nats.clone();
        let tx_ffmpeg = agent_out_tx.clone();
        tokio::spawn(async move {
            let subject = "c35.release.ffmpeg-windows";
            if let Ok(mut sub) = nats_ffmpeg.subscribe(subject.to_string()).await {
                while let Some(msg) = sub.next().await {
                    let notification = if msg.payload.is_empty() {
                        FFMPEG_RELEASE_NUDGE_PAYLOAD.to_vec()
                    } else {
                        msg.payload.to_vec()
                    };
                    if tx_ffmpeg.send(notification).is_err() {
                        break;
                    }
                }
            }
        });
    }

    let mut ping = tokio::time::interval(Duration::from_secs(30));
    ping.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Delay);
    let mut presence_db_tick = 0u32;
    const PRESENCE_DB_EVERY_N_PINGS: u32 = 2;

    loop {
        tokio::select! {
            _ = ping.tick() => {
                if socket.send(Message::Ping(Bytes::new())).await.is_err() {
                    break;
                }
                presence_db_tick += 1;
                let persist_db = presence_db_tick >= PRESENCE_DB_EVERY_N_PINGS;
                if persist_db {
                    presence_db_tick = 0;
                }
                let _ = agent_presence_heartbeat(
                    &state.pool,
                    state.nats.as_ref(),
                    session.device_iid,
                    session.owner_iid,
                    persist_db,
                )
                .await;
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

    remote_signaling_agent_unregister(session.device_iid, agent_conn_id);
    if remote_signaling_agent_connected(session.device_iid) {
        info!(
            device_iid = session.device_iid,
            "agent ws closed; newer control socket still registered"
        );
        return;
    }

    let _ = agent_presence_put(
        &state.pool,
        state.nats.as_ref(),
        session.device_iid,
        false,
        None,
    )
    .await;
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
