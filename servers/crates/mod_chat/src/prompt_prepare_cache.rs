//! Connect-time warmup and disconnect-grace lifecycle for memory / scope-instruction NATS KV bundles.

use async_nats::Client;
use c35_nats::{
    memory_bundle_delete, memory_bundle_kv_ensure, prompt_bundle_disconnect_grace_secs,
    prompt_bundle_session_get, prompt_bundle_session_kv_ensure, prompt_bundle_session_put,
    scope_inst_bundle_delete, scope_inst_kv_ensure, PromptBundleSession,
};
use sqlx::PgPool;
use tracing::warn;

use crate::memory::memory_bundle_warmup;
use crate::scope_instruction::scope_instruction_warm_owner_bundle;
use crate::tools::http_client;

/// Call when a Home app WebSocket session is accepted (after auth).
pub async fn prompt_prepare_cache_on_connect(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
) {
    if owner_iid <= 0 {
        return;
    }
    let Some(client) = nats else {
        return;
    };
    if let Err(e) = prompt_prepare_cache_session_connect(client, owner_iid).await {
        warn!("[c35:prompt_cache] session connect owner_iid={owner_iid}: {e:#}");
    }
    prompt_prepare_cache_purge_if_expired(Some(client), owner_iid).await;
    let http = http_client(std::time::Duration::from_secs(60));
    tokio::join!(
        memory_bundle_warmup(pool, Some(client), &http, owner_iid, None),
        scope_instruction_warm_owner_bundle(pool, Some(client), owner_iid),
    );
}

/// Call when the WebSocket session ends (cluster-wide connection count is in NATS KV).
pub async fn prompt_prepare_cache_on_disconnect(nats: Option<&Client>, owner_iid: i64) {
    if owner_iid <= 0 {
        return;
    }
    let Some(client) = nats else {
        return;
    };
    if let Err(e) = prompt_prepare_cache_session_disconnect(client, owner_iid).await {
        warn!("[c35:prompt_cache] session disconnect owner_iid={owner_iid}: {e:#}");
    }
}

async fn prompt_prepare_cache_session_connect(client: &Client, owner_iid: i64) -> anyhow::Result<()> {
    let store = prompt_bundle_session_kv_ensure(client).await?;
    let mut session = prompt_bundle_session_get(&store, owner_iid).await;
    session.connections = session.connections.saturating_add(1);
    session.purge_after_ms = 0;
    prompt_bundle_session_put(&store, owner_iid, session).await?;
    Ok(())
}

async fn prompt_prepare_cache_session_disconnect(client: &Client, owner_iid: i64) -> anyhow::Result<()> {
    let store = prompt_bundle_session_kv_ensure(client).await?;
    let mut session = prompt_bundle_session_get(&store, owner_iid).await;
    session.connections = session.connections.saturating_sub(1);
    if session.connections == 0 {
        let grace_ms = (prompt_bundle_disconnect_grace_secs() as i64) * 1000;
        session.purge_after_ms = chrono::Utc::now().timestamp_millis() + grace_ms;
    }
    prompt_bundle_session_put(&store, owner_iid, session).await?;
    Ok(())
}

/// If the user has been disconnected past the grace window, drop KV bundles before a cold rebuild.
pub async fn prompt_prepare_cache_purge_if_expired(nats: Option<&Client>, owner_iid: i64) {
    let Some(client) = nats else {
        return;
    };
    let store = match prompt_bundle_session_kv_ensure(client).await {
        Ok(s) => s,
        Err(e) => {
            warn!("[c35:prompt_cache] session kv: {e:#}");
            return;
        }
    };
    let session = prompt_bundle_session_get(&store, owner_iid).await;
    if session.connections > 0 {
        return;
    }
    if session.purge_after_ms <= 0 {
        return;
    }
    let now = chrono::Utc::now().timestamp_millis();
    if now < session.purge_after_ms {
        return;
    }
    if let Ok(mem) = memory_bundle_kv_ensure(client).await {
        let _ = memory_bundle_delete(&mem, owner_iid, None).await;
    }
    if let Ok(scope) = scope_inst_kv_ensure(client).await {
        let _ = scope_inst_bundle_delete(&scope, owner_iid).await;
    }
    let cleared = PromptBundleSession {
        connections: 0,
        purge_after_ms: 0,
    };
    let _ = prompt_bundle_session_put(&store, owner_iid, cleared).await;
}
