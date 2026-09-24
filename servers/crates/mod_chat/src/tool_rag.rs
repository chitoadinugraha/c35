//! Tool RAG — lexical rank + cosine helpers.

use crate::tools::ToolDef;

pub const TOOL_RAG_MIN: usize = 2;
pub const DEFAULT_TOOL_TOP_K: usize = 5;
pub const DEFAULT_TOOL_SIM_THRESHOLD: f32 = 0.6;
pub const DEFAULT_TOOL_SIM_GAP: f32 = 0.05;

#[derive(Debug, Clone)]
pub struct ToolAct {
    pub id: String,
    pub embedding: Vec<f32>,
}

#[derive(Debug, Clone)]
pub struct ToolCandidate {
    pub tool_id: String,
    pub sim: f32,
}

pub fn cosine_similarity(a: &[f32], b: &[f32]) -> f32 {
    if a.is_empty() || a.len() != b.len() {
        return 0.0;
    }
    let (dot, na, nb) = a
        .iter()
        .zip(b.iter())
        .fold((0.0f32, 0.0f32, 0.0f32), |(d, na, nb), (x, y)| (d + x * y, na + x * x, nb + y * y));
    let denom = na.sqrt() * nb.sqrt();
    if denom == 0.0 { 0.0 } else { dot / denom }
}

fn tool_id_norm(s: &str) -> String {
    s.replace('_', ".")
}

pub fn canonicalize_tool_id(eligible: &[ToolDef], id: &str) -> Option<String> {
    let want = tool_id_norm(id);
    eligible
        .iter()
        .find(|t| tool_id_norm(&t.name) == want || t.aliases.iter().any(|a| tool_id_norm(a) == want || a == id))
        .map(|t| t.name.clone())
}

pub fn canonicalize_tool_ids(eligible: &[ToolDef], ids: &[String]) -> Vec<String> {
    let mut out = Vec::new();
    for id in ids {
        if let Some(c) = canonicalize_tool_id(eligible, id) {
            if !out.iter().any(|x| x == &c) {
                out.push(c);
            }
        }
    }
    out
}

fn lexical_tokens(s: &str) -> Vec<String> {
    s.to_ascii_lowercase()
        .split(|c: char| !c.is_ascii_alphanumeric())
        .filter(|t| t.len() >= 2)
        .map(|t| t.to_string())
        .collect()
}

fn lexical_sim(query_tokens: &[String], hay: &str) -> f32 {
    if query_tokens.is_empty() {
        return 0.0;
    }
    let hay_tokens = lexical_tokens(hay);
    if hay_tokens.is_empty() {
        return 0.0;
    }
    let hits = query_tokens
        .iter()
        .filter(|t| hay_tokens.iter().any(|h| h == *t || h.contains(t.as_str()) || t.contains(h.as_str())))
        .count();
    hits as f32 / query_tokens.len() as f32
}

pub fn tool_find_lexical(
    query: &str,
    tools: &[ToolDef],
    force_include: &[String],
    tool_exclude: &[String],
    top_k: usize,
) -> Vec<ToolCandidate> {
    let q = lexical_tokens(query);
    let mut forced: Vec<ToolCandidate> = Vec::new();
    let mut scored: Vec<ToolCandidate> = Vec::new();
    for t in tools {
        if tool_exclude.iter().any(|x| x == &t.name) {
            continue;
        }
        let hay = format!(
            "{} {} {}",
            t.name.replace('_', " ").replace('.', " "),
            t.description,
            t.aliases.join(" ")
        );
        let sim = lexical_sim(&q, &hay);
        let included = force_include.iter().any(|x| x == &t.name);
        if included {
            forced.push(ToolCandidate { tool_id: t.name.clone(), sim: sim.max(0.95) });
            continue;
        }
        if sim > 0.12 {
            scored.push(ToolCandidate { tool_id: t.name.clone(), sim });
        }
    }
    forced.sort_by(|a, b| b.sim.partial_cmp(&a.sim).unwrap_or(std::cmp::Ordering::Equal));
    scored.sort_by(|a, b| b.sim.partial_cmp(&a.sim).unwrap_or(std::cmp::Ordering::Equal));
    if scored.len() > top_k {
        scored.truncate(top_k);
    }
    let remain = top_k.saturating_sub(forced.len());
    let mut out = forced;
    out.extend(scored.into_iter().take(remain));
    out
}

/// Keep forced tools plus scores within [threshold, top−gap] of the best match.
pub fn tool_trim_ranked(
    candidates: &[ToolCandidate],
    force_include: &[String],
    threshold: f32,
    gap: f32,
) -> Vec<ToolCandidate> {
    if candidates.is_empty() {
        return vec![];
    }
    let force: std::collections::HashSet<&str> = force_include.iter().map(|s| s.as_str()).collect();
    let mut sorted: Vec<ToolCandidate> = candidates.to_vec();
    sorted.sort_by(|a, b| b.sim.partial_cmp(&a.sim).unwrap_or(std::cmp::Ordering::Equal));
    let mut out: Vec<ToolCandidate> = Vec::new();
    let mut seen = std::collections::HashSet::new();
    for c in &sorted {
        if force.contains(c.tool_id.as_str()) && seen.insert(c.tool_id.clone()) {
            out.push(c.clone());
        }
    }
    let anchor = sorted[0].sim;
    for c in &sorted {
        if seen.contains(&c.tool_id) {
            continue;
        }
        if c.sim < threshold {
            continue;
        }
        if anchor - c.sim > gap + 0.001 {
            continue;
        }
        if seen.insert(c.tool_id.clone()) {
            out.push(c.clone());
        }
    }
    if out.is_empty() {
        out.push(sorted[0].clone());
    }
    out.sort_by(|a, b| b.sim.partial_cmp(&a.sim).unwrap_or(std::cmp::Ordering::Equal));
    out
}

pub fn tool_select(eligible: &[ToolDef], ranked_ids: &[String], force_include: &[String]) -> Vec<ToolDef> {
    let mut out = Vec::new();
    let mut seen = std::collections::HashSet::new();
    for id in force_include.iter().chain(ranked_ids.iter()) {
        if !seen.insert(id.clone()) {
            continue;
        }
        if let Some(t) = eligible.iter().find(|t| &t.name == id) {
            out.push(t.clone());
        }
    }
    out
}

pub fn tools_for_turn_lexical(
    eligible: &[ToolDef],
    query: &str,
    force_include: &[String],
    tool_exclude: &[String],
) -> Vec<ToolDef> {
    let force = canonicalize_tool_ids(eligible, force_include);
    let exclude = canonicalize_tool_ids(eligible, tool_exclude);
    let eligible: Vec<ToolDef> = eligible
        .iter()
        .filter(|t| !exclude.iter().any(|x| x == &t.name))
        .cloned()
        .collect();
    if eligible.len() <= TOOL_RAG_MIN {
        return eligible;
    }
    let force: Vec<String> = force.into_iter().filter(|id| eligible.iter().any(|t| &t.name == id)).collect();
    let ranked = tool_find_lexical(query, &eligible, &force, &exclude, DEFAULT_TOOL_TOP_K);
    let ids: Vec<String> = ranked.into_iter().map(|c| c.tool_id).collect();
    let selected = tool_select(&eligible, &ids, &force);
    if selected.is_empty() { eligible } else { selected }
}
