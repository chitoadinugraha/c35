use anyhow::Context as _;
use async_nats::jetstream::{self, kv::Store};
use async_nats::Client;
use c35_proto::{stats_push, StatsPush};
use futures_util::StreamExt;
use prost::Message as ProstMessage;
use tracing::warn;

pub const KV_BUCKET: &str = "c35_stats";

pub fn stats_kv_key_node(node_name: &str) -> String {
    format!("node/{node_name}")
}

pub fn stats_kv_key_volume(node_name: &str, namespace: &str, pvc_name: &str) -> String {
    format!("vol/{node_name}/{namespace}/{pvc_name}")
}

pub fn stats_kv_key_pod(node_name: &str, namespace: &str, pod_name: &str) -> String {
    format!("pod/{node_name}/{namespace}/{pod_name}")
}

pub fn stats_kv_key_platform_user_count() -> &'static str {
    "platform/user_count"
}

pub fn stats_kv_key_for_push(push: &StatsPush) -> Option<String> {
    match &push.body {
        Some(stats_push::Body::Node(n)) if !n.node_name.is_empty() => {
            Some(stats_kv_key_node(&n.node_name))
        }
        Some(stats_push::Body::Volume(v)) if !v.node_name.is_empty() && !v.pvc_name.is_empty() => {
            Some(stats_kv_key_volume(&v.node_name, &v.namespace, &v.pvc_name))
        }
        Some(stats_push::Body::Pod(p))
            if !p.node_name.is_empty() && !p.pod_name.is_empty() =>
        {
            Some(stats_kv_key_pod(&p.node_name, &p.namespace, &p.pod_name))
        }
        _ => None,
    }
}

pub async fn stats_kv_put_bytes(store: &Store, key: &str, bytes: &[u8]) -> anyhow::Result<()> {
    store.put(key, bytes.to_vec().into()).await?;
    Ok(())
}

pub async fn stats_kv_get_bytes(store: &Store, key: &str) -> Option<Vec<u8>> {
    let Ok(Some(bytes)) = store.get(key).await else {
        return None;
    };
    Some(bytes.to_vec())
}

pub async fn stats_kv_ensure(client: &Client) -> anyhow::Result<Store> {
    let js = jetstream::new(client.clone());
    match js.get_key_value(KV_BUCKET).await {
        Ok(store) => Ok(store),
        Err(_) => js
            .create_key_value(jetstream::kv::Config {
                bucket: KV_BUCKET.into(),
                history: 1,
                ..Default::default()
            })
            .await
            .context("create c35_stats KV"),
    }
}

pub async fn stats_kv_put(store: &Store, key: &str, push: &StatsPush) -> anyhow::Result<()> {
    let bytes = push.encode_to_vec();
    store.put(key, bytes.into()).await?;
    Ok(())
}

pub async fn stats_kv_get(store: &Store, key: &str) -> Option<StatsPush> {
    let Ok(Some(bytes)) = store.get(key).await else {
        return None;
    };
    decode_push(bytes.as_ref())
}

pub async fn stats_kv_list_pushes(store: &Store) -> Vec<StatsPush> {
    let Ok(mut keys) = store.keys().await else {
        return Vec::new();
    };
    let mut out = Vec::new();
    while let Some(key) = keys.next().await.transpose().ok().flatten() {
        if let Some(push) = stats_kv_get(store, &key).await {
            out.push(push);
        }
    }
    out
}

fn decode_push(bytes: &[u8]) -> Option<StatsPush> {
    match StatsPush::decode(bytes) {
        Ok(p) => Some(p),
        Err(e) => {
            warn!(error = %e, "stats KV decode failed");
            None
        }
    }
}