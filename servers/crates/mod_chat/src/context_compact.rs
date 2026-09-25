use anyhow::Result;
use c35_mod_billing::billing_cost_usd;
use c35_store::snowflake_id;
use reqwest::Client;
use serde::Deserialize;
use serde_json::json;
use sqlx::PgPool;
use tracing::warn;

use crate::context_billing::ContextBillingExtra;
use crate::context_pack::{
    context_pack_history, history_with_summary, model_context_limit, token_estimate, HistoryRow, CONTEXT_RECENT_MSG_MIN,
};

pub const CONTEXT_COMPACT_THRESHOLD_RATIO: f64 = 0.70;
use crate::memory_extract::memory_extract_batch;
use crate::prompt::gemini::{gemini_generate, gemini_model};
use crate::prompt::thought::thinking_level;
use crate::prompt::ChatHistoryMsg;

pub const CONTEXT_COMPACT_MODEL: &str = "gemini-2.0-flash";
const SUMMARY_MAX_LEN: usize = 8000;

const COMPACT_SYSTEM: &str =
    "Summarize the conversation for future LLM context. Output JSON only: {\"summary\":\"…\",\"decisions\":[],\"open_tasks\":[],\"entities\":{}}. Preserve all IDs, numbers, names, and decisions verbatim. Do not invent facts.";

#[derive(Debug, Clone)]
pub struct ChatContextState {
    pub summary: String,
    pub summary_upto_msg_id: i64,
}

#[derive(Debug, Clone, Default)]
pub struct CompactResult {
    pub tokens_in: i32,
    pub tokens_out: i32,
    pub cost_usd: f64,
    pub msgs_summarized: i32,
    pub memory_writes: i32,
}

pub fn should_compact(model: &str, system_tokens: i32, summary_tokens: i32, history_tokens: i32, user_tokens: i32) -> bool {
    let limit = model_context_limit(model);
    let total = system_tokens + summary_tokens + history_tokens + user_tokens;
    total as f64 > (limit as f64) * CONTEXT_COMPACT_THRESHOLD_RATIO
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
}

pub async fn chat_context_load(pool: &PgPool, chat_id: i64) -> Result<ChatContextState> {
    let row: Option<(String, i64)> = sqlx::query_as(
        "SELECT context_summary, context_summary_upto_msg_id FROM ai.chat WHERE id = $1 AND deleted_ts IS NULL",
    )
    .bind(chat_id)
    .fetch_optional(pool)
    .await?;
    Ok(match row {
        Some((summary, upto)) => ChatContextState { summary, summary_upto_msg_id: upto },
        None => ChatContextState { summary: String::new(), summary_upto_msg_id: 0 },
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

async fn compact_llm(transcript: &str, old_summary: &str) -> Result<(String, i32, i32, f64)> {
    let user = if old_summary.trim().is_empty() {
        format!("Transcript:\n{transcript}")
    } else {
        format!("Previous summary:\n{old_summary}\n\nNew messages:\n{transcript}")
    };
    let model = gemini_model(CONTEXT_COMPACT_MODEL);
    let contents = vec![json!({ "role": "user", "parts": [{ "text": user }] })];
    let out = gemini_generate(&contents, &json!([]), &thinking_level("off"), &model, COMPACT_SYSTEM, "AUTO").await?;
    let cost = billing_cost_usd(CONTEXT_COMPACT_MODEL, out.in_tok, out.out_tok);
    let summary = parse_compact_summary(&out.text);
    Ok((summary, out.in_tok, out.out_tok, cost))
}

fn parse_compact_summary(text: &str) -> String {
    let t = text.trim();
    if let Ok(v) = serde_json::from_str::<CompactOut>(t) {
        return v.summary.trim().to_string();
    }
    if let Some(start) = t.find('{') {
        if let Some(end) = t.rfind('}') {
            if let Ok(v) = serde_json::from_str::<CompactOut>(&t[start..=end]) {
                return v.summary.trim().to_string();
            }
        }
    }
    t.to_string()
}

pub async fn context_compact(
    pool: &PgPool,
    http: &Client,
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
    let (batch_summary, tin, tout, cost) = compact_llm(&transcript, &ctx.summary).await?;
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
    Ok(Some(CompactResult {
        tokens_in: tin + mem_tin,
        tokens_out: tout + mem_tout,
        cost_usd: cost + mem_cost,
        msgs_summarized: summarize_rows.len() as i32,
        memory_writes: mem_writes,
    }))
}

pub async fn prepare_prompt_history(
    pool: &PgPool,
    http: &Client,
    chat_id: i64,
    owner_iid: i64,
    user_msg_id: i64,
    req_id: &str,
    model: &str,
    system: &str,
    user: &str,
    bot_iid: Option<i64>,
) -> Result<(Vec<ChatHistoryMsg>, ContextBillingExtra)> {
    let mut billing = ContextBillingExtra::default();
    let system_tokens = token_estimate(system);
    let user_tokens = token_estimate(user);
    let mut ctx = chat_context_load(pool, chat_id).await?;
    let rows = history_rows_load(pool, chat_id, ctx.summary_upto_msg_id, user_msg_id).await?;
    let packed = context_pack_history(&ctx.summary, &rows, model, system_tokens, user_tokens);
    let history_tokens = packed.tokens_est - token_estimate(&ctx.summary);
    if should_compact(model, system_tokens, token_estimate(&ctx.summary), history_tokens, user_tokens) {
        match context_compact(pool, http, chat_id, owner_iid, req_id, user_msg_id, bot_iid, "threshold").await {
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
    let packed = context_pack_history(&ctx.summary, &rows, model, system_tokens, user_tokens);
    Ok((history_with_summary(&ctx.summary, &packed.messages), billing))
}

pub fn context_compact_log_err(e: &anyhow::Error) {
    warn!("[c35:context_compact] {e:#}");
}
