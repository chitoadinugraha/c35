//! Localhost bridge between the WebRTC agent and the Chrome-spawned native host.

use std::io::{Read, Write};
use std::net::{SocketAddr, TcpListener, TcpStream};
use std::sync::mpsc::{self, Receiver, SyncSender};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;

use anyhow::Context;
use serde_json::Value;
use tracing::{debug, info, warn};

use crate::browser_state::BrowserState;
use crate::chrome_native::messages::{AgentIpcMsg, ExtPush};

const DEFAULT_PORT: u16 = 37538;

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

pub struct ExtensionBridge {
    tx: SyncSender<AgentIpcMsg>,
}

impl ExtensionBridge {
    pub fn send(&self, msg: AgentIpcMsg) -> anyhow::Result<()> {
        self.tx
            .send(msg)
            .map_err(|_| anyhow::anyhow!("extension ipc disconnected"))
    }

    pub fn capture_start(&self) -> anyhow::Result<()> {
        self.send(AgentIpcMsg::CaptureStart)
    }

    pub fn capture_stop(&self) -> anyhow::Result<()> {
        self.send(AgentIpcMsg::CaptureStop)
    }

    pub fn tabs_list(&self) -> anyhow::Result<()> {
        self.send(AgentIpcMsg::TabsList)
    }

    pub fn tabs_activate(&self, tab_id: &str) -> anyhow::Result<()> {
        self.send(AgentIpcMsg::TabsActivate {
            tab_id: tab_id.to_string(),
        })
    }
}

pub fn spawn_extension_ipc_server(state: Arc<BrowserState>) -> anyhow::Result<Arc<ExtensionBridge>> {
    let addr = extension_ipc_addr();
    let listener = TcpListener::bind(addr).context("bind extension ipc")?;
    info!(%addr, "extension ipc server listening");

    let (cmd_tx, cmd_rx) = mpsc::sync_channel::<AgentIpcMsg>(64);
    let bridge = Arc::new(ExtensionBridge { tx: cmd_tx });

    let state_bg = Arc::clone(&state);
    thread::spawn(move || {
        for stream in listener.incoming() {
            match stream {
                Ok(s) => {
                    info!("extension ipc client connected");
                    if let Err(e) = ipc_session(&state_bg, &cmd_rx, s) {
                        warn!("extension ipc session ended: {e:#}");
                    }
                }
                Err(e) => warn!("extension ipc accept: {e}"),
            }
        }
    });

    if let Ok(mut g) = state.extension_bridge.lock() {
        *g = Some(bridge.clone());
    }

    Ok(bridge)
}

fn ipc_session(
    state: &Arc<BrowserState>,
    cmd_rx: &Receiver<AgentIpcMsg>,
    stream: TcpStream,
) -> anyhow::Result<()> {
    stream.set_read_timeout(Some(Duration::from_millis(500)))?;
    stream.set_write_timeout(Some(Duration::from_secs(5)))?;
    let mut stream = stream;

    loop {
        while let Ok(cmd) = cmd_rx.try_recv() {
            let v = serde_json::to_value(&cmd)?;
            write_framed_json(&mut stream, &v)?;
        }

        match read_framed_json(&mut stream) {
            Ok(Some(v)) => {
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

pub struct HostIpcClient {
    stream: Mutex<TcpStream>,
}

impl HostIpcClient {
    pub fn connect() -> anyhow::Result<Self> {
        let addr = extension_ipc_addr();
        for attempt in 0..40 {
            match TcpStream::connect(addr) {
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
                    thread::sleep(Duration::from_millis(250));
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

    pub fn drain_agent_commands(&self) -> anyhow::Result<Vec<AgentIpcMsg>> {
        let mut out = Vec::new();
        let mut s = self.stream.lock().map_err(|_| anyhow::anyhow!("lock"))?;
        loop {
            match read_framed_json(&mut *s) {
                Ok(Some(v)) => {
                    let msg: AgentIpcMsg = serde_json::from_value(v)?;
                    out.push(msg);
                }
                Ok(None) => break,
                Err(e) if e.to_string().contains("timed out") => break,
                Err(e) => return Err(e),
            }
        }
        Ok(out)
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

pub fn tabs_result_to_agent(value: Value) -> AgentIpcMsg {
    AgentIpcMsg::TabsResult { value }
}
