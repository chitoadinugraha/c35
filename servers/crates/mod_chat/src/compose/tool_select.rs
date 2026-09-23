use crate::tool_rag::{self, TOOL_RAG_MIN};
use crate::tools::ToolDef;
use super::topic::tool_topic_eligible;

fn tool_def_topics(t: &ToolDef) -> Vec<String> {
    if !t.topics.is_empty() {
        return t.topics.clone();
    }
    if t.name.starts_with("web.") {
        return vec!["*".into()];
    }
    vec![]
}

fn tool_def_always(t: &ToolDef, active_topic: &str) -> bool {
    t.always.iter().any(|x| x == "*" || x == active_topic)
}

pub fn tool_turn_eligible(t: &ToolDef, active_topic: &str) -> bool {
    tool_topic_eligible(&tool_def_topics(t), active_topic) || tool_def_always(t, active_topic)
}

pub fn tools_for_turn(
    defs: &[ToolDef],
    active_topic: &str,
    force_include: &[String],
    exclude: &[String],
    text: &str,
) -> Vec<ToolDef> {
    let eligible: Vec<ToolDef> = defs
        .iter()
        .filter(|t| tool_turn_eligible(t, active_topic))
        .filter(|t| !exclude.iter().any(|x| x == &t.name))
        .cloned()
        .collect();
    if eligible.is_empty() {
        return vec![];
    }

    let mut force: Vec<String> = eligible
        .iter()
        .filter(|t| tool_def_always(t, active_topic))
        .map(|t| t.name.clone())
        .collect();
    for id in tool_rag::canonicalize_tool_ids(&eligible, force_include) {
        if !force.iter().any(|x| x == &id) {
            force.push(id);
        }
    }

    if eligible.len() <= TOOL_RAG_MIN {
        return tool_rag::tools_for_turn_lexical(&eligible, text, &force, exclude);
    }
    tool_rag::tools_for_turn_lexical(&eligible, text, &force, exclude)
}
