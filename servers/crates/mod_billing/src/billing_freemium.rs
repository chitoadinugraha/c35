use anyhow::Result;
use chrono::{Duration, NaiveDate, Utc};
use sqlx::PgPool;

pub const FREEMIUM_MSGS_PER_DAY: i32 = 30;
pub const FREEMIUM_TOKENS_PER_DAY: i32 = 30_000;
pub const FREEMIUM_MODEL: &str = "alienai";
/// Assumed input+output tokens when reserving a turn (whichever-limit-first gate).
pub const FREEMIUM_TURN_TOKEN_ESTIMATE: i32 = 4_000;

const PAID_TIERS: &[&str] = &["lite", "plus", "pro", "ultra"];

#[derive(Debug, Clone, Copy, Default)]
pub struct FreemiumSnapshot {
    pub active: bool,
    pub msgs_used: i32,
    pub msgs_limit: i32,
    pub tokens_used: i32,
    pub tokens_limit: i32,
}

pub fn freemium_snapshot_idle() -> FreemiumSnapshot {
    FreemiumSnapshot {
        active: false,
        msgs_used: 0,
        msgs_limit: FREEMIUM_MSGS_PER_DAY,
        tokens_used: 0,
        tokens_limit: FREEMIUM_TOKENS_PER_DAY,
    }
}

pub fn plan_expires_from_period(billing_period: &str) -> chrono::DateTime<Utc> {
    let now = Utc::now();
    if billing_period.eq_ignore_ascii_case("yearly") {
        now + Duration::days(365)
    } else {
        now + Duration::days(30)
    }
}

pub fn plan_expires_from_months(months: i32) -> chrono::DateTime<Utc> {
    let days = (months.max(1) as i64) * 30;
    Utc::now() + Duration::days(days)
}

pub fn tier_is_paid(tier: &str) -> bool {
    let t = tier.trim().to_lowercase();
    PAID_TIERS.contains(&t.as_str())
}

pub fn freemium_tool_blocked(name: &str) -> bool {
    let n = name.trim().to_lowercase();
    matches!(
        n.as_str(),
        "img.generate"
            | "image.generate"
            | "img_generate"
            | "img.edit"
            | "image.edit"
            | "img_edit"
            | "delegate.run"
            | "delegate_run"
            | "subagent.run"
            | "computer_use.delegate"
            | "computer_use_delegate"
            | "delegate_computer_use"
            | "device.command"
            | "device.input"
            | "device.screenshot"
    )
}

pub fn freemium_tool_allowed(name: &str) -> bool {
    !freemium_tool_blocked(name)
}

fn utc_day() -> NaiveDate {
    Utc::now().date_naive()
}

struct FreemiumProfile {
    id: i64,
    plan_tier: String,
    trial_expires_ts: Option<chrono::DateTime<Utc>>,
    freemium_day: Option<NaiveDate>,
    freemium_msgs_used: i32,
    freemium_tokens_used: i32,
}

async fn freemium_profile_fetch(pool: &PgPool, owner_iid: i64) -> Result<Option<FreemiumProfile>> {
    let row = sqlx::query_as::<_, (
        i64,
        String,
        Option<chrono::DateTime<Utc>>,
        Option<NaiveDate>,
        i32,
        i32,
    )>(
        r#"
        SELECT id, plan_tier, trial_expires_ts, freemium_day, freemium_msgs_used, freemium_tokens_used
        FROM ai.billing_profile
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(|(id, plan_tier, trial_expires_ts, freemium_day, freemium_msgs_used, freemium_tokens_used)| {
        FreemiumProfile {
            id,
            plan_tier,
            trial_expires_ts,
            freemium_day,
            freemium_msgs_used,
            freemium_tokens_used,
        }
    }))
}

async fn paid_tier_from_account(pool: &PgPool, owner_iid: i64) -> Result<Option<String>> {
    let tier = sqlx::query_scalar::<_, Option<String>>(
        r#"
        SELECT plan_tier FROM ai.billing_account
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await?;
    Ok(tier.flatten())
}

fn profile_on_active_trial(row: &FreemiumProfile) -> bool {
    row.trial_expires_ts
        .map(|exp| exp > Utc::now())
        .unwrap_or(false)
}

/// Personal users with no paid plan and no active signup trial.
pub async fn billing_freemium_applies(pool: &PgPool, owner_iid: i64) -> Result<bool> {
    let _ = billing_plan_lapse_if_expired(pool, owner_iid).await?;
    if let Some(row) = freemium_profile_fetch(pool, owner_iid).await? {
        if tier_is_paid(&row.plan_tier) {
            return Ok(false);
        }
        if profile_on_active_trial(&row) {
            return Ok(false);
        }
        return Ok(true);
    }
    if let Some(tier) = paid_tier_from_account(pool, owner_iid).await? {
        if tier_is_paid(&tier) {
            return Ok(false);
        }
    }
    Ok(true)
}

/// Downgrade expired paid plan to freemium (`free` tier, pools cleared).
pub async fn billing_plan_lapse_if_expired(pool: &PgPool, owner_iid: i64) -> Result<bool> {
    let row = sqlx::query_as::<_, (i64, String, Option<chrono::DateTime<Utc>>)>(
        r#"
        SELECT id, plan_tier, plan_expires_ts
        FROM ai.billing_profile
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await?;
    let Some((profile_id, tier, expires)) = row else {
        return Ok(false);
    };
    if !tier_is_paid(&tier) {
        return Ok(false);
    }
    let Some(exp) = expires else {
        return Ok(false);
    };
    if exp > Utc::now() {
        return Ok(false);
    }
    let mut tx = pool.begin().await?;
    sqlx::query(
        r#"
        UPDATE ai.billing_profile
        SET plan_tier = 'free',
            alien_pool_limit_idr = 0,
            alien_pool_used_idr = 0,
            frontier_pool_limit_idr = 0,
            frontier_pool_used_idr = 0,
            plan_expires_ts = NULL,
            updated_ts = NOW()
        WHERE id = $1
        "#,
    )
    .bind(profile_id)
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        r#"
        UPDATE ai.billing_account
        SET plan_tier = 'free', updated_ts = NOW()
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    Ok(true)
}

/// Wire snapshot for NATS push (no plan lapse — avoids notify recursion).
pub async fn billing_freemium_wire(pool: &PgPool, owner_iid: i64) -> FreemiumSnapshot {
    if let Ok(row) = freemium_profile_fetch(pool, owner_iid).await {
        if let Some(row) = row {
            if !tier_is_paid(&row.plan_tier) && !profile_on_active_trial(&row) {
                let today = utc_day();
                let (msgs_used, tokens_used) = if row.freemium_day == Some(today) {
                    (row.freemium_msgs_used, row.freemium_tokens_used)
                } else {
                    (0, 0)
                };
                return FreemiumSnapshot {
                    active: true,
                    msgs_used,
                    msgs_limit: FREEMIUM_MSGS_PER_DAY,
                    tokens_used,
                    tokens_limit: FREEMIUM_TOKENS_PER_DAY,
                };
            }
        }
    }
    if let Ok(Some(tier)) = paid_tier_from_account(pool, owner_iid).await {
        if tier_is_paid(&tier) {
            return freemium_snapshot_idle();
        }
    }
    let today = utc_day();
    let (msgs_used, tokens_used) = freemium_profile_fetch(pool, owner_iid)
        .await
        .ok()
        .flatten()
        .map(|row| {
            if row.freemium_day == Some(today) {
                (row.freemium_msgs_used, row.freemium_tokens_used)
            } else {
                (0, 0)
            }
        })
        .unwrap_or((0, 0));
    FreemiumSnapshot {
        active: true,
        msgs_used,
        msgs_limit: FREEMIUM_MSGS_PER_DAY,
        tokens_used,
        tokens_limit: FREEMIUM_TOKENS_PER_DAY,
    }
}

pub async fn billing_freemium_snapshot(pool: &PgPool, owner_iid: i64) -> Result<FreemiumSnapshot> {
    if !billing_freemium_applies(pool, owner_iid).await? {
        return Ok(freemium_snapshot_idle());
    }
    let row = freemium_profile_fetch(pool, owner_iid)
        .await?
        .ok_or_else(|| anyhow::anyhow!("billing_profile missing"))?;
    let today = utc_day();
    let (msgs_used, tokens_used) = if row.freemium_day == Some(today) {
        (row.freemium_msgs_used, row.freemium_tokens_used)
    } else {
        (0, 0)
    };
    Ok(FreemiumSnapshot {
        active: true,
        msgs_used,
        msgs_limit: FREEMIUM_MSGS_PER_DAY,
        tokens_used,
        tokens_limit: FREEMIUM_TOKENS_PER_DAY,
    })
}

fn freemium_rejection(msgs_used: i32, tokens_used: i32) -> String {
    if msgs_used >= FREEMIUM_MSGS_PER_DAY {
        format!(
            "freemium daily limit: {FREEMIUM_MSGS_PER_DAY} messages per day used. Subscribe to Lite or above for full access."
        )
    } else {
        format!(
            "freemium daily limit: {FREEMIUM_TOKENS_PER_DAY} tokens per day used ({tokens_used}). Subscribe to Lite or above for full access."
        )
    }
}

async fn freemium_profile_lock(pool: &PgPool, owner_iid: i64) -> Result<FreemiumProfile> {
    let _ = crate::billing_profile::billing_profile_ensure(pool, owner_iid).await?;
    let row = sqlx::query_as::<_, (
        i64,
        String,
        Option<chrono::DateTime<Utc>>,
        Option<NaiveDate>,
        i32,
        i32,
    )>(
        r#"
        SELECT id, plan_tier, trial_expires_ts, freemium_day, freemium_msgs_used, freemium_tokens_used
        FROM ai.billing_profile
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        LIMIT 1
        FOR UPDATE
        "#,
    )
    .bind(owner_iid)
    .fetch_one(pool)
    .await?;
    Ok(FreemiumProfile {
        id: row.0,
        plan_tier: row.1,
        trial_expires_ts: row.2,
        freemium_day: row.3,
        freemium_msgs_used: row.4,
        freemium_tokens_used: row.5,
    })
}

async fn freemium_counters_roll(pool: &PgPool, profile_id: i64, row: &FreemiumProfile) -> Result<(i32, i32)> {
    let today = utc_day();
    if row.freemium_day == Some(today) {
        return Ok((row.freemium_msgs_used, row.freemium_tokens_used));
    }
    sqlx::query(
        r#"
        UPDATE ai.billing_profile
        SET freemium_day = $2, freemium_msgs_used = 0, freemium_tokens_used = 0, updated_ts = NOW()
        WHERE id = $1
        "#,
    )
    .bind(profile_id)
    .bind(today)
    .execute(pool)
    .await?;
    Ok((0, 0))
}

/// Check remaining freemium quota (no mutation).
pub async fn billing_freemium_check(pool: &PgPool, owner_iid: i64) -> Result<()> {
    if !billing_freemium_applies(pool, owner_iid).await? {
        return Ok(());
    }
    let row = freemium_profile_fetch(pool, owner_iid).await?.ok_or_else(|| anyhow::anyhow!("billing_profile missing"))?;
    let (msgs_used, tokens_used) = if row.freemium_day == Some(utc_day()) {
        (row.freemium_msgs_used, row.freemium_tokens_used)
    } else {
        (0, 0)
    };
    if msgs_used >= FREEMIUM_MSGS_PER_DAY {
        anyhow::bail!(freemium_rejection(msgs_used, tokens_used));
    }
    if tokens_used + FREEMIUM_TURN_TOKEN_ESTIMATE > FREEMIUM_TOKENS_PER_DAY {
        anyhow::bail!(freemium_rejection(msgs_used, tokens_used));
    }
    Ok(())
}

/// Reserve one freemium message slot at turn start (after check).
pub async fn billing_freemium_reserve_turn(pool: &PgPool, owner_iid: i64) -> Result<()> {
    if !billing_freemium_applies(pool, owner_iid).await? {
        return Ok(());
    }
    let mut tx = pool.begin().await?;
    let row = sqlx::query_as::<_, (
        i64,
        String,
        Option<chrono::DateTime<Utc>>,
        Option<NaiveDate>,
        i32,
        i32,
    )>(
        r#"
        SELECT id, plan_tier, trial_expires_ts, freemium_day, freemium_msgs_used, freemium_tokens_used
        FROM ai.billing_profile
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        LIMIT 1
        FOR UPDATE
        "#,
    )
    .bind(owner_iid)
    .fetch_one(&mut *tx)
    .await?;
    let profile = FreemiumProfile {
        id: row.0,
        plan_tier: row.1,
        trial_expires_ts: row.2,
        freemium_day: row.3,
        freemium_msgs_used: row.4,
        freemium_tokens_used: row.5,
    };
    let today = utc_day();
    let (mut msgs_used, tokens_used) = if profile.freemium_day == Some(today) {
        (profile.freemium_msgs_used, profile.freemium_tokens_used)
    } else {
        (0, 0)
    };
    if msgs_used >= FREEMIUM_MSGS_PER_DAY {
        anyhow::bail!(freemium_rejection(msgs_used, tokens_used));
    }
    if tokens_used + FREEMIUM_TURN_TOKEN_ESTIMATE > FREEMIUM_TOKENS_PER_DAY {
        anyhow::bail!(freemium_rejection(msgs_used, tokens_used));
    }
    msgs_used += 1;
    if profile.freemium_day == Some(today) {
        sqlx::query(
            r#"
            UPDATE ai.billing_profile
            SET freemium_msgs_used = $2, updated_ts = NOW()
            WHERE id = $1
            "#,
        )
        .bind(profile.id)
        .bind(msgs_used)
        .execute(&mut *tx)
        .await?;
    } else {
        sqlx::query(
            r#"
            UPDATE ai.billing_profile
            SET freemium_day = $2, freemium_msgs_used = $3, freemium_tokens_used = 0, updated_ts = NOW()
            WHERE id = $1
            "#,
        )
        .bind(profile.id)
        .bind(today)
        .bind(msgs_used)
        .execute(&mut *tx)
        .await?;
    }
    tx.commit().await?;
    crate::billing_push::billing_notify_owner(pool, None, owner_iid, None).await;
    Ok(())
}

/// Record LLM tokens after a freemium turn completes.
pub async fn billing_freemium_add_tokens(pool: &PgPool, owner_iid: i64, tokens: i32) -> Result<()> {
    if tokens <= 0 || !billing_freemium_applies(pool, owner_iid).await? {
        return Ok(());
    }
    let row = freemium_profile_lock(pool, owner_iid).await?;
    let (msgs_used, mut tokens_used) = freemium_counters_roll(pool, row.id, &row).await?;
    tokens_used = (tokens_used + tokens).min(i32::MAX);
    sqlx::query(
        r#"
        UPDATE ai.billing_profile
        SET freemium_tokens_used = $2, updated_ts = NOW()
        WHERE id = $1
        "#,
    )
    .bind(row.id)
    .bind(tokens_used)
    .execute(pool)
    .await?;
    let _ = msgs_used;
    crate::billing_push::billing_notify_owner(pool, None, owner_iid, None).await;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn paid_tiers() {
        assert!(tier_is_paid("lite"));
        assert!(tier_is_paid("Plus"));
        assert!(!tier_is_paid("free"));
        assert!(!tier_is_paid("trial"));
    }

    #[test]
    fn blocked_tools() {
        assert!(!freemium_tool_allowed("img.generate"));
        assert!(!freemium_tool_allowed("delegate.run"));
        assert!(freemium_tool_allowed("consumption.today"));
        assert!(freemium_tool_allowed("web.search"));
    }

    #[test]
    fn token_estimate_gate() {
        let used = FREEMIUM_TOKENS_PER_DAY - FREEMIUM_TURN_TOKEN_ESTIMATE;
        assert!(used + FREEMIUM_TURN_TOKEN_ESTIMATE <= FREEMIUM_TOKENS_PER_DAY);
        assert!(used + 1 + FREEMIUM_TURN_TOKEN_ESTIMATE > FREEMIUM_TOKENS_PER_DAY);
    }
}
