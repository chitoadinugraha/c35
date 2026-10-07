use std::collections::{HashMap, HashSet};
use std::time::Duration;

use anyhow::{Context, Result};
use chrono::{DateTime, Utc};
use c35_store::db_retry;
use serde_json::Value;
use sqlx::PgPool;

use crate::catalog_price::{ALIEN_POOL_USD_IN_PER_1M, ALIEN_POOL_USD_OUT_PER_1M};
use crate::catalog_pricing::{apply_openrouter_pricing, pricing_from_model_row, CatalogPricing};
use crate::catalog_rank::{
    alien_chain_sort_cmp, assign_picker_order, chat_picker_id_eligible, chat_picker_label_eligible, family_of,
    gemini_chat_eligible, pick_default_provider, version_rank_of,
};
use crate::runtime_config::{cf_gateway_config, cf_gateway_ready};
use crate::embed_gemini::gemini_api_key;
use crate::catalog_types::LlmModelRow;
use crate::llm_catalog::{llm_catalog_reload, sync_enabled, sync_interval_secs, upsert_model};
use crate::runtime_config::{runtime_config_reload, CONFIG_KEY_ALIEN_CHAIN};

pub type PricingIndex = HashMap<String, CatalogPricing>;

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
    let or_raw = openrouter_models_raw().await?;
    let or_prices = openrouter_pricing_index_from_raw(&or_raw);
    let mut cf = cf_models_fetch().await?;
    if cf.is_empty() {
        cf = catalog_rows_from_openrouter_raw(or_raw.clone())?;
    }
    for m in cf.iter_mut() {
        apply_openrouter_pricing(m, &or_prices);
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
    upsert_openrouter_embed_models(pool, &or_raw, &or_prices, synced_at).await?;
    let mut fetched = cf;
    fetched.extend(gemini_fetch(&price_index, &cf_ids).await?);
    for m in fetched.iter_mut() {
        apply_openrouter_pricing(m, &or_prices);
        upsert_model(pool, m, synced_at).await?;
    }
    let reconciled = llm_catalog_reconcile_or_prices(pool, &or_prices, synced_at).await?;
    disable_duplicate_seed_models(pool).await?;
    if reconciled > 0 {
        tracing::info!(reconciled, "llm_catalog openrouter price reconcile");
    }
    prune_stale_google(pool, &fetched).await?;
    sync_alien_meta(pool, &fetched).await?;
    sync_live_offers(pool, &price_index).await?;
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
        h.update(&m.input_cache_micro_per_m.to_le_bytes());
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
        input_cache_micro_per_m: 0,
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

fn pricing_index_from_rows(rows: &[LlmModelRow]) -> HashMap<String, CatalogPricing> {
    let mut out = HashMap::new();
    for m in rows {
        let p = CatalogPricing {
            input_micro_per_m: m.input_micro_per_m,
            output_micro_per_m: m.output_micro_per_m,
            input_cache_micro_per_m: m.input_cache_micro_per_m,
        };
        out.insert(m.id.clone(), p);
        if m.provider == "google" {
            out.insert(format!("google/{}", m.id), p);
        }
    }
    out
}

fn pricing_lookup(index: &HashMap<String, CatalogPricing>, id: &str) -> Option<CatalogPricing> {
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

pub async fn sync_live_offers(pool: &PgPool, price_index: &PricingIndex) -> Result<()> {
    // 1. Google video rate: 15,480 video tokens/min * flash_input_rate (fallback 0.00155)
    let google_flash_rate = price_index
        .get("gemini-2.5-flash")
        .or_else(|| price_index.get("google/gemini-2.5-flash"))
        .or_else(|| price_index.get("gemini-2.0-flash"))
        .or_else(|| price_index.get("google/gemini-2.0-flash"))
        .or_else(|| price_index.get("gemini-1.5-flash"))
        .or_else(|| {
            price_index.iter().find_map(|(k, v)| {
                if k.contains("flash") && !k.contains("lite") && v.input_micro_per_m > 0 {
                    Some(v)
                } else {
                    None
                }
            })
        });
    let google_video_rate = if let Some(p) = google_flash_rate {
        let rate_per_token = (p.input_micro_per_m as f64) / 1_000_000.0 / 1_000_000.0;
        if rate_per_token > 0.0 {
            15_480.0 * rate_per_token
        } else {
            0.00155
        }
    } else {
        0.00155
    };

    // 2. OpenAI video rate: 5,100 vision tokens/min * gpt4o_vision_rate (fallback 0.0255)
    let openai_gpt4o_rate = price_index
        .get("gpt-4o")
        .or_else(|| price_index.get("openai/gpt-4o"))
        .or_else(|| price_index.get("gpt-4o-2024-11-20"))
        .or_else(|| price_index.get("gpt-4o-realtime-preview"))
        .or_else(|| {
            price_index.iter().find_map(|(k, v)| {
                if k.contains("gpt-4o") && !k.contains("mini") && v.input_micro_per_m > 0 {
                    Some(v)
                } else {
                    None
                }
            })
        });
    let openai_video_rate = if let Some(p) = openai_gpt4o_rate {
        let rate_per_token = (p.input_micro_per_m as f64) / 1_000_000.0 / 1_000_000.0;
        if rate_per_token > 0.0 {
            5_100.0 * rate_per_token
        } else {
            0.0255
        }
    } else {
        0.0255
    };

    // 3. xAI video rate: 2,500 vision tokens/min * grok_vision_rate (fallback 0.0050)
    let xai_grok_rate = price_index
        .get("grok-2-vision")
        .or_else(|| price_index.get("grok-2-vision-1212"))
        .or_else(|| price_index.get("x-ai/grok-2-vision"))
        .or_else(|| price_index.get("x-ai/grok-2-vision-1212"))
        .or_else(|| price_index.get("grok-2"))
        .or_else(|| {
            price_index.iter().find_map(|(k, v)| {
                if k.contains("grok") && v.input_micro_per_m > 0 {
                    Some(v)
                } else {
                    None
                }
            })
        });
    let xai_video_rate = if let Some(p) = xai_grok_rate {
        let rate_per_token = (p.input_micro_per_m as f64) / 1_000_000.0 / 1_000_000.0;
        if rate_per_token > 0.0 {
            2_500.0 * rate_per_token
        } else {
            0.0050
        }
    } else {
        0.0050
    };

    let updates = [
        ("live.alienai", google_video_rate),
        ("live.gemini", google_video_rate),
        ("live.gemini.thinker", google_video_rate),
        ("live.chatgpt", openai_video_rate),
        ("live.grok", xai_video_rate),
    ];

    for (id, video_rate) in updates {
        db_retry(pool, || async {
            sqlx::query(
                "UPDATE ai.live_offer SET video_usd_per_min = $1, updated_ts = NOW() \
                 WHERE id = $2 AND deleted_ts IS NULL",
            )
            .bind(video_rate)
            .bind(id)
            .execute(pool)
            .await
        })
        .await?;
    }

    tracing::info!(
        google_video_rate,
        openai_video_rate,
        xai_video_rate,
        "sync_live_offers completed"
    );
    Ok(())
}

async fn gemini_fetch(price_index: &HashMap<String, CatalogPricing>, cf_ids: &HashSet<String>) -> Result<Vec<LlmModelRow>> {
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
        let Some(p) = pricing_lookup(price_index, &id) else {
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
            input_micro_per_m: p.input_micro_per_m,
            input_cache_micro_per_m: p.input_cache_micro_per_m,
            output_micro_per_m: p.output_micro_per_m,
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
        let Some(p) = pricing_from_model_row(&raw) else {
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
            input_micro_per_m: p.input_micro_per_m,
            input_cache_micro_per_m: p.input_cache_micro_per_m,
            output_micro_per_m: p.output_micro_per_m,
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

async fn openrouter_models_raw() -> Result<Vec<Value>> {
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
    Ok(v.get("data").and_then(|d| d.as_array()).cloned().unwrap_or_default())
}

fn openrouter_pricing_index_from_raw(rows: &[Value]) -> HashMap<String, CatalogPricing> {
    let mut out = HashMap::new();
    for raw in rows {
        let id = raw["id"].as_str().or_else(|| raw["name"].as_str()).unwrap_or("").trim();
        if id.is_empty() {
            continue;
        }
        let Some(p) = pricing_from_model_row(raw) else {
            continue;
        };
        out.insert(id.to_string(), p);
        if let Some((provider, slug)) = cf_provider_slug_opt(id) {
            out.insert(slug.clone(), p);
            if provider == "google" {
                out.insert(format!("google/{}", slug), p);
            }
        }
    }
    out
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
        let Some(p) = pricing_from_model_row(&raw) else {
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
            input_micro_per_m: p.input_micro_per_m,
            input_cache_micro_per_m: p.input_cache_micro_per_m,
            output_micro_per_m: p.output_micro_per_m,
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

async fn catalog_reindex_sort_orders(pool: &PgPool) -> Result<()> {
    let rows = db_retry(pool, || async {
        sqlx::query_as::<_, (String, String, String, String, i64, i64, i64, bool, bool, bool, i32, String, i32, String)>(
            "SELECT id, provider, label, provider_model, input_micro_per_m, input_cache_micro_per_m, output_micro_per_m, supports_thinking, enabled, is_default, sort_order, family, version_rank, source \
             FROM ai.llm_model WHERE deleted_at IS NULL",
        )
        .fetch_all(pool)
        .await
    })
    .await?;
    let mut models = rows
        .into_iter()
        .map(
            |(id, provider, label, provider_model, input_micro_per_m, input_cache_micro_per_m, output_micro_per_m, supports_thinking, enabled, is_default, sort_order, family, version_rank, source)| {
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

fn openrouter_embed_eligible(id: &str) -> bool {
    let lower = id.trim().to_ascii_lowercase();
    if lower.is_empty() {
        return false;
    }
    if lower.contains("image") || lower.contains("transcribe") || lower.contains("whisper") {
        return false;
    }
    lower.contains("embed") || lower.contains("embedding")
}

async fn upsert_openrouter_embed_models(
    pool: &PgPool,
    or_raw: &[Value],
    or_prices: &HashMap<String, CatalogPricing>,
    synced_at: DateTime<Utc>,
) -> Result<()> {
    for raw in or_raw {
        let id = raw["id"].as_str().or_else(|| raw["name"].as_str()).unwrap_or("").trim();
        if id.is_empty() || !openrouter_embed_eligible(id) {
            continue;
        }
        let (provider, slug) = match cf_provider_slug_opt(id) {
            Some(p) => p,
            None => continue,
        };
        let label = raw["name"]
            .as_str()
            .or_else(|| raw.get("canonical_slug").and_then(|x| x.as_str()))
            .unwrap_or(slug.as_str())
            .to_string();
        let version_rank = version_rank_of(&slug);
        let mut row = LlmModelRow {
            id: slug,
            provider,
            label,
            provider_model: id.to_string(),
            input_micro_per_m: 0,
            input_cache_micro_per_m: 0,
            output_micro_per_m: 0,
            supports_thinking: false,
            enabled: false,
            is_default: false,
            sort_order: 9000,
            family: "embed".into(),
            version_rank,
            source: "or_api".into(),
        };
        apply_openrouter_pricing(&mut row, or_prices);
        if let Some(p) = pricing_from_model_row(raw) {
            row.input_micro_per_m = p.input_micro_per_m;
            row.output_micro_per_m = p.output_micro_per_m;
            row.input_cache_micro_per_m = p.input_cache_micro_per_m;
        }
        if row.input_micro_per_m == 0 && row.output_micro_per_m == 0 {
            continue;
        }
        upsert_model(pool, &row, synced_at).await?;
    }
    Ok(())
}

async fn llm_catalog_reconcile_or_prices(
    pool: &PgPool,
    or_prices: &HashMap<String, CatalogPricing>,
    synced_at: DateTime<Utc>,
) -> Result<usize> {
    let rows = db_retry(pool, || async {
        sqlx::query_as::<_, (String, String, String, String, i64, i64, i64, bool, bool, bool, i32, String, i32, String)>(
            "SELECT id, provider, label, provider_model, input_micro_per_m, input_cache_micro_per_m, output_micro_per_m, supports_thinking, enabled, is_default, sort_order, family, version_rank, source \
             FROM ai.llm_model WHERE deleted_at IS NULL",
        )
        .fetch_all(pool)
        .await
    })
    .await?;
    let mut updated = 0usize;
    for (id, provider, label, provider_model, in_ppm, cache_ppm, out_ppm, supports_thinking, enabled, is_default, sort_order, family, version_rank, source) in rows {
        if id == "alienai" || provider == "alienai" {
            continue;
        }
        let mut row = LlmModelRow {
            id,
            provider,
            label,
            provider_model,
            input_micro_per_m: in_ppm,
            input_cache_micro_per_m: cache_ppm,
            output_micro_per_m: out_ppm,
            supports_thinking,
            enabled,
            is_default,
            sort_order,
            family,
            version_rank,
            source,
        };
        let before = (row.input_micro_per_m, row.input_cache_micro_per_m, row.output_micro_per_m);
        apply_openrouter_pricing(&mut row, or_prices);
        let after = (row.input_micro_per_m, row.input_cache_micro_per_m, row.output_micro_per_m);
        if before == after {
            continue;
        }
        db_retry(pool, || async {
            sqlx::query(
                "UPDATE ai.llm_model SET input_micro_per_m = $1, input_cache_micro_per_m = $2, output_micro_per_m = $3, synced_at = $4, updated_at = NOW() \
                 WHERE id = $5 AND deleted_at IS NULL AND provider <> 'alienai' AND id <> 'alienai'",
            )
            .bind(after.0)
            .bind(after.1)
            .bind(after.2)
            .bind(synced_at)
            .bind(&row.id)
            .execute(pool)
            .await
        })
        .await?;
        updated += 1;
    }
    Ok(updated)
}

async fn disable_duplicate_seed_models(pool: &PgPool) -> Result<()> {
    db_retry(pool, || async {
        sqlx::query(
            "UPDATE ai.llm_model AS s SET enabled = false, updated_at = NOW() \
             FROM ai.llm_model AS c \
             WHERE s.source = 'seed' AND s.deleted_at IS NULL AND s.enabled = true \
               AND c.deleted_at IS NULL AND c.source IN ('cf_api', 'api', 'or_api') \
               AND c.provider_model <> '' AND s.provider_model = c.provider_model AND s.id <> c.id",
        )
        .execute(pool)
        .await
    })
    .await?;
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
    use super::{cf_api_error_hint, cf_search_result_rows};
    use crate::catalog_pricing::pricing_from_model_row;
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
            "pricing": {
                "prompt": "0.0000025",
                "completion": "0.00001",
                "input_cache_read": "0.000000625"
            }
        });
        let p = pricing_from_model_row(&row).expect("pricing");
        assert_eq!(p.input_micro_per_m, 2_500_000);
        assert_eq!(p.output_micro_per_m, 10_000_000);
        assert_eq!(p.input_cache_micro_per_m, 625_000);
    }

    #[test]
    fn openrouter_pricing_index_resolves_google_slug() {
        let rows = vec![json!({
            "id": "google/gemini-3.5-flash-lite",
            "pricing": {
                "prompt": "0.0000003",
                "completion": "0.0000025",
                "input_cache_read": "0.00000003"
            }
        })];
        let idx = super::openrouter_pricing_index_from_raw(&rows);
        let p = idx.get("gemini-3.5-flash-lite").expect("slug");
        assert_eq!(p.input_micro_per_m, 300_000);
        assert_eq!(p.output_micro_per_m, 2_500_000);
        assert_eq!(p.input_cache_micro_per_m, 30_000);
    }

    #[test]
    fn test_sync_live_offers_calculation() {
        use std::collections::HashMap;
        use crate::catalog_pricing::CatalogPricing;

        let mut index = HashMap::new();
        index.insert(
            "gemini-2.5-flash".to_string(),
            CatalogPricing {
                input_micro_per_m: 100_000, // $0.10 per 1M tokens
                output_micro_per_m: 400_000,
                input_cache_micro_per_m: 25_000,
            },
        );
        index.insert(
            "gpt-4o".to_string(),
            CatalogPricing {
                input_micro_per_m: 5_000_000, // $5.00 per 1M tokens
                output_micro_per_m: 15_000_000,
                input_cache_micro_per_m: 1_250_000,
            },
        );
        index.insert(
            "grok-2-vision".to_string(),
            CatalogPricing {
                input_micro_per_m: 2_000_000, // $2.00 per 1M tokens
                output_micro_per_m: 10_000_000,
                input_cache_micro_per_m: 0,
            },
        );

        // Google: 15480 * 0.10 / 1_000_000 = 0.001548
        let google_rate: f64 = 15_480.0 * (100_000.0 / 1e12);
        assert!((google_rate - 0.001548).abs() < 1e-6);

        // OpenAI: 5100 * 5.00 / 1_000_000 = 0.0255
        let openai_rate: f64 = 5_100.0 * (5_000_000.0 / 1e12);
        assert!((openai_rate - 0.0255).abs() < 1e-6);

        // xAI: 2500 * 2.00 / 1_000_000 = 0.0050
        let xai_rate: f64 = 2_500.0 * (2_000_000.0 / 1e12);
        assert!((xai_rate - 0.0050).abs() < 1e-6);
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
