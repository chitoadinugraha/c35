use chrono::{DateTime, Utc};
use c35_proto::{
    BillingPlanQuoteLine, ReqBillingPlanChange, ReqBillingPlanQuote, ReqBillingPlanSubscribe,
    ResBillingPlanChange, ResBillingPlanQuote, ResBillingPlanSubscribe,
};
use sqlx::{PgPool, Row, Transaction};

use crate::billing_freemium::{plan_expires_from_period, tier_is_paid};
use crate::billing_profile::{billing_plan_pool_template, normalize_billing_period};

pub const YEARLY_ALIEN_BONUS: f64 = 1.2;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PlanChangeKind {
    Same,
    Subscribe,
    Upgrade,
    Downgrade,
    Cancel,
}

impl PlanChangeKind {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Same => "same",
            Self::Subscribe => "subscribe",
            Self::Upgrade => "upgrade",
            Self::Downgrade => "downgrade",
            Self::Cancel => "cancel",
        }
    }
}

struct ProfileSub {
    id: i64,
    plan_tier: String,
    billing_period: String,
    plan_expires_ts: Option<DateTime<Utc>>,
    pending_plan_slug: Option<String>,
    pending_billing_period: Option<String>,
}

pub fn plan_cancel_slug(slug: &str) -> bool {
    matches!(
        slug.trim().to_lowercase().as_str(),
        "none" | "free" | "no_plan" | "no-plan"
    )
}

pub fn tier_rank(slug: &str) -> i32 {
    match slug.trim().to_lowercase().as_str() {
        "lite" => 1,
        "plus" => 2,
        "pro" => 3,
        "ultra" => 4,
        _ => 0,
    }
}

fn period_seconds(period: &str) -> f64 {
    if period == "yearly" {
        365.0 * 86400.0
    } else {
        30.0 * 86400.0
    }
}

fn prorate_credit_idr(price_idr: f64, expires: DateTime<Utc>, period: &str) -> f64 {
    let now = Utc::now();
    if price_idr <= 0.0 || expires <= now {
        return 0.0;
    }
    let total = period_seconds(period);
    let remaining = (expires - now).num_seconds().max(0) as f64;
    (price_idr * remaining / total).floor()
}

pub fn alien_yearly_multiplier(period: &str) -> f64 {
    if normalize_billing_period(period) == "yearly" {
        YEARLY_ALIEN_BONUS
    } else {
        1.0
    }
}

fn classify_change(
    current: &str,
    target: &str,
    target_period: &str,
    current_period: &str,
    current_paid: bool,
    period_expired: bool,
) -> PlanChangeKind {
    if plan_cancel_slug(target) {
        return PlanChangeKind::Cancel;
    }
    if !current_paid || !tier_is_paid(current) || period_expired {
        return PlanChangeKind::Subscribe;
    }
    let cur = current.trim().to_lowercase();
    let tgt = target.trim().to_lowercase();
    if cur == tgt && normalize_billing_period(target_period) == normalize_billing_period(current_period) {
        return PlanChangeKind::Same;
    }
    if cur == tgt {
        return PlanChangeKind::Downgrade;
    }
    if tier_rank(&tgt) > tier_rank(&cur) {
        return PlanChangeKind::Upgrade;
    }
    if tier_rank(&tgt) < tier_rank(&cur) {
        return PlanChangeKind::Downgrade;
    }
    PlanChangeKind::Subscribe
}

async fn profile_sub_fetch(pool: &PgPool, owner_iid: i64) -> Result<Option<ProfileSub>, String> {
    let row = sqlx::query(
        r#"
        SELECT id, plan_tier,
               COALESCE(NULLIF(TRIM(billing_period), ''), 'monthly') AS billing_period,
               plan_expires_ts,
               NULLIF(TRIM(pending_plan_slug), '') AS pending_plan_slug,
               NULLIF(TRIM(pending_billing_period), '') AS pending_billing_period
        FROM ai.billing_profile
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(row.map(|r| ProfileSub {
        id: r.get("id"),
        plan_tier: r.get("plan_tier"),
        billing_period: r.get("billing_period"),
        plan_expires_ts: r.get("plan_expires_ts"),
        pending_plan_slug: r.get("pending_plan_slug"),
        pending_billing_period: r.get("pending_billing_period"),
    }))
}

async fn plan_price_idr(
    pool: &PgPool,
    slug: &str,
    currency: &str,
    billing_period: &str,
    price_usd_fallback: f64,
) -> Result<f64, String> {
    let catalog = sqlx::query_scalar::<_, Option<f64>>(
        r#"
        SELECT amount::float8
        FROM ai.billing_plan_price
        WHERE plan_slug = $1 AND currency = $2 AND billing_period = $3 AND is_active = TRUE
        LIMIT 1
        "#,
    )
    .bind(slug)
    .bind(currency)
    .bind(billing_period)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    .flatten();
    Ok(catalog.unwrap_or_else(|| {
        if currency.eq_ignore_ascii_case("IDR") {
            let fx = crate::fx_live::fx_live_micro_per_usd();
            crate::billing_on_demand::usd_to_native(price_usd_fallback, fx).round()
        } else {
            price_usd_fallback
        }
    }))
}

async fn plan_usd_fallback(pool: &PgPool, slug: &str) -> Result<f64, String> {
    sqlx::query_scalar::<_, Option<f64>>(
        "SELECT price_usd::float8 FROM ai.billing_plan WHERE slug = $1 AND scope = 'user' AND is_active = TRUE",
    )
    .bind(slug)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    .flatten()
    .ok_or_else(|| "plan not found".to_string())
}

struct QuoteCalc {
    kind: PlanChangeKind,
    charge_idr: f64,
    credit_idr: f64,
    list_price_idr: f64,
    lines: Vec<BillingPlanQuoteLine>,
    summary: String,
    effective_ms: i64,
    expires_ms: i64,
    pending_slug: String,
    pending_period: String,
}

async fn quote_calc(
    pool: &PgPool,
    owner_iid: i64,
    slug: &str,
    billing_period: &str,
    currency: &str,
) -> Result<QuoteCalc, String> {
    let slug = slug.trim().to_lowercase();
    let billing_period = normalize_billing_period(billing_period);
    let currency = if currency.trim().is_empty() {
        "IDR".to_string()
    } else {
        currency.trim().to_uppercase()
    };

    if !plan_cancel_slug(&slug) && tier_rank(&slug) == 0 {
        return Err("plan not found".to_string());
    }

    let profile = profile_sub_fetch(pool, owner_iid).await?;
    let account_tier: String = sqlx::query_scalar(
        "SELECT COALESCE(plan_tier, 'free') FROM ai.billing_account WHERE owner_iid = $1 AND deleted_ts IS NULL LIMIT 1",
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    .unwrap_or_else(|| "free".to_string());

    let current = profile
        .as_ref()
        .map(|p| p.plan_tier.clone())
        .unwrap_or_else(|| account_tier.clone());
    let current_period = profile
        .as_ref()
        .map(|p| normalize_billing_period(&p.billing_period).to_string())
        .unwrap_or_else(|| "monthly".to_string());
    let current_paid = tier_is_paid(&current);
    let expires = profile.as_ref().and_then(|p| p.plan_expires_ts);
    let expires_ms = expires.map(|t| t.timestamp_millis()).unwrap_or(0);
    let period_expired = expires.map(|e| e <= Utc::now()).unwrap_or(!current_paid);
    let kind = classify_change(
        &current,
        &slug,
        billing_period,
        &current_period,
        current_paid,
        period_expired,
    );
    let now_ms = Utc::now().timestamp_millis();

    if kind == PlanChangeKind::Same {
        return Ok(QuoteCalc {
            kind,
            charge_idr: 0.0,
            credit_idr: 0.0,
            list_price_idr: 0.0,
            lines: vec![],
            summary: "Already on this plan and billing period.".into(),
            effective_ms: now_ms,
            expires_ms,
            pending_slug: profile
                .as_ref()
                .and_then(|p| p.pending_plan_slug.clone())
                .unwrap_or_default(),
            pending_period: profile
                .as_ref()
                .and_then(|p| p.pending_billing_period.clone())
                .unwrap_or_default(),
        });
    }

    if kind == PlanChangeKind::Cancel {
        if !current_paid {
            return Err("no active paid plan to change".into());
        }
        let end = expires
            .map(|t| t.format("%d %b %Y").to_string())
            .unwrap_or_else(|| "period end".into());
        return Ok(QuoteCalc {
            kind,
            charge_idr: 0.0,
            credit_idr: 0.0,
            list_price_idr: 0.0,
            lines: vec![BillingPlanQuoteLine {
                label: "After current period".into(),
                amount_idr: 0.0,
                is_credit: false,
                accent: false,
            }],
            summary: format!("Stay on {current} until {end}, then daily free limits (Alien AI only)."),
            effective_ms: expires_ms,
            expires_ms,
            pending_slug: "free".into(),
            pending_period: String::new(),
        });
    }

    if kind == PlanChangeKind::Downgrade {
        if !current_paid {
            return Err("no active paid plan to change".into());
        }
        let end = expires
            .map(|t| t.format("%d %b %Y").to_string())
            .unwrap_or_else(|| "period end".into());
        let new_price = if plan_cancel_slug(&slug) {
            0.0
        } else {
            let usd = plan_usd_fallback(pool, &slug).await?;
            plan_price_idr(pool, &slug, &currency, billing_period, usd).await?
        };
        let label = if plan_cancel_slug(&slug) {
            "No plan".into()
        } else {
            slug.clone()
        };
        return Ok(QuoteCalc {
            kind,
            charge_idr: 0.0,
            credit_idr: 0.0,
            list_price_idr: new_price,
            lines: vec![],
            summary: format!(
                "Keep {current} until {end}, then switch to {label}. No charge today."
            ),
            effective_ms: expires_ms,
            expires_ms,
            pending_slug: slug,
            pending_period: billing_period.to_string(),
        });
    }

    let usd = plan_usd_fallback(pool, &slug).await?;
    let list_price = plan_price_idr(pool, &slug, &currency, billing_period, usd).await?;
    let mut credit = 0.0;
    let mut lines = vec![BillingPlanQuoteLine {
        label: format!("{} ({billing_period})", slug),
        amount_idr: list_price,
        is_credit: false,
        accent: false,
    }];

    if kind == PlanChangeKind::Upgrade && current_paid {
        if let (Some(exp), true) = (expires, tier_is_paid(&current)) {
            let cur_usd = plan_usd_fallback(pool, &current).await.unwrap_or(0.0);
            let cur_price = plan_price_idr(pool, &current, &currency, &current_period, cur_usd).await?;
            credit = prorate_credit_idr(cur_price, exp, &current_period);
            if credit > 0.0 {
                let total = period_seconds(&current_period);
                let remaining_days = ((exp - Utc::now()).num_seconds().max(0) as f64 / 86400.0).ceil() as i32;
                let total_days = (total / 86400.0).round() as i32;
                lines.push(BillingPlanQuoteLine {
                    label: format!("Credit — unused {current} ({remaining_days} of {total_days} days)"),
                    amount_idr: credit,
                    is_credit: true,
                    accent: true,
                });
            }
        }
    }

    let charge = (list_price - credit).max(0.0).floor();
    lines.push(BillingPlanQuoteLine {
        label: "Due today".into(),
        amount_idr: charge,
        is_credit: false,
        accent: true,
    });

    let bonus = alien_yearly_multiplier(billing_period) > 1.0;
    let summary = if kind == PlanChangeKind::Upgrade {
        format!(
            "Upgrade to {slug} now. Pools reset to {slug} included amounts{}.",
            if bonus { " (+20% Alien AI quota on yearly)" } else { "" }
        )
    } else {
        format!("Subscribe to {slug} ({billing_period}).")
    };

    Ok(QuoteCalc {
        kind,
        charge_idr: charge,
        credit_idr: credit,
        list_price_idr: list_price,
        lines,
        summary,
        effective_ms: now_ms,
        expires_ms: if kind == PlanChangeKind::Upgrade {
            expires_ms
        } else {
            plan_expires_from_period(billing_period).timestamp_millis()
        },
        pending_slug: String::new(),
        pending_period: String::new(),
    })
}

pub async fn billing_plan_quote(pool: &PgPool, owner_iid: i64, req: ReqBillingPlanQuote) -> Result<ResBillingPlanQuote, String> {
    let slug = req.plan_slug.trim().to_lowercase();
    let calc = quote_calc(
        pool,
        owner_iid,
        &slug,
        &req.billing_period,
        &req.currency,
    )
    .await?;
    let profile = profile_sub_fetch(pool, owner_iid).await?;
    let account_tier: String = sqlx::query_scalar(
        "SELECT COALESCE(plan_tier, 'free') FROM ai.billing_account WHERE owner_iid = $1 AND deleted_ts IS NULL LIMIT 1",
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    .unwrap_or_else(|| "free".to_string());
    let current = profile
        .as_ref()
        .map(|p| p.plan_tier.clone())
        .unwrap_or(account_tier);
    let current_period = profile
        .as_ref()
        .map(|p| normalize_billing_period(&p.billing_period).to_string())
        .unwrap_or_else(|| "monthly".into());

    Ok(ResBillingPlanQuote {
        kind: calc.kind.as_str().into(),
        plan_slug: slug,
        billing_period: normalize_billing_period(&req.billing_period).into(),
        charge_idr: calc.charge_idr,
        credit_idr: calc.credit_idr,
        list_price_idr: calc.list_price_idr,
        effective_ts_ms: calc.effective_ms,
        plan_expires_ts_ms: calc.expires_ms,
        pending_plan_slug: calc.pending_slug,
        pending_billing_period: calc.pending_period,
        lines: calc.lines,
        summary: calc.summary,
        yearly_alien_bonus: alien_yearly_multiplier(&req.billing_period) > 1.0,
        current_plan_slug: current,
        current_billing_period: current_period,
    })
}

struct ApplyLimits {
    alien_pool: f64,
    frontier_pool: f64,
    alien_5h: f64,
    alien_week: f64,
    tier: String,
}

async fn limits_for_plan(pool: &PgPool, slug: &str, billing_period: &str) -> Result<ApplyLimits, String> {
    let plan = sqlx::query(
        r#"
        SELECT slug, alien_allow_5h_usd::float8 AS alien_5h,
               alien_allow_weekly_usd::float8 AS alien_week
        FROM ai.billing_plan
        WHERE slug = $1 AND scope = 'user' AND is_active = TRUE
        "#,
    )
    .bind(slug)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    .ok_or_else(|| "plan not found".to_string())?;
    let (alien_pool, frontier_pool, tier) = billing_plan_pool_template(pool, slug).await?;
    let mult = alien_yearly_multiplier(billing_period);
    Ok(ApplyLimits {
        alien_pool: alien_pool * mult,
        frontier_pool,
        alien_5h: plan.get::<f64, _>("alien_5h") * mult,
        alien_week: plan.get::<f64, _>("alien_week") * mult,
        tier,
    })
}

async fn apply_immediate_plan(
    tx: &mut Transaction<'_, sqlx::Postgres>,
    owner_iid: i64,
    account_id: i64,
    slug: &str,
    billing_period: &str,
    billing_currency: &str,
    limits: &ApplyLimits,
    charge_idr: f64,
    charge_usd: f64,
    balance_usd: f64,
    balance_idr: f64,
    use_idr: bool,
    keep_expires: Option<DateTime<Utc>>,
) -> Result<(f64, f64), String> {
    let (new_usd, new_idr) = if use_idr {
        (balance_usd, balance_idr - charge_idr)
    } else {
        (balance_usd - charge_usd, balance_idr)
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
    .bind(slug)
    .bind(new_usd)
    .bind(new_idr)
    .bind(limits.alien_5h)
    .bind(limits.alien_week)
    .execute(&mut **tx)
    .await
    .map_err(|e| e.to_string())?;

    let plan_expires = keep_expires.unwrap_or_else(|| plan_expires_from_period(billing_period));
    sqlx::query(
        r#"
        UPDATE ai.billing_profile
        SET plan_tier = $2,
            billing_period = $3,
            alien_pool_limit_idr = $4,
            alien_pool_used_idr = 0,
            frontier_pool_limit_idr = $5,
            frontier_pool_used_idr = 0,
            pool_period_start = NOW(),
            plan_expires_ts = $6,
            pending_plan_slug = NULL,
            pending_billing_period = NULL,
            default_wallet_currency = $7,
            updated_ts = NOW()
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .bind(&limits.tier)
    .bind(billing_period)
    .bind(limits.alien_pool)
    .bind(limits.frontier_pool)
    .bind(plan_expires)
    .bind(billing_currency)
    .execute(&mut **tx)
    .await
    .map_err(|e| e.to_string())?;
    Ok((new_usd, new_idr))
}

pub async fn billing_plan_change(pool: &PgPool, owner_iid: i64, req: ReqBillingPlanChange) -> Result<ResBillingPlanChange, String> {
    let slug = req.plan_slug.trim().to_lowercase();
    let billing_period = normalize_billing_period(&req.billing_period);
    let currency = if req.currency.trim().is_empty() {
        "IDR".to_string()
    } else {
        req.currency.trim().to_uppercase()
    };

    let calc = quote_calc(pool, owner_iid, &slug, billing_period, &currency).await?;
    if calc.kind == PlanChangeKind::Same {
        return Err("already on this plan — no change needed".into());
    }

    let profile = profile_sub_fetch(pool, owner_iid).await?;
    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;

    let account = sqlx::query(
        r#"SELECT id, balance_usd::float8 AS balance_usd, balance_idr::float8 AS balance_idr,
                  plan_tier, billing_currency
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
    let billing_currency: String = account.get("billing_currency");

    if calc.kind == PlanChangeKind::Cancel || calc.kind == PlanChangeKind::Downgrade {
        if !tier_is_paid(&account.get::<String, _>("plan_tier")) {
            return Err("no active paid plan to change".into());
        }
        let _ = crate::billing_profile::billing_profile_ensure(pool, owner_iid)
            .await
            .map_err(|e| e.to_string())?;
        let pending_slug = if calc.kind == PlanChangeKind::Cancel {
            "free".to_string()
        } else {
            slug.clone()
        };
        let pending_period = if calc.kind == PlanChangeKind::Cancel {
            String::new()
        } else {
            billing_period.to_string()
        };
        sqlx::query(
            r#"
            UPDATE ai.billing_profile
            SET pending_plan_slug = $2,
                pending_billing_period = NULLIF(TRIM($3), ''),
                updated_ts = NOW()
            WHERE owner_iid = $1 AND deleted_ts IS NULL
            "#,
        )
        .bind(owner_iid)
        .bind(&pending_slug)
        .bind(&pending_period)
        .execute(&mut *tx)
        .await
        .map_err(|e| e.to_string())?;
        tx.commit().await.map_err(|e| e.to_string())?;
        let expires_ms = profile
            .as_ref()
            .and_then(|p| p.plan_expires_ts)
            .map(|t| t.timestamp_millis())
            .unwrap_or(0);
        return Ok(ResBillingPlanChange {
            plan_tier: account.get::<String, _>("plan_tier"),
            balance_usd,
            balance_idr,
            alien_allow_5h_limit: 0.0,
            alien_allow_weekly_limit: 0.0,
            pending_plan_slug: pending_slug,
            plan_expires_ts_ms: expires_ms,
            change_kind: calc.kind.as_str().into(),
            pending_billing_period: pending_period,
        });
    }

    let usd = plan_usd_fallback(pool, &slug).await?;
    let list_usd = usd;
    let charge_idr = calc.charge_idr;
    let charge_usd = if currency.eq_ignore_ascii_case("IDR") {
        0.0
    } else {
        (list_usd - calc.credit_idr / 17_630.0).max(0.0)
    };
    let use_idr = currency.eq_ignore_ascii_case("IDR") && charge_idr > 0.0;

    let (held_usd, held_idr) = crate::billing_reservation::billing_held_totals_exec(&mut *tx, account_id)
        .await
        .map_err(|e| e.to_string())?;
    let avail_usd = (balance_usd - held_usd).max(0.0);
    let avail_idr = (balance_idr - held_idr).max(0.0);
    if use_idr {
        if avail_idr + 0.01 < charge_idr {
            return Err("insufficient IDR balance — top up first".into());
        }
    } else if avail_usd + 0.001 < charge_usd {
        return Err("insufficient balance — top up first".into());
    }

    let limits = limits_for_plan(pool, &slug, billing_period).await?;
    let keep_expires = if calc.kind == PlanChangeKind::Upgrade {
        profile.as_ref().and_then(|p| p.plan_expires_ts)
    } else {
        None
    };
    let (new_usd, new_idr) = apply_immediate_plan(
        &mut tx,
        owner_iid,
        account_id,
        &slug,
        billing_period,
        &billing_currency,
        &limits,
        charge_idr,
        charge_usd,
        balance_usd,
        balance_idr,
        use_idr,
        keep_expires,
    )
    .await?;

    tx.commit().await.map_err(|e| e.to_string())?;

    if charge_idr > 0.0 || charge_usd > 0.0 {
        let purchase_id = format!("plan:{owner_iid}:{slug}:{}", Utc::now().timestamp());
        let commission_idr = if use_idr {
            charge_idr.round() as i64
        } else {
            (charge_usd * 17_630.0).round() as i64
        };
        let _ = c35_mod_referral::commission_accrue_on_purchase(
            pool,
            owner_iid,
            commission_idr,
            &purchase_id,
            "plan_subscribe",
        )
        .await;
    }

    let expires_ms = keep_expires
        .or_else(|| Some(plan_expires_from_period(billing_period)))
        .map(|t| t.timestamp_millis())
        .unwrap_or(0);

    Ok(ResBillingPlanChange {
        plan_tier: slug,
        balance_usd: new_usd,
        balance_idr: new_idr,
        alien_allow_5h_limit: limits.alien_5h,
        alien_allow_weekly_limit: limits.alien_week,
        pending_plan_slug: String::new(),
        plan_expires_ts_ms: expires_ms,
        change_kind: calc.kind.as_str().into(),
        pending_billing_period: String::new(),
    })
}

pub async fn billing_plan_subscribe(
    pool: &PgPool,
    owner_iid: i64,
    req: ReqBillingPlanSubscribe,
) -> Result<ResBillingPlanSubscribe, String> {
    let change = billing_plan_change(
        pool,
        owner_iid,
        ReqBillingPlanChange {
            plan_slug: req.plan_slug,
            billing_period: req.billing_period,
            currency: req.currency,
        },
    )
    .await?;
    Ok(ResBillingPlanSubscribe {
        plan_tier: change.plan_tier,
        balance_usd: change.balance_usd,
        balance_idr: change.balance_idr,
        alien_allow_5h_limit: change.alien_allow_5h_limit,
        alien_allow_weekly_limit: change.alien_allow_weekly_limit,
        pending_plan_slug: change.pending_plan_slug,
        plan_expires_ts_ms: change.plan_expires_ts_ms,
        change_kind: change.change_kind,
    })
}

/// At period end: apply pending downgrade or renew pending paid tier from wallet.
pub async fn billing_plan_pending_apply(pool: &PgPool, owner_iid: i64) -> Result<bool, String> {
    let profile = profile_sub_fetch(pool, owner_iid).await?;
    let Some(p) = profile else {
        return Ok(false);
    };
    let Some(pending) = p.pending_plan_slug.clone() else {
        return Ok(false);
    };
    if pending.eq_ignore_ascii_case("free") {
        return Ok(false);
    }
    let period = p
        .pending_billing_period
        .as_deref()
        .map(normalize_billing_period)
        .unwrap_or(normalize_billing_period(&p.billing_period));
    let _ = billing_plan_change(
        pool,
        owner_iid,
        ReqBillingPlanChange {
            plan_slug: pending,
            billing_period: period.to_string(),
            currency: "IDR".into(),
        },
    )
    .await?;
    Ok(true)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tier_rank_order() {
        assert!(tier_rank("plus") > tier_rank("lite"));
        assert!(tier_rank("ultra") > tier_rank("pro"));
    }

    #[test]
    fn cancel_slugs() {
        assert!(plan_cancel_slug("none"));
        assert!(plan_cancel_slug("no_plan"));
    }

    #[test]
    fn yearly_alien_bonus() {
        assert_eq!(alien_yearly_multiplier("yearly"), YEARLY_ALIEN_BONUS);
        assert_eq!(alien_yearly_multiplier("monthly"), 1.0);
    }
}
