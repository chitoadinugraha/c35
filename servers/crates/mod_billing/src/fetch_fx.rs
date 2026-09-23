use std::time::Duration;

use anyhow::{anyhow, Context, Result};
use async_trait::async_trait;
use c35_mod_fetch::{encode_push, FetchCtx, FetchOutcome, FetchTask};
use c35_proto::FetchFxPush;
use c35_store::snowflake_id;
use chrono::Utc;
use serde::Deserialize;
use sqlx::Row;

pub const FX_SUBJECT: &str = "c35.fetch.fx";
pub const FX_DEFAULT_MICRO: i64 = 17_630_000_000;
/// Open Exchange Rates app id (free tier, hourly). Override via OPENEXCHANGERATES_APP_ID.
pub const OPENEXCHANGERATES_APP_ID_DEFAULT: &str = "bbfbc56fd1ab494dbbc4531e325e6b8b";
const FX_CURRENCY: &str = "IDR";

pub struct FxRateFetchTask {
    app_id: String,
    markup_bps: i64,
    threshold_bps: i64,
}

impl FxRateFetchTask {
    pub fn from_env() -> Self {
        let app_id = std::env::var("OPENEXCHANGERATES_APP_ID")
            .unwrap_or_default()
            .trim()
            .to_string();
        Self {
            app_id: if app_id.is_empty() { OPENEXCHANGERATES_APP_ID_DEFAULT.into() } else { app_id },
            markup_bps: env_i64("FX_MARKUP_BPS", 1000),
            threshold_bps: env_i64("FX_CHANGE_THRESHOLD_BPS", 25),
        }
    }
}

#[async_trait]
impl FetchTask for FxRateFetchTask {
    fn name(&self) -> &'static str {
        "fx_rate"
    }

    fn interval(&self) -> Duration {
        Duration::from_secs(env_u64("FX_FETCH_INTERVAL_SECS", 3600))
    }

    async fn run(&self, ctx: &FetchCtx) -> Result<FetchOutcome> {
        let raw = fetch_oer_idr(&ctx.http, &self.app_id).await?;
        let published = fx_markup_apply(raw, self.markup_bps);
        let micro = fx_micro_from_idr(published);
        let last = latest_fx_row(&ctx.pool).await?;
        if let Some((_, last_micro)) = last {
            let last_idr = last_micro as f64 / 1_000_000.0;
            if last_idr > 0.0 && fx_change_bps(last_idr, published) < self.threshold_bps {
                return Ok(FetchOutcome {
                    changed: false,
                    nats_subject: None,
                    nats_payload: None,
                });
            }
        }
        let fx_rate_id = snowflake_id();
        let effective = Utc::now();
        sqlx::query(
            "INSERT INTO ai.billing_fx_rate (id, currency, micro_per_usd, effective_from) VALUES ($1, $2, $3, $4)",
        )
        .bind(fx_rate_id)
        .bind(FX_CURRENCY)
        .bind(micro)
        .bind(effective)
        .execute(&ctx.pool)
        .await
        .context("billing_fx_rate insert")?;
        let push = FetchFxPush {
            fx_rate_id,
            micro_per_usd: micro,
            raw_idr_per_usd: raw,
            published_idr_per_usd: published,
            effective_ts_ms: effective.timestamp_millis(),
        };
        Ok(FetchOutcome {
            changed: true,
            nats_subject: Some(FX_SUBJECT),
            nats_payload: Some(encode_push(&push)),
        })
    }
}

pub fn fx_markup_apply(raw_idr: f64, markup_bps: i64) -> f64 {
    raw_idr * (1.0 + markup_bps as f64 / 10_000.0)
}

pub fn fx_micro_from_idr(idr: f64) -> i64 {
    (idr * 1_000_000.0).round() as i64
}

pub fn fx_change_bps(old: f64, new: f64) -> i64 {
    if old <= 0.0 {
        return i64::MAX;
    }
    ((new - old).abs() / old * 10_000.0).round() as i64
}

async fn fetch_oer_idr(http: &reqwest::Client, app_id: &str) -> Result<f64> {
    let url = format!(
        "https://openexchangerates.org/api/latest.json?app_id={}&symbols=IDR",
        urlencoding::encode(app_id)
    );
    let body = http
        .get(&url)
        .timeout(Duration::from_secs(30))
        .send()
        .await
        .context("oer request")?
        .error_for_status()
        .context("oer status")?
        .json::<OerLatest>()
        .await
        .context("oer json")?;
    body.rates
        .get("IDR")
        .copied()
        .filter(|r| *r > 0.0)
        .ok_or_else(|| anyhow!("oer missing IDR rate"))
}

async fn latest_fx_row(pool: &sqlx::PgPool) -> Result<Option<(i64, i64)>> {
    let row = sqlx::query(
        "SELECT id, micro_per_usd FROM ai.billing_fx_rate WHERE currency = $1 ORDER BY effective_from DESC LIMIT 1",
    )
    .bind(FX_CURRENCY)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(|r| (r.get("id"), r.get("micro_per_usd"))))
}

#[derive(Debug, Deserialize)]
struct OerLatest {
    rates: std::collections::HashMap<String, f64>,
}

fn env_i64(key: &str, default: i64) -> i64 {
    std::env::var(key)
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(default)
}

fn env_u64(key: &str, default: u64) -> u64 {
    std::env::var(key)
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(default)
}
