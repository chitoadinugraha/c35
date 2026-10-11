use std::collections::HashMap;
use std::path::Path;

use anyhow::{Context, Result};
use serde::Deserialize;
use tracing::warn;

use crate::host::exists;
use crate::volume::VolumeConfig;

const HOST_KUBELET_PODS: &str = "/host/var/lib/kubelet/pods";
const SA_TOKEN: &str = "/var/run/secrets/kubernetes.io/serviceaccount/token";
const SA_CA: &str = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt";

pub fn discover_namespace() -> String {
    std::env::var("C35_VOLUME_DISCOVER_NS").unwrap_or_else(|_| "yugabyte".into())
}

pub async fn node_display_address(node_name: &str) -> String {
    match node_display_address_inner(node_name).await {
        Ok(s) => s,
        Err(e) => {
            warn!(error = %e, "node display address lookup failed");
            String::new()
        }
    }
}

async fn node_display_address_inner(node_name: &str) -> Result<String> {
    if !Path::new(SA_TOKEN).exists() {
        return Ok(String::new());
    }
    let k8s = k8s_client().await?;
    let path = format!("/api/v1/nodes/{}", urlencoding::encode(node_name));
    let json = k8s_get_json(&k8s, &path).await.context("get node")?;
    Ok(pick_node_display_address(&json))
}

pub fn pick_node_display_address(v: &serde_json::Value) -> String {
    let addrs = v
        .get("status")
        .and_then(|s| s.get("addresses"))
        .and_then(|a| a.as_array())
        .cloned()
        .unwrap_or_default();
    let mut external = None;
    let mut hostname = None;
    for entry in addrs {
        let ty = entry.get("type").and_then(|t| t.as_str()).unwrap_or("");
        let addr = entry.get("address").and_then(|a| a.as_str()).unwrap_or("");
        if addr.is_empty() {
            continue;
        }
        match ty {
            "ExternalIP" => external = Some(addr.to_string()),
            "Hostname" => hostname = Some(addr.to_string()),
            _ => {}
        }
    }
    if let Some(e) = external {
        return e;
    }
    if let Some(h) = hostname {
        if !is_likely_private_host(&h) {
            return h;
        }
    }
    String::new()
}

fn is_likely_private_host(host: &str) -> bool {
    if let Ok(ip) = host.parse::<std::net::IpAddr>() {
        return match ip {
            std::net::IpAddr::V4(v4) => v4.is_private() || v4.is_loopback() || v4.is_link_local(),
            std::net::IpAddr::V6(v6) => v6.is_loopback() || v6.is_unique_local(),
        };
    }
    host.starts_with("10.")
        || host.starts_with("192.168.")
        || host.contains(".internal")
}

pub async fn volume_discover(node_name: &str) -> Vec<VolumeConfig> {
    match volume_discover_inner(node_name).await {
        Ok(v) => v,
        Err(e) => {
            warn!(error = %e, "volume discover failed");
            Vec::new()
        }
    }
}

async fn volume_discover_inner(node_name: &str) -> Result<Vec<VolumeConfig>> {
    if !Path::new(SA_TOKEN).exists() {
        return Ok(Vec::new());
    }
    let k8s = k8s_client().await?;
    let ns_raw = discover_namespace();
    let namespaces: Vec<String> = ns_raw
        .split(',')
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(String::from)
        .collect();
    let mut out = Vec::new();
    for ns in namespaces {
        let pods = list_pods_on_node(&k8s, &ns, node_name).await?;
        for pod in pods {
            out.extend(pod_volumes(&pod, &k8s, &ns).await);
        }
    }
    if out.is_empty() {
        warn!(node = %node_name, "volume discover: no PVC paths resolved on node");
    } else {
        tracing::info!(node = %node_name, volumes = out.len(), "volume discover");
    }
    Ok(out)
}

async fn pod_volumes(pod: &PodRow, k8s: &K8sHttp, ns: &str) -> Vec<VolumeConfig> {
    let uid = pod.metadata.uid.as_deref().unwrap_or_default();
    if uid.is_empty() {
        return Vec::new();
    }
    let pvc_by_vol: HashMap<String, String> = pod
        .spec
        .volumes
        .iter()
        .filter_map(|v| {
            v.persistent_volume_claim
                .as_ref()
                .map(|pvc| (v.name.clone(), pvc.claim_name.clone()))
        })
        .collect();
    let mut out = Vec::new();
    for (vol_name, claim) in pvc_by_vol {
        let path = kubelet_volume_path(uid, &vol_name)
            .or_else(|| kubelet_pvc_mount_path(uid, &claim))
            .or_else(|| kubelet_csi_mount_fallback(uid, &claim));
        let Some(path) = path else { continue };
        if !exists(&path) {
            continue;
        }
        let storage_class = pvc_storage_class(k8s, ns, &claim).await;
        let label = pod
            .metadata
            .name
            .clone()
            .filter(|s| !s.is_empty())
            .unwrap_or_else(|| claim.clone());
        out.push(VolumeConfig {
            path,
            namespace: ns.to_string(),
            pvc_name: claim,
            storage_class,
            label,
        });
    }
    out
}

fn kubelet_volume_path(pod_uid: &str, volume_name: &str) -> Option<String> {
    let base = format!("{HOST_KUBELET_PODS}/{pod_uid}/volumes");
    let plugins = std::fs::read_dir(&base).ok()?;
    for plugin in plugins.flatten() {
        let candidate = plugin.path().join(volume_name);
        if candidate.is_dir() {
            return Some(candidate.to_string_lossy().replace('\\', "/"));
        }
        let mount = candidate.join("mount");
        if mount.is_dir() {
            return Some(mount.to_string_lossy().replace('\\', "/"));
        }
    }
    None
}

/// OCI/CSI volumes often use opaque directory names (csi-uuid) that do not contain the PVC name.
fn kubelet_csi_mount_fallback(pod_uid: &str, pvc_name: &str) -> Option<String> {
    let mounts = kubelet_csi_mount_paths(pod_uid);
    if mounts.is_empty() {
        return None;
    }
    let pvc_slug = pvc_name.replace('_', "-");
    for m in &mounts {
        if m.contains(pvc_name) || m.contains(&pvc_slug) {
            return Some(m.clone());
        }
    }
    if mounts.len() == 1 {
        return Some(mounts[0].clone());
    }
    None
}

fn kubelet_csi_mount_paths(pod_uid: &str) -> Vec<String> {
    let base = format!("{HOST_KUBELET_PODS}/{pod_uid}/volumes/kubernetes.io~csi");
    let base_path = Path::new(&base);
    if !base_path.is_dir() {
        return Vec::new();
    }
    let mut out = Vec::new();
    for entry in std::fs::read_dir(base_path).into_iter().flatten().flatten() {
        let mount = entry.path().join("mount");
        if mount.is_dir() {
            out.push(mount.to_string_lossy().replace('\\', "/"));
        }
    }
    out.sort();
    out
}

fn kubelet_pvc_mount_path(pod_uid: &str, pvc_name: &str) -> Option<String> {
    let base = format!("{HOST_KUBELET_PODS}/{pod_uid}/volumes");
    let base_path = Path::new(&base);
    if !base_path.exists() {
        return None;
    }
    let pvc_slug = pvc_name.replace('_', "-");
    for entry in std::fs::read_dir(base_path).into_iter().flatten().flatten() {
        let vol_root = entry.path();
        if !vol_root.is_dir() {
            continue;
        }
        let name = vol_root.file_name().and_then(|s| s.to_str()).unwrap_or_default();
        if !name.contains("csi") && !name.contains("kubernetes.io") {
            continue;
        }
        for sub in std::fs::read_dir(&vol_root).into_iter().flatten().flatten() {
            let sub_name = sub.file_name().to_string_lossy().to_string();
            if sub_name.contains(pvc_name) || sub_name.contains(&pvc_slug) {
                let mount = sub.path().join("mount");
                if mount.exists() {
                    return Some(mount.to_string_lossy().replace('\\', "/"));
                }
                if sub.path().is_dir() {
                    return Some(sub.path().to_string_lossy().replace('\\', "/"));
                }
            }
        }
    }
    None
}

async fn pvc_storage_class(k8s: &K8sHttp, ns: &str, claim: &str) -> String {
    let path = format!("/api/v1/namespaces/{ns}/persistentvolumeclaims/{claim}");
    match k8s_get_json(k8s, &path).await {
        Ok(v) => v
            .get("spec")
            .and_then(|s| s.get("storageClassName"))
            .and_then(|s| s.as_str())
            .unwrap_or("")
            .to_string(),
        Err(_) => String::new(),
    }
}

#[derive(Clone, Debug)]
pub struct NodePodMeta {
    pub namespace: String,
    pub name: String,
    pub uid: String,
    pub cpu_request_cores: f64,
    pub cpu_limit_cores: f64,
    pub mem_request_bytes: u64,
    pub mem_limit_bytes: u64,
}

pub async fn node_pods_on_node(node_name: &str) -> Vec<NodePodMeta> {
    match node_pods_on_node_inner(node_name).await {
        Ok(v) => v,
        Err(e) => {
            warn!(error = %e, "list node pods failed");
            Vec::new()
        }
    }
}

async fn node_pods_on_node_inner(node_name: &str) -> Result<Vec<NodePodMeta>> {
    if !Path::new(SA_TOKEN).exists() {
        return Ok(Vec::new());
    }
    let k8s = k8s_client().await?;
    let selector = format!("spec.nodeName={node_name}");
    let path = format!(
        "/api/v1/pods?fieldSelector={}",
        urlencoding::encode(&selector)
    );
    let json = k8s_get_json(&k8s, &path).await.context("list node pods")?;
    let list: PodListAll = serde_json::from_value(json).context("decode node pods")?;
    Ok(list.items.into_iter().filter_map(pod_row_to_meta).collect())
}

fn pod_row_to_meta(item: PodItemAll) -> Option<NodePodMeta> {
    if item.metadata.deletion_timestamp.is_some() {
        return None;
    }
    let phase = item.status.phase.as_deref().unwrap_or_default();
    if phase != "Running" {
        return None;
    }
    let name = item.metadata.name.filter(|s| !s.is_empty())?;
    let uid = item.metadata.uid.filter(|s| !s.is_empty())?;
    let namespace = item
        .metadata
        .namespace
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| "default".to_string());
    let mut cpu_request = 0.0f64;
    let mut cpu_limit = 0.0f64;
    let mut mem_request = 0u64;
    let mut mem_limit = 0u64;
    for c in &item.spec.containers {
        if let Some(cpu) = c.resources.requests.get("cpu") {
            cpu_request += crate::pod_stats::parse_cpu_limit(cpu);
        }
        if let Some(cpu) = c.resources.limits.get("cpu") {
            cpu_limit += crate::pod_stats::parse_cpu_limit(cpu);
        }
        if let Some(mem) = c.resources.requests.get("memory") {
            mem_request += crate::pod_stats::parse_mem_limit(mem);
        }
        if let Some(mem) = c.resources.limits.get("memory") {
            mem_limit += crate::pod_stats::parse_mem_limit(mem);
        }
    }
    Some(NodePodMeta {
        namespace,
        name,
        uid,
        cpu_request_cores: cpu_request,
        cpu_limit_cores: cpu_limit,
        mem_request_bytes: mem_request,
        mem_limit_bytes: mem_limit,
    })
}

async fn list_pods_on_node(k8s: &K8sHttp, ns: &str, node_name: &str) -> Result<Vec<PodRow>> {
    let selector = format!("spec.nodeName={node_name}");
    let path = format!(
        "/api/v1/namespaces/{ns}/pods?fieldSelector={}",
        urlencoding::encode(&selector)
    );
    let json = k8s_get_json(k8s, &path).await.context("list pods")?;
    let list: PodList = serde_json::from_value(json).context("decode pod list")?;
    Ok(list.items)
}

struct K8sHttp {
    client: reqwest::Client,
    base: String,
}

async fn k8s_client() -> Result<K8sHttp> {
    let host = std::env::var("KUBERNETES_SERVICE_HOST")
        .unwrap_or_else(|_| "kubernetes.default.svc".into());
    let port = std::env::var("KUBERNETES_SERVICE_PORT_HTTPS")
        .or_else(|_| std::env::var("KUBERNETES_SERVICE_PORT"))
        .unwrap_or_else(|_| "443".into());
    let base = format!("https://{host}:{port}");
    let token = std::fs::read_to_string(SA_TOKEN).context("read SA token")?;
    let ca = std::fs::read(SA_CA).context("read SA CA")?;
    let cert = reqwest::Certificate::from_pem(&ca).context("parse SA CA")?;
    let client = reqwest::Client::builder()
        .default_headers({
            let mut h = reqwest::header::HeaderMap::new();
            h.insert(
                reqwest::header::AUTHORIZATION,
                format!("Bearer {}", token.trim())
                    .parse()
                    .context("auth header")?,
            );
            h
        })
        .tls_built_in_root_certs(false)
        .add_root_certificate(cert)
        .build()
        .context("k8s http client")?;
    Ok(K8sHttp { client, base })
}

async fn k8s_get_json(k8s: &K8sHttp, path: &str) -> Result<serde_json::Value> {
    let url = format!("{}{}", k8s.base, path);
    let resp = k8s
        .client
        .get(url)
        .send()
        .await
        .context("k8s GET")?
        .error_for_status()
        .context("k8s status")?
        .json()
        .await
        .context("k8s json")?;
    Ok(resp)
}

#[derive(Debug, Deserialize)]
struct PodListAll {
    items: Vec<PodItemAll>,
}

#[derive(Debug, Deserialize)]
struct PodItemAll {
    metadata: PodMetaAll,
    spec: PodSpecAll,
    status: PodStatusAll,
}

#[derive(Debug, Deserialize)]
struct PodMetaAll {
    name: Option<String>,
    uid: Option<String>,
    namespace: Option<String>,
    #[serde(default, rename = "deletionTimestamp")]
    deletion_timestamp: Option<String>,
}

#[derive(Debug, Default, Deserialize)]
struct PodStatusAll {
    phase: Option<String>,
}

#[derive(Debug, Default, Deserialize)]
struct PodSpecAll {
    #[serde(default)]
    containers: Vec<PodContainerAll>,
}

#[derive(Debug, Default, Deserialize)]
struct PodContainerAll {
    #[serde(default)]
    resources: PodResourcesAll,
}

#[derive(Debug, Default, Deserialize)]
struct PodResourcesAll {
    #[serde(default)]
    requests: HashMap<String, String>,
    #[serde(default)]
    limits: HashMap<String, String>,
}

#[derive(Debug, Deserialize)]
struct PodList {
    items: Vec<PodRow>,
}

#[derive(Debug, Deserialize)]
struct PodRow {
    metadata: PodMeta,
    spec: PodSpec,
}

#[derive(Debug, Deserialize)]
struct PodMeta {
    name: Option<String>,
    uid: Option<String>,
}

#[derive(Debug, Default, Deserialize)]
struct PodSpec {
    #[serde(default)]
    volumes: Vec<PodVolume>,
}

#[derive(Debug, Deserialize)]
struct PodVolume {
    name: String,
    #[serde(rename = "persistentVolumeClaim")]
    persistent_volume_claim: Option<PvcRef>,
}

#[derive(Debug, Deserialize)]
struct PvcRef {
    #[serde(rename = "claimName")]
    claim_name: String,
}

pub fn merge_volume_configs(manual: Vec<VolumeConfig>, discovered: Vec<VolumeConfig>) -> Vec<VolumeConfig> {
    let mut by_key: HashMap<(String, String), VolumeConfig> = HashMap::new();
    for cfg in discovered {
        by_key.insert((cfg.namespace.clone(), cfg.pvc_name.clone()), cfg);
    }
    for cfg in manual {
        by_key.insert((cfg.namespace.clone(), cfg.pvc_name.clone()), cfg);
    }
    by_key.into_values().collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn pick_external_ip_over_internal() {
        let json = serde_json::json!({
            "status": {
                "addresses": [
                    {"type": "InternalIP", "address": "10.0.85.12"},
                    {"type": "ExternalIP", "address": "168.110.203.3"}
                ]
            }
        });
        assert_eq!(pick_node_display_address(&json), "168.110.203.3");
    }

    #[test]
    #[cfg(target_os = "linux")]
    fn kubelet_pvc_path_yb_master_fixture() {
        let uid = "42c87b27-33a8-410a-9564-948b8da696d9";
        let path = kubelet_pvc_mount_path(uid, "yb-data");
        if !Path::new(HOST_KUBELET_PODS).is_dir() {
            return;
        }
        assert!(
            path.as_deref().is_some_and(|p| p.contains("yb-data-restored2")),
            "path={path:?}"
        );
    }

    #[test]
    fn pod_list_fixture_deserializes() {
        let text = std::fs::read_to_string("node_stats/testdata/yb_pods.json")
            .or_else(|_| std::fs::read_to_string("testdata/yb_pods.json"))
            .expect("yb_pods.json");
        let list: PodList = serde_json::from_str(&text).expect("pod list");
        assert_eq!(list.items.len(), 2);
        let pvc = list.items[0]
            .spec
            .volumes
            .iter()
            .find(|v| v.name == "datadir0")
            .and_then(|v| v.persistent_volume_claim.as_ref())
            .expect("datadir pvc");
        assert_eq!(pvc.claim_name, "yb-data");
    }

    #[test]
    fn pod_volume_pvc_json() {
        let json = serde_json::json!({
            "metadata": {"name": "buildkit-0", "uid": "abc"},
            "spec": {
                "volumes": [{
                    "name": "buildkit-cache",
                    "persistentVolumeClaim": {"claimName": "buildkit-data"}
                }]
            }
        });
        let row: PodRow = serde_json::from_value(json).expect("pod row");
        assert_eq!(row.spec.volumes.len(), 1);
        let pvc = row.spec.volumes[0]
            .persistent_volume_claim
            .as_ref()
            .expect("pvc");
        assert_eq!(pvc.claim_name, "buildkit-data");
    }

    #[test]
    fn merge_manual_overrides_discovered() {
        let discovered = vec![VolumeConfig {
            path: "/a".into(),
            namespace: "yugabyte".into(),
            pvc_name: "yb-tserver".into(),
            storage_class: "oci".into(),
            label: "disc".into(),
        }];
        let manual = vec![VolumeConfig {
            path: "/b".into(),
            namespace: "yugabyte".into(),
            pvc_name: "yb-tserver".into(),
            storage_class: "".into(),
            label: "manual".into(),
        }];
        let merged = merge_volume_configs(manual, discovered);
        assert_eq!(merged.len(), 1);
        assert_eq!(merged[0].path, "/b");
        assert_eq!(merged[0].label, "manual");
    }
}
