use std::sync::Arc;
use std::time::{Duration, Instant};

use anyhow::Result;
use c35_mod_billing::{billing_resolve, BillingContext, TurnBillingCtx};
use c35_mod_file::blob_ref_chat_msg;
use c35_proto::ReqPrompt;

use c35_store::snowflake_id;
use sqlx::types::Json;
use sqlx::PgPool;
use tokio_util::sync::CancellationToken;

use crate::catalog_add_followup::{catalog_add_followup_boost, chat_last_assistant_snapshot};
use crate::commerce_tx_followup::commerce_tx_followup_boost;
use crate::catalog_web::{catalog_skip_web_prefetch, catalog_web_phase};
use crate::site_commerce_compose::site_commerce_skip_web_prefetch;
use crate::compose::{
    compose_force_tool_call_with_text, compose_force_web_tool_call, compose_tools_and_inst_async,
    ComposeTurnOpts,
};
use crate::context_billing::ContextBillingExtra;
use crate::context_compact::{
    history_prefetch, prepare_prompt_history_with_prefetch, HistoryPrefetch, PreparedPromptHistory,
};
use crate::context_pack::{context_window_resolve, token_estimate, ContextUsageEst};
use crate::device_context::{
    bound_device_prompt_prepare, chat_bound_device_iid_for_owner, chat_mention_context_commit,
    cluster_tools_for_device_scope, device_platform_compose_signals,
    device_platform_scope_for_prompt, device_prompt_tool_exclude,
};
use crate::inst_cache::inst_list_for_turn;
use crate::inst_macro::{inst_pool_signal, inst_scopes_home};
use crate::compose::ComposePreload;
use crate::memory::{
    memory_prompt_merge, memory_retrieve_with_nats, memory_skip_site_scoped,
    MemoryRetrieveResult,
};

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
use crate::prompt::device_screenshot_prefetch::{
    device_screenshot_prefetch_capture, device_screenshot_prefetch_wanted, prefetch_device_iid,
};
use crate::prompt::tool_loop::{prompt_cluster_turn, user_wants_search};
use crate::tools::device_screenshot_artifact::device_screenshot_artifact_put;
use crate::prompt::user_context::user_prompt_context_get;
use crate::prompt::ChatReq;
use crate::prompt_run::prompt_run_get;
use crate::site_capability::site_capability_view_for_mention;
use crate::site_resolve::site_context_resolve;
use crate::owner_session::{
    chat_cache_append_turn, chat_cache_prefetch, chat_cache_wait_ready,
    owner_session_apply_billing_cached, owner_session_ensure_owner_warm,
    owner_session_wait_owner_bundle_traced, session_billing_snapshot, session_owner_bundle_wait_ms,
    session_warm_wait_ms, WarmState,
};
use crate::user_asset_rag::{
    user_asset_retrieve, user_asset_turn_skip, UserAssetRetrieveResult,
};
use crate::device_context::user_asks_local_file_op;
use crate::tools::{http_client, tool_decls, TurnCtx};
use crate::turn_tracer::{timed, StageClock, TurnTracer};

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

#[derive(Clone, Default)]
pub struct PromptTurnHooks {
    pub skip_billing_gate: bool,
    /// Child `prompt_run` rows (e.g. computer_use.delegate): do not insert user/assistant chat_msg rows.
    pub skip_chat_transcript_persist: bool,
    pub on_hop: Option<Arc<dyn Fn(PromptHopCheckpoint) + Send + Sync>>,
    pub owner_session: Option<Arc<crate::owner_session::OwnerPromptSession>>,
}

pub fn chat_title_from_text(text: &str) -> String {
    crate::mention_content::chat_title_from_bracket_text(text)
}

pub async fn chat_title_from_prompt(
    pool: &PgPool,
    owner_iid: i64,
    text: &str,
    mention_ids: &[String],
) -> String {
    use crate::mention_content::{
        chat_title_from_bracket_text, mention_bracket_fixup_nesting,
        mention_bracket_for_id_with_label, mention_brackets_attach_labels, mention_content_normalize,
    };
    use crate::mention_registry::mention_resolve_one;

    let fixed = mention_bracket_fixup_nesting(text);
    let normalized = mention_content_normalize(&fixed, mention_ids);
    let mut ids: Vec<String> = mention_ids.to_vec();
    for token in mention_ids_in_brackets(&fixed) {
        if !ids.iter().any(|x| x == &token) {
            ids.push(token);
        }
    }
    let mut label_pairs: Vec<(String, String)> = Vec::new();
    for id in &ids {
        let label = mention_resolve_one(pool, owner_iid, id)
            .await
            .map(|r| r.item.label.trim().to_string())
            .filter(|s| !s.is_empty());
        if let Some(label) = label {
            label_pairs.push((id.clone(), label));
        }
    }
    let mut title_body = mention_brackets_attach_labels(&normalized, &label_pairs);
    if let Some((id, label)) = label_pairs.first() {
        let bracket = mention_bracket_for_id_with_label(id, Some(label));
        let plain_label = label.to_lowercase();
        let body_lower = title_body.to_lowercase();
        if !body_lower.contains(&plain_label) && !title_body.contains(&bracket) {
            title_body = if title_body.trim().is_empty() {
                bracket
            } else {
                format!("{bracket} {title_body}")
            };
        }
    }
    chat_title_from_bracket_text(&title_body)
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
                let (payload, _) = crate::mention_content::mention_bracket_body_parts(n);
                let id = format!("iid:{payload}");
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
    if let Some(ref session) = hooks.owner_session {
        owner_session_ensure_owner_warm(pool, nats, session.clone());
        let _ = owner_session_wait_owner_bundle_traced(
            pool,
            nats,
            session.clone(),
            owner_iid,
            req_id,
            Duration::from_millis(session_owner_bundle_wait_ms()),
        )
        .await;
    }

    let turn_started = Instant::now();
    let mut clock = StageClock::new(turn_started);
    let st = Instant::now();
    let cached_billing = if let Some(ref session) = hooks.owner_session {
        session_billing_snapshot(session)
    } else {
        None
    };
    let cached_billing = if cached_billing.is_some() {
        cached_billing
    } else {
        c35_mod_billing::billing_cache_get(nats, owner_iid).await
    };
    let (bctx, freemium, brow) = if let Some(ref cached) = cached_billing {
        let brow = c35_mod_billing::cached_to_billing_row(cached);
        let bctx = BillingContext {
            scope: "personal".into(),
            plan_slug: cached.plan_tier.clone(),
            owner_iid,
            scope_iid: owner_iid,
            billing_account_id: cached.billing_account_id,
            subscription_id: None,
            msgs_used: 0,
            msgs_limit: 0,
        };
        (bctx, cached.is_freemium, brow)
    } else {
        let (bctx_res, freemium_res) = tokio::join!(
            billing_resolve(
                pool,
                TurnBillingCtx {
                    owner_iid,
                    bot_iid: None,
                    device_iid: None,
                },
            ),
            c35_mod_billing::billing_freemium_applies(pool, owner_iid),
        );
        let bctx = bctx_res?;
        let freemium = freemium_res.unwrap_or(false);
        let brow = c35_mod_billing::billing_gate_scoped(pool, &bctx).await?;
        (bctx, freemium, brow)
    };
    clock.seq("billing_resolve", "Billing resolve & freemium", st);

    let requested_model = if freemium {
        "alienai"
    } else if req.model.trim().is_empty() {
        "alienai"
    } else {
        req.model.trim()
    };
    let st = Instant::now();
    if !hooks.skip_billing_gate {
        if let Some(ref cached) = cached_billing {
            if cached.has_sufficient_allowance {
                c35_mod_billing::billing_gate_trusted_allowance_fast(
                    pool,
                    owner_iid,
                    &brow,
                    req_id,
                    c35_mod_billing::DEFAULT_HOLD_USD,
                    freemium,
                )
                .await?;
            } else {
                c35_mod_billing::billing_gate_with_hold_model_opt(
                    pool,
                    owner_iid,
                    &brow,
                    req_id,
                    c35_mod_billing::DEFAULT_HOLD_USD,
                    Some(requested_model),
                    Some(freemium),
                )
                .await?;
            }
        } else {
            c35_mod_billing::billing_gate_with_hold_model_opt(
                pool,
                owner_iid,
                &brow,
                req_id,
                c35_mod_billing::DEFAULT_HOLD_USD,
                Some(requested_model),
                Some(freemium),
            )
            .await?;
        }
    }
    if cached_billing.is_none() {
        let profile_remaining = if freemium {
            0.0
        } else {
            match c35_mod_billing::billing_profile_fetch(pool, owner_iid).await {
                Ok(Some(p)) if c35_mod_billing::profile_has_rings(&p) => {
                    let (a, f) = c35_mod_billing::profile_ring_remaining_usd(&p.rings);
                    a + f
                }
                _ => 0.0,
            }
        };
        let has_sufficient =
            c35_mod_billing::evaluate_allowance_sufficient(&brow, freemium, profile_remaining);
        let cache_entry = c35_mod_billing::BillingGateCached {
            owner_iid,
            billing_account_id: brow.id,
            plan_tier: brow.plan_tier.clone(),
            is_freemium: freemium,
            has_sufficient_allowance: has_sufficient,
            balance_usd: brow.balance_usd,
            alien_allow_5h_used: brow.alien_allow_5h_used,
            alien_allow_5h_limit: brow.alien_allow_5h_limit,
            alien_allow_weekly_used: brow.alien_allow_weekly_used,
            alien_allow_weekly_limit: brow.alien_allow_weekly_limit,
            cached_at_secs: chrono::Utc::now().timestamp(),
        };
        if let Some(ref session) = hooks.owner_session {
            owner_session_apply_billing_cached(session, cache_entry.clone());
        }
        let nats_put = nats.cloned();
        tokio::spawn(async move {
            c35_mod_billing::billing_cache_put(nats_put.as_ref(), &cache_entry).await;
        });
    }
    clock.seq("billing_gate", "Quota & hold gate", st);

    let prepare_started = Instant::now();
    let st = Instant::now();
    let chat_id = if req.chat_id > 0 {
        req.chat_id
    } else {
        let title = chat_title_from_prompt(pool, owner_iid, &req.text, &req.mention_ids).await;
        chat_ensure(pool, owner_iid, 0, &title).await?
    };
    bound_device_prompt_prepare(pool, owner_iid, chat_id, &mut req).await?;
    chat_mention_context_commit(pool, chat_id, owner_iid, &req.mention_ids).await?;
    if let Some(ref session) = hooks.owner_session {
        let mut st_cont = session.write_state();
        st_cont
            .continuity
            .entry(chat_id)
            .or_default()
            .on_user_message();
    }
    clock.seq("chat_setup", "Chat & device setup", st);

    if req.chat_id > 0 {
        let cleanup_started = Instant::now();
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
        clock.seq("last_turn_cleanup", "Last-turn cleanup", cleanup_started);
    }

    let user_content = mention_content_normalize(&req.text, &req.mention_ids);
    let user_msg_id = snowflake_id();
    let model = if freemium {
        c35_mod_billing::FREEMIUM_MODEL.to_string()
    } else if req.model.is_empty() {
        "alienai".to_string()
    } else {
        req.model.clone()
    };
    let is_simple_time =
        user_asks_time(&req.text) && req.mention_ids.is_empty() && !user_wants_search(&req.text);
    let http = http_client(std::time::Duration::from_secs(30));
    let mention_ids: Vec<String> = req.mention_ids.clone();
    let inst_mention_ids: Vec<String> = mention_ids
        .iter()
        .filter_map(|raw| match mention_ref_parse(raw) {
            Some(MentionRef::Catalog(id)) => Some(id),
            _ if !raw.contains(':') && raw.parse::<i64>().is_err() => Some(raw.clone()),
            _ => None,
        })
        .collect();
    let skip_user_assets =
        is_simple_time || user_asset_turn_skip(&req.text, &mention_ids);
    let user_with_attachments = attach_prompt(&user_content, &req.attachments_json);

    let pool_persist = pool.clone();
    let user_content_persist = user_content.clone();
    let attachments_json_persist = req.attachments_json.clone();
    let nats_persist = nats.cloned();
    let req_id_persist = req_id.to_string();
    let persist_st = Instant::now();
    let skip_chat_persist = hooks.skip_chat_transcript_persist;
    let mut persist_handle = if skip_chat_persist {
        tokio::spawn(async { Ok::<(), sqlx::Error>(()) })
    } else {
        tokio::spawn(async move {
            sqlx::query(
                r#"
            INSERT INTO ai.chat_msg (id, chat_id, owner_iid, req_id, sender_iid, role, source, content, attachments, created_ts, updated_ts)
            VALUES ($1, $2, $3, $4, $3, 'user', 'prompt', $5, $6, NOW(), NOW())
            "#,
            )
            .bind(user_msg_id)
            .bind(chat_id)
            .bind(owner_iid)
            .bind(&req_id_persist)
            .bind(&user_content_persist)
            .bind(chat_attachments_json(&attachments_json_persist))
            .execute(&pool_persist)
            .await?;
            if let Err(e) = blob_ref_chat_msg(
                &pool_persist,
                chat_id,
                user_msg_id,
                owner_iid,
                &attachments_json_persist,
                &user_content_persist,
                "[]",
            )
            .await
            {
                tracing::warn!("blob_ref chat user msg_id={user_msg_id}: {e}");
            }
            let _ = crate::chat_sync::chat_touch(
                &pool_persist,
                nats_persist.as_ref(),
                chat_id,
                owner_iid,
                &user_content_persist,
                "streaming",
            )
            .await;
            Ok::<(), sqlx::Error>(())
        })
    };

    let session_hist = hooks.owner_session.clone();

    let tool_mode_early = if req.tool_mode.trim().is_empty() {
        "agent"
    } else {
        req.tool_mode.trim()
    };
    let want_query_embed = (!is_simple_time && tool_mode_early == "agent")
        || (!is_simple_time && !skip_user_assets)
        || (!is_simple_time && !crate::memory::is_trivial_query(&req.text) && !req.text.trim().is_empty());
    let pool_embed = pool.clone();
    let http_embed = http.clone();
    let text_embed = req.text.clone();
    let unified_embed_handle = if want_query_embed {
        Some(tokio::spawn(async move {
            crate::memory::unified_query_embed(&pool_embed, &http_embed, &text_embed).await
        }))
    } else {
        None
    };

    // Stage 1: independent reads (tool RAG embed prefetch runs concurrently in background).
    let (
        (user, doc_st, doc_ms),
        (inst_rows, inst_st, inst_ms),
        (mentions, mlist_st, mlist_ms),
        (prompt_run_res, run_st, run_ms),
        (resolved, mres_st, mres_ms),
        (user_ctx, uctx_st, uctx_ms),
        (site_resolved, sr_st, sr_ms),
        (bound_device_iid, bdev_st, bdev_ms),
        (last_assistant, las_st, las_ms),
        (history_prefetch_res, hist_pf_st, hist_pf_ms),
        (staff, staff_st, staff_ms),
    ) = tokio::join!(
        timed(crate::doc_prompt::append_doc_outlines(
            pool,
            &user_with_attachments,
            &req.attachments_json,
        )),
        timed(inst_list_for_turn(pool)),
        timed(mention_list_enabled(pool)),
        timed(async { prompt_run_get(pool, req_id).await.ok().flatten() }),
        timed(mention_resolve_all(pool, owner_iid, &mention_ids)),
        timed(async {
            if let Some(ref sess) = session_hist {
                let ctx = sess.read_state().user_ctx.clone();
                if !ctx.locale.is_empty() {
                    return ctx;
                }
            }
            user_prompt_context_get(pool, owner_iid).await
        }),
        timed(async {
            if is_simple_time {
                None
            } else {
                site_context_resolve(pool, owner_iid, &req.text, &inst_mention_ids)
                    .await
                    .ok()
                    .flatten()
            }
        }),
        timed(chat_bound_device_iid_for_owner(pool, owner_iid, chat_id)),
        timed(async {
            if let Some(ref sess) = session_hist {
                if let Some(pf) = chat_cache_prefetch(sess, chat_id) {
                    if let Some(last) = pf.rows.iter().rev().find(|r| r.role == "assistant") {
                        return crate::catalog_add_followup::LastAssistantSnapshot {
                            content: Some(last.content.clone()),
                            blocks_json: Some(last.blocks_json.clone()),
                        };
                    }
                }
            }
            chat_last_assistant_snapshot(pool, chat_id).await
        }),
        timed(async {
            if let Some(ref sess) = session_hist {
                let warm = chat_cache_wait_ready(
                    sess,
                    chat_id,
                    Duration::from_millis(session_warm_wait_ms()),
                )
                .await;
                if warm == WarmState::Ready {
                    if let Some(pf) = chat_cache_prefetch(sess, chat_id) {
                        return Ok(pf);
                    }
                }
            }
            history_prefetch(pool, chat_id, user_msg_id).await
        }),
        timed(c35_mod_admin::staff_view_load(pool, owner_iid)),
    );
    clock.par("doc_outlines", "Attachment outlines", doc_st, doc_ms);
    clock.par("inst_list", "Inst list", inst_st, inst_ms);
    clock.par("mention_list", "Mention list", mlist_st, mlist_ms);
    clock.par("prompt_run", "Prompt run checkpoint", run_st, run_ms);
    clock.par("mention_resolve", "Mention resolve", mres_st, mres_ms);
    clock.par("user_context", "User context", uctx_st, uctx_ms);
    clock.par("site_resolve", "Site resolve", sr_st, sr_ms);
    clock.par("bound_device", "Bound device", bdev_st, bdev_ms);
    clock.par("last_assistant", "Last assistant snapshot", las_st, las_ms);
    let history_prefetch = match history_prefetch_res {
        Ok(p) => p,
        Err(e) => {
            tracing::warn!("[c35:history_prefetch] fail open chat_id={chat_id}: {e:#}");
            HistoryPrefetch {
                ctx: crate::context_compact::ChatContextState {
                    summary: String::new(),
                    summary_upto_msg_id: 0,
                    context_window: 0,
                    title: String::new(),
                    meta: serde_json::json!({}),
                },
                rows: vec![],
            }
        }
    };
    clock.par("history_prefetch", "History prefetch", hist_pf_st, hist_pf_ms);
    clock.par("staff_view", "Staff view", staff_st, staff_ms);
    let catalog_followup_raw = last_assistant.content;
    let last_assistant_blocks = last_assistant.blocks_json;
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
    let inst_match_ids = crate::inst_macro::inst_mention_ids(&inst_mention_ids, req.talk);
    let force_tools = mention_force_tools(&resolved);
    let mut mention_ctx = mention_context_build(&resolved);
    if mention_ctx.sites.is_empty() {
        if let Some(site) = site_resolved {
            mention_ctx = MentionContext::from_site(site);
        }
    }
    if crate::device_som::som_command_invoked(&req.text) {
        if let Some(turn) = crate::device_som::som_try_prompt_shortcut(
            pool,
            nats,
            owner_iid,
            staff.is_root,
            req_id,
            chat_id,
            user_msg_id,
            &user_content,
            &mention_ids,
            &mention_ctx,
            bound_device_iid,
            &mut persist_handle,
            turn_started,
            &mut on_delta,
            &mut on_blocks,
            &hooks,
        )
        .await?
        {
            return Ok(turn);
        }
    }
    let preloaded_memory = hooks
        .owner_session
        .as_ref()
        .and_then(|s| s.read_state().memory.clone());
    let preloaded_scope = hooks
        .owner_session
        .as_ref()
        .and_then(|s| s.read_state().scope.clone());
    let skip_memory = is_simple_time || memory_skip_site_scoped(&mention_ctx);
    let want_retrieval_embed = (!skip_user_assets
        || (!skip_memory && !crate::memory::is_trivial_query(&req.text) && !req.text.trim().is_empty()))
        && !is_simple_time;
    let unified_embed = if let Some(h) = unified_embed_handle {
        h.await.ok().flatten()
    } else if want_retrieval_embed {
        crate::memory::unified_query_embed(pool, &http, &req.text).await
    } else {
        None
    };
    let shared_retrieval_embed = unified_embed.as_ref().map(|u| u.embed_256.clone());
    let tool_precomputed_embed = unified_embed.as_ref().map(|u| u.embed_768.clone());
    let site_iids = mention_ctx.site_iids();
    let site_names = crate::scope_instruction::mention_site_names(&mention_ctx);

    // Stage 2: everything that needs the final mention context, concurrently.
    let embed_for_memory = shared_retrieval_embed.clone();
    let embed_for_assets = shared_retrieval_embed.clone();
    let (
        (memory, mem_st, mem_ms),
        (user_assets, ua_st, ua_ms),
        ((scope_user_row, scope_site_rows), scope_st, scope_ms),
        (caps, caps_st, caps_ms),
        ((platform_scope, device_tool_exclude), dev_st, dev_ms),
        (site_granted, grant_st, grant_ms),
    ) = tokio::join!(
        timed(async {
            if skip_memory {
                MemoryRetrieveResult::default()
            } else {
                memory_retrieve_with_nats(
                    pool,
                    nats,
                    &http,
                    owner_iid,
                    None,
                    &req.text,
                    8,
                    embed_for_memory,
                    preloaded_memory,
                )
                .await
            }
        }),
        timed(async {
            if skip_user_assets {
                UserAssetRetrieveResult::default()
            } else {
                user_asset_retrieve(pool, &http, owner_iid, &req.text, embed_for_assets).await
            }
        }),
        timed(async {
            if is_simple_time {
                (None, vec![])
            } else if let Some(bundle) = preloaded_scope {
                crate::scope_instruction::scope_instruction_rows_from_bundle(
                    &bundle,
                    owner_iid,
                    &site_iids,
                    &site_names,
                )
            } else {
                crate::scope_instruction::scope_instruction_load_for_prompt_nats(
                    pool,
                    nats,
                    owner_iid,
                    &site_iids,
                    &site_names,
                )
                .await
                .unwrap_or((None, vec![]))
            }
        }),

        timed(site_capability_view_for_mention(pool, &mention_ctx)),
        timed(async {
            let scope = device_platform_scope_for_prompt(
                pool,
                owner_iid,
                &mention_ctx.devices,
                bound_device_iid,
            )
            .await;
            let exclude = device_prompt_tool_exclude(
                pool,
                owner_iid,
                &mention_ctx.devices,
                bound_device_iid,
                &scope,
            )
            .await;
            (scope, exclude)
        }),
        timed(async {
            if is_simple_time {
                None
            } else if mention_ctx.sites.is_empty() {
                Some(c35_mod_site::site_granted_iids(pool, owner_iid).await)
            } else {
                None
            }
        }),
    );
    clock.par("memory", "Memory retrieve", mem_st, mem_ms);
    clock.par("user_assets", "User assets retrieve", ua_st, ua_ms);
    if mention_ctx.sites.is_empty() {
        if let Some(site) = user_assets.scope_site.clone() {
            mention_ctx = MentionContext::from_site(site);
        }
    }
    clock.par("scope_instruction", "Scope instructions load", scope_st, scope_ms);
    clock.par("site_caps", "Site capabilities", caps_st, caps_ms);
    clock.par("device_scope", "Device scope & tool exclude", dev_st, dev_ms);
    clock.par("site_grants", "Site grants", grant_st, grant_ms);
    let scope_instruction_block = crate::scope_instruction::scope_instruction_prompt_block(
        &req.text,
        scope_user_row.as_ref(),
        &scope_site_rows,
    );
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
    let mut extra_inst_suffix = format!("{catalog_inst_suffix}{commerce_inst_suffix}");
    let mut catalog_force_tools = catalog_force_tools;
    if let Some(c) = &commerce_followup {
        catalog_force_tools.extend(c.force_tools.clone());
    }
    if let Some(ref session) = hooks.owner_session {
        let cont = session.continuity_for_chat(chat_id);
        if cont.active() {
            catalog_force_tools.extend(cont.force_tools.clone());
            if !cont.inst_suffix.is_empty() {
                extra_inst_suffix.push_str(&cont.inst_suffix);
            }
        }
    }
    let mut device_tool_exclude = device_tool_exclude;
    if let Some(c) = &commerce_followup {
        device_tool_exclude.extend(c.tool_exclude.clone());
    }
    if bound_device_iid > 0 && user_asks_local_file_op(&req.text) {
        catalog_force_tools.push("shell.run".to_string());
        device_tool_exclude.push("web.search".to_string());
        device_tool_exclude.push("web.visit".to_string());
    }
    let mut compose_signals = vec![inst_pool_signal(&model).to_string(), "wire:date_range".into()];
    compose_signals.extend(device_platform_compose_signals(&platform_scope));
    let tool_catalog = cluster_tools_for_device_scope(&platform_scope);
    let compose_opts = ComposeTurnOpts {
        extra_signals: &compose_signals,
        attachments_json: &req.attachments_json,
        extra_tool_include: &catalog_force_tools,
        extra_tool_exclude: &device_tool_exclude,
        extra_inst_suffix: &extra_inst_suffix,
        skip_tool_rag: is_simple_time,
        precomputed_query_embed: tool_precomputed_embed.as_deref(),
        ..ComposeTurnOpts::default()
    };
    let compose_preload = ComposePreload { staff };
    let active_topics_for_topics = active_topics.clone();

    // Stage 3: compose (inst enrich + tool RAG) alongside the topic block.
    let ((composed, compose_st, compose_ms), (topic_block, topic_st, topic_ms)) = tokio::join!(
        timed(compose_tools_and_inst_async(
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
            compose_opts,
            owner_iid,
            locale_eff,
            Some(compose_preload),
        )),
        timed(crate::topic::topics_inst_block(
            pool,
            &active_topics_for_topics
        )),
    );
    clock.par("compose", "Compose tools & inst", compose_st, compose_ms);
    clock.par("topic_block", "Topic instructions", topic_st, topic_ms);
    let site_iid = mention_ctx.default_site_iid;
    let instructions_base = token_estimate(&composed.inst_block);
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
    let prefetch_device_iid = prefetch_device_iid(&mention_ctx, &mention_ids, bound_device_iid);
    let prefetch_wanted = !is_simple_time
        && prefetch_device_iid.is_some()
        && device_screenshot_prefetch_wanted(run_kind, &tools, &device_tool_exclude);
    let prefetch_task = if prefetch_wanted {
        let device_iid = prefetch_device_iid.unwrap();
        let pool_pf = pool.clone();
        let nats_pf = nats.cloned();
        Some(tokio::spawn(async move {
            device_screenshot_prefetch_capture(
                &pool_pf,
                nats_pf.as_ref(),
                owner_iid,
                device_iid,
            )
            .await
        }))
    } else {
        None
    };
    let force_tool_call =
        compose_force_tool_call_with_text(&composed.matched_ids, &tools, &req.text);
    let force_web_tool_call = compose_force_web_tool_call(
        &composed.matched_ids,
        &tools,
        &req.text,
        &composed.trace.inst_enrich_keys,
    );

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
    if composed
        .matched_ids
        .iter()
        .any(|id| id == "inst.browser.ensure")
    {
        if !system.is_empty() {
            system.push_str("\n\n");
        }
        system.push_str(
            "[BROWSER ENSURE] Hop 1: call browser.ensure with run_repairs true and device_iid from [MENTION TARGETS]. \
If extension_connected is true, call browser.extension op version. \
If extension_connected is false and user requested setup/install: do not stop with text instructions. Immediately call computer_use.delegate with a stepwise goal: clear foreground blockers \
(Taskmgr: Stop-Process or device.input shortcut alt+f4 / win+d), chrome://extensions, Developer mode ON, Load unpacked to install_path, enable extension, Reload; \
use som=true to locate controls and screenshot_after to verify. Then call browser.extension op version. \
Only fallback to user_offer.steps if delegation fails or on non-desktop devices. Do not suggest Chrome Web Store.",
        );
    }
    let sites_block = mention_context_sites_block(&mention_ctx);
    if !sites_block.is_empty() {
        if !system.is_empty() {
            system.push_str("\n\n");
        }
        system.push_str(&sites_block);
    }
    if !user_assets.block.is_empty() {
        if !system.is_empty() {
            system.push_str("\n\n");
        }
        system.push_str(&user_assets.block);
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
        + token_estimate(&user_assets.block)
        + token_estimate(&mention_block)
        + token_estimate(&time_block)
        + token_estimate(&location_block)
        + token_estimate(&date_range_block);
    let memory_tokens = token_estimate(&memory.block);
    system = memory_prompt_merge(&system, &memory.block);

    // Keep dynamic volatile context (time and location) at the tail of the system prompt
    // to preserve KV prefix cache across turns.
    system = prompt_context_append(&system, &time_block, &location_block);

    let st = Instant::now();
    let prepared = prepare_prompt_history_with_prefetch(
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
        history_prefetch,
    )
    .await
    .unwrap_or_else(|e| {
        tracing::warn!("[c35:context_prepare] fail open chat_id={chat_id}: {e:#}");
        PreparedPromptHistory {
            messages: Vec::new(),
            billing: ContextBillingExtra::default(),
            prompt_tokens: token_estimate(&system) + token_estimate(&user),
            context_window: context_window_resolve(&model, 0),
            compact_ms: 0,
        }
    });
    let history_ms = st.elapsed().as_millis() as i64;
    let compact_ms = prepared.compact_ms;
    clock.seq_ms(
        "history",
        "History load & pack",
        st,
        history_ms - compact_ms,
    );
    if compact_ms > 0 {
        clock.seq_ms("compact", "Context compaction (LLM)", st, compact_ms);
    }
    let history = prepared.messages;
    let mut context_billing = prepared.billing;
    let context_window = prepared.context_window;

    let prepare_ms = prepare_started.elapsed().as_millis() as i64;
    let prepare_wall_ms = clock.elapsed_ms();
    let context_tokens_est = ((system.len() + user.len()) as f64 / 4.0).ceil() as i32;
    let tracer = TurnTracer::new(pool.clone(), nats.cloned(), owner_iid, chat_id, req_id);
    let scope_trace = crate::scope_instruction::scope_instruction_build_trace(
        &req.text,
        scope_user_row.as_ref(),
        &scope_site_rows,
        &scope_instruction_block,
    );
    tokio::join!(
        tracer.trace_prepare(&composed.trace, &req.text, prepare_ms, context_tokens_est),
        tracer.trace_prepare_stages(&clock, prepare_wall_ms),
        tracer.trace_scope_instruction(&scope_trace),
        tracer.trace_user_assets(&user_assets.trace),
        tracer.trace_memory(&memory.trace),
    );

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
        || match site_granted {
            Some(Ok(ids)) => !ids.is_empty(),
            Some(Err(e)) => {
                tracing::warn!(
                    "[c35:catalog_web] site_granted_iids failed owner_iid={owner_iid}: {e:#}"
                );
                false
            }
            None => false,
        };
    let catalog_web = catalog_web_phase(&composed.matched_ids, has_site);
    let skip_web_prefetch = is_simple_time
        || catalog_skip_web_prefetch(&composed.matched_ids, catalog_web)
        || site_commerce_skip_web_prefetch(&req.text, &composed.matched_ids)
        || crate::compose::compose_suppress_general_web_when_staff_registrations(
            &composed.matched_ids,
        )
        || crate::compose::compose_skip_web_prefetch_for_context(
            &composed.matched_ids,
            &composed.trace.inst_enrich_keys,
            &req.text,
        );
    let device_prefetch = if let Some(task) = prefetch_task {
        let pf_started = Instant::now();
        match task.await {
            Ok(Some(p)) => {
                clock.seq_ms(
                    "device_prefetch",
                    "Device screenshot prefetch",
                    pf_started,
                    pf_started.elapsed().as_millis() as i64,
                );
                Some(p)
            }
            Ok(None) => None,
            Err(e) => {
                tracing::warn!("[c35:device_prefetch] task join failed: {e:#}");
                None
            }
        }
    } else {
        None
    };
    let chat_req = ChatReq {
        model: model.clone(),
        system,
        user,
        thinking: thinking_level(&req.thinking),
        tools,
        history,
        matched_inst_ids: composed.matched_ids.clone(),
        force_tool_call,
        force_web_tool_call,
        catalog_web,
        skip_web_prefetch,
        device_prefetch,
    };
    let attachments_json = req.attachments_json.as_str();
    let mut turn_ctx = TurnCtx {
        pool,
        nats,
        owner_iid,
        chat_id,
        site_iid,
        guest_visitor_id: None,
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
    let persist_ms = match persist_handle.await {
        Ok(Ok(())) => persist_st.elapsed().as_millis() as i64,
        Ok(Err(e)) => return Err(e.into()),
        Err(e) => return Err(e.into()),
    };
    clock.par("persist_user_msg", "Save user message", persist_st, persist_ms);

    if let Some(ref pf) = chat_req.device_prefetch {
        if let Ok((hash, url)) = device_screenshot_artifact_put(
            pool,
            owner_iid,
            req_id,
            "turn-start-prefetch",
            "device.screenshot",
            pf.device_iid,
            &pf.jpeg_bytes,
            pf.width,
            pf.height,
            false,
            false,
            pf.axtree_text.len(),
        )
        .await
        {
            let preview = serde_json::json!({
                "ok": true,
                "prefetch": true,
                "device_iid": pf.device_iid,
                "width": pf.width,
                "height": pf.height,
                "image_hash": hash,
                "image_url": url,
                "hint": "Turn-start desktop prefetch (not a model tool call).",
            });
            tracer
                .tool_result(
                    "device.screenshot",
                    "turn-start-prefetch",
                    &serde_json::json!({
                        "device_iid": pf.device_iid,
                        "prefetch": true,
                        "max_width": 1280,
                    }),
                    &preview,
                    true,
                    0,
                )
                .await;
        }
    }

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
            let is_abort = cancel.is_cancelled() || e.to_string().contains("aborted");
            let status = if is_abort { "interrupted" } else { "error" };
            let err_text = e.to_string();
            if !hooks.skip_chat_transcript_persist {
                let assistant_msg_id = snowflake_id();
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
                let _ = crate::chat_sync::chat_touch(pool, nats, chat_id, owner_iid, &err_text, "error")
                    .await;
            }
            let _ = c35_mod_billing::billing_reservation_refund(pool, req_id).await;
            tracer.flush().await;
            return Err(e);
        }
    };
    if let Ok(extra) = turn_ctx.doc_ocr.lock() {
        context_billing.merge(&extra);
    }
    if !res.text.is_empty() {
        on_delta(false, res.text.clone());
    }
    let duration_ms = turn_started.elapsed().as_millis() as i32;
    let assistant_msg_id = snowflake_id();
    let base_blocks = if res.blocks_json.is_empty() {
        "[]"
    } else {
        res.blocks_json.as_str()
    };
    let (assistant_content, blocks_json) =
        crate::viz_chart::merge_assistant_charts(res.text.clone(), base_blocks);
    let settle_started = Instant::now();
    let mut settle = StageClock::new(settle_started);
    tracer
        .llm_turn(
            &res.model_used,
            res.tokens_in,
            res.tokens_out,
            duration_ms as i64,
            prepare_ms,
            0.0,
            &assistant_content,
        )
        .await;
    let context_extra = context_billing.total_extra_usd();
    let llm_cost = c35_mod_billing::billing_cost_usd(&res.model_used, res.tokens_in, res.tokens_out);
    let extra_cost = res.tools_cost_usd
        + context_extra
        + composed.trace.tool_embed_cost_usd
        + memory.trace.embed_cost_usd;
    let cost_usd = llm_cost + extra_cost;
    let billing_included = bctx.scope != "personal"
        || bctx.plan_slug == "ultra"
        || bctx.plan_slug == "pro"
        || bctx.plan_slug == "starter";
    let status = "done";
    let error_text = String::new();

    let pool_bg = pool.clone();
    let nats_bg = nats.cloned();
    let req_id_bg = req_id.to_string();
    let model_bg = res.model_used.clone();
    let bctx_bg = bctx.clone();
    let user_text_bg = req.text.clone();
    let assistant_text_bg = res.text.clone();
    let mut context_billing_bg = context_billing;
    let tools_cost_bg = res.tools_cost_usd;
    let tool_embed_cost_bg = composed.trace.tool_embed_cost_usd;
    let memory_embed_cost_bg = memory.trace.embed_cost_usd;
    let tokens_in_bg = res.tokens_in;
    let tokens_out_bg = res.tokens_out;
    let session_bg = hooks.owner_session.clone();
    tokio::spawn(async move {
        let http_bg = http_client(std::time::Duration::from_secs(30));
        match memory_extract_turn_gate(
            &pool_bg,
            &http_bg,
            owner_iid,
            None,
            &req_id_bg,
            &user_text_bg,
            &assistant_text_bg,
        )
        .await
        {
            Ok((writes, tin, tout, cost)) => {
                context_billing_bg.memory_extract_writes += writes;
                context_billing_bg.memory_extract_cost_usd += cost;
                context_billing_bg.compaction_tokens_in += tin;
                context_billing_bg.compaction_tokens_out += tout;
            }
            Err(e) => crate::memory_extract::memory_extract_log_err(&e),
        }
        let context_extra_bg = context_billing_bg.total_extra_usd();
        let usage_meta_bg = context_billing_bg.to_log_meta();
        let extra_cost_bg =
            tools_cost_bg + context_extra_bg + tool_embed_cost_bg + memory_embed_cost_bg;
        let usage_meta_opt = if usage_meta_bg.as_object().map(|o| !o.is_empty()).unwrap_or(false) {
            Some(usage_meta_bg)
        } else {
            None
        };
        if let Err(e) = c35_mod_billing::billing_usage_report(
            &pool_bg,
            nats_bg.as_ref(),
            owner_iid,
            &req_id_bg,
            chat_id,
            &model_bg,
            tokens_in_bg,
            tokens_out_bg,
            duration_ms,
            Some(&bctx_bg),
            extra_cost_bg,
            usage_meta_opt,
        )
        .await
        {
            tracing::warn!("[c35:billing] background usage report error req_id={req_id_bg}: {e:#}");
        }
        if let Some(ref session) = session_bg {
            if let Some(entry) =
                c35_mod_billing::billing_cache_get(nats_bg.as_ref(), owner_iid).await
            {
                owner_session_apply_billing_cached(session, entry);
            }
        }
    });

    let st = Instant::now();
    if !hooks.skip_chat_transcript_persist {
        let save_fut = sqlx::query(
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
        .bind(&assistant_content)
        .bind(&res.thought)
        .bind(&blocks_json)
        .bind(res.tokens_in)
        .bind(res.tokens_out)
        .bind(duration_ms)
        .bind(cost_usd)
        .bind(status)
        .bind(&error_text)
        .execute(pool);

        let sync_fut =
            crate::chat_sync::chat_touch(pool, nats, chat_id, owner_iid, &assistant_content, "done");

        let (save_res, sync_res) = tokio::join!(save_fut, sync_fut);
        save_res?;
        if let Err(e) = blob_ref_chat_msg(
            pool,
            chat_id,
            assistant_msg_id,
            owner_iid,
            "[]",
            &assistant_content,
            &blocks_json,
        )
        .await
        {
            tracing::warn!("blob_ref chat assistant msg_id={assistant_msg_id}: {e}");
        }
        let _ = sync_res;
        settle.seq("save_and_sync", "Save reply & chat sync", st);
    }

    let settle_ms = settle_started.elapsed().as_millis() as i64;
    tracer.trace_settle(&settle, settle_ms).await;
    tracer.flush().await;

    if let Some(ref session) = hooks.owner_session {
        if !hooks.skip_chat_transcript_persist {
            use crate::context_pack::HistoryRow;
            chat_cache_append_turn(
                session,
                chat_id,
                HistoryRow {
                    id: user_msg_id,
                    role: "user".into(),
                    content: user_content.clone(),
                    blocks_json: "[]".into(),
                },
                HistoryRow {
                    id: assistant_msg_id,
                    role: "assistant".into(),
                    content: assistant_content.clone(),
                    blocks_json: blocks_json.clone(),
                },
            );
        }
        let mut hint_tools = catalog_followup
            .as_ref()
            .map(|b| b.force_tools.clone())
            .unwrap_or_default();
        let mut hint_suffix = catalog_followup
            .as_ref()
            .map(|b| b.inst_suffix.clone())
            .unwrap_or_default();
        if let Some(c) = &commerce_followup {
            hint_tools.extend(c.force_tools.clone());
            hint_suffix.push_str(&c.inst_suffix);
        }
        if composed
            .matched_ids
            .iter()
            .any(|id| id == "inst.staff.registrations")
        {
            if !hint_tools
                .iter()
                .any(|t| t == "admin.user.registrations.list")
            {
                hint_tools.push("admin.user.registrations.list".into());
            }
            if hint_suffix.is_empty() {
                hint_suffix.push_str(
                    "[STAFF REGISTRATIONS FOLLOW-UP] Prefer admin.user.registrations.list for signup lists and counts; do not use web.search for platform users.",
                );
            }
        }
        if !hint_tools.is_empty() || !hint_suffix.is_empty() {
            session
                .write_state()
                .continuity
                .entry(chat_id)
                .or_default()
                .apply_hints(hint_tools, hint_suffix);
        }
    }

    Ok(PromptTurn {
        chat_id,
        user_msg_id,
        assistant_msg_id,
        text: assistant_content,
        thought: res.thought,
        blocks_json,
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
