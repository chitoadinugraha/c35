use anyhow::Result;
use c35_store::snowflake_id;
use sqlx::PgPool;

use crate::billing_on_demand::{
    allowance_remaining, gate_can_start, hold_amounts, wallet_charge_native,
    DEFAULT_HOLD_USD,
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
    let (usd, idr, cur, fx) = row.ok_or_else(|| anyhow::anyhow!("billing account missing"))?;
    Ok((f(usd), f(idr), cur, fx))
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
    let (hold_usd, hold_idr) = hold_amounts(DEFAULT_HOLD_USD, allowance_rem, billing_currency, fx_micro_per_usd);
    if hold_usd <= 0.0 && hold_idr <= 0.0 {
        return Ok(());
    }

    let mut tx = pool.begin().await?;
    let (bal_usd, bal_idr, cur, fx) = billing_account_lock(&mut *tx, row.id).await?;
    let (held_usd, held_idr) = billing_held_totals(pool, row.id).await?;
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
    row: &BillingRow,
    req_id: &str,
    cost_usd: f64,
    balance_idr: f64,
    billing_currency: &str,
    fx_micro_per_usd: i64,
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

    let allowance_rem = allowance_remaining(
        row.alien_allow_5h_used,
        row.alien_allow_5h_limit,
        row.alien_allow_weekly_used,
        row.alien_allow_weekly_limit,
    );
    let (charge_usd, charge_idr) = wallet_charge_native(cost_usd, allowance_rem, billing_currency, fx_micro_per_usd);

    if res_row.is_none() {
        // No hold (allowance-only turn) — direct wallet patch if needed
        if charge_usd > 0.0 || charge_idr > 0.0 {
            sqlx::query(
                r#"
                UPDATE ai.billing_account SET
                    balance_usd = GREATEST(balance_usd - $2::numeric, 0),
                    balance_idr = GREATEST(balance_idr - $3::numeric, 0),
                    updated_ts = NOW()
                WHERE owner_iid = $1
                "#,
            )
            .bind(owner_iid)
            .bind(charge_usd)
            .bind(charge_idr)
            .execute(pool)
            .await?;
        }
        return Ok(());
    }

    let (res_id, _held_usd_s, _held_idr_s, status) = res_row.unwrap();
    if status == "settled" || status == "refunded" {
        return Ok(());
    }

    let mut tx = pool.begin().await?;
    if charge_usd > 0.0 || charge_idr > 0.0 {
        sqlx::query(
            r#"
            UPDATE ai.billing_account SET
                balance_usd = GREATEST(balance_usd - $2::numeric, 0),
                balance_idr = GREATEST(balance_idr - $3::numeric, 0),
                updated_ts = NOW()
            WHERE id = $1
            "#,
        )
        .bind(row.id)
        .bind(charge_usd)
        .bind(charge_idr)
        .execute(&mut *tx)
        .await?;
    }
    sqlx::query(
        r#"
        UPDATE ai.billing_reservation SET status = 'settled', settled_ts = NOW(), updated_ts = NOW()
        WHERE id = $1 AND status = 'held'
        "#,
    )
    .bind(res_id)
    .execute(&mut *tx)
    .await?;
    let _ = (balance_idr, billing_currency, fx_micro_per_usd);
    tx.commit().await?;
    Ok(())
}

pub async fn billing_gate_with_hold(
    pool: &PgPool,
    owner_iid: i64,
    row: &BillingRow,
    req_id: &str,
) -> Result<()> {
    let extra = sqlx::query_as::<_, (String, String, i64)>(
        r#"
        SELECT balance_idr::text, billing_currency, fx_micro_per_usd
        FROM ai.billing_account WHERE id = $1
        "#,
    )
    .bind(row.id)
    .fetch_one(pool)
    .await?;
    let balance_idr = f(extra.0);
    let currency = extra.1;
    let fx = extra.2;
    let allowance_rem = allowance_remaining(
        row.alien_allow_5h_used,
        row.alien_allow_5h_limit,
        row.alien_allow_weekly_used,
        row.alien_allow_weekly_limit,
    );
    let balance_native = if currency.eq_ignore_ascii_case("IDR") { balance_idr } else { row.balance_usd };
    let (held_usd, held_idr) = billing_held_totals(pool, row.id).await?;
    let held_native = if currency.eq_ignore_ascii_case("IDR") { held_idr } else { held_usd };
    let (hold_usd, hold_idr) = hold_amounts(DEFAULT_HOLD_USD, allowance_rem, &currency, fx);
    let hold_native = if currency.eq_ignore_ascii_case("IDR") { hold_idr } else { hold_usd };
    if !gate_can_start(allowance_rem, balance_native, held_native, hold_native) {
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
    billing_reservation_hold(pool, owner_iid, row, req_id, balance_idr, &currency, fx).await?;
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
    let allowance_rem = allowance_remaining(
        row.alien_allow_5h_used,
        row.alien_allow_5h_limit,
        row.alien_allow_weekly_used,
        row.alien_allow_weekly_limit,
    );
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
