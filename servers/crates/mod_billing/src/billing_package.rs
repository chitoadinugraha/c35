use c35_mod_referral::{commission_accrue_on_purchase, commission_simulate, normalize_code};
use c35_proto::{ResBillingPackagePreview, ResBillingPackageRedeem};
use c35_store::snowflake_id;
use chrono::{DateTime, Utc};
use serde_json::{json, Value};
use sqlx::{PgPool, Row};

use crate::billing_entitlement::{billing_entitlement_grant, billing_entitlement_list, EntitlementGrantSpec};
use crate::billing_voucher::billing_voucher_redeem_credit;
use crate::billing_voucher::{voucher_log_redeem, voucher_on_redeemed, voucher_settle_expired_code};

fn meta_str(meta: &Value, key: &str) -> String {
    meta.get(key)
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .trim()
        .to_string()
}

fn meta_f64(meta: &Value, key: &str) -> f64 {
    meta.get(key).and_then(|v| v.as_f64()).unwrap_or(0.0)
}

fn meta_i32(meta: &Value, key: &str) -> i32 {
    meta.get(key).and_then(|v| v.as_i64()).unwrap_or(0) as i32
}

fn meta_bool(meta: &Value, key: &str) -> bool {
    meta.get(key).and_then(|v| v.as_bool()).unwrap_or(false)
}

const FX_IDR_PER_USD: f64 = 17_630.0;

fn package_from_locked_row(code: &str, row: &sqlx::postgres::PgRow) -> Result<c35_mod_referral::ReferralPackage, String> {
    let meta: Value = row.try_get("meta").unwrap_or(json!({}));
    let code_type = meta_str(&meta, "type");
    if code_type != "package" {
        return Err("package code not found or expired".into());
    }
    let expires_at_ms = row.get::<Option<f64>, _>("expires_at_ms").unwrap_or(0.0) as i64;
    if expires_at_ms > 0 && expires_at_ms <= chrono::Utc::now().timestamp_millis() {
        return Err("package code not found or expired".into());
    }
    let prepaid = meta_bool(&meta, "prepaid");
    let price_usd = meta_f64(&meta, "price_usd");
    let price_idr = meta_f64(&meta, "price_idr");
    let face = meta_f64(&meta, "face_value_idr");
    let price_idr = if prepaid && face > 0.0 {
        face
    } else if price_idr > 0.0 {
        price_idr
    } else {
        (price_usd * FX_IDR_PER_USD).round()
    };
    Ok(c35_mod_referral::ReferralPackage {
        code: code.to_string(),
        issued_by_iid: row.get("issued_by_iid"),
        name: meta_str(&meta, "name"),
        price_usd: if prepaid { 0.0 } else { price_usd },
        price_idr,
        duration_months: meta_i32(&meta, "duration_months"),
        base_plan_slug: meta_str(&meta, "base_plan_slug"),
        max_uses: meta_i32(&meta, "max_uses"),
        used_count: row.get("used_count"),
        expires_at_ms,
    })
}

fn row_expires_at(row: &sqlx::postgres::PgRow) -> Option<DateTime<Utc>> {
    row.get::<Option<f64>, _>("expires_at_ms")
        .and_then(|ms| DateTime::from_timestamp_millis(ms as i64))
}

pub async fn billing_package_preview(
    pool: &PgPool,
    buyer_iid: i64,
    raw_code: &str,
) -> Result<ResBillingPackagePreview, String> {
    let code = normalize_code(raw_code);
    let row = sqlx::query(
        r#"
        SELECT code, issued_by_iid, used_count,
               (EXTRACT(EPOCH FROM expires_at) * 1000)::float8 AS expires_at_ms,
               COALESCE(meta, '{}'::jsonb) AS meta
        FROM ai.referral_code
        WHERE code = $1
        "#,
    )
    .bind(&code)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    let Some(row) = row else {
        return Err("package code not found or expired".to_string());
    };
    let meta: Value = row.try_get("meta").unwrap_or(json!({}));
    let code_type = meta_str(&meta, "type");
    if code_type == "credit" {
        let credit = meta_f64(&meta, "credit_idr");
        let face = meta_f64(&meta, "face_value_idr").max(credit);
        let commission = commission_simulate(pool, buyer_iid, face.round() as i64).await?;
        return Ok(ResBillingPackagePreview {
            amount_usd: 0.0,
            amount_idr: credit,
            plan_tier: "credit".into(),
            package_name: meta_str(&meta, "name").if_empty_then("Wallet credit"),
            commission: Some(commission),
        });
    }
    let pkg = package_from_locked_row(&code, &row)?;
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

trait IfEmptyThen {
    fn if_empty_then(self, fallback: &str) -> String;
}

impl IfEmptyThen for String {
    fn if_empty_then(self, fallback: &str) -> String {
        if self.is_empty() {
            fallback.to_string()
        } else {
            self
        }
    }
}

pub async fn billing_package_redeem(
    pool: &PgPool,
    buyer_iid: i64,
    raw_code: &str,
) -> Result<ResBillingPackageRedeem, String> {
    let code = normalize_code(raw_code);
    if code.is_empty() {
        return Err("package code not found or expired".into());
    }
    let _ = voucher_settle_expired_code(pool, &code).await;

    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;

    let ref_row = sqlx::query(
        r#"
        SELECT code, issued_by_iid, used_count, expires_at,
               (EXTRACT(EPOCH FROM expires_at) * 1000)::float8 AS expires_at_ms,
               COALESCE(meta, '{}'::jsonb) AS meta
        FROM ai.referral_code
        WHERE code = $1
        FOR UPDATE
        "#,
    )
    .bind(&code)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|e| e.to_string())?
    .ok_or_else(|| "package code not found or expired".to_string())?;

    let meta: Value = ref_row.try_get("meta").unwrap_or(json!({}));
    let code_type = meta_str(&meta, "type");
    let max_uses = meta_i32(&meta, "max_uses");
    let used_count: i32 = ref_row.get("used_count");
    if max_uses > 0 && used_count >= max_uses {
        return Err("package code usage limit reached".into());
    }

    let purchase_id = snowflake_id();
    let code_expires = ref_row
        .get::<Option<DateTime<Utc>>, _>("expires_at")
        .unwrap_or_else(|| Utc::now() + chrono::Duration::days(90));

    if code_type == "credit" && meta_bool(&meta, "prepaid") {
        let issuer_iid: i64 = ref_row.get("issued_by_iid");
        let face = meta_f64(&meta, "face_value_idr");
        let list_price = meta_f64(&meta, "list_price_idr");
        sqlx::query("UPDATE ai.referral_code SET used_count = used_count + 1, updated_ts = NOW() WHERE code = $1")
            .bind(&code)
            .execute(&mut *tx)
            .await
            .map_err(|e| e.to_string())?;
        tx.commit().await.map_err(|e| e.to_string())?;
        billing_voucher_redeem_credit(pool, buyer_iid, &code, &meta, purchase_id, code_expires).await?;
        let _ = voucher_log_redeem(pool, &code, issuer_iid, buyer_iid, purchase_id, face, list_price).await;
        let _ = voucher_on_redeemed(pool, &code).await;
        return finish_redeem_response(pool, buyer_iid, purchase_id, &code, &meta, 0.0, 0.0, "credit", 0).await;
    }

    let prepaid = meta_bool(&meta, "prepaid");
    if code_type == "package" && prepaid {
        let pkg = package_from_locked_row(&code, &ref_row)?;
        let plan_tier = pkg.base_plan_slug.trim().to_string();
        let face = meta_f64(&meta, "face_value_idr").max(pkg.price_idr);
        let ent_expires = row_expires_at(&ref_row).unwrap_or_else(|| {
            Utc::now() + chrono::Duration::days(30 * pkg.duration_months.max(1) as i64)
        });

        sqlx::query(
            r#"
            INSERT INTO ai.billing_package_purchase (
                id, owner_iid, billing_account_id, referral_code,
                amount_usd, amount_idr, plan_tier, duration_months
            )
            SELECT $1, $2, b.id, $3, 0, $4, $5, $6
            FROM ai.billing_account b
            WHERE b.owner_iid = $2 AND b.deleted_ts IS NULL
            LIMIT 1
            "#,
        )
        .bind(purchase_id)
        .bind(buyer_iid)
        .bind(&pkg.code)
        .bind(face)
        .bind(&plan_tier)
        .bind(pkg.duration_months)
        .execute(&mut *tx)
        .await
        .map_err(|e| e.to_string())?;

        sqlx::query("UPDATE ai.referral_code SET used_count = used_count + 1, updated_ts = NOW() WHERE code = $1")
            .bind(&code)
            .execute(&mut *tx)
            .await
            .map_err(|e| e.to_string())?;
        tx.commit().await.map_err(|e| e.to_string())?;

        let custom_alien = meta_f64(&meta, "alien_pool_limit_idr");
        let custom_frontier = meta_f64(&meta, "frontier_pool_limit_idr");
        let pool_over = if custom_alien > 0.0 || custom_frontier > 0.0 {
            (Some(custom_alien), Some(custom_frontier))
        } else {
            (None, None)
        };
        let issuer_iid: i64 = ref_row.get("issued_by_iid");
        let list_price = meta_f64(&meta, "list_price_idr");
        let entitlement_id = billing_entitlement_grant(
            pool,
            EntitlementGrantSpec {
                owner_iid: buyer_iid,
                source: "voucher".into(),
                referral_code: Some(code.clone()),
                purchase_id: Some(purchase_id),
                plan_slug: plan_tier.clone(),
                duration_months: pkg.duration_months.max(1),
                credit_idr: 0.0,
                highlight: true,
                expires_ts: Some(ent_expires),
                alien_pool_override: pool_over.0,
                frontier_pool_override: pool_over.1,
            },
        )
        .await
        .map_err(|e| e.to_string())?;

        let _ = voucher_log_redeem(pool, &code, issuer_iid, buyer_iid, purchase_id, face, list_price).await;
        let _ = voucher_on_redeemed(pool, &code).await;

        let amount_idr_i64 = face.round() as i64;
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

        let (balance_usd, balance_idr) = wallet_balances(pool, buyer_iid).await?;
        let list = billing_entitlement_list(pool, buyer_iid).await.map_err(|e| e.to_string())?;
        return Ok(ResBillingPackageRedeem {
            purchase_id,
            amount_usd: 0.0,
            amount_idr: face,
            plan_tier,
            duration_months: pkg.duration_months,
            package_name: pkg.name,
            balance_usd,
            balance_idr,
            entitlements: list.items,
            entitlement_id,
            expires_ts_ms: ent_expires.timestamp_millis(),
        });
    }

    let pkg = package_from_locked_row(&code, &ref_row)?;
    if pkg.price_idr <= 0.0 && pkg.price_usd <= 0.0 {
        return Err("invalid package price".into());
    }

    let account = sqlx::query(
        r#"SELECT id, balance_idr::float8 AS balance_idr, balance_usd::float8 AS balance_usd,
                  plan_tier, billing_currency
           FROM ai.billing_account
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
    let balance_usd: f64 = account.get("balance_usd");
    let billing_currency: String = account.get("billing_currency");
    let (held_usd, held_idr) = crate::billing_reservation::billing_held_totals_exec(&mut *tx, account_id)
        .await
        .map_err(|e| e.to_string())?;
    let charge_idr = pkg.price_idr.round();
    let charge_usd = pkg.price_usd;
    let avail = crate::billing_wallet::billing_wallet_available(
        &billing_currency,
        balance_usd,
        balance_idr,
        held_usd,
        held_idr,
    );
    let need = if crate::billing_wallet::billing_wallet_use_idr(&billing_currency) {
        charge_idr
    } else {
        charge_usd
    };
    if avail + 0.001 < need {
        return Err("insufficient unreserved balance".into());
    }

    let (new_usd, new_idr) = crate::billing_wallet::billing_wallet_after_charge(
        &billing_currency,
        balance_usd,
        balance_idr,
        charge_usd,
        charge_idr,
    )?;

    let plan_tier = if !pkg.base_plan_slug.trim().is_empty() {
        pkg.base_plan_slug.trim().to_string()
    } else {
        let current_tier = account.get::<String, _>("plan_tier");
        if !current_tier.trim().is_empty() && current_tier.trim() != "free" {
            current_tier
        } else {
            "lite".to_string()
        }
    };

    sqlx::query(
        r#"
        UPDATE ai.billing_account
        SET balance_usd = $2,
            balance_idr = $3,
            plan_tier = $4,
            updated_ts = NOW()
        WHERE id = $1
        "#,
    )
    .bind(account_id)
    .bind(new_usd)
    .bind(new_idr)
    .bind(&plan_tier)
    .execute(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;

    let charge_native = if crate::billing_wallet::billing_wallet_use_idr(&billing_currency) { charge_idr } else { charge_usd };
    let wallet_currency = if crate::billing_wallet::billing_wallet_use_idr(&billing_currency) { "IDR" } else { "USD" };
    let _ = sqlx::query(
        r#"
        UPDATE ai.billing_wallet
        SET balance = GREATEST(balance - $2, 0), updated_ts = NOW()
        WHERE owner_iid = $1 AND currency = $3 AND deleted_ts IS NULL
        "#,
    )
    .bind(buyer_iid)
    .bind(charge_native)
    .bind(wallet_currency)
    .execute(&mut *tx)
    .await;

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
        .bind(&code)
        .execute(&mut *tx)
        .await
        .map_err(|e| e.to_string())?;

    tx.commit().await.map_err(|e| e.to_string())?;

    let ent_expires = row_expires_at(&ref_row).unwrap_or_else(|| {
        Utc::now() + chrono::Duration::days(30 * pkg.duration_months.max(1) as i64)
    });
    let custom_alien = meta_f64(&meta, "alien_pool_limit_idr");
    let custom_frontier = meta_f64(&meta, "frontier_pool_limit_idr");
    let pool_over = if custom_alien > 0.0 || custom_frontier > 0.0 {
        (Some(custom_alien), Some(custom_frontier))
    } else {
        (None, None)
    };
    let entitlement_id = billing_entitlement_grant(
        pool,
        EntitlementGrantSpec {
            owner_iid: buyer_iid,
            source: "referral_purchase".into(),
            referral_code: Some(code.clone()),
            purchase_id: Some(purchase_id),
            plan_slug: plan_tier.clone(),
            duration_months: pkg.duration_months.max(1),
            credit_idr: 0.0,
            highlight: true,
            expires_ts: Some(ent_expires),
            alien_pool_override: pool_over.0,
            frontier_pool_override: pool_over.1,
        },
    )
    .await
    .map_err(|e| e.to_string())?;

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

    crate::billing_push::billing_notify_owner(pool, None, buyer_iid, None).await;

    let list = billing_entitlement_list(pool, buyer_iid).await.map_err(|e| e.to_string())?;

    Ok(ResBillingPackageRedeem {
        purchase_id,
        amount_usd: pkg.price_usd,
        amount_idr: charge_idr,
        plan_tier,
        duration_months: pkg.duration_months,
        package_name: pkg.name,
        balance_usd: new_usd,
        balance_idr: new_idr,
        entitlements: list.items,
        entitlement_id,
        expires_ts_ms: ent_expires.timestamp_millis(),
    })
}

async fn wallet_balances(pool: &PgPool, owner_iid: i64) -> Result<(f64, f64), String> {
    let row = sqlx::query(
        "SELECT balance_usd::float8 AS balance_usd, balance_idr::float8 AS balance_idr FROM ai.billing_account WHERE owner_iid = $1 AND deleted_ts IS NULL LIMIT 1",
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(match row {
        Some(r) => (r.get("balance_usd"), r.get("balance_idr")),
        None => (0.0, 0.0),
    })
}

async fn finish_redeem_response(
    pool: &PgPool,
    buyer_iid: i64,
    purchase_id: i64,
    _code: &str,
    meta: &Value,
    amount_usd: f64,
    amount_idr: f64,
    plan_tier: &str,
    duration_months: i32,
) -> Result<ResBillingPackageRedeem, String> {
    let (balance_usd, balance_idr) = wallet_balances(pool, buyer_iid).await?;
    let list = billing_entitlement_list(pool, buyer_iid).await.map_err(|e| e.to_string())?;
    let ent_id = list.items.first().map(|e| e.id).unwrap_or(0);
    let expires = list.items.first().map(|e| e.expires_ts_ms).unwrap_or(0);
    Ok(ResBillingPackageRedeem {
        purchase_id,
        amount_usd,
        amount_idr,
        plan_tier: plan_tier.to_string(),
        duration_months,
        package_name: meta_str(meta, "name").if_empty_then("Wallet credit"),
        balance_usd,
        balance_idr,
        entitlements: list.items,
        entitlement_id: ent_id,
        expires_ts_ms: expires,
    })
}
