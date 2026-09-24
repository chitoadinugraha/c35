use anyhow::{anyhow, Context, Result};
use sqlx::{PgPool, Row};

fn native_to_usd(amount_native: f64, micro_per_usd: i64) -> f64 {
    if amount_native <= 0.0 || micro_per_usd <= 0 {
        return 0.0;
    }
    amount_native * 1_000_000.0 / micro_per_usd as f64
}

async fn latest_fx_micro(pool: &PgPool, currency: &str) -> Result<i64> {
    let row = sqlx::query(
        "SELECT micro_per_usd FROM ai.billing_fx_rate WHERE currency = $1 ORDER BY effective_from DESC LIMIT 1",
    )
    .bind(currency)
    .fetch_optional(pool)
    .await
    .context("billing_fx_rate lookup")?;
    row.map(|r| r.get::<i64, _>("micro_per_usd"))
        .filter(|m| *m > 0)
        .ok_or_else(|| anyhow!("no fx rate for {}", currency))
}

/// USD passthrough 1:1; IDR via latest `ai.billing_fx_rate.micro_per_usd`.
pub async fn amount_to_usd(pool: &PgPool, amount_native: f64, currency: &str) -> Result<f64> {
    if currency.eq_ignore_ascii_case("USD") {
        return Ok(amount_native);
    }
    if currency.eq_ignore_ascii_case("IDR") {
        let micro = latest_fx_micro(pool, "IDR").await?;
        return Ok(native_to_usd(amount_native, micro));
    }
    Err(anyhow!("unsupported currency: {}", currency))
}
