use std::sync::Arc;
use std::time::{Duration, Instant};

use async_nats::Client;
use sqlx::PgPool;

use super::state::OwnerPromptSession;
use super::trace::session_bundle_wait_trace_put;
use super::warm::owner_session_warm_owner_bundle;
use super::registry::owner_session_register_warmup_for_session;

pub fn owner_session_bundle_ready(session: &OwnerPromptSession) -> bool {
    let st = session.read_state();
    st.billing.is_some() && st.memory.is_some() && st.scope.is_some()
}

/// Start owner-bundle warmup once (WS connect, headless MCP, or first prompt).
pub fn owner_session_ensure_owner_warm(
    pool: &PgPool,
    nats: Option<&Client>,
    session: Arc<OwnerPromptSession>,
) {
    if owner_session_bundle_ready(&session) || session.is_superseded() {
        return;
    }
    if !session.mark_owner_warm_spawned() {
        return;
    }
    let pool = pool.clone();
    let nats = nats.cloned();
    tokio::spawn(async move {
        owner_session_warm_owner_bundle(
            &pool,
            nats.as_ref(),
            session.clone(),
            |h| owner_session_register_warmup_for_session(&session, h),
        )
        .await;
    });
}

/// Block until L1 owner bundle is ready or timeout. Returns wait wall ms (0 if already ready).
pub async fn owner_session_wait_owner_bundle(
    session: &Arc<OwnerPromptSession>,
    max_wait: Duration,
) -> u64 {
    if owner_session_bundle_ready(session) {
        return 0;
    }
    let notify = session.ready_notify();
    let started = Instant::now();
    let deadline = started + max_wait;
    while Instant::now() < deadline {
        if session.is_superseded() || owner_session_bundle_ready(session) {
            break;
        }
        let remaining = deadline.saturating_duration_since(Instant::now());
        tokio::select! {
            _ = notify.notified() => {
                if session.is_superseded() || owner_session_bundle_ready(session) {
                    break;
                }
            }
            _ = tokio::time::sleep(remaining.min(Duration::from_millis(15))) => {
                if session.is_superseded() || owner_session_bundle_ready(session) {
                    break;
                }
            }
        }
    }
    started.elapsed().as_millis() as u64
}

/// Wait for bundle, log to ai.log outside prompt req trace when blocked.
pub async fn owner_session_wait_owner_bundle_traced(
    pool: &PgPool,
    nats: Option<&Client>,
    session: Arc<OwnerPromptSession>,
    owner_iid: i64,
    req_id: &str,
    max_wait: Duration,
) -> u64 {
    owner_session_ensure_owner_warm(pool, nats, session.clone());
    let waited = owner_session_wait_owner_bundle(&session, max_wait).await;
    if waited > 0 {
        session_bundle_wait_trace_put(
            pool,
            nats,
            owner_iid,
            req_id,
            waited,
            owner_session_bundle_ready(&session),
        )
        .await;
    }
    waited
}
