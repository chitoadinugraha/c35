//! L1 in-process owner prompt session (billing, bundles, chat LRU, continuity).

mod billing;
mod bundle_wait;
mod chat_cache;
mod continuity;
mod live_hydrate;
mod registry;
mod state;
mod trace;
mod warm;

pub use billing::{owner_session_apply_billing_cached, session_billing_snapshot};
pub use bundle_wait::{
    owner_session_bundle_ready, owner_session_ensure_owner_warm, owner_session_wait_owner_bundle,
    owner_session_wait_owner_bundle_traced,
};
pub use chat_cache::{
    chat_cache_append_turn, chat_cache_prefetch, chat_cache_wait_ready, chat_cache_warm, chat_cache_warm_state,
    session_max_chats, session_owner_bundle_wait_mcp_ms, session_owner_bundle_wait_ms, session_warm_wait_ms,
    ChatFocusCache, ChatLru,
};
pub use continuity::{TurnContinuity, TURN_CONTINUITY_INITIAL};
pub use live_hydrate::{
    live_hydrate_from_session, owner_session_prepare_for_live, session_live_bundle_wait_ms,
    LiveOwnerHydrate,
};
pub use registry::{
    owner_session_attach_for_live, owner_session_attach_for_prompt, owner_session_bind_ws,
    owner_session_get,
    owner_session_register_warmup_for_session, owner_session_supersede, owner_session_teardown,
    session_max_memory_items, OwnerSessionConnection, OwnerSessionRegistry,
};
pub use state::{OwnerPromptSession, OwnerSessionState, WarmState};
pub use trace::session_warmup_trace_put;
pub use warm::owner_session_warm_owner_bundle;

use std::sync::Arc;
use std::time::Duration;

use async_nats::Client;
use sqlx::PgPool;

/// Focus a chat: update LRU, start history warmup.
pub async fn session_focus_chat(
    pool: &PgPool,
    nats: Option<&Client>,
    session: Arc<OwnerPromptSession>,
    chat_id: i64,
    last_seen_msg_id: i64,
) -> anyhow::Result<u64> {
    if session.is_superseded() {
        anyhow::bail!("session superseded");
    }
    let owner_iid = session.owner_iid;
    let row = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT id FROM ai.chat
        WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL
        "#,
    )
    .bind(chat_id)
    .bind(owner_iid)
    .fetch_optional(pool)
    .await?;
    if row.is_none() {
        anyhow::bail!("chat not owned by session owner");
    }

    session.on_focus_chat(chat_id);
    {
        let mut st = session.write_state();
        st.chats.touch(chat_id);
    }

    let pool = pool.clone();
    let nats = nats.cloned();
    chat_cache_warm(
        session.clone(),
        pool,
        nats,
        chat_id,
        last_seen_msg_id,
        |h| owner_session_register_warmup_for_session(&session, h),
    );

    Ok(session.bump_revision())
}

/// Wait for chat cache warmup with default env timeout.
pub async fn session_focus_wait_ready(session: &OwnerPromptSession, chat_id: i64) -> WarmState {
    chat_cache_wait_ready(
        session,
        chat_id,
        Duration::from_millis(session_warm_wait_ms()),
    )
    .await
}

/// L1 session for a prompt turn: reuse app WS cache when co-located, else warm headless on this pod.
pub async fn owner_session_prepare_prompt_turn(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    chat_id: i64,
) -> Arc<OwnerPromptSession> {
    let (session, _new_headless) = owner_session_attach_for_prompt(owner_iid);
    owner_session_ensure_owner_warm(pool, nats, session.clone());
    if chat_id > 0 && !session.is_superseded() {
        let _ = session_focus_chat(pool, nats, session.clone(), chat_id, 0).await;
    }
    session
}
