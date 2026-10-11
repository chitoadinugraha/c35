use std::collections::HashMap;
use std::sync::atomic::{AtomicU64, AtomicUsize, Ordering};
use std::sync::{Arc, OnceLock};

use c35_mod_admin::{require_root, AdminError};
use c35_nats::{stats_kv_ensure, stats_kv_key_for_push, stats_kv_list_pushes, stats_kv_put};
use c35_proto::{
    stats_push, Event, EventPush, Log, LogPush, ReqAdminOpsPeaks, ReqAdminPlatformUserMetrics,
    ReqRootConsole, ResRootConsole, ResStatsSubscribe,
    StatsPush, WsRes, ws_res,
};
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
    stats_listener: Option<CancellationToken>,
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
                stats_listener: None,
                log_cancel: None,
            }))
        })
        .clone()
}

/// Keep NATS stats cache warm so root console gets a snapshot without waiting for the next tick.
pub async fn admin_stats_warm(nats: async_nats::Client) {
    let _ = stats_kv_ensure(&nats).await;
    ensure_stats_listener(admin_relay(), nats.clone()).await;
    hydrate_stats_kv(&nats).await;
}

async fn hydrate_stats_kv(nats: &async_nats::Client) {
    let Ok(store) = stats_kv_ensure(nats).await else {
        return;
    };
    let pushes = stats_kv_list_pushes(&store).await;
    if pushes.is_empty() {
        return;
    }
    let relay_arc = admin_relay();
    let mut guard = relay_arc.lock().await;
    for push in pushes {
        let key = stats_push_subject_key(&push);
        if !key.is_empty() {
            guard.last_stats.insert(key, push);
        }
    }
}

async fn ensure_stats_listener(relay_arc: Arc<Mutex<AdminRelay>>, nats: async_nats::Client) {
    let child = {
        let mut guard = relay_arc.lock().await;
        if guard.stats_listener.is_some() {
            return;
        }
        let cancel = CancellationToken::new();
        let child = cancel.child_token();
        guard.stats_listener = Some(cancel);
        child
    };
    tokio::spawn(async move {
        stats_nats_loop(relay_arc, nats, child).await;
    });
}

pub fn admin_session_id() -> u64 {
    SESSION_SEQ.fetch_add(1, Ordering::Relaxed)
}

pub async fn admin_session_drop(session_id: u64) {
    admin_stats_unsubscribe(session_id).await;
    admin_log_unsubscribe(session_id).await;
}

async fn admin_stats_snapshot_merge(
    relay_arc: &Arc<Mutex<AdminRelay>>,
    nats: &async_nats::Client,
) -> HashMap<String, StatsPush> {
    let mut merged = {
        let guard = relay_arc.lock().await;
        guard.last_stats.clone()
    };
    if let Ok(store) = stats_kv_ensure(nats).await {
        for push in stats_kv_list_pushes(&store).await {
            let key = stats_push_subject_key(&push);
            if !key.is_empty() {
                merged.entry(key).or_insert(push);
            }
        }
    }
    merged
}

fn snapshot_vec(merged: &HashMap<String, StatsPush>) -> Vec<StatsPush> {
    let mut nodes = Vec::new();
    let mut volumes = Vec::new();
    let mut pods = Vec::new();
    for push in merged.values() {
        match &push.body {
            Some(stats_push::Body::Node(_)) => nodes.push(push.clone()),
            Some(stats_push::Body::Volume(_)) => volumes.push(push.clone()),
            Some(stats_push::Body::Pod(_)) => pods.push(push.clone()),
            None => {}
        }
    }
    fn node_name(push: &StatsPush) -> &str {
        match &push.body {
            Some(stats_push::Body::Node(n)) => n.node_name.as_str(),
            _ => "",
        }
    }
    fn volume_key(push: &StatsPush) -> String {
        match &push.body {
            Some(stats_push::Body::Volume(v)) => {
                format!("{}.{}.{}", v.node_name, v.namespace, v.pvc_name)
            }
            _ => String::new(),
        }
    }
    fn pod_key(push: &StatsPush) -> String {
        match &push.body {
            Some(stats_push::Body::Pod(p)) => {
                format!("{}.{}.{}", p.node_name, p.namespace, p.pod_name)
            }
            _ => String::new(),
        }
    }
    nodes.sort_by(|a, b| node_name(a).cmp(node_name(b)));
    volumes.sort_by(|a, b| volume_key(a).cmp(&volume_key(b)));
    pods.sort_by(|a, b| pod_key(a).cmp(&pod_key(b)));
    nodes.into_iter().chain(volumes).chain(pods).collect()
}

pub async fn admin_stats_subscribe(
    pool: &sqlx::PgPool,
    nats: Option<&async_nats::Client>,
    viewer_iid: i64,
    session_id: u64,
    out_tx: mpsc::UnboundedSender<WsRes>,
    fanout_snapshot: bool,
) -> Result<ResStatsSubscribe, AdminError> {
    require_root(pool, viewer_iid).await?;
    let Some(nats) = nats else {
        return Err(AdminError::bad("nats unavailable"));
    };
    let relay_arc = admin_relay();
    ensure_stats_listener(relay_arc.clone(), nats.clone()).await;
    let merged = {
        let mut guard = relay_arc.lock().await;
        guard.stats_sessions.insert(session_id, out_tx.clone());
        guard.stats_ref.fetch_add(1, Ordering::AcqRel);
        drop(guard);
        admin_stats_snapshot_merge(&relay_arc, nats).await
    };
    let snapshot = snapshot_vec(&merged);
    if fanout_snapshot {
        for push in &snapshot {
            let _ = out_tx.send(stats_ws_res(push.clone()));
        }
    }
    Ok(ResStatsSubscribe { snapshot })
}

pub async fn admin_root_console(
    pool: &sqlx::PgPool,
    nats: Option<&async_nats::Client>,
    viewer_iid: i64,
    session_id: u64,
    out_tx: mpsc::UnboundedSender<WsRes>,
    req: ReqRootConsole,
) -> Result<ResRootConsole, AdminError> {
    require_root(pool, viewer_iid).await?;
    let Some(nats) = nats else {
        return Err(AdminError::bad("nats unavailable"));
    };
    let relay_arc = admin_relay();
    ensure_stats_listener(relay_arc.clone(), nats.clone()).await;
    let merged = admin_stats_snapshot_merge(&relay_arc, nats).await;
    let stats_snapshot = snapshot_vec(&merged);

    let until_ms = req.peaks_until_ms.unwrap_or_else(|| chrono::Utc::now().timestamp_millis());
    let since_ms = req
        .peaks_since_ms
        .unwrap_or(until_ms - 86_400_000);
    let peaks_req = ReqAdminOpsPeaks {
        since_ms,
        until_ms,
        entity_type: Some("node".into()),
        node_name: None,
    };

    let (user_metrics, peaks_24h) = tokio::join!(
        c35_mod_admin::admin_platform_user_metrics(
            pool,
            viewer_iid,
            ReqAdminPlatformUserMetrics {},
        ),
        c35_mod_admin::admin_ops_peaks(pool, viewer_iid, peaks_req),
    );
    let user_metrics = user_metrics?;
    let peaks_24h = peaks_24h?;

    if req.subscribe_stats.unwrap_or(true) {
        let mut guard = relay_arc.lock().await;
        guard.stats_sessions.insert(session_id, out_tx.clone());
        guard.stats_ref.fetch_add(1, Ordering::AcqRel);
    }

    Ok(ResRootConsole {
        stats_snapshot,
        user_metrics: Some(user_metrics),
        peaks_24h: Some(peaks_24h),
    })
}

pub async fn admin_stats_unsubscribe(session_id: u64) {
    let relay_arc = admin_relay();
    let mut guard = relay_arc.lock().await;
    if guard.stats_sessions.remove(&session_id).is_none() {
        return;
    }
    guard.stats_ref.fetch_sub(1, Ordering::AcqRel);
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
    let kv = stats_kv_ensure(&nats).await.ok();
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
                let key = stats_push_subject_key(&push);
                if key.is_empty() {
                    continue;
                }
                if let Some(store) = kv.as_ref() {
                    if let Some(kv_key) = stats_kv_key_for_push(&push) {
                        let store = store.clone();
                        let push_kv = push.clone();
                        tokio::spawn(async move {
                            if let Err(e) = stats_kv_put(&store, &kv_key, &push_kv).await {
                                warn!(key = %kv_key, error = %e, "stats KV relay put failed");
                            }
                        });
                    }
                }
                let ws = stats_ws_res(push.clone());
                let sessions = {
                    let mut guard = relay_arc.lock().await;
                    guard.last_stats.insert(key, push);
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
    let mut sub_user = match nats.subscribe("c35.user.*.ev.>").await {
        Ok(s) => s,
        Err(e) => {
            warn!("[c35:admin] event nats subscribe user: {e}");
            return;
        }
    };
    let mut sub_scoped = match nats.subscribe("c35.ev.>").await {
        Ok(s) => s,
        Err(e) => {
            warn!("[c35:admin] event nats subscribe scoped: {e}");
            return;
        }
    };
    loop {
        tokio::select! {
            _ = cancel.cancelled() => break,
            msg = sub_user.next() => {
                if !fanout_event_msg(relay_arc.clone(), msg).await {
                    break;
                }
            }
            msg = sub_scoped.next() => {
                if !fanout_event_msg(relay_arc.clone(), msg).await {
                    break;
                }
            }
        }
    }
}

async fn fanout_event_msg(relay_arc: Arc<Mutex<AdminRelay>>, msg: Option<async_nats::Message>) -> bool {
    let Some(msg) = msg else { return false };
    let Ok(push) = EventPush::decode(msg.payload.as_ref()) else { return true };
    let Some(ev) = push.event.as_ref() else { return true };
    let owner = ev.owner_iid;
    let log_push = LogPush {
        row: Some(event_row_to_log(ev)),
    };
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
        body: Some(ws_res::Body::LogPush(log_push)),
    };
    for tx in sessions {
        let _ = tx.send(ws.clone());
    }
    true
}

fn event_row_to_log(ev: &Event) -> Log {
    let kind = if ev.class == "error" {
        "error".to_string()
    } else {
        "conn".to_string()
    };
    Log {
        id: ev.id,
        owner_iid: ev.owner_iid,
        kind,
        topic: ev.slug.clone(),
        dv: ev.dv.clone(),
        req_id: String::new(),
        chat_id: 0,
        task_id: 0,
        device_iid: 0,
        text: ev.text.clone(),
        model: String::new(),
        tokens_in: 0,
        tokens_out: 0,
        duration_ms: 0,
        cost_usd: 0.0,
        meta_json: ev.meta_json.clone(),
        created_ts_ms: ev.created_ts_ms,
        updated_ts_ms: ev.created_ts_ms,
        deleted_ts_ms: 0,
        event_kind: ev.event_kind.clone(),
        class: ev.class.clone(),
        subject: ev.subject.clone(),
    }
}

fn stats_ws_res(push: StatsPush) -> WsRes {
    WsRes {
        req_id: String::new(),
        body: Some(ws_res::Body::StatsPush(push)),
    }
}

fn stats_push_subject_key(push: &StatsPush) -> String {
    match &push.body {
        Some(stats_push::Body::Node(n)) => format!("c35.stats.node.{}", n.node_name),
        Some(stats_push::Body::Volume(v)) => {
            format!("c35.stats.volume.{}.{}.{}", v.node_name, v.namespace, v.pvc_name)
        }
        Some(stats_push::Body::Pod(p)) => {
            format!("c35.stats.pod.{}.{}.{}", p.node_name, p.namespace, p.pod_name)
        }
        None => String::new(),
    }
}
