use c35_proto::{ReqBillingPlanSubscribe, ResBillingPlanSubscribe};
use sqlx::{PgPool, Row};

use crate::billing_profile::{billing_plan_pool_template, normalize_billing_period};

pub async fn billing_plan_subscribe(
    pool: &PgPool,
    owner_iid: i64,
    req: ReqBillingPlanSubscribe,
) -> Result<ResBillingPlanSubscribe, String> {
    let slug = req.plan_slug.trim().to_lowercase();
    if slug.is_empty() || slug == "free" {
        return Err("choose a paid plan to subscribe".into());
    }
    let currency = if req.currency.trim().is_empty() {
        "IDR".to_string()
    } else {
        req.currency.trim().to_uppercase()
    };
    let billing_period = normalize_billing_period(&req.billing_period);

    let plan = sqlx::query(
        r#"
        SELECT slug, price_usd::float8 AS price_usd, alien_allow_5h_usd::float8 AS alien_5h,
               alien_allow_weekly_usd::float8 AS alien_week
        FROM ai.billing_plan
        WHERE slug = $1 AND scope = 'user' AND is_active = TRUE
        "#,
    )
    .bind(&slug)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    .ok_or_else(|| "plan not found".to_string())?;

    let price_usd: f64 = plan.get("price_usd");
    if price_usd <= 0.0 {
        return Err("plan is free — no purchase needed".into());
    }

    let (alien_pool_idr, frontier_pool_idr, tier) = billing_plan_pool_template(pool, &slug).await?;
    if alien_pool_idr <= 0.0 && frontier_pool_idr <= 0.0 {
        return Err("plan has no pool template".into());
    }

    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;

    let catalog_price = sqlx::query_scalar::<_, Option<f64>>(
        r#"
        SELECT amount::float8
        FROM ai.billing_plan_price
        WHERE plan_slug = $1 AND currency = $2 AND billing_period = $3 AND is_active = TRUE
        LIMIT 1
        "#,
    )
    .bind(&slug)
    .bind(&currency)
    .bind(billing_period)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|e| e.to_string())?
    .flatten();

    let account = sqlx::query(
        r#"SELECT id, balance_usd::float8 AS balance_usd, balance_idr::float8 AS balance_idr,
                  fx_micro_per_usd, plan_tier, billing_currency
           FROM ai.billing_account
           WHERE owner_iid = $1 AND deleted_ts IS NULL LIMIT 1 FOR UPDATE"#,
    )
    .bind(owner_iid)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|e| e.to_string())?
    .ok_or_else(|| "billing account not found".to_string())?;

    let account_id: i64 = account.get("id");
    let balance_usd: f64 = account.get("balance_usd");
    let balance_idr: f64 = account.get("balance_idr");
    let fx_micro: i64 = account.get("fx_micro_per_usd");
    let billing_currency: String = account.get("billing_currency");

    let price_idr = catalog_price.unwrap_or_else(|| {
        if currency.eq_ignore_ascii_case("IDR") {
            crate::billing_on_demand::usd_to_native(price_usd, fx_micro).round()
        } else {
            0.0
        }
    });
    let alien_5h: f64 = plan.get("alien_5h");
    let alien_week: f64 = plan.get("alien_week");

    let (held_usd, held_idr) =
        crate::billing_reservation::billing_held_totals_exec(&mut *tx, account_id)
            .await
            .map_err(|e| e.to_string())?;
    let avail_usd = (balance_usd - held_usd).max(0.0);
    let avail_idr = (balance_idr - held_idr).max(0.0);

    let charge_idr = currency.eq_ignore_ascii_case("IDR") && price_idr > 0.0;
    if charge_idr {
        if avail_idr + 0.01 < price_idr {
            return Err("insufficient IDR balance — top up first".into());
        }
    } else if avail_usd + 0.001 < price_usd {
        return Err("insufficient balance — top up first".into());
    }

    let (new_usd, new_idr) = if charge_idr {
        (balance_usd, balance_idr - price_idr)
    } else {
        (balance_usd - price_usd, balance_idr)
    };

    sqlx::query(
        r#"
        UPDATE ai.billing_account
        SET plan_tier = $2,
            balance_usd = $3,
            balance_idr = $4,
            alien_allow_5h_limit = $5,
            alien_allow_weekly_limit = $6,
            alien_allow_5h_used = 0,
            alien_allow_weekly_used = 0,
            window_5h_start = NOW(),
            window_weekly_start = NOW(),
            updated_ts = NOW()
        WHERE id = $1
        "#,
    )
    .bind(account_id)
    .bind(&slug)
    .bind(new_usd)
    .bind(new_idr)
    .bind(alien_5h)
    .bind(alien_week)
    .execute(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;

    let profile_id = sqlx::query_scalar::<_, Option<i64>>(
        "SELECT id FROM ai.billing_profile WHERE owner_iid = $1 AND deleted_ts IS NULL LIMIT 1",
    )
    .bind(owner_iid)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|e| e.to_string())?
    .flatten();

    if let Some(pid) = profile_id {
        sqlx::query(
            r#"
            UPDATE ai.billing_profile
            SET plan_tier = $2,
                alien_pool_limit_idr = $3,
                alien_pool_used_idr = 0,
                frontier_pool_limit_idr = $4,
                frontier_pool_used_idr = 0,
                pool_period_start = NOW(),
                default_wallet_currency = $5,
                updated_ts = NOW()
            WHERE id = $1
            "#,
        )
        .bind(pid)
        .bind(&tier)
        .bind(alien_pool_idr)
        .bind(frontier_pool_idr)
        .bind(&billing_currency)
        .execute(&mut *tx)
        .await
        .map_err(|e| e.to_string())?;
    } else {
        let pid = c35_store::snowflake_id();
        sqlx::query(
            r#"
            INSERT INTO ai.billing_profile (
                id, owner_iid, plan_tier, default_wallet_currency,
                alien_pool_limit_idr, alien_pool_used_idr,
                frontier_pool_limit_idr, frontier_pool_used_idr,
                pool_period_start
            ) VALUES ($1, $2, $3, $4, $5, 0, $6, 0, NOW())
            "#,
        )
        .bind(pid)
        .bind(owner_iid)
        .bind(&tier)
        .bind(&billing_currency)
        .bind(alien_pool_idr)
        .bind(frontier_pool_idr)
        .execute(&mut *tx)
        .await
        .map_err(|e| e.to_string())?;
    }

    tx.commit().await.map_err(|e| e.to_string())?;

    Ok(ResBillingPlanSubscribe {
        plan_tier: slug,
        balance_usd: new_usd,
        balance_idr: new_idr,
        alien_allow_5h_limit: alien_5h,
        alien_allow_weekly_limit: alien_week,
    })
}
