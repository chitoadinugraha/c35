use std::sync::Arc;

use anyhow::Context;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::{TcpListener, TcpStream};
use tracing::{debug, warn};

use crate::state::AppState;

pub const IPC_ADDR: &str = "127.0.0.1:19831";

pub async fn ipc_listen(state: Arc<AppState>) -> anyhow::Result<()> {
    let listener = TcpListener::bind(IPC_ADDR).await?;
    info_bind();
    loop {
        let (stream, addr) = listener.accept().await?;
        debug!("ipc client {addr}");
        let st = state.clone();
        tokio::spawn(async move {
            if let Err(e) = handle_ipc_client(stream, st).await {
                warn!("ipc session: {e:#}");
            }
        });
    }
}

fn info_bind() {
    tracing::info!("alienai_notify ipc listening on {IPC_ADDR}");
}

async fn handle_ipc_client(stream: TcpStream, state: Arc<AppState>) -> anyhow::Result<()> {
    let (read_half, mut write_half) = stream.into_split();
    let mut reader = BufReader::new(read_half);
    let mut push_rx = state.push_tx.subscribe();
    let mut line = String::new();

    loop {
        tokio::select! {
            read = reader.read_line(&mut line) => {
                let n = read.context("ipc read")?;
                if n == 0 {
                    break;
                }
                let cmd = line.trim().to_string();
                line.clear();
                if cmd.is_empty() {
                    continue;
                }
                let response = dispatch_ipc(&state, &cmd);
                write_half.write_all(response.as_bytes()).await?;
                write_half.write_all(b"\n").await?;
                write_half.flush().await?;
            }
            push = push_rx.recv() => {
                match push {
                    Ok(msg) => {
                        write_half.write_all(msg.as_bytes()).await?;
                        write_half.write_all(b"\n").await?;
                        write_half.flush().await?;
                    }
                    Err(tokio::sync::broadcast::error::RecvError::Lagged(n)) => {
                        warn!("ipc client lagged {n} notify_push lines");
                    }
                    Err(tokio::sync::broadcast::error::RecvError::Closed) => break,
                }
            }
        }
    }
    Ok(())
}

fn dispatch_ipc(state: &Arc<AppState>, cmd: &str) -> String {
    if cmd == "hello" {
        let ws = if state.jwt_snapshot().is_some() {
            "jwt_ok"
        } else {
            "no_jwt"
        };
        return format!("ok helper=wave4 ws={ws} client_id={}", crate::config::client_id());
    }
    if cmd == "set_focus" {
        state.set_focused(true);
        return "ok".to_string();
    }
    if cmd.starts_with("presence ") {
        return parse_presence(state, cmd);
    }
    if let Some(rest) = cmd.strip_prefix("set_jwt ") {
        let token = rest.trim();
        if token.is_empty() {
            return "err empty_jwt".to_string();
        }
        state.set_jwt(token.to_string());
        return "ok".to_string();
    }
    if cmd.starts_with("notify_push ") {
        // Flutter -> helper test hook; acknowledge only.
        return "ok".to_string();
    }
    format!("err unknown")
}

fn parse_presence(state: &Arc<AppState>, cmd: &str) -> String {
    let rest = cmd.strip_prefix("presence ").unwrap_or("").trim();
    let mut resumed: Option<bool> = None;
    for part in rest.split_whitespace() {
        if let Some((k, v)) = part.split_once('=') {
            if k == "resumed" {
                resumed = match v {
                    "true" | "1" => Some(true),
                    "false" | "0" => Some(false),
                    _ => None,
                };
            }
        }
    }
    match resumed {
        Some(v) => {
            state.set_resumed(v);
            if !v {
                state.set_focused(false);
            }
            "ok".to_string()
        }
        None => "err bad_presence".to_string(),
    }
}
