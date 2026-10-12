use std::sync::Arc;
use std::time::Duration;

use async_nats::Client;
use c35_nats::BillingGateCached;
use c35_proto::{ScopeInstructionBundle, UserMemoryBundle};
use sqlx::PgPool;

use crate::prompt::user_context::UserPromptContext;

use super::billing::session_billing_snapshot;
use super::bundle_wait::owner_session_wait_owner_bundle_traced;
use super::registry::owner_session_attach_for_live;
use super::state::OwnerPromptSession;

/// L1 fields reused by Live Call setup (no chat continuity / LRU in v1).
#[derive(Debug, Clone)]
pub struct LiveOwnerHydrate {
    pub user_ctx: UserPromptContext,
    pub memory: Option<UserMemoryBundle>,
    pub scope: Option<ScopeInstructionBundle>,
    pub billing: Option<BillingGateCached>,
    pub session_cache_hit: bool,
    pub bundle_wait_ms: u64,
}

pub fn session_live_bundle_wait_ms() -> u64 {
    std::env::var("C35_LIVE_BUNDLE_WAIT_MS")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(5_000)
}

pub fn live_hydrate_from_session(session: &OwnerPromptSession) -> LiveOwnerHydrate {
    let st = session.read_state();
    LiveOwnerHydrate {
        user_ctx: st.user_ctx.clone(),
        memory: st.memory.clone(),
        scope: st.scope.clone(),
        billing: st.billing.clone(),
        session_cache_hit: false,
        bundle_wait_ms: 0,
    }
}

/// Attach or reuse owner L1, warm bundle, wait (traced outside prompt), return hydrate snapshot.
pub async fn owner_session_prepare_for_live(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    req_id: &str,
) -> (Arc<OwnerPromptSession>, LiveOwnerHydrate) {
    let (session, _new_headless) = owner_session_attach_for_live(owner_iid);
    let bundle_wait_ms = owner_session_wait_owner_bundle_traced(
        pool,
        nats,
        session.clone(),
        owner_iid,
        req_id,
        Duration::from_millis(session_live_bundle_wait_ms()),
    )
    .await;
    let mut hydrate = live_hydrate_from_session(&session);
    hydrate.bundle_wait_ms = bundle_wait_ms;
    hydrate.session_cache_hit = session_billing_snapshot(&session).is_some();
    (session, hydrate)
}
