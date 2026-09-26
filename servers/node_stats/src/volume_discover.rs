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
            .or_else(|| kubelet_pvc_mount_path(uid, &claim));
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
    persistent_volume_claim: Option<PvcRef>,
}

#[derive(Debug, Deserialize)]
struct PvcRef {
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
