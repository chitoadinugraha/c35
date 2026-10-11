use std::sync::OnceLock;

use c35_proto::{
    pb_encode, ws_req, ws_res, DeviceEgressClose, DeviceEgressData,
    ReqDeviceEgressData, ReqDeviceEgressOpen, ResDeviceEgressOpen, WsReq, WsRes,
};
use dashmap::DashMap;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpStream;
use tokio::sync::mpsc;

struct TunnelHandle {
    write_tx: mpsc::UnboundedSender<Vec<u8>>,
}

static TUNNELS: OnceLock<DashMap<u64, TunnelHandle>> = OnceLock::new();

fn tunnels() -> &'static DashMap<u64, TunnelHandle> {
    TUNNELS.get_or_init(DashMap::new)
}

pub async fn handle_ws_req(req: &WsReq, out_tx: &mpsc::UnboundedSender<Vec<u8>>) -> bool {
    match &req.body {
        Some(ws_req::Body::ReqDeviceEgressOpen(open)) => {
            handle_open(req.req_id.clone(), open.clone(), out_tx).await;
            true
        }
        Some(ws_req::Body::ReqDeviceEgressData(data)) => {
            forward_data(data.clone());
            true
        }
        Some(ws_req::Body::ReqDeviceEgressClose(close)) => {
            close_tunnel(close.tunnel_id);
            true
        }
        _ => false,
    }
}

async fn handle_open(
    req_id: String,
    open: ReqDeviceEgressOpen,
    out_tx: &mpsc::UnboundedSender<Vec<u8>>,
) {
    let tunnel_id = open.tunnel_id;
    let target = format!("{}:{}", open.host.trim(), open.port);
    let res = match TcpStream::connect(&target).await {
        Ok(stream) => {
            let (mut reader, writer) = stream.into_split();
            let (write_tx, mut write_rx) = mpsc::unbounded_channel::<Vec<u8>>();
            tunnels().insert(tunnel_id, TunnelHandle { write_tx });

            tokio::spawn(async move {
                let mut writer = writer;
                while let Some(chunk) = write_rx.recv().await {
                    if writer.write_all(&chunk).await.is_err() {
                        break;
                    }
                }
                let _ = writer.shutdown().await;
            });

            let out_reader = out_tx.clone();
            tokio::spawn(async move {
                let mut buf = [0u8; 32 * 1024];
                while let Ok(n) = reader.read(&mut buf).await {
                    if n == 0 {
                        break;
                    }
                    let frame = WsRes {
                        req_id: String::new(),
                        body: Some(ws_res::Body::DeviceEgressData(DeviceEgressData {
                            tunnel_id,
                            payload: buf[..n].to_vec(),
                        })),
                    };
                    if out_reader.send(pb_encode(&frame)).is_err() {
                        break;
                    }
                }
                let close = WsRes {
                    req_id: String::new(),
                    body: Some(ws_res::Body::DeviceEgressClose(DeviceEgressClose {
                        tunnel_id,
                        reason: "tcp_eof".into(),
                    })),
                };
                let _ = out_reader.send(pb_encode(&close));
                tunnels().remove(&tunnel_id);
            });

            ResDeviceEgressOpen {
                ok: true,
                error: String::new(),
                tunnel_id,
            }
        }
        Err(e) => ResDeviceEgressOpen {
            ok: false,
            error: e.to_string(),
            tunnel_id,
        },
    };

    let frame = WsRes {
        req_id,
        body: Some(ws_res::Body::ResDeviceEgressOpen(res)),
    };
    let _ = out_tx.send(pb_encode(&frame));
}

fn forward_data(data: ReqDeviceEgressData) {
    if let Some(t) = tunnels().get(&data.tunnel_id) {
        let _ = t.write_tx.send(data.payload.to_vec());
    }
}

fn close_tunnel(tunnel_id: u64) {
    tunnels().remove(&tunnel_id);
}