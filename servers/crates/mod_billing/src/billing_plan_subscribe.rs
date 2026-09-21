use c35_proto::{ReqBillingPlanSubscribe, ResBillingPlanSubscribe};
use sqlx::{PgPool, Row};

pub async fn billing_plan_subscribe(
    pool: &PgPool,
    owner_iid: i64,
    req: ReqBillingPlanSubscribe,
) -> Result<ResBillingPlanSubscribe, String> {
    let slug = req.plan_slug.trim().to_lowercase();
    if slug.is_empty() || slug == "free" {
        return Err("choose a paid plan to subscribe".into());
    }

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

    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;
    let account = sqlx::query(
        r#"SELECT id, balance_usd::float8 AS balance_usd, balance_idr::float8 AS balance_idr,
                  fx_micro_per_usd, plan_tier
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
    let fx = fx_micro as f64 / 1_000_000_000.0;
    let price_idr = (price_usd * fx).round();
    let alien_5h: f64 = plan.get("alien_5h");
    let alien_week: f64 = plan.get("alien_week");

    let charge_idr = price_idr > 0.0 && balance_idr + 0.01 >= price_idr;
    if charge_idr {
        if balance_idr + 0.01 < price_idr {
            return Err("insufficient IDR balance — top up first".into());
        }
    } else if balance_usd + 0.001 < price_usd {
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

    tx.commit().await.map_err(|e| e.to_string())?;

    Ok(ResBillingPlanSubscribe {
        plan_tier: slug,
        balance_usd: new_usd,
        balance_idr: new_idr,
        alien_allow_5h_limit: alien_5h,
        alien_allow_weekly_limit: alien_week,
    })
}
