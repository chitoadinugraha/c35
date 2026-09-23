use std::sync::Arc;
use std::time::Instant;

use anyhow::Result;
use c35_mod_billing::{billing_resolve, billing_usage_report, TurnBillingCtx};
use c35_proto::ReqPrompt;
use c35_store::snowflake_id;
use sqlx::types::Json;
use sqlx::PgPool;
use tokio_util::sync::CancellationToken;

use crate::compose::compose_tools_and_inst;
use crate::prompt_run::prompt_run_get;
use crate::mention_registry::{
    mention_active_topics, mention_prompt_block, mention_ref_parse, mention_resolve_all, MentionRef,
};
use crate::mention_tool_registry::mention_force_tools;
use crate::site_capability::site_capability_view_for_mention;
use crate::inst_macro::inst_scopes_home;
use crate::mention_context::{
    mention_context_build, mention_context_sites_block, MentionContext,
};
use crate::site_resolve::site_context_resolve;
use crate::topic::topic_inst_block;
use crate::inst_cache::inst_list_cached;
use crate::mention::mention_list_enabled;
use crate::memory::{memory_prompt_merge, memory_retrieve};
use crate::prompt::thought::thinking_level;
use crate::prompt::time::{time_prompt_block, time_prompt_prepend, time_timezone_resolve, user_asks_time};
use crate::prompt::tool_loop::prompt_cluster_turn;
use crate::prompt::{ChatHistoryMsg, ChatReq};
use crate::tools::{cluster_tools, http_client, TurnCtx};
use crate::turn_tracer::TurnTracer;

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
    pub model: String,
    pub duration_ms: i32,
    pub error_text: String,
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
    let lower = raw.to_lowercase();
    let mut chars = lower.chars();
    let Some(first) = chars.next() else {
        return "Chat".into();
    };
    format!("{}{}", first.to_uppercase(), chars.as_str())
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
    req: ReqPrompt,
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
        TurnBillingCtx { owner_iid, bot_iid: None, device_iid: None },
    )
    .await?;
    let brow = c35_mod_billing::billing_gate_scoped(pool, &bctx).await?;
    if !hooks.skip_billing_gate {
        c35_mod_billing::billing_gate_with_hold(pool, owner_iid, &brow, req_id).await?;
    }
    let prepare_started = Instant::now();
    let title = chat_title_from_text(&req.text);
    let chat_id = chat_ensure(pool, owner_iid, req.chat_id, &title).await?;
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
    .bind(&req.text)
    .bind(chat_attachments_json(&req.attachments_json))
    .execute(pool)
    .await?;
    let _ = chat_touch(pool, chat_id, owner_iid, &req.text, "streaming").await;

    let history_rows: Vec<(String, String)> = sqlx::query_as(
        r#"
        SELECT role, content FROM ai.chat_msg
        WHERE chat_id = $1 AND id < $2 AND deleted_ts IS NULL AND status <> 'error'
        ORDER BY id DESC
        LIMIT 20
        "#,
    )
    .bind(chat_id)
    .bind(user_msg_id)
    .fetch_all(pool)
    .await
    .unwrap_or_default();
    let history: Vec<ChatHistoryMsg> = history_rows
        .into_iter()
        .rev()
        .filter(|(_, content)| !content.trim().is_empty())
        .map(|(role, content)| ChatHistoryMsg { role, content })
        .collect();

    let model = if req.model.is_empty() { "alienai".to_string() } else { req.model.clone() };
    let user = attach_prompt(&req.text, &req.attachments_json);
    let inst_rows = inst_list_cached();
    let mentions = mention_list_enabled(pool).await;
    let mention_ids: Vec<String> = req.mention_ids.clone();
    let prompt_run = prompt_run_get(pool, req_id).await.ok().flatten();
    let run_kind = prompt_run.as_ref().map(|r| r.kind.as_str()).unwrap_or("main");
    let mut checkpoint = prompt_run
        .as_ref()
        .map(|r| r.checkpoint_json.0.clone())
        .unwrap_or_else(|| serde_json::json!({}));
    let explicit_topic = if run_kind == "computer_use" {
        "computer_use".to_string()
    } else {
        req.topic_id.clone()
    };
    let resolved = mention_resolve_all(pool, owner_iid, &mention_ids).await;
    let inst_mention_ids: Vec<String> = mention_ids
        .iter()
        .filter_map(|raw| match mention_ref_parse(raw) {
            Some(MentionRef::Catalog(id)) => Some(id),
            _ if !raw.contains(':') && raw.parse::<i64>().is_err() => Some(raw.clone()),
            _ => None,
        })
        .collect();
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
    let caps = site_capability_view_for_mention(pool, &mention_ctx).await;
    let commerce_site_iids = caps.commerce_site_iids(&mention_ctx.site_iids());
    let active_topics = mention_active_topics(&resolved, &explicit_topic, &commerce_site_iids);
    let topic_id = active_topics
        .first()
        .cloned()
        .unwrap_or_else(|| explicit_topic.clone());
    let tool_mode = if req.tool_mode.trim().is_empty() { "agent" } else { req.tool_mode.trim() };
    let inst_scopes = inst_scopes_home();
    let composed = compose_tools_and_inst(
        &inst_rows,
        &req.text,
        cluster_tools(),
        &force_tools,
        &inst_mention_ids,
        &active_topics,
        tool_mode,
        &mentions,
        &inst_scopes,
        &mention_ctx,
        &caps,
    );
    let site_iid = mention_ctx.default_site_iid;
    let topic_block = topic_inst_block(pool, &topic_id).await;
    let tz = time_timezone_resolve(locale, &req.text);
    let time_block = time_prompt_block(tz);
    let mut system = time_prompt_prepend(&time_block, "");
    if !topic_block.is_empty() {
        system = format!("{system}\n\n{topic_block}");
    }
    if !composed.inst_block.is_empty() {
        system = format!("{system}\n\n{}", composed.inst_block);
    }
    let sites_block = mention_context_sites_block(&mention_ctx);
    if !sites_block.is_empty() {
        system = format!("{system}\n\n{sites_block}");
    }
    let mention_block = mention_prompt_block(&resolved);
    if !mention_block.is_empty() {
        system = format!("{system}\n\n{mention_block}");
    }
    let http = http_client(std::time::Duration::from_secs(30));
    let memory = memory_retrieve(pool, &http, owner_iid, None, &req.text, 8).await;
    system = memory_prompt_merge(&system, &memory.block);

    let prepare_ms = prepare_started.elapsed().as_millis() as i64;
    let context_tokens_est = ((system.len() + user.len()) as f64 / 4.0).ceil() as i32;
    let tracer = TurnTracer::new(pool.clone(), nats.cloned(), owner_iid, chat_id, req_id);
    tracer.trace_prepare(&composed.trace, &req.text, prepare_ms, context_tokens_est).await;
    tracer.trace_memory(&memory.trace).await;

    let tools = if user_asks_time(&req.text) && mention_ids.is_empty() {
        vec![]
    } else {
        composed.tools
    };
    let chat_req = ChatReq {
        model: model.clone(),
        system,
        user,
        thinking: thinking_level(&req.thinking),
        tools,
        history,
    };
    let attachments_json = req.attachments_json.as_str();
    let mut turn_ctx = TurnCtx {
        pool,
        nats,
        owner_iid,
        chat_id,
        site_iid,
        mention: mention_ctx,
        locale,
        attachments_json,
        req_id,
        run_kind,
        checkpoint: Some(&mut checkpoint),
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
            let _ = chat_touch(pool, chat_id, owner_iid, &err_text, "error").await;
            return Err(e);
        }
    };
    let duration_ms = turn_started.elapsed().as_millis() as i32;
    let assistant_msg_id = snowflake_id();
    let blocks_json = if res.blocks_json.is_empty() { "[]" } else { res.blocks_json.as_str() };
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
        res.tools_cost_usd,
    )
    .await;
    let (cost_usd, status, error_text) = match billing {
        Ok(c) => (c, "done", String::new()),
        Err(e) => (0.0, "error", e.to_string()),
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
    let final_status = if error_text.is_empty() { "done" } else { "error" };
    chat_touch(pool, chat_id, owner_iid, &res.text, final_status).await?;
    if error_text.is_empty() {
        tracer.llm_turn(&res.model_used, res.tokens_in, res.tokens_out, duration_ms as i64, prepare_ms, cost_usd, &res.text).await;
    }

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
        model: res.model_used,
        duration_ms,
        error_text,
    })
}

async fn chat_touch(pool: &PgPool, chat_id: i64, owner_iid: i64, preview: &str, status: &str) -> Result<()> {
    let p: String = preview.chars().take(255).collect();
    let mut tx = match pool.begin().await {
        Ok(t) => t,
        Err(e) => {
            tracing::warn!("[c35:chat] chat_touch begin tx failed: {e}");
            return Ok(());
        }
    };
    let _ = sqlx::query(
        r#"
        UPDATE ai.chat SET last_msg_ts = NOW(), last_msg_preview = $2, updated_ts = NOW() WHERE id = $1
        "#,
    )
    .bind(chat_id)
    .bind(&p)
    .execute(&mut *tx)
    .await;
    let _ = sqlx::query(
        r#"
        UPDATE ai.chat_member SET last_msg_ts = NOW(), last_msg_preview = $2, last_msg_status = $4, updated_ts = NOW()
        WHERE chat_id = $1 AND member_iid = $3
        "#,
    )
    .bind(chat_id)
    .bind(&p)
    .bind(owner_iid)
    .bind(status)
    .execute(&mut *tx)
    .await;
    let _ = tx.commit().await;
    Ok(())
}
