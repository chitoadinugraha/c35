//! Localhost bridge between the WebRTC agent and the Chrome-spawned native host.

use std::collections::HashMap;
use std::io::{Read, Write};
use std::net::{SocketAddr, TcpListener, TcpStream};
use std::sync::mpsc::{self, Receiver, SyncSender};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex, OnceLock};
use std::thread;
use std::time::{Duration, Instant};

use anyhow::Context;
use serde_json::Value;
use tracing::{debug, info, warn};

use crate::browser_state::BrowserState;
use crate::chrome_native::messages::{
    ipc_is_rpc_request, ipc_is_rpc_response, AgentIpcMsg, ExtPush, ExtRpcRequest, ExtRpcResponse,
};

const DEFAULT_PORT: u16 = 37538;

/// User-facing hint when the extension IPC bridge is not available (CE-A6/K.1).
pub const EXTENSION_IPC_NOT_READY_MSG: &str =
    "Start Chrome Remote agent from the app Remote tab (or run start_chrome_remote_agent.ps1), then ensure the Chrome extension is connected.";

pub fn extension_ipc_not_ready_err() -> anyhow::Error {
    anyhow::anyhow!(EXTENSION_IPC_NOT_READY_MSG)
}

pub fn extension_ipc_port_in_use() -> bool {
    TcpStream::connect_timeout(&extension_ipc_addr(), Duration::from_millis(250)).is_ok()
}

pub fn extension_ipc_addr() -> SocketAddr {
    let port = std::env::var("C35_BROWSER_EXTENSION_IPC_PORT")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(DEFAULT_PORT);
    SocketAddr::from(([127, 0, 0, 1], port))
}

pub fn write_framed_json(w: &mut impl Write, v: &serde_json::Value) -> anyhow::Result<()> {
    let bytes = serde_json::to_vec(v)?;
    let len = bytes.len() as u32;
    w.write_all(&len.to_le_bytes())?;
    w.write_all(&bytes)?;
    w.flush()?;
    Ok(())
}

fn read_framed_json(r: &mut impl Read) -> anyhow::Result<Option<serde_json::Value>> {
    let mut len_buf = [0u8; 4];
    match r.read_exact(&mut len_buf) {
        Ok(()) => {}
        Err(e) if e.kind() == std::io::ErrorKind::UnexpectedEof => return Ok(None),
        Err(e) => return Err(e.into()),
    }
    let len = u32::from_le_bytes(len_buf) as usize;
    if len > 32 * 1024 * 1024 {
        anyhow::bail!("ipc frame too large: {len}");
    }
    let mut buf = vec![0u8; len];
    r.read_exact(&mut buf)?;
    Ok(Some(serde_json::from_slice(&buf)?))
}

fn rpc_req_id() -> String {
    let n = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or(0);
    format!("rpc-{n}")
}

type RpcWaiters = Arc<Mutex<HashMap<String, SyncSender<ExtRpcResponse>>>>;

fn rpc_waiters() -> &'static RpcWaiters {
    static SLOT: OnceLock<RpcWaiters> = OnceLock::new();
    SLOT.get_or_init(|| Arc::new(Mutex::new(HashMap::new())))
}

fn rpc_register(req_id: String) -> Receiver<ExtRpcResponse> {
    let (tx, rx) = mpsc::sync_channel(1);
    if let Ok(mut g) = rpc_waiters().lock() {
        g.insert(req_id, tx);
    }
    rx
}

fn rpc_complete(resp: ExtRpcResponse) {
    if let Ok(mut g) = rpc_waiters().lock() {
        if let Some(tx) = g.remove(&resp.req_id) {
            let _ = tx.send(resp);
        }
    }
}

#[derive(Debug, Clone)]
pub enum ExtensionIpcCmd {
    Legacy(AgentIpcMsg),
    Rpc(ExtRpcRequest),
}

pub struct ExtensionBridge {
    tx: SyncSender<ExtensionIpcCmd>,
}

impl ExtensionBridge {
    pub fn send_legacy(&self, msg: AgentIpcMsg) -> anyhow::Result<()> {
        self.tx
            .send(ExtensionIpcCmd::Legacy(msg))
            .map_err(|_| anyhow::anyhow!("extension ipc disconnected"))
    }

    pub fn send_rpc(&self, req: ExtRpcRequest) -> anyhow::Result<()> {
        self.tx
            .send(ExtensionIpcCmd::Rpc(req))
            .map_err(|_| anyhow::anyhow!("extension ipc disconnected"))
    }

    pub fn call(&self, op: &str, params: Value, timeout: Duration) -> anyhow::Result<Value> {
        let req_id = rpc_req_id();
        let wait_id = req_id.clone();
        let rx = rpc_register(wait_id.clone());
        self.send_rpc(ExtRpcRequest {
            req_id,
            op: op.to_string(),
            params,
        })?;
        match rx.recv_timeout(timeout) {
            Ok(resp) if resp.ok => Ok(resp.result.unwrap_or(Value::Null)),
            Ok(resp) => Err(anyhow::anyhow!(
                resp.error.unwrap_or_else(|| format!("rpc failed: {op}"))
            )),
            Err(mpsc::RecvTimeoutError::Timeout) => {
                if let Ok(mut g) = rpc_waiters().lock() {
                    g.remove(&wait_id);
                }
                Err(anyhow::anyhow!("rpc timeout ({op})"))
            }
            Err(mpsc::RecvTimeoutError::Disconnected) => {
                Err(anyhow::anyhow!("extension ipc disconnected during rpc ({op})"))
            }
        }
    }

    pub fn capture_start(&self) -> anyhow::Result<()> {
        self.send_legacy(AgentIpcMsg::CaptureStart)
    }

    pub fn capture_stop(&self) -> anyhow::Result<()> {
        self.send_legacy(AgentIpcMsg::CaptureStop)
    }

    pub fn tabs_list(&self) -> anyhow::Result<()> {
        self.send_legacy(AgentIpcMsg::TabsList)
    }

    pub fn tabs_activate(&self, tab_id: &str) -> anyhow::Result<()> {
        self.send_legacy(AgentIpcMsg::TabsActivate {
            tab_id: tab_id.to_string(),
        })
    }
}

static EXTENSION_BRIDGE: OnceLock<Mutex<Option<Arc<ExtensionBridge>>>> = OnceLock::new();
static STATUS_FETCH_ACTIVE: AtomicBool = AtomicBool::new(false);

pub fn extension_ipc_status_fetch_active() -> bool {
    STATUS_FETCH_ACTIVE.load(Ordering::SeqCst)
}

fn extension_bridge_slot() -> &'static Mutex<Option<Arc<ExtensionBridge>>> {
    EXTENSION_BRIDGE.get_or_init(|| Mutex::new(None))
}

pub fn extension_bridge_get() -> Option<Arc<ExtensionBridge>> {
    extension_bridge_slot()
        .lock()
        .ok()
        .and_then(|g| g.clone())
}

pub fn spawn_extension_ipc_server(state: Arc<BrowserState>) -> anyhow::Result<Arc<ExtensionBridge>> {
    let addr = extension_ipc_addr();
    let listener = TcpListener::bind(addr).context("bind extension ipc")?;
    info!(%addr, "extension ipc server listening");

    let (cmd_tx, cmd_rx) = mpsc::sync_channel::<ExtensionIpcCmd>(64);
    let bridge = Arc::new(ExtensionBridge { tx: cmd_tx });

    let state_bg = Arc::clone(&state);
    let cmd_rx = Arc::new(Mutex::new(cmd_rx));
    thread::spawn(move || {
        for stream in listener.incoming() {
            match stream {
                Ok(s) => {
                    info!("extension ipc client connected");
                    let state_conn = Arc::clone(&state_bg);
                    let cmd_rx_conn = Arc::clone(&cmd_rx);
                    thread::spawn(move || {
                        if let Err(e) = ipc_session(&state_conn, &cmd_rx_conn, s) {
                            warn!("extension ipc session ended: {e:#}");
                        }
                    });
                }
                Err(e) => warn!("extension ipc accept: {e}"),
            }
        }
    });

    if let Ok(mut g) = extension_bridge_slot().lock() {
        *g = Some(bridge.clone());
    }

    Ok(bridge)
}

fn ipc_session(
    state: &Arc<BrowserState>,
    cmd_rx: &Arc<Mutex<Receiver<ExtensionIpcCmd>>>,
    stream: TcpStream,
) -> anyhow::Result<()> {
    stream.set_read_timeout(Some(Duration::from_millis(500)))?;
    stream.set_write_timeout(Some(Duration::from_secs(5)))?;
    let mut stream = stream;

    loop {
        while let Ok(cmd) = cmd_rx
            .lock()
            .map_err(|_| anyhow::anyhow!("cmd_rx lock"))?
            .try_recv()
        {
            let v = match cmd {
                ExtensionIpcCmd::Legacy(msg) => serde_json::to_value(&msg)?,
                ExtensionIpcCmd::Rpc(req) => serde_json::to_value(&req)?,
            };
            write_framed_json(&mut stream, &v)?;
        }

        match read_framed_json(&mut stream) {
            Ok(Some(v)) => {
                if ipc_is_rpc_response(&v) {
                    let resp: ExtRpcResponse = serde_json::from_value(v)?;
                    rpc_complete(resp);
                    continue;
                }
                let msg: AgentIpcMsg = serde_json::from_value(v)?;
                match msg {
                    AgentIpcMsg::Frame {
                        width,
                        height,
                        jpeg_b64,
                    } => {
                        use base64::Engine as _;
                        let jpeg = base64::engine::general_purpose::STANDARD
                            .decode(jpeg_b64.trim())
                            .context("frame jpeg_b64")?;
                        state.set_frame(width, height, jpeg);
                    }
                    AgentIpcMsg::TabsResult { value } => {
                        if let Ok(mut g) = state.extension_tabs.lock() {
                            *g = Some(value);
                        }
                    }
                    AgentIpcMsg::Pong => debug!("extension ipc pong"),
                    AgentIpcMsg::StatusQuery => {
                        let snap = c_remote_core::agent_ui::snapshot();
                        let device_iid =
                            c_remote_core::config::device_iid_load().unwrap_or(0);
                        let log_lines: Vec<String> = c_remote_core::log_ring::tail(40)
                            .iter()
                            .map(c_remote_core::log_ring::format_line)
                            .collect();
                        let resp = AgentIpcMsg::StatusResult {
                            ws_connected: snap.ws_connected,
                            webrtc_sessions: c_remote_core::agent_ui::user_app_connected_count(),
                            webrtc_connecting: snap.webrtc_connecting,
                            device_iid,
                            agent_version: c_remote_core::version::agent_version_label(),
                            server_url: c_remote_core::config::server_url(),
                            log_lines,
                        };
                        let mut v = serde_json::to_value(&resp)?;
                        if let Some(obj) = v.as_object_mut() {
                            obj.insert(
                                "device_iid_str".into(),
                                serde_json::json!(device_iid.to_string()),
                            );
                            obj.remove("device_iid");
                        }
                        write_framed_json(&mut stream, &v)?;
                    }
                    other => debug!(?other, "unexpected ipc from host"),
                }
            }
            Ok(None) => break,
            Err(e) if e.to_string().contains("timed out") || e.to_string().contains("WouldBlock") => {}
            Err(e) => return Err(e),
        }
    }
    Ok(())
}

#[derive(Debug, Clone)]
pub enum AgentInbound {
    Legacy(AgentIpcMsg),
    Rpc(ExtRpcRequest),
}

pub struct HostIpcClient {
    stream: Mutex<TcpStream>,
}

impl HostIpcClient {
    pub fn connect() -> anyhow::Result<Self> {
        Self::connect_budget(Duration::from_secs(10))
    }

    /// Fast connect for native-host status polls (must finish under Chrome NM timeout).
    pub fn connect_quick() -> anyhow::Result<Self> {
        Self::connect_budget(Duration::from_millis(900))
    }

    fn connect_budget(max_wait: Duration) -> anyhow::Result<Self> {
        let addr = extension_ipc_addr();
        let deadline = Instant::now() + max_wait;
        let mut attempt = 0u32;
        while Instant::now() < deadline {
            match TcpStream::connect_timeout(&addr, Duration::from_millis(200)) {
                Ok(s) => {
                    s.set_read_timeout(Some(Duration::from_millis(500)))?;
                    s.set_write_timeout(Some(Duration::from_secs(5)))?;
                    info!(%addr, "extension ipc connected to agent");
                    return Ok(Self {
                        stream: Mutex::new(s),
                    });
                }
                Err(e) => {
                    if attempt == 0 {
                        debug!(%addr, "extension ipc connect retry: {e}");
                    }
                    attempt += 1;
                    thread::sleep(Duration::from_millis(50));
                }
            }
        }
        anyhow::bail!("extension ipc agent not reachable at {addr}");
    }

    pub fn send_tabs_result(&self, value: Value) -> anyhow::Result<()> {
        let msg = tabs_result_to_agent(value);
        let v = serde_json::to_value(&msg)?;
        let mut s = self.stream.lock().map_err(|_| anyhow::anyhow!("lock"))?;
        write_framed_json(&mut *s, &v)
    }

    pub fn send_rpc_response(&self, resp: &ExtRpcResponse) -> anyhow::Result<()> {
        let v = serde_json::to_value(resp)?;
        let mut s = self.stream.lock().map_err(|_| anyhow::anyhow!("lock"))?;
        write_framed_json(&mut *s, &v)
    }

    pub fn send_frame(&self, width: u16, height: u16, jpeg_b64: &str) -> anyhow::Result<()> {
        let msg = AgentIpcMsg::Frame {
            width,
            height,
            jpeg_b64: jpeg_b64.to_string(),
        };
        let v = serde_json::to_value(&msg)?;
        let mut s = self.stream.lock().map_err(|_| anyhow::anyhow!("lock"))?;
        write_framed_json(&mut *s, &v)
    }

    pub fn drain_agent_inbound(&self) -> anyhow::Result<Vec<AgentInbound>> {
        let mut out = Vec::new();
        let mut s = self.stream.lock().map_err(|_| anyhow::anyhow!("lock"))?;
        loop {
            match read_framed_json(&mut *s) {
                Ok(Some(v)) => {
                    if ipc_is_rpc_request(&v) {
                        out.push(AgentInbound::Rpc(serde_json::from_value(v)?));
                    } else {
                        out.push(AgentInbound::Legacy(serde_json::from_value(v)?));
                    }
                }
                Ok(None) => break,
                Err(e) if e.to_string().contains("timed out") => break,
                Err(e) => return Err(e),
            }
        }
        Ok(out)
    }

    pub fn fetch_agent_status(&self, timeout: Duration) -> anyhow::Result<AgentIpcMsg> {
        STATUS_FETCH_ACTIVE.store(true, Ordering::SeqCst);
        let out = self.fetch_agent_status_inner(timeout);
        STATUS_FETCH_ACTIVE.store(false, Ordering::SeqCst);
        out
    }

    fn fetch_agent_status_inner(&self, timeout: Duration) -> anyhow::Result<AgentIpcMsg> {
        let v = serde_json::to_value(&AgentIpcMsg::StatusQuery)?;
        let mut s = self.stream.lock().map_err(|_| anyhow::anyhow!("lock"))?;
        write_framed_json(&mut *s, &v)?;
        let deadline = Instant::now() + timeout;
        while Instant::now() < deadline {
            match read_framed_json(&mut *s) {
                Ok(Some(v)) => {
                    if let Ok(AgentIpcMsg::StatusResult { .. }) = serde_json::from_value(v.clone()) {
                        return Ok(serde_json::from_value(v)?);
                    }
                    if ipc_is_rpc_request(&v) {
                        debug!("fetch_agent_status: unexpected rpc request from agent");
                    }
                }
                Ok(None) => break,
                Err(e) if e.to_string().contains("timed out") => continue,
                Err(e) => return Err(e),
            }
        }
        anyhow::bail!("agent status query timeout")
    }

    pub fn drain_agent_commands(&self) -> anyhow::Result<Vec<AgentIpcMsg>> {
        Ok(self
            .drain_agent_inbound()?
            .into_iter()
            .filter_map(|m| match m {
                AgentInbound::Legacy(msg) => Some(msg),
                AgentInbound::Rpc(_) => None,
            })
            .collect())
    }
}

pub fn agent_ipc_to_ext_push(msg: &AgentIpcMsg) -> Option<ExtPush> {
    match msg {
        AgentIpcMsg::CaptureStart => Some(ExtPush {
            cmd: "capture.start".into(),
            tab_id: None,
            extra: Value::Null,
        }),
        AgentIpcMsg::CaptureStop => Some(ExtPush {
            cmd: "capture.stop".into(),
            tab_id: None,
            extra: Value::Null,
        }),
        AgentIpcMsg::TabsList => Some(ExtPush {
            cmd: "tabs.list".into(),
            tab_id: None,
            extra: Value::Null,
        }),
        AgentIpcMsg::TabsActivate { tab_id } => Some(ExtPush {
            cmd: "tabs.activate".into(),
            tab_id: Some(tab_id.clone()),
            extra: Value::Null,
        }),
        _ => None,
    }
}

pub fn rpc_request_to_ext_push(req: &ExtRpcRequest) -> ExtPush {
    ExtPush {
        cmd: "rpc".into(),
        tab_id: None,
        extra: serde_json::json!({
            "req_id": req.req_id,
            "op": req.op,
            "params": req.params,
        }),
    }
}

pub fn tabs_result_to_agent(value: Value) -> AgentIpcMsg {
    AgentIpcMsg::TabsResult { value }
}

pub fn spawn_agent_ipc_forward(
    ipc_slot: Arc<Mutex<Option<HostIpcClient>>>,
    stdout: Arc<Mutex<std::io::Stdout>>,
) {
    thread::spawn(move || {
        let started = Instant::now();
        while started.elapsed() < Duration::from_secs(3600 * 24) {
            thread::sleep(Duration::from_millis(25));
            if extension_ipc_status_fetch_active() {
                continue;
            }
            let inbound = match ipc_slot.lock() {
                Ok(g) => g.as_ref().and_then(|c| c.drain_agent_inbound().ok()),
                Err(_) => None,
            };
            let Some(frames) = inbound else { continue };
            for frame in frames {
                let push = match frame {
                    AgentInbound::Legacy(msg) => agent_ipc_to_ext_push(&msg),
                    AgentInbound::Rpc(req) => Some(rpc_request_to_ext_push(&req)),
                };
                if let Some(push) = push {
                    let v = serde_json::to_value(&push).unwrap_or(Value::Null);
                    if let Ok(mut w) = stdout.lock() {
                        if let Err(e) = write_framed_json(&mut *w, &v) {
                            warn!("agent ipc forward write: {e:#}");
                        }
                    }
                }
            }
        }
    });
}
