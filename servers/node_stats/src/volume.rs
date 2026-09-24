use std::path::Path;

use c35_proto::{StatsPush, VolumeStat};
use tracing::warn;

use crate::host::stat_bytes;

#[derive(Clone, Debug)]
pub struct VolumeConfig {
    pub path: String,
    pub namespace: String,
    pub pvc_name: String,
    pub storage_class: String,
    pub label: String,
}

pub fn volume_configs() -> Vec<VolumeConfig> {
    std::env::var("C35_VOLUME_PATHS")
        .ok()
        .map(|raw| parse_volume_paths(&raw))
        .unwrap_or_default()
}

fn parse_volume_paths(raw: &str) -> Vec<VolumeConfig> {
    raw.split(',')
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .filter_map(parse_volume_entry)
        .collect()
}

fn parse_volume_entry(entry: &str) -> Option<VolumeConfig> {
    let parts: Vec<&str> = entry.split(':').map(str::trim).collect();
    if parts.len() < 3 {
        warn!(entry, "skip C35_VOLUME_PATHS entry (want ns:pvc:path[:sc][:label])");
        return None;
    }
    let path = parts[2].to_string();
    let label = parts
        .get(4)
        .filter(|s| !s.is_empty())
        .map(|s| s.to_string())
        .unwrap_or_else(|| default_volume_label(&parts[1]));
    Some(VolumeConfig {
        namespace: parts[0].to_string(),
        pvc_name: parts[1].to_string(),
        path,
        storage_class: parts.get(3).unwrap_or(&"").to_string(),
        label,
    })
}

fn default_volume_label(pvc_name: &str) -> String {
    pvc_name.into()
}

pub fn sample_volume(cfg: &VolumeConfig, node_name: &str) -> Option<VolumeStat> {
    if !Path::new(&cfg.path).exists() {
        return None;
    }
    let (used, capacity) = match stat_bytes(&cfg.path) {
        Ok(v) => v,
        Err(e) => {
            warn!(path = %cfg.path, error = %e, "volume statvfs failed");
            return None;
        }
    };
    Some(VolumeStat {
        namespace: cfg.namespace.clone(),
        pvc_name: cfg.pvc_name.clone(),
        pod_name: cfg.label.clone(),
        node_name: node_name.to_string(),
        used_bytes: used,
        capacity_bytes: capacity,
        storage_class: cfg.storage_class.clone(),
        label: cfg.label.clone(),
    })
}

pub fn volume_push(stat: VolumeStat) -> StatsPush {
    StatsPush {
        body: Some(c35_proto::stats_push::Body::Volume(stat)),
    }
}

pub fn volume_subject(node_name: &str, namespace: &str, pvc_name: &str) -> String {
    format!("c35.stats.volume.{node_name}.{namespace}.{pvc_name}")
}
