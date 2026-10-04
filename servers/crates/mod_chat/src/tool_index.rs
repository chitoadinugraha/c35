//! Boot tool embed index — DB cache + in-memory vectors for vector tool RAG.

use std::sync::{Arc, OnceLock};
use std::time::Instant;

use c35_mod_billing::billing_embed_cost_usd;
use futures_util::future::join_all;
use reqwest::Client;
use sqlx::PgPool;
use tokio::sync::Semaphore;
use tracing::{info, warn};

use c35_mod_llm::{
    embed_cache_get_many_touch, embed_cache_key, embed_cached, embed_model_tag, EMBED_DIMENSIONS_DEFAULT,
    EMBED_MODEL, EMBED_TASK_DOCUMENT, EMBED_TASK_QUERY,
};

use crate::tool_rag::{
    cosine_similarity, ToolCandidate, DEFAULT_TOOL_SIM_GAP, DEFAULT_TOOL_SIM_THRESHOLD, DEFAULT_TOOL_TOP_K,
};
use crate::tools::{default_dispatcher, ToolDef};

static TOOL_INDEX: OnceLock<Vec<IndexedTool>> = OnceLock::new();

const TOOL_INDEX_EMBED_PARALLEL_DEFAULT: usize = 8;

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

fn tool_index_embed_parallel() -> usize {
    std::env::var("C35_TOOL_INDEX_EMBED_PARALLEL")
        .ok()
        .and_then(|s| s.parse().ok())
        .filter(|&n| (1..=32).contains(&n))
        .unwrap_or(TOOL_INDEX_EMBED_PARALLEL_DEFAULT)
}

/// Boot: load tool vectors from embed cache; embed and store misses (parallel API, durable cache).
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

    let mut indexed: Vec<IndexedTool> = Vec::with_capacity(defs.len());
    let mut cache_hits = 0usize;
    let mut misses: Vec<(String, String)> = Vec::new();

    for (i, def) in defs.iter().enumerate() {
        if let Some(vec) = cached.get(i).and_then(|v| v.clone()) {
            cache_hits += 1;
            if !vec.is_empty() {
                indexed.push(IndexedTool {
                    tool_id: def.name.clone(),
                    embedding: vec,
                });
            }
            continue;
        }
        misses.push((def.name.clone(), texts[i].clone()));
    }

    let cache_misses = misses.len();
    if !misses.is_empty() {
        let parallel = tool_index_embed_parallel();
        let sem = Arc::new(Semaphore::new(parallel));
        let pool = pool.clone();
        let http = http.clone();
        let fetched = join_all(misses.into_iter().map(|(tool_id, text)| {
            let sem = sem.clone();
            let pool = pool.clone();
            let http = http.clone();
            async move {
                let _permit = sem
                    .acquire()
                    .await
                    .map_err(|e| format!("tool index embed {tool_id}: {e}"))?;
                let out = embed_cached(&pool, &http, &text, task, EMBED_DIMENSIONS_DEFAULT)
                    .await
                    .map_err(|e| format!("tool index embed {tool_id}: {e}"))?;
                if out.embedding.is_empty() {
                    return Err(format!("tool index embed {tool_id}: empty vector"));
                }
                Ok(IndexedTool {
                    tool_id,
                    embedding: out.embedding,
                })
            }
        }))
        .await;
        for item in fetched {
            indexed.push(item?);
        }
    }

    let n = indexed.len();
    let _ = TOOL_INDEX.set(indexed);
    info!(
        "tool_index: {n} tools ({cache_hits} cache hits, {cache_misses} embed API calls, parallel={})",
        if cache_misses > 0 { tool_index_embed_parallel() } else { 0 }
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
    pub embed_ms: i64,
    pub filter_ms: i64,
    pub embed_token_in: i32,
    pub embed_cost_usd: f64,
    pub embed_model: String,
}

/// Vector-rank eligible tools. Returns empty ranked when index not ready or embed fails.
pub async fn tool_find_vector(
    pool: &PgPool,
    http: &Client,
    query: &str,
    eligible: &[ToolDef],
) -> ToolFindResult {
    let empty = |embed_model: String| ToolFindResult {
        ranked: vec![],
        best_sim: 0.0,
        query_cached: false,
        ranker: "vector",
        embed_ms: 0,
        filter_ms: 0,
        embed_token_in: 0,
        embed_cost_usd: 0.0,
        embed_model,
    };
    let embed_model = embed_model_tag(EMBED_MODEL, EMBED_DIMENSIONS_DEFAULT);
    let txt = query.trim();
    if txt.is_empty() || eligible.is_empty() {
        return empty(embed_model);
    }
    let Some(index) = TOOL_INDEX.get() else {
        return empty(embed_model);
    };
    if index.is_empty() {
        return empty(embed_model);
    }

    let embed_t0 = Instant::now();
    let embed = match embed_cached(pool, http, txt, EMBED_TASK_QUERY, EMBED_DIMENSIONS_DEFAULT).await {
        Ok(r) => r,
        Err(e) => {
            warn!("tool_find_vector embed failed: {e}");
            return empty(embed_model);
        }
    };
    let embed_ms = embed_t0.elapsed().as_millis() as i64;
    let embed_token_in = embed.token_in;
    let embed_cost_usd = billing_embed_cost_usd(&embed_model, embed_token_in);

    let rank_t0 = Instant::now();
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

    let filter_ms = rank_t0.elapsed().as_millis() as i64;
    ToolFindResult {
        ranked,
        best_sim,
        query_cached: embed.cached,
        ranker: "vector",
        embed_ms,
        filter_ms,
        embed_token_in,
        embed_cost_usd,
        embed_model,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tool_index_embed_parallel_default_and_env() {
        std::env::remove_var("C35_TOOL_INDEX_EMBED_PARALLEL");
        assert_eq!(tool_index_embed_parallel(), TOOL_INDEX_EMBED_PARALLEL_DEFAULT);
        std::env::set_var("C35_TOOL_INDEX_EMBED_PARALLEL", "4");
        assert_eq!(tool_index_embed_parallel(), 4);
        std::env::set_var("C35_TOOL_INDEX_EMBED_PARALLEL", "99");
        assert_eq!(tool_index_embed_parallel(), TOOL_INDEX_EMBED_PARALLEL_DEFAULT);
        std::env::remove_var("C35_TOOL_INDEX_EMBED_PARALLEL");
    }
}
