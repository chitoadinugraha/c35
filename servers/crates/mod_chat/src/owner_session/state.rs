use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::RwLock;

use c35_nats::BillingGateCached;
use c35_proto::{ScopeInstructionBundle, UserMemoryBundle};

use crate::prompt::user_context::UserPromptContext;

use super::chat_cache::ChatLru;
use super::continuity::TurnContinuity;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WarmState {
    Absent,
    Loading,
    Ready,
    Failed,
}

/// In-memory owner bundle (L1); mirrors NATS KV when warm.
#[derive(Default)]
pub struct OwnerSessionState {
    pub billing: Option<BillingGateCached>,
    pub memory: Option<UserMemoryBundle>,
    pub scope: Option<ScopeInstructionBundle>,
    pub user_ctx: UserPromptContext,
    pub chats: ChatLru,
    pub focused_chat_id: i64,
    pub continuity: HashMap<i64, TurnContinuity>,
}

pub struct OwnerPromptSession {
    pub owner_iid: i64,
    pub conn_id: String,
    state: RwLock<OwnerSessionState>,
    revision: AtomicU64,
    superseded: AtomicBool,
    /// Owner-bundle warmup task started (WS connect or headless attach).
    owner_warm_spawned: AtomicBool,
}

impl OwnerPromptSession {
    pub fn new(owner_iid: i64, conn_id: String) -> Self {
        Self {
            owner_iid,
            conn_id,
            state: RwLock::new(OwnerSessionState::default()),
            revision: AtomicU64::new(0),
            superseded: AtomicBool::new(false),
            owner_warm_spawned: AtomicBool::new(false),
        }
    }

    pub fn owner_warm_spawned(&self) -> bool {
        self.owner_warm_spawned.load(Ordering::Acquire)
    }

    pub fn mark_owner_warm_spawned(&self) -> bool {
        self.owner_warm_spawned
            .compare_exchange(false, true, Ordering::AcqRel, Ordering::Acquire)
            .is_ok()
    }

    pub fn is_superseded(&self) -> bool {
        self.superseded.load(Ordering::Acquire)
    }

    pub fn mark_superseded(&self) {
        self.superseded.store(true, Ordering::Release);
    }

    pub fn bump_revision(&self) -> u64 {
        self.revision.fetch_add(1, Ordering::AcqRel) + 1
    }

    pub fn revision(&self) -> u64 {
        self.revision.load(Ordering::Acquire)
    }

    pub fn read_state(&self) -> std::sync::RwLockReadGuard<'_, OwnerSessionState> {
        self.state.read().expect("owner session state poisoned")
    }

    pub fn write_state(&self) -> std::sync::RwLockWriteGuard<'_, OwnerSessionState> {
        self.state.write().expect("owner session state poisoned")
    }

    pub fn continuity_for_chat(&self, chat_id: i64) -> TurnContinuity {
        self.read_state()
            .continuity
            .get(&chat_id)
            .cloned()
            .unwrap_or_default()
    }

    pub fn on_focus_chat(&self, chat_id: i64) {
        let mut st = self.write_state();
        st.focused_chat_id = chat_id;
    }
}
