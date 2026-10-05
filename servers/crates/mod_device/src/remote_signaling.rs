//! WebRTC signaling relay — app WS ↔ agent WS (SDP/ICE only; no media).
//!
//! v1: in-memory session map on this pod. Multi-pod requires sticky sessions or
//! a shared registry (not implemented).

use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, OnceLock};

use c35_proto::{
    pb_decode, pb_encode, ActDeviceTaskRun, RemoteConnectionMode, RemoteFsListRes, RemoteFsReadRes,
    RemoteSessionPush, ReqRemoteCommand, ReqRemoteFsList, ReqRemoteFsRead, ReqRemoteScreenshot,
    ReqRemoteSessionStart, ReqRemoteSessionStop, ResRemoteCommand, ResRemoteScreenshot,
    ResRemoteSessionStart, ResRemoteSessionStop, RtcSignalAnswer, RtcSignalIce, RtcSignalOffer,
    WsReq, WsRes, ws_req, ws_res,
};
use serde_json::Value;
use dashmap::DashMap;
use sqlx::PgPool;
use tokio::sync::mpsc;

use crate::agent_meta_get;

static HUB: OnceLock<Arc<RemoteSignalingHub>> = OnceLock::new();
static APP_CONN_SEQ: AtomicU64 = AtomicU64::new(1);
static PENDING_SCREENSHOTS: OnceLock<DashMap<String, tokio::sync::oneshot::Sender<ResRemoteScreenshot>>> = OnceLock::new();
static PENDING_COMMANDS: OnceLock<DashMap<String, tokio::sync::oneshot::Sender<ResRemoteCommand>>> = OnceLock::new();
static PENDING_FS_LIST: OnceLock<DashMap<String, tokio::sync::oneshot::Sender<RemoteFsListRes>>> =
    OnceLock::new();
static PENDING_FS_READ: OnceLock<DashMap<String, tokio::sync::oneshot::Sender<RemoteFsReadRes>>> =
    OnceLock::new();

const FS_READ_LLM_MAX: i32 = 256 * 1024;
const FS_RPC_TIMEOUT_SEC: u64 = 30;

fn hub() -> Arc<RemoteSignalingHub> {
    HUB.get_or_init(|| Arc::new(RemoteSignalingHub::default())).clone()
}

fn pending_screenshots() -> &'static DashMap<String, tokio::sync::oneshot::Sender<ResRemoteScreenshot>> {
    PENDING_SCREENSHOTS.get_or_init(DashMap::new)
}

fn pending_commands() -> &'static DashMap<String, tokio::sync::oneshot::Sender<ResRemoteCommand>> {
    PENDING_COMMANDS.get_or_init(DashMap::new)
}

fn pending_fs_list() -> &'static DashMap<String, tokio::sync::oneshot::Sender<RemoteFsListRes>> {
    PENDING_FS_LIST.get_or_init(DashMap::new)
}

fn pending_fs_read() -> &'static DashMap<String, tokio::sync::oneshot::Sender<RemoteFsReadRes>> {
    PENDING_FS_READ.get_or_init(DashMap::new)
}

#[derive(Clone)]
struct RemoteSessionEntry {
    owner_iid: i64,
    app_conn_id: u64,
    app_tx: mpsc::UnboundedSender<WsRes>,
}

#[derive(Clone)]
struct AgentRoute {
    out_tx: mpsc::UnboundedSender<Vec<u8>>,
}

#[derive(Default)]
pub struct RemoteSignalingHub {
    sessions: DashMap<(i64, String), RemoteSessionEntry>,
    agents: DashMap<i64, AgentRoute>,
    app_conns: DashMap<u64, mpsc::UnboundedSender<WsRes>>,
}


pub fn remote_signaling_app_conn_register(app_tx: mpsc::UnboundedSender<WsRes>) -> u64 {
    let id = APP_CONN_SEQ.fetch_add(1, Ordering::Relaxed);
    hub().app_conns.insert(id, app_tx);
    id
}

pub fn remote_signaling_app_conn_unregister(app_conn_id: u64) {
    let h = hub();
    h.sessions.retain(|_, entry| entry.app_conn_id != app_conn_id);
    h.app_conns.remove(&app_conn_id);
}

pub fn remote_signaling_agent_register(
    device_iid: i64,
    out_tx: mpsc::UnboundedSender<Vec<u8>>,
) {
    hub().agents.insert(device_iid, AgentRoute { out_tx });
}

pub fn remote_signaling_agent_unregister(device_iid: i64) {
    hub().agents.remove(&device_iid);
}

pub fn remote_signaling_agent_connected(device_iid: i64) -> bool {
    hub().agents.contains_key(&device_iid)
}

async fn device_root_remote_audit(
    pool: &PgPool,
    caller_iid: i64,
    device_iid: i64,
    device_owner_iid: i64,
) {
    let meta = serde_json::json!({
        "action": "root_device_remote",
        "caller_iid": caller_iid,
        "device_iid": device_iid,
        "device_owner_iid": device_owner_iid,
    });
    let text = format!(
        "root remote access device_iid={} owner_iid={}",
        device_iid,
        device_owner_iid
    );
    let _ = c35_mod_log::log_put(
        pool,
        None,
        c35_mod_log::LogPut {
            owner_iid: caller_iid,
            class: Some("event"),
            kind: "admin",
            topic: "device.remote",
            dv: "",
            req_id: None,
            chat_id: None,
            task_id: None,
            device_iid: Some(device_iid),
            text: &text,
            model: "",
            tokens_in: 0,
            tokens_out: 0,
            duration_ms: 0,
            cost_usd: 0.0,
            meta,
        },
    )
    .await;
}

async fn device_remote_allowed(pool: &PgPool, caller_iid: i64, device_iid: i64) -> Result<(), String> {
    if device_iid <= 0 {
        return Err("invalid device".into());
    }
    if c35_mod_admin::require_root(pool, caller_iid).await.is_ok() {
        let owner: Option<i64> = sqlx::query_scalar(
            r#"
            SELECT owner_iid
            FROM ai.identity
            WHERE id = $1 AND kind = 'remote' AND deleted_ts IS NULL
            LIMIT 1
            "#,
        )
        .bind(device_iid)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
        if let Some(device_owner_iid) = owner {
            device_root_remote_audit(pool, caller_iid, device_iid, device_owner_iid).await;
            return Ok(());
        }
        return Err("invalid device".into());
    }
    let row = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT i.id
        FROM ai.identity i
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $2 AND g.deleted_ts IS NULL
        WHERE i.id = $1
          AND i.kind = 'remote'
          AND i.deleted_ts IS NULL
          AND (i.owner_iid = $2 OR g.grantee_iid = $2)
        LIMIT 1
        "#,
    )
    .bind(device_iid)
    .bind(caller_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    if row.is_some() {
        Ok(())
    } else {
        Err("forbidden".into())
    }
}

async fn agent_cluster_online(pool: &PgPool, device_iid: i64) -> Result<bool, String> {
    if remote_signaling_agent_connected(device_iid) {
        return Ok(true);
    }
    let meta = agent_meta_get(pool, device_iid).await?;
    Ok(meta
        .get("online")
        .and_then(|v| v.as_bool())
        .unwrap_or(false))
}

fn agent_send(device_iid: i64, frame: WsReq) -> Result<(), String> {
    let bytes = pb_encode(&frame);
    hub()
        .agents
        .get(&device_iid)
        .ok_or_else(|| "agent not connected to this server".to_string())?
        .out_tx
        .send(bytes)
        .map_err(|_| "agent disconnected".to_string())
}

async fn agent_send_or_relay(
    nats: Option<&async_nats::Client>,
    device_iid: i64,
    frame: WsReq,
) -> Result<(), String> {
    if agent_send(device_iid, frame.clone()).is_ok() {
        return Ok(());
    }
    if let Some(nats) = nats {
        let subject = format!("c35.signal.device.{device_iid}");
        let bytes = pb_encode(&frame);
        return nats
            .publish(subject, bytes.into())
            .await
            .map_err(|e| e.to_string());
    }
    Err("agent not connected to this server".into())
}

fn session_entry(
    device_iid: i64,
    session_id: &str,
    caller_iid: i64,
) -> Result<RemoteSessionEntry, String> {
    let key = (device_iid, session_id.to_string());
    let h = hub();
    let entry = h
        .sessions
        .get(&key)
        .ok_or_else(|| "session not found".to_string())?;
    if entry.owner_iid != caller_iid {
        return Err("forbidden".into());
    }
    Ok(entry.clone())
}

fn push_session(
    app_tx: &mpsc::UnboundedSender<WsRes>,
    device_iid: i64,
    session_id: &str,
    webrtc_connected: bool,
) {
    let _ = app_tx.send(WsRes {
        req_id: String::new(),
        body: Some(ws_res::Body::RemoteSessionPush(RemoteSessionPush {
            device_iid,
            session_id: session_id.to_string(),
            mode: RemoteConnectionMode::Unspecified as i32,
            selected_ice: 0,
            video_active: false,
            webrtc_connected,
            update_ready: false,
            update_version: 0,
        })),
    });
}

pub async fn remote_session_start(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    caller_iid: i64,
    app_conn_id: u64,
    app_tx: &mpsc::UnboundedSender<WsRes>,
    req: ReqRemoteSessionStart,
) -> ResRemoteSessionStart {
    let device_iid = req.device_iid;
    let session_id = req.session_id.trim().to_string();
    if session_id.is_empty() {
        return ResRemoteSessionStart {
            ok: false,
            error: "session_id required".into(),
            session_id: String::new(),
        };
    }

    if let Err(e) = device_remote_allowed(pool, caller_iid, device_iid).await {
        return ResRemoteSessionStart {
            ok: false,
            error: e,
            session_id: String::new(),
        };
    }

    match agent_cluster_online(pool, device_iid).await {
        Ok(true) => {}
        Ok(false) => {
            return ResRemoteSessionStart {
                ok: false,
                error: "agent offline".into(),
                session_id: String::new(),
            };
        }
        Err(e) => {
            return ResRemoteSessionStart {
                ok: false,
                error: e,
                session_id: String::new(),
            };
        }
    }

    if !remote_signaling_agent_connected(device_iid) && nats.is_none() {
        return ResRemoteSessionStart {
            ok: false,
            error: "agent not connected to this server".into(),
            session_id: String::new(),
        };
    }

    let key = (device_iid, session_id.clone());
    hub().sessions.insert(
        key.clone(),
        RemoteSessionEntry {
            owner_iid: caller_iid,
            app_conn_id,
            app_tx: app_tx.clone(),
        },
    );

    let agent_req = WsReq {
        req_id: String::new(),
        body: Some(ws_req::Body::RemoteSessionStart(ReqRemoteSessionStart {
            device_iid,
            session_id: session_id.clone(),
        })),
    };
    if let Err(e) = agent_send_or_relay(nats, device_iid, agent_req).await {
        hub().sessions.remove(&key);
        return ResRemoteSessionStart {
            ok: false,
            error: e,
            session_id: String::new(),
        };
    }

    if let Some(nats) = nats {
        let nats_sub = nats.clone();
        let sid = session_id.clone();
        let tx = app_tx.clone();
        tokio::spawn(async move {
            let subject = format!("c35.signal.session.{sid}");
            if let Ok(mut sub) = nats_sub.subscribe(subject).await {
                use futures_util::StreamExt;
                while let Some(msg) = sub.next().await {
                    if let Ok(res) = pb_decode::<WsRes>(&msg.payload) {
                        if tx.send(res).is_err() {
                            break;
                        }
                    }
                }
            }
        });
    }

    push_session(app_tx, device_iid, &session_id, false);

    ResRemoteSessionStart {
        ok: true,
        error: String::new(),
        session_id,
    }
}

pub async fn remote_session_stop(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    caller_iid: i64,
    req: ReqRemoteSessionStop,
) -> ResRemoteSessionStop {
    let device_iid = req.device_iid;
    let session_id = req.session_id.trim();
    if session_id.is_empty() {
        return ResRemoteSessionStop { ok: false };
    }

    if let Err(_) = device_remote_allowed(pool, caller_iid, device_iid).await {
        return ResRemoteSessionStop { ok: false };
    }

    let key = (device_iid, session_id.to_string());
    let entry = match hub().sessions.get(&key) {
        Some(e) if e.owner_iid == caller_iid => e.clone(),
        _ => return ResRemoteSessionStop { ok: false },
    };

    hub().sessions.remove(&key);

    let _ = agent_send_or_relay(
        nats,
        device_iid,
        WsReq {
            req_id: String::new(),
            body: Some(ws_req::Body::RemoteSessionStop(ReqRemoteSessionStop {
                device_iid,
                session_id: session_id.to_string(),
            })),
        },
    ).await;

    push_session(&entry.app_tx, device_iid, session_id, false);

    ResRemoteSessionStop { ok: true }
}

pub async fn rtc_signal_offer_from_app(
    nats: Option<&async_nats::Client>,
    caller_iid: i64,
    offer: RtcSignalOffer,
) -> Result<(), String> {
    let device_iid = offer.device_iid;
    let session_id = offer.session_id.trim();
    if session_id.is_empty() {
        return Err("session_id required".into());
    }
    let _ = session_entry(device_iid, session_id, caller_iid);
    agent_send_or_relay(
        nats,
        device_iid,
        WsReq {
            req_id: String::new(),
            body: Some(ws_req::Body::RtcSignalOffer(offer)),
        },
    ).await
}

pub async fn rtc_signal_answer_from_app(
    nats: Option<&async_nats::Client>,
    caller_iid: i64,
    answer: RtcSignalAnswer,
) -> Result<(), String> {
    let device_iid = answer.device_iid;
    let session_id = answer.session_id.trim();
    if session_id.is_empty() {
        return Err("session_id required".into());
    }
    let _ = session_entry(device_iid, session_id, caller_iid);
    agent_send_or_relay(
        nats,
        device_iid,
        WsReq {
            req_id: String::new(),
            body: Some(ws_req::Body::RtcSignalAnswer(answer)),
        },
    ).await
}

pub async fn rtc_signal_ice_from_app(
    nats: Option<&async_nats::Client>,
    caller_iid: i64,
    ice: RtcSignalIce,
) -> Result<(), String> {
    let device_iid = ice.device_iid;
    let session_id = ice.session_id.trim();
    if session_id.is_empty() {
        return Err("session_id required".into());
    }
    let _ = session_entry(device_iid, session_id, caller_iid);
    agent_send_or_relay(
        nats,
        device_iid,
        WsReq {
            req_id: String::new(),
            body: Some(ws_req::Body::RtcSignalIce(ice)),
        },
    ).await
}

fn forward_app(device_iid: i64, session_id: &str, body: ws_res::Body) -> Result<(), String> {
    let key = (device_iid, session_id.to_string());
    let h = hub();
    let entry = h
        .sessions
        .get(&key)
        .ok_or_else(|| "session not found".to_string())?;
    entry
        .app_tx
        .send(WsRes {
            req_id: String::new(),
            body: Some(body),
        })
        .map_err(|_| "app disconnected".to_string())
}

async fn forward_app_or_relay(
    nats: Option<&async_nats::Client>,
    device_iid: i64,
    session_id: &str,
    body: ws_res::Body,
) -> Result<(), String> {
    if forward_app(device_iid, session_id, body.clone()).is_ok() {
        return Ok(());
    }
    if let Some(nats) = nats {
        let subject = format!("c35.signal.session.{session_id}");
        let res = WsRes {
            req_id: String::new(),
            body: Some(body),
        };
        let bytes = pb_encode(&res);
        return nats
            .publish(subject, bytes.into())
            .await
            .map_err(|e| e.to_string());
    }
    Err("session not found".into())
}

pub async fn remote_signaling_agent_frame(
    nats: Option<&async_nats::Client>,
    device_iid: i64,
    data: &[u8],
) -> Result<(), String> {
    if let Ok(res) = pb_decode::<WsRes>(data) {
        return dispatch_agent_res(nats, device_iid, res).await;
    }
    if let Ok(req) = pb_decode::<WsReq>(data) {
        return dispatch_agent_req(nats, device_iid, req).await;
    }
    Err("invalid agent frame".into())
}

async fn dispatch_agent_res(
    nats: Option<&async_nats::Client>,
    device_iid: i64,
    res: WsRes,
) -> Result<(), String> {
    match res.body {
        Some(ws_res::Body::RtcSignalOffer(offer)) => {
            let sid = offer.session_id.clone();
            forward_app_or_relay(nats, device_iid, &sid, ws_res::Body::RtcSignalOffer(offer)).await
        }
        Some(ws_res::Body::RtcSignalAnswer(answer)) => {
            let sid = answer.session_id.clone();
            forward_app_or_relay(nats, device_iid, &sid, ws_res::Body::RtcSignalAnswer(answer)).await
        }
        Some(ws_res::Body::RtcSignalIce(ice)) => {
            let sid = ice.session_id.clone();
            forward_app_or_relay(nats, device_iid, &sid, ws_res::Body::RtcSignalIce(ice)).await
        }
        Some(ws_res::Body::RemoteSessionPush(push)) => {
            let sid = push.session_id.clone();
            forward_app_or_relay(nats, device_iid, &sid, ws_res::Body::RemoteSessionPush(push)).await
        }
        Some(ws_res::Body::ResRemoteScreenshot(screenshot)) => {
            let req_id = res.req_id.trim().to_string();
            if !req_id.is_empty() {
                if let Some((_, tx)) = pending_screenshots().remove(&req_id) {
                    let _ = tx.send(screenshot);
                    return Ok(());
                }
                if let Some(nats) = nats {
                    let subject = format!("c35.rpc.screenshot.{req_id}");
                    let relay_res = WsRes {
                        req_id,
                        body: Some(ws_res::Body::ResRemoteScreenshot(screenshot)),
                    };
                    let bytes = pb_encode(&relay_res);
                    let _ = nats.publish(subject, bytes.into()).await;
                    return Ok(());
                }
            }
            Ok(())
        }
        Some(ws_res::Body::ResRemoteCommand(cmd_res)) => {
            let req_id = res.req_id.trim().to_string();
            if !req_id.is_empty() {
                if let Some((_, tx)) = pending_commands().remove(&req_id) {
                    let _ = tx.send(cmd_res);
                    return Ok(());
                }
                if let Some(nats) = nats {
                    let subject = format!("c35.rpc.command.{req_id}");
                    let relay_res = WsRes {
                        req_id,
                        body: Some(ws_res::Body::ResRemoteCommand(cmd_res)),
                    };
                    let bytes = pb_encode(&relay_res);
                    let _ = nats.publish(subject, bytes.into()).await;
                    return Ok(());
                }
            }
            Ok(())
        }
        Some(ws_res::Body::ResRemoteFsList(fs_res)) => {
            let req_id = res.req_id.trim().to_string();
            if !req_id.is_empty() {
                if let Some((_, tx)) = pending_fs_list().remove(&req_id) {
                    let _ = tx.send(fs_res);
                    return Ok(());
                }
                if let Some(nats) = nats {
                    let subject = format!("c35.rpc.fs_list.{req_id}");
                    let relay_res = WsRes {
                        req_id,
                        body: Some(ws_res::Body::ResRemoteFsList(fs_res)),
                    };
                    let bytes = pb_encode(&relay_res);
                    let _ = nats.publish(subject, bytes.into()).await;
                    return Ok(());
                }
            }
            Ok(())
        }
        Some(ws_res::Body::ResRemoteFsRead(fs_res)) => {
            let req_id = res.req_id.trim().to_string();
            if !req_id.is_empty() {
                if let Some((_, tx)) = pending_fs_read().remove(&req_id) {
                    let _ = tx.send(fs_res);
                    return Ok(());
                }
                if let Some(nats) = nats {
                    let subject = format!("c35.rpc.fs_read.{req_id}");
                    let relay_res = WsRes {
                        req_id,
                        body: Some(ws_res::Body::ResRemoteFsRead(fs_res)),
                    };
                    let bytes = pb_encode(&relay_res);
                    let _ = nats.publish(subject, bytes.into()).await;
                    return Ok(());
                }
            }
            Ok(())
        }
        _ => Ok(()),
    }
}

async fn dispatch_agent_req(
    nats: Option<&async_nats::Client>,
    device_iid: i64,
    req: WsReq,
) -> Result<(), String> {
    match req.body {
        Some(ws_req::Body::RtcSignalOffer(offer)) => {
            let sid = offer.session_id.clone();
            forward_app_or_relay(nats, device_iid, &sid, ws_res::Body::RtcSignalOffer(offer)).await
        }
        Some(ws_req::Body::RtcSignalAnswer(answer)) => {
            let sid = answer.session_id.clone();
            forward_app_or_relay(nats, device_iid, &sid, ws_res::Body::RtcSignalAnswer(answer)).await
        }
        Some(ws_req::Body::RtcSignalIce(ice)) => {
            let sid = ice.session_id.clone();
            forward_app_or_relay(nats, device_iid, &sid, ws_res::Body::RtcSignalIce(ice)).await
        }
        Some(ws_req::Body::RemoteSessionStop(stop)) => {
            let key = (device_iid, stop.session_id.clone());
            if let Some(entry) = hub().sessions.remove(&key) {
                push_session(&entry.1.app_tx, device_iid, &stop.session_id, false);
            }
            Ok(())
        }
        _ => Ok(()),
    }
}

pub async fn remote_agent_send_raw(
    nats: Option<&async_nats::Client>,
    device_iid: i64,
    payload: Vec<u8>,
) -> Result<(), String> {
    if let Some(agent) = hub().agents.get(&device_iid) {
        if agent.out_tx.send(payload.clone()).is_ok() {
            return Ok(());
        }
    }
    if let Some(nats) = nats {
        let subject = format!("c35.signal.device.{device_iid}");
        nats.publish(subject, payload.into())
            .await
            .map_err(|e| e.to_string())?;
        return Ok(());
    }
    Err("agent offline or unreachable".into())
}

pub async fn remote_device_command_run(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    caller_iid: i64,
    device_iid: i64,
    command: &str,
    timeout_sec: u32,
) -> Result<ResRemoteCommand, String> {
    device_remote_allowed(pool, caller_iid, device_iid).await?;

    match agent_cluster_online(pool, device_iid).await {
        Ok(true) => {}
        Ok(false) => return Err("agent offline".into()),
        Err(e) => return Err(e),
    }

    let req_id = c35_store::snowflake_id().to_string();
    let (tx, rx) = tokio::sync::oneshot::channel();
    pending_commands().insert(req_id.clone(), tx);

    let req = WsReq {
        req_id: req_id.clone(),
        body: Some(ws_req::Body::ReqRemoteCommand(ReqRemoteCommand {
            device_iid,
            command: command.to_string(),
            timeout_sec,
        })),
    };

    let mut nats_sub = None;
    if let Some(nats) = nats {
        let subject = format!("c35.rpc.command.{req_id}");
        if let Ok(sub) = nats.subscribe(subject).await {
            nats_sub = Some(sub);
        }
    }

    if let Err(e) = remote_agent_send_raw(nats, device_iid, pb_encode(&req)).await {
        pending_commands().remove(&req_id);
        return Err(e);
    }

    let rx_fut = async {
        if let Ok(res) = rx.await {
            return Ok(res);
        }
        Err("command channel closed".to_string())
    };

    let nats_fut = async {
        if let Some(mut sub) = nats_sub {
            use futures_util::StreamExt;
            if let Some(msg) = sub.next().await {
                if let Ok(res) = pb_decode::<WsRes>(&msg.payload) {
                    if let Some(ws_res::Body::ResRemoteCommand(c)) = res.body {
                        return Ok(c);
                    }
                }
            }
        }
        futures_util::future::pending::<Result<ResRemoteCommand, String>>().await
    };

    let wait_timeout = std::time::Duration::from_secs((timeout_sec.max(15) + 5) as u64);
    let result = tokio::select! {
        res = rx_fut => res,
        res = nats_fut => res,
        _ = tokio::time::sleep(wait_timeout) => {
            Err("command execution timed out (agent took too long to respond)".to_string())
        }
    };

    pending_commands().remove(&req_id);
    result
}

pub async fn remote_device_input_send(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    caller_iid: i64,
    device_iid: i64,
    input: c35_proto::RemoteInputEvent,
) -> Result<(), String> {
    device_remote_allowed(pool, caller_iid, device_iid).await?;
    let bytes = pb_encode(&input);
    remote_agent_send_raw(nats, device_iid, bytes).await
}

pub async fn remote_device_screenshot_capture(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    caller_iid: i64,
    device_iid: i64,
    max_width: u32,
    quality: u32,
    marker: Option<(f64, f64)>,
    som: bool,
) -> Result<ResRemoteScreenshot, String> {
    device_remote_allowed(pool, caller_iid, device_iid).await?;

    match agent_cluster_online(pool, device_iid).await {
        Ok(true) => {}
        Ok(false) => return Err("agent offline".into()),
        Err(e) => return Err(e),
    }

    let (marker_x, marker_y) = marker.unwrap_or((0.0, 0.0));
    let req_id = c35_store::snowflake_id().to_string();
    let (tx, rx) = tokio::sync::oneshot::channel();
    pending_screenshots().insert(req_id.clone(), tx);

    let req = WsReq {
        req_id: req_id.clone(),
        body: Some(ws_req::Body::ReqRemoteScreenshot(ReqRemoteScreenshot {
            device_iid,
            max_width,
            quality,
            marker_x,
            marker_y,
            som,
        })),
    };

    let mut nats_sub = None;
    if let Some(nats) = nats {
        let subject = format!("c35.rpc.screenshot.{req_id}");
        if let Ok(sub) = nats.subscribe(subject).await {
            nats_sub = Some(sub);
        }
    }

    if let Err(e) = remote_agent_send_raw(nats, device_iid, pb_encode(&req)).await {
        pending_screenshots().remove(&req_id);
        return Err(e);
    }

    let rx_fut = async {
        if let Ok(res) = rx.await {
            return Ok(res);
        }
        Err("screenshot channel closed".to_string())
    };

    let nats_fut = async {
        if let Some(mut sub) = nats_sub {
            use futures_util::StreamExt;
            if let Some(msg) = sub.next().await {
                if let Ok(res) = pb_decode::<WsRes>(&msg.payload) {
                    if let Some(ws_res::Body::ResRemoteScreenshot(s)) = res.body {
                        return Ok(s);
                    }
                }
            }
        }
        futures_util::future::pending::<Result<ResRemoteScreenshot, String>>().await
    };

    let timeout_duration = std::time::Duration::from_secs(12);
    let result = tokio::select! {
        res = rx_fut => res,
        res = nats_fut => res,
        _ = tokio::time::sleep(timeout_duration) => {
            Err("screenshot capture timed out (agent took too long to respond)".to_string())
        }
    };

    pending_screenshots().remove(&req_id);
    result
}

async fn remote_device_fs_rpc<T, F>(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    caller_iid: i64,
    device_iid: i64,
    build_req: F,
    pending: &DashMap<String, tokio::sync::oneshot::Sender<T>>,
    nats_subject_prefix: &str,
    extract: fn(WsRes) -> Option<T>,
    timeout_label: &str,
) -> Result<T, String>
where
    F: FnOnce(String) -> WsReq,
    T: Send + 'static,
{
    device_remote_allowed(pool, caller_iid, device_iid).await?;

    match agent_cluster_online(pool, device_iid).await {
        Ok(true) => {}
        Ok(false) => return Err("agent offline".into()),
        Err(e) => return Err(e),
    }

    let req_id = c35_store::snowflake_id().to_string();
    let (tx, rx) = tokio::sync::oneshot::channel();
    pending.insert(req_id.clone(), tx);

    let req = build_req(req_id.clone());

    let mut nats_sub = None;
    if let Some(nats) = nats {
        let subject = format!("{nats_subject_prefix}{req_id}");
        if let Ok(sub) = nats.subscribe(subject).await {
            nats_sub = Some(sub);
        }
    }

    if let Err(e) = remote_agent_send_raw(nats, device_iid, pb_encode(&req)).await {
        pending.remove(&req_id);
        return Err(e);
    }

    let rx_fut = async {
        if let Ok(res) = rx.await {
            return Ok(res);
        }
        Err("fs rpc channel closed".to_string())
    };

    let nats_fut = async {
        if let Some(mut sub) = nats_sub {
            use futures_util::StreamExt;
            if let Some(msg) = sub.next().await {
                if let Ok(res) = pb_decode::<WsRes>(&msg.payload) {
                    if let Some(out) = extract(res) {
                        return Ok(out);
                    }
                }
            }
        }
        futures_util::future::pending::<Result<T, String>>().await
    };

    let wait_timeout = std::time::Duration::from_secs(FS_RPC_TIMEOUT_SEC);
    let result = tokio::select! {
        res = rx_fut => res,
        res = nats_fut => res,
        _ = tokio::time::sleep(wait_timeout) => {
            Err(format!("{timeout_label} timed out (agent took too long to respond)"))
        }
    };

    pending.remove(&req_id);
    result
}

pub async fn remote_device_fs_list(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    caller_iid: i64,
    device_iid: i64,
    path: &str,
) -> Result<RemoteFsListRes, String> {
    let path = path.to_string();
    remote_device_fs_rpc(
        pool,
        nats,
        caller_iid,
        device_iid,
        |req_id| WsReq {
            req_id,
            body: Some(ws_req::Body::ReqRemoteFsList(ReqRemoteFsList {
                device_iid,
                path,
            })),
        },
        pending_fs_list(),
        "c35.rpc.fs_list.",
        |res| {
            if let Some(ws_res::Body::ResRemoteFsList(r)) = res.body {
                Some(r)
            } else {
                None
            }
        },
        "filesystem list",
    )
    .await
}

pub async fn remote_device_fs_read(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    caller_iid: i64,
    device_iid: i64,
    path: &str,
    offset: i64,
    max_bytes: i32,
) -> Result<RemoteFsReadRes, String> {
    let path = path.to_string();
    let max_bytes = if max_bytes <= 0 {
        FS_READ_LLM_MAX
    } else {
        max_bytes.min(FS_READ_LLM_MAX)
    };
    remote_device_fs_rpc(
        pool,
        nats,
        caller_iid,
        device_iid,
        |req_id| WsReq {
            req_id,
            body: Some(ws_req::Body::ReqRemoteFsRead(ReqRemoteFsRead {
                device_iid,
                path,
                offset,
                max_bytes,
            })),
        },
        pending_fs_read(),
        "c35.rpc.fs_read.",
        |res| {
            if let Some(ws_res::Body::ResRemoteFsRead(r)) = res.body {
                Some(r)
            } else {
                None
            }
        },
        "filesystem read",
    )
    .await
}

const BROWSER_COMMAND_PREFIX: &str = "__c35_browser__:";

/// Enqueue `ActDeviceTaskRun` on the paired agent session (JetStream-free v1: direct agent WS).
pub async fn remote_device_task_run_enqueue(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    caller_iid: i64,
    device_iid: i64,
    chat_id: i64,
    req_id: &str,
    prompt: &str,
    skill_id: i64,
    model: &str,
) -> Result<i64, String> {
    device_remote_allowed(pool, caller_iid, device_iid).await?;
    match agent_cluster_online(pool, device_iid).await {
        Ok(true) => {}
        Ok(false) => return Err("agent offline".into()),
        Err(e) => return Err(e),
    }
    let run_id = c35_store::snowflake_id() as i64;
    let act = ActDeviceTaskRun {
        run_id,
        device_iid,
        owner_iid: caller_iid,
        task_id: 0,
        req_id: req_id.to_string(),
        prompt: prompt.to_string(),
        skill_id,
        model: model.to_string(),
        step_index: 0,
        chat_id,
    };
    remote_agent_send_raw(nats, device_iid, pb_encode(&act)).await?;
    Ok(run_id)
}

/// Synchronous browser engine RPC via `ReqRemoteCommand` (remote browser agent only).
pub async fn remote_device_browser_invoke(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    caller_iid: i64,
    device_iid: i64,
    method: &str,
    params: Value,
    timeout_sec: u32,
) -> Result<Value, String> {
    let command = format!(
        "{}{}",
        BROWSER_COMMAND_PREFIX,
        serde_json::json!({ "method": method, "params": params })
    );
    let res = remote_device_command_run(
        pool,
        nats,
        caller_iid,
        device_iid,
        &command,
        timeout_sec.clamp(5, 120),
    )
    .await?;
    if !res.ok {
        let err = if res.error.is_empty() {
            res.stderr.trim().to_string()
        } else {
            res.error
        };
        return Err(if err.is_empty() {
            "browser command failed".into()
        } else {
            err
        });
    }
    let stdout = res.stdout.trim();
    if stdout.is_empty() {
        return Ok(serde_json::json!({ "ok": true }));
    }
    serde_json::from_str(stdout).map_err(|e| format!("invalid browser response json: {e}"))
}

pub async fn remote_device_agent_push(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    caller_iid: i64,
    device_iid: i64,
    payload: &str,
) -> Result<(), String> {
    device_remote_allowed(pool, caller_iid, device_iid).await?;
    match agent_cluster_online(pool, device_iid).await {
        Ok(true) => {}
        Ok(false) => return Err("agent offline".into()),
        Err(e) => return Err(e),
    }
    let text = payload.trim();
    if text.is_empty() {
        return Err("payload cannot be empty".into());
    }
    remote_agent_send_raw(nats, device_iid, text.as_bytes().to_vec()).await
}

pub async fn remote_device_browser_invoke_app(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    caller_iid: i64,
    device_iid: i64,
    method: &str,
    params_json: &str,
    timeout_sec: u32,
) -> Result<c35_proto::ResRemoteBrowserInvoke, String> {
    let method = method.trim();
    if method.is_empty() {
        return Ok(c35_proto::ResRemoteBrowserInvoke {
            ok: false,
            error: "method required".into(),
            result_json: String::new(),
        });
    }
    let params: Value = if params_json.trim().is_empty() {
        Value::Object(serde_json::Map::new())
    } else {
        serde_json::from_str(params_json).map_err(|e| format!("invalid params_json: {e}"))?
    };
    match remote_device_browser_invoke(
        pool,
        nats,
        caller_iid,
        device_iid,
        method,
        params,
        timeout_sec,
    )
    .await
    {
        Ok(v) => Ok(c35_proto::ResRemoteBrowserInvoke {
            ok: true,
            error: String::new(),
            result_json: v.to_string(),
        }),
        Err(e) => Ok(c35_proto::ResRemoteBrowserInvoke {
            ok: false,
            error: e,
            result_json: String::new(),
        }),
    }
}

