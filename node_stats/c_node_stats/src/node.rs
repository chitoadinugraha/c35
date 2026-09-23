use std::time::Instant;

use c35_proto::{DiskMountStat, NodeStat, StatsPush};

use crate::host::{
    cpu_cores, cpu_pct as cpu_usage_pct, cpu_sample, disk_io_by_mount, exists, host_path, mem_bytes,
    net_totals, stat_bytes, CpuSample,
};
use crate::sample::{self, SampleSnapshot};

const HOST_PREFIX: &str = "/host";

#[derive(Clone, Debug)]
struct MountConfig {
    label: String,
    host_path: String,
    mount: String,
}

pub struct NodeSampler {
    mounts: Vec<MountConfig>,
    node_name: String,
    prev: Option<SampleSnapshot>,
    prev_cpu: Option<CpuSample>,
}

impl NodeSampler {
    pub fn new(node_name: String) -> Self {
        Self {
            mounts: mount_configs(),
            node_name,
            prev: None,
            prev_cpu: None,
        }
    }

    pub fn sample(&mut self) -> NodeStat {
        let now = Instant::now();
        let mount_keys: Vec<String> = self.mounts.iter().map(|m| m.mount.clone()).collect();
        let disk_io = disk_io_by_mount(HOST_PREFIX, &mount_keys);
        let net = net_totals(HOST_PREFIX);
        let cur = SampleSnapshot::new(now, disk_io, net);

        let (net_in_bps, net_out_bps) = self
            .prev
            .as_ref()
            .map(|p| sample::net_bps(&p.net, &cur.net, cur.elapsed(p)))
            .unwrap_or((0.0, 0.0));

        let cpu_cur = cpu_sample(HOST_PREFIX);
        let cpu_pct = self
            .prev_cpu
            .map(|p| cpu_usage_pct(p, cpu_cur))
            .unwrap_or(0.0);
        self.prev_cpu = Some(cpu_cur);

        let (mem_used_bytes, mem_total_bytes) = mem_bytes(HOST_PREFIX);
        let mounts = self
            .mounts
            .iter()
            .filter_map(|m| self.mount_stat(m, &cur))
            .collect();

        self.prev = Some(cur);

        NodeStat {
            node_name: self.node_name.clone(),
            cpu_cores: cpu_cores(HOST_PREFIX),
            cpu_pct,
            mem_used_bytes,
            mem_total_bytes,
            mounts,
            net_in_bps,
            net_out_bps,
            ts_ms: crate::host::now_ms(),
        }
    }

    fn mount_stat(&self, m: &MountConfig, cur: &SampleSnapshot) -> Option<DiskMountStat> {
        if !exists(&m.host_path) {
            return None;
        }
        let (used, total) = stat_bytes(&m.host_path).ok()?;
        let (read_bps, write_bps) = self
            .prev
            .as_ref()
            .and_then(|p| {
                let prev_io = p.disks.get(&m.mount)?;
                let cur_io = cur.disks.get(&m.mount)?;
                Some(sample::disk_bps(prev_io, cur_io, cur.elapsed(p)))
            })
            .unwrap_or((0.0, 0.0));
        Some(DiskMountStat {
            label: m.label.clone(),
            mount: m.mount.clone(),
            used_bytes: used,
            total_bytes: total,
            read_bps,
            write_bps,
        })
    }
}

fn mount_configs() -> Vec<MountConfig> {
    let raw = std::env::var("C35_NODE_MOUNTS").unwrap_or_else(|_| "/,/var/log".into());
    raw.split(',')
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(|mount| {
            let mount = if mount.starts_with('/') {
                mount.to_string()
            } else {
                format!("/{mount}")
            };
            MountConfig {
                label: mount_label(&mount),
                host_path: host_path(HOST_PREFIX, &mount),
                mount,
            }
        })
        .collect()
}

fn mount_label(mount: &str) -> String {
    match mount {
        "/" => "Boot".into(),
        "/var/log" => "OS logs".into(),
        _ => mount.trim_start_matches('/').into(),
    }
}

pub fn node_push(stat: NodeStat) -> StatsPush {
    StatsPush {
        body: Some(c35_proto::stats_push::Body::Node(stat)),
    }
}

pub fn node_subject(node_name: &str) -> String {
    format!("c35.stats.node.{node_name}")
}
