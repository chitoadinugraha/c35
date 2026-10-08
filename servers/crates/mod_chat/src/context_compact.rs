use std::time::Duration;

use anyhow::{anyhow, Result};
use async_nats::Client as NatsClient;
use c35_mod_billing::{billing_cost_usd, billing_gate, billing_usage_report};
use c35_proto::{ReqChatCompact, ReqChatContextWindowSet, ResChatCompact, ResChatContextWindowSet};
use c35_store::snowflake_id;
use reqwest::Client;
use serde::Deserialize;
use serde_json::json;
use sqlx::{PgPool, Row};
use tracing::warn;

use crate::chat_sync::chat_title_set;
use crate::context_billing::ContextBillingExtra;
use crate::context_pack::{
    context_pack_history, context_window_resolve, context_window_store, history_rows_tokens, history_with_summary,
    prompt_tokens_estimate, token_estimate, HistoryRow, CONTEXT_RECENT_MSG_MIN,
};
use crate::prompt_turn::chat_title_from_text;
use crate::tools::http_client;

pub const CONTEXT_COMPACT_THRESHOLD_RATIO: f64 = 0.70;
use crate::memory_extract::memory_extract_batch;
use crate::prompt::gemini::{gemini_generate, gemini_model};
use crate::prompt::thought::thinking_level;
use crate::prompt::ChatHistoryMsg;

pub const CONTEXT_COMPACT_MODEL: &str = c35_mod_llm::CHEAP_MODEL;
const SUMMARY_MAX_LEN: usize = 8000;

const COMPACT_SYSTEM: &str =
    "Summarize the conversation for future LLM context. Output JSON only: {\"summary\":\"…\",\"decisions\":[],\"open_tasks\":[],\"entities\":{},\"title\":\"short title\"}. title is a short chat title of at most 48 characters in the user's language. Preserve all IDs, numbers, names, and decisions verbatim. Do not invent facts.";

#[derive(Debug, Clone)]
pub struct ChatContextState {
    pub summary: String,
    pub summary_upto_msg_id: i64,
    pub context_window: i32,
    pub title: String,
    pub meta: serde_json::Value,
}

#[derive(Debug, Clone, Default)]
pub struct CompactResult {
    pub tokens_in: i32,
    pub tokens_out: i32,
    pub cost_usd: f64,
    pub msgs_summarized: i32,
    pub memory_writes: i32,
    pub title: String,
}

pub struct PreparedPromptHistory {
    pub messages: Vec<ChatHistoryMsg>,
    pub billing: ContextBillingExtra,
    pub prompt_tokens: i32,
    pub context_window: i32,
}

pub fn should_compact(window: i32, system_tokens: i32, summary_tokens: i32, history_tokens: i32, user_tokens: i32) -> bool {
    let total = system_tokens.saturating_add(summary_tokens).saturating_add(history_tokens).saturating_add(user_tokens);
    total as f64 >= (window.max(1) as f64) * CONTEXT_COMPACT_THRESHOLD_RATIO
}

/// Auto title may replace the first-message title. A tool-set title (`title_locked`) stays.
pub fn title_refresh_allowed(meta: &serde_json::Value, current_title: &str, first_user_text: &str) -> bool {
    if meta.get("title_locked").and_then(|v| v.as_bool()) == Some(true) {
        return false;
    }
    let t = current_title.trim();
    t.is_empty() || t == "Chat" || t == chat_title_from_text(first_user_text)
}

pub fn summary_merge(old: &str, new: &str) -> String {
    let old = old.trim();
    let new = new.trim();
    if old.is_empty() {
        return cap_summary(new);
    }
    if new.is_empty() {
        return cap_summary(old);
    }
    cap_summary(&format!("{old}\n\n{new}"))
}

fn cap_summary(s: &str) -> String {
    if s.len() <= SUMMARY_MAX_LEN {
        return s.to_string();
    }
    let mut out = s[..SUMMARY_MAX_LEN].to_string();
    out.push_str("…");
    out
}

#[derive(Deserialize)]
struct CompactOut {
    summary: String,
    #[serde(default)]
    title: String,
}

pub async fn chat_context_load(pool: &PgPool, chat_id: i64) -> Result<ChatContextState> {
    let row = sqlx::query(
        r#"
        SELECT context_summary, context_summary_upto_msg_id, context_window, title, COALESCE(meta, '{}'::jsonb) AS meta
        FROM ai.chat WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(chat_id)
    .fetch_optional(pool)
    .await?;
    Ok(match row {
        Some(r) => ChatContextState {
            summary: r.get("context_summary"),
            summary_upto_msg_id: r.get("context_summary_upto_msg_id"),
            context_window: r.get("context_window"),
            title: r.get("title"),
            meta: r.get("meta"),
        },
        None => ChatContextState {
            summary: String::new(),
            summary_upto_msg_id: 0,
            context_window: 0,
            title: String::new(),
            meta: json!({}),
        },
    })
}

pub async fn history_rows_load(
    pool: &PgPool,
    chat_id: i64,
    after_msg_id: i64,
    before_msg_id: i64,
) -> Result<Vec<HistoryRow>> {
    let rows: Vec<(i64, String, String, String)> = sqlx::query_as(
        r#"
        SELECT id, role, content, COALESCE(blocks_json::text, '[]')
        FROM ai.chat_msg
        WHERE chat_id = $1 AND id > $2 AND id < $3 AND deleted_ts IS NULL AND status <> 'error'
        ORDER BY id DESC
        "#,
    )
    .bind(chat_id)
    .bind(after_msg_id)
    .bind(before_msg_id)
    .fetch_all(pool)
    .await?;
    Ok(rows
        .into_iter()
        .map(|(id, role, content, blocks_json)| HistoryRow { id, role, content, blocks_json })
        .collect())
}

fn transcript_from_rows(rows: &[HistoryRow]) -> String {
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

async fn compact_llm(transcript: &str, old_summary: &str) -> Result<(String, String, i32, i32, f64)> {
    let user = if old_summary.trim().is_empty() {
        format!("Transcript:\n{transcript}")
    } else {
        format!("Previous summary:\n{old_summary}\n\nNew messages:\n{transcript}")
    };
    let model = gemini_model(CONTEXT_COMPACT_MODEL);
    let contents = vec![json!({ "role": "user", "parts": [{ "text": user }] })];
    let out = gemini_generate(&contents, &json!([]), &thinking_level("off"), &model, CONTEXT_COMPACT_MODEL, COMPACT_SYSTEM, "AUTO").await?;
    let cost = billing_cost_usd(&model, out.in_tok, out.out_tok);
    let (summary, title) = parse_compact_out(&out.text);
    Ok((summary, title, out.in_tok, out.out_tok, cost))
}

fn compact_title_cap(title: &str) -> String {
    title.trim().chars().take(48).collect()
}

fn parse_compact_out(text: &str) -> (String, String) {
    let t = text.trim();
    let parsed = serde_json::from_str::<CompactOut>(t).ok().or_else(|| {
        let (Some(start), Some(end)) = (t.find('{'), t.rfind('}')) else { return None };
        serde_json::from_str::<CompactOut>(&t[start..=end]).ok()
    });
    if let Some(v) = parsed {
        return (v.summary.trim().to_string(), compact_title_cap(&v.title));
    }
    (t.to_string(), String::new())
}

async fn first_user_text(pool: &PgPool, chat_id: i64) -> Result<String> {
    let text: Option<String> = sqlx::query_scalar(
        "SELECT content FROM ai.chat_msg WHERE chat_id = $1 AND role = 'user' AND deleted_ts IS NULL AND status <> 'error' ORDER BY id ASC LIMIT 1",
    )
    .bind(chat_id)
    .fetch_optional(pool)
    .await?;
    Ok(text.unwrap_or_default())
}

async fn compact_title_apply(
    pool: &PgPool,
    nats: Option<&NatsClient>,
    chat_id: i64,
    owner_iid: i64,
    ctx: &ChatContextState,
    candidate: &str,
) -> Result<String> {
    let candidate = compact_title_cap(candidate);
    if candidate.is_empty() {
        return Ok(String::new());
    }
    let first = first_user_text(pool, chat_id).await?;
    if !title_refresh_allowed(&ctx.meta, &ctx.title, &first) {
        return Ok(String::new());
    }
    chat_title_set(pool, nats, owner_iid, chat_id, &candidate, false).await?;
    Ok(candidate)
}

pub async fn context_compact(
    pool: &PgPool,
    http: &Client,
    nats: Option<&NatsClient>,
    chat_id: i64,
    owner_iid: i64,
    req_id: &str,
    user_msg_id: i64,
    bot_iid: Option<i64>,
    trigger: &str,
) -> Result<Option<CompactResult>> {
    let ctx = chat_context_load(pool, chat_id).await?;
    let all_rows = history_rows_load(pool, chat_id, ctx.summary_upto_msg_id, user_msg_id).await?;
    if all_rows.len() <= CONTEXT_RECENT_MSG_MIN {
        return Ok(None);
    }
    let keep_recent = CONTEXT_RECENT_MSG_MIN.min(all_rows.len());
    let summarize_rows: Vec<HistoryRow> = all_rows.iter().skip(keep_recent).cloned().collect();
    if summarize_rows.is_empty() {
        return Ok(None);
    }
    let upto_id = summarize_rows.iter().map(|r| r.id).max().unwrap_or(ctx.summary_upto_msg_id);
    let transcript = transcript_from_rows(&summarize_rows);
    if transcript.trim().is_empty() {
        return Ok(None);
    }
    let (batch_summary, batch_title, tin, tout, cost) = compact_llm(&transcript, &ctx.summary).await?;
    if batch_summary.trim().is_empty() {
        return Ok(None);
    }
    let merged = summary_merge(&ctx.summary, &batch_summary);
    let before_len = ctx.summary.len();
    let after_len = merged.len();
    sqlx::query(
        r#"
        UPDATE ai.chat SET
            context_summary = $2,
            context_summary_upto_msg_id = $3,
            context_compact_ts = NOW(),
            context_compact_req_id = $4,
            meta = COALESCE(meta, '{}'::jsonb) || '{"context_summary_present":true}'::jsonb,
            updated_ts = NOW()
        WHERE id = $1
        "#,
    )
    .bind(chat_id)
    .bind(&merged)
    .bind(upto_id)
    .bind(req_id)
    .execute(pool)
    .await?;
    let (mem_writes, mem_tin, mem_tout, mem_cost) =
        memory_extract_batch(pool, http, owner_iid, bot_iid, req_id, &transcript).await.unwrap_or((0, 0, 0, 0.0));
    let log_id = snowflake_id();
    let _ = sqlx::query(
        r#"
        INSERT INTO ai.chat_compact_log (
            id, chat_id, owner_iid, req_id, trigger, msgs_summarized,
            tokens_in, tokens_out, cost_usd, model, summary_before_len, summary_after_len, memory_writes
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
        "#,
    )
    .bind(log_id)
    .bind(chat_id)
    .bind(owner_iid)
    .bind(req_id)
    .bind(trigger)
    .bind(summarize_rows.len() as i32)
    .bind(tin + mem_tin)
    .bind(tout + mem_tout)
    .bind(cost + mem_cost)
    .bind(CONTEXT_COMPACT_MODEL)
    .bind(before_len as i32)
    .bind(after_len as i32)
    .bind(mem_writes)
    .execute(pool)
    .await;
    let title = match compact_title_apply(pool, nats, chat_id, owner_iid, &ctx, &batch_title).await {
        Ok(t) => t,
        Err(e) => {
            warn!("[c35:context_compact] title refresh chat_id={chat_id}: {e:#}");
            String::new()
        }
    };
    Ok(Some(CompactResult {
        tokens_in: tin + mem_tin,
        tokens_out: tout + mem_tout,
        cost_usd: cost + mem_cost,
        msgs_summarized: summarize_rows.len() as i32,
        memory_writes: mem_writes,
        title,
    }))
}

pub async fn prepare_prompt_history(
    pool: &PgPool,
    http: &Client,
    nats: Option<&NatsClient>,
    chat_id: i64,
    owner_iid: i64,
    user_msg_id: i64,
    req_id: &str,
    model: &str,
    system: &str,
    user: &str,
    bot_iid: Option<i64>,
) -> Result<PreparedPromptHistory> {
    let mut billing = ContextBillingExtra::default();
    let system_tokens = token_estimate(system);
    let user_tokens = token_estimate(user);
    let mut ctx = chat_context_load(pool, chat_id).await?;
    let window = context_window_resolve(model, ctx.context_window);
    let rows = history_rows_load(pool, chat_id, ctx.summary_upto_msg_id, user_msg_id).await?;
    let full_history_tokens = history_rows_tokens(&rows);
    if should_compact(window, system_tokens, token_estimate(&ctx.summary), full_history_tokens, user_tokens) {
        match context_compact(pool, http, nats, chat_id, owner_iid, req_id, user_msg_id, bot_iid, "threshold").await {
            Ok(Some(compact)) => {
                billing.compaction_cost_usd = compact.cost_usd;
                billing.compaction_tokens_in = compact.tokens_in;
                billing.compaction_tokens_out = compact.tokens_out;
                billing.memory_extract_writes = compact.memory_writes;
                ctx = chat_context_load(pool, chat_id).await?;
            }
            Ok(None) => {}
            Err(e) => warn!("[c35:context_compact] fail open chat_id={chat_id}: {e:#}"),
        }
    }
    let rows = history_rows_load(pool, chat_id, ctx.summary_upto_msg_id, user_msg_id).await?;
    let packed = context_pack_history(&ctx.summary, &rows, window, system_tokens, user_tokens);
    Ok(PreparedPromptHistory {
        messages: history_with_summary(&ctx.summary, &packed.messages),
        billing,
        prompt_tokens: prompt_tokens_estimate(system_tokens, packed.tokens_est, user_tokens),
        context_window: window,
    })
}

async fn chat_owned(pool: &PgPool, chat_id: i64, owner_iid: i64) -> Result<(String, i32)> {
    let row = sqlx::query("SELECT model, context_window FROM ai.chat WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL")
        .bind(chat_id)
        .bind(owner_iid)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| anyhow!("chat not found"))?;
    Ok((row.get("model"), row.get("context_window")))
}

async fn chat_prompt_tokens_now(pool: &PgPool, chat_id: i64, model: &str) -> Result<i32> {
    let ctx = chat_context_load(pool, chat_id).await?;
    let window = context_window_resolve(model, ctx.context_window);
    let rows = history_rows_load(pool, chat_id, ctx.summary_upto_msg_id, i64::MAX).await?;
    let packed = context_pack_history(&ctx.summary, &rows, window, 0, 0);
    Ok(packed.tokens_est)
}

pub async fn chat_context_window_set(pool: &PgPool, owner_iid: i64, req: ReqChatContextWindowSet) -> Result<ResChatContextWindowSet> {
    if req.chat_id == 0 {
        anyhow::bail!("chat_id required");
    }
    let (model, _) = chat_owned(pool, req.chat_id, owner_iid).await?;
    let store = context_window_store(&model, req.context_window).map_err(|e| anyhow!(e))?;
    sqlx::query("UPDATE ai.chat SET context_window = $3, updated_ts = NOW() WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL")
        .bind(req.chat_id)
        .bind(owner_iid)
        .bind(store)
        .execute(pool)
        .await?;
    let prompt_tokens = chat_prompt_tokens_now(pool, req.chat_id, &model).await?;
    Ok(ResChatContextWindowSet {
        context_window: store,
        prompt_tokens,
        usage: Some(crate::context_pack::ContextUsageEst { conversation: prompt_tokens, ..Default::default() }.proto()),
    })
}

async fn bill_manual_compact(
    pool: &PgPool,
    nats: Option<&NatsClient>,
    owner_iid: i64,
    chat_id: i64,
    req_id: &str,
    compact: &CompactResult,
) -> Result<f64> {
    let mut billing = ContextBillingExtra::default();
    billing.compaction_cost_usd = compact.cost_usd;
    billing.compaction_tokens_in = compact.tokens_in;
    billing.compaction_tokens_out = compact.tokens_out;
    billing.memory_extract_writes = compact.memory_writes;
    let priced = billing_cost_usd(CONTEXT_COMPACT_MODEL, compact.tokens_in, compact.tokens_out);
    let extra = (compact.cost_usd - priced).max(0.0);
    billing_usage_report(
        pool,
        nats,
        owner_iid,
        req_id,
        chat_id,
        CONTEXT_COMPACT_MODEL,
        compact.tokens_in,
        compact.tokens_out,
        0,
        None,
        extra,
        Some(billing.to_log_meta()),
    )
    .await
    .map(|r| r.cost_usd)
}

pub async fn chat_compact_manual(
    pool: &PgPool,
    nats: Option<&NatsClient>,
    owner_iid: i64,
    req: ReqChatCompact,
) -> Result<ResChatCompact> {
    let chat_id = req.chat_id;
    if chat_id == 0 {
        anyhow::bail!("chat_id required");
    }
    let (model, _) = chat_owned(pool, chat_id, owner_iid).await?;
    billing_gate(pool, owner_iid).await?;
    let latest: Option<i64> = sqlx::query_scalar(
        "SELECT id FROM ai.chat_msg WHERE chat_id = $1 AND deleted_ts IS NULL ORDER BY id DESC LIMIT 1",
    )
    .bind(chat_id)
    .fetch_optional(pool)
    .await?;
    let user_msg_id = latest.unwrap_or(0).saturating_add(1);
    let req_id = format!("compact-{chat_id}-{}", snowflake_id());
    let http = http_client(Duration::from_secs(60));
    let compact = context_compact(pool, &http, nats, chat_id, owner_iid, &req_id, user_msg_id, None, "manual").await?;
    let cost_usd = if let Some(c) = &compact {
        if c.cost_usd > 0.0 { bill_manual_compact(pool, nats, owner_iid, chat_id, &req_id, c).await? } else { 0.0 }
    } else {
        0.0
    };
    let ctx = chat_context_load(pool, chat_id).await?;
    let title = compact.as_ref().map(|c| c.title.clone()).filter(|t| !t.is_empty()).unwrap_or(ctx.title);
    let prompt_tokens = chat_prompt_tokens_now(pool, chat_id, &model).await?;
    Ok(ResChatCompact {
        ran: compact.is_some(),
        title,
        prompt_tokens,
        cost_usd,
        usage: Some(crate::context_pack::ContextUsageEst { conversation: prompt_tokens, ..Default::default() }.proto()),
    })
}

pub fn context_compact_log_err(e: &anyhow::Error) {
    warn!("[c35:context_compact] {e:#}");
}
