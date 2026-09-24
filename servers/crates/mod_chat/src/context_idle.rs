use std::time::Duration;

use anyhow::Result;
use async_trait::async_trait;
use c35_mod_billing::{billing_gate, billing_usage_report};
use c35_mod_fetch::{FetchOutcome, FetchTask};
use c35_store::snowflake_id;
use sqlx::PgPool;
use tracing::warn;

use crate::context_billing::ContextBillingExtra;
use crate::context_compact::{chat_context_load, context_compact, history_rows_load};
use crate::context_pack::CONTEXT_RECENT_MSG_MIN;
use crate::memory_extract::memory_extract_batch;
use crate::tools::http_client;

pub const CONTEXT_IDLE_MINUTES: i64 = 45;
pub const CONTEXT_IDLE_MIN_MSGS: i64 = 4;

fn transcript_from_rows(rows: &[crate::context_pack::HistoryRow]) -> String {
    rows.iter()
        .rev()
        .filter_map(|r| {
            let c = r.content.trim();
            if c.is_empty() {
                return None;
            }
            Some(format!("{}: {}", r.role, c))
        })
        .collect::<Vec<_>>()
        .join("\n")
}

pub async fn context_idle_process(pool: &PgPool, chat_id: i64, owner_iid: i64) -> Result<()> {
    let req_id = format!("compact-{}-{}", chat_id, snowflake_id());
    if billing_gate(pool, owner_iid).await.is_err() {
        return Ok(());
    }
    let msg_count: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM ai.chat_msg WHERE chat_id = $1 AND deleted_ts IS NULL",
    )
    .bind(chat_id)
    .fetch_one(pool)
    .await?;
    if msg_count < CONTEXT_IDLE_MIN_MSGS {
        return Ok(());
    }
    let latest_user_msg: Option<i64> = sqlx::query_scalar(
        "SELECT id FROM ai.chat_msg WHERE chat_id = $1 AND deleted_ts IS NULL ORDER BY id DESC LIMIT 1",
    )
    .bind(chat_id)
    .fetch_optional(pool)
    .await?;
    let user_msg_id = latest_user_msg.unwrap_or(0) + 1;
    let http = http_client(Duration::from_secs(30));
    let mut billing = ContextBillingExtra::default();
    if let Some(compact) = context_compact(pool, &http, chat_id, owner_iid, &req_id, user_msg_id, None, "idle").await? {
        billing.compaction_cost_usd = compact.cost_usd;
        billing.compaction_tokens_in = compact.tokens_in;
        billing.compaction_tokens_out = compact.tokens_out;
        billing.memory_extract_writes = compact.memory_writes;
    } else {
        let ctx = chat_context_load(pool, chat_id).await?;
        let rows = history_rows_load(pool, chat_id, ctx.summary_upto_msg_id, user_msg_id).await?;
        if rows.len() > CONTEXT_RECENT_MSG_MIN {
            let transcript = transcript_from_rows(&rows);
            let (writes, tin, tout, cost) = memory_extract_batch(pool, &http, owner_iid, None, &req_id, &transcript).await?;
            billing.memory_extract_cost_usd = cost;
            billing.memory_extract_writes = writes;
            billing.compaction_tokens_in = tin;
            billing.compaction_tokens_out = tout;
        }
    }
    let extra = billing.total_extra_usd();
    if extra > 0.0 {
        let _ = billing_usage_report(
            pool,
            None,
            owner_iid,
            &req_id,
            chat_id,
            crate::context_compact::CONTEXT_COMPACT_MODEL,
            billing.compaction_tokens_in,
            billing.compaction_tokens_out,
            0,
            None,
            extra,
            Some(billing.to_log_meta()),
        )
        .await;
    }
    Ok(())
}

pub async fn context_idle_scan(pool: &PgPool) -> Result<i32> {
    let rows: Vec<(i64, i64)> = sqlx::query_as(
        r#"
        SELECT c.id, c.owner_iid FROM ai.chat c
        WHERE c.kind = 'prompt' AND c.deleted_ts IS NULL
          AND c.last_msg_ts < NOW() - ($2 * INTERVAL '1 minute')
          AND (c.context_compact_ts IS NULL OR c.context_compact_ts < c.last_msg_ts)
          AND (SELECT COUNT(*) FROM ai.chat_msg m WHERE m.chat_id = c.id AND m.deleted_ts IS NULL) >= $1
        LIMIT 50
        "#,
    )
    .bind(CONTEXT_IDLE_MIN_MSGS)
    .bind(CONTEXT_IDLE_MINUTES)
    .fetch_all(pool)
    .await?;
    let mut n = 0i32;
    for (chat_id, owner_iid) in rows {
        if let Err(e) = context_idle_process(pool, chat_id, owner_iid).await {
            warn!("[c35:context_idle] chat_id={chat_id}: {e:#}");
        } else {
            n += 1;
        }
    }
    Ok(n)
}

pub struct ContextIdleFetchTask;

#[async_trait]
impl FetchTask for ContextIdleFetchTask {
    fn name(&self) -> &'static str {
        "chat_context_idle"
    }

    fn interval(&self) -> Duration {
        Duration::from_secs(15 * 60)
    }

    async fn run(&self, ctx: &c35_mod_fetch::FetchCtx) -> Result<FetchOutcome> {
        let n = context_idle_scan(&ctx.pool).await?;
        Ok(FetchOutcome {
            changed: n > 0,
            nats_subject: None,
            nats_payload: None,
        })
    }
}
