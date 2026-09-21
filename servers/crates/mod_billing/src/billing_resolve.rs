use anyhow::Result;
use chrono::{Duration, Utc};
use sqlx::PgPool;

use crate::billing_turn::{billing_account_ensure, billing_deduct, BillingRow};

#[derive(Debug, Clone)]
pub struct TurnBillingCtx {
    pub owner_iid: i64,
    pub bot_iid: Option<i64>,
    pub device_iid: Option<i64>,
}

#[derive(Debug, Clone)]
pub struct BillingContext {
    pub scope: String,
    pub plan_slug: String,
    pub owner_iid: i64,
    pub scope_iid: i64,
    pub billing_account_id: i64,
    pub subscription_id: Option<i64>,
    pub msgs_used: i32,
    pub msgs_limit: i32,
}

#[derive(Debug, Clone)]
struct SubRow {
    id: i64,
    plan_slug: String,
    alien_allow_5h_used: String,
    alien_allow_5h_limit: String,
    alien_allow_weekly_used: String,
    alien_allow_weekly_limit: String,
    msgs_used: i32,
    msgs_limit: i32,
    window_5h_start: chrono::DateTime<Utc>,
    window_weekly_start: chrono::DateTime<Utc>,
    window_month_start: chrono::DateTime<Utc>,
}

fn f(s: String) -> f64 {
    s.parse().unwrap_or(0.0)
}

async fn subscription_fetch(pool: &PgPool, scope: &str, scope_iid: i64) -> Result<Option<SubRow>> {
    let row = sqlx::query_as::<_, (
        i64, String, String, String, String, String, i32, i32,
        chrono::DateTime<Utc>, chrono::DateTime<Utc>, chrono::DateTime<Utc>,
    )>(
        r#"
        SELECT id, plan_slug,
               alien_allow_5h_used::text, alien_allow_5h_limit::text,
               alien_allow_weekly_used::text, alien_allow_weekly_limit::text,
               msgs_used, msgs_limit,
               window_5h_start, window_weekly_start, window_month_start
        FROM ai.billing_subscription
        WHERE scope = $1 AND scope_iid = $2 AND deleted_ts IS NULL
          AND (expires_ts IS NULL OR expires_ts > NOW())
        LIMIT 1
        "#,
    )
    .bind(scope)
    .bind(scope_iid)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(|(id, plan_slug, u5, l5, uw, lw, msgs_used, msgs_limit, w5, ww, wm)| SubRow {
        id,
        plan_slug,
        alien_allow_5h_used: u5,
        alien_allow_5h_limit: l5,
        alien_allow_weekly_used: uw,
        alien_allow_weekly_limit: lw,
        msgs_used,
        msgs_limit,
        window_5h_start: w5,
        window_weekly_start: ww,
        window_month_start: wm,
    }))
}

async fn subscription_windows_roll(pool: &PgPool, mut row: SubRow) -> Result<SubRow> {
    let now = Utc::now();
    let mut sql = "UPDATE ai.billing_subscription SET updated_ts = NOW()".to_string();
    if now - row.window_5h_start >= Duration::hours(5) {
        sql.push_str(", alien_allow_5h_used = 0, window_5h_start = NOW()");
        row.alien_allow_5h_used = "0".into();
        row.window_5h_start = now;
    }
    if now - row.window_weekly_start >= Duration::days(7) {
        sql.push_str(", alien_allow_weekly_used = 0, window_weekly_start = NOW()");
        row.alien_allow_weekly_used = "0".into();
        row.window_weekly_start = now;
    }
    if now - row.window_month_start >= Duration::days(30) {
        sql.push_str(", msgs_used = 0, window_month_start = NOW()");
        row.msgs_used = 0;
        row.window_month_start = now;
    }
    sql.push_str(" WHERE id = $1");
    sqlx::query(&sql).bind(row.id).execute(pool).await?;
    Ok(row)
}

pub async fn billing_resolve(pool: &PgPool, ctx: TurnBillingCtx) -> Result<BillingContext> {
    let personal = billing_account_ensure(pool, ctx.owner_iid).await?;
    if let Some(bot_iid) = ctx.bot_iid.filter(|id| *id > 0) {
        if let Some(sub) = subscription_fetch(pool, "bot", bot_iid).await? {
            let sub = subscription_windows_roll(pool, sub).await?;
            if sub.msgs_limit > 0 && sub.msgs_used >= sub.msgs_limit {
                anyhow::bail!("bot message quota exceeded");
            }
            return Ok(BillingContext {
                scope: "bot".into(),
                plan_slug: sub.plan_slug,
                owner_iid: ctx.owner_iid,
                scope_iid: bot_iid,
                billing_account_id: personal.id,
                subscription_id: Some(sub.id),
                msgs_used: sub.msgs_used,
                msgs_limit: sub.msgs_limit,
            });
        }
    }
    if let Some(device_iid) = ctx.device_iid.filter(|id| *id > 0) {
        if let Some(sub) = subscription_fetch(pool, "device", device_iid).await? {
            let sub = subscription_windows_roll(pool, sub).await?;
            return Ok(BillingContext {
                scope: "device".into(),
                plan_slug: sub.plan_slug,
                owner_iid: ctx.owner_iid,
                scope_iid: device_iid,
                billing_account_id: personal.id,
                subscription_id: Some(sub.id),
                msgs_used: sub.msgs_used,
                msgs_limit: sub.msgs_limit,
            });
        }
    }
    Ok(BillingContext {
        scope: "personal".into(),
        plan_slug: personal.plan_tier.clone(),
        owner_iid: ctx.owner_iid,
        scope_iid: ctx.owner_iid,
        billing_account_id: personal.id,
        subscription_id: None,
        msgs_used: 0,
        msgs_limit: 0,
    })
}

pub async fn billing_gate_scoped(pool: &PgPool, bctx: &BillingContext) -> Result<BillingRow> {
    if bctx.scope == "personal" {
        return crate::billing_turn::billing_gate(pool, bctx.owner_iid).await;
    }
    if let Some(sub_id) = bctx.subscription_id {
        let sub = subscription_fetch(pool, &bctx.scope, bctx.scope_iid)
            .await?
            .ok_or_else(|| anyhow::anyhow!("subscription missing"))?;
        let sub = subscription_windows_roll(pool, sub).await?;
        let u5 = f(sub.alien_allow_5h_used);
        let l5 = f(sub.alien_allow_5h_limit);
        let uw = f(sub.alien_allow_weekly_used);
        let lw = f(sub.alien_allow_weekly_limit);
        if u5 < l5 && uw < lw {
            return billing_account_ensure(pool, bctx.owner_iid).await;
        }
        let personal = billing_account_ensure(pool, bctx.owner_iid).await?;
        if personal.balance_usd > 0.0
            || personal.alien_allow_5h_used < personal.alien_allow_5h_limit
        {
            return Ok(personal);
        }
        let _ = sub_id;
        anyhow::bail!("scoped quota exceeded");
    }
    billing_gate(pool, bctx.owner_iid).await
}

async fn billing_gate(pool: &PgPool, owner_iid: i64) -> Result<BillingRow> {
    crate::billing_turn::billing_gate(pool, owner_iid).await
}

pub async fn billing_deduct_scoped(pool: &PgPool, bctx: &BillingContext, cost_usd: f64, model: &str) -> Result<()> {
    if cost_usd <= 0.0 {
        return Ok(());
    }
    if let Some(sub_id) = bctx.subscription_id {
        if model == "alienai" || model.is_empty() {
            if let Some(sub) = subscription_fetch(pool, &bctx.scope, bctx.scope_iid).await? {
                let sub = subscription_windows_roll(pool, sub).await?;
                let u5 = f(sub.alien_allow_5h_used);
                let l5 = f(sub.alien_allow_5h_limit);
                let uw = f(sub.alien_allow_weekly_used);
                let lw = f(sub.alien_allow_weekly_limit);
                if u5 + cost_usd <= l5 || uw + cost_usd <= lw {
                    sqlx::query(
                        r#"
                        UPDATE ai.billing_subscription SET
                            alien_allow_5h_used = alien_allow_5h_used + $2,
                            alien_allow_weekly_used = alien_allow_weekly_used + $2,
                            msgs_used = msgs_used + 1,
                            updated_ts = NOW()
                        WHERE id = $1
                        "#,
                    )
                    .bind(sub_id)
                    .bind(cost_usd)
                    .execute(pool)
                    .await?;
                    return Ok(());
                }
            }
        }
    }
    billing_deduct(pool, bctx.owner_iid, cost_usd).await?;
    Ok(())
}
