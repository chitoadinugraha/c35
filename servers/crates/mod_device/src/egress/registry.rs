use std::collections::HashMap;
use std::sync::OnceLock;

use c35_proto::{pb_encode, ws_req, ws_res, ReqDeviceEgressClose, ReqDeviceEgressData, ResDeviceEgressOpen, WsReq, WsRes};
use dashmap::DashMap;
use tokio::sync::{mpsc, oneshot, Mutex};

struct TunnelState {
    to_client: mpsc::UnboundedSender<Vec<u8>>,
}

static PENDING_OPEN: OnceLock<DashMap<String, oneshot::Sender<ResDeviceEgressOpen>>> = OnceLock::new();
static TUNNELS: OnceLock<DashMap<u64, TunnelState>> = OnceLock::new();
static DEVICE_TUNNEL_COUNT: OnceLock<Mutex<HashMap<i64, u32>>> = OnceLock::new();

fn pending_open() -> &'static DashMap<String, oneshot::Sender<ResDeviceEgressOpen>> {
    PENDING_OPEN.get_or_init(DashMap::new)
}

fn tunnels() -> &'static DashMap<u64, TunnelState> {
    TUNNELS.get_or_init(DashMap::new)
}

fn device_counts() -> &'static Mutex<HashMap<i64, u32>> {
    DEVICE_TUNNEL_COUNT.get_or_init(|| Mutex::new(HashMap::new()))
}

pub async fn register_pending_open(req_id: String) -> oneshot::Receiver<ResDeviceEgressOpen> {
    let (tx, rx) = oneshot::channel();
    pending_open().insert(req_id, tx);
    rx
}

pub fn complete_pending_open(req_id: &str, res: ResDeviceEgressOpen) -> bool {
    if let Some((_, tx)) = pending_open().remove(req_id) {
        let _ = tx.send(res);
        return true;
    }
    false
}

pub async fn tunnel_register(
    tunnel_id: u64,
    device_iid: i64,
    to_client: mpsc::UnboundedSender<Vec<u8>>,
) {
    tunnels().insert(tunnel_id, TunnelState { to_client });
    let mut map = device_counts().lock().await;
    let n = map.get(&device_iid).copied().unwrap_or(0) + 1;
    map.insert(device_iid, n);
}

pub async fn tunnel_unregister(tunnel_id: u64, device_iid: i64) {
    tunnels().remove(&tunnel_id);
    let mut map = device_counts().lock().await;
    if let Some(n) = map.get_mut(&device_iid) {
        *n = n.saturating_sub(1);
        if *n == 0 {
            map.remove(&device_iid);
        }
    }
}

pub async fn device_tunnel_count(device_iid: i64) -> u32 {
    device_counts()
        .lock()
        .await
        .get(&device_iid)
        .copied()
        .unwrap_or(0)
}

pub fn tunnel_send_to_client(tunnel_id: u64, payload: Vec<u8>) -> bool {
    if let Some(entry) = tunnels().get(&tunnel_id) {
        return entry.to_client.send(payload).is_ok();
    }
    false
}

pub fn tunnel_close_local(tunnel_id: u64) {
    tunnels().remove(&tunnel_id);
}

pub fn egress_dispatch_agent_res(res: &WsRes) -> bool {
    match &res.body {
        Some(ws_res::Body::ResDeviceEgressOpen(open)) => {
            let req_id = res.req_id.trim();
            if req_id.is_empty() {
                return false;
            }
            complete_pending_open(req_id, open.clone())
        }
        Some(ws_res::Body::DeviceEgressData(data)) => {
            tunnel_send_to_client(data.tunnel_id, data.payload.to_vec());
            true
        }
        Some(ws_res::Body::DeviceEgressClose(close)) => {
            tunnel_close_local(close.tunnel_id);
            true
        }
        _ => false,
    }
}

pub fn encode_egress_data_to_agent(tunnel_id: u64, payload: Vec<u8>) -> Vec<u8> {
    let req = WsReq {
        req_id: String::new(),
        body: Some(ws_req::Body::ReqDeviceEgressData(ReqDeviceEgressData {
            tunnel_id,
            payload,
        })),
    };
    pb_encode(&req)
}

pub fn encode_egress_close_to_agent(tunnel_id: u64, reason: &str) -> Vec<u8> {
    let req = WsReq {
        req_id: String::new(),
        body: Some(ws_req::Body::ReqDeviceEgressClose(ReqDeviceEgressClose {
            tunnel_id,
            reason: reason.to_string(),
        })),
    };
    pb_encode(&req)
}