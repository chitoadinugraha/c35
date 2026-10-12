//! In-process bot channel prompt cache (per owner + bot): warm owner billing KV and memory bundle.

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, LazyLock, RwLock};

use async_nats::Client;
use c35_mod_billing::{billing_cache_get, billing_cache_warmup};
use c35_nats::BillingGateCached;
use dashmap::DashMap;
use sqlx::PgPool;

use crate::memory::memory_bundle_warmup;
use crate::tools::http_client;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct BotKey {
    owner_iid: i64,
    bot_iid: i64,
}

pub struct BotSessionState {
    billing: RwLock<Option<BillingGateCached>>,
    warming: AtomicBool,
    warmed: AtomicBool,
}

impl BotSessionState {
    fn new() -> Self {
        Self {
            billing: RwLock::new(None),
            warming: AtomicBool::new(false),
            warmed: AtomicBool::new(false),
        }
    }

    pub fn billing_snapshot(&self) -> Option<BillingGateCached> {
        self.billing.read().ok()?.clone()
    }

    fn set_billing(&self, entry: BillingGateCached) {
        if let Ok(mut g) = self.billing.write() {
            *g = Some(entry);
        }
    }

    /// Returns true if this call should spawn the warmup task.
    fn start_warmup_if_needed(&self) -> bool {
        if self.warmed.load(Ordering::Acquire) {
            return false;
        }
        if self.warming.swap(true, Ordering::AcqRel) {
            return false;
        }
        true
    }

    fn mark_warm_complete(&self) {
        self.warmed.store(true, Ordering::Release);
        self.warming.store(false, Ordering::Release);
    }
}

pub struct BotPromptRuntime {
    sessions: DashMap<BotKey, Arc<BotSessionState>>,
}

impl BotPromptRuntime {
    pub fn new() -> Self {
        Self {
            sessions: DashMap::new(),
        }
    }

    fn get_state(&self, owner_iid: i64, bot_iid: i64) -> Option<Arc<BotSessionState>> {
        self.sessions
            .get(&BotKey {
                owner_iid,
                bot_iid,
            })
            .map(|e| e.value().clone())
    }
}

static BOT_RUNTIME: LazyLock<BotPromptRuntime> = LazyLock::new(BotPromptRuntime::new);

pub fn bot_prompt_runtime() -> &'static BotPromptRuntime {
    &BOT_RUNTIME
}

pub fn bot_session_billing_snapshot(owner_iid: i64, bot_iid: i64) -> Option<BillingGateCached> {
    bot_prompt_runtime()
        .get_state(owner_iid, bot_iid)
        .and_then(|s| s.billing_snapshot())
}

/// First channel turn for `(owner_iid, bot_iid)` kicks off billing + memory bundle warmup (single flight).
pub fn bot_session_on_turn(
    pool: PgPool,
    nats: Option<Client>,
    owner_iid: i64,
    bot_iid: i64,
) {
    if owner_iid <= 0 || bot_iid <= 0 {
        return;
    }
    let key = BotKey {
        owner_iid,
        bot_iid,
    };
    let state = bot_prompt_runtime()
        .sessions
        .entry(key)
        .or_insert_with(|| Arc::new(BotSessionState::new()))
        .clone();
    if !state.start_warmup_if_needed() {
        return;
    }
    tokio::spawn(async move {
        let http = http_client(std::time::Duration::from_secs(30));
        billing_cache_warmup(&pool, nats.as_ref(), owner_iid).await;
        memory_bundle_warmup(&pool, nats.as_ref(), &http, owner_iid, Some(bot_iid)).await;
        if let Some(entry) = billing_cache_get(nats.as_ref(), owner_iid).await {
            state.set_billing(entry);
        }
        state.mark_warm_complete();
    });
}
