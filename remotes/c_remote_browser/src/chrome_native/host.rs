//! Chrome native messaging host loop (4-byte LE length + JSON on stdin/stdout).



use std::io::{Read, Write};

use std::sync::{Arc, Mutex};

use std::thread;

use std::time::Duration;



use anyhow::Context;

use c_remote_core::config::{session_key_load, session_key_save, server_url};

use c_remote_core::pair::{pair_poll, pair_register_meta, pair_should_reroll, PairPoll};

use serde_json::{json, Value};

use tracing::{debug, info, warn};



use super::ipc::{spawn_agent_ipc_forward, ExtRpcResponse, HostIpcClient};

use super::messages::{AgentIpcMsg, ExtRequest, ExtResponse};

use crate::extension_ipc::EXTENSION_IPC_NOT_READY_MSG;

use crate::extension_agent::{
    ensure_detached_extension_agent, embedded_agent_active, spawn_embedded_extension_agent,
    wait_for_extension_agent,
};
use crate::pair_loop::chrome_extension_device_name;



#[derive(Debug, Clone, Copy, PartialEq, Eq)]

enum PairPhase {

    Idle,

    Pending,

    Claimed,

}



struct PairHostState {

    phase: PairPhase,

    display_code: String,

    secret: String,

    expires_in_sec: i64,

    device_iid: i64,

}



impl Default for PairHostState {

    fn default() -> Self {

        Self {

            phase: PairPhase::Idle,

            display_code: String::new(),

            secret: String::new(),

            expires_in_sec: 0,

            device_iid: 0,

        }

    }

}



pub fn run_chrome_native_host() -> anyhow::Result<()> {
    c_remote_core::log_local::init();
    crate::mode::hydrate_agent_ui_from_config();

    // Must run before stdin loop: `agent.status` uses `embedded_agent_active()` for a fast UI snapshot.
    spawn_embedded_extension_agent();
    thread::spawn(|| {
        wait_for_extension_agent(Duration::from_secs(15));
        if !embedded_agent_active() && !crate::extension_ipc::extension_ipc_port_in_use() {
            ensure_detached_extension_agent();
        }
    });

    let pair_state = Arc::new(Mutex::new(PairHostState::default()));
    let ipc_slot: Arc<Mutex<Option<HostIpcClient>>> = Arc::new(Mutex::new(None));
    let ipc_bg = Arc::clone(&ipc_slot);
    thread::spawn(move || {
        loop {
            wait_for_extension_agent(Duration::from_secs(8));
            match HostIpcClient::connect() {
                Ok(c) => {
                    if let Ok(mut g) = ipc_bg.lock() {
                        *g = Some(c);
                    }
                    return;
                }
                Err(e) => {
                    debug!("extension ipc not connected (retry): {e:#}");
                    thread::sleep(Duration::from_millis(500));
                }
            }
        }
    });



    if session_key_load().is_some() {

        if let Ok(mut g) = pair_state.lock() {

            g.phase = PairPhase::Claimed;

            g.device_iid = c_remote_core::config::device_iid_load().unwrap_or(0);

        }

    }



    let stdout = Arc::new(Mutex::new(std::io::stdout()));
    spawn_agent_ipc_forward(Arc::clone(&ipc_slot), Arc::clone(&stdout));
    let pair_state_poll = pair_state.clone();
    thread::spawn(move || pair_poll_thread(pair_state_poll));

    let mut stdin = std::io::stdin();

    loop {
        let req = match read_message(&mut stdin) {

            Ok(Some(v)) => v,

            Ok(None) => break,

            Err(e) => {

                warn!("native host read: {e:#}");

                break;

            }

        };



        let req: ExtRequest = match serde_json::from_value(req) {

            Ok(r) => r,

            Err(e) => {
                if let Ok(mut w) = stdout.lock() {
                    let _ = write_response(
                        &mut *w,
                        ExtResponse::err(format!("invalid request: {e}")),
                    );
                }
                continue;
            }
        };

        let resp = match handle_request(&req, &pair_state, &ipc_slot) {
            Ok(r) => r,
            Err(e) => ExtResponse::err(format!("{e:#}")),
        };
        if let Ok(mut w) = stdout.lock() {
            if let Err(e) = write_response(&mut *w, resp) {
                warn!("native host write: {e:#}");
                break;
            }
        }
    }



    Ok(())

}



fn pair_poll_thread(pair_state: Arc<Mutex<PairHostState>>) {

    let rt = tokio::runtime::Builder::new_current_thread()

        .enable_all()

        .build()

        .expect("tokio runtime");

    let base_url = server_url();



    loop {

        thread::sleep(Duration::from_secs(2));



        let (secret, deadline) = {

            let g = match pair_state.lock() {

                Ok(g) => g,

                Err(_) => continue,

            };

            if g.phase != PairPhase::Pending || g.secret.is_empty() {

                continue;

            }

            let deadline =

                std::time::Instant::now() + Duration::from_secs(g.expires_in_sec.max(1) as u64);

            (g.secret.clone(), deadline)

        };



        let poll = match rt.block_on(pair_poll(&base_url, &secret)) {

            Ok(p) => p,

            Err(e) => {

                warn!("pair_poll failed: {e}");

                continue;

            }

        };



        if let PairPoll::Claimed { session_key, device_iid } = poll {

            if let Err(e) = session_key_save(&session_key, device_iid) {

                warn!("session_key_save: {e}");

            } else if let Ok(mut g) = pair_state.lock() {

                g.phase = PairPhase::Claimed;

                g.device_iid = device_iid;

            }

            info!(device_iid, "chrome extension paired");
            wait_for_extension_agent(Duration::from_secs(3));

            continue;

        }



        if pair_should_reroll(&poll, deadline, std::time::Instant::now()) {

            if let Ok(mut g) = pair_state.lock() {

                g.phase = PairPhase::Idle;

                g.secret.clear();

                g.display_code.clear();

            }

        }

    }

}



fn handle_request(
    req: &ExtRequest,
    pair_state: &Arc<Mutex<PairHostState>>,
    ipc_slot: &Arc<Mutex<Option<HostIpcClient>>>,
) -> anyhow::Result<ExtResponse> {

    match req.cmd.as_str() {

        "ping" => {

            let mut r = ExtResponse::ok();

            r.pong = Some(true);

            Ok(r)

        }

        "pair.start" => {
            if session_key_load().is_some() {
                let mut r = ExtResponse::ok();
                r.status = Some("claimed".into());
                r.device_iid = Some(c_remote_core::config::device_iid_load().unwrap_or(0));
                return Ok(r);
            }

            let rt = tokio::runtime::Builder::new_current_thread()
                .enable_all()
                .build()
                .context("tokio")?;

            let name = req

                .device_name

                .clone()

                .filter(|s| !s.is_empty())

                .unwrap_or_else(chrome_extension_device_name);

            let meta = json!({ "browser_engine": "extension" });

            let pending = rt.block_on(pair_register_meta(

                &server_url(),

                &name,

                "browser",

                Some(&meta),

            ))?;



            if let Ok(mut g) = pair_state.lock() {

                g.phase = PairPhase::Pending;

                g.display_code = pending.display_code.clone();

                g.secret = pending.secret.clone();

                g.expires_in_sec = pending.expires_in_sec;

            }



            let mut r = ExtResponse::ok();

            r.code = Some(pending.display_code);

            r.expires_in_sec = Some(pending.expires_in_sec);

            r.status = Some("pending".into());

            Ok(r)

        }

        "pair.status" => {

            let g = pair_state.lock().map_err(|_| anyhow::anyhow!("lock"))?;

            let status = match g.phase {

                PairPhase::Idle => {

                    if session_key_load().is_some() {

                        "claimed"

                    } else {

                        "idle"

                    }

                }

                PairPhase::Pending => "pending",

                PairPhase::Claimed => "claimed",

            };

            let mut r = ExtResponse::ok();

            r.status = Some(status.into());

            if g.phase == PairPhase::Pending && !g.display_code.is_empty() {

                r.code = Some(g.display_code.clone());

                r.expires_in_sec = Some(g.expires_in_sec);

            }

            if status == "claimed" {

                r.device_iid = Some(

                    g.device_iid

                        .max(c_remote_core::config::device_iid_load().unwrap_or(0)),

                );

            }

            Ok(r)

        }

        "frame" => {

            let width = req.width.unwrap_or(0);

            let height = req.height.unwrap_or(0);

            let b64 = req

                .jpeg_b64

                .as_deref()

                .ok_or_else(|| anyhow::anyhow!("jpeg_b64 required"))?;

            if let Ok(g) = ipc_slot.lock() {
                if let Some(ipc) = g.as_ref() {
                    let _ = ipc.send_frame(width, height, b64);
                }
            }

            Ok(ExtResponse::ok())

        }

        "capture.start" | "capture.stop" => Ok(ExtResponse::ok()),

        "tabs.list" => {

            let tabs = req

                .extra

                .get("tabs")

                .cloned()

                .unwrap_or_else(|| json!([]));

            if let Ok(g) = ipc_slot.lock() {
                if let Some(ipc) = g.as_ref() {
                    let _ = ipc.send_tabs_result(json!({ "tabs": tabs }));
                }
            }

            let mut r = ExtResponse::ok();

            r.tabs = Some(tabs);

            Ok(r)

        }

        "tabs.activate" => Ok(ExtResponse::ok()),

        "agent.status" => {
            let mut r = ExtResponse::ok();
            r.data = agent_status_response(ipc_slot);
            Ok(r)
        }

        "identity.get" => {
            let mut r = ExtResponse::ok();
            r.data = agent_status_merge_identity(json!({}));
            Ok(r)
        }

        "rpc.result" => {
            let req_id = req
                .extra
                .get("req_id")
                .and_then(|v| v.as_str())
                .ok_or_else(|| anyhow::anyhow!("req_id required"))?;
            let ok = req.extra.get("ok").and_then(|v| v.as_bool()).unwrap_or(false);
            let error = req
                .extra
                .get("error")
                .and_then(|v| v.as_str())
                .map(|s| s.to_string());
            let result = req.extra.get("result").cloned();
            if let Ok(g) = ipc_slot.lock() {
                if let Some(ipc) = g.as_ref() {
                    let resp = ExtRpcResponse {
                        req_id: req_id.to_string(),
                        ok,
                        error,
                        result,
                    };
                    let _ = ipc.send_rpc_response(&resp);
                }
            }
            Ok(ExtResponse::ok())
        }

        other => Ok(ExtResponse::err(format!("unknown cmd: {other}"))),

    }

}



fn agent_status_merge_identity(status: Value) -> Value {
    let mut status = status;
    let cfg = c_remote_core::config::config_load();
    let device_name = cfg
        .as_ref()
        .and_then(|j| j.get("device_name"))
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty());
    let owner_name = cfg
        .as_ref()
        .and_then(|j| j.get("owner_name"))
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty());
    let owner_alien_id = cfg
        .as_ref()
        .and_then(|j| j.get("owner_alien_id"))
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty());
    if let Some(obj) = status.as_object_mut() {
        let name: Option<String> = device_name
            .map(|s| s.to_string())
            .or_else(|| {
                let n = c_remote_core::agent_ui::device_name();
                let t = n.trim();
                if t.is_empty() {
                    None
                } else {
                    Some(t.to_string())
                }
            });
        if let Some(s) = name {
            obj.insert("device_name".into(), json!(s));
        }
        if let Some(s) = owner_name {
            obj.insert("owner_name".into(), json!(s));
        } else {
            let label = c_remote_core::agent_ui::owner_label();
            let t = label.trim();
            if !t.is_empty() {
                obj.insert("owner_name".into(), json!(t));
            }
        }
        if let Some(s) = owner_alien_id {
            obj.insert("owner_alien_id".into(), json!(s));
        }
        let srv = cfg
            .as_ref()
            .and_then(|j| j.get("server_url"))
            .and_then(|v| v.as_str())
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .map(|s| s.to_string())
            .or_else(|| {
                let u = c_remote_core::config::server_url();
                let t = u.trim();
                if t.is_empty() {
                    None
                } else {
                    Some(t.to_string())
                }
            });
        if let Some(s) = srv {
            obj.insert("server_url".into(), json!(s));
        }
        let iid = obj
            .get("device_iid")
            .and_then(|v| v.as_i64())
            .filter(|id| *id > 0)
            .or_else(c_remote_core::config::device_iid_load);
        if let Some(id) = iid {
            obj.insert("device_iid_str".into(), json!(id.to_string()));
            obj.remove("device_iid");
        }
    }
    status
}

fn agent_status_from_ui_snapshot() -> Value {
    let snap = c_remote_core::agent_ui::snapshot();
    let device_iid = c_remote_core::config::device_iid_load().unwrap_or(0);
    let log_lines: Vec<String> = c_remote_core::log_ring::tail(40)
        .iter()
        .map(c_remote_core::log_ring::format_line)
        .collect();
    agent_status_merge_identity(json!({
        "native_ipc": true,
        "agent_reachable": true,
        "ws_connected": snap.ws_connected,
        "webrtc_sessions": c_remote_core::agent_ui::user_app_connected_count(),
        "webrtc_connecting": snap.webrtc_connecting,
        "webrtc_subtitle": c_remote_core::agent_ui::user_app_subtitle(snap.webrtc_connecting),
        "device_iid": device_iid,
        "agent_version": c_remote_core::version::agent_version_label(),
        "server_url": c_remote_core::config::server_url(),
        "log_lines": log_lines,
    }))
}

fn agent_status_response(slot: &Arc<Mutex<Option<HostIpcClient>>>) -> Value {
    if embedded_agent_active() {
        return agent_status_from_ui_snapshot();
    }
    if let Ok(c) = HostIpcClient::connect_quick() {
        if let Ok(mut g) = slot.lock() {
            *g = Some(c);
        }
    }
    let out = agent_status_with_slot(slot);
    let reachable = out
        .get("agent_reachable")
        .and_then(|v| v.as_bool())
        .unwrap_or(false);
    if reachable {
        return out;
    }
    if crate::extension_ipc::extension_ipc_port_in_use() {
        if let Ok(c) = HostIpcClient::connect_quick() {
            let direct = agent_status_payload_quick(Some(&c));
            let ok = direct
                .get("agent_reachable")
                .and_then(|v| v.as_bool())
                .unwrap_or(false);
            if ok {
                return direct;
            }
        }
        return agent_status_merge_identity(json!({
            "native_ipc": true,
            "agent_reachable": false,
            "ws_connected": false,
            "agent_error": out
                .get("agent_error")
                .and_then(|v| v.as_str())
                .filter(|s| !s.is_empty())
                .unwrap_or("extension agent busy — retry"),
        }));
    }
    out
}

fn agent_status_with_slot(slot: &Arc<Mutex<Option<HostIpcClient>>>) -> Value {
    for attempt in 0..8 {
        if let Ok(mut g) = slot.lock() {
            if g.is_none() {
                if let Ok(c) = HostIpcClient::connect_quick() {
                    *g = Some(c);
                }
            }
        }
        let out = slot
            .lock()
            .ok()
            .and_then(|g| g.as_ref().map(|c| agent_status_payload_quick(Some(c))));
        if let Some(out) = out {
            let reachable = out
                .get("agent_reachable")
                .and_then(|v| v.as_bool())
                .unwrap_or(false);
            if reachable || attempt >= 7 {
                return out;
            }
            if let Ok(mut g) = slot.lock() {
                *g = None;
            }
        }
        thread::sleep(Duration::from_millis(40));
    }
    if let Ok(c) = HostIpcClient::connect_quick() {
        return agent_status_payload_quick(Some(&c));
    }
    agent_status_payload_quick(None)
}

fn agent_status_payload_quick(ipc: Option<&HostIpcClient>) -> Value {
    agent_status_payload(ipc, Duration::from_millis(1500))
}

fn agent_status_payload(ipc: Option<&HostIpcClient>, fetch_timeout: Duration) -> Value {
    let fetch = |c: &HostIpcClient| -> Value {
        let base = match c.fetch_agent_status(fetch_timeout) {
            Ok(AgentIpcMsg::StatusResult {
                ws_connected,
                webrtc_sessions,
                webrtc_connecting,
                device_iid,
                agent_version,
                server_url,
                log_lines,
            }) => {
                json!({
                    "native_ipc": true,
                    "agent_reachable": true,
                    "ws_connected": ws_connected,
                    "webrtc_sessions": c_remote_core::agent_ui::user_app_connected_count(),
                    "webrtc_connecting": webrtc_connecting,
                    "webrtc_subtitle": c_remote_core::agent_ui::user_app_subtitle(webrtc_connecting),
                    "device_iid": device_iid,
                    "agent_version": agent_version,
                    "server_url": server_url,
                    "log_lines": log_lines,
                })
            }
            Ok(_) => json!({
                "native_ipc": true,
                "agent_reachable": false,
                "agent_error": "unexpected status reply",
            }),
            Err(e) => json!({
                "native_ipc": true,
                "agent_reachable": false,
                "agent_error": format!("{e:#}"),
            }),
        };
        agent_status_merge_identity(base)
    };
    if let Some(c) = ipc {
        return fetch(c);
    }
    if let Ok(c) = HostIpcClient::connect_quick() {
        return fetch(&c);
    }
    agent_status_merge_identity(json!({
        "native_ipc": false,
        "agent_reachable": false,
        "agent_error": EXTENSION_IPC_NOT_READY_MSG,
    }))
}

fn read_message(r: &mut impl Read) -> anyhow::Result<Option<Value>> {

    let mut len_buf = [0u8; 4];

    match r.read_exact(&mut len_buf) {

        Ok(()) => {}

        Err(e) if e.kind() == std::io::ErrorKind::UnexpectedEof => return Ok(None),

        Err(e) => return Err(e.into()),

    }

    let len = u32::from_le_bytes(len_buf) as usize;

    if len > 16 * 1024 * 1024 {

        anyhow::bail!("message too large: {len}");

    }

    let mut buf = vec![0u8; len];

    r.read_exact(&mut buf)?;

    Ok(Some(serde_json::from_slice(&buf)?))

}



fn write_message(w: &mut impl Write, v: &Value) -> anyhow::Result<()> {

    super::ipc::write_framed_json(w, v)

}



fn write_response(w: &mut impl Write, resp: ExtResponse) -> anyhow::Result<()> {

    let v = serde_json::to_value(resp)?;

    write_message(w, &v)

}

