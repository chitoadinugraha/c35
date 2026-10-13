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

        let (
            (_, bill_started, bill_ms),
            (_, mem_started, mem_ms),
            (_, scope_started, scope_ms),
            (user_ctx, ctx_started, ctx_ms),
        ) = tokio::join!(
            timed(billing_cache_warmup(&pool, nats_cloned.as_ref(), owner_iid)),
            timed(memory_bundle_warmup(&pool, nats_cloned.as_ref(), &http, owner_iid, None)),
            timed(scope_instruction_warm_owner_bundle(&pool, nats_cloned.as_ref(), owner_iid)),
            timed(user_prompt_context_get(&pool, owner_iid)),
        );
        clock.par("billing_warmup", "Billing warmup", bill_started, bill_ms);
        clock.par("memory_warmup", "Memory warmup", mem_started, mem_ms);
        clock.par("scope_warmup", "Scope warmup", scope_started, scope_ms);
        clock.par("user_ctx", "User context", ctx_started, ctx_ms);

        if session.is_superseded() {
            session.notify_ready();
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
        session.notify_ready();
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
