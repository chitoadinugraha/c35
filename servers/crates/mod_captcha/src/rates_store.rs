use anyhow::{Context, Result};
use chrono::Utc;
use serde::{Deserialize, Serialize};
use sqlx::PgPool;

use crate::types::CaptchaKind;

pub const CONFIG_KEY: &str = "captcha.2captcha_wholesale";
pub const NATS_SUBJECT: &str = "c35.fetch.captcha_rates";
pub const DEFAULT_SOURCE_URL: &str = "https://2captcha.com/pricing";

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct CaptchaKindRate {
    pub wholesale_usd: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct CaptchaWholesaleConfig {
    pub vendor: String,
    pub kinds: std::collections::HashMap<String, CaptchaKindRate>,
    pub source_url: String,
    pub fetched_ts_ms: i64,
}

impl CaptchaWholesaleConfig {
    pub fn wholesale_usd(&self, kind: CaptchaKind) -> Option<f64> {
        self.kinds
            .get(kind.billing_kind_key())
            .map(|r| r.wholesale_usd)
            .filter(|&n| n > 0.0)
    }
}

pub fn default_compiled_config() -> CaptchaWholesaleConfig {
    let mut kinds = std::collections::HashMap::new();
    for kind in [
        CaptchaKind::RecaptchaV2,
        CaptchaKind::RecaptchaV3,
        CaptchaKind::Hcaptcha,
        CaptchaKind::Image,
    ] {
        kinds.insert(
            kind.billing_kind_key().to_string(),
            CaptchaKindRate {
                wholesale_usd: crate::billing::compiled_wholesale_usd(kind),
            },
        );
    }
    CaptchaWholesaleConfig {
        vendor: "2captcha".into(),
        kinds,
        source_url: DEFAULT_SOURCE_URL.into(),
        fetched_ts_ms: 0,
    }
}

pub async fn captcha_rates_load(pool: &PgPool) -> Result<Option<CaptchaWholesaleConfig>> {
    let row = sqlx::query_scalar::<_, Option<serde_json::Value>>(
        "SELECT value FROM ai.config WHERE key = $1",
    )
    .bind(CONFIG_KEY)
    .fetch_optional(pool)
    .await?;
    let Some(value) = row.flatten() else {
        return Ok(None);
    };
    let cfg: CaptchaWholesaleConfig = serde_json::from_value(value).context("captcha rates json")?;
    Ok(Some(cfg))
}

pub async fn captcha_rates_save(pool: &PgPool, cfg: &CaptchaWholesaleConfig) -> Result<()> {
    let value = serde_json::to_value(cfg).context("captcha rates serialize")?;
    sqlx::query(
        "INSERT INTO ai.config (key, value, updated_at) VALUES ($1, $2, NOW()) \
         ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()",
    )
    .bind(CONFIG_KEY)
    .bind(value)
    .execute(pool)
    .await
    .context("captcha rates upsert")?;
    Ok(())
}

pub fn captcha_rates_merge_parsed(
    parsed: std::collections::HashMap<String, f64>,
    source_url: &str,
) -> CaptchaWholesaleConfig {
    let base = default_compiled_config();
    let mut kinds = base.kinds;
    for (key, usd) in parsed {
        if usd > 0.0 {
            kinds.insert(key, CaptchaKindRate { wholesale_usd: usd });
        }
    }
    CaptchaWholesaleConfig {
        vendor: "2captcha".into(),
        kinds,
        source_url: source_url.to_string(),
        fetched_ts_ms: Utc::now().timestamp_millis(),
    }
}

pub fn captcha_rates_unchanged(a: &CaptchaWholesaleConfig, b: &CaptchaWholesaleConfig) -> bool {
    for key in ["recaptcha_v2", "recaptcha_v3", "hcaptcha", "image"] {
        let x = a.kinds.get(key).map(|r| r.wholesale_usd).unwrap_or(0.0);
        let y = b.kinds.get(key).map(|r| r.wholesale_usd).unwrap_or(0.0);
        if x <= 0.0 || y <= 0.0 {
            if (x - y).abs() > 1e-12 {
                return false;
            }
            continue;
        }
        if (x - y).abs() / x > 0.001 {
            return false;
        }
    }
    true
}

pub fn captcha_rates_stale_ms(cfg: &CaptchaWholesaleConfig, max_age_ms: i64) -> bool {
    if cfg.fetched_ts_ms <= 0 {
        return true;
    }
    let now = Utc::now().timestamp_millis();
    now - cfg.fetched_ts_ms > max_age_ms
}
