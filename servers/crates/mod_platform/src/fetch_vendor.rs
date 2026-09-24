use std::time::Duration;

use anyhow::Result;
use async_trait::async_trait;
use chrono::{NaiveDate, Utc};
use c35_mod_fetch::{FetchCtx, FetchOutcome, FetchTask};

use crate::period::{
    vendor_bill_mtd_window, vendor_bill_prev_month_window, vendor_bill_should_finalize_today,
};
use crate::vendor_cost::{vendor_cost_finalize_period, vendor_cost_upsert_batch, VendorCostLine};

#[async_trait]
pub trait VendorBillSource: Send + Sync {
    fn vendor(&self) -> &'static str;
    async fn fetch_lines(
        &self,
        ctx: &FetchCtx,
        window: (NaiveDate, NaiveDate),
    ) -> Result<Vec<VendorCostLine>>;
}

pub struct VendorBillFetchTask {
    pub source: Box<dyn VendorBillSource>,
    pub stagger_mins: u64,
}

impl VendorBillFetchTask {
    pub fn new(source: Box<dyn VendorBillSource>, stagger_mins: u64) -> Self {
        Self {
            source,
            stagger_mins,
        }
    }

}

pub fn env_enabled(key: &str) -> bool {
    std::env::var(key)
        .map(|v| env_flag(&v))
        .unwrap_or(false)
}

pub fn parse_finalize_days() -> Vec<u32> {
    std::env::var("VENDOR_BILL_FINALIZE_DAYS")
        .unwrap_or_else(|_| "1,3,7,14".into())
        .split(',')
        .filter_map(|s| s.trim().parse().ok())
        .collect()
}

fn env_flag(v: &str) -> bool {
    matches!(
        v.trim().to_ascii_lowercase().as_str(),
        "1" | "true" | "yes" | "on"
    )
}

fn env_u64(key: &str, default: u64) -> u64 {
    std::env::var(key)
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(default)
}

fn vendor_bill_mtd_enabled() -> bool {
    std::env::var("VENDOR_BILL_MTD_ENABLED")
        .map(|v| env_flag(&v))
        .unwrap_or(true)
}

async fn fetch_and_upsert(
    ctx: &FetchCtx,
    source: &dyn VendorBillSource,
    window: (NaiveDate, NaiveDate),
) -> Result<usize> {
    let lines = source.fetch_lines(ctx, window).await?;
    if lines.is_empty() {
        return Ok(0);
    }
    vendor_cost_upsert_batch(&ctx.pool, &lines).await
}

#[async_trait]
impl FetchTask for VendorBillFetchTask {
    fn name(&self) -> &'static str {
        match self.source.vendor() {
            "oci" => "vendor_bill_oci",
            "gcp" => "vendor_bill_gcp",
            "cf" => "vendor_bill_cf",
            "wasabi" => "vendor_bill_wasabi",
            _ => "vendor_bill",
        }
    }

    fn interval(&self) -> Duration {
        Duration::from_secs(env_u64("VENDOR_BILL_FETCH_INTERVAL_SECS", 86_400))
    }

    async fn run(&self, ctx: &FetchCtx) -> Result<FetchOutcome> {
        let now = Utc::now();
        let finalize_days = parse_finalize_days();
        let mut rows = 0usize;

        if vendor_bill_should_finalize_today(now, &finalize_days) {
            let window = vendor_bill_prev_month_window(now);
            rows += fetch_and_upsert(ctx, self.source.as_ref(), window).await?;
            let _ = vendor_cost_finalize_period(
                &ctx.pool,
                self.source.vendor(),
                window.0,
                window.1,
            )
            .await?;
        }

        if vendor_bill_mtd_enabled() {
            let window = vendor_bill_mtd_window(now);
            if window.1 >= window.0 {
                rows += fetch_and_upsert(ctx, self.source.as_ref(), window).await?;
            }
        }

        Ok(FetchOutcome {
            changed: rows > 0,
            nats_subject: None,
            nats_payload: None,
        })
    }
}
