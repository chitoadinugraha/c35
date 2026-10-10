//! Compose inst match + vector/lexical tool filter per turn.

mod mail_gate;
mod mention_gate;
mod staff_gate;
mod tool_select;
mod topic;

use std::time::Instant;

use reqwest::Client;
use sqlx::PgPool;

use super::inst_macro::{
    inst_matched_prompt, inst_pick, inst_text_site_builder_intent, inst_tool_directives,
    InstMatchCtx, InstRow,
};
use super::mention::MentionRow;
use super::tool_index::{tool_find_vector, tool_index_ready, ToolFindResult};
use super::tool_rag::{
    tool_find_lexical, tool_select as rag_tool_select, tool_trim_ranked, ToolCandidate,
    DEFAULT_TOOL_SIM_GAP, DEFAULT_TOOL_SIM_THRESHOLD, DEFAULT_TOOL_TOP_K, LEXICAL_SIM_THRESHOLD,
    TOOL_RAG_MIN,
};
use c35_mod_admin::StaffView;

use crate::mention_context::MentionContext;
use crate::site_capability::SiteCapabilityView;
use crate::tools::ToolDef;

pub use mail_gate::tool_platform_mail_eligible;
pub use mention_gate::{
    tool_mention_capability_eligible, tool_mention_eligible, tool_mention_kinds_eligible,
};
pub use staff_gate::tool_staff_eligible;
pub use tool_select::{
    compose_bot_web_tools_inject, compose_force_bot_web, compose_force_general_web,
    compose_inject_force_tools, tool_turn_eligible, tools_for_turn,
};
pub use topic::{tool_topic_eligible, topic_resolve};

#[derive(Clone, Copy)]
pub struct ComposeTurnOpts<'a> {
    pub extra_signals: &'a [String],
    pub extra_tool_include: &'a [String],
    pub extra_tool_exclude: &'a [String],
    pub extra_inst_suffix: &'a str,
    pub bot_web_search: bool,
    pub attachments_json: &'a str,
    pub skip_tool_rag: bool,
}

impl<'a> Default for ComposeTurnOpts<'a> {
    fn default() -> Self {
        Self {
            extra_signals: &[],
            extra_tool_include: &[],
            extra_tool_exclude: &[],
            extra_inst_suffix: "",
            bot_web_search: false,
            attachments_json: "[]",
            skip_tool_rag: false,
        }
    }
}

/// First LLM hop must call web.search when web-search inst matched.
pub fn compose_force_web_tool_call(
    matched_ids: &[String],
    tools: &[ToolDef],
    user_text: &str,
) -> bool {
    if matched_ids.iter().any(|id| {
        id == "inst.mention.sheets"
            || id == "inst.sheets.topic"
            || id == "inst.device.facts"
            || id == "inst.device.android"
            || id.starts_with("inst.mention.device_")
            || id == "inst.browser.topic"
    }) {
        return false;
    }
    if crate::site_commerce_compose::site_commerce_suppress_web_tool_call(
        user_text,
        matched_ids,
    ) {
        return false;
    }
    matched_ids.iter().any(|id| id == "inst.web_search")
        && tools.iter().any(|t| t.name == "web.search")
}

/// First LLM hop must call presentation.create when presentation inst matched.
pub fn compose_force_presentation_tool_call(matched_ids: &[String], tools: &[ToolDef]) -> bool {
    matched_ids.iter().any(|id| id == "inst.presentation")
        && tools.iter().any(|t| t.name == "presentation.create")
}

/// First LLM hop must call consumption.today when nutrition coach inst matched.
pub fn compose_force_consumption_coach_tool_call(
    matched_ids: &[String],
    tools: &[ToolDef],
) -> bool {
    matched_ids.iter().any(|id| id == "inst.consumption_coach")
        && tools.iter().any(|t| t.name == "consumption.today")
}

fn tools_has(tools: &[ToolDef], name: &str) -> bool {
    tools.iter().any(|t| t.name == name)
}

/// First LLM hop must call account / device.pair tools when matching inst rows are fed.
pub fn compose_force_account_tool_call(matched_ids: &[String], tools: &[ToolDef]) -> bool {
    matched_ids.iter().any(|id| match id.as_str() {
        "inst.account.profile" => tools_has(tools, "account.get"),
        "inst.account.billing" => {
            tools_has(tools, "account.billing.get") || tools_has(tools, "account.billing.history")
        }
        "inst.account.referral" => {
            tools_has(tools, "account.referral.stats")
                || tools_has(tools, "account.referral.ledger")
        }
        "inst.account.snapshot" => tools_has(tools, "account.snapshot"),
        "inst.account.assets" => {
            tools_has(tools, "bot.list")
                || tools_has(tools, "device.list")
                || tools_has(tools, "site.list")
                || tools_has(tools, "client.list")
        }
        "inst.device.pair" => tools_has(tools, "device.pair"),
        _ => false,
    })
}

/// Force site.create only after discovery — user explicitly asks to generate the site.
pub fn compose_force_site_builder_tool_call(
    matched_ids: &[String],
    tools: &[ToolDef],
    user_text: &str,
) -> bool {
    if !matched_ids.iter().any(|id| id == "inst.site.builder") {
        return false;
    }
    if !tools.iter().any(|t| t.name == "site.create") {
        return false;
    }
    site_builder_ready_to_create(user_text)
}

/// User gave site-creation intent plus catalog/POS details — skip discovery and create in hop 1.
pub fn site_builder_bootstrap_catalog(text: &str) -> bool {
    if !inst_text_site_builder_intent(text) {
        return false;
    }
    let lower = text.trim().to_lowercase();
    lower.contains("fitur pos")
        || (lower.contains("produk") && lower.contains("harga"))
        || (lower.contains("pos") && lower.contains("produk"))
}

pub fn site_builder_ready_to_create(text: &str) -> bool {
    if site_builder_bootstrap_catalog(text) {
        return true;
    }
    let lower = text.trim().to_lowercase();
    if lower.is_empty() {
        return false;
    }
    const READY: &[&str] = &[
        "buat sitenya",
        "bikin sitenya",
        "buatkan sitenya",
        "buatkan websitenya",
        "lanjut buat",
        "silakan buat",
        "ok buat",
        "oke buat",
        "generate sitenya",
        "create the site",
        "build the site",
        "build it now",
        "just create",
        "create now",
        "generate the site",
        "publish draft",
    ];
    READY.iter().any(|p| lower.contains(p))
}

/// First LLM hop must call a tool when a force-* inst matched and its tool is available.
/// Menu-photo catalog add must call `site.product_put` on hop 1 (inst owns the price scale).
pub fn compose_force_catalog_menu_tool_call(matched_ids: &[String], tools: &[ToolDef]) -> bool {
    matched_ids
        .iter()
        .any(|id| id == "inst.site.catalog.add.menu")
        && tools.iter().any(|t| t.name == "site.product_put")
}

pub use crate::site_commerce_compose::SITE_QUERY_FORCE_INSTS;

pub fn compose_force_site_query_tool_call(matched_ids: &[String], tools: &[ToolDef]) -> bool {
    matched_ids
        .iter()
        .any(|id| SITE_QUERY_FORCE_INSTS.iter().any(|want| want == id))
        && tools.iter().any(|t| t.name == "site.query.run")
}

pub fn compose_force_tool_call(matched_ids: &[String], tools: &[ToolDef]) -> bool {
    compose_force_web_tool_call(matched_ids, tools, "")
        || compose_force_presentation_tool_call(matched_ids, tools)
        || compose_force_consumption_coach_tool_call(matched_ids, tools)
        || compose_force_account_tool_call(matched_ids, tools)
        || compose_force_catalog_menu_tool_call(matched_ids, tools)
        || compose_force_site_query_tool_call(matched_ids, tools)
}

pub fn compose_force_tool_call_with_text(
    matched_ids: &[String],
    tools: &[ToolDef],
    user_text: &str,
) -> bool {
    compose_force_web_tool_call(matched_ids, tools, user_text)
        || compose_force_presentation_tool_call(matched_ids, tools)
        || compose_force_consumption_coach_tool_call(matched_ids, tools)
        || compose_force_account_tool_call(matched_ids, tools)
        || compose_force_catalog_menu_tool_call(matched_ids, tools)
        || compose_force_site_query_tool_call(matched_ids, tools)
        || compose_force_site_builder_tool_call(matched_ids, tools, user_text)
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct ComposeTraceCandidate {
    pub tool_id: String,
    pub sim: f32,
    pub fed: bool,
}

#[derive(Debug, Clone, Default, serde::Serialize)]
pub struct ComposeTrace {
    pub duration_ms: i64,
    pub inst_ids: Vec<String>,
    pub candidates: Vec<ComposeTraceCandidate>,
    pub dropped_gap: Vec<ComposeTraceCandidate>,
    pub selected_tools: Vec<String>,
    pub rag_skipped: bool,
    pub rag_skip_reason: String,
    #[serde(default)]
    pub ranker: String,
    #[serde(default)]
    pub best_sim: f32,
    #[serde(default)]
    pub embed_cached: bool,
    #[serde(default)]
    pub inst_enrich_keys: Vec<String>,
    #[serde(default)]
    pub inst_enrich_ms: i64,
    #[serde(default)]
    pub tool_filter_ms: i64,
    #[serde(default)]
    pub tool_embed_ms: i64,
    #[serde(default)]
    pub tool_embed_token_in: i32,
    #[serde(default)]
    pub tool_embed_cost_usd: f64,
    #[serde(default)]
    pub tool_embed_model: String,
    #[serde(default)]
    pub tool_embed_cached: bool,
}

fn trace_dropped_gap(
    ranked: &[ToolCandidate],
    trimmed: &[ToolCandidate],
) -> Vec<ComposeTraceCandidate> {
    let kept: std::collections::HashSet<&str> =
        trimmed.iter().map(|c| c.tool_id.as_str()).collect();
    ranked
        .iter()
        .filter(|c| !kept.contains(c.tool_id.as_str()))
        .take(8)
        .map(|c| ComposeTraceCandidate {
            tool_id: c.tool_id.clone(),
            sim: c.sim,
            fed: false,
        })
        .collect()
}

pub struct ComposeOutput {
    pub inst_block: String,
    pub matched_ids: Vec<String>,
    pub tools: Vec<ToolDef>,
    pub trace: ComposeTrace,
}

struct ComposePrep {
    inst_block: String,
    matched_ids: Vec<String>,
    matched: Vec<InstRow>,
    eligible: Vec<ToolDef>,
    force: Vec<String>,
    exclude: Vec<String>,
    rag_skipped: bool,
}

fn ranked_with_forced(ranked: &[ToolCandidate], force: &[String]) -> Vec<ToolCandidate> {
    let mut out = ranked.to_vec();
    let mut seen: std::collections::HashSet<String> =
        out.iter().map(|c| c.tool_id.clone()).collect();
    for id in force {
        if seen.insert(id.clone()) {
            out.push(ToolCandidate {
                tool_id: id.clone(),
                sim: 0.95,
            });
        }
    }
    out.sort_by(|a, b| {
        b.sim
            .partial_cmp(&a.sim)
            .unwrap_or(std::cmp::Ordering::Equal)
    });
    out
}

fn compose_tools_ranked(
    text: &str,
    eligible: &[ToolDef],
    force: &[String],
    exclude: &[String],
    rag_skipped: bool,
    vector_find: Option<&ToolFindResult>,
) -> (
    Vec<ToolCandidate>,
    Vec<ToolCandidate>,
    Vec<ToolDef>,
    String,
    f32,
    bool,
) {
    if rag_skipped {
        let all = eligible
            .iter()
            .map(|t| ToolCandidate {
                tool_id: t.name.clone(),
                sim: 1.0,
            })
            .collect::<Vec<_>>();
        return (
            all.clone(),
            all,
            eligible.to_vec(),
            "all".into(),
            1.0,
            false,
        );
    }

    if let Some(vf) = vector_find {
        if !vf.ranked.is_empty() {
            let ranked = ranked_with_forced(&vf.ranked, force);
            let trimmed = tool_trim_ranked(
                &ranked,
                force,
                DEFAULT_TOOL_SIM_THRESHOLD,
                DEFAULT_TOOL_SIM_GAP,
            );
            let ranked_ids: Vec<String> = trimmed.iter().map(|c| c.tool_id.clone()).collect();
            let mut tools = rag_tool_select(eligible, &ranked_ids, force);
            for id in force {
                if tools.iter().any(|t| &t.name == id) {
                    continue;
                }
                if let Some(t) = eligible.iter().find(|t| &t.name == id) {
                    tools.push(t.clone());
                }
            }
            return (
                ranked,
                trimmed,
                tools,
                vf.ranker.to_string(),
                vf.best_sim,
                vf.query_cached,
            );
        }
    }

    let ranked = tool_find_lexical(text, eligible, force, exclude, DEFAULT_TOOL_TOP_K);
    let trimmed = tool_trim_ranked(&ranked, force, LEXICAL_SIM_THRESHOLD, DEFAULT_TOOL_SIM_GAP);
    let ranked_ids: Vec<String> = trimmed.iter().map(|c| c.tool_id.clone()).collect();
    let mut tools = if trimmed.is_empty() && !eligible.is_empty() {
        eligible.to_vec()
    } else {
        rag_tool_select(eligible, &ranked_ids, force)
    };
    for id in force {
        if tools.iter().any(|t| &t.name == id) {
            continue;
        }
        if let Some(t) = eligible.iter().find(|t| &t.name == id) {
            tools.push(t.clone());
        }
    }
    let best = ranked.first().map(|c| c.sim).unwrap_or(0.0);
    (ranked, trimmed, tools, "lexical".into(), best, false)
}

fn compose_prepare_scoped(
    inst_rows: &[InstRow],
    text: &str,
    eligible_tools: Vec<ToolDef>,
    skill_tools: &[String],
    mention_ids: &[String],
    active_topics: &[String],
    tool_mode: &str,
    mentions: &[MentionRow],
    scopes: &[String],
    mention: &MentionContext,
    caps: &SiteCapabilityView,
    staff: &StaffView,
    platform_mail: bool,
    opts: ComposeTurnOpts<'_>,
) -> Result<ComposePrep, ComposeOutput> {
    let mut topics: Vec<String> = if active_topics.is_empty() {
        vec![topic_resolve("", mention_ids, mentions)]
    } else {
        active_topics.to_vec()
    };
    let primary_topic = topics.first().map(|t| t.as_str()).unwrap_or("general");
    let signal_slice: &[String] = if opts.extra_signals.is_empty() {
        &[]
    } else {
        opts.extra_signals
    };
    let matched = inst_pick(
        inst_rows,
        &InstMatchCtx {
            scopes,
            topic_id: primary_topic,
            active_topics: &topics,
            text,
            mention_ids,
            signals: signal_slice,
            staff: Some(staff),
        },
    );
    if matched.iter().any(|r| r.id == "inst.presentation")
        && !topics.iter().any(|t| t == "presentation")
    {
        topics.push("presentation".into());
    }
    let topic_refs: Vec<&str> = topics.iter().map(|t| t.as_str()).collect();
    let primary_topic = topic_refs.first().map(|t| *t).unwrap_or("general");
    let matched_ids: Vec<String> = matched.iter().map(|r| r.id.clone()).collect();
    let mut inst_block = inst_matched_prompt(&matched);
    if !opts.extra_inst_suffix.trim().is_empty() {
        if !inst_block.is_empty() {
            inst_block.push_str("\n\n");
        }
        inst_block.push_str(opts.extra_inst_suffix.trim());
    }
    let (mut force_include, mut tool_exclude) = inst_tool_directives(&matched);
    for t in opts.extra_tool_exclude {
        if !t.is_empty() && !tool_exclude.iter().any(|x| x == t) {
            tool_exclude.push(t.to_string());
        }
    }
    for t in opts.extra_tool_include {
        if !t.is_empty() && !force_include.iter().any(|x| x == t) {
            force_include.push(t.to_string());
        }
    }
    let has_site_context = !mention.sites.is_empty();
    for t in crate::site_commerce_compose::site_commerce_extra_tool_include(
        text,
        &matched_ids,
        has_site_context,
    ) {
        if !force_include.iter().any(|x| x == &t) {
            force_include.push(t);
        }
    }
    for t in crate::site_commerce_compose::site_commerce_extra_tool_exclude(text, &matched_ids) {
        if !t.is_empty() && !tool_exclude.iter().any(|x| x == &t) {
            tool_exclude.push(t);
        }
    }
    for t in skill_tools {
        if !t.is_empty() && !force_include.iter().any(|x| x == t) {
            force_include.push(t.clone());
        }
    }

    let ask_mode = tool_mode == "ask";
    let tool_catalog = eligible_tools.clone();
    let eligible_tools: Vec<ToolDef> = eligible_tools
        .into_iter()
        .filter(|t| tool_mention_eligible(t, mention, caps))
        .filter(|t| tool_staff_eligible(t, staff))
        .filter(|t| tool_platform_mail_eligible(t, platform_mail))
        .filter(|t| !ask_mode || t.readonly)
        .collect();
    if !crate::site_commerce_compose::site_commerce_suppress_general_web(text, &matched_ids) {
        compose_force_general_web(&eligible_tools, &topic_refs, &mut force_include);
    }
    if opts.bot_web_search && primary_topic == "bot" {
        compose_force_bot_web(&eligible_tools, &mut force_include);
    }

    if ask_mode && eligible_tools.is_empty() {
        return Err(ComposeOutput {
            inst_block,
            matched_ids: matched_ids.clone(),
            tools: vec![],
            trace: ComposeTrace {
                duration_ms: 0,
                inst_ids: matched_ids,
                candidates: vec![],
                dropped_gap: vec![],
                selected_tools: vec![],
                rag_skipped: true,
                rag_skip_reason: "ask_mode".into(),
                ranker: String::new(),
                best_sim: 0.0,
                embed_cached: false,
                ..Default::default()
            },
        });
    }

    let force = super::tool_rag::canonicalize_tool_ids(&tool_catalog, &force_include);
    let exclude = super::tool_rag::canonicalize_tool_ids(&tool_catalog, &tool_exclude);
    let mut eligible: Vec<ToolDef> = eligible_tools
        .iter()
        .filter(|t| !exclude.iter().any(|x| x == &t.name))
        .filter(|t| tool_turn_eligible(t, &topic_refs))
        .cloned()
        .collect();
    if opts.bot_web_search && primary_topic == "bot" {
        compose_bot_web_tools_inject(&tool_catalog, &mut eligible, &exclude);
    }
    compose_inject_force_tools(&tool_catalog, &mut eligible, &force_include, &exclude);
    if ask_mode {
        eligible.retain(|t| t.readonly);
    }
    let force: Vec<String> = force
        .into_iter()
        .filter(|id| eligible.iter().any(|t| &t.name == id))
        .collect();
    let rag_skipped = eligible.len() <= TOOL_RAG_MIN;

    Ok(ComposePrep {
        inst_block,
        matched_ids,
        matched,
        eligible,
        force,
        exclude,
        rag_skipped,
    })
}

fn compose_finish(
    started: Instant,
    prep: ComposePrep,
    text: &str,
    vector_find: Option<&ToolFindResult>,
) -> ComposeOutput {
    let (ranked, trimmed, tools, ranker, best_sim, embed_cached) = compose_tools_ranked(
        text,
        &prep.eligible,
        &prep.force,
        &prep.exclude,
        prep.rag_skipped,
        vector_find,
    );
    let selected_tools: Vec<String> = tools.iter().map(|t| t.name.clone()).collect();
    let selected_set: std::collections::HashSet<&str> =
        selected_tools.iter().map(|s| s.as_str()).collect();
    let mut all_candidates = ranked.clone();
    for t in &prep.eligible {
        if all_candidates.iter().any(|c| c.tool_id == t.name) {
            continue;
        }
        all_candidates.push(ToolCandidate {
            tool_id: t.name.clone(),
            sim: 0.0,
        });
    }
    all_candidates.sort_by(|a, b| {
        b.sim
            .partial_cmp(&a.sim)
            .unwrap_or(std::cmp::Ordering::Equal)
    });
    let candidates: Vec<ComposeTraceCandidate> = all_candidates
        .iter()
        .map(|c| ComposeTraceCandidate {
            tool_id: c.tool_id.clone(),
            sim: c.sim,
            fed: selected_set.contains(c.tool_id.as_str()),
        })
        .collect();

    ComposeOutput {
        inst_block: prep.inst_block,
        matched_ids: prep.matched_ids.clone(),
        tools,
        trace: ComposeTrace {
            duration_ms: started.elapsed().as_millis() as i64,
            inst_ids: prep.matched_ids,
            candidates,
            dropped_gap: trace_dropped_gap(&ranked, &trimmed),
            selected_tools,
            rag_skipped: prep.rag_skipped,
            rag_skip_reason: if prep.rag_skipped {
                "few_tools".into()
            } else {
                String::new()
            },
            ranker,
            best_sim,
            embed_cached,
            ..Default::default()
        },
    }
}

pub async fn compose_tools_and_inst_async(
    pool: &PgPool,
    http: &Client,
    inst_rows: &[InstRow],
    text: &str,
    eligible_tools: Vec<ToolDef>,
    skill_tools: &[String],
    mention_ids: &[String],
    active_topics: &[String],
    tool_mode: &str,
    mentions: &[MentionRow],
    scopes: &[String],
    mention: &MentionContext,
    caps: &SiteCapabilityView,
    opts: ComposeTurnOpts<'_>,
    owner_iid: i64,
    locale: &str,
) -> ComposeOutput {
    let started = Instant::now();
    let staff = c35_mod_admin::staff_view_load(pool, owner_iid).await;
    let platform_mail = c35_mod_mail::mail_access(pool, owner_iid)
        .await
        .unwrap_or(false);
    let prep = match compose_prepare_scoped(
        inst_rows,
        text,
        eligible_tools,
        skill_tools,
        mention_ids,
        active_topics,
        tool_mode,
        mentions,
        scopes,
        mention,
        caps,
        &staff,
        platform_mail,
        opts,
    ) {
        Ok(p) => p,
        Err(out) => {
            return ComposeOutput {
                inst_block: out.inst_block,
                matched_ids: out.matched_ids,
                tools: out.tools,
                trace: ComposeTrace {
                    duration_ms: started.elapsed().as_millis() as i64,
                    ..out.trace
                },
            };
        }
    };

    let locale_eff = if locale.trim().is_empty() {
        "id-ID"
    } else {
        locale.trim()
    };
    let enrich_ctx = crate::inst_enrich::InstEnrichCtx {
        pool,
        owner_iid,
        locale: locale_eff,
        user_text: text,
        attachments_json: opts.attachments_json,
    };
    let matched = prep.matched.clone();
    let eligible = prep.eligible.clone();
    let rag_skipped = prep.rag_skipped;
    let parallel_start = Instant::now();

    let ((enrich_res, enrich_ms), vector_find) = tokio::join!(
        async {
            let t = Instant::now();
            let r = crate::inst_enrich::inst_enrich_append(&matched, &enrich_ctx).await;
            (r, t.elapsed().as_millis() as i64)
        },
        async {
            if rag_skipped || opts.skip_tool_rag || !tool_index_ready() {
                None
            } else {
                Some(tool_find_vector(pool, http, text, &eligible).await)
            }
        }
    );

    let mut prep = prep;
    prep.inst_block.push_str(&enrich_res.suffix);
    let parallel_ms = parallel_start.elapsed().as_millis() as i64;
    let mut out = compose_finish(started, prep, text, vector_find.as_ref());
    out.trace.duration_ms = parallel_ms;
    out.trace.inst_enrich_ms = enrich_ms;
    out.trace.inst_enrich_keys = enrich_res.keys;
    if let Some(vf) = vector_find.as_ref() {
        out.trace.tool_filter_ms = vf.filter_ms;
        out.trace.tool_embed_ms = vf.embed_ms;
        out.trace.tool_embed_token_in = vf.embed_token_in;
        out.trace.tool_embed_cost_usd = vf.embed_cost_usd;
        out.trace.tool_embed_model = vf.embed_model.clone();
        out.trace.tool_embed_cached = vf.query_cached;
        out.trace.embed_cached = vf.query_cached;
    }
    out
}

pub fn compose_tools_and_inst(
    inst_rows: &[InstRow],
    text: &str,
    eligible_tools: Vec<ToolDef>,
    skill_tools: &[String],
    mention_ids: &[String],
    active_topics: &[String],
    tool_mode: &str,
    mentions: &[MentionRow],
    scopes: &[String],
    mention: &MentionContext,
    caps: &SiteCapabilityView,
    opts: ComposeTurnOpts<'_>,
) -> ComposeOutput {
    let started = Instant::now();
    let staff = StaffView::default();
    let prep = match compose_prepare_scoped(
        inst_rows,
        text,
        eligible_tools,
        skill_tools,
        mention_ids,
        active_topics,
        tool_mode,
        mentions,
        scopes,
        mention,
        caps,
        &staff,
        false,
        opts,
    ) {
        Ok(p) => p,
        Err(out) => {
            return ComposeOutput {
                inst_block: out.inst_block,
                matched_ids: out.matched_ids,
                tools: out.tools,
                trace: ComposeTrace {
                    duration_ms: started.elapsed().as_millis() as i64,
                    ..out.trace
                },
            };
        }
    };
    compose_finish(started, prep, text, None)
}
