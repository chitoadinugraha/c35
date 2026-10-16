use std::sync::{OnceLock, RwLock};

use sqlx::PgPool;

use crate::rates_store::CaptchaWholesaleConfig;
use crate::types::CaptchaKind;

static CACHE: OnceLock<RwLock<Option<CaptchaWholesaleConfig>>> = OnceLock::new();

fn cache() -> &'static RwLock<Option<CaptchaWholesaleConfig>> {
    CACHE.get_or_init(|| RwLock::new(None))
}

pub fn captcha_rates_cache_set(cfg: Option<CaptchaWholesaleConfig>) {
    if let Ok(mut g) = cache().write() {
        *g = cfg;
    }
}

pub fn captcha_rates_cache_get() -> Option<CaptchaWholesaleConfig> {
    cache().read().ok().and_then(|g| g.clone())
}

pub fn captcha_rates_wholesale_usd(kind: CaptchaKind) -> Option<f64> {
    captcha_rates_cache_get()
        .and_then(|cfg| cfg.wholesale_usd(kind))
}

pub async fn captcha_rates_reload_from_db(pool: &PgPool) -> Result<(), sqlx::Error> {
    let cfg = crate::rates_store::captcha_rates_load(pool)
        .await
        .map_err(|e| sqlx::Error::Protocol(e.to_string()))?;
    captcha_rates_cache_set(cfg);
    Ok(())
}
