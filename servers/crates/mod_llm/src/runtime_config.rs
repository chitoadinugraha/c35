use std::collections::HashMap;
use std::sync::{LazyLock, RwLock};
use std::time::Duration;

use chrono::{DateTime, Utc};
use c35_store::db_retry;
use sqlx::PgPool;
use tracing::{info, warn};

use crate::catalog_resolve::catalog_alien_chain_effective;

pub const CONFIG_KEY_ALIEN_CHAIN: &str = "llm.alien_chain";
pub const CONFIG_KEY_CF_GATEWAY: &str = "llm.cf_gateway";
pub const CF_ACCOUNT_ID_DEFAULT: &str = "13bbda4c964029cb15bb16c7d57ec548";

#[derive(Clone, Debug, Default)]
pub struct CfGatewayRuntime {
    pub enabled: bool,
    pub account_id: String,
    pub gateway_id: String,
    pub api_token: String,
}

#[derive(Clone, Debug)]
struct RuntimeState {
    alien_models: Vec<String>,
    cf: CfGatewayRuntime,
}

impl Default for RuntimeState {
    fn default() -> Self {
        Self { alien_models: Vec::new(), cf: cf_gateway_from_env() }
    }
}

static RUNTIME: LazyLock<RwLock<RuntimeState>> = LazyLock::new(|| RwLock::new(RuntimeState::default()));

pub fn alien_chain_default() -> Vec<String> {
    Vec::new()
}

pub fn model_is_flash_lite(model: &str) -> bool {
    let m = model.trim().to_ascii_lowercase();
    if m.is_empty() || m.contains("pro") {
        return false;
    }
    m.contains("flash-lite") || m.contains("flash_lite")
}

pub fn alien_chain_normalize(raw: &[String]) -> Vec<String> {
    raw.iter()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty() && model_is_flash_lite(s))
        .collect()
}

fn env_or(key: &str) -> String {
    std::env::var(key).unwrap_or_default().trim().to_string()
}

fn cf_account_id_from_env() -> String {
    env_or("CLOUDFLARE_ACCOUNT_ID").if_empty_then(&env_or("CF_ACCOUNT_ID"))
}

fn cf_api_token_from_env() -> String {
    std::env::var("CLOUDFLARE_AIG_API_TOKEN")
        .or_else(|_| std::env::var("CLOUDFLARE_API_TOKEN"))
        .or_else(|_| std::env::var("CF_API_TOKEN"))
        .unwrap_or_default()
        .trim()
        .to_string()
}

pub fn cf_gateway_from_env() -> CfGatewayRuntime {
    let api_token = cf_api_token_from_env();
    let account_id = cf_account_id_from_env();
    let account_id = if account_id.is_empty() && !api_token.is_empty() {
        CF_ACCOUNT_ID_DEFAULT.to_string()
    } else {
        account_id
    };
    CfGatewayRuntime {
        enabled: true,
        account_id,
        gateway_id: env_or("CLOUDFLARE_AI_GATEWAY_ID").if_empty_then("default"),
        api_token,
    }
}

pub async fn cf_account_id_from_token(token: &str) -> Option<String> {
    let token = token.trim();
    if token.is_empty() {
        return None;
    }
    let resp = reqwest::Client::new()
        .get("https://api.cloudflare.com/client/v4/accounts?per_page=1")
        .header("Authorization", format!("Bearer {}", token))
        .timeout(Duration::from_secs(15))
        .send()
        .await;
    let resp = match resp {
        Ok(r) if r.status().is_success() => r,
        Ok(r) => {
            warn!(status = %r.status(), "cf account lookup failed");
            return None;
        }
        Err(e) => {
            warn!(error = %e, "cf account lookup request failed");
            return None;
        }
    };
    let v: serde_json::Value = resp.json().await.ok()?;
    v.get("result")
        .and_then(|r| r.as_array())
        .and_then(|a| a.first())
        .and_then(|o| o.get("id"))
        .and_then(|id| id.as_str())
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
}

async fn cf_gateway_finalize(mut cfg: CfGatewayRuntime) -> CfGatewayRuntime {
    if !cfg.enabled || cfg.api_token.is_empty() || !cfg.account_id.is_empty() {
        return cfg;
    }
    cfg.account_id = cf_account_id_from_token(&cfg.api_token)
        .await
        .unwrap_or_else(|| CF_ACCOUNT_ID_DEFAULT.to_string());
    cfg
}

trait StrEmpty {
    fn if_empty_then(self, fallback: &str) -> String;
}

impl StrEmpty for String {
    fn if_empty_then(self, fallback: &str) -> String {
        if self.is_empty() { fallback.into() } else { self }
    }
}

fn cf_gateway_merge_env(mut cfg: CfGatewayRuntime) -> CfGatewayRuntime {
    let env = cf_gateway_from_env();
    if cfg.account_id.is_empty() {
        cfg.account_id = env.account_id;
    }
    if cfg.gateway_id.is_empty() {
        cfg.gateway_id = env.gateway_id;
    }
    if cfg.api_token.is_empty() {
        cfg.api_token = env.api_token;
    }
    cfg
}

fn cf_gateway_parse(v: &serde_json::Value) -> CfGatewayRuntime {
    let cfg = CfGatewayRuntime {
        enabled: v.get("enabled").and_then(|x| x.as_bool()).unwrap_or(true),
        account_id: v.get("account_id").and_then(|x| x.as_str()).unwrap_or("").trim().to_string(),
        gateway_id: v.get("gateway_id").and_then(|x| x.as_str()).unwrap_or("").trim().to_string(),
        api_token: v.get("api_token").and_then(|x| x.as_str()).unwrap_or("").trim().to_string(),
    };
    cf_gateway_merge_env(cfg)
}

async fn config_json(pool: &PgPool, key: &str) -> Result<Option<serde_json::Value>, sqlx::Error> {
    db_retry(pool, || async {
        sqlx::query_scalar("SELECT value FROM ai.config WHERE key = $1")
            .bind(key)
            .fetch_optional(pool)
            .await
    })
    .await
}

async fn alien_chain_load(pool: &PgPool) -> Result<Vec<String>, sqlx::Error> {
    let row = config_json(pool, CONFIG_KEY_ALIEN_CHAIN).await?;
    let parsed = row.and_then(|v| {
        v.get("models").and_then(|m| m.as_array()).map(|arr| {
            arr.iter()
                .filter_map(|x| x.as_str().map(str::to_string))
                .collect::<Vec<_>>()
        })
    });
    let configured = alien_chain_normalize(parsed.as_deref().unwrap_or(&[]));
    Ok(catalog_alien_chain_effective(&configured))
}

async fn cf_gateway_load(pool: &PgPool) -> Result<CfGatewayRuntime, sqlx::Error> {
    let row = config_json(pool, CONFIG_KEY_CF_GATEWAY).await?;
    Ok(row.map(|v| cf_gateway_parse(&v)).unwrap_or_else(cf_gateway_from_env))
}

async fn config_updated_at(pool: &PgPool, key: &str) -> Option<DateTime<Utc>> {
    db_retry(pool, || async {
        sqlx::query_scalar("SELECT updated_at FROM ai.config WHERE key = $1")
            .bind(key)
            .fetch_optional(pool)
            .await
    })
    .await
    .ok()
    .flatten()
}

pub async fn runtime_config_reload(pool: &PgPool) {
    crate::llm_catalog::llm_catalog_ensure_memory(pool).await;
    let alien = match alien_chain_load(pool).await {
        Ok(m) => m,
        Err(e) => {
            warn!("[c35:runtime] alien chain load failed: {e:#}");
            catalog_alien_chain_effective(&[])
        }
    };
    let cf = match cf_gateway_load(pool).await {
        Ok(c) => c,
        Err(e) => {
            warn!("[c35:runtime] cf gateway load failed: {e:#}");
            cf_gateway_from_env()
        }
    };
    let cf = cf_gateway_finalize(cf).await;
    {
        let mut state = RUNTIME.write().expect("runtime lock");
        state.alien_models = alien;
        state.cf = cf;
    }
    runtime_config_log();
}

pub async fn runtime_config_init(pool: &PgPool) {
    runtime_config_reload(pool).await;
}

pub fn runtime_config_watch(pool: PgPool) {
    tokio::spawn(async move {
        let mut seen: HashMap<String, DateTime<Utc>> = HashMap::new();
        for key in [CONFIG_KEY_ALIEN_CHAIN, CONFIG_KEY_CF_GATEWAY] {
            if let Some(ts) = config_updated_at(&pool, key).await {
                seen.insert(key.to_string(), ts);
            }
        }
        loop {
            tokio::time::sleep(Duration::from_secs(30)).await;
            let keys = [CONFIG_KEY_ALIEN_CHAIN, CONFIG_KEY_CF_GATEWAY];
            let mut changed = false;
            for key in keys {
                let cur = config_updated_at(&pool, key).await;
                let prev = seen.get(key).copied();
                if cur != prev {
                    if let Some(ts) = cur {
                        seen.insert(key.to_string(), ts);
                    }
                    changed = true;
                }
            }
            if changed {
                runtime_config_reload(&pool).await;
            }
        }
    });
}

fn runtime_config_log() {
    let state = RUNTIME.read().expect("runtime lock");
    info!("[c35:runtime] alien chain (flash-lite): {:?}", state.alien_models);
    let cf = &state.cf;
    info!(
        "[c35:runtime] cf gateway enabled={} account={} gateway={} token={}",
        cf.enabled,
        if cf.account_id.is_empty() { "-" } else { &cf.account_id },
        cf.gateway_id,
        if cf.api_token.is_empty() { "missing" } else { "set" }
    );
}

pub fn alien_chain_models() -> Vec<String> {
    RUNTIME.read().expect("runtime lock").alien_models.clone()
}

pub fn alien_default_model() -> String {
    use crate::catalog_resolve::catalog_alien_default;
    alien_chain_models()
        .first()
        .cloned()
        .or_else(catalog_alien_default)
        .unwrap_or_default()
}

pub fn cf_gateway_config() -> CfGatewayRuntime {
    RUNTIME.read().expect("runtime lock").cf.clone()
}

pub fn cf_gateway_ready() -> bool {
    let c = cf_gateway_config();
    c.enabled && !c.account_id.is_empty() && !c.api_token.is_empty()
}
