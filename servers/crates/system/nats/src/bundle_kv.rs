use anyhow::Context as _;
use async_nats::jetstream::{self, kv::Store};
use async_nats::Client;
use c35_proto::{ScopeInstructionBundle, UserMemoryBundle};
use prost::Message;
use std::time::Duration;

pub const MEMORY_BUNDLE_KV_BUCKET: &str = "c35_user_memory_cache";
pub const SCOPE_INST_KV_BUCKET: &str = "c35_scope_inst_cache";
pub const BUNDLE_CACHE_TTL_SECS: u64 = 3600; // 1 hour

pub fn memory_bundle_kv_key(owner_iid: i64, bot_iid: Option<i64>) -> String {
    match bot_iid.filter(|b| *b > 0) {
        Some(bid) => format!("mem_{owner_iid}_{bid}"),
        None => format!("mem_{owner_iid}_0"),
    }
}

pub fn scope_inst_kv_key(owner_iid: i64) -> String {
    format!("scope_{owner_iid}")
}

pub async fn memory_bundle_kv_ensure(client: &Client) -> anyhow::Result<Store> {
    let js = jetstream::new(client.clone());
    match js.get_key_value(MEMORY_BUNDLE_KV_BUCKET).await {
        Ok(store) => Ok(store),
        Err(_) => js
            .create_key_value(jetstream::kv::Config {
                bucket: MEMORY_BUNDLE_KV_BUCKET.into(),
                history: 1,
                max_age: Duration::from_secs(BUNDLE_CACHE_TTL_SECS),
                ..Default::default()
            })
            .await
            .context("create c35_user_memory_cache KV"),
    }
}

pub async fn scope_inst_kv_ensure(client: &Client) -> anyhow::Result<Store> {
    let js = jetstream::new(client.clone());
    match js.get_key_value(SCOPE_INST_KV_BUCKET).await {
        Ok(store) => Ok(store),
        Err(_) => js
            .create_key_value(jetstream::kv::Config {
                bucket: SCOPE_INST_KV_BUCKET.into(),
                history: 1,
                max_age: Duration::from_secs(BUNDLE_CACHE_TTL_SECS),
                ..Default::default()
            })
            .await
            .context("create c35_scope_inst_cache KV"),
    }
}

pub async fn memory_bundle_get(store: &Store, owner_iid: i64, bot_iid: Option<i64>) -> Option<UserMemoryBundle> {
    let key = memory_bundle_kv_key(owner_iid, bot_iid);
    let Ok(Some(bytes)) = store.get(&key).await else {
        return None;
    };
    UserMemoryBundle::decode(bytes.as_ref()).ok()
}

pub async fn memory_bundle_put(store: &Store, bundle: &UserMemoryBundle) -> anyhow::Result<()> {
    let bot_iid = (bundle.bot_iid > 0).then_some(bundle.bot_iid);
    let key = memory_bundle_kv_key(bundle.owner_iid, bot_iid);
    let bytes = bundle.encode_to_vec();
    store.put(&key, bytes.into()).await?;
    Ok(())
}

pub async fn memory_bundle_delete(store: &Store, owner_iid: i64, bot_iid: Option<i64>) -> anyhow::Result<()> {
    let key = memory_bundle_kv_key(owner_iid, bot_iid);
    let _ = store.delete(&key).await;
    Ok(())
}

pub async fn scope_inst_bundle_get(store: &Store, owner_iid: i64) -> Option<ScopeInstructionBundle> {
    let key = scope_inst_kv_key(owner_iid);
    let Ok(Some(bytes)) = store.get(&key).await else {
        return None;
    };
    ScopeInstructionBundle::decode(bytes.as_ref()).ok()
}

pub async fn scope_inst_bundle_put(store: &Store, bundle: &ScopeInstructionBundle) -> anyhow::Result<()> {
    let key = scope_inst_kv_key(bundle.owner_iid);
    let bytes = bundle.encode_to_vec();
    store.put(&key, bytes.into()).await?;
    Ok(())
}

pub async fn scope_inst_bundle_delete(store: &Store, owner_iid: i64) -> anyhow::Result<()> {
    let key = scope_inst_kv_key(owner_iid);
    let _ = store.delete(&key).await;
    Ok(())
}
