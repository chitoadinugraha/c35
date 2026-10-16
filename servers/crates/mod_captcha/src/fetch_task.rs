use std::time::Duration;

use anyhow::{Context, Result};
use async_trait::async_trait;
use c35_mod_fetch::{encode_push, FetchCtx, FetchOutcome, FetchTask};
use c35_proto::FetchCaptchaRatesPush;
use tracing::warn;

use crate::rates_cache::captcha_rates_cache_set;
use crate::rates_parse::parse_pricing_html;
use crate::rates_store::{
    captcha_rates_load, captcha_rates_merge_parsed, captcha_rates_save, captcha_rates_stale_ms,
    captcha_rates_unchanged, CONFIG_KEY, DEFAULT_SOURCE_URL, NATS_SUBJECT,
};

pub const SYNC_INTERVAL_SECS: u64 = 24 * 60 * 60;
const STALE_FORCE_MS: i64 = 7 * 24 * 60 * 60 * 1000;

pub fn captcha_rates_sync_enabled() -> bool {
    std::env::var("CAPTCHA_RATES_SYNC")
        .map(|v| !matches!(v.to_lowercase().as_str(), "0" | "false" | "no"))
        .unwrap_or(true)
}

pub fn captcha_rates_sync_interval_secs() -> u64 {
    std::env::var("CAPTCHA_RATES_SYNC_INTERVAL_SECS")
        .ok()
        .and_then(|v| v.parse().ok())
        .filter(|&n| n > 0)
        .unwrap_or(SYNC_INTERVAL_SECS)
}

fn source_url() -> String {
    std::env::var("CAPTCHA_RATES_SOURCE_URL")
        .ok()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| DEFAULT_SOURCE_URL.to_string())
}

pub struct CaptchaRatesFetchTask;

#[async_trait]
impl FetchTask for CaptchaRatesFetchTask {
    fn name(&self) -> &'static str {
        "captcha_vendor_rates"
    }

    fn interval(&self) -> Duration {
        Duration::from_secs(captcha_rates_sync_interval_secs())
    }

    async fn run(&self, ctx: &FetchCtx) -> Result<FetchOutcome> {
        let stored = captcha_rates_load(&ctx.pool).await?;
        if let Some(ref cfg) = stored {
            if !captcha_rates_stale_ms(cfg, STALE_FORCE_MS) {
                captcha_rates_cache_set(stored.clone());
            }
        }
        let url = source_url();
        let html = ctx
            .http
            .get(&url)
            .timeout(Duration::from_secs(30))
            .send()
            .await
            .context("captcha pricing fetch")?
            .error_for_status()
            .context("captcha pricing status")?
            .text()
            .await
            .context("captcha pricing body")?;
        let parsed = match parse_pricing_html(&html) {
            Ok(m) => m,
            Err(e) => {
                warn!(error = %e, "captcha_rates_parse_failed");
                return Ok(FetchOutcome {
                    changed: false,
                    nats_subject: None,
                    nats_payload: None,
                });
            }
        };
        let next = captcha_rates_merge_parsed(parsed, &url);
        if stored.as_ref().is_some_and(|s| captcha_rates_unchanged(s, &next)) {
            return Ok(FetchOutcome {
                changed: false,
                nats_subject: None,
                nats_payload: None,
            });
        }
        captcha_rates_save(&ctx.pool, &next).await?;
        captcha_rates_cache_set(Some(next.clone()));
        let push = FetchCaptchaRatesPush {
            sync_ts_ms: next.fetched_ts_ms,
            config_key: CONFIG_KEY.to_string(),
        };
        Ok(FetchOutcome {
            changed: true,
            nats_subject: Some(NATS_SUBJECT),
            nats_payload: Some(encode_push(&push)),
        })
    }
}
