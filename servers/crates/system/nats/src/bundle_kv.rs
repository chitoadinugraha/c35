use anyhow::Context as _;
use async_nats::jetstream::{self, kv::Store};
use async_nats::Client;
use c35_proto::{HintCatalog, ScopeInstructionBundle, UserMemoryBundle};
use prost::Message;
use std::time::Duration;

pub const MEMORY_BUNDLE_KV_BUCKET: &str = "c35_user_memory_cache";
pub const SCOPE_INST_KV_BUCKET: &str = "c35_scope_inst_cache";
/// KV entry TTL (refreshed on each put). Active users stay warm via turn writes and connect warmup.
pub const BUNDLE_CACHE_TTL_SECS: u64 = 86_400; // 24 hours
/// After the last WebSocket disconnect, keep bundles in KV this long before purge.
pub const PROMPT_BUNDLE_DISCONNECT_GRACE_SECS: u64 = 86_400; // 24 hours

pub const PROMPT_BUNDLE_SESSION_KV_BUCKET: &str = "c35_prompt_bundle_session";

pub fn prompt_bundle_disconnect_grace_secs() -> u64 {
    std::env::var("C35_PROMPT_BUNDLE_DISCONNECT_GRACE_SECS")
        .ok()
        .and_then(|v| v.parse().ok())
        .filter(|&s| s > 0)
        .unwrap_or(PROMPT_BUNDLE_DISCONNECT_GRACE_SECS)
}

#[derive(Clone, Copy, Debug, Default)]
pub struct PromptBundleSession {
    pub connections: u32,
    /// Unix ms; when > 0 and connections == 0, purge bundles after this time.
    pub purge_after_ms: i64,
}

pub fn prompt_bundle_session_encode(s: PromptBundleSession) -> Vec<u8> {
    let mut b = [0u8; 12];
    b[0..4].copy_from_slice(&s.connections.to_le_bytes());
    b[4..12].copy_from_slice(&s.purge_after_ms.to_le_bytes());
    b.to_vec()
}

pub fn prompt_bundle_session_decode(bytes: &[u8]) -> Option<PromptBundleSession> {
    if bytes.len() < 12 {
        return None;
    }
    let connections = u32::from_le_bytes(bytes[0..4].try_into().ok()?);
    let purge_after_ms = i64::from_le_bytes(bytes[4..12].try_into().ok()?);
    Some(PromptBundleSession {
        connections,
        purge_after_ms,
    })
}

pub async fn prompt_bundle_session_kv_ensure(client: &Client) -> anyhow::Result<Store> {
    let js = jetstream::new(client.clone());
    match js.get_key_value(PROMPT_BUNDLE_SESSION_KV_BUCKET).await {
        Ok(store) => Ok(store),
        Err(_) => js
            .create_key_value(jetstream::kv::Config {
                bucket: PROMPT_BUNDLE_SESSION_KV_BUCKET.into(),
                history: 1,
                max_age: Duration::from_secs(BUNDLE_CACHE_TTL_SECS),
                ..Default::default()
            })
            .await
            .context("create c35_prompt_bundle_session KV"),
    }
}

pub fn prompt_bundle_session_kv_key(owner_iid: i64) -> String {
    format!("sess_{owner_iid}")
}

pub async fn prompt_bundle_session_get(store: &Store, owner_iid: i64) -> PromptBundleSession {
    let key = prompt_bundle_session_kv_key(owner_iid);
    let Ok(Some(bytes)) = store.get(&key).await else {
        return PromptBundleSession::default();
    };
    prompt_bundle_session_decode(bytes.as_ref()).unwrap_or_default()
}

pub async fn prompt_bundle_session_put(store: &Store, owner_iid: i64, session: PromptBundleSession) -> anyhow::Result<()> {
    let key = prompt_bundle_session_kv_key(owner_iid);
    store
        .put(&key, prompt_bundle_session_encode(session).into())
        .await?;
    Ok(())
}

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

pub const DEVICE_PRESENCE_KV_BUCKET: &str = "c35_device_presence";
pub const DEVICE_PRESENCE_TTL_SECS: u64 = 30; // 30 seconds

pub fn device_presence_kv_key(device_iid: i64) -> String {
    format!("dev_{device_iid}")
}

pub async fn device_presence_kv_ensure(client: &Client) -> anyhow::Result<Store> {
    let js = jetstream::new(client.clone());
    match js.get_key_value(DEVICE_PRESENCE_KV_BUCKET).await {
        Ok(store) => Ok(store),
        Err(_) => js
            .create_key_value(jetstream::kv::Config {
                bucket: DEVICE_PRESENCE_KV_BUCKET.into(),
                history: 1,
                max_age: Duration::from_secs(DEVICE_PRESENCE_TTL_SECS),
                ..Default::default()
            })
            .await
            .context("create c35_device_presence KV"),
    }
}

pub async fn device_presence_put(store: &Store, device_iid: i64) -> anyhow::Result<()> {
    let key = device_presence_kv_key(device_iid);
    store.put(&key, "online".into()).await?;
    Ok(())
}

pub async fn device_presence_get(store: &Store, device_iid: i64) -> bool {
    let key = device_presence_kv_key(device_iid);
    matches!(store.get(&key).await, Ok(Some(_)))
}

pub const HINT_BUNDLE_KV_BUCKET: &str = "c35_hint_bundle_cache";

pub fn hint_bundle_kv_key(user_iid: i64, lang: &str) -> String {
    format!("hint_{user_iid}_{lang}")
}

pub async fn hint_bundle_kv_ensure(client: &Client) -> anyhow::Result<Store> {
    let js = jetstream::new(client.clone());
    match js.get_key_value(HINT_BUNDLE_KV_BUCKET).await {
        Ok(store) => Ok(store),
        Err(_) => js
            .create_key_value(jetstream::kv::Config {
                bucket: HINT_BUNDLE_KV_BUCKET.into(),
                history: 1,
                max_age: Duration::from_secs(BUNDLE_CACHE_TTL_SECS),
                ..Default::default()
            })
            .await
            .context("create c35_hint_bundle_cache KV"),
    }
}

pub async fn hint_bundle_cache_get(store: &Store, user_iid: i64, lang: &str) -> Option<HintCatalog> {
    let key = hint_bundle_kv_key(user_iid, lang);
    let Ok(Some(bytes)) = store.get(&key).await else {
        return None;
    };
    HintCatalog::decode(bytes.as_ref()).ok()
}

pub async fn hint_bundle_cache_put(store: &Store, user_iid: i64, lang: &str, catalog: &HintCatalog) -> anyhow::Result<()> {
    let key = hint_bundle_kv_key(user_iid, lang);
    let bytes = catalog.encode_to_vec();
    store.put(&key, bytes.into()).await?;
    Ok(())
}

pub async fn hint_bundle_cache_delete(store: &Store, user_iid: i64) -> anyhow::Result<()> {
    for lang in &["en", "id"] {
        let key = hint_bundle_kv_key(user_iid, lang);
        let _ = store.delete(&key).await;
    }
    Ok(())
}


