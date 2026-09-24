use c35_mod_admin::require_admin;
use c35_mod_referral::normalize_code;
use c35_proto::{BillingPromotion, BillingPromotionClaim, BillingProfile, ResBillingPromotionClaim};
use c35_store::snowflake_id;
use chrono::{DateTime, Duration, Utc};
use sqlx::{PgPool, Row};
use sqlx::postgres::PgRow;

const LITE_ALIEN_POOL_IDR: f64 = 100_000.0;
const LITE_FRONTIER_POOL_IDR: f64 = 20_000.0;
const SIGNUP_TRIAL_MULTIPLIER: f64 = 0.25;
const SIGNUP_TRIAL_DAYS: i32 = 7;

#[derive(Debug, Clone)]
pub struct PromotionCreateFields {
    pub code: String,
    pub promo_type: String,
    pub audience: String,
    pub name: String,
    pub base_plan_slug: String,
    pub pool_multiplier: f64,
    pub alien_pool_idr: f64,
    pub frontier_pool_idr: f64,
    pub duration_days: i32,
    pub duration_minutes: i32,
    pub max_claims_total: i32,
    pub max_claims_per_email: i32,
    pub valid_from_ms: i64,
    pub valid_to_ms: i64,
    pub scope: String,
    pub is_active: bool,
}

fn f64_col(row: &PgRow, col: &str) -> f64 {
    row.try_get::<f64, _>(col).unwrap_or(0.0)
}

fn i32_col(row: &PgRow, col: &str) -> i32 {
    row.try_get::<i32, _>(col).unwrap_or(0)
}

fn str_col(row: &PgRow, col: &str) -> String {
    row.try_get::<String, _>(col).unwrap_or_default()
}

fn ts_ms(row: &PgRow, col: &str) -> i64 {
    row.try_get::<Option<DateTime<Utc>>, _>(col)
        .ok()
        .flatten()
        .map(|t| t.timestamp_millis())
        .unwrap_or(0)
}

fn promotion_from_row(row: PgRow) -> BillingPromotion {
    BillingPromotion {
        id: row.get("id"),
        code: row.get("code"),
        r#type: row.get("type"),
        audience: row.get("audience"),
        name: row.get("name"),
        base_plan_slug: row.get("base_plan_slug"),
        pool_multiplier: f64_col(&row, "pool_multiplier"),
        alien_pool_idr: f64_col(&row, "alien_pool_idr"),
        frontier_pool_idr: f64_col(&row, "frontier_pool_idr"),
        duration_days: i32_col(&row, "duration_days"),
        duration_minutes: i32_col(&row, "duration_minutes"),
        max_claims_total: i32_col(&row, "max_claims_total"),
        max_claims_per_email: i32_col(&row, "max_claims_per_email"),
        valid_from_ms: ts_ms(&row, "valid_from"),
        valid_to_ms: ts_ms(&row, "valid_to"),
        scope: row.get("scope"),
        is_active: row.get("is_active"),
        created_by_iid: row.get("created_by_iid"),
        claims_count: i32_col(&row, "claims_count"),
        created_ts_ms: ts_ms(&row, "created_ts"),
        meta_json: row
            .try_get::<serde_json::Value, _>("meta")
            .ok()
            .map(|v| v.to_string())
            .unwrap_or_else(|| "{}".into()),
        updated_ts_ms: ts_ms(&row, "updated_ts"),
    }
}

fn ms_to_ts(ms: i64) -> Option<DateTime<Utc>> {
    if ms <= 0 {
        None
    } else {
        DateTime::from_timestamp_millis(ms)
    }
}

async fn plan_pool_template(
    tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
    plan_slug: &str,
) -> Result<(f64, f64, f64, String), String> {
    let slug = if plan_slug.trim().is_empty() { "lite" } else { plan_slug.trim() };
    let row = sqlx::query(
        r#"
        SELECT alien_pool_idr_monthly::float8 AS alien_pool,
               frontier_pool_idr_monthly::float8 AS frontier_pool,
               pool_multiplier::float8 AS plan_mult,
               COALESCE(tier, slug) AS tier
        FROM ai.billing_plan
        WHERE slug = $1 AND is_active = TRUE
        LIMIT 1
        "#,
    )
    .bind(slug)
    .fetch_optional(&mut **tx)
    .await
    .map_err(|e| e.to_string())?;
    if let Some(row) = row {
        let alien = f64_col(&row, "alien_pool");
        let frontier = f64_col(&row, "frontier_pool");
        if alien > 0.0 || frontier > 0.0 {
            return Ok((alien, frontier, f64_col(&row, "plan_mult"), str_col(&row, "tier")));
        }
    }
    Ok((LITE_ALIEN_POOL_IDR, LITE_FRONTIER_POOL_IDR, 1.0, slug.to_string()))
}

async fn promotion_resolve_pools(
    tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
    row: &PgRow,
) -> Result<(f64, f64, String), String> {
    let alien_fixed = f64_col(row, "alien_pool_idr");
    let frontier_fixed = f64_col(row, "frontier_pool_idr");
    if alien_fixed > 0.0 || frontier_fixed > 0.0 {
        let tier = str_col(row, "base_plan_slug");
        return Ok((alien_fixed, frontier_fixed, tier));
    }
    let promo_mult = f64_col(row, "pool_multiplier");
    let (tpl_alien, tpl_frontier, plan_mult, tier) =
        plan_pool_template(tx, &str_col(row, "base_plan_slug")).await?;
    let mult = if promo_mult > 0.0 { promo_mult } else if plan_mult > 0.0 { plan_mult } else { 1.0 };
    Ok((tpl_alien * mult, tpl_frontier * mult, tier))
}

fn promotion_validate_dates(
    audience: &str,
    valid_from: Option<DateTime<Utc>>,
    valid_to: Option<DateTime<Utc>>,
) -> Result<(), String> {
    let now = Utc::now();
    if audience == "multi" {
        if valid_from.is_none() || valid_to.is_none() {
            return Err("valid_from and valid_to required for multi audience".into());
        }
        if valid_from.unwrap() > now {
            return Err("promotion not yet valid".into());
        }
        if valid_to.unwrap() < now {
            return Err("promotion expired".into());
        }
    } else if let Some(to) = valid_to {
        if to < now {
            return Err("promotion expired".into());
        }
    }
    Ok(())
}

pub async fn billing_promotion_create(
    pool: &PgPool,
    created_by_iid: i64,
    fields: PromotionCreateFields,
) -> Result<i64, String> {
    require_admin(pool, created_by_iid).await.map_err(|e| e.message)?;
    let code = normalize_code(&fields.code);
    if code.is_empty() {
        return Err("code required".into());
    }
    if fields.promo_type.trim().is_empty() {
        return Err("promotion type required".into());
    }
    let audience = if fields.audience.trim().is_empty() {
        "multi".to_string()
    } else {
        fields.audience.trim().to_lowercase()
    };
    let max_per_email = if fields.max_claims_per_email <= 0 { 1 } else { fields.max_claims_per_email };
    let id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.billing_promotion (
            id, code, type, audience, name, base_plan_slug, pool_multiplier,
            alien_pool_idr, frontier_pool_idr, duration_days, duration_minutes,
            max_claims_total, max_claims_per_email, valid_from, valid_to,
            scope, is_active, created_by_iid
        ) VALUES (
            $1, $2, $3, $4, $5, $6, $7,
            $8, $9, $10, $11,
            $12, $13, $14, $15,
            $16, $17, $18
        )
        "#,
    )
    .bind(id)
    .bind(&code)
    .bind(fields.promo_type.trim())
    .bind(&audience)
    .bind(fields.name.trim())
    .bind(fields.base_plan_slug.trim())
    .bind(fields.pool_multiplier)
    .bind(fields.alien_pool_idr)
    .bind(fields.frontier_pool_idr)
    .bind(fields.duration_days)
    .bind(fields.duration_minutes)
    .bind(fields.max_claims_total)
    .bind(max_per_email)
    .bind(ms_to_ts(fields.valid_from_ms))
    .bind(ms_to_ts(fields.valid_to_ms))
    .bind(if fields.scope.trim().is_empty() { "user" } else { fields.scope.trim() })
    .bind(fields.is_active)
    .bind(created_by_iid)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(id)
}

pub async fn billing_promotion_get(pool: &PgPool, code: &str) -> Result<Option<BillingPromotion>, String> {
    let code = normalize_code(code);
    if code.is_empty() {
        return Ok(None);
    }
    let row = sqlx::query(
        r#"
        SELECT p.*,
               (SELECT COUNT(*)::int FROM ai.billing_promotion_claim c WHERE c.promotion_id = p.id) AS claims_count
        FROM ai.billing_promotion p
        WHERE p.code = $1
        LIMIT 1
        "#,
    )
    .bind(&code)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(row.map(promotion_from_row))
}

pub async fn billing_promotion_list_by_creator(
    pool: &PgPool,
    created_by_iid: i64,
) -> Result<Vec<BillingPromotion>, String> {
    let rows = sqlx::query(
        r#"
        SELECT p.*,
               (SELECT COUNT(*)::int FROM ai.billing_promotion_claim c WHERE c.promotion_id = p.id) AS claims_count
        FROM ai.billing_promotion p
        WHERE p.created_by_iid = $1
        ORDER BY p.created_ts DESC
        "#,
    )
    .bind(created_by_iid)
    .fetch_all(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(rows.into_iter().map(promotion_from_row).collect())
}

pub async fn billing_promotion_claim(
    pool: &PgPool,
    owner_iid: i64,
    email: &str,
    raw_code: &str,
) -> Result<ResBillingPromotionClaim, String> {
    let code = normalize_code(raw_code);
    if code.is_empty() {
        return Err("code required".into());
    }
    let email = email.trim().to_lowercase();
    if email.is_empty() || !email.contains('@') {
        return Err("verified email required".into());
    }

    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;
    let promo = sqlx::query(
        r#"
        SELECT *
        FROM ai.billing_promotion
        WHERE code = $1 AND is_active = TRUE
        LIMIT 1
        FOR UPDATE
        "#,
    )
    .bind(&code)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|e| e.to_string())?
    .ok_or_else(|| "promotion not found".to_string())?;

    let promo_id: i64 = promo.get("id");
    let promo_type = str_col(&promo, "type");
    let audience = str_col(&promo, "audience");
    let max_total = i32_col(&promo, "max_claims_total");
    let max_per_email = if i32_col(&promo, "max_claims_per_email") <= 0 {
        1
    } else {
        i32_col(&promo, "max_claims_per_email")
    };
    let valid_from = promo.try_get::<Option<DateTime<Utc>>, _>("valid_from").ok().flatten();
    let valid_to = promo.try_get::<Option<DateTime<Utc>>, _>("valid_to").ok().flatten();
    promotion_validate_dates(&audience, valid_from, valid_to)?;

    let total_claims: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM ai.billing_promotion_claim WHERE promotion_id = $1",
    )
    .bind(promo_id)
    .fetch_one(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;

    if audience == "single" && total_claims >= 1 {
        return Err("promotion already claimed".into());
    }
    if max_total > 0 && total_claims >= max_total as i64 {
        return Err("promotion claim limit reached".into());
    }

    let email_claims: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM ai.billing_promotion_claim WHERE promotion_id = $1 AND LOWER(email) = $2",
    )
    .bind(promo_id)
    .bind(&email)
    .fetch_one(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;
    if max_per_email > 0 && email_claims >= max_per_email as i64 {
        return Err("email already claimed this promotion".into());
    }

    let existing_user_claim: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM ai.billing_promotion_claim WHERE promotion_id = $1 AND owner_iid = $2",
    )
    .bind(promo_id)
    .bind(owner_iid)
    .fetch_one(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;
    if existing_user_claim > 0 {
        return Err("you already claimed this promotion".into());
    }

    let (alien_pool, frontier_pool, plan_tier) = if promo_type == "signup_trial" {
        (
            LITE_ALIEN_POOL_IDR * SIGNUP_TRIAL_MULTIPLIER,
            LITE_FRONTIER_POOL_IDR * SIGNUP_TRIAL_MULTIPLIER,
            if str_col(&promo, "base_plan_slug").is_empty() {
                "trial".to_string()
            } else {
                str_col(&promo, "base_plan_slug")
            },
        )
    } else {
        promotion_resolve_pools(&mut tx, &promo).await?
    };

    let duration_days = if promo_type == "signup_trial" {
        if i32_col(&promo, "duration_days") > 0 {
            i32_col(&promo, "duration_days")
        } else {
            SIGNUP_TRIAL_DAYS
        }
    } else {
        i32_col(&promo, "duration_days")
    };
    let duration_minutes = i32_col(&promo, "duration_minutes");
    let expires_ts = if duration_minutes > 0 {
        Utc::now() + Duration::minutes(duration_minutes as i64)
    } else if duration_days > 0 {
        Utc::now() + Duration::days(duration_days as i64)
    } else {
        Utc::now() + Duration::days(SIGNUP_TRIAL_DAYS as i64)
    };

    let claim_id = snowflake_id();
    let scope = str_col(&promo, "scope");
    let touches_profile = promo_type != "demo_trial" && scope != "device";

    if touches_profile {
        let profile_id = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT id FROM ai.billing_profile
            WHERE owner_iid = $1 AND deleted_ts IS NULL
            LIMIT 1
            FOR UPDATE
            "#,
        )
        .bind(owner_iid)
        .fetch_optional(&mut *tx)
        .await
        .map_err(|e| e.to_string())?;

        let profile_id: i64 = if let Some(id) = profile_id {
            id
        } else {
            let new_id = snowflake_id();
            sqlx::query(
                r#"
                INSERT INTO ai.billing_profile (id, owner_iid, plan_tier)
                VALUES ($1, $2, $3)
                "#,
            )
            .bind(new_id)
            .bind(owner_iid)
            .bind(&plan_tier)
            .execute(&mut *tx)
            .await
            .map_err(|e| e.to_string())?;
            new_id
        };

        sqlx::query(
            r#"
            UPDATE ai.billing_profile
            SET alien_pool_limit_idr = $2,
                alien_pool_used_idr = 0,
                frontier_pool_limit_idr = $3,
                frontier_pool_used_idr = 0,
                pool_period_start = NOW(),
                trial_expires_ts = $4,
                active_promotion_id = $5,
                plan_tier = $6,
                updated_ts = NOW()
            WHERE id = $1
            "#,
        )
        .bind(profile_id)
        .bind(alien_pool)
        .bind(frontier_pool)
        .bind(expires_ts)
        .bind(promo_id)
        .bind(&plan_tier)
        .execute(&mut *tx)
        .await
        .map_err(|e| e.to_string())?;
    }

    let meta = if promo_type == "demo_trial" {
        serde_json::json!({
            "alien_pool_limit_idr": alien_pool,
            "frontier_pool_limit_idr": frontier_pool,
            "scope": scope,
        })
    } else {
        serde_json::json!({})
    };

    sqlx::query(
        r#"
        INSERT INTO ai.billing_promotion_claim (
            id, promotion_id, owner_iid, email, expires_ts,
            alien_pool_used_idr, frontier_pool_used_idr, meta
        ) VALUES ($1, $2, $3, $4, $5, 0, 0, $6::jsonb)
        "#,
    )
    .bind(claim_id)
    .bind(promo_id)
    .bind(owner_iid)
    .bind(&email)
    .bind(expires_ts)
    .bind(meta)
    .execute(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;

    tx.commit().await.map_err(|e| e.to_string())?;

    let mut promotion_doc = promotion_from_row(promo);
    promotion_doc.claims_count = (total_claims + 1) as i32;
    let claim_doc = BillingPromotionClaim {
        id: claim_id,
        promotion_id: promo_id,
        owner_iid,
        email: email.clone(),
        expires_ts_ms: expires_ts.timestamp_millis(),
        alien_pool_used_idr: 0.0,
        frontier_pool_used_idr: 0.0,
        meta_json: if promo_type == "demo_trial" {
            serde_json::json!({
                "alien_pool_limit_idr": alien_pool,
                "frontier_pool_limit_idr": frontier_pool,
                "scope": scope,
            })
            .to_string()
        } else {
            "{}".into()
        },
        created_ts_ms: Utc::now().timestamp_millis(),
    };
    let profile_doc = if touches_profile {
        Some(BillingProfile {
            id: 0,
            owner_iid,
            plan_tier: plan_tier.clone(),
            default_wallet_currency: "IDR".into(),
            alien_allow_5h_used: 0.0,
            alien_allow_5h_limit: 0.0,
            alien_allow_weekly_used: 0.0,
            alien_allow_weekly_limit: 0.0,
            window_5h_start_ms: 0,
            window_weekly_start_ms: 0,
            commission_available_usd: 0.0,
            commission_earned_usd: 0.0,
            commission_available_idr: 0.0,
            commission_earned_idr: 0.0,
            updated_ts_ms: Utc::now().timestamp_millis(),
            alien_pool_limit_idr: alien_pool,
            alien_pool_used_idr: 0.0,
            frontier_pool_limit_idr: frontier_pool,
            frontier_pool_used_idr: 0.0,
            pool_period_start_ms: Utc::now().timestamp_millis(),
            trial_expires_ts_ms: expires_ts.timestamp_millis(),
            active_promotion_id: promo_id,
            ..Default::default()
        })
    } else {
        None
    };

    Ok(ResBillingPromotionClaim {
        claim_id,
        promotion_id: promo_id,
        alien_pool_limit_idr: alien_pool,
        frontier_pool_limit_idr: frontier_pool,
        expires_ts_ms: expires_ts.timestamp_millis(),
        plan_tier,
        promo_type: promo_type.clone(),
        claim: Some(claim_doc),
        promotion: Some(promotion_doc),
        profile: profile_doc,
    })
}
