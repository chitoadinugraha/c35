use c35_proto::{sync_push, SyncPush, WsRes, ws_res};
use tokio::sync::mpsc;

pub fn site_sync_push(out_tx: &mpsc::UnboundedSender<WsRes>, body: sync_push::Body) {
    let _ = out_tx.send(WsRes {
        req_id: String::new(),
        body: Some(ws_res::Body::SyncPush(SyncPush {
            body: Some(body),
        })),
    });
}
