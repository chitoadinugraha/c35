//! Durable Gemini embed cache — BLAKE3 key, sliding access window eviction.

use std::sync::OnceLock;
use std::time::Duration;

use chrono::Utc;
use dashmap::DashMap;
use reqwest::Client;
use sqlx::PgPool;
use tracing::{debug, info};

use crate::embed_gemini::{embed_text, embed_token_est, EMBED_MODEL};
use crate::{embed_bytes_to_vec, embed_cache_key, embed_model_tag, embed_vec_to_bytes};

pub const EMBED_DIMENSIONS_DEFAULT: i32 = 768;
pub const EMBED_CACHE_RETENTION_DAYS: i64 = 30;
pub const EMBED_CACHE_EVICT_INTERVAL: Duration = Duration::from_secs(24 * 60 * 60);

const L1_CACHE_MAX_ENTRIES: usize = 4096;
static L1_CACHE: OnceLock<DashMap<String, (Vec<f32>, i32)>> = OnceLock::new();

fn l1_cache() -> &'static DashMap<String, (Vec<f32>, i32)> {
    L1_CACHE.get_or_init(DashMap::new)
}

pub struct EmbedCacheResult {
    pub embedding: Vec<f32>,
    pub cached: bool,
    pub token_in: i32,
}

/// Point read with sliding-window touch — one round trip on hit.
pub async fn embed_cache_get_touch(pool: &PgPool, model: &str, key: &str) -> Result<Option<(Vec<f32>, i32)>, sqlx::Error> {
    let now_ms = Utc::now().timestamp_millis();
    let row = sqlx::query_as::<_, (Option<Vec<u8>>, Option<i32>)>(
        r#"
        UPDATE ai.embed_cache
        SET accessed_ts_ms = $3
        WHERE model = $1 AND key = $2
        RETURNING embedding, token_in
        "#,
    )
    .bind(model)
    .bind(key)
    .bind(now_ms)
    .fetch_optional(pool)
    .await?;
    Ok(match row {
        Some((Some(bytes), token_in)) => {
            embed_bytes_to_vec(&bytes).map(|v| (v, token_in.unwrap_or(0)))
        }
        _ => None,
    })
}

pub async fn embed_cache_get_many_touch(
    pool: &PgPool,
    model: &str,
    keys: &[String],
) -> Result<Vec<Option<Vec<f32>>>, sqlx::Error> {
    let mut out = vec![None; keys.len()];
    if keys.is_empty() {
        return Ok(out);
    }
    let now_ms = Utc::now().timestamp_millis();
    let rows = sqlx::query_as::<_, (String, Option<Vec<u8>>)>(
        r#"
        UPDATE ai.embed_cache
        SET accessed_ts_ms = $3
        WHERE model = $1 AND key = ANY($2)
        RETURNING key, embedding
        "#,
    )
    .bind(model)
    .bind(keys)
    .bind(now_ms)
    .fetch_all(pool)
    .await?;
    let key_to_idx: std::collections::HashMap<&str, usize> = keys
        .iter()
        .enumerate()
        .map(|(i, k)| (k.as_str(), i))
        .collect();
    for (key, opt_bytes) in rows {
        if let Some(i) = key_to_idx.get(key.as_str()) {
            out[*i] = opt_bytes.and_then(|b| embed_bytes_to_vec(&b));
        }
    }
    Ok(out)
}

pub async fn embed_cache_put(
    pool: &PgPool,
    model: &str,
    key: &str,
    text: &str,
    task: &str,
    embedding: &[f32],
    token_in: i32,
) -> Result<(), sqlx::Error> {
    let now_ms = Utc::now().timestamp_millis();
    let bytes = embed_vec_to_bytes(embedding);
    sqlx::query(
        r#"
        INSERT INTO ai.embed_cache (model, key, text, embedding, task, token_in, ts_ms, accessed_ts_ms)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $7)
        ON CONFLICT (model, key) DO UPDATE SET
            text = EXCLUDED.text,
            embedding = EXCLUDED.embedding,
            task = EXCLUDED.task,
            token_in = EXCLUDED.token_in,
            ts_ms = EXCLUDED.ts_ms,
            accessed_ts_ms = EXCLUDED.accessed_ts_ms
        "#,
    )
    .bind(model)
    .bind(key)
    .bind(text)
    .bind(bytes)
    .bind(task)
    .bind(token_in)
    .bind(now_ms)
    .execute(pool)
    .await?;
    Ok(())
}

/// Cache-first embed: touch on hit, store on miss. No TTL — eviction is access-based.
pub async fn embed_cached(
    pool: &PgPool,
    http: &Client,
    text: &str,
    task: &str,
    dimensions: i32,
) -> Result<EmbedCacheResult, String> {
    let trimmed = text.trim();
    if trimmed.is_empty() {
        return Err("embed text empty".into());
    }
    let model = embed_model_tag(EMBED_MODEL, dimensions);
    let key = embed_cache_key(trimmed, task, dimensions);
    let full_key = format!("{model}:{key}");

    if let Some(entry) = l1_cache().get(&full_key) {
        let (vec, token_in) = entry.value().clone();
        return Ok(EmbedCacheResult { embedding: vec, cached: true, token_in });
    }

    if let Ok(Some((vec, token_in))) = embed_cache_get_touch(pool, &model, &key).await {
        let tokens = if token_in > 0 { token_in } else { embed_token_est(trimmed) };
        if l1_cache().len() < L1_CACHE_MAX_ENTRIES {
            l1_cache().insert(full_key, (vec.clone(), tokens));
        }
        return Ok(EmbedCacheResult { embedding: vec, cached: true, token_in: tokens });
    }
    let out = embed_text(http, trimmed, task, dimensions)
        .await
        .map_err(|e| e.to_string())?;
    embed_cache_put(pool, &model, &key, trimmed, task, &out.embedding, out.token_in)
        .await
        .map_err(|e| format!("embed_cache_put: {e}"))?;
    if l1_cache().len() < L1_CACHE_MAX_ENTRIES {
        l1_cache().insert(full_key, (out.embedding.clone(), out.token_in));
    }
    Ok(EmbedCacheResult {
        embedding: out.embedding,
        cached: false,
        token_in: out.token_in,
    })
}

/// Delete rows not accessed within `retention_days` (sliding window, not fixed TTL).
pub async fn embed_cache_evict_stale(pool: &PgPool, retention_days: i64) -> Result<u64, sqlx::Error> {
    let cutoff_ms = Utc::now().timestamp_millis() - retention_days * 24 * 60 * 60 * 1000;
    let res = sqlx::query(
        r#"
        DELETE FROM ai.embed_cache
        WHERE COALESCE(accessed_ts_ms, ts_ms, 0) < $1
        "#,
    )
    .bind(cutoff_ms)
    .execute(pool)
    .await?;
    Ok(res.rows_affected())
}

pub fn embed_cache_evict_spawn(pool: PgPool) {
    tokio::spawn(async move {
        if let Ok(n) = embed_cache_evict_stale(&pool, EMBED_CACHE_RETENTION_DAYS).await {
            if n > 0 {
                info!("embed_cache: evicted {n} stale rows (>{EMBED_CACHE_RETENTION_DAYS}d since last access)");
            }
        }
        let mut interval = tokio::time::interval(EMBED_CACHE_EVICT_INTERVAL);
        interval.tick().await;
        loop {
            interval.tick().await;
            match embed_cache_evict_stale(&pool, EMBED_CACHE_RETENTION_DAYS).await {
                Ok(n) if n > 0 => debug!("embed_cache: evicted {n} stale rows"),
                Ok(_) => {}
                Err(e) => tracing::warn!("embed_cache evict failed: {e}"),
            }
        }
    });
}
