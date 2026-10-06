use anyhow::{anyhow, Result};
use c35_proto::{BillingEntitlementDoc, ResBillingEntitlementList};
use c35_store::snowflake_id;
use chrono::{DateTime, Utc};
use sqlx::{PgPool, Row};

use crate::billing_plan_change::tier_rank;
use crate::billing_profile::{billing_plan_pool_template, billing_profile_ensure};

pub struct EntitlementGrantSpec {
    pub owner_iid: i64,
    pub source: String,
    pub referral_code: Option<String>,
    pub purchase_id: Option<i64>,
    pub plan_slug: String,
    pub duration_months: i32,
    pub credit_idr: f64,
    pub highlight: bool,
    pub expires_ts: Option<DateTime<Utc>>,
    pub alien_pool_override: Option<f64>,
    pub frontier_pool_override: Option<f64>,
}

pub async fn billing_entitlement_grant(pool: &PgPool, spec: EntitlementGrantSpec) -> Result<i64> {
    let months = spec.duration_months.max(1);
    let expires = spec.expires_ts.unwrap_or_else(|| {
        Utc::now() + chrono::Duration::days(30 * months as i64)
    });
    let (alien_pool, frontier_pool, tier) = if let (Some(a), Some(f)) = (spec.alien_pool_override, spec.frontier_pool_override) {
        (a, f, spec.plan_slug.trim().to_string())
    } else if spec.plan_slug.trim().is_empty() {
        (0.0, 0.0, String::new())
    } else {
        let (a, f, t) = billing_plan_pool_template(pool, spec.plan_slug.trim())
            .await
            .map_err(|e| anyhow!(e))?;
        (a, f, t)
    };
    let (alien_5h, alien_week) = if spec.plan_slug.trim().is_empty() {
        (0.0, 0.0)
    } else {
        plan_allowance_limits(pool, spec.plan_slug.trim()).await?
    };
    let id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.billing_entitlement (
            id, owner_iid, source, referral_code, purchase_id, plan_slug,
            duration_months, credit_idr,
            alien_pool_limit_idr, frontier_pool_limit_idr,
            alien_allow_5h_limit, alien_allow_weekly_limit,
            expires_ts, meta
        ) VALUES (
            $1, $2, $3, $4, $5, $6,
            $7, $8,
            $9, $10,
            $11, $12,
            $13, $14::jsonb
        )
        "#,
    )
    .bind(id)
    .bind(spec.owner_iid)
    .bind(&spec.source)
    .bind(spec.referral_code.as_deref())
    .bind(spec.purchase_id)
    .bind(spec.plan_slug.trim())
    .bind(months)
    .bind(spec.credit_idr)
    .bind(alien_pool)
    .bind(frontier_pool)
    .bind(alien_5h)
    .bind(alien_week)
    .bind(expires)
    .bind(serde_json::json!({ "highlight": spec.highlight, "tier": tier }))
    .execute(pool)
    .await?;
    if spec.credit_idr > 0.0 {
        credit_wallet_idr(pool, spec.owner_iid, spec.credit_idr).await?;
    }
    billing_entitlement_recompute(pool, spec.owner_iid).await?;
    Ok(id)
}

async fn plan_allowance_limits(pool: &PgPool, slug: &str) -> Result<(f64, f64)> {
    let row = sqlx::query(
        r#"
        SELECT alien_allow_5h_usd::float8 AS alien_5h,
               alien_allow_weekly_usd::float8 AS alien_week
        FROM ai.billing_plan
        WHERE slug = $1 AND scope = 'user' AND is_active = TRUE
        "#,
    )
    .bind(slug)
    .fetch_optional(pool)
    .await?;
    Ok(match row {
        Some(r) => (r.get("alien_5h"), r.get("alien_week")),
        None => (0.0, 0.0),
    })
}

async fn credit_wallet_idr(pool: &PgPool, owner_iid: i64, amount_idr: f64) -> Result<()> {
    let _ = crate::billing_account_ensure(pool, owner_iid).await?;
    sqlx::query(
        r#"
        UPDATE ai.billing_account
        SET balance_idr = balance_idr + $2, updated_ts = NOW()
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .bind(amount_idr)
    .execute(pool)
    .await?;

    let wallet_id = snowflake_id();
    let _ = sqlx::query(
        r#"
        INSERT INTO ai.billing_wallet (id, owner_iid, currency, balance, is_default, name)
        VALUES ($1, $2, 'IDR', $3, TRUE, 'Personal IDR')
        ON CONFLICT (owner_iid, currency) WHERE deleted_ts IS NULL
        DO UPDATE SET balance = ai.billing_wallet.balance + EXCLUDED.balance, updated_ts = NOW()
        "#,
    )
    .bind(wallet_id)
    .bind(owner_iid)
    .bind(amount_idr)
    .execute(pool)
    .await;

    Ok(())
}

pub async fn billing_entitlement_recompute(pool: &PgPool, owner_iid: i64) -> Result<()> {
    let _ = billing_profile_ensure(pool, owner_iid).await?;
    let rows = sqlx::query(
        r#"
        SELECT plan_slug, credit_idr::float8 AS credit_idr,
               alien_pool_limit_idr::float8 AS alien_pool,
               frontier_pool_limit_idr::float8 AS frontier_pool,
               alien_allow_5h_limit::float8 AS alien_5h,
               alien_allow_weekly_limit::float8 AS alien_week,
               expires_ts
        FROM ai.billing_entitlement
        WHERE owner_iid = $1 AND revoked_ts IS NULL AND expires_ts > NOW()
        "#,
    )
    .bind(owner_iid)
    .fetch_all(pool)
    .await?;

    let mut alien_pool = 0.0;
    let mut frontier_pool = 0.0;
    let mut alien_5h = 0.0;
    let mut alien_week = 0.0;
    let mut max_tier = String::from("free");
    let mut max_rank = 0;
    let mut max_expires: Option<DateTime<Utc>> = None;

    for r in &rows {
        alien_pool += r.get::<f64, _>("alien_pool");
        frontier_pool += r.get::<f64, _>("frontier_pool");
        alien_5h += r.get::<f64, _>("alien_5h");
        alien_week += r.get::<f64, _>("alien_week");
        let slug: String = r.get("plan_slug");
        let rank = tier_rank(&slug);
        if rank > max_rank {
            max_rank = rank;
            max_tier = slug;
        }
        let exp: DateTime<Utc> = r.get("expires_ts");
        max_expires = Some(max_expires.map(|m| m.max(exp)).unwrap_or(exp));
    }

    sqlx::query(
        r#"
        UPDATE ai.billing_profile
        SET plan_tier = $2,
            alien_pool_limit_idr = $3,
            frontier_pool_limit_idr = $4,
            plan_expires_ts = $5,
            updated_ts = NOW()
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .bind(if max_rank > 0 { max_tier.clone() } else { "free".into() })
    .bind(alien_pool)
    .bind(frontier_pool)
    .bind(max_expires)
    .execute(pool)
    .await?;

    sqlx::query(
        r#"
        UPDATE ai.billing_account
        SET plan_tier = $2,
            alien_allow_5h_limit = $3,
            alien_allow_weekly_limit = $4,
            updated_ts = NOW()
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .bind(if max_rank > 0 { max_tier } else { "free".into() })
    .bind(alien_5h)
    .bind(alien_week)
    .execute(pool)
    .await?;

    Ok(())
}

pub async fn billing_entitlement_list(
    pool: &PgPool,
    owner_iid: i64,
) -> Result<ResBillingEntitlementList, String> {
    let rows = sqlx::query(
        r#"
        SELECT e.id, e.plan_slug, e.credit_idr::float8 AS credit_idr,
               e.expires_ts, e.created_ts, e.source, e.referral_code,
               COALESCE(e.meta, '{}'::jsonb) AS meta,
               COALESCE(p.name, '') AS plan_name
        FROM ai.billing_entitlement e
        LEFT JOIN ai.billing_plan p ON p.slug = e.plan_slug
        WHERE e.owner_iid = $1 AND e.revoked_ts IS NULL AND e.expires_ts > NOW()
        ORDER BY e.expires_ts ASC, e.created_ts DESC
        "#,
    )
    .bind(owner_iid)
    .fetch_all(pool)
    .await
    .map_err(|e| e.to_string())?;

    let items = rows
        .into_iter()
        .map(|r| {
            let meta: serde_json::Value = r.get("meta");
            let highlight = meta.get("highlight").and_then(|v| v.as_bool()).unwrap_or(false);
            let plan_slug: String = r.get("plan_slug");
            let plan_name: String = r.get("plan_name");
            let credit: f64 = r.get("credit_idr");
            let name = if !plan_name.is_empty() {
                plan_name
            } else if credit > 0.0 {
                format!("Credit Rp {}", credit.round())
            } else {
                plan_slug.clone()
            };
            BillingEntitlementDoc {
                id: r.get("id"),
                plan_slug,
                plan_name: name,
                expires_ts_ms: r.get::<DateTime<Utc>, _>("expires_ts").timestamp_millis(),
                purchased_ts_ms: r.get::<DateTime<Utc>, _>("created_ts").timestamp_millis(),
                source: r.get("source"),
                referral_code: r.get::<Option<String>, _>("referral_code").unwrap_or_default(),
                credit_idr: credit,
                highlight,
            }
        })
        .collect();
    Ok(ResBillingEntitlementList { items })
}
