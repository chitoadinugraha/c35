use std::sync::{Arc, LazyLock, Mutex};

use c35_proto::{SessionSuperseded, WsRes, ws_res};
use dashmap::DashMap;
use tokio::sync::mpsc;
use tokio::task::AbortHandle;

use super::chat_cache::session_max_chats;
use super::state::OwnerPromptSession;

pub fn session_max_memory_items() -> usize {
    std::env::var("C35_SESSION_MAX_MEMORY_ITEMS")
        .ok()
        .and_then(|s| s.parse().ok())
        .filter(|n| *n > 0)
        .unwrap_or(64)
}

struct SessionEntry {
    conn_id: String,
    session: Arc<OwnerPromptSession>,
    warmups: Mutex<Vec<AbortHandle>>,
    ws_tx: Mutex<Option<mpsc::UnboundedSender<WsRes>>>,
}

pub struct OwnerSessionRegistry {
    by_owner: DashMap<i64, SessionEntry>,
    conn_owner: DashMap<String, i64>,
}

impl OwnerSessionRegistry {
    pub fn new() -> Self {
        Self {
            by_owner: DashMap::new(),
            conn_owner: DashMap::new(),
        }
    }

    fn abort_warmups(entry: &SessionEntry) {
        let mut handles = entry.warmups.lock().expect("warmup handles poisoned");
        for h in handles.drain(..) {
            h.abort();
        }
    }

    fn register_warmup(entry: &SessionEntry, handle: AbortHandle) {
        let mut handles = entry.warmups.lock().expect("warmup handles poisoned");
        handles.retain(|h| !h.is_finished());
        handles.push(handle);
    }
}

static GLOBAL_REGISTRY: LazyLock<OwnerSessionRegistry> = LazyLock::new(OwnerSessionRegistry::new);

pub fn owner_session_registry() -> &'static OwnerSessionRegistry {
    &GLOBAL_REGISTRY
}

fn ensure_chat_lru_cap(session: &OwnerPromptSession) {
    let max = session_max_chats();
    let mut st = session.write_state();
    if st.chats.max != max {
        st.chats.max = max;
    }
}

fn notify_session_superseded(old: &SessionEntry) {
    let revision = old.session.revision();
    if let Some(tx) = old.ws_tx.lock().expect("ws_tx poisoned").take() {
        let _ = tx.send(WsRes {
            req_id: String::new(),
            body: Some(ws_res::Body::SessionSuperseded(SessionSuperseded {
                reason: "superseded".into(),
                revision,
            })),
        });
    }
}

/// Replace any existing session for this owner; abort prior warmups.
pub fn owner_session_supersede(owner_iid: i64, conn_id: String) -> Arc<OwnerPromptSession> {
    let registry = owner_session_registry();
    if let Some((_, old)) = registry.by_owner.remove(&owner_iid) {
        notify_session_superseded(&old);
        old.session.mark_superseded();
        OwnerSessionRegistry::abort_warmups(&old);
        registry.conn_owner.remove(&old.conn_id);
    }

    let session = Arc::new(OwnerPromptSession::new(owner_iid, conn_id.clone()));
    ensure_chat_lru_cap(&session);
    let entry = SessionEntry {
        conn_id: conn_id.clone(),
        session: session.clone(),
        warmups: Mutex::new(Vec::new()),
        ws_tx: Mutex::new(None),
    };
    registry.by_owner.insert(owner_iid, entry);
    registry.conn_owner.insert(conn_id, owner_iid);
    session
}

pub fn owner_session_get(owner_iid: i64) -> Option<Arc<OwnerPromptSession>> {
    owner_session_registry()
        .by_owner
        .get(&owner_iid)
        .and_then(|e| {
            if e.session.is_superseded() {
                None
            } else {
                Some(e.session.clone())
            }
        })
}

/// Active app WS session when this pod has one; otherwise a headless session for prompt/MCP on this pod.
/// Never replaces an existing live session (app wins over MCP-only attach).
pub fn owner_session_attach_for_prompt(owner_iid: i64) -> (Arc<OwnerPromptSession>, bool) {
    if let Some(session) = owner_session_get(owner_iid) {
        return (session, false);
    }
    let conn_id = format!("headless-prompt-{owner_iid}");
    let session = owner_session_supersede(owner_iid, conn_id);
    (session, true)
}

pub fn owner_session_bind_ws(owner_iid: i64, tx: mpsc::UnboundedSender<WsRes>) {
    let registry = owner_session_registry();
    if let Some(entry) = registry.by_owner.get(&owner_iid) {
        if entry.session.is_superseded() {
            return;
        }
        *entry.ws_tx.lock().expect("ws_tx poisoned") = Some(tx);
    }
}

/// Tear down the session owned by `conn_id` (WS close).
pub fn owner_session_teardown(conn_id: &str) {
    let registry = owner_session_registry();
    let owner_iid = match registry.conn_owner.remove(conn_id) {
        Some((_conn, id)) => id,
        None => return,
    };
    let entry = match registry.by_owner.remove(&owner_iid) {
        Some((_k, e)) => e,
        None => return,
    };
    if entry.conn_id != conn_id {
        return;
    }
    entry.session.mark_superseded();
    OwnerSessionRegistry::abort_warmups(&entry);
}

pub fn owner_session_register_warmup(owner_iid: i64, handle: AbortHandle) {
    let registry = owner_session_registry();
    if let Some(entry) = registry.by_owner.get(&owner_iid) {
        OwnerSessionRegistry::register_warmup(&entry, handle);
    }
}

pub fn owner_session_register_warmup_for_session(session: &OwnerPromptSession, handle: AbortHandle) {
    owner_session_register_warmup(session.owner_iid, handle);
}

/// Calls [`owner_session_teardown`] when dropped (WS connection guard).
pub struct OwnerSessionConnection {
    conn_id: String,
    teardown_on_drop: bool,
}

impl OwnerSessionConnection {
    pub fn new(conn_id: String) -> Self {
        Self {
            conn_id,
            teardown_on_drop: true,
        }
    }

    pub fn conn_id(&self) -> &str {
        &self.conn_id
    }

    pub fn disable_teardown_on_drop(&mut self) {
        self.teardown_on_drop = false;
    }
}

impl Drop for OwnerSessionConnection {
    fn drop(&mut self) {
        if self.teardown_on_drop {
            owner_session_teardown(&self.conn_id);
        }
    }
}
