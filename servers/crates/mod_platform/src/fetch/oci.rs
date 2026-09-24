use std::io::Read;

use anyhow::{anyhow, Context, Result};
use async_trait::async_trait;
use base64::Engine;
use blake3;
use chrono::NaiveDate;
use c35_mod_fetch::FetchCtx;
use rsa::pkcs1::DecodeRsaPrivateKey;
use rsa::pkcs8::DecodePrivateKey;
use rsa::pkcs1v15::SigningKey;
use rsa::signature::{SignatureEncoding, Signer};
use rsa::RsaPrivateKey;
use serde::Deserialize;
use serde_json::Value;
use sha2::{Digest, Sha256};

use crate::fetch_vendor::VendorBillSource;
use crate::VendorCostLine;

const USAGE_API_PATH: &str = "/20200408/UsageSummary";

pub struct OciConfig {
    pub tenancy_ocid: String,
    pub user_ocid: String,
    pub fingerprint: String,
    pub private_key_pem: String,
    pub region: String,
    pub compartment_ocid: String,
}

impl OciConfig {
    pub fn from_env() -> Option<Self> {
        let tenancy_ocid = env_var("OCI_TENANCY_OCID")?;
        let user_ocid = env_var("OCI_USER_OCID")?;
        let fingerprint = env_var("OCI_FINGERPRINT")?;
        let compartment_ocid = env_var("OCI_COMPARTMENT_OCID")?;
        let region = env_var("OCI_REGION").unwrap_or_else(|| "ap-southeast-1".into());
        let private_key_pem = load_private_key_pem()?;
        Some(Self {
            tenancy_ocid,
            user_ocid,
            fingerprint,
            private_key_pem,
            region,
            compartment_ocid,
        })
    }
}

pub struct OciVendorSource {
    config: OciConfig,
    private_key: RsaPrivateKey,
}

impl OciVendorSource {
    pub fn from_env() -> Option<Self> {
        let config = OciConfig::from_env()?;
        let private_key = parse_private_key(&config.private_key_pem).ok()?;
        Some(Self {
            config,
            private_key,
        })
    }

    pub fn new(config: OciConfig) -> Result<Self> {
        let private_key = parse_private_key(&config.private_key_pem)?;
        Ok(Self {
            config,
            private_key,
        })
    }

    fn host(&self) -> String {
        format!("usage.{}.oci.oraclecloud.com", self.config.region)
    }

    fn usage_url(&self, path: &str) -> String {
        format!("https://{}{}", self.host(), path)
    }

    async fn fetch_usage_pages(
        &self,
        http: &reqwest::Client,
        window: (NaiveDate, NaiveDate),
    ) -> Result<Vec<OciUsageItem>> {
        let body = build_usage_request(&self.config, window);
        let mut path = USAGE_API_PATH.to_string();
        let mut items = Vec::new();

        loop {
            let page = self
                .signed_post(http, &path, &body)
                .await
                .with_context(|| format!("OCI UsageSummary {path}"))?;
            items.extend(parse_usage_items(&page.body)?);
            match page.next_path {
                Some(next) => path = next,
                None => break,
            }
        }

        Ok(items)
    }

    async fn signed_post(
        &self,
        http: &reqwest::Client,
        path: &str,
        body: &str,
    ) -> Result<OciUsagePage> {
        let host = self.host();
        let body_bytes = body.as_bytes();
        let (date, authorization, content_sha256) =
            sign_post_request(&self.private_key, &self.config, &host, path, body_bytes)?;

        let resp = http
            .post(self.usage_url(path))
            .header("date", date)
            .header("authorization", authorization)
            .header("x-content-sha256", content_sha256)
            .header("content-type", "application/json")
            .header("content-length", body_bytes.len().to_string())
            .header("host", &host)
            .body(body.to_string())
            .send()
            .await
            .context("OCI UsageSummary HTTP")?;

        if !resp.status().is_success() {
            let status = resp.status();
            let text = resp.text().await.unwrap_or_default();
            return Err(anyhow!("OCI UsageSummary {status}: {text}"));
        }

        let next_path = resp
            .headers()
            .get("opc-next-page")
            .and_then(|v| v.to_str().ok())
            .map(str::to_string);
        let body = resp.text().await.context("OCI UsageSummary body")?;
        Ok(OciUsagePage { body, next_path })
    }
}

struct OciUsagePage {
    body: String,
    next_path: Option<String>,
}

#[derive(Debug, Deserialize)]
struct OciUsageItem {
    #[serde(default)]
    service: String,
    #[serde(default, rename = "skuName")]
    sku_name: String,
    #[serde(default, rename = "computedAmount")]
    computed_amount: f64,
    #[serde(default)]
    currency: String,
    #[serde(default, rename = "timeUsageStarted")]
    time_usage_started: String,
}

#[async_trait]
impl VendorBillSource for OciVendorSource {
    fn vendor(&self) -> &'static str {
        "oci"
    }

    async fn fetch_lines(
        &self,
        ctx: &FetchCtx,
        window: (NaiveDate, NaiveDate),
    ) -> Result<Vec<VendorCostLine>> {
        let items = self.fetch_usage_pages(&ctx.http, window).await?;
        Ok(items_to_lines(
            &items,
            &self.config.compartment_ocid,
            window,
            "estimated",
        ))
    }
}

fn env_var(key: &str) -> Option<String> {
    std::env::var(key).ok().map(|v| v.trim().to_string()).filter(|v| !v.is_empty())
}

fn load_private_key_pem() -> Option<String> {
    if let Some(path) = env_var("OCI_PRIVATE_KEY_PATH") {
        if let Ok(pem) = std::fs::read_to_string(&path) {
            return Some(normalize_pem(&pem));
        }
    }
    if let Some(pem) = env_var("OCI_PRIVATE_KEY") {
        return Some(normalize_pem(&pem));
    }
    let path = env_var("OCI_PRIVATE_KEY_PATH")?;
    let mut file = std::fs::File::open(&path).ok()?;
    let mut pem = String::new();
    file.read_to_string(&mut pem).ok()?;
    Some(normalize_pem(&pem))
}

fn normalize_pem(pem: &str) -> String {
    pem.replace("\\n", "\n").trim().to_string()
}

fn parse_private_key(pem: &str) -> Result<RsaPrivateKey> {
    RsaPrivateKey::from_pkcs1_pem(pem)
        .or_else(|_| RsaPrivateKey::from_pkcs8_pem(pem))
        .context("parse OCI private key PEM")
}

fn sha256_base64(data: &[u8]) -> String {
    let hash = Sha256::digest(data);
    base64::engine::general_purpose::STANDARD.encode(hash)
}

fn sign_post_request(
    private_key: &RsaPrivateKey,
    config: &OciConfig,
    host: &str,
    path: &str,
    body: &[u8],
) -> Result<(String, String, String)> {
    let date = chrono::Utc::now()
        .format("%a, %d %b %Y %H:%M:%S GMT")
        .to_string();
    let content_sha256 = sha256_base64(body);
    let content_type = "application/json";
    let content_length = body.len().to_string();
    let request_target = format!("post {path}");
    let signing_string = format!(
        "(request-target): {request_target}\nhost: {host}\ndate: {date}\nx-content-sha256: {content_sha256}\ncontent-type: {content_type}\ncontent-length: {content_length}"
    );

    let signing_key = SigningKey::<Sha256>::new(private_key.clone());
    let signature = signing_key.sign(signing_string.as_bytes());
    let sig_b64 = base64::engine::general_purpose::STANDARD.encode(signature.to_bytes());
    let key_id = format!(
        "{}/{}/{}",
        config.tenancy_ocid, config.user_ocid, config.fingerprint
    );
    let headers = "(request-target) host date x-content-sha256 content-type content-length";
    let authorization = format!(
        r#"Signature version="1",keyId="{key_id}",algorithm="rsa-sha256",headers="{headers}",signature="{sig_b64}""#
    );
    Ok((date, authorization, content_sha256))
}

fn build_usage_request(config: &OciConfig, window: (NaiveDate, NaiveDate)) -> String {
    let body = serde_json::json!({
        "tenantId": config.tenancy_ocid,
        "timeUsageStarted": oci_time_start(window.0),
        "timeUsageEnded": oci_time_end(window.1),
        "granularity": "DAILY",
        "queryType": "COST",
        "groupBy": ["service", "skuName"],
        "filter": {
            "operator": "AND",
            "dimensions": [{
                "key": "compartmentId",
                "value": config.compartment_ocid
            }]
        }
    });
    body.to_string()
}

fn oci_time_start(d: NaiveDate) -> String {
    format!("{d}T00:00:00.000Z")
}

fn oci_time_end(d: NaiveDate) -> String {
    format!("{d}T23:59:59.999Z")
}

pub fn parse_usage_response(
    body: &str,
    compartment_ocid: &str,
    window: (NaiveDate, NaiveDate),
    status: &'static str,
) -> Result<Vec<VendorCostLine>> {
    let items = parse_usage_items(body)?;
    Ok(items_to_lines(&items, compartment_ocid, window, status))
}

fn parse_usage_items(body: &str) -> Result<Vec<OciUsageItem>> {
    let value: Value = serde_json::from_str(body).context("OCI usage JSON")?;
    let items = value
        .get("items")
        .and_then(|v| serde_json::from_value(v.clone()).ok())
        .unwrap_or_default();
    Ok(items)
}

fn items_to_lines(
    items: &[OciUsageItem],
    compartment_ocid: &str,
    window: (NaiveDate, NaiveDate),
    status: &'static str,
) -> Vec<VendorCostLine> {
    items
        .iter()
        .filter(|item| item.computed_amount.abs() > f64::EPSILON)
        .map(|item| {
            let day = usage_day(&item.time_usage_started).unwrap_or(window.0);
            let sku = if item.sku_name.is_empty() {
                item.service.clone()
            } else {
                item.sku_name.clone()
            };
            let currency = if item.currency.is_empty() {
                "USD".to_string()
            } else {
                item.currency.clone()
            };
            VendorCostLine {
                vendor: "oci",
                category: oci_service_category(&item.service),
                sku: sku.clone(),
                description: format!("{} — {}", item.service, sku),
                period_start: day,
                period_end: day,
                amount_native: item.computed_amount,
                currency,
                source: "api",
                external_ref: oci_external_ref(compartment_ocid, &item.service, &sku, day),
                status,
                meta: serde_json::json!({
                    "service": item.service,
                    "skuName": item.sku_name,
                    "timeUsageStarted": item.time_usage_started,
                }),
            }
        })
        .collect()
}

fn usage_day(time_usage_started: &str) -> Option<NaiveDate> {
    NaiveDate::parse_from_str(&time_usage_started[..10.min(time_usage_started.len())], "%Y-%m-%d")
        .ok()
}

pub fn oci_service_category(service: &str) -> &'static str {
    let s = service.to_ascii_lowercase();
    if s.contains("compute")
        || s.contains("kubernetes")
        || s.contains("container")
        || s.contains("oke")
        || s.contains("functions")
    {
        "compute"
    } else if s.contains("storage")
        || s.contains("volume")
        || s.contains("object")
        || s.contains("block")
        || s.contains("archive")
    {
        "storage"
    } else if s.contains("network")
        || s.contains("load balancer")
        || s.contains("vcn")
        || s.contains("dns")
        || s.contains("fastconnect")
    {
        "network"
    } else {
        "other"
    }
}

pub fn oci_external_ref(compartment_ocid: &str, service: &str, sku: &str, day: NaiveDate) -> String {
    let key = format!("{compartment_ocid}|{service}|{sku}|{day}");
    blake3::hash(key.as_bytes()).to_hex().to_string()
}
