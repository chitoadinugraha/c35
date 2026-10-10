use std::sync::Arc;
use std::time::Instant;

use anyhow::Result;
use c35_mod_billing::{billing_resolve, billing_usage_report, TurnBillingCtx};
use c35_proto::ReqPrompt;
use c35_store::snowflake_id;
use sqlx::types::Json;
use sqlx::PgPool;
use tokio_util::sync::CancellationToken;

use crate::catalog_add_followup::{catalog_add_followup_boost, chat_last_assistant_content};
use crate::commerce_tx_followup::{chat_last_assistant_blocks, commerce_tx_followup_boost};
use crate::catalog_web::{catalog_skip_web_prefetch, catalog_web_phase};
use crate::site_commerce_compose::site_commerce_skip_web_prefetch;
use crate::compose::{
    compose_force_tool_call_with_text, compose_force_web_tool_call, compose_tools_and_inst_async,
    ComposeTurnOpts,
};
use crate::context_billing::ContextBillingExtra;
use crate::context_compact::{prepare_prompt_history, PreparedPromptHistory};
use crate::context_pack::{context_window_resolve, token_estimate, ContextUsageEst};
use crate::device_context::{
    bound_device_prompt_prepare, chat_bound_device_iid_for_owner, chat_mention_context_commit,
    cluster_tools_for_device_scope, device_platform_compose_signals,
    device_platform_scope_for_prompt, device_prompt_tool_exclude,
};
use crate::inst_cache::inst_list_for_turn;
use crate::inst_macro::{inst_pool_signal, inst_scopes_home};
use crate::memory::{memory_prompt_merge, memory_retrieve, MemoryRetrieveResult};
use crate::memory_extract::memory_extract_turn_gate;
use crate::mention::mention_list_enabled;
use crate::mention_content::mention_content_normalize;
use crate::mention_context::{mention_context_build, mention_context_sites_block, MentionContext};
use crate::mention_registry::{
    mention_active_topics, mention_prompt_block, mention_ref_parse, mention_resolve_all, MentionRef,
};
use crate::mention_tool_registry::mention_force_tools;
use crate::prompt::thought::thinking_level;
use crate::prompt::date_range::date_range_prompt_block;
use crate::prompt::time::{
    location_prompt_block, prompt_context_append, time_prompt_block, time_timezone_resolve,
    user_asks_time,
};
use crate::prompt::tool_loop::{prompt_cluster_turn, user_wants_search};
use crate::prompt::user_context::user_prompt_context_get;
use crate::prompt::ChatReq;
use crate::prompt_run::prompt_run_get;
use crate::site_capability::site_capability_view_for_mention;
use crate::site_resolve::site_context_resolve;
use crate::tools::{http_client, tool_decls, TurnCtx};
use crate::turn_tracer::TurnTracer;

/// Soft-delete the trailing user message and any assistant rows after it (retry / replace turn).
pub async fn chat_soft_delete_last_turn(pool: &PgPool, chat_id: i64) -> Result<()> {
    let last_user_id: Option<i64> = sqlx::query_scalar(
        r#"
        SELECT id FROM ai.chat_msg
        WHERE chat_id = $1 AND deleted_ts IS NULL AND role = 'user'
        ORDER BY id DESC LIMIT 1
        "#,
    )
    .bind(chat_id)
    .fetch_optional(pool)
    .await?;
    if let Some(uid) = last_user_id {
        let _ = sqlx::query(
            r#"
            UPDATE ai.chat_msg SET deleted_ts = NOW()
            WHERE chat_id = $1 AND deleted_ts IS NULL AND id >= $2
            "#,
        )
        .bind(chat_id)
        .bind(uid)
        .execute(pool)
        .await;
    }
    Ok(())
}

pub struct PromptTurn {
    pub chat_id: i64,
    pub user_msg_id: i64,
    pub assistant_msg_id: i64,
    pub text: String,
    pub thought: String,
    pub blocks_json: String,
    pub tokens_in: i32,
    pub tokens_out: i32,
    pub cost_usd: f64,
    /// True when turn cost was covered by plan allowance (wallet not charged).
    pub billing_included: bool,
    pub model: String,
    pub duration_ms: i32,
    pub error_text: String,
    pub prompt_tokens: i32,
    pub context_window: i32,
    pub usage: ContextUsageEst,
}

pub use crate::prompt::hooks::PromptHopCheckpoint;

#[derive(Default, Clone)]
pub struct PromptTurnHooks {
    pub skip_billing_gate: bool,
    pub on_hop: Option<Arc<dyn Fn(PromptHopCheckpoint) + Send + Sync>>,
}

pub fn chat_title_from_text(text: &str) -> String {
    let raw: String = text.trim().chars().take(48).collect();
    if raw.is_empty() {
        return "Chat".into();
    }
    let mut chars = raw.chars();
    let Some(first) = chars.next() else {
        return "Chat".into();
    };
    format!("{}{}", first.to_uppercase(), chars.as_str())
}

pub async fn chat_title_from_prompt(
    pool: &PgPool,
    owner_iid: i64,
    text: &str,
    mention_ids: &[String],
) -> String {
    use crate::mention_content::{
        mention_bracket_fixup_nesting, mention_bracket_for_id, mention_content_normalize,
        mention_plain_for_title,
    };
    use crate::mention_registry::mention_resolve_one;

    let fixed = mention_bracket_fixup_nesting(text);
    let normalized = mention_content_normalize(&fixed, mention_ids);
    let mut plain = normalized;
    let mut ids: Vec<String> = mention_ids.to_vec();
    for token in mention_ids_in_brackets(&fixed) {
        if !ids.iter().any(|x| x == &token) {
            ids.push(token);
        }
    }
    for id in &ids {
        let bracket = mention_bracket_for_id(id);
        if !plain.contains(&bracket) {
            continue;
        }
        let label = mention_resolve_one(pool, owner_iid, id)
            .await
            .map(|r| r.item.label.trim().to_string())
            .filter(|s| !s.is_empty());
        if let Some(label) = label {
            plain = plain.replace(&bracket, &label);
        }
    }
    chat_title_from_text(&mention_plain_for_title(&plain))
}

fn mention_ids_in_brackets(text: &str) -> Vec<String> {
    use crate::mention_content::mention_bracket_fixup_nesting;
    let mut out = Vec::new();
    let s = mention_bracket_fixup_nesting(text);
    let mut i = 0;
    let bytes = s.as_bytes();
    while i + 6 < bytes.len() {
        if bytes[i] == b'[' && bytes[i + 1] == b'@' && bytes[i + 2] == b'i' && bytes[i + 3] == b'i' && bytes[i + 4] == b'd' && bytes[i + 5] == b':' {
            let start = i + 6;
            let mut j = start;
            while j < bytes.len() && bytes[j] != b']' {
                j += 1;
            }
            if j > start {
                let n = &s[start..j];
                let id = format!("iid:{n}");
                if !out.contains(&id) {
                    out.push(id);
                }
            }
            i = j + 1;
            continue;
        }
        i += 1;
    }
    out
}

pub fn chat_attachments_json(s: &str) -> Json<serde_json::Value> {
    let raw = if s.trim().is_empty() { "[]" } else { s };
    Json(serde_json::from_str(raw).unwrap_or(serde_json::json!([])))
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
            let mime = a.get("mime").and_then(|x| x.as_str()).unwrap_or("");
            if hash.is_empty() {
                continue;
            }
            out.push_str(&format!("\n[attached: {} {} {}]", name, hash, mime));
            if mime.starts_with("image/") {
                out.push_str(&format!(" [image: /fs/{}]", hash));
            }
        }
    }
    out
}

pub async fn chat_ensure(pool: &PgPool, owner_iid: i64, chat_id: i64, title: &str) -> Result<i64> {
    if chat_id != 0 {
        let exists = sqlx::query_scalar::<_, i64>(
            "SELECT id FROM ai.chat WHERE id = $1 AND owner_iid = $2 AND kind = 'prompt' AND deleted_ts IS NULL",
        )
        .bind(chat_id)
        .bind(owner_iid)
        .fetch_optional(pool)
        .await?;
        if exists.is_some() {
            return Ok(chat_id);
        }
        anyhow::bail!("chat not found");
    }
    let id = snowflake_id();
    let t = if title.is_empty() { "Chat" } else { title };
    let mut tx = pool.begin().await?;
    sqlx::query(
        r#"
        INSERT INTO ai.chat (id, kind, owner_iid, title, model, created_ts, updated_ts)
        VALUES ($1, 'prompt', $2, $3, 'cloud', NOW(), NOW())
        "#,
    )
    .bind(id)
    .bind(owner_iid)
    .bind(t)
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        r#"
        INSERT INTO ai.chat_member (chat_id, member_iid, last_msg_preview, created_ts, updated_ts)
        VALUES ($1, $2, '', NOW(), NOW())
        ON CONFLICT (chat_id, member_iid) DO NOTHING
        "#,
    )
    .bind(id)
    .bind(owner_iid)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    Ok(id)
}

pub async fn prompt_turn<F, G>(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    owner_iid: i64,
    req_id: &str,
    mut req: ReqPrompt,
    locale: &str,
    mut on_delta: F,
    mut on_blocks: G,
    cancel: &CancellationToken,
    hooks: PromptTurnHooks,
) -> Result<PromptTurn>
where
    F: FnMut(bool, String) + Send,
    G: FnMut(String) + Send,
{
    let turn_started = Instant::now();
    let bctx = billing_resolve(
        pool,
        TurnBillingCtx {
            owner_iid,
            bot_iid: None,
            device_iid: None,
        },
    )
    .await?;
    let freemium = c35_mod_billing::billing_freemium_applies(pool, owner_iid)
        .await
        .unwrap_or(false);
    let requested_model = if freemium {
        "alienai"
    } else if req.model.trim().is_empty() {
        "alienai"
    } else {
        req.model.trim()
    };
    let brow = c35_mod_billing::billing_gate_scoped(pool, &bctx).await?;
    if !hooks.skip_billing_gate {
        c35_mod_billing::billing_gate_with_hold_model(
            pool,
            owner_iid,
            &brow,
            req_id,
            c35_mod_billing::DEFAULT_HOLD_USD,
            Some(requested_model),
        )
        .await?;
    }
    let prepare_started = Instant::now();
    let title = if req.chat_id != 0 {
        String::new()
    } else {
        chat_title_from_prompt(pool, owner_iid, &req.text, &req.mention_ids).await
    };
    let chat_id = chat_ensure(pool, owner_iid, req.chat_id, &title).await?;
    bound_device_prompt_prepare(pool, owner_iid, chat_id, &mut req).await?;
    chat_mention_context_commit(pool, chat_id, owner_iid, &req.mention_ids).await?;

    if req.chat_id > 0 {
        if req.replace_last_turn {
            chat_soft_delete_last_turn(pool, chat_id).await?;
        }
        let last_msg: Option<(i64, String)> = sqlx::query_as(
            r#"
            SELECT id, status FROM ai.chat_msg
            WHERE chat_id = $1 AND deleted_ts IS NULL
            ORDER BY id DESC LIMIT 1
            "#,
        )
        .bind(chat_id)
        .fetch_optional(pool)
        .await
        .unwrap_or(None);

        if !req.replace_last_turn {
            if let Some((last_id, status)) = last_msg {
                if status == "error" || status == "interrupted" {
                    let last_user_id: Option<i64> = sqlx::query_scalar(
                        r#"
                    SELECT id FROM ai.chat_msg
                    WHERE chat_id = $1 AND deleted_ts IS NULL AND role = 'user' AND id < $2
                    ORDER BY id DESC LIMIT 1
                    "#,
                    )
                    .bind(chat_id)
                    .bind(last_id)
                    .fetch_optional(pool)
                    .await
                    .unwrap_or(None);

                    if let Some(uid) = last_user_id {
                        let _ = sqlx::query(
                            r#"
                        UPDATE ai.chat_msg SET deleted_ts = NOW()
                        WHERE chat_id = $1 AND id IN ($2, $3)
                        "#,
                        )
                        .bind(chat_id)
                        .bind(last_id)
                        .bind(uid)
                        .execute(pool)
                        .await;
                    } else {
                        let _ = sqlx::query(
                            r#"
                        UPDATE ai.chat_msg SET deleted_ts = NOW()
                        WHERE chat_id = $1 AND id = $2
                        "#,
                        )
                        .bind(chat_id)
                        .bind(last_id)
                        .execute(pool)
                        .await;
                    }
                }
            }
        }
    }

    let user_content = mention_content_normalize(&req.text, &req.mention_ids);
    let user_msg_id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.chat_msg (id, chat_id, owner_iid, req_id, sender_iid, role, source, content, attachments, created_ts, updated_ts)
        VALUES ($1, $2, $3, $4, $3, 'user', 'prompt', $5, $6, NOW(), NOW())
        "#,
    )
    .bind(user_msg_id)
    .bind(chat_id)
    .bind(owner_iid)
    .bind(req_id)
    .bind(&user_content)
    .bind(chat_attachments_json(&req.attachments_json))
    .execute(pool)
    .await?;
    let _ =
        crate::chat_sync::chat_touch(pool, nats, chat_id, owner_iid, &user_content, "streaming")
            .await;

    let model = if freemium {
        c35_mod_billing::FREEMIUM_MODEL.to_string()
    } else if req.model.is_empty() {
        "alienai".to_string()
    } else {
        req.model.clone()
    };
    let user = crate::doc_prompt::append_doc_outlines(
        pool,
        &attach_prompt(&user_content, &req.attachments_json),
        &req.attachments_json,
    )
    .await;
    let is_simple_time =
        user_asks_time(&req.text) && req.mention_ids.is_empty() && !user_wants_search(&req.text);
    let http = http_client(std::time::Duration::from_secs(30));
    let mention_ids: Vec<String> = req.mention_ids.clone();

    let (inst_rows, mentions, prompt_run_res, resolved, user_ctx, memory): (
        Vec<crate::inst_macro::InstRow>,
        Vec<crate::mention::MentionRow>,
        Option<crate::prompt_run::PromptRunRow>,
        Vec<crate::mention_registry::MentionResolved>,
        crate::prompt::user_context::UserPromptContext,
        MemoryRetrieveResult,
    ) = tokio::join!(
        inst_list_for_turn(pool),
        mention_list_enabled(pool),
        async { prompt_run_get(pool, req_id).await.ok().flatten() },
        mention_resolve_all(pool, owner_iid, &mention_ids),
        user_prompt_context_get(pool, owner_iid),
        {
            let pool = pool.clone();
            let http = http.clone();
            let query = req.text.clone();
            async move {
                if is_simple_time {
                    MemoryRetrieveResult::default()
                } else {
                    memory_retrieve(&pool, &http, owner_iid, None, &query, 8).await
                }
            }
        }
    );
    let prompt_run = prompt_run_res;
    let run_kind = prompt_run
        .as_ref()
        .map(|r| r.kind.as_str())
        .unwrap_or("main");
    let mut checkpoint = prompt_run
        .as_ref()
        .map(|r| r.checkpoint_json.0.clone())
        .unwrap_or_else(|| serde_json::json!({}));
    let explicit_topic = if run_kind == "computer_use" {
        "computer_use".to_string()
    } else {
        req.topic_id.clone()
    };
    let inst_mention_ids: Vec<String> = mention_ids
        .iter()
        .filter_map(|raw| match mention_ref_parse(raw) {
            Some(MentionRef::Catalog(id)) => Some(id),
            _ if !raw.contains(':') && raw.parse::<i64>().is_err() => Some(raw.clone()),
            _ => None,
        })
        .collect();
    let inst_match_ids = crate::inst_macro::inst_mention_ids(&inst_mention_ids, req.talk);
    let force_tools = mention_force_tools(&resolved);
    let mention_ctx = mention_context_build(&resolved);
    let mention_ctx = if mention_ctx.sites.is_empty() {
        site_context_resolve(pool, owner_iid, &req.text, &inst_mention_ids)
            .await
            .ok()
            .flatten()
            .map(MentionContext::from_site)
            .unwrap_or(mention_ctx)
    } else {
        mention_ctx
    };
    let site_iids = mention_ctx.site_iids();
    let site_names = crate::scope_instruction::mention_site_names(&mention_ctx);
    let (scope_user_row, scope_site_rows) = crate::scope_instruction::scope_instruction_load_for_prompt(
        pool,
        owner_iid,
        &site_iids,
        &site_names,
    )
    .await
    .unwrap_or((None, vec![]));
    let scope_instruction_block = crate::scope_instruction::scope_instruction_prompt_block(
        &req.text,
        scope_user_row.as_ref(),
        &scope_site_rows,
    );

    let caps = site_capability_view_for_mention(pool, &mention_ctx).await;
    let commerce_site_iids = caps.commerce_site_iids(&mention_ctx.site_iids());
    let active_topics = mention_active_topics(&resolved, &explicit_topic, &commerce_site_iids);
    let tool_mode = if req.tool_mode.trim().is_empty() {
        "agent"
    } else {
        req.tool_mode.trim()
    };
    let inst_scopes = inst_scopes_home();
    let locale_eff = if locale.trim().is_empty() {
        user_ctx.locale.as_str()
    } else {
        locale
    };
    let (bound_device_iid, catalog_followup_raw, last_assistant_blocks) = tokio::join!(
        chat_bound_device_iid_for_owner(pool, owner_iid, chat_id),
        chat_last_assistant_content(pool, chat_id),
        chat_last_assistant_blocks(pool, chat_id),
    );
    let platform_scope =
        device_platform_scope_for_prompt(pool, owner_iid, &mention_ctx.devices, bound_device_iid)
            .await;
    let device_tool_exclude = device_prompt_tool_exclude(
        pool,
        owner_iid,
        &mention_ctx.devices,
        bound_device_iid,
        &platform_scope,
    )
    .await;
    let catalog_followup = catalog_followup_raw
        .as_deref()
        .and_then(|prev| catalog_add_followup_boost(prev, &req.text));
    let catalog_force_tools: Vec<String> = catalog_followup
        .as_ref()
        .map(|b| b.force_tools.clone())
        .unwrap_or_default();
    let catalog_inst_suffix = catalog_followup
        .as_ref()
        .map(|b| b.inst_suffix.as_str())
        .unwrap_or("");
    let commerce_followup = last_assistant_blocks
        .as_deref()
        .and_then(|b| commerce_tx_followup_boost(b, &req.text));
    let commerce_inst_suffix = commerce_followup
        .as_ref()
        .map(|b| b.inst_suffix.as_str())
        .unwrap_or("");
    let extra_inst_suffix = format!("{catalog_inst_suffix}{commerce_inst_suffix}");
    let mut catalog_force_tools = catalog_force_tools;
    if let Some(c) = &commerce_followup {
        catalog_force_tools.extend(c.force_tools.clone());
    }
    let mut device_tool_exclude = device_tool_exclude;
    if let Some(c) = &commerce_followup {
        device_tool_exclude.extend(c.tool_exclude.clone());
    }
    let mut compose_signals = vec![inst_pool_signal(&model).to_string(), "wire:date_range".into()];
    compose_signals.extend(device_platform_compose_signals(&platform_scope));
    let tool_catalog = cluster_tools_for_device_scope(&platform_scope);
    let composed = compose_tools_and_inst_async(
        pool,
        &http,
        &inst_rows,
        &req.text,
        tool_catalog,
        &force_tools,
        &inst_match_ids,
        &active_topics,
        tool_mode,
        &mentions,
        &inst_scopes,
        &mention_ctx,
        &caps,
        ComposeTurnOpts {
            extra_signals: &compose_signals,
            attachments_json: &req.attachments_json,
            extra_tool_include: &catalog_force_tools,
            extra_tool_exclude: &device_tool_exclude,
            extra_inst_suffix: &extra_inst_suffix,
            skip_tool_rag: is_simple_time,
            ..ComposeTurnOpts::default()
        },
        owner_iid,
        locale_eff,
    )
    .await;
    let site_iid = mention_ctx.default_site_iid;
    let instructions_base = token_estimate(&composed.inst_block);
    let topic_block = crate::topic::topics_inst_block(pool, &active_topics).await;
    let instructions_base = instructions_base
        + token_estimate(&topic_block)
        + token_estimate(&scope_instruction_block);

    let tools = if is_simple_time {
        vec![]
    } else {
        composed
            .tools
            .into_iter()
            .filter(|t| !freemium || c35_mod_billing::freemium_tool_allowed(&t.name))
            .collect()
    };
    let force_tool_call =
        compose_force_tool_call_with_text(&composed.matched_ids, &tools, &req.text);
    let force_web_tool_call =
        compose_force_web_tool_call(&composed.matched_ids, &tools, &req.text);

    let tz = time_timezone_resolve(&user_ctx.tz, locale_eff, &req.text);
    let time_block = time_prompt_block(&tz);
    let date_range_block = if composed
        .matched_ids
        .iter()
        .any(|id| id == "inst.core.date_range")
    {
        String::new()
    } else {
        date_range_prompt_block(&tz)
    };
    let location_block = location_prompt_block(
        &user_ctx.location_city,
        &user_ctx.location_region,
        &user_ctx.location_country,
    );
    let mut system = String::new();
    if !composed.inst_block.is_empty() {
        system = composed.inst_block.clone();
    }
    if !topic_block.is_empty() {
        if !system.is_empty() {
            system.push_str("\n\n");
        }
        system.push_str(&topic_block);
    }
    if !scope_instruction_block.is_empty() {
        if !system.is_empty() {
            system.push_str("\n\n");
        }
        system.push_str(&scope_instruction_block);
    }
    if force_web_tool_call {
        if !system.is_empty() {
            system.push_str("\n\n");
        }
        system.push_str(crate::prompt::web_grounding::WEB_GROUNDED_REPLY_RULE);
    }
    let sites_block = mention_context_sites_block(&mention_ctx);
    if !sites_block.is_empty() {
        if !system.is_empty() {
            system.push_str("\n\n");
        }
        system.push_str(&sites_block);
    }
    let mention_block = mention_prompt_block(&resolved);
    if !mention_block.is_empty() {
        if !system.is_empty() {
            system.push_str("\n\n");
        }
        system.push_str(&mention_block);
    }
    if !date_range_block.is_empty() {
        if !system.is_empty() {
            system.push_str("\n\n");
        }
        system.push_str(&date_range_block);
    }
    let context_named = token_estimate(&sites_block)
        + token_estimate(&mention_block)
        + token_estimate(&time_block)
        + token_estimate(&location_block)
        + token_estimate(&date_range_block);
    let memory_tokens = token_estimate(&memory.block);
    system = memory_prompt_merge(&system, &memory.block);

    // Keep dynamic volatile context (time and location) at the tail of the system prompt
    // to preserve KV prefix cache across turns.
    system = prompt_context_append(&system, &time_block, &location_block);

    let prepared = prepare_prompt_history(
        pool,
        &http,
        nats,
        chat_id,
        owner_iid,
        user_msg_id,
        req_id,
        &model,
        &system,
        &user,
        None,
    )
    .await
    .unwrap_or_else(|e| {
        tracing::warn!("[c35:context_prepare] fail open chat_id={chat_id}: {e:#}");
        PreparedPromptHistory {
            messages: Vec::new(),
            billing: ContextBillingExtra::default(),
            prompt_tokens: token_estimate(&system) + token_estimate(&user),
            context_window: context_window_resolve(&model, 0),
        }
    });
    let history = prepared.messages;
    let mut context_billing = prepared.billing;
    let context_window = prepared.context_window;

    let prepare_ms = prepare_started.elapsed().as_millis() as i64;
    let context_tokens_est = ((system.len() + user.len()) as f64 / 4.0).ceil() as i32;
    let tracer = TurnTracer::new(pool.clone(), nats.cloned(), owner_iid, chat_id, req_id);
    tracer
        .trace_prepare(&composed.trace, &req.text, prepare_ms, context_tokens_est)
        .await;
    let scope_trace = crate::scope_instruction::scope_instruction_build_trace(
        &req.text,
        scope_user_row.as_ref(),
        &scope_site_rows,
        &scope_instruction_block,
    );
    tracer.trace_scope_instruction(&scope_trace).await;
    tracer.trace_memory(&memory.trace).await;

    let system_tokens = token_estimate(&system);
    let named = instructions_base
        + context_named
        + memory_tokens
        + if force_web_tool_call {
            token_estimate(crate::prompt::web_grounding::WEB_GROUNDED_REPLY_RULE)
        } else {
            0
        };
    let slack = system_tokens.saturating_sub(named);
    let usage_base = ContextUsageEst {
        instructions: instructions_base
            + if force_web_tool_call {
                token_estimate(crate::prompt::web_grounding::WEB_GROUNDED_REPLY_RULE)
            } else {
                0
            },
        memory: memory_tokens,
        context: context_named + slack,
        tools: token_estimate(&tool_decls(&tools).to_string()),
        conversation: prepared.prompt_tokens.saturating_sub(system_tokens),
    };
    let prompt_tokens = usage_base.total();
    let usage = usage_base;
    let has_site = !mention_ctx.sites.is_empty()
        || match c35_mod_site::site_granted_iids(pool, owner_iid).await {
            Ok(ids) => !ids.is_empty(),
            Err(e) => {
                tracing::warn!(
                    "[c35:catalog_web] site_granted_iids failed owner_iid={owner_iid}: {e:#}"
                );
                false
            }
        };
    let catalog_web = catalog_web_phase(&composed.matched_ids, has_site);
    let skip_web_prefetch = catalog_skip_web_prefetch(&composed.matched_ids, catalog_web)
        || site_commerce_skip_web_prefetch(&req.text, &composed.matched_ids);
    let chat_req = ChatReq {
        model: model.clone(),
        system,
        user,
        thinking: thinking_level(&req.thinking),
        tools,
        history,
        force_tool_call,
        force_web_tool_call,
        catalog_web,
        skip_web_prefetch,
    };
    let attachments_json = req.attachments_json.as_str();
    let mut turn_ctx = TurnCtx {
        pool,
        nats,
        owner_iid,
        chat_id,
        site_iid,
        mention: mention_ctx,
        mention_ids: &mention_ids,
        user_text: &req.text,
        locale,
        location_city: &user_ctx.location_city,
        location_region: &user_ctx.location_region,
        location_country: &user_ctx.location_country,
        attachments_json,
        req_id,
        run_kind,
        checkpoint: Some(&mut checkpoint),
        title_slot: std::sync::Arc::new(std::sync::Mutex::new(None)),
        doc_ocr: std::sync::Arc::new(std::sync::Mutex::new(ContextBillingExtra::default())),
        billing: Some(bctx.clone()),
    };
    let res = match prompt_cluster_turn(
        &chat_req,
        &mut on_delta,
        &mut on_blocks,
        cancel,
        Some(&tracer),
        Some(&mut turn_ctx),
        hooks.on_hop.clone(),
    )
    .await
    {
        Ok(r) => r,
        Err(e) => {
            let duration_ms = turn_started.elapsed().as_millis() as i32;
            let assistant_msg_id = snowflake_id();
            let is_abort = cancel.is_cancelled() || e.to_string().contains("aborted");
            let status = if is_abort { "interrupted" } else { "error" };
            let err_text = e.to_string();
            let _ = sqlx::query(
                r#"
                INSERT INTO ai.chat_msg (
                    id, chat_id, owner_iid, req_id, sender_iid, role, source,
                    content, thought, blocks_json, tokens_in, tokens_out, duration_ms, cost_usd, status, error_text,
                    created_ts, updated_ts
                )
                VALUES ($1, $2, $3, $4, $3, 'assistant', 'prompt', '', '', '[]'::jsonb, 0, 0, $5, 0, $6, $7, NOW(), NOW())
                "#,
            )
            .bind(assistant_msg_id)
            .bind(chat_id)
            .bind(owner_iid)
            .bind(req_id)
            .bind(duration_ms)
            .bind(status)
            .bind(&err_text)
            .execute(pool)
            .await;
            let _ = c35_mod_billing::billing_reservation_refund(pool, req_id).await;
            let _ =
                crate::chat_sync::chat_touch(pool, nats, chat_id, owner_iid, &err_text, "error")
                    .await;
            return Err(e);
        }
    };
    if let Ok(extra) = turn_ctx.doc_ocr.lock() {
        context_billing.merge(&extra);
    }
    let duration_ms = turn_started.elapsed().as_millis() as i32;
    let assistant_msg_id = snowflake_id();
    let blocks_json = if res.blocks_json.is_empty() {
        "[]"
    } else {
        res.blocks_json.as_str()
    };
    tracer
        .llm_turn(
            &res.model_used,
            res.tokens_in,
            res.tokens_out,
            duration_ms as i64,
            prepare_ms,
            0.0,
            &res.text,
        )
        .await;
    match memory_extract_turn_gate(pool, &http, owner_iid, None, req_id, &req.text, &res.text).await
    {
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
    let billing = billing_usage_report(
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
        res.tools_cost_usd
            + context_extra
            + composed.trace.tool_embed_cost_usd
            + memory.trace.embed_cost_usd,
        if usage_meta
            .as_object()
            .map(|o| !o.is_empty())
            .unwrap_or(false)
        {
            Some(usage_meta)
        } else {
            None
        },
    )
    .await;
    let (cost_usd, billing_included, status, error_text) = match billing {
        Ok(r) => (r.cost_usd, !r.wallet_charged, "done", String::new()),
        Err(e) => (0.0, false, "error", e.to_string()),
    };
    sqlx::query(
        r#"
        INSERT INTO ai.chat_msg (
            id, chat_id, owner_iid, req_id, sender_iid, role, source,
            content, thought, blocks_json, tokens_in, tokens_out, duration_ms, cost_usd, status, error_text,
            created_ts, updated_ts
        )
        VALUES ($1, $2, $3, $4, $3, 'assistant', 'prompt', $5, $6, $7::jsonb, $8, $9, $10, $11, $12, $13, NOW(), NOW())
        "#,
    )
    .bind(assistant_msg_id)
    .bind(chat_id)
    .bind(owner_iid)
    .bind(req_id)
    .bind(&res.text)
    .bind(&res.thought)
    .bind(blocks_json)
    .bind(res.tokens_in)
    .bind(res.tokens_out)
    .bind(duration_ms)
    .bind(cost_usd)
    .bind(status)
    .bind(&error_text)
    .execute(pool)
    .await?;
    let final_status = if error_text.is_empty() {
        "done"
    } else {
        "error"
    };
    crate::chat_sync::chat_touch(pool, nats, chat_id, owner_iid, &res.text, final_status).await?;

    Ok(PromptTurn {
        chat_id,
        user_msg_id,
        assistant_msg_id,
        text: res.text,
        thought: res.thought,
        blocks_json: res.blocks_json,
        tokens_in: res.tokens_in,
        tokens_out: res.tokens_out,
        cost_usd,
        billing_included,
        model: res.model_used,
        duration_ms,
        error_text,
        prompt_tokens,
        context_window,
        usage,
    })
}
