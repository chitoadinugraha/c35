use anyhow::Result;
use chrono::{Duration, Utc};
use c35_mod_log::{log_put, LogPut};
use c35_store::snowflake_id;
use sqlx::PgPool;

use crate::billing_cost::billing_cost_usd;

#[derive(Debug, Clone)]
pub struct BillingRow {
    pub id: i64,
    pub owner_iid: i64,
    pub plan_tier: String,
    pub balance_usd: f64,
    pub alien_allow_5h_used: f64,
    pub alien_allow_5h_limit: f64,
    pub alien_allow_weekly_used: f64,
    pub alien_allow_weekly_limit: f64,
    pub window_5h_start: chrono::DateTime<Utc>,
    pub window_weekly_start: chrono::DateTime<Utc>,
}

fn f(s: String) -> f64 { s.parse().unwrap_or(0.0) }

async fn billing_fetch(pool: &PgPool, owner_iid: i64) -> Result<Option<BillingRow>> {
    let row = sqlx::query_as::<_, (i64, String, String, String, String, String, String, chrono::DateTime<Utc>, chrono::DateTime<Utc>)>(
        r#"
        SELECT id, plan_tier, balance_usd::text, alien_allow_5h_used::text, alien_allow_5h_limit::text,
               alien_allow_weekly_used::text, alien_allow_weekly_limit::text,
               window_5h_start, window_weekly_start
        FROM ai.billing_account
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(|(id, tier, bal, u5, l5, uw, lw, w5, ww)| BillingRow {
        id,
        owner_iid,
        plan_tier: tier,
        balance_usd: f(bal),
        alien_allow_5h_used: f(u5),
        alien_allow_5h_limit: f(l5),
        alien_allow_weekly_used: f(uw),
        alien_allow_weekly_limit: f(lw),
        window_5h_start: w5,
        window_weekly_start: ww,
    }))
}

async fn billing_windows_roll(pool: &PgPool, mut row: BillingRow) -> Result<BillingRow> {
    let now = Utc::now();
    let mut sql = "UPDATE ai.billing_account SET updated_ts = NOW()".to_string();
    if now - row.window_5h_start >= Duration::hours(5) {
        sql.push_str(", alien_allow_5h_used = 0, window_5h_start = NOW()");
        row.alien_allow_5h_used = 0.0;
        row.window_5h_start = now;
    }
    if now - row.window_weekly_start >= Duration::days(7) {
        sql.push_str(", alien_allow_weekly_used = 0, window_weekly_start = NOW()");
        row.alien_allow_weekly_used = 0.0;
        row.window_weekly_start = now;
    }
    sql.push_str(" WHERE id = $1");
    sqlx::query(&sql).bind(row.id).execute(pool).await?;
    Ok(row)
}

pub async fn billing_account_ensure(pool: &PgPool, owner_iid: i64) -> Result<BillingRow> {
    if let Some(row) = billing_fetch(pool, owner_iid).await? {
        return billing_windows_roll(pool, row).await;
    }
    if billing_fetch(pool, owner_iid).await?.is_none() {
        let id = snowflake_id();
        sqlx::query("INSERT INTO ai.billing_account (id, owner_iid) VALUES ($1, $2)")
            .bind(id)
            .bind(owner_iid)
            .execute(pool)
            .await?;
    }
    Ok(billing_fetch(pool, owner_iid).await?.expect("billing_account"))
}

pub async fn billing_gate(pool: &PgPool, owner_iid: i64) -> Result<BillingRow> {
    let row = billing_account_ensure(pool, owner_iid).await?;
    let acct = sqlx::query_as::<_, (String, String, i64)>(
        "SELECT balance_idr::text, billing_currency, fx_micro_per_usd FROM ai.billing_account WHERE id = $1",
    )
    .bind(row.id)
    .fetch_one(pool)
    .await?;
    let balance_idr = f(acct.0);
    let allowance_rem = crate::billing_on_demand::allowance_remaining(
        row.alien_allow_5h_used,
        row.alien_allow_5h_limit,
        row.alien_allow_weekly_used,
        row.alien_allow_weekly_limit,
    );
    if allowance_rem > 0.0 {
        return Ok(row);
    }
    let (held_usd, held_idr) = crate::billing_reservation::billing_held_totals(pool, row.id).await?;
    let balance_native = if acct.1.eq_ignore_ascii_case("IDR") { balance_idr } else { row.balance_usd };
    let held_native = if acct.1.eq_ignore_ascii_case("IDR") { held_idr } else { held_usd };
    let (hold_usd, hold_idr) = crate::billing_on_demand::hold_amounts(
        crate::billing_on_demand::DEFAULT_HOLD_USD,
        allowance_rem,
        &acct.1,
        acct.2,
    );
    let hold_native = if acct.1.eq_ignore_ascii_case("IDR") { hold_idr } else { hold_usd };
    if !crate::billing_on_demand::gate_can_start(allowance_rem, balance_native, held_native, hold_native) {
        anyhow::bail!("quota exceeded");
    }
    Ok(row)
}

pub async fn billing_deduct_allowance(pool: &PgPool, owner_iid: i64, cost_usd: f64) -> Result<BillingRow> {
    let row = billing_account_ensure(pool, owner_iid).await?;
    sqlx::query(
        r#"
        UPDATE ai.billing_account SET
            alien_allow_5h_used = alien_allow_5h_used + $2,
            alien_allow_weekly_used = alien_allow_weekly_used + $2,
            updated_ts = NOW()
        WHERE owner_iid = $1
        "#,
    )
    .bind(owner_iid)
    .bind(cost_usd)
    .execute(pool)
    .await?;
    Ok(billing_fetch(pool, owner_iid).await?.unwrap_or(row))
}

pub async fn billing_deduct(pool: &PgPool, owner_iid: i64, cost_usd: f64) -> Result<BillingRow> {
    billing_deduct_allowance(pool, owner_iid, cost_usd).await
}

pub async fn billing_usage_report(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    owner_iid: i64,
    req_id: &str,
    chat_id: i64,
    model: &str,
    tokens_in: i32,
    tokens_out: i32,
    duration_ms: i32,
    bctx: Option<&crate::billing_resolve::BillingContext>,
) -> Result<f64> {
    let req_id = req_id.trim();
    if req_id.is_empty() {
        anyhow::bail!("req_id required");
    }
    let row = if let Some(b) = bctx {
        crate::billing_resolve::billing_gate_scoped(pool, b).await?
    } else {
        billing_gate(pool, owner_iid).await?
    };
    let cost = billing_cost_usd(model, tokens_in, tokens_out);
    if cost <= 0.0 {
        return Ok(0.0);
    }
    let meta = if let Some(b) = bctx {
        serde_json::json!({
            "billing_scope": b.scope,
            "plan_slug": b.plan_slug,
            "bot_iid": if b.scope == "bot" { b.scope_iid } else { 0 },
            "device_iid": if b.scope == "device" { b.scope_iid } else { 0 },
        })
    } else {
        serde_json::json!({})
    };
    let log_id = log_put(
        pool,
        nats,
        LogPut {
            owner_iid,
            kind: "llm",
            topic: "",
            dv: "",
            req_id: Some(req_id),
            chat_id: Some(chat_id),
            task_id: None,
            device_iid: bctx.and_then(|b| if b.scope == "device" { Some(b.scope_iid) } else { None }),
            text: "",
            model,
            tokens_in,
            tokens_out,
            duration_ms,
            cost_usd: cost,
            meta,
        },
    )
    .await?;
    let inserted = sqlx::query(
        r#"
        INSERT INTO ai.billing_usage_dedupe (owner_iid, req_id, cost_usd, billing_account_id, log_id)
        VALUES ($1, $2, $3, $4, $5)
        ON CONFLICT (owner_iid, req_id) DO NOTHING
        "#,
    )
    .bind(owner_iid)
    .bind(req_id)
    .bind(cost)
    .bind(row.id)
    .bind(log_id)
    .execute(pool)
    .await?;
    if inserted.rows_affected() == 0 {
        return Ok(0.0);
    }
    let allowance_rem = crate::billing_on_demand::allowance_remaining(
        row.alien_allow_5h_used,
        row.alien_allow_5h_limit,
        row.alien_allow_weekly_used,
        row.alien_allow_weekly_limit,
    );
    let row_after = if let Some(b) = bctx {
        crate::billing_resolve::billing_deduct_scoped(pool, b, cost, model).await?;
        billing_fetch(pool, owner_iid).await?.unwrap_or(row)
    } else {
        billing_deduct_allowance(pool, owner_iid, cost).await?
    };
    let acct = sqlx::query_as::<_, (String, String, i64)>(
        "SELECT balance_idr::text, billing_currency, fx_micro_per_usd FROM ai.billing_account WHERE id = $1",
    )
    .bind(row_after.id)
    .fetch_one(pool)
    .await?;
    let balance_idr = acct.0.parse().unwrap_or(0.0);
    crate::billing_reservation::billing_reservation_settle(
        pool,
        owner_iid,
        &row_after,
        req_id,
        cost,
        balance_idr,
        &acct.1,
        acct.2,
    )
    .await?;
    let currency = acct.1.clone();
    let fx = acct.2;
    let amount_native = if currency.eq_ignore_ascii_case("IDR") {
        crate::billing_on_demand::usd_to_native(cost, fx)
    } else {
        cost
    };
    let (charge_usd, charge_idr) =
        crate::billing_on_demand::wallet_charge_native(cost, allowance_rem, &currency, fx);
    let deducted_native = if currency.eq_ignore_ascii_case("IDR") { charge_idr } else { charge_usd };
    sqlx::query(
        r#"
        UPDATE ai.billing_usage_dedupe SET
            currency = $3,
            amount_native = $4,
            deducted_native = $5
        WHERE owner_iid = $1 AND req_id = $2
        "#,
    )
    .bind(owner_iid)
    .bind(req_id)
    .bind(&currency)
    .bind(amount_native)
    .bind(deducted_native)
    .execute(pool)
    .await?;
    Ok(cost)
}
