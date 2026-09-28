use std::collections::HashSet;

use anyhow::Result;
use reqwest::Client;
use sqlx::PgPool;
use tracing::warn;

use crate::chunk::embed_normalize;
use crate::config::{
    data_source_retrieve_limit, data_source_retrieve_timeout, DATA_SOURCE_CHUNK_CANDIDATE_LIMIT, EMBED_DIMS,
    EMBED_MIN_CHARS,
};
use crate::store::{chunk_candidates_fts, chunk_candidates_recent, ChunkCand};
use c35_mod_llm::{
    embed_cache_key, embed_cache_put, embed_cached, embed_model_tag, embed_text, EMBED_TASK_DOCUMENT,
    EMBED_TASK_QUERY,
};

pub async fn data_source_chunk_retrieve(
    pool: &PgPool,
    http: &Client,
    data_source_ids: &[i64],
    query_text: &str,
    limit: usize,
) -> String {
    let limit = if limit > 0 { limit } else { data_source_retrieve_limit() };
    match tokio::time::timeout(
        data_source_retrieve_timeout(),
        data_source_chunk_retrieve_impl(pool, http, data_source_ids, query_text, limit),
    )
    .await
    {
        Ok(Ok(block)) => block,
        Ok(Err(e)) => {
            warn!("[c35:data_source] retrieve failed: {e:#}");
            String::new()
        }
        Err(_) => {
            warn!("[c35:data_source] retrieve timed out");
            String::new()
        }
    }
}

async fn data_source_chunk_retrieve_impl(
    pool: &PgPool,
    http: &Client,
    data_source_ids: &[i64],
    query_text: &str,
    limit: usize,
) -> Result<String> {
    if data_source_ids.is_empty() {
        return Ok(String::new());
    }
    let cands = chunk_candidates(pool, data_source_ids, query_text).await?;
    if cands.is_empty() {
        return Ok(String::new());
    }
    let qn = embed_normalize(query_text);
    if qn.chars().count() < EMBED_MIN_CHARS {
        let lines: Vec<String> = cands.into_iter().take(limit).map(|c| format!("- {}", c.content)).collect();
        return Ok(lines.join("\n"));
    }
    let query_vec = match embed_cached(pool, http, query_text, EMBED_TASK_QUERY, EMBED_DIMS).await {
        Ok(r) => r.embedding,
        Err(_) => {
            let lines: Vec<String> = cands.into_iter().take(limit).map(|c| format!("- {}", c.content)).collect();
            return Ok(lines.join("\n"));
        }
    };
    let model = embed_model_tag(c35_mod_llm::EMBED_MODEL, EMBED_DIMS);
    let mut scored: Vec<(String, f32)> = Vec::new();
    for cand in &cands {
        let payload = embed_normalize(&cand.content);
        let dkey = embed_cache_key(&payload, EMBED_TASK_DOCUMENT, EMBED_DIMS);
        let sim = if let Ok(r) = embed_cached(pool, http, &payload, EMBED_TASK_DOCUMENT, EMBED_DIMS).await {
            cosine_similarity(&query_vec, &r.embedding)
        } else if let Ok(out) = embed_text(http, &payload, EMBED_TASK_DOCUMENT, EMBED_DIMS).await {
            let _ = embed_cache_put(pool, &model, &dkey, &payload, EMBED_TASK_DOCUMENT, &out.embedding, out.token_in).await;
            cosine_similarity(&query_vec, &out.embedding)
        } else {
            f32::NEG_INFINITY
        };
        scored.push((cand.content.clone(), sim));
    }
    scored.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
    let lines: Vec<String> = scored.into_iter().take(limit).map(|(c, _)| format!("- {c}")).collect();
    Ok(lines.join("\n"))
}

async fn chunk_candidates(pool: &PgPool, data_source_ids: &[i64], query_text: &str) -> Result<Vec<ChunkCand>> {
    let mut by_key: HashSet<(i64, String)> = HashSet::new();
    let mut out: Vec<ChunkCand> = Vec::new();
    let q = query_text.trim();
    if !q.is_empty() {
        let fts = chunk_candidates_fts(pool, data_source_ids, q, DATA_SOURCE_CHUNK_CANDIDATE_LIMIT).await?;
        for c in fts {
            push_chunk(&mut by_key, &mut out, c);
        }
    }
    let recent = chunk_candidates_recent(pool, data_source_ids, DATA_SOURCE_CHUNK_CANDIDATE_LIMIT).await?;
    for c in recent {
        push_chunk(&mut by_key, &mut out, c);
    }
    Ok(out)
}

fn push_chunk(by_key: &mut HashSet<(i64, String)>, out: &mut Vec<ChunkCand>, c: ChunkCand) {
    if !by_key.insert((c.data_source_id, c.chunk_key.clone())) {
        return;
    }
    out.push(c);
}

fn cosine_similarity(a: &[f32], b: &[f32]) -> f32 {
    if a.len() != b.len() || a.is_empty() {
        return 0.0;
    }
    let dot: f32 = a.iter().zip(b.iter()).map(|(x, y)| x * y).sum();
    let na: f32 = a.iter().map(|x| x * x).sum::<f32>().sqrt();
    let nb: f32 = b.iter().map(|x| x * x).sum::<f32>().sqrt();
    if na == 0.0 || nb == 0.0 {
        0.0
    } else {
        dot / (na * nb)
    }
}
