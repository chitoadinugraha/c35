use std::collections::HashMap;
use std::sync::atomic::{AtomicU64, AtomicUsize, Ordering};
use std::sync::{Arc, OnceLock};

use c35_mod_admin::{require_root, AdminError};
use c35_proto::{LogPush, StatsPush, WsRes, ws_res};
use futures_util::StreamExt;
use prost::Message as ProstMessage;
use tokio::sync::{mpsc, Mutex};
use tokio_util::sync::CancellationToken;
use tracing::warn;

static SESSION_SEQ: AtomicU64 = AtomicU64::new(1);
static RELAY: OnceLock<Arc<Mutex<AdminRelay>>> = OnceLock::new();

struct LogSub {
    out_tx: mpsc::UnboundedSender<WsRes>,
    owner_iid: Option<i64>,
}

struct AdminRelay {
    stats_ref: AtomicUsize,
    log_ref: AtomicUsize,
    last_stats: HashMap<String, StatsPush>,
    stats_sessions: HashMap<u64, mpsc::UnboundedSender<WsRes>>,
    log_sessions: HashMap<u64, LogSub>,
    stats_cancel: Option<CancellationToken>,
    log_cancel: Option<CancellationToken>,
}

fn admin_relay() -> Arc<Mutex<AdminRelay>> {
    RELAY
        .get_or_init(|| {
            Arc::new(Mutex::new(AdminRelay {
                stats_ref: AtomicUsize::new(0),
                log_ref: AtomicUsize::new(0),
                last_stats: HashMap::new(),
                stats_sessions: HashMap::new(),
                log_sessions: HashMap::new(),
                stats_cancel: None,
                log_cancel: None,
            }))
        })
        .clone()
}

pub fn admin_session_id() -> u64 {
    SESSION_SEQ.fetch_add(1, Ordering::Relaxed)
}

pub async fn admin_session_drop(session_id: u64) {
    admin_stats_unsubscribe(session_id).await;
    admin_log_unsubscribe(session_id).await;
}

pub async fn admin_stats_subscribe(
    pool: &sqlx::PgPool,
    nats: Option<&async_nats::Client>,
    viewer_iid: i64,
    session_id: u64,
    out_tx: mpsc::UnboundedSender<WsRes>,
) -> Result<(), AdminError> {
    require_root(pool, viewer_iid).await?;
    let Some(nats) = nats else {
        return Err(AdminError::bad("nats unavailable"));
    };
    let relay_arc = admin_relay();
    let snapshot = {
        let mut guard = relay_arc.lock().await;
        guard.stats_sessions.insert(session_id, out_tx.clone());
        let prev = guard.stats_ref.fetch_add(1, Ordering::AcqRel);
        if prev == 0 {
            let cancel = CancellationToken::new();
            let child = cancel.child_token();
            guard.stats_cancel = Some(cancel);
            let relay_loop = admin_relay();
            let nats = nats.clone();
            tokio::spawn(async move {
                stats_nats_loop(relay_loop, nats, child).await;
            });
        }
        guard.last_stats.values().cloned().collect::<Vec<_>>()
    };
    for push in snapshot {
        let _ = out_tx.send(stats_ws_res(push));
    }
    Ok(())
}

pub async fn admin_stats_unsubscribe(session_id: u64) {
    let relay_arc = admin_relay();
    let mut guard = relay_arc.lock().await;
    if guard.stats_sessions.remove(&session_id).is_none() {
        return;
    }
    let prev = guard.stats_ref.fetch_sub(1, Ordering::AcqRel);
    if prev == 1 {
        if let Some(cancel) = guard.stats_cancel.take() {
            cancel.cancel();
        }
    }
}

pub async fn admin_log_subscribe(
    pool: &sqlx::PgPool,
    nats: Option<&async_nats::Client>,
    viewer_iid: i64,
    session_id: u64,
    owner_iid: Option<i64>,
    out_tx: mpsc::UnboundedSender<WsRes>,
) -> Result<(), AdminError> {
    require_root(pool, viewer_iid).await?;
    let Some(nats) = nats else {
        return Err(AdminError::bad("nats unavailable"));
    };
    let relay_arc = admin_relay();
    let mut guard = relay_arc.lock().await;
    guard.log_sessions.insert(
        session_id,
        LogSub {
            out_tx,
            owner_iid,
        },
    );
    let prev = guard.log_ref.fetch_add(1, Ordering::AcqRel);
    if prev == 0 {
        let cancel = CancellationToken::new();
        let child = cancel.child_token();
        guard.log_cancel = Some(cancel);
        let relay_loop = admin_relay();
        let nats = nats.clone();
        tokio::spawn(async move {
            log_nats_loop(relay_loop, nats, child).await;
        });
    }
    Ok(())
}

pub async fn admin_log_unsubscribe(session_id: u64) {
    let relay_arc = admin_relay();
    let mut guard = relay_arc.lock().await;
    if guard.log_sessions.remove(&session_id).is_none() {
        return;
    }
    let prev = guard.log_ref.fetch_sub(1, Ordering::AcqRel);
    if prev == 1 {
        if let Some(cancel) = guard.log_cancel.take() {
            cancel.cancel();
        }
    }
}

async fn stats_nats_loop(
    relay_arc: Arc<Mutex<AdminRelay>>,
    nats: async_nats::Client,
    cancel: CancellationToken,
) {
    let mut sub = match nats.subscribe("c35.stats.>").await {
        Ok(s) => s,
        Err(e) => {
            warn!("[c35:admin] stats nats subscribe: {e}");
            return;
        }
    };
    loop {
        tokio::select! {
            _ = cancel.cancelled() => break,
            msg = sub.next() => {
                let Some(msg) = msg else { break };
                let Ok(push) = StatsPush::decode(msg.payload.as_ref()) else { continue };
                let subject = msg.subject.to_string();
                let ws = stats_ws_res(push.clone());
                let sessions = {
                    let mut guard = relay_arc.lock().await;
                    guard.last_stats.insert(subject, push);
                    guard.stats_sessions.values().cloned().collect::<Vec<_>>()
                };
                for tx in sessions {
                    let _ = tx.send(ws.clone());
                }
            }
        }
    }
}

async fn log_nats_loop(
    relay_arc: Arc<Mutex<AdminRelay>>,
    nats: async_nats::Client,
    cancel: CancellationToken,
) {
    let mut sub = match nats.subscribe("log.>").await {
        Ok(s) => s,
        Err(e) => {
            warn!("[c35:admin] log nats subscribe: {e}");
            return;
        }
    };
    loop {
        tokio::select! {
            _ = cancel.cancelled() => break,
            msg = sub.next() => {
                let Some(msg) = msg else { break };
                let Ok(push) = LogPush::decode(msg.payload.as_ref()) else { continue };
                let Some(row) = push.row.as_ref() else { continue };
                let owner = row.owner_iid;
                let sessions = {
                    let guard = relay_arc.lock().await;
                    guard
                        .log_sessions
                        .values()
                        .filter(|s| s.owner_iid.is_none_or(|oid| oid == owner))
                        .map(|s| s.out_tx.clone())
                        .collect::<Vec<_>>()
                };
                let ws = WsRes {
                    req_id: String::new(),
                    body: Some(ws_res::Body::LogPush(push)),
                };
                for tx in sessions {
                    let _ = tx.send(ws.clone());
                }
            }
        }
    }
}

fn stats_ws_res(push: StatsPush) -> WsRes {
    WsRes {
        req_id: String::new(),
        body: Some(ws_res::Body::StatsPush(push)),
    }
}
