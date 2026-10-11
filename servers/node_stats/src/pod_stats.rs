use std::collections::HashMap;
use std::fs;
use std::path::Path;
use std::time::Instant;

use anyhow::{Context, Result};
use c35_proto::PodStat;
use tracing::warn;

use crate::host::now_ms;
use crate::volume_discover::{node_pods_on_node, NodePodMeta};

const HOST_PREFIX: &str = "/host";

pub struct PodSampler {
    prev_cpu_usec: HashMap<String, u64>,
    prev_sample_at: HashMap<String, Instant>,
}

impl PodSampler {
    pub fn new() -> Self {
        Self {
            prev_cpu_usec: HashMap::new(),
            prev_sample_at: HashMap::new(),
        }
    }

    pub async fn sample(&mut self, node_name: &str) -> Vec<PodStat> {
        let pods = node_pods_on_node(node_name).await;
        let mut out = Vec::new();
        for pod in pods {
            match sample_pod(node_name, &pod, self) {
                Ok(stat) => out.push(stat),
                Err(e) => {
                    warn!(
                        ns = %pod.namespace,
                        pod = %pod.name,
                        error = %e,
                        "pod stats sample failed"
                    );
                }
            }
        }
        out.sort_by(|a, b| a.pod_name.cmp(&b.pod_name));
        out
    }
}

pub fn pod_push(stat: PodStat) -> c35_proto::StatsPush {
    c35_proto::StatsPush {
        body: Some(c35_proto::stats_push::Body::Pod(stat)),
    }
}

pub fn pod_subject(node_name: &str, namespace: &str, pod_name: &str) -> String {
    format!("c35.stats.pod.{node_name}.{namespace}.{pod_name}")
}

fn sample_pod(node_name: &str, pod: &NodePodMeta, sampler: &mut PodSampler) -> Result<PodStat> {
    let key = format!("{}/{}", pod.namespace, pod.name);
    let cgroup = pod_cgroup_dir(HOST_PREFIX, &pod.uid).context("pod cgroup")?;
    let mem_used = read_u64_file(&format!("{cgroup}/memory.current"))?;
    let mem_k8s_limit = pod.mem_limit_bytes;
    let mem_cgroup_cap = read_memory_limit(&format!("{cgroup}/memory.max"));
    let cpu_used = cpu_used_cores(&cgroup, &key, sampler)?;
    let cpu_limit = pod.cpu_limit_cores;
    let cpu_request = pod.cpu_request_cores;
    let mem_request = pod.mem_request_bytes;
    let cpu_bar = bar_denom_f64(cpu_used, cpu_limit, cpu_request);
    let mem_bar_limit = if mem_k8s_limit > 0 {
        mem_k8s_limit
    } else {
        mem_cgroup_cap.unwrap_or(0)
    };
    let mem_bar = bar_denom_u64(mem_used, mem_bar_limit, mem_request);
    let cpu_pct = ((cpu_used / cpu_bar) * 100.0).clamp(0.0, 100.0);
    // No Kubernetes memory limit: UI uses blue informational bar (not request-scaled %).
    let mem_pct = if mem_k8s_limit == 0 {
        0.0
    } else {
        ((mem_used as f64 / mem_bar as f64) * 100.0).clamp(0.0, 100.0)
    };
    Ok(PodStat {
        node_name: node_name.to_string(),
        namespace: pod.namespace.clone(),
        pod_name: pod.name.clone(),
        cpu_used_cores: cpu_used,
        cpu_limit_cores: cpu_limit,
        cpu_request_cores: cpu_request,
        cpu_pct,
        mem_used_bytes: mem_used,
        mem_limit_bytes: mem_k8s_limit,
        mem_request_bytes: mem_request,
        mem_pct,
        net_in_bps: 0.0,
        net_out_bps: 0.0,
        ts_ms: now_ms(),
    })
}

/// Bar scale: limit when set, else request, else a small floor from current usage.
fn bar_denom_f64(used: f64, limit: f64, request: f64) -> f64 {
    if limit > 0.0 {
        return limit;
    }
    if request > 0.0 {
        return request;
    }
    if used > 0.0 {
        return used;
    }
    1.0
}

fn bar_denom_u64(used: u64, limit: u64, request: u64) -> u64 {
    if limit > 0 {
        return limit;
    }
    if request > 0 {
        return request;
    }
    if used > 0 {
        return used;
    }
    1
}

fn cpu_used_cores(cgroup: &str, key: &str, sampler: &mut PodSampler) -> Result<f64> {
    let usage_usec = read_cpu_usage_usec(cgroup)?;
    let now = Instant::now();
    let prev_usec = sampler.prev_cpu_usec.get(key).copied();
    let prev_at = sampler.prev_sample_at.get(key).copied();
    let key = key.to_string();
    sampler.prev_cpu_usec.insert(key.clone(), usage_usec);
    sampler.prev_sample_at.insert(key, now);
    let Some(prev_usec) = prev_usec else {
        return Ok(0.0);
    };
    let Some(prev_at) = prev_at else {
        return Ok(0.0);
    };
    let dt = now.duration_since(prev_at).as_secs_f64();
    if dt <= 0.0 {
        return Ok(0.0);
    }
    let delta = usage_usec.saturating_sub(prev_usec);
    Ok((delta as f64 / 1_000_000.0) / dt)
}

fn read_cpu_usage_usec(cgroup: &str) -> Result<u64> {
    let path = format!("{cgroup}/cpu.stat");
    let text = fs::read_to_string(&path).with_context(|| format!("read {path}"))?;
    for line in text.lines() {
        let Some((k, v)) = line.split_once(' ') else {
            continue;
        };
        if k == "usage_usec" {
            return v.trim().parse().context("parse usage_usec");
        }
    }
    Ok(0)
}

fn read_memory_limit(path: &str) -> Option<u64> {
    let raw = fs::read_to_string(path).ok()?;
    let t = raw.trim();
    if t == "max" {
        return None;
    }
    t.parse().ok()
}

fn read_u64_file(path: &str) -> Result<u64> {
    let raw = fs::read_to_string(path).with_context(|| format!("read {path}"))?;
    raw.trim().parse().with_context(|| format!("parse {path}"))
}

fn pod_cgroup_dir(host_prefix: &str, pod_uid: &str) -> Result<String> {
    let uid_key = pod_uid.replace('-', "_");
    let roots = [
        format!("{host_prefix}/sys/fs/cgroup/kubepods.slice/kubepods-burstable.slice"),
        format!("{host_prefix}/sys/fs/cgroup/kubepods.slice/kubepods-besteffort.slice"),
        format!("{host_prefix}/sys/fs/cgroup/kubepods.slice"),
    ];
    for root in roots {
        let path = Path::new(&root);
        if !path.is_dir() {
            continue;
        }
        for entry in fs::read_dir(path).into_iter().flatten().flatten() {
            let name = entry.file_name().to_string_lossy().to_string();
            if name.contains(&uid_key) {
                return Ok(entry.path().to_string_lossy().replace('\\', "/"));
            }
        }
    }
    anyhow::bail!("cgroup not found for pod uid {pod_uid}")
}

pub fn parse_cpu_limit(raw: &str) -> f64 {
    let s = raw.trim();
    if s.is_empty() {
        return 0.0;
    }
    if let Some(m) = s.strip_suffix('m') {
        return m.parse::<f64>().unwrap_or(0.0) / 1000.0;
    }
    s.parse().unwrap_or(0.0)
}

pub fn parse_mem_limit(raw: &str) -> u64 {
    let s = raw.trim();
    if s.is_empty() {
        return 0;
    }
    if let Some(k) = s.strip_suffix("Ki") {
        return (k.parse::<f64>().unwrap_or(0.0) * 1024.0) as u64;
    }
    if let Some(m) = s.strip_suffix("Mi") {
        return (m.parse::<f64>().unwrap_or(0.0) * 1024.0 * 1024.0) as u64;
    }
    if let Some(g) = s.strip_suffix("Gi") {
        return (g.parse::<f64>().unwrap_or(0.0) * 1024.0 * 1024.0 * 1024.0) as u64;
    }
    s.parse().unwrap_or(0)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_cpu_millicores() {
        assert_eq!(parse_cpu_limit("500m"), 0.5);
        assert_eq!(parse_cpu_limit("2"), 2.0);
    }

    #[test]
    fn parse_mem_gi() {
        assert_eq!(parse_mem_limit("512Mi"), 512 * 1024 * 1024);
    }

    #[test]
    fn bar_denom_prefers_limit() {
        assert_eq!(bar_denom_f64(1.5, 2.0, 1.0), 2.0);
        assert_eq!(bar_denom_f64(1.5, 0.0, 1.0), 1.0);
    }
}
