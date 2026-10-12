use std::time::{Duration, Instant};

use anyhow::Result;
use c35_mod_billing::billing_embed_cost_usd;
use c35_mod_llm::{
    embed_cached, embed_model_tag, embed_text, EMBED_MODEL, EMBED_TASK_DOCUMENT, EMBED_TASK_QUERY,
};
use c35_proto::UserMemoryBundle;
use c35_store::snowflake_id;
use reqwest::Client;
use sqlx::types::Json;
use sqlx::PgPool;
use tracing::warn;

const MEMORY_PINNED_LIMIT: i64 = 4;
const MEMORY_SIM_FLOOR: f32 = 0.50;
const MEMORY_RETRIEVE_TIMEOUT: Duration = Duration::from_millis(3500);
const MEMORY_EMBED_TIMEOUT: Duration = Duration::from_millis(2000);
pub const RETRIEVAL_EMBED_DIMS: i32 = 256;
const EMBED_DIMS: i32 = RETRIEVAL_EMBED_DIMS;

static QUERY_EMBED_CACHE: std::sync::LazyLock<dashmap::DashMap<String, Vec<f32>>> =
    std::sync::LazyLock::new(dashmap::DashMap::new);

#[inline]
pub fn dot_product_256(a: &[f32], b: &[f32]) -> f32 {
    let n = a.len().min(b.len());
    let mut sum = 0.0f32;
    for i in 0..n {
        sum += a[i] * b[i];
    }
    sum
}

#[inline]
pub fn l2_normalize_256(v: &mut [f32]) {
    let mut sum = 0.0f32;
    for x in v.iter() {
        sum += x * x;
    }
    let norm = sum.sqrt();
    if norm > 1e-12 {
        for x in v.iter_mut() {
            *x /= norm;
        }
    }
}

pub fn is_trivial_query(q: &str) -> bool {
    let t = q.trim();
    if t.is_empty() {
        return true;
    }
    if t.len() <= 20 {
        let lower = t.to_lowercase();
        const TRIVIAL: &[&str] = &[
            "ok", "oke", "okay", "yes", "ya", "iya", "siap", "lanjut", "terima kasih",
            "makasih", "thanks", "thx", "halo", "hi", "hai", "p", "test", "halo!",
            "sip", "mantap", "pagi", "siang", "malam", "sore",
        ];
        if TRIVIAL.iter().any(|&w| lower == w) {
            return true;
        }
    }
    false
}

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
        Self {
            block: String::new(),
            trace: MemoryRetrieveTrace::default(),
        }
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
            Some(if k.is_empty() {
                format!("- {c}")
            } else {
                format!("- {k}: {c}")
            })
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
    let http = Client::builder()
        .timeout(Duration::from_secs(15))
        .build()
        .unwrap_or_default();
    memory_put_with_client(
        pool,
        &http,
        owner_iid,
        bot_iid,
        key,
        content,
        category,
        source_req_id,
    )
    .await
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
    let content_hash = blake3::hash(format!("{}: {}", key.trim(), content.trim()).as_bytes())
        .to_hex()
        .to_string();
    let payload = format!("{}: {}", key.trim(), content.trim());
    let embed_vec = match embed_cached(pool, http, &payload, EMBED_TASK_DOCUMENT, EMBED_DIMS).await
    {
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
    let embed_json = embed_vec
        .and_then(|v| serde_json::to_value(v).ok())
        .map(Json);

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

/// Site-scoped turns load data via site tools; skip embedding retrieval on the hot path.
pub fn memory_skip_site_scoped(mention_ctx: &crate::mention_context::MentionContext) -> bool {
    !mention_ctx.sites.is_empty()
}

pub async fn memory_retrieve(
    pool: &PgPool,
    http: &Client,
    owner_iid: i64,
    bot_iid: Option<i64>,
    query_text: &str,
    limit: usize,
) -> MemoryRetrieveResult {
    memory_retrieve_with_nats(
        pool,
        None,
        http,
        owner_iid,
        bot_iid,
        query_text,
        limit,
        None,
        None,
    )
    .await
}

/// MRL 256-dim query embedding shared by memory retrieve and user-asset RAG (tool RAG stays 768).
pub async fn retrieval_query_embed(
    pool: &PgPool,
    http: &Client,
    query_text: &str,
) -> Option<Vec<f32>> {
    let q = query_text.trim();
    if q.is_empty() || is_trivial_query(q) {
        return None;
    }
    if let Some(hit) = QUERY_EMBED_CACHE.get(q) {
        return Some(hit.value().clone());
    }
    match tokio::time::timeout(
        MEMORY_EMBED_TIMEOUT,
        embed_cached(pool, http, q, EMBED_TASK_QUERY, EMBED_DIMS),
    )
    .await
    {
        Ok(Ok(r)) => {
            if QUERY_EMBED_CACHE.len() < 512 {
                QUERY_EMBED_CACHE.insert(q.to_string(), r.embedding.clone());
            }
            Some(r.embedding)
        }
        _ => None,
    }
}

pub async fn memory_bundle_warmup(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    http: &Client,
    owner_iid: i64,
    bot_iid: Option<i64>,
) {
    let _ = memory_bundle_fetch_or_build(pool, nats, http, owner_iid, bot_iid).await;
}

pub async fn memory_retrieve_with_nats(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    http: &Client,
    owner_iid: i64,
    bot_iid: Option<i64>,
    query_text: &str,
    limit: usize,
    query_embed: Option<Vec<f32>>,
    preloaded_bundle: Option<UserMemoryBundle>,
) -> MemoryRetrieveResult {
    let started = Instant::now();
    match tokio::time::timeout(
        MEMORY_RETRIEVE_TIMEOUT,
        memory_retrieve_impl(
            pool,
            nats,
            http,
            owner_iid,
            bot_iid,
            query_text,
            limit.max(1),
            query_embed,
            preloaded_bundle,
        ),
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

pub async fn memory_cache_invalidate(
    nats: Option<&async_nats::Client>,
    owner_iid: i64,
    bot_iid: Option<i64>,
) {
    if let Some(client) = nats {
        if let Ok(store) = c35_nats::memory_bundle_kv_ensure(client).await {
            let _ = c35_nats::memory_bundle_delete(&store, owner_iid, bot_iid).await;
        }
    }
}

async fn memory_bundle_fetch_or_build(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    http: &Client,
    owner_iid: i64,
    bot_iid: Option<i64>,
) -> Option<c35_proto::UserMemoryBundle> {
    if let Some(client) = nats {
        if let Ok(store) = c35_nats::memory_bundle_kv_ensure(client).await {
            if let Some(bundle) = c35_nats::memory_bundle_get(&store, owner_iid, bot_iid).await {
                return Some(bundle);
            }
        }
    }

    let pinned = memory_pinned(pool, owner_iid, bot_iid, MEMORY_PINNED_LIMIT).await.ok()?;
    let active = memory_active_with_embed(pool, owner_iid, bot_iid, 64).await.ok()?;
    let mut items = Vec::new();

    for (k, c) in &pinned {
        items.push(c35_proto::UserMemoryBundleItem {
            id: 0,
            key: k.clone(),
            content: c.clone(),
            is_pinned: true,
            tags: vec![],
            embedding: vec![],
        });
    }

    for a in active {
        let is_pinned = items.iter().any(|i| i.key == a.key);
        let mut emb = a.embedding_json.and_then(|val| {
            serde_json::from_value::<Vec<f32>>(val).ok().map(|mut v| {
                if v.len() > EMBED_DIMS as usize {
                    v.truncate(EMBED_DIMS as usize);
                    l2_normalize_256(&mut v);
                }
                v
            })
        }).unwrap_or_default();

        if emb.is_empty() {
            if let Ok(res) = embed_cached(pool, http, &a.content, EMBED_TASK_DOCUMENT, EMBED_DIMS).await {
                emb = res.embedding;
            }
        }

        if is_pinned {
            if let Some(existing) = items.iter_mut().find(|i| i.key == a.key) {
                existing.embedding = emb;
            }
        } else {
            items.push(c35_proto::UserMemoryBundleItem {
                id: 0,
                key: a.key,
                content: a.content,
                is_pinned: false,
                tags: vec![],
                embedding: emb,
            });
        }
    }

    let bundle = c35_proto::UserMemoryBundle {
        owner_iid,
        bot_iid: bot_iid.unwrap_or(0),
        updated_ts_ms: chrono::Utc::now().timestamp_millis(),
        items,
    };

    if let Some(client) = nats {
        if let Ok(store) = c35_nats::memory_bundle_kv_ensure(client).await {
            let _ = c35_nats::memory_bundle_put(&store, &bundle).await;
        }
    }

    Some(bundle)
}

async fn memory_retrieve_impl(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    http: &Client,
    owner_iid: i64,
    bot_iid: Option<i64>,
    query_text: &str,
    limit: usize,
    query_embed: Option<Vec<f32>>,
    preloaded_bundle: Option<UserMemoryBundle>,
) -> Result<(String, MemoryRetrieveTrace)> {
    let mut trace = MemoryRetrieveTrace::default();
    let q = query_text.trim();

    let bundle = match preloaded_bundle {
        Some(b) => Some(b),
        None => memory_bundle_fetch_or_build(pool, nats, http, owner_iid, bot_iid).await,
    };

    if let Some(ref bundle) = bundle {
        let pinned_items: Vec<(String, String)> = bundle
            .items
            .iter()
            .filter(|i| i.is_pinned)
            .map(|i| (i.key.clone(), i.content.clone()))
            .collect();
        trace.pinned_count = pinned_items.len() as i32;
        trace.active_count = bundle.items.len() as i32;

        if q.is_empty() || is_trivial_query(q) {
            trace.embed_skipped = true;
            let mut combined = pinned_items;
            for item in &bundle.items {
                if !combined.iter().any(|(k, _)| k == &item.key) {
                    combined.push((item.key.clone(), item.content.clone()));
                }
            }
            combined.truncate(limit);
            trace.memory_count = combined.len() as i32;
            return Ok((memory_prompt_block(&combined), trace));
        }

        let embed_t0 = Instant::now();
        let model = embed_model_tag(EMBED_MODEL, EMBED_DIMS);
        trace.embed_model = model.clone();

        let query_vec: Option<Vec<f32>> = if let Some(pre) = query_embed {
            trace.embed_cached = true;
            trace.embed_ms = embed_t0.elapsed().as_millis() as i64;
            Some(pre)
        } else if let Some(hit) = QUERY_EMBED_CACHE.get(q) {
            trace.embed_cached = true;
            trace.embed_ms = embed_t0.elapsed().as_millis() as i64;
            Some(hit.value().clone())
        } else {
            match tokio::time::timeout(
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
                    if QUERY_EMBED_CACHE.len() < 512 {
                        QUERY_EMBED_CACHE.insert(q.to_string(), r.embedding.clone());
                    }
                    Some(r.embedding)
                }
                _ => {
                    trace.embed_skipped = true;
                    None
                }
            }
        };

        let mut scored: Vec<(String, String, f32)> = Vec::new();
        if let Some(q_vec) = query_vec.as_deref() {
            for item in &bundle.items {
                if !item.embedding.is_empty() {
                    let sim = dot_product_256(q_vec, &item.embedding);
                    if sim >= MEMORY_SIM_FLOOR {
                        scored.push((item.key.clone(), item.content.clone(), sim));
                    }
                } else {
                    scored.push((item.key.clone(), item.content.clone(), 0.55));
                }
            }
        } else {
            for item in &bundle.items {
                scored.push((item.key.clone(), item.content.clone(), 0.55));
            }
        }

        scored.sort_by(|a, b| b.2.partial_cmp(&a.2).unwrap_or(std::cmp::Ordering::Equal));

        let mut result_rows: Vec<(String, String)> = Vec::new();
        for p in pinned_items {
            result_rows.push(p);
        }
        for (k, c, _) in scored {
            if !result_rows.iter().any(|(rk, _)| rk == &k) {
                result_rows.push((k, c));
            }
        }
        result_rows.truncate(limit);
        trace.memory_count = result_rows.len() as i32;
        return Ok((memory_prompt_block(&result_rows), trace));
    }

    Ok((String::new(), trace))
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
    Ok(rows
        .into_iter()
        .map(|(key, content, category, embedding_json)| ActiveMemoryRow {
            key,
            content,
            category,
            embedding_json: embedding_json.map(|j| j.0),
        })
        .collect())
}

#[cfg(test)]
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
