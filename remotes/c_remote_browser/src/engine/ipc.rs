use std::collections::HashMap;
use std::sync::atomic::{AtomicU64, Ordering};

use anyhow::{anyhow, Result};
use base64::Engine as _;
use serde_json::{json, Value};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::process::{ChildStdin, ChildStdout};
use tokio::sync::{Mutex, oneshot};

use crate::browser_state;

pub const BRIDGE_VERSION: u8 = 1;
const MAX_FRAME: u32 = 16 * 1024 * 1024;

pub struct EngineBridge {
    stdin: Mutex<ChildStdin>,
    pending: Mutex<HashMap<String, oneshot::Sender<Value>>>,
    next_id: AtomicU64,
}

impl EngineBridge {
    pub fn new(stdin: ChildStdin) -> Self {
        Self {
            stdin: Mutex::new(stdin),
            pending: Mutex::new(HashMap::new()),
            next_id: AtomicU64::new(1),
        }
    }

    pub async fn call(&self, method: &str, params: Value) -> Result<Value> {
        let id = self.next_id.fetch_add(1, Ordering::Relaxed).to_string();
        let (tx, rx) = oneshot::channel();
        self.pending.lock().await.insert(id.clone(), tx);
        let msg = json!({
            "bridge_version": BRIDGE_VERSION,
            "kind": "req",
            "id": id,
            "method": method,
            "params": params
        });
        self.write_message(&msg).await?;
        match rx.await {
            Ok(v) => Ok(v),
            Err(_) => Err(anyhow!("engine ipc closed waiting for {method}")),
        }
    }

    async fn write_message(&self, msg: &Value) -> Result<()> {
        let body = serde_json::to_vec(msg)?;
        if body.len() as u32 > MAX_FRAME {
            return Err(anyhow!("ipc frame too large"));
        }
        let len = (body.len() as u32).to_le_bytes();
        let mut stdin = self.stdin.lock().await;
        stdin.write_all(&len).await?;
        stdin.write_all(&body).await?;
        stdin.flush().await?;
        Ok(())
    }

    pub async fn dispatch_frame(&self, msg: Value) -> Result<()> {
        let kind = msg.get("kind").and_then(|v| v.as_str()).unwrap_or("");
        match kind {
            "res" => {
                let id = msg
                    .get("id")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| anyhow!("res missing id"))?;
                let tx = self.pending.lock().await.remove(id);
                if msg.get("ok").and_then(|v| v.as_bool()) == Some(true) {
                    let payload = msg.get("result").cloned().unwrap_or(Value::Null);
                    if let Some(tx) = tx {
                        let _ = tx.send(payload);
                    }
                } else {
                    let code = msg
                        .get("error")
                        .and_then(|e| e.get("code"))
                        .and_then(|c| c.as_str())
                        .unwrap_or("error");
                    let message = msg
                        .get("error")
                        .and_then(|e| e.get("message"))
                        .and_then(|m| m.as_str())
                        .unwrap_or("engine error");
                    return Err(anyhow!("{code}: {message}"));
                }
            }
            "evt" => {
                let method = msg.get("method").and_then(|v| v.as_str()).unwrap_or("");
                if method == "worker.ready" {
                    tracing::info!("browser_engine ready");
                } else if method == "screencast.frame" {
                    let p = msg.get("params").cloned().unwrap_or(Value::Null);
                    let w = p.get("width").and_then(|v| v.as_u64()).unwrap_or(1280) as u16;
                    let h = p.get("height").and_then(|v| v.as_u64()).unwrap_or(800) as u16;
                    let b64 = p.get("jpeg_b64").and_then(|v| v.as_str()).unwrap_or("");
                    if let Ok(jpeg) = base64::engine::general_purpose::STANDARD.decode(b64) {
                        if let Some(st) = browser_state::global() {
                            st.set_frame(w, h, jpeg);
                        }
                    }
                }
            }
            _ => {}
        }
        Ok(())
    }
}

pub async fn stdout_reader_loop(bridge: std::sync::Arc<EngineBridge>, mut stdout: ChildStdout) {
    let mut rx = Vec::new();
    let mut scratch = [0u8; 4096];
    loop {
        match stdout.read(&mut scratch).await {
            Ok(0) => break,
            Ok(n) => rx.extend_from_slice(&scratch[..n]),
            Err(e) => {
                tracing::warn!("engine stdout read: {e}");
                break;
            }
        }
        while let Some((msg, rest)) = try_parse_frame(&rx) {
            rx = rest;
            if let Err(e) = bridge.dispatch_frame(msg).await {
                tracing::warn!("engine ipc dispatch: {e}");
            }
        }
    }
    let n = {
        let mut guard = bridge.pending.lock().await;
        let n = guard.len();
        guard.clear();
        n
    };
    if n > 0 {
        tracing::warn!(pending = n, "engine worker exited; cancelled pending ipc calls");
    }
}

fn try_parse_frame(buf: &[u8]) -> Option<(Value, Vec<u8>)> {
    if buf.len() < 4 {
        return None;
    }
    let len = u32::from_le_bytes(buf[0..4].try_into().unwrap());
    if len == 0 || len > MAX_FRAME {
        return None;
    }
    let total = 4 + len as usize;
    if buf.len() < total {
        return None;
    }
    let body = &buf[4..total];
    let msg: Value = serde_json::from_slice(body).ok()?;
    let rest = buf[total..].to_vec();
    Some((msg, rest))
}