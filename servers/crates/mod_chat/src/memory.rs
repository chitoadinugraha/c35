use std::time::{Duration, Instant};

use anyhow::Result;
use c35_mod_billing::billing_embed_cost_usd;
use c35_mod_llm::{
    embed_cached, embed_model_tag, embed_text, EMBED_MODEL, EMBED_TASK_DOCUMENT, EMBED_TASK_QUERY,
};
use c35_store::snowflake_id;
use reqwest::Client;
use sqlx::types::Json;
use sqlx::PgPool;
use tracing::warn;

const MEMORY_CANDIDATE_LIMIT: i64 = 32;
const MEMORY_PINNED_LIMIT: i64 = 4;
const MEMORY_SIM_FLOOR: f32 = 0.50;
const MEMORY_RETRIEVE_TIMEOUT: Duration = Duration::from_millis(3500);
const MEMORY_EMBED_TIMEOUT: Duration = Duration::from_millis(2000);
const EMBED_DIMS: i32 = 768;

#[derive(Clone, Debug, Default, serde::Serialize)]
pub struct MemoryRetrieveTrace {
    pub duration_ms: i64,
    pub memory_count: i32,
    pub embed_ms: i64,
    pub embed_cached: bool,
    pub embed_skipped: bool,
    pub embed_token_in: i32,
    pub embed_cost_usd: f64,
    pub embed_model: String,
    pub pinned_count: i32,
    pub active_count: i32,
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
        format!(
            "## Memory\nKnown facts about the user. Use naturally without reciting. If the user's current message contradicts a stored fact, follow the user.\n{}",
            lines.join("\n")
        )
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
    let http = Client::builder().timeout(Duration::from_secs(15)).build().unwrap_or_default();
    memory_put_with_client(pool, &http, owner_iid, bot_iid, key, content, category, source_req_id).await
}

pub async fn memory_put_with_client(
    pool: &PgPool,
    http: &Client,
    owner_iid: i64,
    bot_iid: Option<i64>,
    key: &str,
    content: &str,
    category: &str,
    source_req_id: &str,
) -> Result<i64> {
    let content_hash = blake3::hash(format!("{}: {}", key.trim(), content.trim()).as_bytes()).to_hex().to_string();
    let payload = format!("{}: {}", key.trim(), content.trim());
    let embed_vec = match embed_cached(pool, http, &payload, EMBED_TASK_DOCUMENT, EMBED_DIMS).await {
        Ok(r) => Some(r.embedding),
        Err(e) => {
            warn!("[c35:memory] embed_cached failed for '{payload}': {e}");
            match embed_text(http, &payload, EMBED_TASK_DOCUMENT, EMBED_DIMS).await {
                Ok(r) => Some(r.embedding),
                Err(e2) => {
                    warn!("[c35:memory] embed_text fallback failed: {e2:#}");
                    None
                }
            }
        }
    };
    let embed_json = embed_vec.and_then(|v| serde_json::to_value(v).ok()).map(Json);

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
            "UPDATE ai.memory SET content = $2, category = $3, source_req_id = $4, content_hash = $5, embedding_json = $6, is_active = true, updated_ts = NOW() WHERE id = $1",
        )
        .bind(id)
        .bind(content)
        .bind(category)
        .bind(source_req_id)
        .bind(&content_hash)
        .bind(embed_json)
        .execute(pool)
        .await?;
        return Ok(id);
    }
    let id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.memory (id, owner_iid, bot_iid, category, key, content, source_req_id, content_hash, embedding_json, is_active, updated_ts)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, true, NOW())
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
    .bind(embed_json)
    .execute(pool)
    .await?;
    Ok(id)
}

pub async fn memory_delete(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: Option<i64>,
    key: &str,
) -> Result<bool> {
    let res = if let Some(bid) = bot_iid {
        sqlx::query(
            "UPDATE ai.memory SET is_active = false, deleted_ts = NOW(), updated_ts = NOW() \
             WHERE owner_iid = $1 AND bot_iid = $2 AND key = $3 AND deleted_ts IS NULL",
        )
        .bind(owner_iid)
        .bind(bid)
        .bind(key)
        .execute(pool)
        .await?
    } else {
        sqlx::query(
            "UPDATE ai.memory SET is_active = false, deleted_ts = NOW(), updated_ts = NOW() \
             WHERE owner_iid = $1 AND bot_iid IS NULL AND key = $2 AND deleted_ts IS NULL",
        )
        .bind(owner_iid)
        .bind(key)
        .execute(pool)
        .await?
    };
    Ok(res.rows_affected() > 0)
}

pub async fn memory_list_active(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: Option<i64>,
    limit: i64,
) -> Result<Vec<(String, String)>> {
    let rows = if let Some(bid) = bot_iid {
        sqlx::query_as::<_, (String, String)>(
            "SELECT key, content FROM ai.memory WHERE owner_iid = $1 AND (bot_iid IS NULL OR bot_iid = $2) \
             AND is_active = true AND deleted_ts IS NULL ORDER BY updated_ts DESC LIMIT $3",
        )
        .bind(owner_iid)
        .bind(bid)
        .bind(limit)
        .fetch_all(pool)
        .await?
    } else {
        sqlx::query_as::<_, (String, String)>(
            "SELECT key, content FROM ai.memory WHERE owner_iid = $1 AND bot_iid IS NULL \
             AND is_active = true AND deleted_ts IS NULL ORDER BY updated_ts DESC LIMIT $2",
        )
        .bind(owner_iid)
        .bind(limit)
        .fetch_all(pool)
        .await?
    };
    Ok(rows)
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
    let q = query_text.trim();

    // 1. Core/pinned memories (identity, preference, and key user traits)
    let pinned_rows = match memory_pinned(pool, owner_iid, bot_iid, MEMORY_PINNED_LIMIT).await {
        Ok(rows) => {
            trace.pinned_count = rows.len() as i32;
            rows
        }
        Err(e) => {
            warn!("[c35:memory] memory_pinned failed owner_iid={owner_iid}: {e:#}");
            Vec::new()
        }
    };

    if q.is_empty() {
        let mut combined = pinned_rows;
        let recent = memory_list_active(pool, owner_iid, bot_iid, limit as i64).await.unwrap_or_default();
        for r in recent {
            if !combined.iter().any(|(k, _)| k == &r.0) {
                combined.push(r);
            }
        }
        combined.truncate(limit);
        trace.memory_count = combined.len() as i32;
        return Ok((memory_prompt_block(&combined), trace));
    }

    // 2. Load active memories for the user
    let all_active = match memory_active_with_embed(pool, owner_iid, bot_iid, 64).await {
        Ok(rows) => {
            trace.active_count = rows.len() as i32;
            rows
        }
        Err(e) => {
            warn!("[c35:memory] memory_active_with_embed failed owner_iid={owner_iid}: {e:#}");
            Vec::new()
        }
    };

    if all_active.is_empty() {
        if !pinned_rows.is_empty() {
            trace.memory_count = pinned_rows.len() as i32;
            return Ok((memory_prompt_block(&pinned_rows), trace));
        }
        return Ok((String::new(), trace));
    }

    let embed_t0 = Instant::now();
    let model = embed_model_tag(EMBED_MODEL, EMBED_DIMS);
    trace.embed_model = model.clone();

    let query_vec = match tokio::time::timeout(
        MEMORY_EMBED_TIMEOUT,
        embed_cached(pool, http, q, EMBED_TASK_QUERY, EMBED_DIMS),
    )
    .await
    {
        Ok(Ok(r)) => {
            trace.embed_cached = r.cached;
            trace.embed_ms = embed_t0.elapsed().as_millis() as i64;
            trace.embed_token_in = r.token_in;
            trace.embed_cost_usd = billing_embed_cost_usd(&model, r.token_in);
            Some(r.embedding)
        }
        _ => {
            trace.embed_skipped = true;
            None
        }
    };

    let mut scored: Vec<(String, String, f32)> = Vec::new();

    // In-memory vector comparison against stored embedding_json
    if let Some(ref q_vec) = query_vec {
        for row in &all_active {
            if let Some(ref emb_val) = row.embedding_json {
                if let Ok(emb_vec) = serde_json::from_value::<Vec<f32>>(emb_val.clone()) {
                    let sim = cosine_similarity(q_vec, &emb_vec);
                    if sim >= MEMORY_SIM_FLOOR {
                        scored.push((row.key.clone(), row.content.clone(), sim));
                    }
                }
            } else {
                // If embedding not yet cached, still include as candidate
                scored.push((row.key.clone(), row.content.clone(), 0.55));
            }
        }
    } else {
        // Embed skipped: include all active memories as candidates
        for row in &all_active {
            scored.push((row.key.clone(), row.content.clone(), 0.55));
        }
    }

    // 3. FTS keyword fallback
    let fts_cands = match memory_candidates(pool, owner_iid, bot_iid, q).await {
        Ok(rows) => rows,
        Err(e) => {
            warn!("[c35:memory] memory_candidates failed owner_iid={owner_iid}: {e:#}");
            Vec::new()
        }
    };
    for f in fts_cands {
        if !scored.iter().any(|(k, _, _)| k == &f.key) {
            scored.push((f.key, f.content, 0.60));
        }
    }

    scored.sort_by(|a, b| b.2.partial_cmp(&a.2).unwrap_or(std::cmp::Ordering::Equal));

    // 4. Merge: pinned first, then top scored
    let mut result_rows: Vec<(String, String)> = Vec::new();
    for p in pinned_rows {
        result_rows.push(p);
    }
    for (k, c, _) in scored {
        if !result_rows.iter().any(|(rk, _)| rk == &k) {
            result_rows.push((k, c));
        }
    }
    result_rows.truncate(limit);
    trace.memory_count = result_rows.len() as i32;
    Ok((memory_prompt_block(&result_rows), trace))
}

struct ActiveMemoryRow {
    key: String,
    content: String,
    #[allow(dead_code)]
    category: String,
    embedding_json: Option<serde_json::Value>,
}

async fn memory_pinned(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: Option<i64>,
    limit: i64,
) -> Result<Vec<(String, String)>> {
    let rows = if let Some(bid) = bot_iid {
        sqlx::query_as::<_, (String, String)>(
            "SELECT key, content FROM ai.memory WHERE owner_iid = $1 AND (bot_iid IS NULL OR bot_iid = $2) \
             AND (category IN ('identity', 'preference') OR key IN ('user_name', 'name', 'diet', 'dietary_restriction', 'language', 'city', 'location')) \
             AND is_active = true AND deleted_ts IS NULL \
             ORDER BY updated_ts DESC LIMIT $3",
        )
        .bind(owner_iid)
        .bind(bid)
        .bind(limit)
        .fetch_all(pool)
        .await?
    } else {
        sqlx::query_as::<_, (String, String)>(
            "SELECT key, content FROM ai.memory WHERE owner_iid = $1 AND bot_iid IS NULL \
             AND (category IN ('identity', 'preference') OR key IN ('user_name', 'name', 'diet', 'dietary_restriction', 'language', 'city', 'location')) \
             AND is_active = true AND deleted_ts IS NULL \
             ORDER BY updated_ts DESC LIMIT $2",
        )
        .bind(owner_iid)
        .bind(limit)
        .fetch_all(pool)
        .await?
    };
    Ok(rows)
}

async fn memory_active_with_embed(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: Option<i64>,
    limit: i64,
) -> Result<Vec<ActiveMemoryRow>> {
    let rows = if let Some(bid) = bot_iid {
        sqlx::query_as::<_, (String, String, String, Option<Json<serde_json::Value>>)>(
            "SELECT key, content, category, embedding_json FROM ai.memory \
             WHERE owner_iid = $1 AND (bot_iid IS NULL OR bot_iid = $2) \
             AND is_active = true AND deleted_ts IS NULL \
             ORDER BY updated_ts DESC LIMIT $3",
        )
        .bind(owner_iid)
        .bind(bid)
        .bind(limit)
        .fetch_all(pool)
        .await?
    } else {
        sqlx::query_as::<_, (String, String, String, Option<Json<serde_json::Value>>)>(
            "SELECT key, content, category, embedding_json FROM ai.memory \
             WHERE owner_iid = $1 AND bot_iid IS NULL \
             AND is_active = true AND deleted_ts IS NULL \
             ORDER BY updated_ts DESC LIMIT $2",
        )
        .bind(owner_iid)
        .bind(limit)
        .fetch_all(pool)
        .await?
    };
    Ok(rows.into_iter().map(|(key, content, category, embedding_json)| ActiveMemoryRow {
        key, content, category, embedding_json: embedding_json.map(|j| j.0),
    }).collect())
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_cosine_similarity() {
        let v1 = vec![1.0, 0.0, 0.0];
        let v2 = vec![1.0, 0.0, 0.0];
        let v3 = vec![0.0, 1.0, 0.0];
        assert!((cosine_similarity(&v1, &v2) - 1.0).abs() < 1e-5);
        assert!((cosine_similarity(&v1, &v3) - 0.0).abs() < 1e-5);
    }

    #[test]
    fn test_memory_prompt_block() {
        let items = vec![
            ("name".to_string(), "Alex".to_string()),
            ("diet".to_string(), "vegetarian".to_string()),
        ];
        let block = memory_prompt_block(&items);
        assert!(block.contains("## Memory"));
        assert!(block.contains("- name: Alex"));
        assert!(block.contains("- diet: vegetarian"));
    }

    #[test]
    fn test_memory_prompt_merge() {
        let base = "System instructions.";
        let block = "## Memory\n- user_name: Alex";
        let merged = memory_prompt_merge(base, block);
        assert!(merged.contains("System instructions."));
        assert!(merged.contains("## Memory\n- user_name: Alex"));
    }
}

