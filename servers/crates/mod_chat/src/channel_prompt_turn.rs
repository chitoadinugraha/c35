use std::time::Instant;

use anyhow::Result;
use c35_mod_billing::{billing_resolve, billing_usage_report, TurnBillingCtx};
use sqlx::PgPool;
use tokio_util::sync::CancellationToken;

use crate::bot_meta::{bot_turn_meta_parse, bot_turn_signals, BOT_TOPIC, BOT_WEB_TOOL_EXCLUDE};
use crate::compose::{compose_tools_and_inst_async, ComposeTurnOpts};
use crate::inst_macro::inst_scopes_channel;
use crate::inst_cache::inst_list_cached;
use crate::context_billing::ContextBillingExtra;
use crate::context_compact::prepare_prompt_history;
use crate::memory::{memory_prompt_merge, memory_retrieve};
use crate::memory_extract::memory_extract_turn_gate;
use crate::prompt::gemini::gemini_api_key;
use crate::prompt::thought::thinking_level;
use crate::prompt::time::{
    location_prompt_block, prompt_context_prepend, time_prompt_block, time_timezone_resolve,
};
use crate::prompt::user_context::user_prompt_context_get;
use crate::prompt::tool_loop::prompt_cluster_turn;
use crate::prompt::ChatReq;
use crate::tools::{cluster_tools, TurnCtx};
use crate::turn_tracer::TurnTracer;

pub async fn channel_prompt_turn(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    bot_iid: i64,
    chat_id: i64,
    owner_iid: i64,
    text: &str,
    attachments_json: &str,
    is_voice: bool,
    req_id: &str,
) -> Result<(String, i32, i32, f64, String)> {
    if gemini_api_key().is_empty() {
        anyhow::bail!("GEMINI_API_KEY not set");
    }
    let turn_started = Instant::now();
    let bctx = billing_resolve(
        pool,
        TurnBillingCtx { owner_iid, bot_iid: Some(bot_iid), device_iid: None },
    )
    .await?;
    let brow = c35_mod_billing::billing_gate_scoped(pool, &bctx).await?;
    c35_mod_billing::billing_gate_with_hold(pool, owner_iid, &brow, req_id).await?;
    let model = identity_model_resolve(pool, bot_iid)
        .await
        .or(identity_model_resolve(pool, owner_iid).await)
        .unwrap_or_else(|| "alienai".into());
    let mut prompt_text = text.to_string();
    if is_voice && prompt_text.trim().is_empty() {
        prompt_text = "[voice message]".into();
    }
    let user = attach_prompt(&prompt_text, attachments_json);
    let locale = "";

    let bot_meta = bot_meta_load(pool, bot_iid).await;
    let turn_meta = bot_turn_meta_parse(bot_meta.as_ref());
    let signals = bot_turn_signals(&turn_meta);
    let mut extra_exclude: Vec<String> = Vec::new();
    if !turn_meta.web_search {
        extra_exclude.extend(BOT_WEB_TOOL_EXCLUDE.iter().map(|s| s.to_string()));
    }
    let compose_opts = ComposeTurnOpts {
        extra_signals: &signals,
        extra_tool_exclude: &extra_exclude,
        bot_web_search: turn_meta.web_search,
    };

    let inst_rows = inst_list_cached();
    let empty_mentions: [String; 0] = [];
    let inst_scopes = inst_scopes_channel();
    let http = crate::tools::http_client(std::time::Duration::from_secs(30));
    let composed = compose_tools_and_inst_async(
        pool,
        &http,
        &inst_rows,
        &prompt_text,
        cluster_tools(),
        &[],
        &empty_mentions,
        &[BOT_TOPIC.into()],
        "agent",
        &[],
        &inst_scopes,
        &crate::mention_context::MentionContext::empty(),
        &crate::site_capability::SiteCapabilityView::empty(),
        compose_opts,
    )
    .await;
    let user_ctx = user_prompt_context_get(pool, owner_iid).await;
    let tz = time_timezone_resolve(&user_ctx.tz, locale, &prompt_text);
    let time_block = time_prompt_block(&tz);
    let location_block = location_prompt_block(
        &user_ctx.location_city,
        &user_ctx.location_region,
        &user_ctx.location_country,
    );
    let mut system = prompt_context_prepend(&time_block, &location_block, "");
    if let Some(inst_base) = bot_inst_base(pool, bot_iid).await {
        system = format!("{inst_base}\n\n{system}");
    }
    if !composed.inst_block.is_empty() {
        system = format!("{system}\n\n{}", composed.inst_block);
    }
    let memory = memory_retrieve(pool, &http, owner_iid, Some(bot_iid), &prompt_text, 8).await;
    system = memory_prompt_merge(&system, &memory.block);

    let tracer = TurnTracer::new(pool.clone(), nats.cloned(), owner_iid, chat_id, req_id);
    tracer.trace_prepare(&composed.trace, &prompt_text, 0, 0).await;
    tracer.trace_memory(&memory.trace).await;

    let user_msg_id: i64 = sqlx::query_scalar(
        "SELECT COALESCE(MAX(id), 0) FROM ai.chat_msg WHERE chat_id = $1 AND deleted_ts IS NULL",
    )
    .bind(chat_id)
    .fetch_one(pool)
    .await
    .unwrap_or(0);
    let (history, mut context_billing) = prepare_prompt_history(
        pool,
        &http,
        chat_id,
        owner_iid,
        user_msg_id + 1,
        req_id,
        &model,
        &system,
        &user,
        Some(bot_iid),
    )
    .await
    .unwrap_or_else(|e| {
        tracing::warn!("[c35:context_prepare] bot chat_id={chat_id}: {e:#}");
        (Vec::new(), ContextBillingExtra::default())
    });

    let chat_req = ChatReq {
        model,
        system,
        user,
        thinking: thinking_level(""),
        tools: composed.tools.clone(),
        history,
        force_tool_call: crate::compose::compose_force_tool_call(&composed.matched_ids, &composed.tools),
    };
    let mut turn_ctx = TurnCtx {
        pool,
        nats: None,
        owner_iid,
        chat_id,
        site_iid: None,
        mention: crate::mention_context::MentionContext::empty(),
        mention_ids: &[],
        user_text: &prompt_text,
        locale,
        location_city: &user_ctx.location_city,
        location_region: &user_ctx.location_region,
        location_country: &user_ctx.location_country,
        attachments_json,
        req_id,
        run_kind: "main",
        checkpoint: None,
        title_slot: std::sync::Arc::new(std::sync::Mutex::new(None)),
    };
    let cancel = CancellationToken::new();
    let res = match prompt_cluster_turn(
        &chat_req,
        &mut |_thought, _delta| {},
        &mut |_blocks| {},
        &cancel,
        Some(&tracer),
        Some(&mut turn_ctx),
        None,
    )
    .await
    {
        Ok(r) => r,
        Err(e) => {
            let _ = c35_mod_billing::billing_reservation_refund(pool, req_id).await;
            return Err(e);
        }
    };
    let duration_ms = turn_started.elapsed().as_millis() as i32;
    match memory_extract_turn_gate(pool, &http, owner_iid, Some(bot_iid), req_id, &prompt_text, &res.text).await {
        Ok((writes, tin, tout, cost)) => {
            context_billing.memory_extract_writes += writes;
            context_billing.memory_extract_cost_usd += cost;
            context_billing.compaction_tokens_in += tin;
            context_billing.compaction_tokens_out += tout;
        }
        Err(e) => crate::memory_extract::memory_extract_log_err(&e),
    }
    let context_extra = context_billing.total_extra_usd();
    let usage_meta = context_billing.to_log_meta();
    let cost_usd = billing_usage_report(
        pool,
        nats,
        owner_iid,
        req_id,
        chat_id,
        &res.model_used,
        res.tokens_in,
        res.tokens_out,
        duration_ms,
        Some(&bctx),
        res.tools_cost_usd + context_extra,
        if usage_meta.as_object().map(|o| !o.is_empty()).unwrap_or(false) { Some(usage_meta) } else { None },
    )
    .await?;
    tracer.llm_turn(&res.model_used, res.tokens_in, res.tokens_out, duration_ms as i64, 0, cost_usd, &res.text).await;
    Ok((res.text, res.tokens_in, res.tokens_out, cost_usd, res.model_used))
}

async fn bot_meta_load(pool: &PgPool, bot_iid: i64) -> Option<serde_json::Value> {
    sqlx::query_scalar("SELECT meta FROM ai.identity WHERE id = $1 AND kind = 'bot' AND deleted_ts IS NULL")
        .bind(bot_iid)
        .fetch_optional(pool)
        .await
        .ok()
        .flatten()
}

async fn bot_inst_base(pool: &PgPool, bot_iid: i64) -> Option<String> {
    bot_meta_load(pool, bot_iid)
        .await
        .and_then(|m| m.get("inst_base").and_then(|v| v.as_str()).map(|s| s.trim().to_string()))
        .filter(|s| !s.is_empty())
}

async fn identity_model_resolve(pool: &PgPool, iid: i64) -> Option<String> {
    let meta: Option<serde_json::Value> = sqlx::query_scalar("SELECT meta FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL")
        .bind(iid)
        .fetch_optional(pool)
        .await
        .ok()
        .flatten();
    meta.and_then(|m| m.get("model").and_then(|v| v.as_str()).map(|s| s.to_string()))
        .filter(|s| !s.is_empty())
}

fn attach_prompt(text: &str, attachments_json: &str) -> String {
    if attachments_json.trim().is_empty() || attachments_json.trim() == "[]" {
        return text.to_string();
    }
    let mut out = text.to_string();
    if let Ok(v) = serde_json::from_str::<Vec<serde_json::Value>>(attachments_json) {
        for a in v {
            let name = a.get("name").and_then(|x| x.as_str()).unwrap_or("");
            let hash = a.get("hash").and_then(|x| x.as_str()).unwrap_or("");
            if !hash.is_empty() {
                out.push_str(&format!("\n[attached: {} {}]", name, hash));
            }
        }
    }
    out
}
