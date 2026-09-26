mod device;
mod host;
mod metric_rollup;
mod node;
mod sample;
mod volume;
mod volume_discover;

use std::path::Path;
use std::time::Duration;

use anyhow::{Context, Result};
use async_nats::jetstream::kv::Store;
use async_nats::Client;
use c35_nats::{stats_kv_ensure, stats_kv_key_node, stats_kv_key_volume, stats_kv_put};
use prost::Message;
use tracing::{info, warn};

use crate::metric_rollup::{pg_pool_from_env, MetricRollup};
use crate::node::{node_push, node_subject, NodeSampler};
use crate::volume::{sample_volume, volume_configs, volume_push, volume_subject, VolumeConfig};
use crate::volume_discover::{discover_namespace, merge_volume_configs, volume_discover};

const TICK: Duration = Duration::from_secs(2);
const DISCOVER_INTERVAL: Duration = Duration::from_secs(60);

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    let node_name = std::env::var("NODE_NAME").context("NODE_NAME required")?;
    let nats = nats_connect().await.context("NATS connect")?;
    let kv = stats_kv_ensure(&nats).await.context("stats KV ensure")?;
    let pool = pg_pool_from_env().await;
    let mut rollup = MetricRollup::new(node_name.clone(), pool);
    let mut sampler = NodeSampler::new(node_name.clone());
    let mut volumes = merge_volume_configs(volume_configs(), volume_discover(&node_name).await);
    let mut last_discover = std::time::Instant::now();

    info!(
        node = %node_name,
        mounts = %std::env::var("C35_NODE_MOUNTS").unwrap_or_else(|_| "/,/var/log".into()),
        volumes = volumes.len(),
        yb_rollup = std::env::var("DATABASE_URL").ok().is_some_and(|s| !s.trim().is_empty()),
        discover_ns = %discover_namespace(),
        "c_node_stats started"
    );

    let mut tick = tokio::time::interval(TICK);
    loop {
        tick.tick().await;
        if last_discover.elapsed() >= DISCOVER_INTERVAL {
            volumes = merge_volume_configs(volume_configs(), volume_discover(&node_name).await);
            last_discover = std::time::Instant::now();
        }
        publish_node(&nats, &kv, &mut sampler, &node_name, &mut rollup).await;
        publish_volumes(&nats, &kv, &volumes, &node_name, &mut rollup).await;
    }
}

async fn publish_node(
    nats: &Client,
    kv: &Store,
    sampler: &mut NodeSampler,
    node_name: &str,
    rollup: &mut MetricRollup,
) {
    let stat = sampler.sample();
    rollup.observe_node(&stat);
    let subject = node_subject(node_name);
    let push = node_push(stat);
    let payload = push.encode_to_vec();
    if let Err(e) = nats.publish(subject.clone(), payload.into()).await {
        warn!(subject = %subject, error = %e, "node stats publish failed");
        return;
    }
    let key = stats_kv_key_node(node_name);
    if let Err(e) = stats_kv_put(kv, &key, &push).await {
        warn!(key = %key, error = %e, "stats KV node put failed");
    }
}

async fn publish_volumes(
    nats: &Client,
    kv: &Store,
    volumes: &[VolumeConfig],
    node_name: &str,
    rollup: &mut MetricRollup,
) {
    for cfg in volumes {
        let Some(stat) = sample_volume(cfg, node_name) else {
            continue;
        };
        let ns = stat.namespace.clone();
        let pvc = stat.pvc_name.clone();
        let subject = volume_subject(node_name, &ns, &pvc);
        rollup.observe_volume(&stat);
        let push = volume_push(stat);
        let payload = push.encode_to_vec();
        if let Err(e) = nats.publish(subject.clone(), payload.into()).await {
            warn!(subject = %subject, error = %e, "volume stats publish failed");
            continue;
        }
        let key = stats_kv_key_volume(node_name, &ns, &pvc);
        if let Err(e) = stats_kv_put(kv, &key, &push).await {
            warn!(key = %key, error = %e, "stats KV volume put failed");
        }
    }
}

async fn nats_connect() -> Result<Client> {
    let url = std::env::var("NATS_URL")
        .unwrap_or_else(|_| "tls://nats-client.nats.svc.cluster.local:4222".into());
    let mut opts = async_nats::ConnectOptions::new();
    if let (Ok(u), Ok(p)) = (std::env::var("NATS_USER"), std::env::var("NATS_PASS")) {
        if !u.is_empty() {
            opts = opts.user_and_password(u, p);
        }
    }
    if let Ok(ca) = std::env::var("NATS_CA") {
        if Path::new(&ca).exists() {
            opts = opts.add_root_certificates(Path::new(&ca).into());
        }
    }
    opts.connect(url).await.context("async_nats connect")
}