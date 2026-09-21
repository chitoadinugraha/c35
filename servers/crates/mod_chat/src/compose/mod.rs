//! Compose inst match + lexical tool filter per turn.

mod topic;
mod tool_select;

use std::time::Instant;

use super::inst_macro::{inst_matched_prompt, inst_pick, inst_tool_directives, InstMatchCtx, InstRow};
use super::mention::MentionRow;
use super::tool_rag::{tool_find_lexical, tool_select as rag_tool_select, ToolCandidate, DEFAULT_TOOL_TOP_K, TOOL_RAG_MIN};
use crate::tools::ToolDef;

pub use topic::{tool_topic_eligible, topic_resolve};
pub use tool_select::tools_for_turn;

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
    pub selected_tools: Vec<String>,
    pub rag_skipped: bool,
    pub rag_skip_reason: String,
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
    explicit_topic: &str,
    tool_mode: &str,
    mentions: &[MentionRow],
) -> ComposeOutput {
    let started = Instant::now();
    let active_topic = topic_resolve(explicit_topic, mention_ids, mentions);
    let empty: [String; 0] = [];
    let matched = inst_pick(
        inst_rows,
        &InstMatchCtx {
            topic_id: &active_topic,
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
    let eligible_tools: Vec<ToolDef> = if ask_mode {
        eligible_tools.into_iter().filter(|t| t.readonly).collect()
    } else {
        eligible_tools
    };
    if ask_mode && eligible_tools.is_empty() {
        return ComposeOutput {
            inst_block,
            matched_ids: matched_ids.clone(),
            tools: vec![],
            trace: ComposeTrace {
                duration_ms: started.elapsed().as_millis() as i64,
                inst_ids: matched_ids,
                candidates: vec![],
                selected_tools: vec![],
                rag_skipped: true,
                rag_skip_reason: "ask_mode".into(),
            },
        };
    }

    let topic_filtered = tools_for_turn(&eligible_tools, &active_topic, &force_include, &tool_exclude, text);
    let selected_tools: Vec<String> = topic_filtered.iter().map(|t| t.name.clone()).collect();

    if eligible_tools.len() <= TOOL_RAG_MIN {
        let candidates = selected_tools
            .iter()
            .map(|id| ComposeTraceCandidate { tool_id: id.clone(), sim: 1.0, fed: true })
            .collect();
        return ComposeOutput {
            inst_block,
            matched_ids: matched_ids.clone(),
            tools: topic_filtered,
            trace: ComposeTrace {
                duration_ms: started.elapsed().as_millis() as i64,
                inst_ids: matched_ids,
                candidates,
                selected_tools,
                rag_skipped: true,
                rag_skip_reason: "few_tools".into(),
            },
        };
    }

    let force = super::tool_rag::canonicalize_tool_ids(&eligible_tools, &force_include);
    let exclude = super::tool_rag::canonicalize_tool_ids(&eligible_tools, &tool_exclude);
    let eligible: Vec<ToolDef> = eligible_tools
        .iter()
        .filter(|t| !exclude.iter().any(|x| x == &t.name))
        .filter(|t| tool_topic_eligible(&tool_def_topics(t), &active_topic))
        .cloned()
        .collect();
    let force: Vec<String> = force.into_iter().filter(|id| eligible.iter().any(|t| &t.name == id)).collect();

    let ranked = tool_find_lexical(text, &eligible, &force, &exclude, DEFAULT_TOOL_TOP_K);
    let ranked_ids: Vec<String> = ranked.iter().map(|c| c.tool_id.clone()).collect();
    let tools = rag_tool_select(&eligible, &ranked_ids, &force);
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
    let candidates = all_candidates
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
            candidates,
            selected_tools,
            rag_skipped: false,
            rag_skip_reason: String::new(),
        },
    }
}

fn tool_def_topics(t: &ToolDef) -> Vec<String> {
    if !t.topics.is_empty() {
        return t.topics.clone();
    }
    if t.name.starts_with("web.") || t.name == "img.generate" {
        return vec!["*".into()];
    }
    vec![]
}
