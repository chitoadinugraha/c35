use c35_proto::{BillingPlanDoc, ResBillingSummary};
use sqlx::{PgPool, Row};

const MICRO_PER_USD: f64 = 1_000_000.0;

pub async fn billing_summary(pool: &PgPool, caller_iid: i64, billing_account_id: i64) -> ResBillingSummary {
    let plans = billing_plan_list(pool).await.unwrap_or_default();
    let account_id = if billing_account_id > 0 {
        billing_account_id
    } else {
        match sqlx::query_scalar::<_, i64>(
            r#"SELECT billing_iid FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL"#,
        )
        .bind(caller_iid)
        .fetch_optional(pool)
        .await
        .ok()
        .flatten()
        {
            Some(id) if id > 0 => id,
            _ => return billing_summary_default(plans),
        }
    };

    let row = sqlx::query(
        r#"
        SELECT b.balance_usd::float8 AS balance_usd,
               COALESCE(b.balance_idr::float8, 0.0) AS balance_idr,
               COALESCE(b.plan_tier, 'free') AS plan_tier,
               COALESCE(b.alien_allow_5h_used::float8, 0.0) AS alien_5h_used,
               COALESCE(b.alien_allow_5h_limit::float8, 0.05) AS alien_5h_limit,
               COALESCE(b.alien_allow_weekly_used::float8, 0.0) AS alien_week_used,
               COALESCE(b.alien_allow_weekly_limit::float8, 1.0) AS alien_week_limit,
               COALESCE(b.commission_available_usd::float8, 0.0) AS commission_available_usd,
               COALESCE(b.commission_available_idr::float8, 0.0) AS commission_available_idr,
               COALESCE(p.overage_enabled, FALSE) AS overage_enabled,
               b.window_5h_start,
               b.window_weekly_start
        FROM ai.billing_account b
        LEFT JOIN ai.billing_plan p ON p.slug = b.plan_tier AND p.scope = 'user'
        WHERE b.id = $1 AND b.owner_iid = $2 AND b.deleted_ts IS NULL
        "#,
    )
    .bind(account_id)
    .bind(caller_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();

    let Some(row) = row else {
        return billing_summary_default(plans);
    };

    let alien_5h_used: f64 = row.get("alien_5h_used");
    let alien_5h_limit: f64 = row.get("alien_5h_limit");
    let alien_week_used: f64 = row.get("alien_week_used");
    let alien_week_limit: f64 = row.get("alien_week_limit");
    let (quota_5h_used, quota_5h_limit) = allow_to_micro(alien_5h_used, alien_5h_limit);
    let (quota_weekly_used, quota_weekly_limit) = allow_to_micro(alien_week_used, alien_week_limit);
    let meter_state = allow_meter_state(alien_5h_used, alien_5h_limit);
    let window_5h_start: chrono::DateTime<chrono::Utc> = row.get("window_5h_start");
    let window_weekly_start: chrono::DateTime<chrono::Utc> = row.get("window_weekly_start");

    ResBillingSummary {
        balance_usd: row.get("balance_usd"),
        plan_tier: row.get("plan_tier"),
        quota_5h_used,
        quota_5h_limit,
        window_5h_resets_at_ms: (window_5h_start + chrono::Duration::hours(5)).timestamp_millis(),
        meter_state,
        bots_paused: alien_5h_limit > 0.0 && alien_5h_used >= alien_5h_limit * 0.9,
        quota_weekly_used,
        quota_weekly_limit,
        window_weekly_resets_at_ms: (window_weekly_start + chrono::Duration::days(7)).timestamp_millis(),
        balance_idr: row.get("balance_idr"),
        commission_available_usd: row.get("commission_available_usd"),
        commission_available_idr: row.get("commission_available_idr"),
        alien_allow_5h_used: alien_5h_used,
        alien_allow_5h_limit: alien_5h_limit,
        alien_allow_weekly_used: alien_week_used,
        alien_allow_weekly_limit: alien_week_limit,
        plans,
        overage_enabled: row.get("overage_enabled"),
    }
}

async fn billing_plan_list(pool: &PgPool) -> Result<Vec<BillingPlanDoc>, sqlx::Error> {
    let rows = sqlx::query(
        r#"
        SELECT p.slug, p.name, p.sort_order, p.price_usd::float8 AS price_usd, p.duration_months,
               p.alien_allow_5h_usd::float8 AS alien_allow_5h_usd,
               p.alien_allow_weekly_usd::float8 AS alien_allow_weekly_usd,
               p.msgs_limit, p.channels_limit, p.concurrent_limit, p.overage_enabled,
               COALESCE(p.alien_pool_idr_monthly::float8, 0.0) AS alien_pool_idr_monthly,
               COALESCE(p.frontier_pool_idr_monthly::float8, 0.0) AS frontier_pool_idr_monthly,
               COALESCE(p.pool_multiplier::float8, 1.0) AS pool_multiplier,
               COALESCE(p.tier, '') AS tier,
               COALESCE((p.caps_json->>'priority_queue')::boolean, FALSE) AS priority_queue,
               COALESCE(
                   NULLIF((p.caps_json->>'queue_priority_multiplier')::int, 0),
                   CASE p.slug WHEN 'pro' THEN 5 WHEN 'ultra' THEN 30 ELSE 0 END
               ) AS queue_priority_multiplier,
               COALESCE(
                   (SELECT amount::float8 FROM ai.billing_plan_price
                    WHERE plan_slug = p.slug AND currency = 'IDR' AND billing_period = 'monthly' AND is_active = TRUE
                    LIMIT 1),
                   0.0
               ) AS price_idr_monthly,
               COALESCE(
                   (SELECT amount::float8 FROM ai.billing_plan_price
                    WHERE plan_slug = p.slug AND currency = 'IDR' AND billing_period = 'yearly' AND is_active = TRUE
                    LIMIT 1),
                   0.0
               ) AS price_idr_yearly
        FROM ai.billing_plan p
        WHERE p.is_active = TRUE AND p.scope = 'user'
        ORDER BY p.sort_order ASC, p.slug ASC
        "#,
    )
    .fetch_all(pool)
    .await?;

    Ok(rows
        .into_iter()
        .map(|r| BillingPlanDoc {
            slug: r.get("slug"),
            name: r.get("name"),
            sort_order: r.get("sort_order"),
            price_usd: r.get("price_usd"),
            duration_months: r.get("duration_months"),
            alien_allow_5h_usd: r.get("alien_allow_5h_usd"),
            alien_allow_weekly_usd: r.get("alien_allow_weekly_usd"),
            msgs_limit: r.get("msgs_limit"),
            channels_limit: r.get("channels_limit"),
            concurrent_limit: r.get("concurrent_limit"),
            overage_enabled: r.get("overage_enabled"),
            price_idr_monthly: r.get("price_idr_monthly"),
            price_idr_yearly: r.get("price_idr_yearly"),
            alien_pool_idr_monthly: r.get("alien_pool_idr_monthly"),
            frontier_pool_idr_monthly: r.get("frontier_pool_idr_monthly"),
            pool_multiplier: r.get("pool_multiplier"),
            tier: r.get("tier"),
            queue_priority_multiplier: r.get("queue_priority_multiplier"),
            priority_queue: r.get("priority_queue"),
        })
        .collect())
}

fn allow_to_micro(used: f64, limit: f64) -> (i32, i32) {
    (
        (used * MICRO_PER_USD).round() as i32,
        (limit * MICRO_PER_USD).round() as i32,
    )
}

fn allow_meter_state(used: f64, limit: f64) -> String {
    if limit <= 0.0 {
        return "green".into();
    }
    let pct = used / limit;
    if pct >= 0.9 {
        "red".into()
    } else if pct >= 0.8 {
        "orange".into()
    } else {
        "green".into()
    }
}

fn billing_summary_default(plans: Vec<BillingPlanDoc>) -> ResBillingSummary {
    let now = chrono::Utc::now();
    ResBillingSummary {
        balance_usd: 0.0,
        plan_tier: "free".into(),
        quota_5h_used: 0,
        quota_5h_limit: 50_000,
        window_5h_resets_at_ms: (now + chrono::Duration::hours(5)).timestamp_millis(),
        meter_state: "green".into(),
        bots_paused: false,
        quota_weekly_used: 0,
        quota_weekly_limit: 1_000_000,
        window_weekly_resets_at_ms: (now + chrono::Duration::days(7)).timestamp_millis(),
        balance_idr: 0.0,
        commission_available_usd: 0.0,
        commission_available_idr: 0.0,
        alien_allow_5h_used: 0.0,
        alien_allow_5h_limit: 0.05,
        alien_allow_weekly_used: 0.0,
        alien_allow_weekly_limit: 1.0,
        plans,
        overage_enabled: false,
    }
}
