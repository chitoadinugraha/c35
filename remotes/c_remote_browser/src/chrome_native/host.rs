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

use crate::extension_agent::wait_for_extension_agent;
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

    let pair_state = Arc::new(Mutex::new(PairHostState::default()));
    let ipc_slot: Arc<Mutex<Option<HostIpcClient>>> = Arc::new(Mutex::new(None));
    let ipc_bg = Arc::clone(&ipc_slot);
    thread::spawn(move || {
        wait_for_extension_agent(Duration::from_secs(2));
        for attempt in 0..30 {
            match HostIpcClient::connect() {
                Ok(c) => {
                    if let Ok(mut g) = ipc_bg.lock() {
                        *g = Some(c);
                    }
                    return;
                }
                Err(e) => {
                    if attempt == 0 {
                        debug!("extension ipc not connected (retry): {e:#}");
                    }
                    thread::sleep(Duration::from_millis(200));
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

        let resp = match ipc_slot.lock() {
            Ok(guard) => match handle_request(&req, &pair_state, guard.as_ref()) {
                Ok(r) => r,
                Err(e) => ExtResponse::err(format!("{e:#}")),
            },
            Err(_) => ExtResponse::err("ipc lock"),
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

    ipc: Option<&HostIpcClient>,

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

            if let Some(ipc) = ipc {

                let _ = ipc.send_frame(width, height, b64);

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

            if let Some(ipc) = ipc {

                let _ = ipc.send_tabs_result(json!({ "tabs": tabs }));

            }

            let mut r = ExtResponse::ok();

            r.tabs = Some(tabs);

            Ok(r)

        }

        "tabs.activate" => Ok(ExtResponse::ok()),

        "agent.status" => {
            let mut r = ExtResponse::ok();
            r.data = agent_status_payload(ipc);
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
            if let Some(ipc) = ipc {
                let resp = ExtRpcResponse {
                    req_id: req_id.to_string(),
                    ok,
                    error,
                    result,
                };
                let _ = ipc.send_rpc_response(&resp);
            }
            Ok(ExtResponse::ok())
        }

        other => Ok(ExtResponse::err(format!("unknown cmd: {other}"))),

    }

}



fn agent_status_payload(ipc: Option<&HostIpcClient>) -> Value {
    let fetch = |c: &HostIpcClient| -> Value {
        match c.fetch_agent_status(Duration::from_secs(2)) {
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
                    "webrtc_sessions": webrtc_sessions,
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
        }
    };
    if let Some(c) = ipc {
        return fetch(c);
    }
    if let Ok(c) = HostIpcClient::connect() {
        return fetch(&c);
    }
    json!({
        "native_ipc": false,
        "agent_reachable": false,
        "agent_error": EXTENSION_IPC_NOT_READY_MSG,
    })
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

