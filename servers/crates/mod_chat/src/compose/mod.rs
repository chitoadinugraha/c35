//! Compose inst match + lexical tool filter per turn.

mod mention_gate;
mod topic;
mod tool_select;

use std::time::Instant;

use super::inst_macro::{inst_matched_prompt, inst_pick, inst_tool_directives, InstMatchCtx, InstRow};
use super::mention::MentionRow;
use super::tool_rag::{
    tool_find_lexical, tool_select as rag_tool_select, tool_trim_ranked, ToolCandidate, DEFAULT_TOOL_SIM_GAP,
    DEFAULT_TOOL_SIM_THRESHOLD, DEFAULT_TOOL_TOP_K, TOOL_RAG_MIN,
};
use crate::mention_context::MentionContext;
use crate::site_capability::SiteCapabilityView;
use crate::tools::ToolDef;

pub use mention_gate::{
    tool_mention_capability_eligible, tool_mention_eligible, tool_mention_kinds_eligible,
};
pub use topic::{tool_topic_eligible, topic_resolve};
pub use tool_select::{tool_turn_eligible, tools_for_turn};

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
}

fn trace_dropped_gap(ranked: &[ToolCandidate], trimmed: &[ToolCandidate]) -> Vec<ComposeTraceCandidate> {
    let kept: std::collections::HashSet<&str> = trimmed.iter().map(|c| c.tool_id.as_str()).collect();
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
) -> ComposeOutput {
    let started = Instant::now();
    let topics: Vec<String> = if active_topics.is_empty() {
        vec![topic_resolve("", mention_ids, mentions)]
    } else {
        active_topics.to_vec()
    };
    let topic_refs: Vec<&str> = topics.iter().map(|t| t.as_str()).collect();
    let primary_topic = topic_refs.first().map(|t| *t).unwrap_or("general");
    let empty: [String; 0] = [];
    let matched = inst_pick(
        inst_rows,
        &InstMatchCtx {
            scopes,
            topic_id: primary_topic,
            text,
            mention_ids,
            signals: &empty,
        },
    );
    let matched_ids: Vec<String> = matched.iter().map(|r| r.id.clone()).collect();
    let inst_block = inst_matched_prompt(&matched);
    let (mut force_include, tool_exclude) = inst_tool_directives(&matched);
    for t in skill_tools {
        if !t.is_empty() && !force_include.iter().any(|x| x == t) {
            force_include.push(t.clone());
        }
    }

    let ask_mode = tool_mode == "ask";
    let eligible_tools: Vec<ToolDef> = eligible_tools
        .into_iter()
        .filter(|t| tool_mention_eligible(t, mention, caps))
        .filter(|t| !ask_mode || t.readonly)
        .collect();
    if ask_mode && eligible_tools.is_empty() {
        return ComposeOutput {
            inst_block,
            matched_ids: matched_ids.clone(),
            tools: vec![],
            trace: ComposeTrace {
                duration_ms: started.elapsed().as_millis() as i64,
                inst_ids: matched_ids,
                candidates: vec![],
                dropped_gap: vec![],
                selected_tools: vec![],
                rag_skipped: true,
                rag_skip_reason: "ask_mode".into(),
            },
        };
    }

    let force = super::tool_rag::canonicalize_tool_ids(&eligible_tools, &force_include);
    let exclude = super::tool_rag::canonicalize_tool_ids(&eligible_tools, &tool_exclude);
    let eligible: Vec<ToolDef> = eligible_tools
        .iter()
        .filter(|t| !exclude.iter().any(|x| x == &t.name))
        .filter(|t| tool_turn_eligible(t, &topic_refs))
        .cloned()
        .collect();
    let force: Vec<String> = force.into_iter().filter(|id| eligible.iter().any(|t| &t.name == id)).collect();

    let rag_skipped = eligible.len() <= TOOL_RAG_MIN;
    let (ranked, trimmed, tools) = if rag_skipped {
        let all = eligible
            .iter()
            .map(|t| ToolCandidate { tool_id: t.name.clone(), sim: 1.0 })
            .collect::<Vec<_>>();
        (all.clone(), all, eligible.clone())
    } else {
        let ranked = tool_find_lexical(text, &eligible, &force, &exclude, DEFAULT_TOOL_TOP_K);
        let trimmed = tool_trim_ranked(&ranked, &force, DEFAULT_TOOL_SIM_THRESHOLD, DEFAULT_TOOL_SIM_GAP);
        let ranked_ids: Vec<String> = trimmed.iter().map(|c| c.tool_id.clone()).collect();
        let tools = rag_tool_select(&eligible, &ranked_ids, &force);
        (ranked, trimmed, tools)
    };
    let selected_tools: Vec<String> = tools.iter().map(|t| t.name.clone()).collect();
    let selected_set: std::collections::HashSet<&str> = selected_tools.iter().map(|s| s.as_str()).collect();
    let mut all_candidates = ranked.clone();
    for t in &eligible {
        if all_candidates.iter().any(|c| c.tool_id == t.name) {
            continue;
        }
        all_candidates.push(ToolCandidate { tool_id: t.name.clone(), sim: 0.0 });
    }
    all_candidates.sort_by(|a, b| b.sim.partial_cmp(&a.sim).unwrap_or(std::cmp::Ordering::Equal));
    let candidates: Vec<ComposeTraceCandidate> = all_candidates
        .iter()
        .map(|c| ComposeTraceCandidate {
            tool_id: c.tool_id.clone(),
            sim: c.sim,
            fed: selected_set.contains(c.tool_id.as_str()),
        })
        .collect();

    ComposeOutput {
        inst_block,
        matched_ids: matched_ids.clone(),
        tools,
        trace: ComposeTrace {
            duration_ms: started.elapsed().as_millis() as i64,
            inst_ids: matched_ids,
            candidates: candidates.clone(),
            dropped_gap: trace_dropped_gap(&ranked, &trimmed),
            selected_tools,
            rag_skipped,
            rag_skip_reason: if rag_skipped { "few_tools".into() } else { String::new() },
        },
    }
}
