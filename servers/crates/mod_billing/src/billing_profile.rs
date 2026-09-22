use anyhow::Result;
use c35_store::snowflake_id;
use sqlx::{PgPool, Row};

use crate::billing_cost::billing_cost_wholesale_usd;
use crate::billing_pool::{pool_alien_deduct_idr, pool_deduct_apply, pool_frontier_deduct_idr, PoolSnapshot};

#[derive(Debug, Clone)]
pub struct ProfilePoolRow {
    pub id: i64,
    pub owner_iid: i64,
    pub plan_tier: String,
    pub alien_pool_limit_idr: f64,
    pub alien_pool_used_idr: f64,
    pub frontier_pool_limit_idr: f64,
    pub frontier_pool_used_idr: f64,
}

fn f64_col(row: &sqlx::postgres::PgRow, col: &str) -> f64 {
    row.try_get::<f64, _>(col).unwrap_or(0.0)
}

fn profile_from_row(row: sqlx::postgres::PgRow) -> ProfilePoolRow {
    ProfilePoolRow {
        id: row.get("id"),
        owner_iid: row.get("owner_iid"),
        plan_tier: row.get("plan_tier"),
        alien_pool_limit_idr: f64_col(&row, "alien_pool_limit_idr"),
        alien_pool_used_idr: f64_col(&row, "alien_pool_used_idr"),
        frontier_pool_limit_idr: f64_col(&row, "frontier_pool_limit_idr"),
        frontier_pool_used_idr: f64_col(&row, "frontier_pool_used_idr"),
    }
}

pub fn profile_pool_snapshot(row: &ProfilePoolRow) -> PoolSnapshot {
    PoolSnapshot {
        alien_used_idr: row.alien_pool_used_idr,
        alien_limit_idr: row.alien_pool_limit_idr,
        frontier_used_idr: row.frontier_pool_used_idr,
        frontier_limit_idr: row.frontier_pool_limit_idr,
    }
}

pub fn profile_pool_remaining(row: &ProfilePoolRow) -> (f64, f64) {
    (
        (row.alien_pool_limit_idr - row.alien_pool_used_idr).max(0.0),
        (row.frontier_pool_limit_idr - row.frontier_pool_used_idr).max(0.0),
    )
}

pub fn profile_has_pools(row: &ProfilePoolRow) -> bool {
    row.alien_pool_limit_idr > 0.0 || row.frontier_pool_limit_idr > 0.0
}

pub fn model_uses_alien_pool(model: &str) -> bool {
    let m = model.trim().to_lowercase();
    m.is_empty() || m == "alienai" || m == "auto"
}

pub async fn billing_profile_fetch(pool: &PgPool, owner_iid: i64) -> Result<Option<ProfilePoolRow>> {
    let row = sqlx::query(
        r#"
        SELECT id, owner_iid, plan_tier,
               alien_pool_limit_idr::float8 AS alien_pool_limit_idr,
               alien_pool_used_idr::float8 AS alien_pool_used_idr,
               frontier_pool_limit_idr::float8 AS frontier_pool_limit_idr,
               frontier_pool_used_idr::float8 AS frontier_pool_used_idr
        FROM ai.billing_profile
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(profile_from_row))
}

pub async fn billing_profile_ensure(pool: &PgPool, owner_iid: i64) -> Result<ProfilePoolRow> {
    if let Some(row) = billing_profile_fetch(pool, owner_iid).await? {
        return Ok(row);
    }
    let id = snowflake_id();
    let _ = sqlx::query(
        "INSERT INTO ai.billing_profile (id, owner_iid, plan_tier) VALUES ($1, $2, 'free')",
    )
    .bind(id)
    .bind(owner_iid)
    .execute(pool)
    .await;
    billing_profile_fetch(pool, owner_iid)
        .await?
        .ok_or_else(|| anyhow::anyhow!("billing_profile missing after insert"))
}

pub async fn billing_profile_apply_plan_pools(
    pool: &PgPool,
    owner_iid: i64,
    plan_tier: &str,
    alien_limit_idr: f64,
    frontier_limit_idr: f64,
) -> Result<ProfilePoolRow> {
    let _ = billing_profile_ensure(pool, owner_iid).await?;
    sqlx::query(
        r#"
        UPDATE ai.billing_profile
        SET plan_tier = $2,
            alien_pool_limit_idr = $3,
            alien_pool_used_idr = 0,
            frontier_pool_limit_idr = $4,
            frontier_pool_used_idr = 0,
            pool_period_start = NOW(),
            updated_ts = NOW()
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .bind(plan_tier)
    .bind(alien_limit_idr)
    .bind(frontier_limit_idr)
    .execute(pool)
    .await?;
    billing_profile_fetch(pool, owner_iid)
        .await?
        .ok_or_else(|| anyhow::anyhow!("billing_profile missing after pool apply"))
}

async fn owner_email(pool: &PgPool, owner_iid: i64) -> Option<String> {
    sqlx::query_scalar::<_, Option<String>>(
        r#"
        SELECT COALESCE(NULLIF(TRIM(meta->>'email'), ''), NULL)
        FROM ai.identity
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten()
    .flatten()
    .filter(|e| e.contains('@'))
}

async fn signup_trial_already_claimed(pool: &PgPool, owner_iid: i64) -> Result<bool> {
    let n: i64 = sqlx::query_scalar(
        r#"
        SELECT COUNT(*)::bigint
        FROM ai.billing_promotion_claim c
        JOIN ai.billing_promotion p ON p.id = c.promotion_id
        WHERE c.owner_iid = $1 AND p.type = 'signup_trial'
        "#,
    )
    .bind(owner_iid)
    .fetch_one(pool)
    .await?;
    Ok(n > 0)
}

/// Auto-claim seeded signup trial once per user (requires verified email in identity meta).
pub async fn billing_signup_trial_autoclaim(pool: &PgPool, owner_iid: i64) -> Result<()> {
    if signup_trial_already_claimed(pool, owner_iid).await? {
        return Ok(());
    }
    let profile = billing_profile_ensure(pool, owner_iid).await?;
    if profile_has_pools(&profile) {
        return Ok(());
    }
    let Some(email) = owner_email(pool, owner_iid).await else {
        return Ok(());
    };
    match crate::billing_promotion::billing_promotion_claim(pool, owner_iid, &email, "signup_trial").await {
        Ok(_) => Ok(()),
        Err(e) if e.contains("already claimed") || e.contains("email already claimed") => Ok(()),
        Err(e) => Err(anyhow::anyhow!(e)),
    }
}

pub fn normalize_billing_period(raw: &str) -> &'static str {
    if raw.trim().eq_ignore_ascii_case("yearly") {
        "yearly"
    } else {
        "monthly"
    }
}

/// Deduct one LLM turn from profile IDR pools. Returns wallet overflow IDR when pools exhausted.
pub async fn billing_profile_deduct_turn(
    pool: &PgPool,
    owner_iid: i64,
    model: &str,
    tokens_in: i32,
    tokens_out: i32,
    fx_micro: i64,
) -> Result<Option<f64>> {
    let use_alien = model_uses_alien_pool(model);
    let charge_idr = if use_alien {
        pool_alien_deduct_idr(tokens_in, tokens_out, fx_micro)
    } else {
        pool_frontier_deduct_idr(billing_cost_wholesale_usd(model, tokens_in, tokens_out), fx_micro)
    };
    if charge_idr <= 0.0 {
        return Ok(None);
    }

    let mut tx = pool.begin().await?;
    let row = sqlx::query(
        r#"
        SELECT id, owner_iid, plan_tier,
               alien_pool_limit_idr::float8 AS alien_pool_limit_idr,
               alien_pool_used_idr::float8 AS alien_pool_used_idr,
               frontier_pool_limit_idr::float8 AS frontier_pool_limit_idr,
               frontier_pool_used_idr::float8 AS frontier_pool_used_idr
        FROM ai.billing_profile
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        LIMIT 1
        FOR UPDATE
        "#,
    )
    .bind(owner_iid)
    .fetch_optional(&mut *tx)
    .await?;
    let Some(row) = row else {
        return Ok(None);
    };
    let profile = profile_from_row(row);
    if !profile_has_pools(&profile) {
        return Ok(None);
    }
    let applied = pool_deduct_apply(&profile_pool_snapshot(&profile), charge_idr, use_alien);
    sqlx::query(
        r#"
        UPDATE ai.billing_profile
        SET alien_pool_used_idr = $2,
            frontier_pool_used_idr = $3,
            updated_ts = NOW()
        WHERE id = $1
        "#,
    )
    .bind(profile.id)
    .bind(applied.alien_used_idr)
    .bind(applied.frontier_used_idr)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    Ok(Some(applied.wallet_overflow_idr))
}

pub async fn billing_plan_pool_template(
    pool: &PgPool,
    plan_slug: &str,
) -> Result<(f64, f64, String), String> {
    let row = sqlx::query(
        r#"
        SELECT alien_pool_idr_monthly::float8 AS alien_pool,
               frontier_pool_idr_monthly::float8 AS frontier_pool,
               COALESCE(tier, slug) AS tier
        FROM ai.billing_plan
        WHERE slug = $1 AND is_active = TRUE
        LIMIT 1
        "#,
    )
    .bind(plan_slug)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    let Some(row) = row else {
        return Err("plan not found".into());
    };
    Ok((f64_col(&row, "alien_pool"), f64_col(&row, "frontier_pool"), row.get("tier")))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn alien_pool_models() {
        assert!(model_uses_alien_pool("alienai"));
        assert!(model_uses_alien_pool("auto"));
        assert!(model_uses_alien_pool(""));
        assert!(!model_uses_alien_pool("gpt-4"));
    }

    #[test]
    fn billing_period_defaults_monthly() {
        assert_eq!(normalize_billing_period(""), "monthly");
        assert_eq!(normalize_billing_period("yearly"), "yearly");
    }

    #[test]
    fn signup_trial_constants_match_lite_quarter() {
        use crate::billing_pool::{SIGNUP_TRIAL_ALIEN_IDR, SIGNUP_TRIAL_FRONTIER_IDR};
        assert_eq!(SIGNUP_TRIAL_ALIEN_IDR, 25_000.0);
        assert_eq!(SIGNUP_TRIAL_FRONTIER_IDR, 5_000.0);
    }
}
