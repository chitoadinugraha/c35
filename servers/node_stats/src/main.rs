mod device;
mod host;
mod node;
mod sample;
mod volume;

use std::path::Path;
use std::time::Duration;

use anyhow::{Context, Result};
use async_nats::Client;
use prost::Message;
use tracing::{info, warn};

use crate::node::{node_push, node_subject, NodeSampler};
use crate::volume::{sample_volume, volume_configs, volume_push, volume_subject};

const TICK: Duration = Duration::from_secs(2);

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    let node_name = std::env::var("NODE_NAME").context("NODE_NAME required")?;
    let nats = nats_connect().await.context("NATS connect")?;
    let volumes = volume_configs();
    let mut sampler = NodeSampler::new(node_name.clone());

    info!(
        node = %node_name,
        mounts = %std::env::var("C35_NODE_MOUNTS").unwrap_or_else(|_| "/,/var/log".into()),
        volumes = volumes.len(),
        "c_node_stats started"
    );

    let mut tick = tokio::time::interval(TICK);
    loop {
        tick.tick().await;
        publish_node(&nats, &mut sampler, &node_name).await;
        publish_volumes(&nats, &volumes, &node_name).await;
    }
}

async fn publish_node(nats: &Client, sampler: &mut NodeSampler, node_name: &str) {
    let stat = sampler.sample();
    let subject = node_subject(node_name);
    let payload = node_push(stat).encode_to_vec();
    if let Err(e) = nats.publish(subject.clone(), payload.into()).await {
        warn!(subject = %subject, error = %e, "node stats publish failed");
    }
}

async fn publish_volumes(nats: &Client, volumes: &[volume::VolumeConfig], node_name: &str) {
    for cfg in volumes {
        let Some(stat) = sample_volume(cfg, node_name) else {
            continue;
        };
        let subject = volume_subject(node_name, &stat.namespace, &stat.pvc_name);
        let payload = volume_push(stat).encode_to_vec();
        if let Err(e) = nats.publish(subject.clone(), payload.into()).await {
            warn!(subject = %subject, error = %e, "volume stats publish failed");
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
