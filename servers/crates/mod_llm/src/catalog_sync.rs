use std::time::Duration;

use anyhow::{Context, Result};
use chrono::Utc;
use c35_store::db_retry;
use serde_json::Value;
use sqlx::PgPool;

use crate::catalog_price::{price_for_model_id, DEFAULT_INPUT_MICRO_PER_M, DEFAULT_OUTPUT_MICRO_PER_M};
use crate::catalog_rank::{alien_chain_sort_cmp, apply_gemini_enabled, family_of, gemini_chat_eligible, is_preview_id, model_list_sort_cmp, pick_default_provider, sort_order_for, version_rank_of};
use crate::runtime_config::{cf_gateway_config, cf_gateway_ready};
use crate::embed_gemini::gemini_api_key;
use crate::catalog_types::LlmModelRow;
use crate::llm_catalog::{llm_catalog_reload, sync_enabled, upsert_model, SYNC_INTERVAL_SECS};
use crate::runtime_config::{runtime_config_reload, CONFIG_KEY_ALIEN_CHAIN};

pub fn llm_catalog_spawn(pool: PgPool) {
    if crate::fetch_catalog::external_fetcher_enabled() || !sync_enabled() {
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
    let _ = llm_catalog_sync_force(pool).await?;
    Ok(())
}

pub async fn llm_catalog_sync_force(pool: &PgPool) -> Result<usize> {
    let synced_at = Utc::now();
    let mut fetched = gemini_fetch().await?;
    let cf = cf_models_fetch().await?;
    prune_stale_cf(pool, &cf).await?;
    fetched.extend(cf);
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
    let n = fetched.len();
    tracing::info!(models = n, "llm_catalog synced");
    Ok(n)
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
    chain.sort_by(|a, b| alien_chain_sort_cmp(a, b));
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
            enabled: false,
            is_default: false,
            sort_order: 0,
            family,
            version_rank,
            source: "api".into(),
        });
    }
    apply_gemini_enabled(&mut out);
    for (idx, m) in out.iter_mut().enumerate() {
        m.sort_order = sort_order_for(m, idx as i32);
    }
    Ok(out)
}

async fn cf_models_fetch() -> Result<Vec<LlmModelRow>> {
    if !cf_gateway_ready() {
        return Ok(Vec::new());
    }
    let cfg = cf_gateway_config();
    let url = format!(
        "https://api.cloudflare.com/client/v4/accounts/{}/ai/models/search?format=openrouter&per_page=200&hide_experimental=true",
        cfg.account_id
    );
    let v: Value = reqwest::Client::new()
        .get(&url)
        .header("Authorization", format!("Bearer {}", cfg.api_token))
        .timeout(Duration::from_secs(45))
        .send()
        .await
        .context("cf models search")?
        .error_for_status()
        .context("cf models search status")?
        .json()
        .await
        .context("cf models search json")?;
    let rows = v["result"].as_array().cloned().unwrap_or_default();
    let mut out = Vec::new();
    for raw in rows {
        let id = raw["id"].as_str().or_else(|| raw["name"].as_str()).unwrap_or("").trim().to_string();
        if id.is_empty() || !cf_chat_eligible(&id) {
            continue;
        }
        let (provider, slug) = cf_provider_slug(&id)?;
        let label = raw["name"]
            .as_str()
            .or_else(|| raw["display_name"].as_str())
            .unwrap_or(&slug)
            .to_string();
        let family = family_of(&slug);
        let version_rank = version_rank_of(&slug);
        let (in_ppm, out_ppm) = price_for_model_id(&slug).unwrap_or((DEFAULT_INPUT_MICRO_PER_M, DEFAULT_OUTPUT_MICRO_PER_M));
        let thinks = slug.contains("gemini-3") || slug.contains("claude") || slug.contains("o1");
        out.push(LlmModelRow {
            id: slug,
            provider,
            label,
            provider_model: id,
            input_micro_per_m: in_ppm,
            output_micro_per_m: out_ppm,
            supports_thinking: thinks,
            enabled: true,
            is_default: false,
            sort_order: 0,
            family,
            version_rank,
            source: "cf_api".into(),
        });
    }
    out.sort_by(model_list_sort_cmp);
    for (idx, m) in out.iter_mut().enumerate() {
        m.sort_order = sort_order_for(m, idx as i32);
    }
    Ok(out)
}

fn cf_provider_slug(id: &str) -> Result<(String, String)> {
    let lower = id.to_ascii_lowercase();
    if lower.starts_with("openai/") {
        return Ok(("openai".into(), lower.strip_prefix("openai/").unwrap_or(&lower).to_string()));
    }
    if lower.starts_with("anthropic/") {
        return Ok(("anthropic".into(), lower.strip_prefix("anthropic/").unwrap_or(&lower).to_string()));
    }
    if lower.starts_with("deepseek/") {
        return Ok(("deepseek".into(), lower.strip_prefix("deepseek/").unwrap_or(&lower).to_string()));
    }
    if lower.starts_with("google/") {
        return Err(anyhow::anyhow!("skip google cf model"));
    }
    if lower.starts_with("@cf/") {
        return Ok(("cloudflare".into(), lower.to_string()));
    }
    Err(anyhow::anyhow!("unsupported cf model id: {id}"))
}

fn cf_chat_eligible(id: &str) -> bool {
    let m = id.to_ascii_lowercase();
    if is_preview_id(&m) {
        return false;
    }
    const SKIP: &[&str] = &[
        "embed", "embedding", "whisper", "tts", "dall-e", "image", "moderation", "transcribe", "realtime",
    ];
    if SKIP.iter().any(|s| m.contains(s)) {
        return false;
    }
    m.starts_with("openai/")
        || m.starts_with("anthropic/")
        || m.starts_with("deepseek/")
        || m.starts_with("@cf/")
}

async fn prune_stale_cf(pool: &PgPool, fetched: &[LlmModelRow]) -> Result<()> {
    if fetched.is_empty() {
        return Ok(());
    }
    let ids: Vec<String> = fetched.iter().map(|m| m.id.clone()).collect();
    db_retry(pool, || async {
        sqlx::query(
            "UPDATE ai.llm_model SET deleted_at = NOW(), enabled = false, updated_at = NOW() \
             WHERE source = 'cf_api' AND deleted_at IS NULL AND NOT (id = ANY($1))",
        )
        .bind(&ids)
        .execute(pool)
        .await
    })
    .await?;
    Ok(())
}
