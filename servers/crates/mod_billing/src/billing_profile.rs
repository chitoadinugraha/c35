use anyhow::Result;
use chrono::{Duration, Utc};
use c35_store::snowflake_id;
use sqlx::{PgPool, Row};

use crate::billing_cost::billing_cost_usd;
use crate::billing_on_demand::allowance_remaining;
use crate::billing_pool::{LITE_ALIEN_POOL_IDR, LITE_FRONTIER_POOL_IDR};

#[derive(Debug, Clone)]
pub struct ProfileRingRow {
    pub alien_allow_5h_used: f64,
    pub alien_allow_5h_limit: f64,
    pub alien_allow_weekly_used: f64,
    pub alien_allow_weekly_limit: f64,
    pub frontier_allow_5h_used: f64,
    pub frontier_allow_5h_limit: f64,
    pub frontier_allow_weekly_used: f64,
    pub frontier_allow_weekly_limit: f64,
    pub window_5h_start: chrono::DateTime<Utc>,
    pub window_weekly_start: chrono::DateTime<Utc>,
}

#[derive(Debug, Clone)]
pub struct ProfilePoolRow {
    pub id: i64,
    pub owner_iid: i64,
    pub plan_tier: String,
    pub alien_pool_limit_idr: f64,
    pub alien_pool_used_idr: f64,
    pub frontier_pool_limit_idr: f64,
    pub frontier_pool_used_idr: f64,
    pub rings: ProfileRingRow,
}

fn f64_col(row: &sqlx::postgres::PgRow, col: &str) -> f64 {
    row.try_get::<f64, _>(col).unwrap_or(0.0)
}

fn rings_from_row(row: &sqlx::postgres::PgRow) -> ProfileRingRow {
    ProfileRingRow {
        alien_allow_5h_used: f64_col(row, "alien_allow_5h_used"),
        alien_allow_5h_limit: f64_col(row, "alien_allow_5h_limit"),
        alien_allow_weekly_used: f64_col(row, "alien_allow_weekly_used"),
        alien_allow_weekly_limit: f64_col(row, "alien_allow_weekly_limit"),
        frontier_allow_5h_used: f64_col(row, "frontier_allow_5h_used"),
        frontier_allow_5h_limit: f64_col(row, "frontier_allow_5h_limit"),
        frontier_allow_weekly_used: f64_col(row, "frontier_allow_weekly_used"),
        frontier_allow_weekly_limit: f64_col(row, "frontier_allow_weekly_limit"),
        window_5h_start: row.get("window_5h_start"),
        window_weekly_start: row.get("window_weekly_start"),
    }
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
        rings: rings_from_row(&row),
    }
}

const PROFILE_RING_SELECT: &str = r#"
        id, owner_iid, plan_tier,
        alien_pool_limit_idr::float8 AS alien_pool_limit_idr,
        alien_pool_used_idr::float8 AS alien_pool_used_idr,
        frontier_pool_limit_idr::float8 AS frontier_pool_limit_idr,
        frontier_pool_used_idr::float8 AS frontier_pool_used_idr,
        alien_allow_5h_used::float8 AS alien_allow_5h_used,
        alien_allow_5h_limit::float8 AS alien_allow_5h_limit,
        alien_allow_weekly_used::float8 AS alien_allow_weekly_used,
        alien_allow_weekly_limit::float8 AS alien_allow_weekly_limit,
        frontier_allow_5h_used::float8 AS frontier_allow_5h_used,
        frontier_allow_5h_limit::float8 AS frontier_allow_5h_limit,
        frontier_allow_weekly_used::float8 AS frontier_allow_weekly_used,
        frontier_allow_weekly_limit::float8 AS frontier_allow_weekly_limit,
        window_5h_start, window_weekly_start
"#;

pub fn profile_pool_remaining(row: &ProfilePoolRow) -> (f64, f64) {
    (
        (row.alien_pool_limit_idr - row.alien_pool_used_idr).max(0.0),
        (row.frontier_pool_limit_idr - row.frontier_pool_used_idr).max(0.0),
    )
}

pub fn profile_has_pools(row: &ProfilePoolRow) -> bool {
    row.alien_pool_limit_idr > 0.0 || row.frontier_pool_limit_idr > 0.0
}

pub fn profile_has_rings(row: &ProfilePoolRow) -> bool {
    let r = &row.rings;
    r.alien_allow_5h_limit > 0.0
        || r.alien_allow_weekly_limit > 0.0
        || r.frontier_allow_5h_limit > 0.0
        || r.frontier_allow_weekly_limit > 0.0
}

pub fn profile_needs_frontier_ring_repair(row: &ProfilePoolRow) -> bool {
    let tier = row.plan_tier.trim().to_lowercase();
    if tier.is_empty() || tier == "free" {
        return false;
    }
    let r = &row.rings;
    let alien_on = r.alien_allow_5h_limit > 0.0 || r.alien_allow_weekly_limit > 0.0;
    let frontier_off = r.frontier_allow_5h_limit <= 0.0 && r.frontier_allow_weekly_limit <= 0.0;
    alien_on && frontier_off
}

pub fn profile_needs_pool_retire(row: &ProfilePoolRow) -> bool {
    profile_has_pools(row) && profile_has_rings(row)
}

pub fn frontier_limits_derive_from_profile(
    row: &ProfilePoolRow,
    tpl_alien_pool_idr: f64,
    tpl_frontier_pool_idr: f64,
) -> (f64, f64) {
    let alien_pool = if row.alien_pool_limit_idr > 0.0 {
        row.alien_pool_limit_idr
    } else {
        tpl_alien_pool_idr
    };
    let frontier_pool = if row.frontier_pool_limit_idr > 0.0 {
        row.frontier_pool_limit_idr
    } else {
        tpl_frontier_pool_idr
    };
    frontier_rings_from_alien(
        row.rings.alien_allow_5h_limit,
        row.rings.alien_allow_weekly_limit,
        alien_pool,
        frontier_pool,
    )
}

/// Backfill missing frontier 5h/7d caps from plan template; clear legacy monthly pools when rings are active.
pub async fn billing_profile_repair_rings_v4(pool: &PgPool, owner_iid: i64) -> Result<Option<ProfilePoolRow>> {
    let Some(row) = billing_profile_fetch_inner(pool, owner_iid).await? else {
        return Ok(None);
    };
    let repair_frontier = profile_needs_frontier_ring_repair(&row);
    let retire_pools = profile_needs_pool_retire(&row);
    if !repair_frontier && !retire_pools {
        return Ok(Some(row));
    }
    let (frontier_5h, frontier_week) = if repair_frontier {
        let (tpl_alien, tpl_frontier, _) = billing_plan_pool_template(pool, row.plan_tier.trim())
            .await
            .map_err(|e| anyhow::anyhow!(e))?;
        frontier_limits_derive_from_profile(&row, tpl_alien, tpl_frontier)
    } else {
        (row.rings.frontier_allow_5h_limit, row.rings.frontier_allow_weekly_limit)
    };
    sqlx::query(
        r#"
        UPDATE ai.billing_profile
        SET frontier_allow_5h_limit = CASE WHEN $2 THEN $3 ELSE frontier_allow_5h_limit END,
            frontier_allow_weekly_limit = CASE WHEN $2 THEN $4 ELSE frontier_allow_weekly_limit END,
            alien_pool_limit_idr = CASE WHEN $5 THEN 0 ELSE alien_pool_limit_idr END,
            alien_pool_used_idr = CASE WHEN $5 THEN 0 ELSE alien_pool_used_idr END,
            frontier_pool_limit_idr = CASE WHEN $5 THEN 0 ELSE frontier_pool_limit_idr END,
            frontier_pool_used_idr = CASE WHEN $5 THEN 0 ELSE frontier_pool_used_idr END,
            updated_ts = NOW()
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .bind(repair_frontier)
    .bind(frontier_5h)
    .bind(frontier_week)
    .bind(retire_pools)
    .execute(pool)
    .await?;
    billing_profile_fetch_inner(pool, owner_iid).await
}

async fn billing_profile_fetch_inner(pool: &PgPool, owner_iid: i64) -> Result<Option<ProfilePoolRow>> {
    let row = sqlx::query(&format!(
        "SELECT {PROFILE_RING_SELECT} FROM ai.billing_profile WHERE owner_iid = $1 AND deleted_ts IS NULL LIMIT 1"
    ))
    .bind(owner_iid)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(profile_from_row))
}

pub fn profile_ring_remaining_usd(rings: &ProfileRingRow) -> (f64, f64) {
    let alien = allowance_remaining(
        rings.alien_allow_5h_used,
        rings.alien_allow_5h_limit,
        rings.alien_allow_weekly_used,
        rings.alien_allow_weekly_limit,
    );
    let frontier = allowance_remaining(
        rings.frontier_allow_5h_used,
        rings.frontier_allow_5h_limit,
        rings.frontier_allow_weekly_used,
        rings.frontier_allow_weekly_limit,
    );
    (alien, frontier)
}

pub fn frontier_rings_from_alien(
    alien_5h: f64,
    alien_week: f64,
    alien_pool_idr: f64,
    frontier_pool_idr: f64,
) -> (f64, f64) {
    if alien_pool_idr > 0.0 && frontier_pool_idr > 0.0 {
        let ratio = frontier_pool_idr / alien_pool_idr;
        return (alien_5h * ratio, alien_week * ratio);
    }
    (0.0, 0.0)
}

/// Signup trial ring caps: 0.25× lite USD rings with frontier scaled like monthly pools.
pub fn signup_trial_ring_caps() -> (f64, f64, f64, f64) {
    const MULT: f64 = 0.25;
    const LITE_ALIEN_5H: f64 = 0.05;
    const LITE_ALIEN_WEEK: f64 = 1.00;
    let alien_5h = LITE_ALIEN_5H * MULT;
    let alien_week = LITE_ALIEN_WEEK * MULT;
    let (frontier_5h, frontier_week) =
        frontier_rings_from_alien(alien_5h, alien_week, LITE_ALIEN_POOL_IDR, LITE_FRONTIER_POOL_IDR);
    (alien_5h, alien_week, frontier_5h, frontier_week)
}

pub fn model_uses_alien_pool(model: &str) -> bool {
    let m = model.trim().to_lowercase();
    m.is_empty() || m == "alienai" || m == "auto"
}

pub async fn billing_profile_fetch(pool: &PgPool, owner_iid: i64) -> Result<Option<ProfilePoolRow>> {
    if let Ok(Some(row)) = billing_profile_repair_rings_v4(pool, owner_iid).await {
        return Ok(Some(row));
    }
    billing_profile_fetch_inner(pool, owner_iid).await
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

pub async fn billing_profile_windows_roll(pool: &PgPool, mut row: ProfilePoolRow) -> Result<ProfilePoolRow> {
    let now = Utc::now();
    let roll_5h = now - row.rings.window_5h_start >= Duration::hours(5);
    let roll_weekly = now - row.rings.window_weekly_start >= Duration::days(7);
    if !roll_5h && !roll_weekly {
        return Ok(row);
    }
    let mut sql = "UPDATE ai.billing_profile SET updated_ts = NOW()".to_string();
    let r = &mut row.rings;
    if roll_5h {
        sql.push_str(", alien_allow_5h_used = 0, frontier_allow_5h_used = 0, window_5h_start = NOW()");
        r.alien_allow_5h_used = 0.0;
        r.frontier_allow_5h_used = 0.0;
        r.window_5h_start = now;
    }
    if roll_weekly {
        sql.push_str(", alien_allow_weekly_used = 0, frontier_allow_weekly_used = 0, window_weekly_start = NOW()");
        r.alien_allow_weekly_used = 0.0;
        r.frontier_allow_weekly_used = 0.0;
        r.window_weekly_start = now;
    }
    sql.push_str(" WHERE id = $1");
    sqlx::query(&sql).bind(row.id).execute(pool).await?;
    Ok(row)
}

pub async fn billing_profile_apply_plan_rings(
    pool: &PgPool,
    owner_iid: i64,
    alien_5h: f64,
    alien_week: f64,
    frontier_5h: f64,
    frontier_week: f64,
    tier: &str,
) -> Result<ProfilePoolRow> {
    let _ = billing_profile_ensure(pool, owner_iid).await?;
    sqlx::query(
        r#"
        UPDATE ai.billing_profile
        SET plan_tier = $2,
            alien_allow_5h_limit = $3,
            alien_allow_weekly_limit = $4,
            frontier_allow_5h_limit = $5,
            frontier_allow_weekly_limit = $6,
            alien_allow_5h_used = 0,
            alien_allow_weekly_used = 0,
            frontier_allow_5h_used = 0,
            frontier_allow_weekly_used = 0,
            alien_pool_limit_idr = 0,
            alien_pool_used_idr = 0,
            frontier_pool_limit_idr = 0,
            frontier_pool_used_idr = 0,
            window_5h_start = NOW(),
            window_weekly_start = NOW(),
            updated_ts = NOW()
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .bind(tier)
    .bind(alien_5h)
    .bind(alien_week)
    .bind(frontier_5h)
    .bind(frontier_week)
    .execute(pool)
    .await?;
    billing_profile_fetch(pool, owner_iid)
        .await?
        .ok_or_else(|| anyhow::anyhow!("billing_profile missing after ring apply"))
}

pub async fn billing_profile_apply_plan_pools(
    pool: &PgPool,
    owner_iid: i64,
    plan_tier: &str,
    alien_limit_idr: f64,
    frontier_limit_idr: f64,
) -> Result<ProfilePoolRow> {
    let (alien_5h_usd, alien_week_usd) = if alien_limit_idr > 0.0 {
        let ratio = alien_limit_idr / LITE_ALIEN_POOL_IDR;
        (0.05 * ratio, 1.0 * ratio)
    } else {
        (0.0, 0.0)
    };
    let (frontier_5h, frontier_week) = frontier_rings_from_alien(
        alien_5h_usd,
        alien_week_usd,
        alien_limit_idr.max(LITE_ALIEN_POOL_IDR),
        frontier_limit_idr.max(LITE_FRONTIER_POOL_IDR),
    );
    billing_profile_apply_plan_rings(
        pool,
        owner_iid,
        alien_5h_usd,
        alien_week_usd,
        frontier_5h,
        frontier_week,
        plan_tier,
    )
    .await
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
    if profile_has_rings(&profile) {
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

pub fn ring_deduct_pair(
    used_5h: f64,
    limit_5h: f64,
    used_week: f64,
    limit_week: f64,
    cost_usd: f64,
) -> (f64, f64, f64, f64) {
    let rem = allowance_remaining(used_5h, limit_5h, used_week, limit_week);
    let take = cost_usd.min(rem);
    let overflow = cost_usd - take;
    (used_5h + take, used_week + take, take, overflow)
}

/// Same 5h / weekly reset `billing_profile_deduct_rings` applies before it charges a ring.
fn roll_profile_ring_windows(rings: &mut ProfileRingRow, now: chrono::DateTime<Utc>) {
    if now - rings.window_5h_start >= Duration::hours(5) {
        rings.alien_allow_5h_used = 0.0;
        rings.frontier_allow_5h_used = 0.0;
        rings.window_5h_start = now;
    }
    if now - rings.window_weekly_start >= Duration::days(7) {
        rings.alien_allow_weekly_used = 0.0;
        rings.frontier_allow_weekly_used = 0.0;
        rings.window_weekly_start = now;
    }
}

/// Frontier cover after the shared window roll.
/// `None` when `ring_deduct_pair` overflow is positive (frontier remaining cannot pay `cost_usd`).
/// Alien used is not part of the decision. The SQL commit in `billing_frontier_try_deduct`
/// is not integration-tested; this helper is the pure short-vs-enough check.
struct FrontierCover {
    frontier_5h_used: f64,
    frontier_weekly_used: f64,
    window_5h_start: chrono::DateTime<Utc>,
    window_weekly_start: chrono::DateTime<Utc>,
}

fn frontier_cover_after_roll(
    rings: &ProfileRingRow,
    now: chrono::DateTime<Utc>,
    cost_usd: f64,
) -> Option<FrontierCover> {
    let mut rolled = rings.clone();
    roll_profile_ring_windows(&mut rolled, now);
    let (new_5h, new_week) = if cost_usd <= 0.0 {
        (rolled.frontier_allow_5h_used, rolled.frontier_allow_weekly_used)
    } else {
        let (new_5h, new_week, _, overflow) = ring_deduct_pair(
            rolled.frontier_allow_5h_used,
            rolled.frontier_allow_5h_limit,
            rolled.frontier_allow_weekly_used,
            rolled.frontier_allow_weekly_limit,
            cost_usd,
        );
        if overflow > 0.0 {
            return None;
        }
        (new_5h, new_week)
    };
    Some(FrontierCover {
        frontier_5h_used: new_5h,
        frontier_weekly_used: new_week,
        window_5h_start: rolled.window_5h_start,
        window_weekly_start: rolled.window_weekly_start,
    })
}

/// Frontier ring only. Ok(true) when remaining USD >= cost and the deduct committed.
/// Ok(false) when frontier remaining is short. Does not touch alien rings or wallet.
///
/// `cost_usd <= 0` returns `Ok(true)` without a write. Remaining is the frontier half of
/// `profile_ring_remaining_usd` after the same 5h/weekly window roll as
/// `billing_profile_deduct_rings`. Deduct uses `ring_deduct_pair` on the frontier pair only.
/// Overflow rolls the transaction back and returns `Ok(false)` instead of charging the wallet.
///
/// The async SQL path is not integration-tested. `frontier_cover_after_roll` covers the pure
/// decision (short vs enough) without a database.
pub async fn billing_frontier_try_deduct(
    pool: &PgPool,
    owner_iid: i64,
    cost_usd: f64,
) -> Result<bool> {
    if cost_usd <= 0.0 {
        return Ok(true);
    }
    let _ = billing_profile_repair_rings_v4(pool, owner_iid).await;
    let mut tx = pool.begin().await?;
    let row = sqlx::query(&format!(
        "SELECT {PROFILE_RING_SELECT} FROM ai.billing_profile WHERE owner_iid = $1 AND deleted_ts IS NULL LIMIT 1 FOR UPDATE"
    ))
    .bind(owner_iid)
    .fetch_optional(&mut *tx)
    .await?;
    let Some(row) = row else {
        tx.rollback().await?;
        return Ok(false);
    };
    let profile = profile_from_row(row);
    let now = Utc::now();
    let Some(cover) = frontier_cover_after_roll(&profile.rings, now, cost_usd) else {
        tx.rollback().await?;
        return Ok(false);
    };
    // Frontier used and the shared window clock only. alien_allow_* is never written.
    // Wallet is not touched; a short frontier ring rolls this transaction back above.
    sqlx::query(
        r#"
        UPDATE ai.billing_profile
        SET frontier_allow_5h_used = $2,
            frontier_allow_weekly_used = $3,
            window_5h_start = $4,
            window_weekly_start = $5,
            updated_ts = NOW()
        WHERE id = $1
        "#,
    )
    .bind(profile.id)
    .bind(cover.frontier_5h_used)
    .bind(cover.frontier_weekly_used)
    .bind(cover.window_5h_start)
    .bind(cover.window_weekly_start)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    Ok(true)
}

/// Deduct retail `cost_usd` from profile rings. Returns wallet overflow USD (0 when fully covered).
pub async fn billing_profile_deduct_rings(
    pool: &PgPool,
    owner_iid: i64,
    model: &str,
    cost_usd: f64,
) -> Result<Option<f64>> {
    if cost_usd <= 0.0 {
        return Ok(Some(0.0));
    }
    let _ = billing_profile_repair_rings_v4(pool, owner_iid).await;
    let mut tx = pool.begin().await?;
    let row = sqlx::query(&format!(
        "SELECT {PROFILE_RING_SELECT} FROM ai.billing_profile WHERE owner_iid = $1 AND deleted_ts IS NULL LIMIT 1 FOR UPDATE"
    ))
    .bind(owner_iid)
    .fetch_optional(&mut *tx)
    .await?;
    let Some(row) = row else {
        return Ok(None);
    };
    let mut profile = profile_from_row(row);
    if !profile_has_rings(&profile) {
        return Ok(None);
    }
    let now = Utc::now();
    roll_profile_ring_windows(&mut profile.rings, now);
    let use_alien = model_uses_alien_pool(model);
    let r = &mut profile.rings;
    let (new_5h, new_week, _, overflow) = if use_alien {
        ring_deduct_pair(
            r.alien_allow_5h_used,
            r.alien_allow_5h_limit,
            r.alien_allow_weekly_used,
            r.alien_allow_weekly_limit,
            cost_usd,
        )
    } else {
        ring_deduct_pair(
            r.frontier_allow_5h_used,
            r.frontier_allow_5h_limit,
            r.frontier_allow_weekly_used,
            r.frontier_allow_weekly_limit,
            cost_usd,
        )
    };
    if use_alien {
        r.alien_allow_5h_used = new_5h;
        r.alien_allow_weekly_used = new_week;
    } else {
        r.frontier_allow_5h_used = new_5h;
        r.frontier_allow_weekly_used = new_week;
    }
    sqlx::query(
        r#"
        UPDATE ai.billing_profile
        SET alien_allow_5h_used = $2,
            alien_allow_weekly_used = $3,
            frontier_allow_5h_used = $4,
            frontier_allow_weekly_used = $5,
            window_5h_start = $6,
            window_weekly_start = $7,
            updated_ts = NOW()
        WHERE id = $1
        "#,
    )
    .bind(profile.id)
    .bind(r.alien_allow_5h_used)
    .bind(r.alien_allow_weekly_used)
    .bind(r.frontier_allow_5h_used)
    .bind(r.frontier_allow_weekly_used)
    .bind(r.window_5h_start)
    .bind(r.window_weekly_start)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    Ok(Some(overflow.max(0.0)))
}

/// Deduct one LLM turn from profile rings. Returns wallet overflow USD when rings exhausted.
pub async fn billing_profile_deduct_turn(
    pool: &PgPool,
    owner_iid: i64,
    model: &str,
    tokens_in: i32,
    tokens_out: i32,
    fx_micro: i64,
) -> Result<Option<f64>> {
    let cost_usd = billing_cost_usd(model, tokens_in, tokens_out);
    let overflow_usd = billing_profile_deduct_rings(pool, owner_iid, model, cost_usd).await?;
    Ok(overflow_usd.map(|usd| crate::billing_on_demand::usd_to_native(usd, fx_micro)))
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
    fn signup_trial_ring_caps_match_quarter_lite() {
        let (a5, aw, f5, fw) = signup_trial_ring_caps();
        assert!((a5 - 0.0125).abs() < 1e-9);
        assert!((aw - 0.25).abs() < 1e-9);
        assert!((f5 - 0.0025).abs() < 1e-9);
        assert!((fw - 0.05).abs() < 1e-9);
    }

    fn frontier_rings_for(
        used_5h: f64,
        limit_5h: f64,
        used_week: f64,
        limit_week: f64,
        now: chrono::DateTime<Utc>,
        age_5h: Duration,
        age_week: Duration,
    ) -> ProfileRingRow {
        ProfileRingRow {
            alien_allow_5h_used: 0.4,
            alien_allow_5h_limit: 4.0,
            alien_allow_weekly_used: 1.0,
            alien_allow_weekly_limit: 80.0,
            frontier_allow_5h_used: used_5h,
            frontier_allow_5h_limit: limit_5h,
            frontier_allow_weekly_used: used_week,
            frontier_allow_weekly_limit: limit_week,
            window_5h_start: now - age_5h,
            window_weekly_start: now - age_week,
        }
    }

    /// Pure decision only. `billing_frontier_try_deduct`'s SQL commit is not integration-tested.
    #[test]
    fn frontier_try_deduct_short_of_five_cents_not_deducted() {
        let now = Utc::now();
        let rings = frontier_rings_for(0.04, 0.05, 0.0, 1.0, now, Duration::zero(), Duration::zero());
        let (_, frontier_rem) = profile_ring_remaining_usd(&rings);
        assert!(frontier_rem < 0.05);
        assert!(frontier_cover_after_roll(&rings, now, 0.05).is_none());
        assert!((rings.alien_allow_5h_used - 0.4).abs() < 1e-9);
        assert!((rings.alien_allow_weekly_used - 1.0).abs() < 1e-9);
    }

    /// Pure decision only. `billing_frontier_try_deduct`'s SQL commit is not integration-tested.
    #[test]
    fn frontier_try_deduct_with_room_increases_frontier_used_only() {
        let now = Utc::now();
        let rings = frontier_rings_for(0.01, 0.20, 0.10, 1.0, now, Duration::zero(), Duration::zero());
        let (_, frontier_rem) = profile_ring_remaining_usd(&rings);
        assert!(frontier_rem >= 0.05);
        let cover = frontier_cover_after_roll(&rings, now, 0.05).expect("covered");
        assert_eq!(cover.window_5h_start, rings.window_5h_start);
        assert_eq!(cover.window_weekly_start, rings.window_weekly_start);
        assert!((cover.frontier_5h_used - 0.06).abs() < 1e-9);
        assert!((cover.frontier_weekly_used - 0.15).abs() < 1e-9);
        assert!((rings.alien_allow_5h_used - 0.4).abs() < 1e-9);
        assert!((rings.alien_allow_weekly_used - 1.0).abs() < 1e-9);
        assert!((rings.frontier_allow_5h_used - 0.01).abs() < 1e-9);
    }

    /// Expired windows restore frontier room before the 0.05 check. SQL commit is not integration-tested.
    #[test]
    fn frontier_try_deduct_window_roll_restores_five_cents() {
        let now = Utc::now();
        let rings = frontier_rings_for(
            0.05,
            0.05,
            0.05,
            0.05,
            now,
            Duration::hours(6),
            Duration::days(8),
        );
        let (_, before) = profile_ring_remaining_usd(&rings);
        assert!(before < 0.05);
        let cover = frontier_cover_after_roll(&rings, now, 0.05).expect("rolled cover");
        assert!((cover.frontier_5h_used - 0.05).abs() < 1e-9);
        assert!((cover.frontier_weekly_used - 0.05).abs() < 1e-9);
        assert_eq!(cover.window_5h_start, now);
        assert_eq!(cover.window_weekly_start, now);
    }

    #[test]
    fn ring_deduct_respects_both_windows() {
        let (u5, uw, _, ov) = ring_deduct_pair(0.04, 0.05, 0.0, 1.0, 0.02);
        assert!((u5 - 0.05).abs() < 1e-9);
        assert!((uw - 0.01).abs() < 1e-9);
        assert!((ov - 0.01).abs() < 1e-9);
        let (_, _, _, ov2) = ring_deduct_pair(0.04, 0.05, 0.99, 1.0, 0.02);
        assert!((ov2 - 0.01).abs() < 1e-9);
    }

    #[test]
    fn frontier_rings_scale_with_pool_ratio() {
        let (f5, fw) = frontier_rings_from_alien(0.05, 1.0, 100_000.0, 20_000.0);
        assert!((f5 - 0.01).abs() < 1e-9);
        assert!((fw - 0.2).abs() < 1e-9);
    }

    #[test]
    fn ultra_frontier_limits_derive_from_alien_rings() {
        let row = ProfilePoolRow {
            id: 1,
            owner_iid: 99_000,
            plan_tier: "ultra".into(),
            alien_pool_limit_idr: 2_000_000.0,
            alien_pool_used_idr: 0.0,
            frontier_pool_limit_idr: 400_000.0,
            frontier_pool_used_idr: 0.0,
            rings: ProfileRingRow {
                alien_allow_5h_used: 0.0,
                alien_allow_5h_limit: 4.0,
                alien_allow_weekly_used: 0.0,
                alien_allow_weekly_limit: 80.0,
                frontier_allow_5h_used: 0.0,
                frontier_allow_5h_limit: 0.0,
                frontier_allow_weekly_used: 0.0,
                frontier_allow_weekly_limit: 0.0,
                window_5h_start: Utc::now(),
                window_weekly_start: Utc::now(),
            },
        };
        assert!(profile_needs_frontier_ring_repair(&row));
        assert!(profile_needs_pool_retire(&row));
        let (f5, fw) = frontier_limits_derive_from_profile(&row, 2_000_000.0, 400_000.0);
        assert!((f5 - 0.8).abs() < 1e-9);
        assert!((fw - 16.0).abs() < 1e-9);
    }
}
