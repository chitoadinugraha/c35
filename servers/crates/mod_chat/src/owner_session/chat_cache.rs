use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;

use async_nats::Client;
use sqlx::PgPool;
use tokio::sync::Notify;
use tokio::task::AbortHandle;
use tracing::warn;

use crate::context_compact::{history_prefetch, HistoryPrefetch};
use crate::context_pack::HistoryRow;

use super::state::{OwnerPromptSession, WarmState};

pub fn session_max_chats() -> usize {
    std::env::var("C35_SESSION_MAX_CHATS")
        .ok()
        .and_then(|s| s.parse().ok())
        .filter(|n| *n > 0)
        .unwrap_or(8)
}

pub fn session_warm_wait_ms() -> u64 {
    std::env::var("C35_SESSION_WARM_WAIT_MS")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(150)
}

/// Max wait for owner billing/memory/scope bundle before prompt_turn clock (WS path).
pub fn session_owner_bundle_wait_ms() -> u64 {
    std::env::var("C35_SESSION_OWNER_BUNDLE_WAIT_MS")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(150)
}

/// MCP / headless: wait for bundle outside prompt trace (does not count in trace_stages).
pub fn session_owner_bundle_wait_mcp_ms() -> u64 {
    std::env::var("C35_SESSION_MCP_BUNDLE_WAIT_MS")
        .ok()
        .and_then(|s| s.parse().ok())
        .or_else(|| {
            std::env::var("C35_SESSION_OWNER_BUNDLE_WAIT_MS")
                .ok()
                .and_then(|s| s.parse().ok())
        })
        .unwrap_or(30_000)
}

pub struct ChatFocusCache {
    pub warm: WarmState,
    pub prefetch: Option<HistoryPrefetch>,
    pub last_user_msg_id: i64,
    pub bound_device_iid: Option<i64>,
    pub warm_error: Option<String>,
    ready: Arc<Notify>,
}

impl Default for ChatFocusCache {
    fn default() -> Self {
        Self {
            warm: WarmState::Absent,
            prefetch: None,
            last_user_msg_id: 0,
            bound_device_iid: None,
            warm_error: None,
            ready: Arc::new(Notify::new()),
        }
    }
}

impl ChatFocusCache {
    fn notify_ready(&self) {
        self.ready.notify_waiters();
    }
}

pub struct ChatLru {
    pub max: usize,
    order: Vec<i64>,
    entries: HashMap<i64, ChatFocusCache>,
}

impl Default for ChatLru {
    fn default() -> Self {
        Self::new(session_max_chats())
    }
}

impl ChatLru {
    pub fn new(max: usize) -> Self {
        Self {
            max: max.max(1),
            order: Vec::new(),
            entries: HashMap::new(),
        }
    }

    pub fn len(&self) -> usize {
        self.entries.len()
    }

    pub fn touch(&mut self, chat_id: i64) -> &mut ChatFocusCache {
        if let Some(pos) = self.order.iter().position(|&id| id == chat_id) {
            let id = self.order.remove(pos);
            self.order.insert(0, id);
        } else {
            self.order.insert(0, chat_id);
            if self.order.len() > self.max {
                if let Some(evict) = self.order.pop() {
                    self.entries.remove(&evict);
                }
            }
            self.entries.entry(chat_id).or_default();
        }
        self.entries.get_mut(&chat_id).expect("chat lru entry")
    }

    pub fn get(&mut self, chat_id: i64) -> Option<&mut ChatFocusCache> {
        if !self.entries.contains_key(&chat_id) {
            return None;
        }
        self.touch(chat_id);
        self.entries.get_mut(&chat_id)
    }

    pub fn get_readonly(&self, chat_id: i64) -> Option<&ChatFocusCache> {
        self.entries.get(&chat_id)
    }

    pub fn eviction_order(&self) -> Vec<i64> {
        let mut v: Vec<i64> = self.order.clone();
        v.reverse();
        v
    }
}

pub fn chat_cache_warm_state(session: &OwnerPromptSession, chat_id: i64) -> WarmState {
    session
        .read_state()
        .chats
        .get_readonly(chat_id)
        .map(|c| c.warm)
        .unwrap_or(WarmState::Absent)
}

pub fn chat_cache_warm(
    session: Arc<OwnerPromptSession>,
    pool: PgPool,
    _nats: Option<Client>,
    chat_id: i64,
    user_msg_id: i64,
    register_abort: impl FnOnce(AbortHandle),
) {
    let need_spawn = {
        let mut st = session.write_state();
        let entry = st.chats.touch(chat_id);
        entry.last_user_msg_id = user_msg_id;
        match entry.warm {
            WarmState::Ready | WarmState::Loading => false,
            WarmState::Absent | WarmState::Failed => {
                entry.warm = WarmState::Loading;
                entry.prefetch = None;
                entry.warm_error = None;
                true
            }
        }
    };
    if !need_spawn {
        return;
    }

    let handle = tokio::spawn(async move {
        let result = history_prefetch(&pool, chat_id, user_msg_id).await;
        let mut st = session.write_state();
        let entry = st.chats.touch(chat_id);
        match result {
            Ok(prefetch) => {
                entry.prefetch = Some(prefetch);
                entry.warm = WarmState::Ready;
                entry.warm_error = None;
            }
            Err(e) => {
                warn!(
                    "[c35:owner_session] chat_cache_warm chat_id={chat_id} owner_iid={}: {e:#}",
                    session.owner_iid
                );
                entry.warm = WarmState::Failed;
                entry.warm_error = Some(e.to_string());
            }
        }
        entry.notify_ready();
        session.bump_revision();
    });
    register_abort(handle.abort_handle());
}

pub async fn chat_cache_wait_ready(
    session: &OwnerPromptSession,
    chat_id: i64,
    max_wait: Duration,
) -> WarmState {
    let notify = {
        let st = session.read_state();
        st.chats
            .get_readonly(chat_id)
            .map(|c| (c.warm, c.ready.clone()))
    };
    let Some((mut state, notify)) = notify else {
        return WarmState::Absent;
    };
    if state == WarmState::Ready || state == WarmState::Failed {
        return state;
    }
    if state != WarmState::Loading {
        return state;
    }
    let deadline = tokio::time::Instant::now() + max_wait;
    while tokio::time::Instant::now() < deadline {
        let remaining = deadline.saturating_duration_since(tokio::time::Instant::now());
        tokio::select! {
            _ = notify.notified() => {},
            _ = tokio::time::sleep(remaining.min(Duration::from_millis(10))) => {
                let st = session.read_state();
                state = st
                    .chats
                    .get_readonly(chat_id)
                    .map(|c| c.warm)
                    .unwrap_or(WarmState::Absent);
                if state != WarmState::Loading {
                    return state;
                }
            }
        }
        let st = session.read_state();
        state = st
            .chats
            .get_readonly(chat_id)
            .map(|c| c.warm)
            .unwrap_or(WarmState::Absent);
        if state != WarmState::Loading {
            return state;
        }
    }
    session
        .read_state()
        .chats
        .get_readonly(chat_id)
        .map(|c| c.warm)
        .unwrap_or(WarmState::Absent)
}

pub fn chat_cache_prefetch(session: &OwnerPromptSession, chat_id: i64) -> Option<HistoryPrefetch> {
    session
        .read_state()
        .chats
        .get_readonly(chat_id)
        .and_then(|c| {
            if c.warm == WarmState::Ready {
                c.prefetch.clone()
            } else {
                None
            }
        })
}

/// Append completed turn rows to the in-memory prefetch tail (best-effort).
pub fn chat_cache_append_turn(
    session: &OwnerPromptSession,
    chat_id: i64,
    user_row: HistoryRow,
    assistant_row: HistoryRow,
) {
    let mut st = session.write_state();
    let entry = st.chats.touch(chat_id);
    entry.last_user_msg_id = user_row.id;
    if let Some(ref mut prefetch) = entry.prefetch {
        prefetch.rows.push(user_row);
        prefetch.rows.push(assistant_row);
        entry.warm = WarmState::Ready;
    }
    session.bump_revision();
}

