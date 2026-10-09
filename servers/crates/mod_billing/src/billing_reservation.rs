use anyhow::Result;
use c35_store::snowflake_id;
use sqlx::PgPool;

use crate::billing_on_demand::{
    allowance_remaining, gate_can_start, hold_amounts, DEFAULT_HOLD_USD,
};
use crate::billing_turn::BillingRow;

fn f(s: String) -> f64 {
    s.parse().unwrap_or(0.0)
}

async fn billing_account_lock<'e, E>(executor: E, account_id: i64) -> Result<(f64, f64, String, i64)>
where
    E: sqlx::Executor<'e, Database = sqlx::Postgres>,
{
    let row = sqlx::query_as::<_, (String, String, String, i64)>(
        r#"
        SELECT balance_usd::text, balance_idr::text, billing_currency, fx_micro_per_usd
        FROM ai.billing_account
        WHERE id = $1 AND deleted_ts IS NULL
        FOR UPDATE
        "#,
    )
    .bind(account_id)
    .fetch_optional(executor)
    .await?;
    let (usd, idr, cur, _fx) = row.ok_or_else(|| anyhow::anyhow!("billing account missing"))?;
    Ok((f(usd), f(idr), cur, crate::fx_live::fx_live_micro_per_usd()))
}

pub async fn billing_held_totals(pool: &PgPool, billing_account_id: i64) -> Result<(f64, f64)> {
    billing_held_totals_exec(pool, billing_account_id).await
}

pub async fn billing_held_totals_exec<'e, E>(executor: E, billing_account_id: i64) -> Result<(f64, f64)>
where
    E: sqlx::Executor<'e, Database = sqlx::Postgres>,
{
    let row = sqlx::query_as::<_, (Option<String>, Option<String>)>(
        r#"
        SELECT COALESCE(SUM(held_usd)::text, '0'), COALESCE(SUM(held_idr)::text, '0')
        FROM ai.billing_reservation
        WHERE billing_account_id = $1 AND status = 'held'
        "#,
    )
    .bind(billing_account_id)
    .fetch_one(executor)
    .await?;
    Ok((f(row.0.unwrap_or_else(|| "0".into())), f(row.1.unwrap_or_else(|| "0".into()))))
}

pub async fn billing_reservation_hold(
    pool: &PgPool,
    owner_iid: i64,
    row: &BillingRow,
    req_id: &str,
    balance_idr: f64,
    billing_currency: &str,
    fx_micro_per_usd: i64,
) -> Result<()> {
    billing_reservation_hold_custom(
        pool,
        owner_iid,
        row,
        req_id,
        DEFAULT_HOLD_USD,
        balance_idr,
        billing_currency,
        fx_micro_per_usd,
    )
    .await
}

pub async fn billing_reservation_hold_custom(
    pool: &PgPool,
    owner_iid: i64,
    row: &BillingRow,
    req_id: &str,
    hold_usd: f64,
    balance_idr: f64,
    billing_currency: &str,
    fx_micro_per_usd: i64,
) -> Result<()> {
    let req_id = req_id.trim();
    if req_id.is_empty() {
        anyhow::bail!("req_id required");
    }
    let existing = sqlx::query_as::<_, (String,)>(
        "SELECT status FROM ai.billing_reservation WHERE req_id = $1",
    )
    .bind(req_id)
    .fetch_optional(pool)
    .await?;
    if let Some((status,)) = existing {
        if status == "held" || status == "settled" {
            return Ok(());
        }
    }

    let allowance_rem = allowance_remaining(
        row.alien_allow_5h_used,
        row.alien_allow_5h_limit,
        row.alien_allow_weekly_used,
        row.alien_allow_weekly_limit,
    );
    let (hold_usd, hold_idr) = hold_amounts(hold_usd, allowance_rem, billing_currency, fx_micro_per_usd);
    if hold_usd <= 0.0 && hold_idr <= 0.0 {
        return Ok(());
    }

    let mut tx = pool.begin().await?;
    let (bal_usd, bal_idr, cur, fx) = billing_account_lock(&mut *tx, row.id).await?;
    let (held_usd, held_idr) = billing_held_totals_exec(&mut *tx, row.id).await?;
    let balance_native = if cur.eq_ignore_ascii_case("IDR") { bal_idr } else { bal_usd };
    let held_native = if cur.eq_ignore_ascii_case("IDR") { held_idr } else { held_usd };
    let hold_native = if cur.eq_ignore_ascii_case("IDR") { hold_idr } else { hold_usd };
    if !gate_can_start(allowance_rem, balance_native, held_native, hold_native) {
        let reason = crate::billing_on_demand::quota_rejection_reason(
            row.alien_allow_5h_used,
            row.alien_allow_5h_limit,
            row.alien_allow_weekly_used,
            row.alien_allow_weekly_limit,
            &cur,
            hold_native,
        );
        anyhow::bail!(reason);
    }
    let id = snowflake_id();
    let inserted = sqlx::query(
        r#"
        INSERT INTO ai.billing_reservation (
            id, req_id, owner_iid, billing_account_id, held_usd, held_idr, status
        ) VALUES ($1, $2, $3, $4, $5, $6, 'held')
        ON CONFLICT (req_id) DO NOTHING
        "#,
    )
    .bind(id)
    .bind(req_id)
    .bind(owner_iid)
    .bind(row.id)
    .bind(hold_usd)
    .bind(hold_idr)
    .execute(&mut *tx)
    .await?;
    if inserted.rows_affected() == 0 {
        tx.commit().await?;
        return Ok(());
    }
    let _ = (balance_idr, billing_currency, fx_micro_per_usd, bal_usd, bal_idr, fx, cur);
    tx.commit().await?;
    Ok(())
}

pub async fn billing_reservation_refund(pool: &PgPool, req_id: &str) -> Result<()> {
    let req_id = req_id.trim();
    if req_id.is_empty() {
        return Ok(());
    }
    sqlx::query(
        r#"
        UPDATE ai.billing_reservation SET status = 'refunded', settled_ts = NOW(), updated_ts = NOW()
        WHERE req_id = $1 AND status = 'held'
        "#,
    )
    .bind(req_id)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn billing_reservation_settle(
    pool: &PgPool,
    owner_iid: i64,
    _row: &BillingRow,
    req_id: &str,
    cost_usd: f64,
    _balance_idr: f64,
    _billing_currency: &str,
    _fx_micro_per_usd: i64,
) -> Result<()> {
    let req_id = req_id.trim();
    if req_id.is_empty() || cost_usd <= 0.0 {
        billing_reservation_refund(pool, req_id).await?;
        return Ok(());
    }

    let res_row = sqlx::query_as::<_, (i64, String, String, String)>(
        r#"
        SELECT id, held_usd::text, held_idr::text, status
        FROM ai.billing_reservation
        WHERE req_id = $1 AND owner_iid = $2
        "#,
    )
    .bind(req_id)
    .bind(owner_iid)
    .fetch_optional(pool)
    .await?;

    let Some((res_id, _held_usd_s, _held_idr_s, status)) = res_row else {
        return Ok(());
    };
    if status == "settled" || status == "refunded" {
        return Ok(());
    }

    sqlx::query(
        r#"
        UPDATE ai.billing_reservation SET status = 'settled', settled_ts = NOW(), updated_ts = NOW()
        WHERE id = $1 AND status = 'held'
        "#,
    )
    .bind(res_id)
    .execute(pool)
    .await?;

    Ok(())
}

pub async fn billing_gate_with_hold(
    pool: &PgPool,
    owner_iid: i64,
    row: &BillingRow,
    req_id: &str,
) -> Result<()> {
    billing_gate_with_hold_model(pool, owner_iid, row, req_id, DEFAULT_HOLD_USD, None).await
}

pub async fn billing_gate_with_hold_custom(
    pool: &PgPool,
    owner_iid: i64,
    row: &BillingRow,
    req_id: &str,
    hold_usd: f64,
) -> Result<()> {
    billing_gate_with_hold_model(pool, owner_iid, row, req_id, hold_usd, None).await
}

pub async fn billing_gate_with_hold_model(
    pool: &PgPool,
    owner_iid: i64,
    row: &BillingRow,
    req_id: &str,
    hold_usd: f64,
    model: Option<&str>,
) -> Result<()> {
    let req_id = req_id.trim();
    if req_id.is_empty() {
        anyhow::bail!("req_id required");
    }
    let freemium_eligible = match model {
        None => true,
        Some(m) => crate::billing_profile::model_uses_alien_pool(m),
    };
    if freemium_eligible && crate::billing_freemium::billing_freemium_applies(pool, owner_iid).await? {
        crate::billing_freemium::billing_freemium_reserve_turn(pool, owner_iid).await?;
        return Ok(());
    }
    let profile_fut = async {
        match crate::billing_profile::billing_profile_fetch(pool, owner_iid).await? {
            Some(profile) if crate::billing_profile::profile_has_rings(&profile) => {
                let profile = crate::billing_profile::billing_profile_windows_roll(pool, profile).await?;
                let (alien_rem, frontier_rem) =
                    crate::billing_profile::profile_ring_remaining_usd(&profile.rings);
                let rem = if let Some(m) = model {
                    if crate::billing_profile::model_uses_alien_pool(m) {
                        alien_rem
                    } else {
                        frontier_rem
                    }
                } else {
                    alien_rem + frontier_rem
                };
                Ok::<_, anyhow::Error>(rem)
            }
            Some(_) => Ok(0.0),
            None => Ok(allowance_remaining(
                row.alien_allow_5h_used,
                row.alien_allow_5h_limit,
                row.alien_allow_weekly_used,
                row.alien_allow_weekly_limit,
            )),
        }
    };

    let in_flight_held_fut = async {
        sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*)::bigint FROM ai.billing_reservation WHERE owner_iid = $1 AND status = 'held'",
        )
        .bind(owner_iid)
        .fetch_one(pool)
        .await
        .unwrap_or(0)
    };

    let extra_fut = async {
        sqlx::query_as::<_, (String, String, i64)>(
            r#"
            SELECT balance_idr::text, billing_currency, fx_micro_per_usd
            FROM ai.billing_account WHERE id = $1
            "#,
        )
        .bind(row.id)
        .fetch_one(pool)
        .await
    };

    let held_totals_fut = billing_held_totals(pool, row.id);

    let existing_fut = async {
        sqlx::query_as::<_, (String,)>(
            "SELECT status FROM ai.billing_reservation WHERE req_id = $1",
        )
        .bind(req_id)
        .fetch_optional(pool)
        .await
    };

    let (allowance_rem_res, in_flight_held_count, extra_res, held_totals_res, existing_res) = tokio::join!(
        profile_fut,
        in_flight_held_fut,
        extra_fut,
        held_totals_fut,
        existing_fut,
    );

    if let Ok(Some((status,))) = existing_res {
        if status == "held" || status == "settled" {
            return Ok(());
        }
    }

    let allowance_rem = allowance_rem_res?;
    let in_flight_allowance_hold = (in_flight_held_count as f64) * hold_usd;
    let effective_allowance_rem = (allowance_rem - in_flight_allowance_hold).max(0.0);

    let extra = extra_res?;
    let balance_idr = f(extra.0);
    let currency = extra.1;
    let fx = extra.2;
    let balance_native = if currency.eq_ignore_ascii_case("IDR") { balance_idr } else { row.balance_usd };
    let (held_usd, held_idr) = held_totals_res?;
    let held_native = if currency.eq_ignore_ascii_case("IDR") { held_idr } else { held_usd };
    let (hold_usd_amt, hold_idr) = hold_amounts(hold_usd, effective_allowance_rem, &currency, fx);
    let hold_native = if currency.eq_ignore_ascii_case("IDR") { hold_idr } else { hold_usd_amt };
    if !gate_can_start(effective_allowance_rem, balance_native, held_native, hold_native) {
        let reason = crate::billing_on_demand::quota_rejection_reason(
            row.alien_allow_5h_used,
            row.alien_allow_5h_limit,
            row.alien_allow_weekly_used,
            row.alien_allow_weekly_limit,
            &currency,
            hold_native,
        );
        anyhow::bail!(reason);
    }

    let id = snowflake_id();
    let mut tx = pool.begin().await?;
    let _ = sqlx::query(
        r#"
        INSERT INTO ai.billing_reservation (
            id, req_id, owner_iid, billing_account_id, held_usd, held_idr, status
        ) VALUES ($1, $2, $3, $4, $5, $6, 'held')
        ON CONFLICT (req_id) DO NOTHING
        "#,
    )
    .bind(id)
    .bind(req_id)
    .bind(owner_iid)
    .bind(row.id)
    .bind(hold_usd_amt)
    .bind(hold_idr)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;

    Ok(())
}

pub async fn billing_can_afford_tool(
    pool: &PgPool,
    owner_iid: i64,
    tool_cost_usd: f64,
) -> Result<bool> {
    if tool_cost_usd <= 0.0 {
        return Ok(true);
    }
    let row = crate::billing_turn::billing_account_ensure(pool, owner_iid).await?;
    let profile_row = crate::billing_profile::billing_profile_fetch(pool, owner_iid).await?;
    let allowance_rem = if let Some(profile) = profile_row {
        if crate::billing_profile::profile_has_rings(&profile) {
            let profile = crate::billing_profile::billing_profile_windows_roll(pool, profile).await?;
            let (alien_rem, frontier_rem) =
                crate::billing_profile::profile_ring_remaining_usd(&profile.rings);
            alien_rem + frontier_rem
        } else {
            0.0
        }
    } else {
        allowance_remaining(
            row.alien_allow_5h_used,
            row.alien_allow_5h_limit,
            row.alien_allow_weekly_used,
            row.alien_allow_weekly_limit,
        )
    };
    if allowance_rem >= tool_cost_usd {
        return Ok(true);
    }
    let on_demand = tool_cost_usd - allowance_rem;
    let acct = sqlx::query_as::<_, (String, String, i64)>(
        "SELECT balance_idr::text, billing_currency, fx_micro_per_usd FROM ai.billing_account WHERE id = $1",
    )
    .bind(row.id)
    .fetch_one(pool)
    .await?;
    let balance_idr = f(acct.0);
    let currency = acct.1;
    let fx = acct.2;
    let (held_usd, held_idr) = billing_held_totals(pool, row.id).await?;
    let balance_native = if currency.eq_ignore_ascii_case("IDR") { balance_idr } else { row.balance_usd };
    let held_native = if currency.eq_ignore_ascii_case("IDR") { held_idr } else { held_usd };
    let available_native = crate::billing_on_demand::wallet_available_native(balance_native, held_native);
    let needed_native = if currency.eq_ignore_ascii_case("IDR") {
        crate::billing_on_demand::usd_to_native(on_demand, fx)
    } else {
        on_demand
    };
    Ok(available_native >= needed_native)
}
