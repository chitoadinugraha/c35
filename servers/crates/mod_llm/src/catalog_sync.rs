use std::collections::{HashMap, HashSet};
use std::time::Duration;

use anyhow::{Context, Result};
use chrono::Utc;
use c35_store::db_retry;
use serde_json::Value;
use sqlx::PgPool;

use crate::catalog_price::{ALIEN_POOL_USD_IN_PER_1M, ALIEN_POOL_USD_OUT_PER_1M};
use crate::catalog_rank::{
    alien_chain_sort_cmp, assign_picker_order, chat_picker_id_eligible, chat_picker_label_eligible, family_of,
    gemini_chat_eligible, pick_default_provider, version_rank_of,
};
use crate::runtime_config::{cf_gateway_config, cf_gateway_ready};
use crate::embed_gemini::gemini_api_key;
use crate::catalog_types::LlmModelRow;
use crate::llm_catalog::{llm_catalog_reload, sync_enabled, sync_interval_secs, upsert_model};
use crate::runtime_config::{runtime_config_reload, CONFIG_KEY_ALIEN_CHAIN};

pub fn llm_catalog_spawn(pool: PgPool) {
    if crate::fetch_catalog::external_fetcher_enabled() || !sync_enabled() {
        return;
    }
    tokio::spawn(async move {
        let mut interval = tokio::time::interval(Duration::from_secs(sync_interval_secs()));
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
    let mut cf = cf_models_fetch().await?;
    if cf.is_empty() {
        cf = openrouter_catalog_fetch().await?;
    }
    if cf.is_empty() && !cf_gateway_ready() {
        tracing::warn!(
            "llm_catalog sync: CF AI gateway not configured — set CLOUDFLARE_API_TOKEN + account (env or ai.config llm.cf_gateway)"
        );
    }
    prune_stale_cf(pool, &cf).await?;
    prune_stale_manual_seed(pool, &cf).await?;
    let cf_ids: HashSet<String> = cf.iter().map(|m| m.id.clone()).collect();
    let price_index = pricing_index_from_rows(&cf);
    let mut fetched = cf;
    fetched.extend(gemini_fetch(&price_index, &cf_ids).await?);
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
    for m in pinned_models() {
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
        input_micro_per_m: (ALIEN_POOL_USD_IN_PER_1M * 1_000_000.0).round() as i64,
        output_micro_per_m: (ALIEN_POOL_USD_OUT_PER_1M * 1_000_000.0).round() as i64,
        supports_thinking: true,
        enabled: true,
        is_default: true,
        sort_order: 0,
        family: "flash-lite".into(),
        version_rank: 0,
        source: "pinned".into(),
    }]
}

fn pricing_index_from_rows(rows: &[LlmModelRow]) -> HashMap<String, (i64, i64)> {
    let mut out = HashMap::new();
    for m in rows {
        out.insert(m.id.clone(), (m.input_micro_per_m, m.output_micro_per_m));
        if m.provider == "google" {
            out.insert(format!("google/{}", m.id), (m.input_micro_per_m, m.output_micro_per_m));
        }
    }
    out
}

fn pricing_lookup(index: &HashMap<String, (i64, i64)>, id: &str) -> Option<(i64, i64)> {
    let key = id.trim();
    index
        .get(key)
        .copied()
        .or_else(|| {
            index
                .get(&format!("google/{}", key.strip_prefix("models/").unwrap_or(key)))
                .copied()
        })
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
    let wholesale = fetched
        .iter()
        .find(|m| m.id == default || m.provider_model == default)
        .map(|m| (m.input_micro_per_m, m.output_micro_per_m))
        .unwrap_or((0, 0));
    db_retry(pool, || async {
        sqlx::query(
            "UPDATE ai.llm_model SET provider_model = $1, input_micro_per_m = $2, output_micro_per_m = $3, \
             family = 'flash-lite', version_rank = $4, updated_at = NOW() \
             WHERE id = 'alienai' AND source = 'pinned'",
        )
        .bind(&default)
        .bind(wholesale.0)
        .bind(wholesale.1)
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

async fn gemini_fetch(price_index: &HashMap<String, (i64, i64)>, cf_ids: &HashSet<String>) -> Result<Vec<LlmModelRow>> {
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
        if cf_ids.contains(&id) {
            continue;
        }
        let label = raw["displayName"].as_str().unwrap_or(&id).to_string();
        let Some((in_ppm, out_ppm)) = pricing_lookup(price_index, &id) else {
            continue;
        };
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
    let client = reqwest::Client::new();
    let mut raw_rows: Vec<Value> = Vec::new();
    const PER_PAGE: u32 = 200;
    const MAX_PAGES: u32 = 40;
    for page in 1..=MAX_PAGES {
        let url = format!(
            "https://api.cloudflare.com/client/v4/accounts/{}/ai/models/search?format=openrouter&per_page={}&page={}",
            cfg.account_id,
            PER_PAGE,
            page
        );
        let resp = client
            .get(&url)
            .header("Authorization", format!("Bearer {}", cfg.api_token))
            .timeout(Duration::from_secs(45))
            .send()
            .await
            .with_context(|| format!("cf models search page {page}"))?;
        if !resp.status().is_success() {
            let status = resp.status();
            let body = resp.text().await.unwrap_or_default();
            tracing::warn!(
                status = %status,
                page,
                hint = %cf_api_error_hint(&body),
                "cf models search failed"
            );
            break;
        }
        let v: Value = resp.json().await.context("cf models search json")?;
        let batch = cf_search_result_rows(&v);
        if batch.is_empty() {
            break;
        }
        let n = batch.len();
        raw_rows.extend(batch);
        if n < PER_PAGE as usize {
            break;
        }
    }
    if raw_rows.is_empty() {
        tracing::warn!("cf_models_fetch: zero rows from Cloudflare models search (check token Workers AI Read + account id)");
    } else {
        tracing::info!(cf_raw_rows = raw_rows.len(), "cf_models_fetch pages merged");
    }
    let mut out = Vec::new();
    for raw in raw_rows {
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
        if !chat_picker_label_eligible(&label) {
            continue;
        }
        let family = family_of(&slug);
        let version_rank = version_rank_of(&slug);
        let Some((in_ppm, out_ppm)) = cf_pricing_micro_per_m(&raw) else {
            continue;
        };
        let thinks = slug.contains("gemini-3")
            || slug.contains("claude")
            || slug.contains("kimi")
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

/// Public OpenRouter model list (live $/token). Used when CF models search returns no rows.
async fn openrouter_catalog_fetch() -> Result<Vec<LlmModelRow>> {
    let v: Value = reqwest::Client::new()
        .get("https://openrouter.ai/api/v1/models")
        .timeout(Duration::from_secs(60))
        .send()
        .await
        .context("openrouter models")?
        .error_for_status()
        .context("openrouter models status")?
        .json()
        .await
        .context("openrouter models json")?;
    let rows = v.get("data").and_then(|d| d.as_array()).cloned().unwrap_or_default();
    let out = catalog_rows_from_openrouter_raw(rows)?;
    tracing::info!(openrouter_models = out.len(), "openrouter_catalog_fetch");
    Ok(out)
}

fn catalog_rows_from_openrouter_raw(rows: Vec<Value>) -> Result<Vec<LlmModelRow>> {
    let mut out = Vec::new();
    for raw in rows {
        let id = raw["id"].as_str().or_else(|| raw["name"].as_str()).unwrap_or("").trim().to_string();
        if id.is_empty() || !cf_chat_eligible(&id) {
            continue;
        }
        let (provider, slug) = cf_provider_slug(&id)?;
        let label = raw["name"]
            .as_str()
            .or_else(|| raw.get("canonical_slug").and_then(|x| x.as_str()))
            .unwrap_or(&slug)
            .to_string();
        if !chat_picker_label_eligible(&label) {
            continue;
        }
        let family = family_of(&slug);
        let version_rank = version_rank_of(&slug);
        let Some((in_ppm, out_ppm)) = cf_pricing_micro_per_m(&raw) else {
            continue;
        };
        let thinks = slug.contains("gemini-3")
            || slug.contains("claude")
            || slug.contains("kimi")
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
    Ok(out)
}

/// OpenRouter-style ids from CF models search (`format=openrouter`).
const CF_CHAT_ID_PREFIXES: &[(&str, &str)] = &[
    ("openai/", "openai"),
    ("anthropic/", "anthropic"),
    ("deepseek/", "deepseek"),
    ("google/", "google"),
    ("x-ai/", "xai"),
    ("xai/", "xai"),
    ("moonshotai/", "moonshot"),
    ("meta-llama/", "meta"),
    ("mistralai/", "mistral"),
    ("qwen/", "qwen"),
    ("cohere/", "cohere"),
    ("perplexity/", "perplexity"),
    ("nvidia/", "nvidia"),
    ("microsoft/", "microsoft"),
    ("z-ai/", "zai"),
    ("minimax/", "minimax"),
    ("baidu/", "baidu"),
    ("amazon/", "amazon"),
];

pub(crate) fn cf_provider_slug_opt(id: &str) -> Option<(String, String)> {
    let lower = id.trim().to_ascii_lowercase();
    if lower.starts_with("@cf/") {
        return Some(("cloudflare".into(), lower));
    }
    for (pfx, provider) in CF_CHAT_ID_PREFIXES {
        if let Some(rest) = lower.strip_prefix(pfx) {
            if !rest.is_empty() {
                return Some((provider.to_string(), rest.to_string()));
            }
        }
    }
    None
}

fn cf_provider_slug(id: &str) -> Result<(String, String)> {
    cf_provider_slug_opt(id).ok_or_else(|| anyhow::anyhow!("unsupported cf model id: {id}"))
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

async fn prune_stale_manual_seed(pool: &PgPool, cf: &[LlmModelRow]) -> Result<()> {
    if cf.is_empty() {
        return Ok(());
    }
    db_retry(pool, || async {
        sqlx::query(
            "UPDATE ai.llm_model SET deleted_at = NOW(), enabled = false, updated_at = NOW() \
             WHERE source = 'seed' AND deleted_at IS NULL",
        )
        .execute(pool)
        .await
    })
    .await?;
    Ok(())
}

fn cf_chat_eligible(id: &str) -> bool {
    if !chat_picker_id_eligible(id) {
        return false;
    }
    let m = id.to_ascii_lowercase();
    const SKIP: &[&str] = &[
        "embed", "embedding", "whisper", "tts", "dall-e", "image", "moderation", "transcribe", "realtime",
    ];
    if SKIP.iter().any(|s| m.contains(s)) {
        return false;
    }
    cf_provider_slug_opt(id).is_some()
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
    fn moonshot_slug_maps_to_provider() {
        let (p, slug) = super::cf_provider_slug_opt("moonshotai/kimi-k2").expect("moonshot");
        assert_eq!(p, "moonshot");
        assert_eq!(slug, "kimi-k2");
    }

    #[test]
    fn cf_pricing_openrouter_to_micro_per_m() {
        let row = json!({
            "id": "openai/gpt-4o",
            "pricing": { "prompt": "0.0000025", "completion": "0.00001" }
        });
        let (in_ppm, out_ppm) = cf_pricing_micro_per_m(&row).expect("pricing");
        assert_eq!(in_ppm, 2_500_000);
        assert_eq!(out_ppm, 10_000_000);
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
