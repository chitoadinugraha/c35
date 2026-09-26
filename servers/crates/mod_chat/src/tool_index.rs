//! Boot tool embed index — DB cache + in-memory vectors for vector tool RAG.

use std::sync::OnceLock;

use reqwest::Client;
use sqlx::PgPool;
use tracing::{info, warn};

use c35_mod_llm::{
    embed_cache_get_many_touch, embed_cache_key, embed_cache_put, embed_cached, embed_model_tag,
    EMBED_DIMENSIONS_DEFAULT, EMBED_MODEL, EMBED_TASK_DOCUMENT, EMBED_TASK_QUERY,
};
use c35_mod_llm::embed_text;

use crate::tool_rag::{cosine_similarity, ToolCandidate, DEFAULT_TOOL_SIM_GAP, DEFAULT_TOOL_SIM_THRESHOLD, DEFAULT_TOOL_TOP_K};
use crate::tools::{default_dispatcher, ToolDef};

static TOOL_INDEX: OnceLock<Vec<IndexedTool>> = OnceLock::new();

#[derive(Clone)]
struct IndexedTool {
    tool_id: String,
    embedding: Vec<f32>,
}

pub fn tool_definition_text(def: &ToolDef) -> String {
    let mut parts = vec![def.name.clone()];
    let desc = def.description.trim();
    if !desc.is_empty() {
        parts.push(desc.to_string());
    }
    for a in &def.aliases {
        let t = a.trim();
        if !t.is_empty() {
            parts.push(t.to_string());
        }
    }
    for p in &def.rag_phrases {
        let t = p.trim();
        if !t.is_empty() {
            parts.push(t.to_string());
        }
    }
    parts.join("\n")
}

/// Boot: load tool vectors from embed cache; embed and store misses.
pub async fn tool_index_init(pool: &PgPool, http: &Client) -> Result<usize, String> {
    if TOOL_INDEX.get().is_some() {
        return Ok(TOOL_INDEX.get().map(|v| v.len()).unwrap_or(0));
    }
    let defs: Vec<ToolDef> = default_dispatcher()
        .definitions()
        .iter()
        .map(ToolDef::from_definition)
        .collect();
    if defs.is_empty() {
        let _ = TOOL_INDEX.set(Vec::new());
        return Ok(0);
    }

    let model = embed_model_tag(EMBED_MODEL, EMBED_DIMENSIONS_DEFAULT);
    let task = EMBED_TASK_DOCUMENT;
    let texts: Vec<String> = defs.iter().map(tool_definition_text).collect();
    let keys: Vec<String> = texts
        .iter()
        .map(|t| embed_cache_key(t, task, EMBED_DIMENSIONS_DEFAULT))
        .collect();

    let cached = embed_cache_get_many_touch(pool, &model, &keys)
        .await
        .map_err(|e| e.to_string())?;

    let mut indexed: Vec<IndexedTool> = Vec::new();
    let mut cache_hits = 0usize;
    let mut cache_misses = 0usize;

    for (i, def) in defs.iter().enumerate() {
        let text = &texts[i];
        let key = &keys[i];
        let embedding = if let Some(vec) = cached.get(i).and_then(|v| v.clone()) {
            cache_hits += 1;
            vec
        } else {
            cache_misses += 1;
            let vec = embed_text(http, text, task, EMBED_DIMENSIONS_DEFAULT)
                .await
                .map_err(|e| format!("tool index embed {}: {e}", def.name))?;
            let _ = embed_cache_put(pool, &model, key, text, task, &vec, 0).await;
            vec
        };
        if !embedding.is_empty() {
            indexed.push(IndexedTool {
                tool_id: def.name.clone(),
                embedding,
            });
        }
    }

    let n = indexed.len();
    let _ = TOOL_INDEX.set(indexed);
    info!(
        "tool_index: {n} tools ({cache_hits} cache hits, {cache_misses} embed API calls)"
    );
    Ok(n)
}

pub fn tool_index_ready() -> bool {
    TOOL_INDEX.get().is_some()
}

#[derive(Debug, Clone)]
pub struct ToolFindResult {
    pub ranked: Vec<ToolCandidate>,
    pub best_sim: f32,
    pub query_cached: bool,
    pub ranker: &'static str,
}

/// Vector-rank eligible tools. Returns empty ranked when index not ready or embed fails.
pub async fn tool_find_vector(
    pool: &PgPool,
    http: &Client,
    query: &str,
    eligible: &[ToolDef],
) -> ToolFindResult {
    let empty = ToolFindResult {
        ranked: vec![],
        best_sim: 0.0,
        query_cached: false,
        ranker: "vector",
    };
    let txt = query.trim();
    if txt.is_empty() || eligible.is_empty() {
        return empty;
    }
    let Some(index) = TOOL_INDEX.get() else {
        return empty;
    };
    if index.is_empty() {
        return empty;
    }

    let embed = match embed_cached(pool, http, txt, EMBED_TASK_QUERY, EMBED_DIMENSIONS_DEFAULT).await {
        Ok(r) => r,
        Err(e) => {
            warn!("tool_find_vector embed failed: {e}");
            return empty;
        }
    };

    let eligible_ids: std::collections::HashSet<&str> =
        eligible.iter().map(|t| t.name.as_str()).collect();
    let mut scored: Vec<ToolCandidate> = Vec::new();
    let mut best_sim = 0.0f32;

    for item in index {
        if !eligible_ids.contains(item.tool_id.as_str()) {
            continue;
        }
        let sim = cosine_similarity(&embed.embedding, &item.embedding);
        if sim > best_sim {
            best_sim = sim;
        }
        if sim > DEFAULT_TOOL_SIM_THRESHOLD {
            scored.push(ToolCandidate {
                tool_id: item.tool_id.clone(),
                sim,
            });
        }
    }

    scored.sort_by(|a, b| b.sim.partial_cmp(&a.sim).unwrap_or(std::cmp::Ordering::Equal));
    if scored.len() > DEFAULT_TOOL_TOP_K {
        scored.truncate(DEFAULT_TOOL_TOP_K);
    }

    let mut ranked = Vec::new();
    if let Some(first) = scored.first() {
        ranked.push(first.clone());
        for c in scored.iter().skip(1) {
            if first.sim - c.sim <= DEFAULT_TOOL_SIM_GAP + 0.001 {
                ranked.push(c.clone());
            } else {
                break;
            }
        }
    }

    ToolFindResult {
        ranked,
        best_sim,
        query_cached: embed.cached,
        ranker: "vector",
    }
}
