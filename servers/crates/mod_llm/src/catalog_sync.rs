use std::time::Duration;

use anyhow::{Context, Result};
use chrono::Utc;
use c35_store::db_retry;
use serde_json::Value;
use sqlx::PgPool;

use crate::catalog_price::{price_for_model_id, DEFAULT_INPUT_MICRO_PER_M, DEFAULT_OUTPUT_MICRO_PER_M};
use crate::catalog_rank::{family_of, gemini_chat_eligible, model_list_sort_cmp, pick_default_provider, sort_order_for, version_rank_of};
use crate::embed_gemini::gemini_api_key;
use crate::catalog_types::LlmModelRow;
use crate::llm_catalog::{llm_catalog_reload, sync_enabled, sync_unlock, try_sync_lock, upsert_model, SYNC_INTERVAL_SECS};
use crate::runtime_config::{runtime_config_reload, CONFIG_KEY_ALIEN_CHAIN};

pub fn llm_catalog_spawn(pool: PgPool) {
    if !sync_enabled() {
        return;
    }
    tokio::spawn(async move {
        let mut interval = tokio::time::interval(Duration::from_secs(SYNC_INTERVAL_SECS));
        interval.tick().await;
        loop {
            interval.tick().await;
            if let Err(e) = llm_catalog_sync(&pool).await {
                tracing::warn!(error = %e, "llm_catalog sync");
            }
        }
    });
}

pub async fn llm_catalog_sync(pool: &PgPool) -> Result<()> {
    if !try_sync_lock(pool).await? {
        tracing::debug!("llm_catalog sync: lock held by peer");
        return Ok(());
    }
    let synced_at = Utc::now();
    let mut fetched = gemini_fetch().await?;
    for (idx, m) in fetched.iter_mut().enumerate() {
        m.sort_order = sort_order_for(m, idx as i32);
        upsert_model(pool, m, synced_at).await?;
    }
    prune_stale_google(pool, &fetched).await?;
    sync_alien_meta(pool, &fetched).await?;
    if let Some(default_id) = pick_default_provider(&fetched, "google") {
        let id = default_id;
        db_retry(pool, || async {
            sqlx::query(
                "UPDATE ai.llm_model SET is_default = (id = $1) WHERE provider = 'google' AND source != 'pinned' AND deleted_at IS NULL",
            )
            .bind(&id)
            .execute(pool)
            .await
        })
        .await?;
    }
    llm_catalog_reload(pool).await?;
    runtime_config_reload(pool).await;
    sync_unlock(pool).await?;
    tracing::info!(models = fetched.len(), "llm_catalog synced");
    Ok(())
}

pub fn pinned_models() -> Vec<LlmModelRow> {
    vec![LlmModelRow {
        id: "alienai".into(),
        provider: "alienai".into(),
        label: "Alien AI".into(),
        provider_model: String::new(),
        input_micro_per_m: DEFAULT_INPUT_MICRO_PER_M,
        output_micro_per_m: DEFAULT_OUTPUT_MICRO_PER_M,
        supports_thinking: true,
        enabled: true,
        is_default: true,
        sort_order: 0,
        family: "flash-lite".into(),
        version_rank: 0,
        source: "pinned".into(),
    }]
}

async fn prune_stale_google(pool: &PgPool, fetched: &[LlmModelRow]) -> Result<()> {
    if fetched.is_empty() {
        return Ok(());
    }
    let ids: Vec<String> = fetched.iter().map(|m| m.id.clone()).collect();
    db_retry(pool, || async {
        sqlx::query(
            "UPDATE ai.llm_model SET deleted_at = NOW(), enabled = false, updated_at = NOW() \
             WHERE provider = 'google' AND source = 'api' AND deleted_at IS NULL AND NOT (id = ANY($1))",
        )
        .bind(&ids)
        .execute(pool)
        .await
    })
    .await?;
    Ok(())
}

async fn sync_alien_meta(pool: &PgPool, fetched: &[LlmModelRow]) -> Result<()> {
    let mut chain: Vec<String> = fetched
        .iter()
        .filter(|m| m.enabled && m.provider == "google" && m.family == "flash-lite")
        .map(|m| m.provider_model.clone())
        .collect();
    chain.sort_by(|a, b| version_rank_of(b).cmp(&version_rank_of(a)));
    chain.dedup();
    if chain.is_empty() {
        tracing::warn!("llm_catalog sync: no flash-lite models from provider");
        return Ok(());
    }
    let default = chain[0].clone();
    db_retry(pool, || async {
        sqlx::query(
            "UPDATE ai.llm_model SET provider_model = $1, input_micro_per_m = $2, output_micro_per_m = $3, \
             family = 'flash-lite', version_rank = $4, updated_at = NOW() \
             WHERE id = 'alienai' AND source = 'pinned'",
        )
        .bind(&default)
        .bind(price_for_model_id(&default).map(|p| p.0).unwrap_or(DEFAULT_INPUT_MICRO_PER_M))
        .bind(price_for_model_id(&default).map(|p| p.1).unwrap_or(DEFAULT_OUTPUT_MICRO_PER_M))
        .bind(version_rank_of(&default))
        .execute(pool)
        .await
    })
    .await?;
    let value = serde_json::json!({ "models": chain });
    db_retry(pool, || async {
        sqlx::query(
            "INSERT INTO ai.config (key, value, updated_at) VALUES ($1, $2, NOW()) \
             ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()",
        )
        .bind(CONFIG_KEY_ALIEN_CHAIN)
        .bind(value.clone())
        .execute(pool)
        .await
    })
    .await?;
    Ok(())
}

async fn gemini_fetch() -> Result<Vec<LlmModelRow>> {
    let key = gemini_api_key();
    if key.is_empty() {
        return Ok(Vec::new());
    }
    let url = format!("https://generativelanguage.googleapis.com/v1beta/models?key={key}");
    let v: Value = reqwest::Client::new()
        .get(&url)
        .timeout(Duration::from_secs(30))
        .send()
        .await
        .context("gemini models list")?
        .error_for_status()
        .context("gemini models list status")?
        .json()
        .await
        .context("gemini models list json")?;
    let models = v["models"].as_array().cloned().unwrap_or_default();
    let mut out = Vec::new();
    let mut seen_family: std::collections::HashMap<String, i32> = std::collections::HashMap::new();
    for raw in models {
        let name = raw["name"].as_str().unwrap_or("").trim();
        if name.is_empty() {
            continue;
        }
        let id = name.strip_prefix("models/").unwrap_or(name).to_string();
        let methods = raw["supportedGenerationMethods"]
            .as_array()
            .map(|a| a.iter().filter_map(|x| x.as_str().map(str::to_string)).collect::<Vec<_>>())
            .unwrap_or_default();
        if !gemini_chat_eligible(&id, &methods) {
            continue;
        }
        let family = family_of(&id);
        let fam_idx = seen_family.entry(family.clone()).or_insert(0);
        let idx = *fam_idx;
        *fam_idx += 1;
        let enabled = matches!(family.as_str(), "flash-lite" | "flash" | "pro") && idx < 3;
        let label = raw["displayName"].as_str().unwrap_or(&id).to_string();
        let (in_ppm, out_ppm) = price_for_model_id(&id).unwrap_or((DEFAULT_INPUT_MICRO_PER_M, DEFAULT_OUTPUT_MICRO_PER_M));
        let version_rank = version_rank_of(&id);
        let supports_thinking = id.contains("gemini-3") || id.contains("2.5");
        let provider_model = id.clone();
        out.push(LlmModelRow {
            id,
            provider: "google".into(),
            label,
            provider_model,
            input_micro_per_m: in_ppm,
            output_micro_per_m: out_ppm,
            supports_thinking,
            enabled,
            is_default: false,
            sort_order: 0,
            family,
            version_rank,
            source: "api".into(),
        });
    }
    out.sort_by(model_list_sort_cmp);
    for (idx, m) in out.iter_mut().enumerate() {
        m.sort_order = sort_order_for(m, idx as i32);
    }
    Ok(out)
}
