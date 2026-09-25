use std::collections::HashMap;
use std::sync::{OnceLock, RwLock};

use anyhow::Result;
use c35_proto::PromptModelOption;
use c35_store::db_retry;
use chrono::{DateTime, Utc};
use sqlx::PgPool;

use crate::runtime_config::runtime_config_reload;
pub use crate::catalog_types::LlmModelRow;

pub const SYNC_INTERVAL_SECS: u64 = 30 * 60;

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
    llm_catalog_seed(pool).await?;
    runtime_config_reload(pool).await;
    if sync_enabled() {
        let _ = crate::catalog_sync::llm_catalog_sync(pool).await;
    }
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
        .filter(|m| m.enabled)
        .map(|m| PromptModelOption {
            id: m.id.clone(),
            label: m.label.clone(),
            provider: m.provider.clone(),
            is_default: m.is_default,
            usd_in_per_1m: micro_per_m_to_usd(m.input_micro_per_m),
            usd_out_per_1m: micro_per_m_to_usd(m.output_micro_per_m),
            supports_thinking: m.supports_thinking,
        })
        .collect()
}

pub fn catalog_price(model: &str) -> Option<(i64, i64)> {
    let key = model.trim();
    cache()
        .read()
        .unwrap()
        .price_by_id
        .get(key)
        .copied()
        .or_else(|| provider_fallback_price(key))
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
    use crate::catalog_resolve::catalog_row_by_provider_model;
    let key = model.trim();
    if key.is_empty() || key == "alienai" || key == "auto" {
        return catalog_row_resolve("alienai").map(|m| m.provider_model);
    }
    if let Some(m) = catalog_row_resolve(key) {
        return Some(m.provider_model);
    }
    if key == "google" {
        let g = cache().read().unwrap();
        return g
            .models
            .iter()
            .find(|m| m.provider == "google" && m.is_default)
            .or_else(|| g.models.iter().find(|m| m.provider == "google" && m.enabled))
            .map(|m| m.provider_model.clone());
    }
    catalog_row_by_provider_model(key).map(|m| m.provider_model)
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
            bool,
            bool,
            bool,
            i32,
            String,
            i32,
            String,
        )>(
            "SELECT id, provider, label, provider_model, input_micro_per_m, output_micro_per_m, supports_thinking, enabled, is_default, sort_order, family, version_rank, source \
             FROM ai.llm_model WHERE deleted_at IS NULL ORDER BY sort_order ASC, label ASC",
        )
        .fetch_all(pool)
        .await
    })
    .await?;
    let models = rows
        .into_iter()
        .map(
            |(id, provider, label, provider_model, input_micro_per_m, output_micro_per_m, supports_thinking, enabled, is_default, sort_order, family, version_rank, source)| {
                LlmModelRow {
                    id,
                    provider,
                    label,
                    provider_model,
                    input_micro_per_m,
                    output_micro_per_m,
                    supports_thinking,
                    enabled,
                    is_default,
                    sort_order,
                    family,
                    version_rank,
                    source,
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

async fn llm_catalog_seed(pool: &PgPool) -> Result<()> {
    let pinned = crate::catalog_sync::pinned_models();
    for m in pinned {
        db_retry(pool, || async {
            sqlx::query(
                "INSERT INTO ai.llm_model (id, provider, label, provider_model, input_micro_per_m, output_micro_per_m, supports_thinking, enabled, is_default, sort_order, family, version_rank, source, updated_at) \
                 VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,NOW()) \
                 ON CONFLICT (id) DO UPDATE SET \
                 label = EXCLUDED.label, provider_model = EXCLUDED.provider_model, \
                 input_micro_per_m = EXCLUDED.input_micro_per_m, output_micro_per_m = EXCLUDED.output_micro_per_m, \
                 supports_thinking = EXCLUDED.supports_thinking, enabled = EXCLUDED.enabled, is_default = EXCLUDED.is_default, \
                 sort_order = EXCLUDED.sort_order, family = EXCLUDED.family, version_rank = EXCLUDED.version_rank, source = EXCLUDED.source, \
                 updated_at = NOW()",
            )
            .bind(&m.id)
            .bind(&m.provider)
            .bind(&m.label)
            .bind(&m.provider_model)
            .bind(m.input_micro_per_m)
            .bind(m.output_micro_per_m)
            .bind(m.supports_thinking)
            .bind(m.enabled)
            .bind(m.is_default)
            .bind(m.sort_order)
            .bind(&m.family)
            .bind(m.version_rank)
            .bind(&m.source)
            .execute(pool)
            .await
        })
        .await?;
    }
    Ok(())
}

fn provider_fallback_price(model: &str) -> Option<(i64, i64)> {
    if model.trim().eq_ignore_ascii_case("local") {
        return Some((0, 0));
    }
    None
}

fn micro_per_m_to_usd(micro_per_m: i64) -> f64 {
    micro_per_m as f64 / 1_000_000.0
}

fn fallback_models() -> Vec<PromptModelOption> {
    vec![PromptModelOption {
        id: "alienai".into(),
        label: "Alien AI".into(),
        provider: "alienai".into(),
        is_default: true,
        usd_in_per_1m: 0.0,
        usd_out_per_1m: 0.0,
        supports_thinking: true,
    }]
}

pub(crate) async fn upsert_model(pool: &PgPool, m: &LlmModelRow, synced_at: DateTime<Utc>) -> Result<()> {
    db_retry(pool, || async {
        sqlx::query(
            "INSERT INTO ai.llm_model (id, provider, label, provider_model, input_micro_per_m, output_micro_per_m, supports_thinking, enabled, is_default, sort_order, family, version_rank, source, synced_at, updated_at) \
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,NOW()) \
             ON CONFLICT (id) DO UPDATE SET \
             label = EXCLUDED.label, provider_model = EXCLUDED.provider_model, \
             input_micro_per_m = EXCLUDED.input_micro_per_m, output_micro_per_m = EXCLUDED.output_micro_per_m, \
             supports_thinking = EXCLUDED.supports_thinking, \
             enabled = CASE WHEN ai.llm_model.source IN ('pinned', 'manual') THEN ai.llm_model.enabled ELSE EXCLUDED.enabled END, \
             family = EXCLUDED.family, version_rank = EXCLUDED.version_rank, \
             source = CASE WHEN ai.llm_model.source IN ('pinned', 'manual') THEN ai.llm_model.source ELSE EXCLUDED.source END, \
             synced_at = EXCLUDED.synced_at, updated_at = NOW(), deleted_at = NULL",
        )
        .bind(&m.id)
        .bind(&m.provider)
        .bind(&m.label)
        .bind(&m.provider_model)
        .bind(m.input_micro_per_m)
        .bind(m.output_micro_per_m)
        .bind(m.supports_thinking)
        .bind(m.enabled)
        .bind(m.is_default)
        .bind(m.sort_order)
        .bind(&m.family)
        .bind(m.version_rank)
        .bind(&m.source)
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
}
