use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;

use c35_proto::{pb_encode, ws_req, ReqDeviceEgressOpen, WsReq};
use c35_store::PgPool;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpListener;
use tokio::time::{timeout, Duration};
use tracing::{info, warn};

use super::allowlist::host_allowed;
use super::lease::{egress_enabled, egress_listen_addr, lease_validate_basic_auth};
use super::registry::{
    device_tunnel_count, encode_egress_close_to_agent, encode_egress_data_to_agent,
    register_pending_open, tunnel_register, tunnel_unregister,
};
use crate::remote_signaling::{agent_cluster_online, remote_agent_send_raw};

const MAX_HEADER: usize = 16 * 1024;
const READ_TIMEOUT: Duration = Duration::from_secs(30);
const OPEN_TIMEOUT: Duration = Duration::from_secs(20);
const MAX_TUNNELS_PER_DEVICE: u32 = 16;

pub fn egress_proxy_spawn(pool: PgPool, nats: Option<async_nats::Client>) {
    if !egress_enabled() {
        return;
    }
    let addr = egress_listen_addr();
    tokio::spawn(async move {
        let listener = match TcpListener::bind(&addr).await {
            Ok(l) => l,
            Err(e) => {
                warn!(%addr, "egress proxy bind failed: {e:#}");
                return;
            }
        };
        info!(%addr, "device egress CONNECT proxy listening");
        let active = Arc::new(AtomicUsize::new(0));
        loop {
            let (stream, peer) = match listener.accept().await {
                Ok(v) => v,
                Err(e) => {
                    warn!("egress accept: {e:#}");
                    continue;
                }
            };
            let pool = pool.clone();
            let nats = nats.clone();
            let active = Arc::clone(&active);
            tokio::spawn(async move {
                active.fetch_add(1, Ordering::Relaxed);
                if let Err(e) = serve_connection(stream, &pool, nats.as_ref()).await {
                    warn!(%peer, "egress connection: {e:#}");
                }
                active.fetch_sub(1, Ordering::Relaxed);
            });
        }
    });
}

async fn serve_connection(
    mut client: tokio::net::TcpStream,
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
) -> anyhow::Result<()> {
    let (head, rest) = read_http_head(&mut client).await?;
    let head = std::str::from_utf8(&head)?;
    let mut lines = head.lines();
    let request_line = lines.next().ok_or_else(|| anyhow::anyhow!("empty request"))?;
    let mut parts = request_line.split_whitespace();
    let method = parts.next().unwrap_or_default();
    let target = parts.next().unwrap_or_default();

    if method.eq_ignore_ascii_case("GET") && (target == "/health" || target == "/ready") {
        let body = "ok\n";
        let resp = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{body}",
            body.len()
        );
        client.write_all(resp.as_bytes()).await?;
        return Ok(());
    }

    if !method.eq_ignore_ascii_case("CONNECT") {
        let resp =
            "HTTP/1.1 405 Method Not Allowed\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
        client.write_all(resp.as_bytes()).await?;
        return Ok(());
    }

    let (user, pass) = match parse_proxy_auth(&head) {
        Ok(v) => v,
        Err(_) => {
            client
                .write_all(b"HTTP/1.1 407 Proxy Authentication Required\r\nProxy-Authenticate: Basic realm=\"device-egress\"\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
                .await?;
            return Ok(());
        }
    };
    let lease = match lease_validate_basic_auth(pool, &user, &pass).await {
        Ok(l) => l,
        Err(_) => {
            client
                .write_all(b"HTTP/1.1 407 Proxy Authentication Required\r\nProxy-Authenticate: Basic realm=\"device-egress\"\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
                .await?;
            return Ok(());
        }
    };

    let (host, port) = parse_connect_host_port(target)?;
    if !host_allowed(&host, &lease.allow_hosts) {
        client
            .write_all(b"HTTP/1.1 403 Forbidden\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
            .await?;
        return Ok(());
    }

    if device_tunnel_count(lease.device_iid).await >= MAX_TUNNELS_PER_DEVICE {
        client
            .write_all(b"HTTP/1.1 503 Service Unavailable\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
            .await?;
        return Ok(());
    }

    match agent_cluster_online(pool, nats, lease.device_iid).await {
        Ok(true) => {}
        _ => {
            client
                .write_all(b"HTTP/1.1 502 Bad Gateway\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
                .await?;
            return Ok(());
        }
    }

    let tunnel_id = c35_store::snowflake_id() as u64;
    let req_id = c35_store::snowflake_id().to_string();
    let open_rx = register_pending_open(req_id.clone()).await;

    let open_req = WsReq {
        req_id,
        body: Some(ws_req::Body::ReqDeviceEgressOpen(ReqDeviceEgressOpen {
            tunnel_id,
            host: host.clone(),
            port,
        })),
    };
    if remote_agent_send_raw(nats, lease.device_iid, pb_encode(&open_req))
        .await
        .is_err()
    {
        client
            .write_all(b"HTTP/1.1 502 Bad Gateway\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
            .await?;
        return Ok(());
    }

    let open_res = match timeout(OPEN_TIMEOUT, open_rx).await {
        Ok(Ok(r)) => r,
        _ => {
            client
                .write_all(b"HTTP/1.1 504 Gateway Timeout\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
                .await?;
            return Ok(());
        }
    };

    if !open_res.ok {
        client
            .write_all(b"HTTP/1.1 502 Bad Gateway\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
            .await?;
        return Ok(());
    }

    client
        .write_all(b"HTTP/1.1 200 Connection Established\r\n\r\n")
        .await?;
    if !rest.is_empty() {
        let frame = encode_egress_data_to_agent(tunnel_id, rest);
        let _ = remote_agent_send_raw(nats, lease.device_iid, frame).await;
    }

    let (mut cr, mut cw) = client.into_split();
    let (to_client_tx, mut to_client_rx) = tokio::sync::mpsc::unbounded_channel();
    tunnel_register(tunnel_id, lease.device_iid, to_client_tx).await;

    let device_iid = lease.device_iid;
    let nats_client = nats.cloned();
    let c2a = tokio::spawn(async move {
        let mut buf = [0u8; 32 * 1024];
        while let Ok(n) = cr.read(&mut buf).await {
            if n == 0 {
                break;
            }
            let frame = encode_egress_data_to_agent(tunnel_id, buf[..n].to_vec());
            if remote_agent_send_raw(nats_client.as_ref(), device_iid, frame)
                .await
                .is_err()
            {
                break;
            }
        }
        let close = encode_egress_close_to_agent(tunnel_id, "client_eof");
        let _ = remote_agent_send_raw(nats_client.as_ref(), device_iid, close).await;
    });

    let a2c = tokio::spawn(async move {
        while let Some(chunk) = to_client_rx.recv().await {
            if cw.write_all(&chunk).await.is_err() {
                break;
            }
        }
        let _ = cw.shutdown().await;
    });

    let _ = tokio::join!(c2a, a2c);
    tunnel_unregister(tunnel_id, lease.device_iid).await;
    Ok(())
}

fn parse_proxy_auth(head: &str) -> anyhow::Result<(String, String)> {
    for line in head.lines() {
        if line.len() >= 20 && line[..20].eq_ignore_ascii_case("proxy-authorization:") {
            let val = line[20..].trim();
            if let Some(b64) = val.strip_prefix("Basic ").or_else(|| val.strip_prefix("basic ")) {
                let decoded = base64::Engine::decode(
                    &base64::engine::general_purpose::STANDARD,
                    b64.trim(),
                )?;
                let s = String::from_utf8(decoded)?;
                if let Some((u, p)) = s.split_once(':') {
                    return Ok((u.to_string(), p.to_string()));
                }
            }
        }
    }
    anyhow::bail!("missing Proxy-Authorization")
}

fn parse_connect_host_port(target: &str) -> anyhow::Result<(String, u32)> {
    let t = target.trim();
    if let Some((host, port)) = t.rsplit_once(':') {
        let port: u32 = port.parse()?;
        return Ok((host.to_string(), port));
    }
    anyhow::bail!("invalid CONNECT target")
}

async fn read_http_head(client: &mut tokio::net::TcpStream) -> anyhow::Result<(Vec<u8>, Vec<u8>)> {
    let mut buf = Vec::with_capacity(4096);
    loop {
        if buf.len() >= MAX_HEADER {
            anyhow::bail!("header too large");
        }
        let mut chunk = [0u8; 1024];
        let n = timeout(READ_TIMEOUT, client.read(&mut chunk))
            .await??;
        if n == 0 {
            anyhow::bail!("eof before headers");
        }
        buf.extend_from_slice(&chunk[..n]);
        if let Some(end) = buf.windows(4).position(|w| w == b"\r\n\r\n") {
            let rest = buf.split_off(end + 4);
            return Ok((buf, rest));
        }
    }
}
