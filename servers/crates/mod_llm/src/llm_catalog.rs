use std::collections::HashMap;
use std::sync::{OnceLock, RwLock};

use anyhow::Result;
use c35_proto::PromptModelOption;
use c35_store::db_retry;
use chrono::{DateTime, Utc};
use sqlx::PgPool;

use crate::catalog_price::{ALIEN_POOL_USD_IN_PER_1M, ALIEN_POOL_USD_OUT_PER_1M};
use crate::catalog_rank::chat_picker_row_eligible;
use crate::runtime_config::runtime_config_reload;
pub use crate::catalog_types::LlmModelRow;

/// Default catalog sync interval (CF models search / OpenRouter fallback).
pub const SYNC_INTERVAL_SECS: u64 = 24 * 60 * 60;

pub fn sync_interval_secs() -> u64 {
    std::env::var("LLM_CATALOG_SYNC_INTERVAL_SECS")
        .ok()
        .and_then(|v| v.parse().ok())
        .filter(|&n| n > 0)
        .unwrap_or(SYNC_INTERVAL_SECS)
}

struct CatalogCache {
    models: Vec<LlmModelRow>,
    price_by_id: HashMap<String, (i64, i64)>,
}

fn cache() -> &'static RwLock<CatalogCache> {
    static C: OnceLock<RwLock<CatalogCache>> = OnceLock::new();
    C.get_or_init(|| RwLock::new(CatalogCache { models: Vec::new(), price_by_id: HashMap::new() }))
}

// ============================================================= API
pub async fn llm_catalog_init(pool: &PgPool) -> Result<()> {
    llm_catalog_pinned_ensure(pool).await?;
    llm_catalog_reload(pool).await?;
    if sync_enabled() && !crate::fetch_catalog::external_fetcher_enabled() {
        let _ = crate::catalog_sync::llm_catalog_sync(pool).await?;
    } else {
        runtime_config_reload(pool).await;
    }
    Ok(())
}

/// In-memory catalog must be loaded before alien-chain validation against provider models.
pub async fn llm_catalog_ensure_memory(pool: &PgPool) {
    if cache().read().unwrap().models.is_empty() {
        if let Err(e) = llm_catalog_reload(pool).await {
            tracing::warn!(error = %e, "llm_catalog_reload (ensure memory) failed");
        }
    }
}

/// Load catalog cache + alien chain runtime (no provider sync or pinned DB writes).
pub async fn llm_catalog_warm(pool: &PgPool) -> Result<()> {
    llm_catalog_reload(pool).await?;
    runtime_config_reload(pool).await;
    Ok(())
}

pub fn prompt_models() -> Vec<PromptModelOption> {
    let g = cache().read().unwrap();
    if g.models.is_empty() {
        return fallback_models();
    }
    g.models
        .iter()
        .filter(|m| m.enabled && chat_picker_row_eligible(m))
        .map(|m| {
            let (usd_in_per_1m, usd_out_per_1m) = prompt_model_usd_per_1m(m);
            PromptModelOption {
                id: m.id.clone(),
                label: m.label.clone(),
                provider: m.provider.clone(),
                is_default: m.is_default,
                usd_in_per_1m,
                usd_out_per_1m,
                supports_thinking: m.supports_thinking,
                context_tokens: m.effective_context_tokens(),
            }
        })
        .collect()
}

/// Lookup keys for billing: exact id, then base before `@` (embed cache tags `model@dims`).
fn catalog_price_keys(model: &str) -> Vec<String> {
    let key = model.trim();
    if key.is_empty() {
        return Vec::new();
    }
    if let Some((base, _)) = key.split_once('@') {
        let base = base.trim();
        if !base.is_empty() && !base.eq_ignore_ascii_case(key) {
            return vec![key.to_string(), base.to_string()];
        }
    }
    vec![key.to_string()]
}

pub fn catalog_price(model: &str) -> Option<(i64, i64)> {
    let cache = cache().read().unwrap();
    for id in catalog_price_keys(model) {
        if let Some(p) = cache.price_by_id.get(&id).copied() {
            return Some(p);
        }
        if let Some(p) = provider_fallback_price(&id) {
            return Some(p);
        }
    }
    None
}

pub fn catalog_models() -> Vec<LlmModelRow> {
    cache().read().unwrap().models.clone()
}

pub fn catalog_row_resolve(slug: &str) -> Option<LlmModelRow> {
    let key = slug.trim();
    if key.is_empty() {
        return None;
    }
    let g = cache().read().unwrap();
    g.models.iter().find(|m| m.id == key).cloned()
}

pub fn provider_model_resolve(model: &str) -> Option<String> {
    use crate::catalog_resolve::{catalog_row_by_provider_model, google_gemini_api_model_id};
    let key = model.trim();
    let google_row = |m: &LlmModelRow| -> String {
        if m.provider == "google" {
            google_gemini_api_model_id(&m.provider_model)
        } else {
            m.provider_model.clone()
        }
    };
    if key.is_empty() || key == "alienai" || key == "auto" {
        return catalog_row_resolve("alienai").map(|m| google_row(&m));
    }
    if let Some(m) = catalog_row_resolve(key) {
        return Some(google_row(&m));
    }
    if key == "google" {
        let g = cache().read().unwrap();
        return g
            .models
            .iter()
            .find(|m| m.provider == "google" && m.is_default)
            .or_else(|| g.models.iter().find(|m| m.provider == "google" && m.enabled))
            .map(google_row);
    }
    catalog_row_by_provider_model(key).map(|m| google_row(&m))
}

// ============================================================= Implementation
pub(crate) fn sync_enabled() -> bool {
    match std::env::var("LLM_CATALOG_SYNC").as_deref() {
        Ok("0") | Ok("false") | Ok("off") => false,
        Ok("1") | Ok("true") | Ok("on") => true,
        _ => true,
    }
}

pub async fn llm_catalog_reload(pool: &PgPool) -> Result<()> {
    let rows = db_retry(pool, || async {
        sqlx::query_as::<_, (
            String,
            String,
            String,
            String,
            i64,
            i64,
            i64,
            bool,
            bool,
            bool,
            i32,
            String,
            i32,
            String,
            i32,
        )>(
            "SELECT id, provider, label, provider_model, input_micro_per_m, input_cache_micro_per_m, output_micro_per_m, supports_thinking, enabled, is_default, sort_order, family, version_rank, source, context_tokens \
             FROM ai.llm_model WHERE deleted_at IS NULL ORDER BY sort_order ASC, label ASC",
        )
        .fetch_all(pool)
        .await
    })
    .await?;
    let models = rows
        .into_iter()
        .map(
            |(id, provider, label, provider_model, input_micro_per_m, input_cache_micro_per_m, output_micro_per_m, supports_thinking, enabled, is_default, sort_order, family, version_rank, source, context_tokens)| {
                LlmModelRow {
                    id,
                    provider,
                    label,
                    provider_model,
                    input_micro_per_m,
                    input_cache_micro_per_m,
                    output_micro_per_m,
                    supports_thinking,
                    enabled,
                    is_default,
                    sort_order,
                    family,
                    version_rank,
                    source,
                    context_tokens,
                }
            },
        )
        .collect::<Vec<_>>();
    let price_by_id = models
        .iter()
        .map(|m| (m.id.clone(), (m.input_micro_per_m, m.output_micro_per_m)))
        .collect();
    let mut g = cache().write().unwrap();
    g.models = models;
    g.price_by_id = price_by_id;
    Ok(())
}

const LLM_PINNED_SEED_KEY: &str = "c35.llm_pinned_seed";

pub async fn llm_catalog_pinned_ensure(pool: &PgPool) -> Result<()> {
    let expected = crate::catalog_sync::pinned_seed_fingerprint();
    let stored = db_retry(pool, || async {
        sqlx::query_scalar::<_, Option<String>>(
            "SELECT value->>'hash' FROM ai.config WHERE key = $1",
        )
        .bind(LLM_PINNED_SEED_KEY)
        .fetch_optional(pool)
        .await
    })
    .await?
    .flatten();
    if stored.as_deref() == Some(&expected) {
        return Ok(());
    }
    llm_catalog_seed(pool).await?;
    let value = serde_json::json!({ "hash": expected });
    db_retry(pool, || async {
        sqlx::query(
            "INSERT INTO ai.config (key, value, updated_at) VALUES ($1, $2, NOW()) \
             ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()",
        )
        .bind(LLM_PINNED_SEED_KEY)
        .bind(value.clone())
        .execute(pool)
        .await
    })
    .await?;
    Ok(())
}

async fn llm_catalog_seed(pool: &PgPool) -> Result<()> {
    let pinned = crate::catalog_sync::pinned_models();
    for m in pinned {
        db_retry(pool, || async {
            sqlx::query(
                "INSERT INTO ai.llm_model (id, provider, label, provider_model, input_micro_per_m, input_cache_micro_per_m, output_micro_per_m, supports_thinking, enabled, is_default, sort_order, family, version_rank, source, context_tokens, updated_at) \
                 VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,NOW()) \
                 ON CONFLICT (id) DO UPDATE SET \
                 label = EXCLUDED.label, provider_model = EXCLUDED.provider_model, \
                 input_micro_per_m = EXCLUDED.input_micro_per_m, input_cache_micro_per_m = EXCLUDED.input_cache_micro_per_m, output_micro_per_m = EXCLUDED.output_micro_per_m, \
                 supports_thinking = EXCLUDED.supports_thinking, enabled = EXCLUDED.enabled, is_default = EXCLUDED.is_default, \
                 sort_order = EXCLUDED.sort_order, family = EXCLUDED.family, version_rank = EXCLUDED.version_rank, source = EXCLUDED.source, \
                 context_tokens = CASE WHEN EXCLUDED.context_tokens > 0 THEN EXCLUDED.context_tokens ELSE ai.llm_model.context_tokens END, \
                 updated_at = NOW()",
            )
            .bind(&m.id)
            .bind(&m.provider)
            .bind(&m.label)
            .bind(&m.provider_model)
            .bind(m.input_micro_per_m)
            .bind(m.input_cache_micro_per_m)
            .bind(m.output_micro_per_m)
            .bind(m.supports_thinking)
            .bind(m.enabled)
            .bind(m.is_default)
            .bind(m.sort_order)
            .bind(&m.family)
            .bind(m.version_rank)
            .bind(&m.source)
            .bind(m.context_tokens)
            .execute(pool)
            .await
        })
        .await?;
    }
    Ok(())
}

fn provider_fallback_price(model: &str) -> Option<(i64, i64)> {
    let m = model.trim().to_ascii_lowercase();
    if m == "local" {
        return Some((0, 0));
    }
    if m.contains("flash-lite") {
        return Some((75_000, 300_000));
    }
    if m.contains("flash") {
        return Some((150_000, 600_000));
    }
    if m.contains("pro") {
        return Some((1_250_000, 5_000_000));
    }
    None
}

fn micro_per_m_to_usd(micro_per_m: i64) -> f64 {
    micro_per_m as f64 / 1_000_000.0
}

/// User-facing $/M in model picker. Frontier uses catalog wholesale; Alien AI uses locked pool rates (not DB wholesale).
fn prompt_model_usd_per_1m(m: &LlmModelRow) -> (f64, f64) {
    if m.id == "alienai" || m.provider == "alienai" {
        return (ALIEN_POOL_USD_IN_PER_1M, ALIEN_POOL_USD_OUT_PER_1M);
    }
    (
        micro_per_m_to_usd(m.input_micro_per_m),
        micro_per_m_to_usd(m.output_micro_per_m),
    )
}

fn fallback_models() -> Vec<PromptModelOption> {
    vec![PromptModelOption {
        id: "alienai".into(),
        label: "Alien AI".into(),
        provider: "alienai".into(),
        is_default: true,
        usd_in_per_1m: ALIEN_POOL_USD_IN_PER_1M,
        usd_out_per_1m: ALIEN_POOL_USD_OUT_PER_1M,
        supports_thinking: true,
        context_tokens: 1_048_576,
    }]
}

pub(crate) async fn upsert_model(pool: &PgPool, m: &LlmModelRow, synced_at: DateTime<Utc>) -> Result<()> {
    db_retry(pool, || async {
        sqlx::query(
            "INSERT INTO ai.llm_model (id, provider, label, provider_model, input_micro_per_m, input_cache_micro_per_m, output_micro_per_m, supports_thinking, enabled, is_default, sort_order, family, version_rank, source, context_tokens, synced_at, updated_at) \
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,NOW()) \
             ON CONFLICT (id) DO UPDATE SET \
             label = EXCLUDED.label, provider_model = EXCLUDED.provider_model, \
             input_micro_per_m = EXCLUDED.input_micro_per_m, input_cache_micro_per_m = EXCLUDED.input_cache_micro_per_m, output_micro_per_m = EXCLUDED.output_micro_per_m, \
             supports_thinking = EXCLUDED.supports_thinking, \
             enabled = CASE WHEN ai.llm_model.source IN ('pinned', 'manual') THEN ai.llm_model.enabled ELSE EXCLUDED.enabled END, \
             family = EXCLUDED.family, version_rank = EXCLUDED.version_rank, \
             source = CASE WHEN ai.llm_model.source IN ('pinned', 'manual') THEN ai.llm_model.source ELSE EXCLUDED.source END, \
             context_tokens = CASE WHEN EXCLUDED.context_tokens > 0 THEN EXCLUDED.context_tokens ELSE ai.llm_model.context_tokens END, \
             synced_at = EXCLUDED.synced_at, updated_at = NOW(), deleted_at = NULL",
        )
        .bind(&m.id)
        .bind(&m.provider)
        .bind(&m.label)
        .bind(&m.provider_model)
        .bind(m.input_micro_per_m)
        .bind(m.input_cache_micro_per_m)
        .bind(m.output_micro_per_m)
        .bind(m.supports_thinking)
        .bind(m.enabled)
        .bind(m.is_default)
        .bind(m.sort_order)
        .bind(&m.family)
        .bind(m.version_rank)
        .bind(&m.source)
        .bind(m.context_tokens)
        .bind(synced_at)
        .execute(pool)
        .await
    })
    .await?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fallback_models_non_empty() {
        assert!(!fallback_models().is_empty());
    }

    #[test]
    fn provider_fallback_local_is_free() {
        assert_eq!(provider_fallback_price("local"), Some((0, 0)));
    }

    #[test]
    fn catalog_price_keys_strip_embed_dimensions() {
        assert_eq!(
            catalog_price_keys("gemini-embedding-2@768"),
            vec!["gemini-embedding-2@768".to_string(), "gemini-embedding-2".to_string()]
        );
        assert_eq!(catalog_price_keys("gemini-2.5-flash"), vec!["gemini-2.5-flash".to_string()]);
    }

    #[test]
    fn alienai_prompt_uses_pool_rates_not_wholesale() {
        let m = LlmModelRow {
            id: "alienai".into(),
            provider: "alienai".into(),
            label: "Alien AI".into(),
            provider_model: String::new(),
            input_micro_per_m: 75_000,
            input_cache_micro_per_m: 0,
            output_micro_per_m: 300_000,
            supports_thinking: true,
            enabled: true,
            is_default: true,
            sort_order: 0,
            family: "flash-lite".into(),
            version_rank: 0,
            source: "pinned".into(),
            context_tokens: 1_048_576,
        };
        let (in_usd, out_usd) = prompt_model_usd_per_1m(&m);
        assert_eq!(in_usd, ALIEN_POOL_USD_IN_PER_1M);
        assert_eq!(out_usd, ALIEN_POOL_USD_OUT_PER_1M);
    }
}
