//! Ensure cert-manager Ingress per verified custom domain (Path A HTTPS).
//!
//! In-cluster only — uses ServiceAccount token. Debounced / single-flight per domain.
//! Outside the cluster (local dev) returns `disabled`.

use std::collections::HashMap;
use std::sync::{Arc, Mutex, OnceLock};
use std::time::{Duration, Instant};

use serde_json::{json, Value};
use sqlx::PgPool;

const LABEL_CUSTOM: &str = "c35.alienai.id/custom-domain";
const STUCK_AFTER: Duration = Duration::from_secs(20 * 60);

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum CertStatus {
    /// TLS sync not available (local dev / feature off).
    Disabled,
    Pending,
    Ready,
    Failed,
}

impl CertStatus {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Disabled => "disabled",
            Self::Pending => "pending",
            Self::Ready => "ready",
            Self::Failed => "failed",
        }
    }
}

#[derive(Debug, Clone)]
pub struct CertInfo {
    pub status: CertStatus,
    pub error: String,
}

impl CertInfo {
    fn disabled() -> Self {
        Self {
            status: CertStatus::Disabled,
            error: String::new(),
        }
    }

    fn pending() -> Self {
        Self {
            status: CertStatus::Pending,
            error: String::new(),
        }
    }

    fn ready() -> Self {
        Self {
            status: CertStatus::Ready,
            error: String::new(),
        }
    }

    fn failed(msg: impl Into<String>) -> Self {
        Self {
            status: CertStatus::Failed,
            error: msg.into(),
        }
    }
}

struct K8s {
    base: String,
    ns: String,
    token: String,
    client: reqwest::Client,
    issuer: String,
}

fn tls_sync_enabled() -> bool {
    match std::env::var("C35_TLS_SYNC_ENABLED") {
        Ok(v) => {
            let t = v.trim().to_lowercase();
            !(t == "0" || t == "false" || t == "no" || t == "off")
        }
        Err(_) => true,
    }
}

fn debounce_secs() -> u64 {
    std::env::var("C35_TLS_DEBOUNCE_SECS")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(45)
}

fn cluster_issuer() -> String {
    std::env::var("C35_TLS_CLUSTER_ISSUER")
        .ok()
        .filter(|s| !s.trim().is_empty())
        .unwrap_or_else(|| "letsencrypt-prod-dns".into())
}

fn api_server_url() -> Option<String> {
    let host = std::env::var("KUBERNETES_SERVICE_HOST").ok()?;
    let port = std::env::var("KUBERNETES_SERVICE_PORT").unwrap_or_else(|_| "443".into());
    let host = if host.contains(':') && !host.starts_with('[') {
        format!("[{host}]")
    } else {
        host
    };
    Some(format!("https://{host}:{port}"))
}

fn try_in_cluster() -> Option<K8s> {
    if !tls_sync_enabled() {
        return None;
    }
    let base = api_server_url()?;
    let token =
        std::fs::read_to_string("/var/run/secrets/kubernetes.io/serviceaccount/token").ok()?;
    let ca = std::fs::read("/var/run/secrets/kubernetes.io/serviceaccount/ca.crt").ok()?;
    let ns = std::env::var("C35_TLS_NAMESPACE")
        .ok()
        .filter(|s| !s.trim().is_empty())
        .or_else(|| {
            std::fs::read_to_string("/var/run/secrets/kubernetes.io/serviceaccount/namespace").ok()
        })
        .unwrap_or_else(|| "c35".into());
    let cert = reqwest::Certificate::from_pem(&ca).ok()?;
    let client = reqwest::Client::builder()
        .add_root_certificate(cert)
        .timeout(Duration::from_secs(20))
        .build()
        .ok()?;
    Some(K8s {
        base,
        ns: ns.trim().to_string(),
        token: token.trim().to_string(),
        client,
        issuer: cluster_issuer(),
    })
}

fn k8s() -> Option<&'static K8s> {
    static CELL: OnceLock<Option<K8s>> = OnceLock::new();
    CELL.get_or_init(try_in_cluster).as_ref()
}

/// Kubernetes object name: `c35-domain-{sanitized}` (≤63 chars).
pub fn ingress_name(domain: &str) -> String {
    let mut s: String = domain
        .chars()
        .map(|c| if c.is_ascii_alphanumeric() { c } else { '-' })
        .collect();
    while s.contains("--") {
        s = s.replace("--", "-");
    }
    let s = s.trim_matches('-').to_lowercase();
    let prefix = "c35-domain-";
    let max = 63usize.saturating_sub(prefix.len());
    let body = if s.len() > max {
        s.chars()
            .take(max)
            .collect::<String>()
            .trim_end_matches('-')
            .to_string()
    } else {
        s
    };
    format!("{prefix}{body}")
}

fn secret_name(domain: &str) -> String {
    format!("{}-tls", ingress_name(domain))
}

fn last_ensure_map() -> &'static Mutex<HashMap<String, Instant>> {
    static M: OnceLock<Mutex<HashMap<String, Instant>>> = OnceLock::new();
    M.get_or_init(|| Mutex::new(HashMap::new()))
}

fn ensure_locks() -> &'static Mutex<HashMap<String, Arc<tokio::sync::Mutex<()>>>> {
    static M: OnceLock<Mutex<HashMap<String, Arc<tokio::sync::Mutex<()>>>>> = OnceLock::new();
    M.get_or_init(|| Mutex::new(HashMap::new()))
}

fn domain_lock(domain: &str) -> Arc<tokio::sync::Mutex<()>> {
    let mut g = ensure_locks().lock().unwrap();
    g.entry(domain.to_string())
        .or_insert_with(|| Arc::new(tokio::sync::Mutex::new(())))
        .clone()
}

impl K8s {
    fn auth(&self, req: reqwest::RequestBuilder) -> reqwest::RequestBuilder {
        req.bearer_auth(&self.token)
            .header("Accept", "application/json")
    }

    async fn get_json(&self, path: &str) -> Result<Option<Value>, String> {
        let url = format!("{}{}", self.base, path);
        let res = self
            .auth(self.client.get(&url))
            .send()
            .await
            .map_err(|e| e.to_string())?;
        let status = res.status();
        if status.as_u16() == 404 {
            return Ok(None);
        }
        if !status.is_success() {
            let body = res.text().await.unwrap_or_default();
            return Err(format!("k8s GET {path}: {status} {body}"));
        }
        Ok(Some(res.json().await.map_err(|e| e.to_string())?))
    }

    async fn put_json(&self, path: &str, body: &Value) -> Result<Value, String> {
        let url = format!("{}{}", self.base, path);
        let res = self
            .auth(self.client.put(&url))
            .header("Content-Type", "application/json")
            .json(body)
            .send()
            .await
            .map_err(|e| e.to_string())?;
        let status = res.status();
        if !status.is_success() {
            let t = res.text().await.unwrap_or_default();
            return Err(format!("k8s PUT {path}: {status} {t}"));
        }
        res.json().await.map_err(|e| e.to_string())
    }

    async fn post_json(&self, path: &str, body: &Value) -> Result<Value, String> {
        let url = format!("{}{}", self.base, path);
        let res = self
            .auth(self.client.post(&url))
            .header("Content-Type", "application/json")
            .json(body)
            .send()
            .await
            .map_err(|e| e.to_string())?;
        let status = res.status();
        if status.as_u16() == 409 {
            return Ok(json!({}));
        }
        if !status.is_success() {
            let t = res.text().await.unwrap_or_default();
            return Err(format!("k8s POST {path}: {status} {t}"));
        }
        res.json().await.map_err(|e| e.to_string())
    }

    async fn delete(&self, path: &str) -> Result<(), String> {
        let url = format!("{}{}", self.base, path);
        let res = self
            .auth(self.client.delete(&url))
            .send()
            .await
            .map_err(|e| e.to_string())?;
        let status = res.status();
        if status.as_u16() == 404 || status.is_success() {
            return Ok(());
        }
        let t = res.text().await.unwrap_or_default();
        Err(format!("k8s DELETE {path}: {status} {t}"))
    }

    fn ingress_body(&self, domain: &str) -> Value {
        let name = ingress_name(domain);
        let secret = secret_name(domain);
        json!({
            "apiVersion": "networking.k8s.io/v1",
            "kind": "Ingress",
            "metadata": {
                "name": name,
                "namespace": self.ns,
                "labels": {
                    "app.kubernetes.io/name": "c35-server",
                    "app.kubernetes.io/part-of": "c35",
                    LABEL_CUSTOM: "true",
                    "c35.alienai.id/domain": domain,
                },
                "annotations": {
                    "cert-manager.io/cluster-issuer": self.issuer,
                    "traefik.ingress.kubernetes.io/router.tls": "true",
                    "traefik.ingress.kubernetes.io/redirect-entry-point": "https",
                }
            },
            "spec": {
                "ingressClassName": "traefik",
                "tls": [{ "hosts": [domain], "secretName": secret }],
                "rules": [{
                    "host": domain,
                    "http": {
                        "paths": [{
                            "path": "/",
                            "pathType": "Prefix",
                            "backend": {
                                "service": { "name": "c35-server", "port": { "name": "http" } }
                            }
                        }]
                    }
                }]
            }
        })
    }

    async fn ensure_ingress(&self, domain: &str) -> Result<(), String> {
        let name = ingress_name(domain);
        let path = format!(
            "/apis/networking.k8s.io/v1/namespaces/{}/ingresses/{}",
            self.ns, name
        );
        let list_path = format!(
            "/apis/networking.k8s.io/v1/namespaces/{}/ingresses",
            self.ns
        );
        match self.get_json(&path).await? {
            None => {
                let body = self.ingress_body(domain);
                let _ = self.post_json(&list_path, &body).await?;
                Ok(())
            }
            Some(existing) => {
                let mut body = self.ingress_body(domain);
                if let Some(rv) = existing
                    .pointer("/metadata/resourceVersion")
                    .and_then(|v| v.as_str())
                {
                    body["metadata"]["resourceVersion"] = json!(rv);
                }
                if let Some(uid) = existing.pointer("/metadata/uid") {
                    body["metadata"]["uid"] = uid.clone();
                }
                let _ = self.put_json(&path, &body).await?;
                Ok(())
            }
        }
    }

    async fn delete_ingress(&self, domain: &str) -> Result<(), String> {
        let name = ingress_name(domain);
        let path = format!(
            "/apis/networking.k8s.io/v1/namespaces/{}/ingresses/{}",
            self.ns, name
        );
        self.delete(&path).await
    }

    async fn cert_info(&self, domain: &str) -> Result<CertInfo, String> {
        let name = secret_name(domain);
        let cert_path = format!(
            "/apis/cert-manager.io/v1/namespaces/{}/certificates/{}",
            self.ns, name
        );
        let secret_path = format!("/api/v1/namespaces/{}/secrets/{}", self.ns, name);
        let ingress_path = format!(
            "/apis/networking.k8s.io/v1/namespaces/{}/ingresses/{}",
            self.ns,
            ingress_name(domain)
        );

        if self.get_json(&ingress_path).await?.is_none() {
            return Ok(CertInfo::pending());
        }

        if self.get_json(&secret_path).await?.is_some() {
            if let Some(cert) = self.get_json(&cert_path).await? {
                if cert_ready(&cert) {
                    return Ok(CertInfo::ready());
                }
                if let Some(info) = cert_failed_or_stuck(&cert) {
                    return Ok(info);
                }
            }
            return Ok(CertInfo::ready());
        }

        match self.get_json(&cert_path).await? {
            None => Ok(CertInfo::pending()),
            Some(cert) => {
                if cert_ready(&cert) {
                    Ok(CertInfo::ready())
                } else if let Some(info) = cert_failed_or_stuck(&cert) {
                    Ok(info)
                } else {
                    Ok(CertInfo::pending())
                }
            }
        }
    }
}

fn cert_ready(cert: &Value) -> bool {
    cert.pointer("/status/conditions")
        .and_then(|c| c.as_array())
        .map(|arr| {
            arr.iter().any(|c| {
                c.get("type").and_then(|t| t.as_str()) == Some("Ready")
                    && c.get("status").and_then(|s| s.as_str()) == Some("True")
            })
        })
        .unwrap_or(false)
}

fn cert_failed_or_stuck(cert: &Value) -> Option<CertInfo> {
    let conditions = cert.pointer("/status/conditions")?.as_array()?;
    let ready = conditions
        .iter()
        .find(|c| c.get("type").and_then(|t| t.as_str()) == Some("Ready"));
    if let Some(c) = ready {
        let status = c.get("status").and_then(|s| s.as_str()).unwrap_or("");
        let reason = c.get("reason").and_then(|s| s.as_str()).unwrap_or("");
        let message = c.get("message").and_then(|s| s.as_str()).unwrap_or("");
        if status == "False" {
            let bad = matches!(
                reason,
                "Failed" | "InvalidRequest" | "InvalidCertificateRequest" | "Expired"
            ) || message.to_lowercase().contains("failed");
            if bad {
                return Some(CertInfo::failed(if message.is_empty() {
                    reason.to_string()
                } else {
                    message.to_string()
                }));
            }
        }
    }
    if let Some(created) = cert
        .pointer("/metadata/creationTimestamp")
        .and_then(|v| v.as_str())
    {
        if let Ok(t) = chrono::DateTime::parse_from_rfc3339(created) {
            let age = chrono::Utc::now().signed_duration_since(t.with_timezone(&chrono::Utc));
            if age.to_std().unwrap_or(Duration::ZERO) > STUCK_AFTER && !cert_ready(cert) {
                let msg = ready
                    .and_then(|c| c.get("message").and_then(|s| s.as_str()))
                    .unwrap_or("Certificate stuck pending");
                return Some(CertInfo::failed(msg.to_string()));
            }
        }
    }
    None
}

/// Ensure Ingress exists for `domain`. Debounced unless `force`.
pub async fn domain_tls_ensure(domain: &str, force: bool) -> CertInfo {
    let Some(k) = k8s() else {
        return CertInfo::disabled();
    };
    let domain = domain.trim().to_lowercase();
    if domain.is_empty() {
        return CertInfo::failed("invalid domain");
    }

    let lock = domain_lock(&domain);
    let _guard = lock.lock().await;

    if !force {
        let skip = {
            let map = last_ensure_map().lock().unwrap();
            map.get(&domain)
                .map(|t| t.elapsed() < Duration::from_secs(debounce_secs()))
                .unwrap_or(false)
        };
        if skip {
            return k
                .cert_info(&domain)
                .await
                .unwrap_or_else(|e| CertInfo::failed(e));
        }
    }

    if let Err(e) = k.ensure_ingress(&domain).await {
        return CertInfo::failed(e);
    }
    last_ensure_map()
        .lock()
        .unwrap()
        .insert(domain.clone(), Instant::now());

    k.cert_info(&domain)
        .await
        .unwrap_or_else(|e| CertInfo::failed(e))
}

pub async fn domain_tls_status(domain: &str) -> CertInfo {
    let Some(k) = k8s() else {
        return CertInfo::disabled();
    };
    let domain = domain.trim().to_lowercase();
    if domain.is_empty() {
        return CertInfo::failed("invalid domain");
    }
    k.cert_info(&domain)
        .await
        .unwrap_or_else(|e| CertInfo::failed(e))
}

pub async fn domain_tls_delete(domain: &str) -> Result<(), String> {
    let Some(k) = k8s() else {
        return Ok(());
    };
    let domain = domain.trim().to_lowercase();
    if domain.is_empty() {
        return Ok(());
    }
    let lock = domain_lock(&domain);
    let _guard = lock.lock().await;
    last_ensure_map().lock().unwrap().remove(&domain);
    k.delete_ingress(&domain).await
}

pub async fn domain_tls_status_sync(pool: &PgPool, domain_id: i64, info: &CertInfo) {
    let _ = sqlx::query(
        r#"
        UPDATE site.domain
        SET tls_status = $2, tls_error = $3, updated_ts = NOW()
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(domain_id)
    .bind(info.status.as_str())
    .bind(&info.error)
    .execute(pool)
    .await;
}
