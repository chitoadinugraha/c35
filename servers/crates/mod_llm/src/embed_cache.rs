//! Durable Gemini embed cache — BLAKE3 key, sliding access window eviction.

use std::time::Duration;

use chrono::Utc;
use reqwest::Client;
use sqlx::PgPool;
use tracing::{debug, info};

use crate::embed_gemini::{embed_text, EMBED_MODEL};
use crate::{embed_bytes_to_vec, embed_cache_key, embed_model_tag, embed_vec_to_bytes};

pub const EMBED_DIMENSIONS_DEFAULT: i32 = 768;
pub const EMBED_CACHE_RETENTION_DAYS: i64 = 30;
pub const EMBED_CACHE_EVICT_INTERVAL: Duration = Duration::from_secs(24 * 60 * 60);

pub struct EmbedCacheResult {
    pub embedding: Vec<f32>,
    pub cached: bool,
}

/// Point read with sliding-window touch — one round trip on hit.
pub async fn embed_cache_get_touch(pool: &PgPool, model: &str, key: &str) -> Result<Option<Vec<f32>>, sqlx::Error> {
    let now_ms = Utc::now().timestamp_millis();
    let row = sqlx::query_scalar::<_, Option<Vec<u8>>>(
        r#"
        UPDATE ai.embed_cache
        SET accessed_ts_ms = $3, ts_ms = $3
        WHERE model = $1 AND key = $2
        RETURNING embedding
        "#,
    )
    .bind(model)
    .bind(key)
    .bind(now_ms)
    .fetch_optional(pool)
    .await?;
    Ok(row.flatten().and_then(|b| embed_bytes_to_vec(&b)))
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
    let rows = sqlx::query_as::<_, (String, Vec<u8>)>(
        r#"
        UPDATE ai.embed_cache
        SET accessed_ts_ms = $3, ts_ms = $3
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
    for (key, bytes) in rows {
        if let Some(i) = key_to_idx.get(key.as_str()) {
            out[*i] = embed_bytes_to_vec(&bytes);
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
    if let Ok(Some(vec)) = embed_cache_get_touch(pool, &model, &key).await {
        return Ok(EmbedCacheResult { embedding: vec, cached: true });
    }
    let vec = embed_text(http, trimmed, task, dimensions)
        .await
        .map_err(|e| e.to_string())?;
    let _ = embed_cache_put(pool, &model, &key, trimmed, task, &vec, 0).await;
    Ok(EmbedCacheResult { embedding: vec, cached: false })
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
