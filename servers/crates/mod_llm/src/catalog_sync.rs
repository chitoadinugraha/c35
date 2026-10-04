use std::time::Duration;

use anyhow::{Context, Result};
use chrono::Utc;
use c35_store::db_retry;
use serde_json::Value;
use sqlx::PgPool;

use crate::catalog_price::{price_for_model_id, DEFAULT_INPUT_MICRO_PER_M, DEFAULT_OUTPUT_MICRO_PER_M};
use crate::catalog_rank::{alien_chain_sort_cmp, assign_picker_order, family_of, gemini_chat_eligible, pick_default_provider, version_rank_of};
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
    runtime_config_reload(pool).await;
    let synced_at = Utc::now();
    let mut fetched = gemini_fetch().await?;
    let cf = cf_models_fetch().await?;
    prune_stale_cf(pool, &cf).await?;
    prune_stale_seed_frontier(pool, &cf).await?;
    fetched.extend(cf);
    for m in fetched.iter_mut() {
        upsert_model(pool, m, synced_at).await?;
    }
    prune_stale_google(pool, &fetched).await?;
    sync_alien_meta(pool, &fetched).await?;
    catalog_reindex_sort_orders(pool).await?;
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

pub fn pinned_seed_fingerprint() -> String {
    let mut h = blake3::Hasher::new();
    for m in pinned_models().into_iter().chain(frontier_seed_models()) {
        h.update(m.id.as_bytes());
        h.update(m.provider.as_bytes());
        h.update(m.label.as_bytes());
        h.update(m.provider_model.as_bytes());
        h.update(&m.input_micro_per_m.to_le_bytes());
        h.update(&m.output_micro_per_m.to_le_bytes());
        h.update(&[m.supports_thinking as u8]);
        h.update(&[m.enabled as u8]);
        h.update(&[m.is_default as u8]);
        h.update(&m.sort_order.to_le_bytes());
        h.update(m.family.as_bytes());
        h.update(&m.version_rank.to_le_bytes());
        h.update(m.source.as_bytes());
    }
    h.finalize().to_hex().to_string()
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

fn frontier_seed_row(
    id: &str,
    provider: &str,
    label: &str,
    provider_model: &str,
    family: &str,
    supports_thinking: bool,
    version_rank: i32,
) -> LlmModelRow {
    let (input_micro_per_m, output_micro_per_m) = price_for_model_id(id)
        .or_else(|| price_for_model_id(provider_model))
        .unwrap_or((DEFAULT_INPUT_MICRO_PER_M, DEFAULT_OUTPUT_MICRO_PER_M));
    LlmModelRow {
        id: id.into(),
        provider: provider.into(),
        label: label.into(),
        provider_model: provider_model.into(),
        input_micro_per_m,
        output_micro_per_m,
        supports_thinking,
        enabled: true,
        is_default: false,
        sort_order: 0,
        family: family.into(),
        version_rank,
        source: "seed".into(),
    }
}

/// Popular frontier models (Cloudflare gateway slugs). Kept when CF catalog sync is unavailable.
pub fn frontier_seed_models() -> Vec<LlmModelRow> {
    vec![
        frontier_seed_row("gpt-4o", "openai", "GPT-4o", "openai/gpt-4o", "gpt-4o", false, 0),
        frontier_seed_row("gpt-4o-mini", "openai", "GPT-4o mini", "openai/gpt-4o-mini", "gpt-4o", false, 0),
        frontier_seed_row("gpt-4.1", "openai", "GPT-4.1", "openai/gpt-4.1", "gpt-4", false, 41),
        frontier_seed_row("gpt-4.1-mini", "openai", "GPT-4.1 mini", "openai/gpt-4.1-mini", "gpt-4", false, 41),
        frontier_seed_row(
            "claude-sonnet-4-5",
            "anthropic",
            "Claude Sonnet 4.5",
            "anthropic/claude-sonnet-4-5",
            "claude",
            false,
            45,
        ),
        frontier_seed_row(
            "claude-3-5-haiku-latest",
            "anthropic",
            "Claude 3.5 Haiku",
            "anthropic/claude-3-5-haiku-latest",
            "claude",
            false,
            35,
        ),
        frontier_seed_row(
            "deepseek-chat",
            "deepseek",
            "DeepSeek Chat",
            "deepseek/deepseek-chat",
            "chat",
            false,
            0,
        ),
        frontier_seed_row(
            "deepseek-reasoner",
            "deepseek",
            "DeepSeek Reasoner",
            "deepseek/deepseek-reasoner",
            "reasoner",
            true,
            0,
        ),
        frontier_seed_row("grok-2-latest", "xai", "Grok 2", "x-ai/grok-2-latest", "grok", false, 2),
    ]
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
    assign_picker_order(&mut out);
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
    let resp = reqwest::Client::new()
        .get(&url)
        .header("Authorization", format!("Bearer {}", cfg.api_token))
        .timeout(Duration::from_secs(45))
        .send()
        .await
        .context("cf models search")?;
    if !resp.status().is_success() {
        let status = resp.status();
        let body = resp.text().await.unwrap_or_default();
        tracing::warn!(
            status = %status,
            hint = %cf_api_error_hint(&body),
            "cf models search failed; skipping CF catalog (CLOUDFLARE_ACCOUNT_ID + token with Workers AI Read)"
        );
        return Ok(Vec::new());
    }
    let v: Value = resp.json().await.context("cf models search json")?;
    let rows = cf_search_result_rows(&v);
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
        let (in_ppm, out_ppm) = cf_pricing_micro_per_m(&raw)
            .or_else(|| price_for_model_id(&slug))
            .unwrap_or((DEFAULT_INPUT_MICRO_PER_M, DEFAULT_OUTPUT_MICRO_PER_M));
        let thinks = slug.contains("gemini-3")
            || slug.contains("claude")
            || slug.contains("o1")
            || slug.contains("reasoner")
            || slug.contains("grok");
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
    assign_picker_order(&mut out);
    tracing::info!(cf_models = out.len(), enabled = out.iter().filter(|m| m.enabled).count(), "cf_models_fetch");
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
    if lower.starts_with("x-ai/") || lower.starts_with("xai/") {
        let slug = lower
            .strip_prefix("x-ai/")
            .or_else(|| lower.strip_prefix("xai/"))
            .unwrap_or(&lower)
            .to_string();
        return Ok(("xai".into(), slug));
    }
    if lower.starts_with("google/") {
        return Err(anyhow::anyhow!("skip google cf model"));
    }
    if lower.starts_with("@cf/") {
        return Ok(("cloudflare".into(), lower.to_string()));
    }
    Err(anyhow::anyhow!("unsupported cf model id: {id}"))
}

fn cf_search_result_rows(v: &Value) -> Vec<Value> {
    let result = v.get("result");
    if let Some(arr) = result.and_then(|r| r.as_array()) {
        return arr.clone();
    }
    if let Some(arr) = result.and_then(|r| r.get("data")).and_then(|d| d.as_array()) {
        return arr.clone();
    }
    Vec::new()
}

fn cf_api_error_hint(body: &str) -> String {
    let v: Value = serde_json::from_str(body).unwrap_or(Value::Null);
    if let Some(msg) = v
        .get("errors")
        .and_then(|e| e.as_array())
        .and_then(|a| a.first())
        .and_then(|o| o.get("message"))
        .and_then(|m| m.as_str())
    {
        return msg.to_string();
    }
    let t = body.trim();
    if t.len() > 200 {
        format!("{}...", t.chars().take(200).collect::<String>())
    } else {
        t.to_string()
    }
}

fn cf_pricing_micro_per_m(raw: &Value) -> Option<(i64, i64)> {
    let pricing = raw.get("pricing")?;
    let in_s = pricing.get("prompt").and_then(|v| v.as_str()).or_else(|| pricing.get("input").and_then(|v| v.as_str()))?;
    let out_s = pricing
        .get("completion")
        .and_then(|v| v.as_str())
        .or_else(|| pricing.get("output").and_then(|v| v.as_str()))?;
    let in_tok = in_s.trim().parse::<f64>().ok().filter(|&n| n >= 0.0)?;
    let out_tok = out_s.trim().parse::<f64>().ok().filter(|&n| n >= 0.0)?;
    if in_tok == 0.0 && out_tok == 0.0 {
        return None;
    }
    Some((usd_per_token_to_micro_per_m(in_tok), usd_per_token_to_micro_per_m(out_tok)))
}

fn usd_per_token_to_micro_per_m(usd_per_token: f64) -> i64 {
    (usd_per_token * 1_000_000.0 * 1_000_000.0).round() as i64
}

async fn catalog_reindex_sort_orders(pool: &PgPool) -> Result<()> {
    let rows = db_retry(pool, || async {
        sqlx::query_as::<_, (String, String, String, String, i64, i64, bool, bool, bool, i32, String, i32, String)>(
            "SELECT id, provider, label, provider_model, input_micro_per_m, output_micro_per_m, supports_thinking, enabled, is_default, sort_order, family, version_rank, source \
             FROM ai.llm_model WHERE deleted_at IS NULL",
        )
        .fetch_all(pool)
        .await
    })
    .await?;
    let mut models = rows
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
    assign_picker_order(&mut models);
    for m in &models {
        let enabled = m.enabled;
        let sort_order = m.sort_order;
        let family = m.family.clone();
        let version_rank = m.version_rank;
        let id = m.id.clone();
        db_retry(pool, || async {
            sqlx::query(
                "UPDATE ai.llm_model SET \
                   sort_order = $1, \
                   family = CASE WHEN source IN ('pinned', 'manual') THEN family ELSE $2 END, \
                   version_rank = CASE WHEN source IN ('pinned', 'manual') THEN version_rank ELSE $3 END, \
                   enabled = CASE WHEN source IN ('pinned', 'manual') THEN enabled ELSE $4 END, \
                   updated_at = NOW() \
                 WHERE id = $5 AND deleted_at IS NULL",
            )
            .bind(sort_order)
            .bind(&family)
            .bind(version_rank)
            .bind(enabled)
            .bind(&id)
            .execute(pool)
            .await
        })
        .await?;
    }
    Ok(())
}

async fn prune_stale_seed_frontier(pool: &PgPool, cf: &[LlmModelRow]) -> Result<()> {
    if cf.is_empty() {
        return Ok(());
    }
    use std::collections::HashSet;
    let providers: HashSet<String> = cf.iter().map(|m| m.provider.clone()).collect();
    for provider in providers {
        db_retry(pool, || async {
            sqlx::query(
                "UPDATE ai.llm_model SET enabled = false, updated_at = NOW() \
                 WHERE source = 'seed' AND provider = $1 AND deleted_at IS NULL",
            )
            .bind(&provider)
            .execute(pool)
            .await
        })
        .await?;
    }
    Ok(())
}

fn cf_chat_eligible(id: &str) -> bool {
    let m = id.to_ascii_lowercase();
    const SKIP: &[&str] = &[
        "embed", "embedding", "whisper", "tts", "dall-e", "image", "moderation", "transcribe", "realtime",
    ];
    if SKIP.iter().any(|s| m.contains(s)) {
        return false;
    }
    m.starts_with("openai/")
        || m.starts_with("anthropic/")
        || m.starts_with("deepseek/")
        || m.starts_with("x-ai/")
        || m.starts_with("xai/")
        || m.starts_with("@cf/")
}

#[cfg(test)]
mod cf_search_tests {
    use super::{cf_api_error_hint, cf_pricing_micro_per_m, cf_search_result_rows};
    use serde_json::json;

    #[test]
    fn cf_search_rows_default_result_array() {
        let v = json!({ "result": [{ "id": "openai/gpt-4" }] });
        assert_eq!(cf_search_result_rows(&v).len(), 1);
    }

    #[test]
    fn cf_search_rows_openrouter_data() {
        let v = json!({ "result": { "data": [{ "id": "anthropic/claude" }] } });
        assert_eq!(cf_search_result_rows(&v).len(), 1);
    }

    #[test]
    fn cf_api_error_hint_parses_cf_json() {
        let body = r#"{"errors":[{"code":7003,"message":"invalid account"}]}"#;
        assert_eq!(cf_api_error_hint(body), "invalid account");
    }

    #[test]
    fn cf_pricing_openrouter_to_micro_per_m() {
        let row = json!({
            "id": "openai/gpt-4o",
            "pricing": { "prompt": "0.00000025", "completion": "0.000001" }
        });
        let (in_ppm, out_ppm) = cf_pricing_micro_per_m(&row).expect("pricing");
        assert_eq!(in_ppm, 250_000);
        assert_eq!(out_ppm, 1_000_000);
    }
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
