use c35_mod_referral::{commission_accrue_on_purchase, commission_simulate, referral_package_get};
use c35_proto::{ResBillingPackagePreview, ResBillingPackageRedeem};
use c35_store::snowflake_id;
use sqlx::{PgPool, Row};

pub async fn billing_package_preview(
    pool: &PgPool,
    buyer_iid: i64,
    raw_code: &str,
) -> Result<ResBillingPackagePreview, String> {
    let pkg = referral_package_get(pool, raw_code)
        .await?
        .ok_or_else(|| "package code not found or expired".to_string())?;
    if pkg.max_uses > 0 && pkg.used_count >= pkg.max_uses {
        return Err("package code usage limit reached".into());
    }
    let amount_idr = pkg.price_idr.round() as i64;
    let commission = commission_simulate(pool, buyer_iid, amount_idr).await?;
    Ok(ResBillingPackagePreview {
        amount_usd: pkg.price_usd,
        amount_idr: pkg.price_idr,
        plan_tier: pkg.base_plan_slug.clone(),
        package_name: pkg.name.clone(),
        commission: Some(commission),
    })
}

pub async fn billing_package_redeem(
    pool: &PgPool,
    buyer_iid: i64,
    raw_code: &str,
) -> Result<ResBillingPackageRedeem, String> {
    let pkg = referral_package_get(pool, raw_code)
        .await?
        .ok_or_else(|| "package code not found or expired".to_string())?;
    if pkg.max_uses > 0 && pkg.used_count >= pkg.max_uses {
        return Err("package code usage limit reached".into());
    }
    if pkg.price_idr <= 0.0 && pkg.price_usd <= 0.0 {
        return Err("invalid package price".into());
    }

    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;
    let account = sqlx::query(
        r#"SELECT id, balance_idr, balance_usd, plan_tier FROM ai.billing_account
           WHERE owner_iid = $1 AND deleted_ts IS NULL LIMIT 1 FOR UPDATE"#,
    )
    .bind(buyer_iid)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;
    let Some(account) = account else {
        return Err("billing account not found".into());
    };
    let account_id: i64 = account.get("id");
    let balance_idr: f64 = account.get("balance_idr");
    let charge_idr = pkg.price_idr.round();
    if balance_idr + 0.001 < charge_idr {
        return Err("insufficient balance".into());
    }

    let purchase_id = snowflake_id();
    let plan_tier = if pkg.base_plan_slug.trim().is_empty() {
        account.get::<String, _>("plan_tier")
    } else {
        pkg.base_plan_slug.trim().to_string()
    };

    sqlx::query(
        r#"
        UPDATE ai.billing_account
        SET balance_idr = balance_idr - $2,
            plan_tier = $3,
            updated_ts = NOW()
        WHERE id = $1
        "#,
    )
    .bind(account_id)
    .bind(charge_idr)
    .bind(&plan_tier)
    .execute(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;

    sqlx::query(
        r#"
        INSERT INTO ai.billing_package_purchase (
            id, owner_iid, billing_account_id, referral_code,
            amount_usd, amount_idr, plan_tier, duration_months
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        "#,
    )
    .bind(purchase_id)
    .bind(buyer_iid)
    .bind(account_id)
    .bind(&pkg.code)
    .bind(pkg.price_usd)
    .bind(charge_idr)
    .bind(&plan_tier)
    .bind(pkg.duration_months)
    .execute(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;

    sqlx::query("UPDATE ai.referral_code SET used_count = used_count + 1, updated_ts = NOW() WHERE code = $1")
        .bind(&pkg.code)
        .execute(&mut *tx)
        .await
        .map_err(|e| e.to_string())?;

    tx.commit().await.map_err(|e| e.to_string())?;

    let amount_idr_i64 = charge_idr.round() as i64;
    if let Err(e) = commission_accrue_on_purchase(
        pool,
        buyer_iid,
        amount_idr_i64,
        &purchase_id.to_string(),
        "package_redeem",
    )
    .await
    {
        tracing::warn!("commission accrue on package redeem: {e}");
    }

    Ok(ResBillingPackageRedeem {
        purchase_id,
        amount_usd: pkg.price_usd,
        amount_idr: charge_idr,
        plan_tier,
        duration_months: pkg.duration_months,
        package_name: pkg.name,
    })
}
