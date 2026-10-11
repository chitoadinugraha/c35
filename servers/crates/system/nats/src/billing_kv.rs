use anyhow::Context as _;
use async_nats::jetstream::{self, kv::Store};
use async_nats::Client;
use serde::{Deserialize, Serialize};
use std::time::Duration;

pub const BILLING_KV_BUCKET: &str = "c35_billing_cache";
pub const BILLING_CACHE_TTL_SECS: u64 = 30;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BillingGateCached {
    pub owner_iid: i64,
    pub billing_account_id: i64,
    pub plan_tier: String,
    pub is_freemium: bool,
    pub has_sufficient_allowance: bool,
    pub balance_usd: f64,
    pub alien_allow_5h_used: f64,
    pub alien_allow_5h_limit: f64,
    pub alien_allow_weekly_used: f64,
    pub alien_allow_weekly_limit: f64,
    pub cached_at_secs: i64,
}

pub fn billing_kv_key_owner(owner_iid: i64) -> String {
    format!("user_{owner_iid}")
}

pub async fn billing_kv_ensure(client: &Client) -> anyhow::Result<Store> {
    let js = jetstream::new(client.clone());
    match js.get_key_value(BILLING_KV_BUCKET).await {
        Ok(store) => Ok(store),
        Err(_) => js
            .create_key_value(jetstream::kv::Config {
                bucket: BILLING_KV_BUCKET.into(),
                history: 1,
                max_age: Duration::from_secs(BILLING_CACHE_TTL_SECS),
                ..Default::default()
            })
            .await
            .context("create c35_billing_cache KV"),
    }
}

pub async fn billing_kv_get(store: &Store, owner_iid: i64) -> Option<BillingGateCached> {
    let key = billing_kv_key_owner(owner_iid);
    let Ok(Some(bytes)) = store.get(&key).await else {
        return None;
    };
    serde_json::from_slice(&bytes).ok()
}

pub async fn billing_kv_put(store: &Store, entry: &BillingGateCached) -> anyhow::Result<()> {
    let key = billing_kv_key_owner(entry.owner_iid);
    let bytes = serde_json::to_vec(entry)?;
    store.put(&key, bytes.into()).await?;
    Ok(())
}

pub async fn billing_kv_delete(store: &Store, owner_iid: i64) -> anyhow::Result<()> {
    let key = billing_kv_key_owner(owner_iid);
    let _ = store.delete(&key).await;
    Ok(())
}
