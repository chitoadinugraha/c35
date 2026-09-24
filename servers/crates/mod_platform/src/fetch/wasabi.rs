use anyhow::{Context, Result};
use async_trait::async_trait;
use chrono::{DateTime, NaiveDate, Utc};
use c35_mod_fetch::FetchCtx;
use hmac::{Hmac, Mac};
use serde::Deserialize;
use serde_json::{json, Value};
use sha2::{Digest, Sha256};

use crate::fetch_vendor::VendorBillSource;
use crate::VendorCostLine;

const BILLING_HOST: &str = "billing.wasabisys.com";
const BILLING_SERVICE: &str = "billing";

pub struct WasabiConfig {
    pub access_key: String,
    pub secret_key: String,
    pub region: String,
}

impl WasabiConfig {
    pub fn from_env() -> Option<Self> {
        let access_key = std::env::var("WASABI_ACCESS_KEY")
            .ok()
            .map(|s| s.trim().to_string())
            .filter(|s| !s.is_empty())?;
        let secret_key = std::env::var("WASABI_SECRET_KEY")
            .ok()
            .map(|s| s.trim().to_string())
            .filter(|s| !s.is_empty())?;
        let region = std::env::var("WASABI_REGION")
            .ok()
            .map(|s| s.trim().to_string())
            .filter(|s| !s.is_empty())
            .unwrap_or_else(|| "ap-southeast-1".into());
        Some(Self {
            access_key,
            secret_key,
            region,
        })
    }
}

pub struct WasabiVendorSource {
    config: WasabiConfig,
    billing_host: String,
}

impl Default for WasabiVendorSource {
    fn default() -> Self {
        Self::new(WasabiConfig {
            access_key: String::new(),
            secret_key: String::new(),
            region: "ap-southeast-1".into(),
        })
    }
}

impl WasabiVendorSource {
    pub fn from_env() -> Option<Self> {
        WasabiConfig::from_env().map(Self::new)
    }

    pub fn new(config: WasabiConfig) -> Self {
        Self {
            config,
            billing_host: BILLING_HOST.into(),
        }
    }

    async fn fetch_signed(&self, http: &reqwest::Client, query: &str) -> Result<Value> {
        let path = "/";
        let url = format!("https://{}{}{}", self.billing_host, path, query);
        let now = Utc::now();
        let auth = sign_get(
            &self.config.access_key,
            &self.config.secret_key,
            &self.config.region,
            &self.billing_host,
            path,
            query,
            now,
        )?;
        let body = http
            .get(&url)
            .header("Authorization", auth)
            .header("x-amz-date", amz_date(now))
            .header("Accept", "application/json")
            .send()
            .await
            .context("wasabi billing request")?
            .error_for_status()
            .context("wasabi billing HTTP status")?
            .text()
            .await
            .context("wasabi billing body")?;
        serde_json::from_str(&body).or_else(|_| {
            anyhow::bail!("wasabi billing response is not JSON: {}", truncate(&body, 240))
        })
    }

    async fn fetch_billing_data(
        &self,
        http: &reqwest::Client,
        window: (NaiveDate, NaiveDate),
    ) -> Result<Value> {
        let query = format!(
            "?Action=BillingData&Version=1&StartTime={}&EndTime={}",
            window.0.format("%Y-%m-%d"),
            window.1.format("%Y-%m-%d"),
        );
        self.fetch_signed(http, &query).await
    }

    async fn fetch_utilization(&self, http: &reqwest::Client) -> Result<Value> {
        self.fetch_signed(http, "?Action=Utilization&Version=1")
            .await
    }
}

#[async_trait]
impl VendorBillSource for WasabiVendorSource {
    fn vendor(&self) -> &'static str {
        "wasabi"
    }

    async fn fetch_lines(
        &self,
        ctx: &FetchCtx,
        window: (NaiveDate, NaiveDate),
    ) -> Result<Vec<VendorCostLine>> {
        let billing = self
            .fetch_billing_data(&ctx.http, window)
            .await
            .context("wasabi billing data")?;
        let utilization = self
            .fetch_utilization(&ctx.http)
            .await
            .context("wasabi utilization")?;
        Ok(wasabi_lines_from_api(
            window,
            &billing,
            &utilization,
            &self.config.region,
        ))
    }
}

pub fn wasabi_external_ref(category: &str, window: (NaiveDate, NaiveDate)) -> String {
    format!("wasabi:{}:{}:{}", category, window.0, window.1)
}

pub fn wasabi_category(text: &str) -> &'static str {
    let t = text.to_ascii_lowercase();
    if t.contains("transfer")
        || t.contains("egress")
        || t.contains("outbound")
        || t.contains("network")
        || t.contains("download")
    {
        "network"
    } else if t.contains("storage") || t.contains("retention") || t.contains("active") {
        "storage"
    } else {
        "other"
    }
}

pub fn wasabi_parse_billing_lines(
    window: (NaiveDate, NaiveDate),
    billing: &Value,
) -> Vec<VendorCostLine> {
    let currency = billing
        .pointer("/BillingData/Currency")
        .or_else(|| billing.pointer("/billingData/currency"))
        .and_then(|v| v.as_str())
        .unwrap_or("USD")
        .to_string();
    let mut lines = Vec::new();
    for item in line_items_from_value(billing) {
        if item.amount == 0.0 {
            continue;
        }
        let label = if !item.description.is_empty() {
            item.description.clone()
        } else {
            item.category.clone()
        };
        let category = wasabi_category(&format!("{} {}", label, item.category));
        if category == "other" {
            continue;
        }
        let sku = if item.sku.is_empty() {
            category.into()
        } else {
            item.sku.clone()
        };
        let item_currency = if item.currency.is_empty() {
            currency.clone()
        } else {
            item.currency.clone()
        };
        lines.push(VendorCostLine {
            vendor: "wasabi",
            category,
            sku,
            description: label,
            period_start: window.0,
            period_end: window.1,
            amount_native: item.amount,
            currency: item_currency,
            source: "api",
            external_ref: wasabi_external_ref(category, window),
            status: "estimated",
            meta: json!({}),
        });
    }
    lines
}

pub fn wasabi_utilization_storage_gb(utilization: &Value, region: &str) -> Option<f64> {
    let region_lc = region.to_ascii_lowercase();
    for entry in utilization_entries(utilization) {
        let entry_region = entry
            .get("Region")
            .or_else(|| entry.get("region"))
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_ascii_lowercase();
        if !entry_region.is_empty() && entry_region != region_lc {
            continue;
        }
        if let Some(tb) = entry
            .get("NumBillableTB")
            .or_else(|| entry.get("numBillableTb"))
            .or_else(|| entry.get("numBillableTB"))
            .and_then(|v| v.as_f64().or_else(|| v.as_str().and_then(|s| s.parse().ok())))
        {
            return Some(tb * 1024.0);
        }
        if let Some(bytes) = entry
            .get("PaddedStorageSizeBytes")
            .or_else(|| entry.get("paddedStorageSizeBytes"))
            .and_then(|v| v.as_u64().or_else(|| v.as_str().and_then(|s| s.parse().ok())))
        {
            return Some(bytes as f64 / 1_073_741_824.0);
        }
    }
    None
}

pub fn wasabi_lines_from_api(
    window: (NaiveDate, NaiveDate),
    billing: &Value,
    utilization: &Value,
    region: &str,
) -> Vec<VendorCostLine> {
    let storage_gb = wasabi_utilization_storage_gb(utilization, region);
    let mut lines = wasabi_parse_billing_lines(window, billing);
    if lines.is_empty() {
        lines = wasabi_utilization_cost_lines(window, utilization, region);
    }
    if let Some(gb) = storage_gb {
        for line in &mut lines {
            if line.category == "storage" {
                line.meta["storage_gb"] = json!(gb);
            }
        }
        if lines.is_empty() {
            lines.push(VendorCostLine {
                vendor: "wasabi",
                category: "storage",
                sku: "utilization".into(),
                description: "Wasabi billable storage (utilization)".into(),
                period_start: window.0,
                period_end: window.1,
                amount_native: 0.0,
                currency: "USD".into(),
                source: "api",
                external_ref: wasabi_external_ref("storage", window),
                status: "estimated",
                meta: json!({ "storage_gb": gb }),
            });
        }
    }
    lines
}

fn truncate(s: &str, max: usize) -> String {
    if s.len() <= max {
        return s.to_string();
    }
    format!("{}...", &s[..max])
}

fn amz_date(now: DateTime<Utc>) -> String {
    now.format("%Y%m%dT%H%M%SZ").to_string()
}

fn sha256_hex(data: &[u8]) -> String {
    let digest = Sha256::digest(data);
    hex_encode(&digest)
}

fn hex_encode(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{:02x}", b)).collect()
}

type HmacSha256 = Hmac<Sha256>;

fn hmac_sha256(key: &[u8], data: &[u8]) -> Vec<u8> {
    let mut mac = HmacSha256::new_from_slice(key).expect("hmac key");
    mac.update(data);
    mac.finalize().into_bytes().to_vec()
}

fn sign_get(
    access_key: &str,
    secret_key: &str,
    region: &str,
    host: &str,
    path: &str,
    query: &str,
    now: DateTime<Utc>,
) -> Result<String> {
    let amz_date = amz_date(now);
    let date_stamp = now.format("%Y%m%d").to_string();
    let canonical_query = canonical_query_string(query);
    let canonical_headers = format!("host:{host}\nx-amz-date:{amz_date}\n");
    let signed_headers = "host;x-amz-date";
    let payload_hash = sha256_hex(b"");
    let canonical_request = format!(
        "GET\n{path}\n{canonical_query}\n{canonical_headers}\n{signed_headers}\n{payload_hash}"
    );
    let scope = format!("{date_stamp}/{region}/{BILLING_SERVICE}/aws4_request");
    let string_to_sign = format!(
        "AWS4-HMAC-SHA256\n{amz_date}\n{scope}\n{}",
        sha256_hex(canonical_request.as_bytes())
    );
    let k_date = hmac_sha256(format!("AWS4{secret_key}").as_bytes(), date_stamp.as_bytes());
    let k_region = hmac_sha256(&k_date, region.as_bytes());
    let k_service = hmac_sha256(&k_region, BILLING_SERVICE.as_bytes());
    let k_signing = hmac_sha256(&k_service, b"aws4_request");
    let signature = hex_encode(&hmac_sha256(&k_signing, string_to_sign.as_bytes()));
    Ok(format!(
        "AWS4-HMAC-SHA256 Credential={access_key}/{scope}, SignedHeaders={signed_headers}, Signature={signature}"
    ))
}

fn canonical_query_string(query: &str) -> String {
    let q = query.strip_prefix('?').unwrap_or(query);
    if q.is_empty() {
        return String::new();
    }
    let mut pairs: Vec<(String, String)> = q
        .split('&')
        .filter_map(|part| {
            let (k, v) = part.split_once('=').unwrap_or((part, ""));
            Some((k.to_string(), v.to_string()))
        })
        .collect();
    pairs.sort_by(|a, b| a.0.cmp(&b.0));
    pairs
        .into_iter()
        .map(|(k, v)| format!("{}={}", uri_encode(&k), uri_encode(&v)))
        .collect::<Vec<_>>()
        .join("&")
}

fn uri_encode(s: &str) -> String {
    urlencoding::encode(s).into_owned()
}

#[derive(Debug, Deserialize)]
struct WasabiLineItem {
    #[serde(default, alias = "Description", alias = "description")]
    description: String,
    #[serde(default, alias = "Category", alias = "category")]
    category: String,
    #[serde(default, alias = "Amount", alias = "amount")]
    amount: f64,
    #[serde(default, alias = "Sku", alias = "sku")]
    sku: String,
    #[serde(default, alias = "Currency", alias = "currency")]
    currency: String,
}

fn line_items_from_value(value: &Value) -> Vec<WasabiLineItem> {
    let mut out = Vec::new();
    if let Some(items) = value
        .pointer("/BillingData/LineItems")
        .or_else(|| value.pointer("/billingData/lineItems"))
        .and_then(|v| v.as_array())
    {
        for item in items {
            if let Ok(parsed) = serde_json::from_value::<WasabiLineItem>(item.clone()) {
                out.push(parsed);
            }
        }
    }
    if let Some(items) = value.pointer("/invoices").and_then(|v| v.as_array()) {
        for invoice in items {
            if let Some(items) = invoice
                .get("lineItems")
                .or_else(|| invoice.get("LineItems"))
                .and_then(|v| v.as_array())
            {
                for item in items {
                    if let Ok(parsed) = serde_json::from_value::<WasabiLineItem>(item.clone()) {
                        out.push(parsed);
                    }
                }
            }
        }
    }
    out
}

fn utilization_entries(utilization: &Value) -> Vec<&Value> {
    utilization
        .pointer("/Utilization")
        .or_else(|| utilization.pointer("/utilization"))
        .and_then(|v| v.as_array())
        .map(|arr| arr.iter().collect())
        .unwrap_or_default()
}

fn wasabi_utilization_cost_lines(
    window: (NaiveDate, NaiveDate),
    utilization: &Value,
    region: &str,
) -> Vec<VendorCostLine> {
    let mut lines = Vec::new();
    let region_lc = region.to_ascii_lowercase();
    for entry in utilization_entries(utilization) {
        let entry_region = entry
            .get("Region")
            .or_else(|| entry.get("region"))
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_ascii_lowercase();
        if !entry_region.is_empty() && entry_region != region_lc {
            continue;
        }
        for (field, category, label) in [
            ("StorageCharge", "storage", "Wasabi storage charge"),
            ("TimedActiveStorageCharge", "storage", "Wasabi timed active storage"),
            ("DataTransferCharge", "network", "Wasabi data transfer out"),
            ("EgressCharge", "network", "Wasabi egress"),
        ] {
            let amount = entry
                .get(field)
                .or_else(|| {
                    let camel = field
                        .chars()
                        .enumerate()
                        .map(|(i, c)| {
                            if i == 0 {
                                c.to_ascii_lowercase().to_string()
                            } else {
                                c.to_string()
                            }
                        })
                        .collect::<String>();
                    entry.get(&camel)
                })
                .and_then(|v| v.as_f64().or_else(|| v.as_str().and_then(|s| s.parse().ok())))
                .unwrap_or(0.0);
            if amount == 0.0 {
                continue;
            }
            lines.push(VendorCostLine {
                vendor: "wasabi",
                category,
                sku: category.into(),
                description: label.into(),
                period_start: window.0,
                period_end: window.1,
                amount_native: amount,
                currency: "USD".into(),
                source: "api",
                external_ref: wasabi_external_ref(category, window),
                status: "estimated",
                meta: json!({}),
            });
        }
    }
    lines
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sign_get_produces_authorization_header() {
        let now = DateTime::parse_from_rfc3339("2026-09-24T02:00:00Z")
            .unwrap()
            .with_timezone(&Utc);
        let auth = sign_get(
            "AKIATEST",
            "secret",
            "ap-southeast-1",
            BILLING_HOST,
            "/",
            "?Action=Utilization&Version=1",
            now,
        )
        .expect("sign");
        assert!(auth.starts_with("AWS4-HMAC-SHA256 Credential=AKIATEST/"));
        assert!(auth.contains("SignedHeaders=host;x-amz-date"));
        assert!(auth.contains("Signature="));
    }
}
