use std::collections::HashMap;
use std::sync::{OnceLock, RwLock};

use anyhow::Result;
use c35_proto::PromptModelOption;
use c35_store::db_retry;
use sqlx::PgPool;

#[derive(Debug, Clone)]
pub struct LlmModelRow {
    pub id: String,
    pub provider: String,
    pub label: String,
    pub input_micro_per_m: i64,
    pub output_micro_per_m: i64,
    pub supports_thinking: bool,
    pub enabled: bool,
    pub is_default: bool,
}

struct CatalogCache {
    models: Vec<LlmModelRow>,
    price_by_id: HashMap<String, (i64, i64)>,
}

fn cache() -> &'static RwLock<CatalogCache> {
    static C: OnceLock<RwLock<CatalogCache>> = OnceLock::new();
    C.get_or_init(|| RwLock::new(CatalogCache { models: Vec::new(), price_by_id: HashMap::new() }))
}

pub async fn llm_catalog_init(pool: &PgPool) -> Result<()> {
    llm_catalog_reload(pool).await?;
    Ok(())
}

pub async fn llm_catalog_reload(pool: &PgPool) -> Result<()> {
    let rows = db_retry(pool, || async {
        sqlx::query_as::<_, (String, String, String, String, i64, i64, bool, bool, bool, i32)>(
            "SELECT id, provider, label, provider_model, input_micro_per_m, output_micro_per_m, supports_thinking, enabled, is_default, sort_order \
             FROM ai.llm_model WHERE deleted_at IS NULL ORDER BY sort_order ASC, label ASC",
        )
        .fetch_all(pool)
        .await
    })
    .await?;
    let models = rows
        .into_iter()
        .map(
            |(id, provider, label, _provider_model, input_micro_per_m, output_micro_per_m, supports_thinking, enabled, is_default, _sort_order)| {
                LlmModelRow {
                    id,
                    provider,
                    label,
                    input_micro_per_m,
                    output_micro_per_m,
                    supports_thinking,
                    enabled,
                    is_default,
                }
            },
        )
        .collect::<Vec<_>>();
    let price_by_id = models.iter().map(|m| (m.id.clone(), (m.input_micro_per_m, m.output_micro_per_m))).collect();
    let mut g = cache().write().unwrap();
    g.models = models;
    g.price_by_id = price_by_id;
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
    cache().read().unwrap().price_by_id.get(key).copied()
}

fn micro_per_m_to_usd(micro_per_m: i64) -> f64 {
    micro_per_m as f64 / 1_000_000.0
}

fn fallback_models() -> Vec<PromptModelOption> {
    vec![
        PromptModelOption {
            id: "auto".into(),
            label: "Alien AI".into(),
            provider: "alienai".into(),
            is_default: true,
            usd_in_per_1m: 0.075,
            usd_out_per_1m: 0.3,
            supports_thinking: true,
        },
        PromptModelOption {
            id: "gemini-3.1-flash-lite".into(),
            label: "Gemini 3.1 Flash Lite".into(),
            provider: "google".into(),
            is_default: false,
            usd_in_per_1m: 0.075,
            usd_out_per_1m: 0.3,
            supports_thinking: true,
        },
    ]
}
