use anyhow::{Context, Result};
use chrono::{DateTime, NaiveDate, Utc};
use sqlx::{PgPool, QueryBuilder, Row};

#[derive(Debug, Clone, PartialEq)]
pub struct PlatformPnl {
    pub revenue_usd: f64,
    pub ai_cogs_usd: f64,
    pub infra_cogs_usd: f64,
    pub gross_profit_usd: f64,
    pub ai_api_vendor_usd: f64,
    pub ai_cogs_drift_pct: f64,
}

#[derive(Debug, Clone, PartialEq)]
pub struct VendorCostBreakdown {
    pub vendor: String,
    pub amount_usd: f64,
}

/// Percent drift of vendor AI API spend vs wholesale AI COGS (0 when both zero).
pub fn pnl_ai_cogs_drift_pct(ai_cogs_usd: f64, ai_api_vendor_usd: f64) -> f64 {
    if ai_cogs_usd <= 0.0 && ai_api_vendor_usd <= 0.0 {
        return 0.0;
    }
    let base = if ai_cogs_usd > 0.0 {
        ai_cogs_usd
    } else {
        ai_api_vendor_usd
    };
    ((ai_api_vendor_usd - ai_cogs_usd).abs() / base) * 100.0
}

pub async fn platform_pnl_query(
    pool: &PgPool,
    since_ms: i64,
    until_ms: i64,
) -> Result<(PlatformPnl, Vec<VendorCostBreakdown>)> {
    let since_ts = ts_bound(since_ms);
    let until_ts = ts_bound(until_ms);
    let since_date = date_bound(since_ms);
    let until_date = date_bound(until_ms);

    let topup_usd = revenue_topup_usd(pool, since_ts, until_ts).await?;
    let purchase_usd = revenue_purchase_usd(pool, since_ts, until_ts).await?;
    let (usage_retail_usd, ai_cogs_usd) = usage_totals(pool, since_ts, until_ts).await?;
    let (infra_cogs_usd, ai_api_vendor_usd) =
        vendor_cost_totals(pool, since_date, until_date).await?;
    let vendor_rows = vendor_breakdown(pool, since_date, until_date).await?;

    let revenue_usd = topup_usd + purchase_usd + usage_retail_usd;
    let gross_profit_usd = revenue_usd - ai_cogs_usd - infra_cogs_usd;
    let ai_cogs_drift_pct = pnl_ai_cogs_drift_pct(ai_cogs_usd, ai_api_vendor_usd);

    Ok((
        PlatformPnl {
            revenue_usd,
            ai_cogs_usd,
            infra_cogs_usd,
            gross_profit_usd,
            ai_api_vendor_usd,
            ai_cogs_drift_pct,
        },
        vendor_rows,
    ))
}

fn ts_bound(ms: i64) -> Option<DateTime<Utc>> {
    if ms <= 0 {
        None
    } else {
        DateTime::from_timestamp_millis(ms)
    }
}

fn date_bound(ms: i64) -> Option<NaiveDate> {
    ts_bound(ms).map(|ts| ts.date_naive())
}

async fn revenue_topup_usd(
    pool: &PgPool,
    since_ts: Option<DateTime<Utc>>,
    until_ts: Option<DateTime<Utc>>,
) -> Result<f64> {
    let mut qb = QueryBuilder::new(
        "SELECT COALESCE(SUM(amount_usd::float8), 0) AS usd FROM ai.billing_topup_request WHERE status = 'settled' AND deleted_ts IS NULL",
    );
    push_ts_filters(&mut qb, "settled_ts", since_ts, until_ts);
    let row = qb.build().fetch_one(pool).await.context("topup revenue")?;
    Ok(row.get::<f64, _>("usd"))
}

async fn revenue_purchase_usd(
    pool: &PgPool,
    since_ts: Option<DateTime<Utc>>,
    until_ts: Option<DateTime<Utc>>,
) -> Result<f64> {
    let mut qb = QueryBuilder::new(
        r#"
        SELECT COALESCE(SUM(
            CASE
                WHEN p.currency = 'USD' THEN p.amount::float8
                WHEN p.currency = 'IDR' THEN
                    p.amount::float8 * 1000000.0 / COALESCE(fx.micro_per_usd, 0)
                ELSE 0
            END
        ), 0) AS usd
        FROM ai.billing_purchase p
        LEFT JOIN LATERAL (
            SELECT micro_per_usd FROM ai.billing_fx_rate
            WHERE currency = 'IDR'
            ORDER BY effective_from DESC
            LIMIT 1
        ) fx ON p.currency = 'IDR'
        WHERE p.status = 'settled'
        "#,
    );
    push_ts_filters(&mut qb, "p.settled_ts", since_ts, until_ts);
    let row = qb.build().fetch_one(pool).await.context("purchase revenue")?;
    Ok(row.get::<f64, _>("usd"))
}

async fn usage_totals(
    pool: &PgPool,
    since_ts: Option<DateTime<Utc>>,
    until_ts: Option<DateTime<Utc>>,
) -> Result<(f64, f64)> {
    let mut qb = QueryBuilder::new(
        r#"
        SELECT
            COALESCE(SUM(cost_usd::float8), 0) AS retail,
            COALESCE(SUM(cost_wholesale_usd::float8), 0) AS wholesale
        FROM ai.billing_usage_dedupe
        WHERE 1=1
        "#,
    );
    push_ts_filters(&mut qb, "created_ts", since_ts, until_ts);
    let row = qb.build().fetch_one(pool).await.context("usage totals")?;
    Ok((row.get("retail"), row.get("wholesale")))
}

async fn vendor_cost_totals(
    pool: &PgPool,
    since_date: Option<NaiveDate>,
    until_date: Option<NaiveDate>,
) -> Result<(f64, f64)> {
    let mut qb = QueryBuilder::new(
        r#"
        SELECT
            COALESCE(SUM(CASE WHEN category <> 'ai_api' THEN amount_usd::float8 ELSE 0 END), 0) AS infra,
            COALESCE(SUM(CASE WHEN category = 'ai_api' THEN amount_usd::float8 ELSE 0 END), 0) AS ai_api
        FROM ai.platform_vendor_cost
        WHERE deleted_ts IS NULL
        "#,
    );
    push_period_filters(&mut qb, since_date, until_date);
    let row = qb.build().fetch_one(pool).await.context("vendor cost totals")?;
    Ok((row.get("infra"), row.get("ai_api")))
}

async fn vendor_breakdown(
    pool: &PgPool,
    since_date: Option<NaiveDate>,
    until_date: Option<NaiveDate>,
) -> Result<Vec<VendorCostBreakdown>> {
    let mut qb = QueryBuilder::new(
        r#"
        SELECT vendor, COALESCE(SUM(amount_usd::float8), 0) AS usd
        FROM ai.platform_vendor_cost
        WHERE deleted_ts IS NULL
        "#,
    );
    push_period_filters(&mut qb, since_date, until_date);
    qb.push(" GROUP BY vendor ORDER BY usd DESC");
    let rows = qb.build().fetch_all(pool).await.context("vendor breakdown")?;
    Ok(rows
        .into_iter()
        .map(|r| VendorCostBreakdown {
            vendor: r.get("vendor"),
            amount_usd: r.get("usd"),
        })
        .collect())
}

fn push_ts_filters(
    qb: &mut QueryBuilder<'_, sqlx::Postgres>,
    col: &str,
    since_ts: Option<DateTime<Utc>>,
    until_ts: Option<DateTime<Utc>>,
) {
    if let Some(since) = since_ts {
        qb.push(format!(" AND {} >= ", col));
        qb.push_bind(since);
    }
    if let Some(until) = until_ts {
        qb.push(format!(" AND {} <= ", col));
        qb.push_bind(until);
    }
}

#[cfg(test)]
mod tests {
    use super::pnl_ai_cogs_drift_pct;

    #[test]
    fn drift_zero_when_both_zero() {
        assert_eq!(pnl_ai_cogs_drift_pct(0.0, 0.0), 0.0);
    }

    #[test]
    fn drift_five_percent_against_wholesale() {
        assert!((pnl_ai_cogs_drift_pct(100.0, 105.0) - 5.0).abs() < 0.001);
    }
}

fn push_period_filters(
    qb: &mut QueryBuilder<'_, sqlx::Postgres>,
    since_date: Option<NaiveDate>,
    until_date: Option<NaiveDate>,
) {
    if let Some(since) = since_date {
        qb.push(" AND period_end >= ");
        qb.push_bind(since);
    }
    if let Some(until) = until_date {
        qb.push(" AND period_start <= ");
        qb.push_bind(until);
    }
}
