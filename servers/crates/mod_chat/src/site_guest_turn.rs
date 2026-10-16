//! Guest storefront AI prompt turn (published site scope, owner billing).

use std::time::Instant;

use anyhow::{Context, Result};
use c35_mod_billing::{billing_resolve, billing_usage_report, TurnBillingCtx};
use c35_mod_log::{log_put, LogPut};
use serde_json::json;
use sqlx::PgPool;
use tokio_util::sync::CancellationToken;

use crate::bot_meta::BOT_WEB_TOOL_EXCLUDE;
use crate::compose::{compose_tools_and_inst_async, ComposeTurnOpts};
use crate::catalog_web::CatalogWebPhase;
use crate::inst_cache::inst_list_for_turn;
use crate::inst_macro::{inst_pool_signal, inst_scopes_site_guest};
use crate::mention_context::MentionContext;
use crate::mention_registry::mention_ref_iid;
use crate::prompt::gemini::gemini_api_key;
use crate::prompt::thought::thinking_level;
use crate::prompt::time::{time_prompt_block, time_timezone_resolve};
use crate::prompt::tool_loop::prompt_cluster_turn;
use crate::prompt::ChatReq;
use crate::prompt_run::prompt_run_concurrency_acquire;
use crate::context_billing::ContextBillingExtra;
use crate::tools::{http_client, TurnCtx};
use crate::turn_tracer::TurnTracer;

#[allow(unused_imports)]
pub use crate::site_guest_context::{
    guest_call_enabled, guest_chat_enabled, guest_site_data_mode_from_boot_mode,
    knowledge_prompt_block, site_guest_chat_system_prompt, site_guest_context_prepare,
    site_guest_live_system_prompt, site_guest_live_tool_catalog, site_guest_tool_catalog,
    GuestContextError, GuestSiteContext, GuestSiteDataMode, ToolDeclaration,
    GUEST_KNOWLEDGE_MAX_CHARS, GUEST_KNOWLEDGE_MAX_ITEMS, SITE_GUEST_LIVE_VOICE_INSTRUCTIONS,
};

#[derive(Debug, Clone)]
pub struct SiteGuestTurnResult {
    pub text: String,
    pub blocks_json: String,
    pub tokens_in: i32,
    pub tokens_out: i32,
    pub cost_usd: f64,
    pub model: String,
    pub duration_ms: i32,
    pub inst_ids: Vec<String>,
}

async fn guest_staff_log(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    owner_iid: i64,
    site_iid: i64,
    visitor_id: &str,
    req_id: &str,
    user_text: &str,
    assistant_text: &str,
) {
    let meta = json!({
        "scope": "site_guest",
        "site_iid": site_iid,
        "visitor_id": visitor_id,
        "user": user_text.chars().take(2000).collect::<String>(),
        "assistant": assistant_text.chars().take(4000).collect::<String>(),
    });
    let _ = log_put(
        pool,
        nats,
        LogPut {
            class: Some("event"),
            owner_iid,
            kind: "site_guest",
            topic: "",
            dv: "",
            req_id: Some(req_id),
            chat_id: None,
            task_id: None,
            device_iid: None,
            text: user_text,
            model: "",
            tokens_in: 0,
            tokens_out: 0,
            duration_ms: 0,
            cost_usd: 0.0,
            meta,
        },
    )
    .await;
}

pub async fn site_guest_turn(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    site_iid: i64,
    visitor_id: &str,
    message: &str,
    req_id: &str,
) -> Result<SiteGuestTurnResult> {
    site_guest_turn_with_hooks(
        pool,
        nats,
        site_iid,
        visitor_id,
        message,
        req_id,
        GuestSiteDataMode::Published,
        None,
        None,
    )
    .await
}

pub async fn site_guest_turn_with_hooks(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    site_iid: i64,
    visitor_id: &str,
    message: &str,
    req_id: &str,
    data_mode: GuestSiteDataMode,
    on_delta: Option<&mut (dyn FnMut(bool, String) + Send)>,
    on_blocks: Option<&mut (dyn FnMut(String) + Send)>,
) -> Result<SiteGuestTurnResult> {
    if gemini_api_key().is_empty() {
        anyhow::bail!("GEMINI_API_KEY not set");
    }
    let visitor_id = visitor_id.trim();
    if visitor_id.is_empty() {
        anyhow::bail!("visitor_id required");
    }
    let text = message.trim();
    if text.is_empty() {
        anyhow::bail!("message required");
    }
    let guest_ctx = site_guest_context_prepare(pool, site_iid, data_mode).await?;
    guest_ctx.ensure_chat_enabled()?;
    let owner_iid = guest_ctx.owner_iid;
    let _concurrency = prompt_run_concurrency_acquire()
        .await
        .context("prompt turn concurrency limit")?;
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
    let brow = c35_mod_billing::billing_gate_scoped(pool, &bctx).await?;
    let model = "alienai".to_string();
    c35_mod_billing::billing_gate_with_hold_model(
        pool,
        owner_iid,
        &brow,
        req_id,
        c35_mod_billing::DEFAULT_HOLD_USD,
        Some(&model),
    )
    .await?;

    let mention = MentionContext::from_site(guest_ctx.site.clone());
    let caps = guest_ctx.caps.clone();
    let mention_ids = [mention_ref_iid(site_iid)];
    let inst_rows = inst_list_for_turn(pool).await;
    let inst_scopes = inst_scopes_site_guest();
    let http = http_client(std::time::Duration::from_secs(30));
    let tool_catalog = site_guest_live_tool_catalog(&guest_ctx);
    let extra_exclude: Vec<String> = BOT_WEB_TOOL_EXCLUDE
        .iter()
        .map(|s| s.to_string())
        .collect();
    let compose_signals = [inst_pool_signal(&model).to_string()];
    let compose_opts = ComposeTurnOpts {
        extra_signals: &compose_signals,
        extra_tool_exclude: &extra_exclude,
        skip_tool_rag: false,
        ..ComposeTurnOpts::default()
    };
    let composed = compose_tools_and_inst_async(
        pool,
        &http,
        &inst_rows,
        text,
        tool_catalog,
        &[],
        &mention_ids,
        &["site.guest".to_string()],
        "agent",
        &[],
        &inst_scopes,
        &mention,
        &caps,
        compose_opts,
        owner_iid,
        "",
        None,
    )
    .await;

    let tz = time_timezone_resolve("", "", text);
    let time_block = time_prompt_block(&tz);
    let system = site_guest_chat_system_prompt(&guest_ctx, &composed.inst_block, &time_block);

    let chat_id = 0_i64;
    let tracer = TurnTracer::new(pool.clone(), nats.cloned(), owner_iid, chat_id, req_id);
    tracer
        .trace_prepare(&composed.trace, text, 0, 0)
        .await;

    let chat_req = ChatReq {
        model,
        system,
        user: text.to_string(),
        thinking: thinking_level(""),
        tools: composed.tools.clone(),
        history: vec![],
        matched_inst_ids: composed.matched_ids.clone(),
        force_tool_call: false,
        force_web_tool_call: false,
        catalog_web: CatalogWebPhase::Off,
        skip_web_prefetch: true,
        device_prefetch: None,
    };

    let mut turn_ctx = TurnCtx {
        pool,
        nats,
        owner_iid,
        chat_id,
        site_iid: Some(site_iid),
        guest_visitor_id: Some(visitor_id),
        mention,
        mention_ids: &mention_ids,
        user_text: text,
        locale: "",
        location_city: "",
        location_region: "",
        location_country: "",
        attachments_json: "",
        req_id,
        run_kind: "site_guest",
        checkpoint: None,
        title_slot: std::sync::Arc::new(std::sync::Mutex::new(None)),
        doc_ocr: std::sync::Arc::new(std::sync::Mutex::new(ContextBillingExtra::default())),
        billing: Some(bctx.clone()),
    };
    let cancel = CancellationToken::new();
    let res = if let (Some(on_delta), Some(on_blocks)) = (on_delta, on_blocks) {
        match prompt_cluster_turn(
            &chat_req,
            on_delta,
            on_blocks,
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
        }
    } else {
        let mut noop_delta = |_: bool, _: String| {};
        let mut noop_blocks = |_: String| {};
        match prompt_cluster_turn(
            &chat_req,
            &mut noop_delta,
            &mut noop_blocks,
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
        }
    };

    let duration_ms = turn_started.elapsed().as_millis() as i32;
    let usage_meta = json!({
        "scope": "site_guest",
        "site_iid": site_iid,
        "visitor_id": visitor_id,
    });
    let billing = billing_usage_report(
        pool,
        nats,
        owner_iid,
        req_id,
        chat_id,
        &res.model_used,
        res.tokens_in,
        res.tokens_out,
        res.tokens_cached,
        duration_ms,
        Some(&bctx),
        res.tools_cost_usd + composed.trace.tool_embed_cost_usd,
        Some(usage_meta),
    )
    .await?;

    tracer
        .llm_turn(
            &res.model_used,
            res.tokens_in,
            res.tokens_out,
            res.tokens_cached,
            duration_ms as i64,
            0,
            billing.cost_usd,
            &res.text,
        )
        .await;

    guest_staff_log(
        pool,
        nats,
        owner_iid,
        site_iid,
        visitor_id,
        req_id,
        text,
        &res.text,
    )
    .await;

    Ok(SiteGuestTurnResult {
        text: res.text,
        blocks_json: res.blocks_json,
        tokens_in: res.tokens_in,
        tokens_out: res.tokens_out,
        cost_usd: billing.cost_usd,
        model: res.model_used,
        duration_ms,
        inst_ids: composed.matched_ids,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::inst_macro::{
        inst_pick, InstMatchCtx, InstRow, INST_SIGNAL_MODEL_ALIEN, SCOPE_ROLE_SITE_GUEST,
    };

    #[test]
    fn knowledge_prompt_block_caps_items() {
        let mut rows = Vec::new();
        for i in 0..60 {
            rows.push(json!({ "title": format!("t{i}"), "content": "x" }));
        }
        let block = knowledge_prompt_block(&json!({ "knowledge": rows }));
        assert!(block.contains("[SITE KNOWLEDGE]"));
        assert!(block.lines().count() <= GUEST_KNOWLEDGE_MAX_ITEMS + 1);
    }

    #[test]
    fn guest_chat_disabled_when_configured_off() {
        let meta = json!({
            "ai_assistant": { "configured": true, "chat_enabled": false }
        });
        assert!(!guest_chat_enabled(&meta));
    }

    #[test]
    fn site_guest_inst_scope_constant() {
        assert_eq!(SCOPE_ROLE_SITE_GUEST, "role:site_guest");
    }

    #[test]
    fn site_guest_tool_catalog_includes_cart_only_by_default() {
        let tools = site_guest_tool_catalog(false);
        let names: Vec<_> = tools.iter().map(|t| t.name.clone()).collect();
        assert!(names.contains(&"site.guest.cart.get".to_string()));
        assert!(!names.iter().any(|n| n == "site.tx.preview"));
    }

    #[test]
    fn site_guest_tool_catalog_adds_preview_when_commerce() {
        let tools = site_guest_tool_catalog(true);
        let names: Vec<_> = tools.iter().map(|t| t.name.clone()).collect();
        assert!(names.iter().any(|n| n == "site.tx.preview"));
    }

    #[test]
    fn guest_site_data_mode_parses_draft() {
        assert_eq!(
            guest_site_data_mode_from_boot_mode(Some("draft")),
            GuestSiteDataMode::Draft
        );
        assert_eq!(
            guest_site_data_mode_from_boot_mode(Some("published")),
            GuestSiteDataMode::Published
        );
        assert_eq!(
            guest_site_data_mode_from_boot_mode(None),
            GuestSiteDataMode::Published
        );
    }

    #[test]
    fn inst_site_guest_chat_row_matches_scope() {
        let row = InstRow {
            id: "inst.site.guest.chat".into(),
            scope: SCOPE_ROLE_SITE_GUEST.into(),
            kind: "trigger".into(),
            topic_id: String::new(),
            topics: vec![],
            inst: "guest assistant".into(),
            phrases: vec![],
            triggers: vec!["always".into()],
            include_tools: vec![],
            exclude_tools: vec![],
            requires_global_roles: vec![],
            priority: 100,
        };
        let scopes = inst_scopes_site_guest();
        let ctx = InstMatchCtx {
            scopes: &scopes,
            topic_id: "",
            active_topics: &["site.guest".to_string()],
            text: "harga kopi",
            mention_ids: &[],
            signals: &[],
            staff: None,
        };
        let matched = inst_pick(&[row], &ctx);
        assert_eq!(matched.len(), 1);
    }

    #[test]
    fn inst_site_guest_call_row_matches_live_signal() {
        let row = InstRow {
            id: "inst.site.guest.call".into(),
            scope: SCOPE_ROLE_SITE_GUEST.into(),
            kind: "trigger".into(),
            topic_id: "site.guest".into(),
            topics: vec![],
            inst: "guest voice call assistant".into(),
            phrases: vec!["call".into(), "telepon".into(), "bicara".into()],
            triggers: vec!["live:guest".into(), "live:voice".into()],
            include_tools: vec![
                "site.guest.cart.get".into(),
                "site.guest.cart.patch".into(),
                "site.tx.preview".into(),
            ],
            exclude_tools: vec!["web.search".into(), "web.visit".into()],
            requires_global_roles: vec![],
            priority: 190,
        };
        let scopes = inst_scopes_site_guest();
        let signals = [INST_SIGNAL_MODEL_ALIEN.to_string(), "live:guest".to_string()];
        let ctx = InstMatchCtx {
            scopes: &scopes,
            topic_id: "",
            active_topics: &["site.guest".to_string()],
            text: "bisa pesan menu apa saja?",
            mention_ids: &[],
            signals: &signals,
            staff: None,
        };
        let matched = inst_pick(&[row], &ctx);
        assert_eq!(matched.len(), 1);
        assert_eq!(matched[0].id, "inst.site.guest.call");
    }
}

