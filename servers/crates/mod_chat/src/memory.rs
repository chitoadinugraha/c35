use std::time::{Duration, Instant};

use anyhow::Result;
use c35_mod_llm::{embed_cache_key, embed_cached, embed_cache_put, embed_text, EMBED_TASK_DOCUMENT, EMBED_TASK_QUERY};
use c35_store::snowflake_id;
use reqwest::Client;
use sqlx::PgPool;
use tracing::warn;

const MEMORY_CANDIDATE_LIMIT: i64 = 32;
const MEMORY_RETRIEVE_TIMEOUT: Duration = Duration::from_millis(800);
const EMBED_DIMS: i32 = 768;

#[derive(Clone, Debug, Default, serde::Serialize)]
pub struct MemoryRetrieveTrace {
    pub duration_ms: i64,
    pub memory_count: i32,
    pub embed_ms: i64,
    pub embed_cached: bool,
    pub embed_skipped: bool,
}

pub struct MemoryRetrieveResult {
    pub block: String,
    pub trace: MemoryRetrieveTrace,
}

impl Default for MemoryRetrieveResult {
    fn default() -> Self {
        Self { block: String::new(), trace: MemoryRetrieveTrace::default() }
    }
}

pub fn memory_prompt_block(rows: &[(String, String)]) -> String {
    if rows.is_empty() {
        return String::new();
    }
    let lines: Vec<String> = rows
        .iter()
        .filter_map(|(k, c)| {
            let c = c.trim();
            if c.is_empty() {
                return None;
            }
            let k = k.trim();
            Some(if k.is_empty() { format!("- {c}") } else { format!("- {k}: {c}") })
        })
        .collect();
    if lines.is_empty() {
        String::new()
    } else {
        format!("## Memory\n{}", lines.join("\n"))
    }
}

pub fn memory_prompt_merge(base: &str, block: &str) -> String {
    let block = block.trim();
    if block.is_empty() {
        return base.to_string();
    }
    if base.trim().is_empty() {
        return block.to_string();
    }
    format!("{base}\n\n{block}")
}

pub async fn memory_put(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: Option<i64>,
    key: &str,
    content: &str,
    category: &str,
    source_req_id: &str,
) -> Result<i64> {
    let content_hash = blake3::hash(format!("{}: {}", key.trim(), content.trim()).as_bytes()).to_hex().to_string();
    let existing: Option<i64> = if let Some(bid) = bot_iid {
        sqlx::query_scalar(
            "SELECT id FROM ai.memory WHERE owner_iid = $1 AND bot_iid = $2 AND key = $3 AND deleted_ts IS NULL",
        )
        .bind(owner_iid)
        .bind(bid)
        .bind(key)
        .fetch_optional(pool)
        .await?
    } else {
        sqlx::query_scalar(
            "SELECT id FROM ai.memory WHERE owner_iid = $1 AND bot_iid IS NULL AND key = $2 AND deleted_ts IS NULL",
        )
        .bind(owner_iid)
        .bind(key)
        .fetch_optional(pool)
        .await?
    };
    if let Some(id) = existing {
        sqlx::query(
            "UPDATE ai.memory SET content = $2, category = $3, source_req_id = $4, content_hash = $5, updated_ts = NOW() WHERE id = $1",
        )
        .bind(id)
        .bind(content)
        .bind(category)
        .bind(source_req_id)
        .bind(&content_hash)
        .execute(pool)
        .await?;
        return Ok(id);
    }
    let id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.memory (id, owner_iid, bot_iid, category, key, content, source_req_id, content_hash, updated_ts)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
        "#,
    )
    .bind(id)
    .bind(owner_iid)
    .bind(bot_iid)
    .bind(category)
    .bind(key)
    .bind(content)
    .bind(source_req_id)
    .bind(&content_hash)
    .execute(pool)
    .await?;
    Ok(id)
}

pub async fn memory_retrieve(
    pool: &PgPool,
    http: &Client,
    owner_iid: i64,
    bot_iid: Option<i64>,
    query_text: &str,
    limit: usize,
) -> MemoryRetrieveResult {
    let started = Instant::now();
    match tokio::time::timeout(
        MEMORY_RETRIEVE_TIMEOUT,
        memory_retrieve_impl(pool, http, owner_iid, bot_iid, query_text, limit.max(1)),
    )
    .await
    {
        Ok(Ok((block, mut trace))) => {
            trace.duration_ms = started.elapsed().as_millis() as i64;
            MemoryRetrieveResult { block, trace }
        }
        Ok(Err(e)) => {
            warn!("[c35:memory] retrieve failed owner_iid={owner_iid}: {e:#}");
            MemoryRetrieveResult::default()
        }
        Err(_) => {
            warn!("[c35:memory] retrieve timed out owner_iid={owner_iid}");
            MemoryRetrieveResult::default()
        }
    }
}

async fn memory_retrieve_impl(
    pool: &PgPool,
    http: &Client,
    owner_iid: i64,
    bot_iid: Option<i64>,
    query_text: &str,
    limit: usize,
) -> Result<(String, MemoryRetrieveTrace)> {
    let mut trace = MemoryRetrieveTrace::default();
    let cands = memory_candidates(pool, owner_iid, bot_iid, query_text).await?;
    if cands.is_empty() {
        return Ok((String::new(), trace));
    }
    let q = query_text.trim();
    if q.is_empty() {
        let rows: Vec<(String, String)> = cands.into_iter().take(limit).map(|c| (c.key, c.content)).collect();
        trace.memory_count = rows.len() as i32;
        return Ok((memory_prompt_block(&rows), trace));
    }

    let embed_t0 = Instant::now();
    let model = c35_mod_llm::embed_model_tag("gemini-embedding-2", EMBED_DIMS);
    let query_vec = match embed_cached(pool, http, q, EMBED_TASK_QUERY, EMBED_DIMS).await {
        Ok(r) => {
            trace.embed_cached = r.cached;
            trace.embed_ms = embed_t0.elapsed().as_millis() as i64;
            r.embedding
        }
        Err(_) => {
            trace.embed_skipped = true;
            let rows: Vec<(String, String)> = cands.into_iter().take(limit).map(|c| (c.key, c.content)).collect();
            trace.memory_count = rows.len() as i32;
            return Ok((memory_prompt_block(&rows), trace));
        }
    };

    let mut scored: Vec<(String, String, f32)> = Vec::new();
    for cand in &cands {
        let payload = format!("{}: {}", cand.key, cand.content);
        let dkey = embed_cache_key(&payload, EMBED_TASK_DOCUMENT, EMBED_DIMS);
        let doc_vec = if let Ok(r) = embed_cached(pool, http, &payload, EMBED_TASK_DOCUMENT, EMBED_DIMS).await {
            r.embedding
        } else if let Ok(v) = embed_text(http, &payload, EMBED_TASK_DOCUMENT, EMBED_DIMS).await {
            let _ = embed_cache_put(pool, &model, &dkey, &payload, EMBED_TASK_DOCUMENT, &v, 0).await;
            v
        } else {
            continue;
        };
        scored.push((cand.key.clone(), cand.content.clone(), cosine_similarity(&query_vec, &doc_vec)));
    }

    if scored.is_empty() {
        let rows: Vec<(String, String)> = cands.into_iter().take(limit).map(|c| (c.key, c.content)).collect();
        trace.memory_count = rows.len() as i32;
        return Ok((memory_prompt_block(&rows), trace));
    }
    scored.sort_by(|a, b| b.2.partial_cmp(&a.2).unwrap_or(std::cmp::Ordering::Equal));
    let rows: Vec<(String, String)> = scored.into_iter().take(limit).map(|(k, c, _)| (k, c)).collect();
    trace.memory_count = rows.len() as i32;
    Ok((memory_prompt_block(&rows), trace))
}

struct MemoryCand {
    key: String,
    content: String,
}

async fn memory_candidates(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: Option<i64>,
    query_text: &str,
) -> Result<Vec<MemoryCand>> {
    let q = query_text.trim();
    let rows = if q.is_empty() {
        if let Some(bid) = bot_iid {
            sqlx::query_as::<_, (String, String)>(
                "SELECT key, content FROM ai.memory WHERE owner_iid = $1 AND (bot_iid IS NULL OR bot_iid = $2) \
                 AND is_active = true AND deleted_ts IS NULL ORDER BY updated_ts DESC LIMIT $3",
            )
            .bind(owner_iid)
            .bind(bid)
            .bind(MEMORY_CANDIDATE_LIMIT)
            .fetch_all(pool)
            .await?
        } else {
            sqlx::query_as::<_, (String, String)>(
                "SELECT key, content FROM ai.memory WHERE owner_iid = $1 AND bot_iid IS NULL \
                 AND is_active = true AND deleted_ts IS NULL ORDER BY updated_ts DESC LIMIT $2",
            )
            .bind(owner_iid)
            .bind(MEMORY_CANDIDATE_LIMIT)
            .fetch_all(pool)
            .await?
        }
    } else if let Some(bid) = bot_iid {
        sqlx::query_as::<_, (String, String)>(
            "SELECT key, content FROM ai.memory WHERE owner_iid = $1 AND (bot_iid IS NULL OR bot_iid = $2) \
             AND is_active = true AND deleted_ts IS NULL \
             AND tsv @@ plainto_tsquery('english', $3) ORDER BY ts_rank(tsv, plainto_tsquery('english', $3)) DESC LIMIT $4",
        )
        .bind(owner_iid)
        .bind(bid)
        .bind(q)
        .bind(MEMORY_CANDIDATE_LIMIT)
        .fetch_all(pool)
        .await?
    } else {
        sqlx::query_as::<_, (String, String)>(
            "SELECT key, content FROM ai.memory WHERE owner_iid = $1 AND bot_iid IS NULL \
             AND is_active = true AND deleted_ts IS NULL \
             AND tsv @@ plainto_tsquery('english', $2) ORDER BY ts_rank(tsv, plainto_tsquery('english', $2)) DESC LIMIT $3",
        )
        .bind(owner_iid)
        .bind(q)
        .bind(MEMORY_CANDIDATE_LIMIT)
        .fetch_all(pool)
        .await?
    };
    Ok(rows.into_iter().map(|(key, content)| MemoryCand { key, content }).collect())
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
