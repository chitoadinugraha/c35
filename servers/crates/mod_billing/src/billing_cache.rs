use async_nats::Client;
use chrono::Utc;

use c35_nats::{
    billing_kv_delete, billing_kv_ensure, billing_kv_get, billing_kv_put, BillingGateCached,
};

use crate::billing_turn::BillingRow;

pub async fn billing_cache_get(
    nats: Option<&Client>,
    owner_iid: i64,
) -> Option<BillingGateCached> {
    let client = nats?;
    let store = billing_kv_ensure(client).await.ok()?;
    billing_kv_get(&store, owner_iid).await
}

pub async fn billing_cache_put(
    nats: Option<&Client>,
    entry: &BillingGateCached,
) {
    let Some(client) = nats else { return };
    if let Ok(store) = billing_kv_ensure(client).await {
        let _ = billing_kv_put(&store, entry).await;
    }
}

pub async fn billing_cache_invalidate(
    nats: Option<&Client>,
    owner_iid: i64,
) {
    let Some(client) = nats else { return };
    if let Ok(store) = billing_kv_ensure(client).await {
        let _ = billing_kv_delete(&store, owner_iid).await;
    }
}

pub fn cached_to_billing_row(cached: &BillingGateCached) -> BillingRow {
    BillingRow {
        id: cached.billing_account_id,
        owner_iid: cached.owner_iid,
        plan_tier: cached.plan_tier.clone(),
        balance_usd: cached.balance_usd,
        alien_allow_5h_used: cached.alien_allow_5h_used,
        alien_allow_5h_limit: cached.alien_allow_5h_limit,
        alien_allow_weekly_used: cached.alien_allow_weekly_used,
        alien_allow_weekly_limit: cached.alien_allow_weekly_limit,
        window_5h_start: Utc::now(),
        window_weekly_start: Utc::now(),
    }
}

pub fn evaluate_allowance_sufficient(
    row: &BillingRow,
    is_freemium: bool,
    profile_remaining_usd: f64,
) -> bool {
    if is_freemium {
        return true;
    }
    if profile_remaining_usd >= 0.05 {
        return true;
    }
    if row.balance_usd >= 0.50 {
        return true;
    }
    let rem_5h = (row.alien_allow_5h_limit - row.alien_allow_5h_used).max(0.0);
    let rem_weekly = (row.alien_allow_weekly_limit - row.alien_allow_weekly_used).max(0.0);
    rem_5h >= 0.05 && rem_weekly >= 0.05
}

/// Asynchronously warm up the billing cache into NATS KV on user connection.
/// Runs concurrently on a background task without blocking session initialization or login.
pub async fn billing_cache_warmup(
    pool: &sqlx::PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
) {
    if owner_iid <= 0 {
        return;
    }
    // If already warm in NATS KV, no DB work needed.
    if billing_cache_get(nats, owner_iid).await.is_some() {
        return;
    }

    let account_fut = sqlx::query(
        r#"
        SELECT id, COALESCE(plan_tier, 'free') AS plan_tier,
               balance_usd::float8 AS balance_usd
        FROM ai.billing_account
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(owner_iid)
    .fetch_optional(pool);

    let profile_fut = sqlx::query(
        r#"
        SELECT COALESCE(alien_allow_5h_used::float8, 0.0) AS alien_allow_5h_used,
               COALESCE(alien_allow_5h_limit::float8, 0.0) AS alien_allow_5h_limit,
               COALESCE(alien_allow_weekly_used::float8, 0.0) AS alien_allow_weekly_used,
               COALESCE(alien_allow_weekly_limit::float8, 0.0) AS alien_allow_weekly_limit
        FROM ai.billing_profile
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(owner_iid)
    .fetch_optional(pool);

    let profile_rings_fut = crate::billing_profile::billing_profile_fetch(pool, owner_iid);

    let freemium_fut = crate::billing_freemium::billing_freemium_applies(pool, owner_iid);

    let (acc_res, prof_res, rings_res, free_res) =
        tokio::join!(account_fut, profile_fut, profile_rings_fut, freemium_fut);
    let row = match acc_res {
        Ok(Some(r)) => r,
        _ => return,
    };
    use sqlx::Row;
    let account_id: i64 = row.get("id");
    let plan_tier: String = row.get("plan_tier");
    let balance_usd: f64 = row.get("balance_usd");
    let is_freemium = free_res.unwrap_or(false);

    let profile_remaining_usd = match rings_res {
        Ok(Some(profile)) if crate::billing_profile::profile_has_rings(&profile) => {
            let (alien, frontier) =
                crate::billing_profile::profile_ring_remaining_usd(&profile.rings);
            alien + frontier
        }
        _ => 0.0,
    };

    let (allow_5h_used, allow_5h_limit, allow_weekly_used, allow_weekly_limit) = match prof_res {
        Ok(Some(p)) => (
            p.get::<f64, _>("alien_allow_5h_used"),
            p.get::<f64, _>("alien_allow_5h_limit"),
            p.get::<f64, _>("alien_allow_weekly_used"),
            p.get::<f64, _>("alien_allow_weekly_limit"),
        ),
        _ => (0.0, 0.0, 0.0, 0.0),
    };

    let brow_temp = BillingRow {
        id: account_id,
        owner_iid,
        plan_tier: plan_tier.clone(),
        balance_usd,
        alien_allow_5h_used: allow_5h_used,
        alien_allow_5h_limit: allow_5h_limit,
        alien_allow_weekly_used: allow_weekly_used,
        alien_allow_weekly_limit: allow_weekly_limit,
        window_5h_start: Utc::now(),
        window_weekly_start: Utc::now(),
    };
    let has_sufficient =
        evaluate_allowance_sufficient(&brow_temp, is_freemium, profile_remaining_usd);
    billing_cache_put(
        nats,
        &BillingGateCached {
            owner_iid,
            billing_account_id: account_id,
            plan_tier,
            is_freemium,
            has_sufficient_allowance: has_sufficient,
            balance_usd,
            alien_allow_5h_used: allow_5h_used,
            alien_allow_5h_limit: allow_5h_limit,
            alien_allow_weekly_used: allow_weekly_used,
            alien_allow_weekly_limit: allow_weekly_limit,
            cached_at_secs: Utc::now().timestamp(),
        },
    )
    .await;
}
