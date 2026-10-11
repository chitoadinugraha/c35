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
