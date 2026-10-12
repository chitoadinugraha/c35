use std::sync::Arc;
use std::time::Instant;

use async_nats::Client;
use c35_mod_billing::{billing_cache_get, billing_cache_warmup};
use c35_nats::{memory_bundle_get, memory_bundle_kv_ensure, scope_inst_bundle_get, scope_inst_kv_ensure};
use sqlx::PgPool;
use tokio::task::AbortHandle;
use tracing::warn;

use crate::memory::memory_bundle_warmup;
use crate::prompt::user_context::user_prompt_context_get;
use crate::scope_instruction::scope_instruction_warm_owner_bundle;
use crate::tools::http_client;
use crate::turn_tracer::{timed, StageClock};

use super::registry::session_max_memory_items;
use super::state::OwnerPromptSession;
use super::trace::session_warmup_trace_put;

pub async fn owner_session_warm_owner_bundle(
    pool: &PgPool,
    nats: Option<&Client>,
    session: Arc<OwnerPromptSession>,
    register_abort: impl Fn(AbortHandle),
) {
    if session.is_superseded() {
        return;
    }
    let owner_iid = session.owner_iid;
    let conn_id = session.conn_id.clone();
    let run_id = format!("{}", chrono::Utc::now().timestamp_millis());
    let pool = pool.clone();
    let nats_cloned = nats.cloned();

    let handle = tokio::spawn(async move {
        let started = Instant::now();
        let mut clock = StageClock::new(started);
        let http = http_client(std::time::Duration::from_secs(60));

        let (_, bill_started, _) = timed(async {
            billing_cache_warmup(&pool, nats_cloned.as_ref(), owner_iid).await;
        })
        .await;
        clock.seq("billing_warmup", "Billing warmup", bill_started);

        let (_, mem_started, _) = timed(async {
            memory_bundle_warmup(&pool, nats_cloned.as_ref(), &http, owner_iid, None).await;
        })
        .await;
        clock.seq("memory_warmup", "Memory warmup", mem_started);

        let (_, scope_started, _) = timed(async {
            scope_instruction_warm_owner_bundle(&pool, nats_cloned.as_ref(), owner_iid).await;
        })
        .await;
        clock.seq("scope_warmup", "Scope warmup", scope_started);

        let (user_ctx, ctx_started, _) =
            timed(async { user_prompt_context_get(&pool, owner_iid).await }).await;
        clock.seq("user_ctx", "User context", ctx_started);

        if session.is_superseded() {
            let duration_ms = started.elapsed().as_millis() as i64;
            session_warmup_trace_put(
                &pool,
                nats_cloned.as_ref(),
                owner_iid,
                &conn_id,
                &run_id,
                duration_ms,
                &clock,
                true,
            )
            .await;
            return;
        }

        let billing = if let Some(client) = nats_cloned.as_ref() {
            billing_cache_get(Some(client), owner_iid).await
        } else {
            None
        };
        let memory = if let Some(client) = nats_cloned.as_ref() {
            if let Ok(store) = memory_bundle_kv_ensure(client).await {
                memory_bundle_get(&store, owner_iid, None).await
            } else {
                None
            }
        } else {
            None
        };
        if let Some(bundle) = &memory {
            let item_count = bundle.items.len();
            let max_items = session_max_memory_items();
            if item_count > max_items {
                warn!(
                    "[c35:owner_session] memory bundle items={item_count} exceeds cap={max_items} owner_iid={owner_iid}"
                );
            }
        }
        let scope = if let Some(client) = nats_cloned.as_ref() {
            if let Ok(store) = scope_inst_kv_ensure(client).await {
                scope_inst_bundle_get(&store, owner_iid).await
            } else {
                None
            }
        } else {
            None
        };

        {
            let mut st = session.write_state();
            st.user_ctx = user_ctx;
            st.billing = billing;
            st.memory = memory;
            st.scope = scope;
        }

        session.bump_revision();
        let duration_ms = started.elapsed().as_millis() as i64;
        let cancelled = session.is_superseded();
        session_warmup_trace_put(
            &pool,
            nats_cloned.as_ref(),
            owner_iid,
            &conn_id,
            &run_id,
            duration_ms,
            &clock,
            cancelled,
        )
        .await;
    });
    register_abort(handle.abort_handle());
}
