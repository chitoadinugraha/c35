//! HTTP CONNECT forward proxy — pod egress via Cloudflare WARP mesh sidecar.
//!
//! Tunnels stay open until the client/upstream closes (no idle cutoff by default).

use std::net::SocketAddr;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;
use std::time::Duration;

use anyhow::{anyhow, Context, Result};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};
use tokio::time::timeout;
use tracing::{error, info, warn};

const DEFAULT_ADDR: &str = "0.0.0.0:8080";
const READ_TIMEOUT: Duration = Duration::from_secs(30);
const MAX_HEADER: usize = 16 * 1024;

#[derive(Clone)]
struct AppState {
    active: Arc<AtomicUsize>,
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info,c35_proxy_cf_warp=info".into()),
        )
        .init();

    let addr = std::env::var("C35_PROXY_CF_ADDR")
        .or_else(|_| std::env::var("CS_PROXY_CF_ADDR"))
        .or_else(|_| std::env::var("ALIENAI_PROXY_CF_ADDR"))
        .unwrap_or_else(|_| DEFAULT_ADDR.to_string());
    let tunnel_idle = tunnel_idle_secs();
    let listener = TcpListener::bind(&addr)
        .await
        .with_context(|| format!("bind {addr}"))?;
    info!(%addr, tunnel_idle_secs = tunnel_idle, "c35_proxy_cf_warp listening");

    let state = AppState {
        active: Arc::new(AtomicUsize::new(0)),
    };

    loop {
        tokio::select! {
            _ = shutdown_signal() => {
                info!("shutdown signal received");
                break;
            }
            accept = listener.accept() => {
                let (stream, peer) = accept?;
                let st = state.clone();
                tokio::spawn(async move {
                    if let Err(err) = serve(stream, st, tunnel_idle).await {
                        warn!(%peer, %err, "connection failed");
                    }
                });
            }
        }
    }
    Ok(())
}

/// `0` = no idle cutoff (default). Set `C35_PROXY_TUNNEL_IDLE_SECS` to cap stale tunnels.
fn tunnel_idle_secs() -> u64 {
    std::env::var("C35_PROXY_TUNNEL_IDLE_SECS")
        .or_else(|_| std::env::var("CS_PROXY_TUNNEL_IDLE_SECS"))
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(0)
}

async fn shutdown_signal() {
    #[cfg(unix)]
    {
        use tokio::signal::unix::{signal, SignalKind};
        let mut term = signal(SignalKind::terminate()).expect("SIGTERM handler");
        tokio::select! {
            _ = tokio::signal::ctrl_c() => {}
            _ = term.recv() => {}
        }
    }
    #[cfg(not(unix))]
    {
        tokio::signal::ctrl_c().await.expect("ctrl_c");
    }
}

async fn serve(mut client: TcpStream, state: AppState, tunnel_idle_secs: u64) -> Result<()> {
    let (head, rest) = read_http_head(&mut client).await?;
    let head = std::str::from_utf8(&head).context("request not utf-8")?;
    let mut lines = head.lines();
    let request_line = lines.next().ok_or_else(|| anyhow!("empty request"))?;
    let mut parts = request_line.split_whitespace();
    let method = parts.next().unwrap_or_default();
    let target = parts.next().unwrap_or_default();

    if method.eq_ignore_ascii_case("GET") && (target == "/health" || target == "/ready") {
        let active = state.active.load(Ordering::Relaxed);
        let body = format!("ok active={active}\n");
        let resp = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{body}",
            body.len()
        );
        client.write_all(resp.as_bytes()).await?;
        return Ok(());
    }

    if !method.eq_ignore_ascii_case("CONNECT") {
        let resp = "HTTP/1.1 405 Method Not Allowed\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
        client.write_all(resp.as_bytes()).await?;
        return Ok(());
    }

    let upstream_addr = parse_connect_target(target).await?;
    let mut upstream = TcpStream::connect(&upstream_addr)
        .await
        .with_context(|| format!("connect {upstream_addr}"))?;

    client
        .write_all(b"HTTP/1.1 200 Connection Established\r\n\r\n")
        .await?;

    if !rest.is_empty() {
        upstream.write_all(&rest).await?;
    }

    state.active.fetch_add(1, Ordering::Relaxed);
    let relay = relay_tunnel(client, upstream, tunnel_idle_secs).await;
    state.active.fetch_sub(1, Ordering::Relaxed);
    relay
}

async fn read_http_head(client: &mut TcpStream) -> Result<(Vec<u8>, Vec<u8>)> {
    let mut buf = Vec::with_capacity(4096);
    loop {
        if buf.len() >= MAX_HEADER {
            return Err(anyhow!("request header too large"));
        }
        let mut chunk = [0u8; 1024];
        let n = timeout(READ_TIMEOUT, client.read(&mut chunk))
            .await
            .context("read timeout")??;
        if n == 0 {
            return Err(anyhow!("client closed before headers"));
        }
        buf.extend_from_slice(&chunk[..n]);
        if let Some(end) = find_header_end(&buf) {
            let rest = buf.split_off(end);
            return Ok((buf, rest));
        }
    }
}

fn find_header_end(buf: &[u8]) -> Option<usize> {
    buf.windows(4).position(|w| w == b"\r\n\r\n").map(|i| i + 4)
}

async fn relay_tunnel(
    client: TcpStream,
    upstream: TcpStream,
    idle_secs: u64,
) -> Result<()> {
    let (mut cr, mut cw) = client.into_split();
    let (mut ur, mut uw) = upstream.into_split();
    let idle = if idle_secs > 0 {
        Some(Duration::from_secs(idle_secs))
    } else {
        None
    };

    let c2u = tokio::spawn(async move {
        let r = match idle {
            Some(d) => timeout(d, tokio::io::copy(&mut cr, &mut uw)).await,
            None => Ok(tokio::io::copy(&mut cr, &mut uw).await),
        };
        let _ = r;
        let _ = uw.shutdown().await;
    });
    let u2c = tokio::spawn(async move {
        let r = match idle {
            Some(d) => timeout(d, tokio::io::copy(&mut ur, &mut cw)).await,
            None => Ok(tokio::io::copy(&mut ur, &mut cw).await),
        };
        let _ = r;
        let _ = cw.shutdown().await;
    });

    if let Err(err) = tokio::try_join!(c2u, u2c) {
        error!(%err, "tunnel relay ended");
    }
    Ok(())
}

async fn parse_connect_target(target: &str) -> Result<SocketAddr> {
    let host_port = target.trim();
    if host_port.is_empty() {
        return Err(anyhow!("empty CONNECT target"));
    }
    if let Ok(addr) = host_port.parse::<SocketAddr>() {
        return Ok(addr);
    }
    let (host, port) = host_port
        .rsplit_once(':')
        .ok_or_else(|| anyhow!("invalid CONNECT target: {host_port}"))?;
    let port: u16 = port.parse().context("invalid port")?;
    let addrs: Vec<SocketAddr> = tokio::net::lookup_host((host, port))
        .await
        .with_context(|| format!("resolve {host_port}"))?
        .collect();
    addrs
        .into_iter()
        .next()
        .ok_or_else(|| anyhow!("no addresses for {host_port}"))
}
