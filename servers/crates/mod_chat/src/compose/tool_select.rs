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

/// Force web.search on general topic; pair web.visit so the model can read URLs from results.
pub fn compose_force_general_web(eligible: &[ToolDef], active_topics: &[&str], force_include: &mut Vec<String>) {
    if !active_topics.iter().any(|t| *t == "general") {
        return;
    }
    let has = |name: &str| eligible.iter().any(|t| t.name == name);
    if has("web.search") && !force_include.iter().any(|x| x == "web.search") {
        force_include.push("web.search".into());
    }
    if force_include.iter().any(|x| x == "web.search") && has("web.visit") && !force_include.iter().any(|x| x == "web.visit") {
        force_include.push("web.visit".into());
    }
}

pub fn tool_turn_eligible(t: &ToolDef, active_topics: &[&str]) -> bool {
    active_topics
        .iter()
        .any(|topic| tool_topic_eligible(&tool_def_topics(t), topic) || tool_def_always(t, topic))
}

pub fn tools_for_turn(
    defs: &[ToolDef],
    active_topics: &[&str],
    force_include: &[String],
    exclude: &[String],
    text: &str,
) -> Vec<ToolDef> {
    let eligible: Vec<ToolDef> = defs
        .iter()
        .filter(|t| tool_turn_eligible(t, active_topics))
        .filter(|t| !exclude.iter().any(|x| x == &t.name))
        .cloned()
        .collect();
    if eligible.is_empty() {
        return vec![];
    }

    let mut force: Vec<String> = eligible
        .iter()
        .filter(|t| active_topics.iter().any(|topic| tool_def_always(t, topic)))
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
