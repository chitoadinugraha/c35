use anyhow::{anyhow, Context, Result};
use async_trait::async_trait;
use chrono::NaiveDate;
use c35_mod_fetch::FetchCtx;
use jsonwebtoken::{encode, Algorithm, EncodingKey, Header};
use serde::Deserialize;
use serde_json::Value;

use crate::fetch_vendor::VendorBillSource;
use crate::VendorCostLine;

const BQ_SCOPE: &str = "https://www.googleapis.com/auth/bigquery";

pub struct GcpBillingConfig {
    pub project_id: String,
    pub dataset: String,
    pub table: String,
    pub credentials_json: String,
}

pub struct GcpVendorSource {
    config: Option<GcpBillingConfig>,
}

impl Default for GcpVendorSource {
    fn default() -> Self {
        Self { config: None }
    }
}

impl GcpVendorSource {
    pub fn new(config: GcpBillingConfig) -> Self {
        Self {
            config: Some(config),
        }
    }

    pub fn from_env() -> Option<Self> {
        gcp_billing_config_from_env().map(Self::new)
    }
}

pub fn gcp_billing_config_from_env() -> Option<GcpBillingConfig> {
    let project_id = std::env::var("GCP_BILLING_PROJECT_ID")
        .ok()
        .filter(|s| !s.trim().is_empty())?;
    let dataset = std::env::var("GCP_BILLING_DATASET")
        .ok()
        .filter(|s| !s.trim().is_empty())?;
    let table = std::env::var("GCP_BILLING_TABLE")
        .ok()
        .filter(|s| !s.trim().is_empty())?;
    let credentials_json = std::env::var("GOOGLE_APPLICATION_CREDENTIALS_JSON")
        .ok()
        .filter(|s| !s.trim().is_empty())?;
    Some(GcpBillingConfig {
        project_id,
        dataset,
        table,
        credentials_json,
    })
}

#[derive(Debug, Clone)]
pub struct GcpBqRow {
    pub service_description: String,
    pub sku_description: String,
    pub total_cost: f64,
    pub currency: String,
}

#[async_trait]
impl VendorBillSource for GcpVendorSource {
    fn vendor(&self) -> &'static str {
        "gcp"
    }

    async fn fetch_lines(
        &self,
        ctx: &FetchCtx,
        window: (NaiveDate, NaiveDate),
    ) -> Result<Vec<VendorCostLine>> {
        let Some(config) = &self.config else {
            return Ok(vec![]);
        };
        let token = gcp_access_token(&config.credentials_json, ctx).await?;
        let body = gcp_bq_query(config, window, &token, ctx).await?;
        let rows = gcp_parse_bq_query_response(&body)?;
        Ok(gcp_lines_from_bq_rows(&rows, window))
    }
}

pub fn gcp_classify_category(service_description: &str, sku_description: &str) -> &'static str {
    let service = service_description.to_ascii_lowercase();
    let sku = sku_description.to_ascii_lowercase();
    let hay = format!("{service} {sku}");
    if hay.contains("gemini")
        || hay.contains("vertex ai")
        || hay.contains("speech")
        || hay.contains("text-to-speech")
        || hay.contains("text to speech")
    {
        return "ai_api";
    }
    if sku.contains("persistent disk")
        || sku.contains("cloud storage")
        || service.contains("cloud storage")
    {
        return "storage";
    }
    if service.contains("kubernetes engine") || service.contains("compute engine") {
        return "compute";
    }
    if service.contains("networking")
        || service.contains("load balancing")
        || sku.contains("network ")
    {
        return "network";
    }
    "other"
}

pub fn gcp_external_ref(
    service_description: &str,
    sku_description: &str,
    period_start: NaiveDate,
    period_end: NaiveDate,
) -> String {
    let input = format!(
        "{}|{}|{}|{}",
        service_description, sku_description, period_start, period_end
    );
    blake3::hash(input.as_bytes()).to_hex().to_string()
}

pub fn gcp_lines_from_bq_rows(
    rows: &[GcpBqRow],
    window: (NaiveDate, NaiveDate),
) -> Vec<VendorCostLine> {
    rows.iter()
        .filter(|r| r.total_cost.abs() > f64::EPSILON)
        .map(|row| {
            let category = gcp_classify_category(&row.service_description, &row.sku_description);
            let description = format!("{} — {}", row.service_description, row.sku_description);
            VendorCostLine {
                vendor: "gcp",
                category,
                sku: row.sku_description.clone(),
                description,
                period_start: window.0,
                period_end: window.1,
                amount_native: row.total_cost,
                currency: row.currency.clone(),
                source: "api",
                external_ref: gcp_external_ref(
                    &row.service_description,
                    &row.sku_description,
                    window.0,
                    window.1,
                ),
                status: "estimated",
                meta: serde_json::json!({
                    "service_description": row.service_description,
                    "sku_description": row.sku_description,
                }),
            }
        })
        .collect()
}

pub fn gcp_parse_bq_query_response(body: &Value) -> Result<Vec<GcpBqRow>> {
    let fields = body
        .get("schema")
        .and_then(|s| s.get("fields"))
        .and_then(|f| f.as_array())
        .context("bigquery response missing schema.fields")?;
    let col = |name: &str| -> Result<usize> {
        fields
            .iter()
            .position(|f| f.get("name").and_then(|n| n.as_str()) == Some(name))
            .ok_or_else(|| anyhow!("bigquery schema missing column {name}"))
    };
    let service_i = col("service_description")?;
    let sku_i = col("sku_description")?;
    let cost_i = col("total_cost")?;
    let currency_i = col("currency")?;

    let rows = body
        .get("rows")
        .and_then(|r| r.as_array())
        .map(|r| r.as_slice())
        .unwrap_or(&[]);

    rows.iter()
        .map(|row| {
            let cells = row
                .get("f")
                .and_then(|f| f.as_array())
                .context("bigquery row missing f")?;
            let cell_str = |i: usize| -> Result<String> {
                cells
                    .get(i)
                    .and_then(|c| c.get("v"))
                    .and_then(|v| v.as_str())
                    .map(str::to_string)
                    .ok_or_else(|| anyhow!("bigquery cell {i} missing string value"))
            };
            let cell_f64 = |i: usize| -> Result<f64> {
                let v = cells
                    .get(i)
                    .and_then(|c| c.get("v"))
                    .context("bigquery cell missing v")?;
                if let Some(s) = v.as_str() {
                    return s.parse().context("bigquery float cell parse");
                }
                v.as_f64().context("bigquery float cell")
            };
            Ok(GcpBqRow {
                service_description: cell_str(service_i)?,
                sku_description: cell_str(sku_i)?,
                total_cost: cell_f64(cost_i)?,
                currency: cell_str(currency_i)?,
            })
        })
        .collect()
}

fn gcp_billing_sql(config: &GcpBillingConfig, window: (NaiveDate, NaiveDate)) -> String {
    let table = format!(
        "`{}.{}.{}`",
        config.project_id, config.dataset, config.table
    );
    format!(
        "SELECT service.description AS service_description, \
         sku.description AS sku_description, \
         SUM(cost) AS total_cost, \
         ANY_VALUE(currency) AS currency \
         FROM {table} \
         WHERE DATE(usage_start_time) BETWEEN DATE '{start}' AND DATE '{end}' \
         GROUP BY service.description, sku.description",
        start = window.0,
        end = window.1,
    )
}

async fn gcp_access_token(credentials_json: &str, ctx: &FetchCtx) -> Result<String> {
    let sa: ServiceAccountKey =
        serde_json::from_str(credentials_json).context("parse service account json")?;
    let now = chrono::Utc::now().timestamp();
    let claims = GoogleJwtClaims {
        iss: sa.client_email.clone(),
        scope: BQ_SCOPE,
        aud: sa.token_uri.clone(),
        exp: now + 3600,
        iat: now,
    };
    let key = EncodingKey::from_rsa_pem(sa.private_key.as_bytes())
        .context("parse service account private key")?;
    let jwt = encode(&Header::new(Algorithm::RS256), &claims, &key)
        .context("sign service account jwt")?;
    let res = ctx
        .http
        .post(&sa.token_uri)
        .form(&[
            ("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer"),
            ("assertion", &jwt),
        ])
        .send()
        .await
        .context("gcp token request")?;
    let status = res.status();
    let body: Value = res.json().await.context("gcp token response json")?;
    if !status.is_success() {
        return Err(anyhow!("gcp token error {status}: {body}"));
    }
    body.get("access_token")
        .and_then(|v| v.as_str())
        .map(str::to_string)
        .ok_or_else(|| anyhow!("gcp token response missing access_token"))
}

async fn gcp_bq_query(
    config: &GcpBillingConfig,
    window: (NaiveDate, NaiveDate),
    token: &str,
    ctx: &FetchCtx,
) -> Result<Value> {
    let url = format!(
        "https://bigquery.googleapis.com/bigquery/v2/projects/{}/queries",
        config.project_id
    );
    let query = gcp_billing_sql(config, window);
    let res = ctx
        .http
        .post(&url)
        .bearer_auth(token)
        .json(&serde_json::json!({
            "query": query,
            "useLegacySql": false,
        }))
        .send()
        .await
        .context("bigquery query request")?;
    let status = res.status();
    let body: Value = res.json().await.context("bigquery query response json")?;
    if !status.is_success() {
        return Err(anyhow!("bigquery query error {status}: {body}"));
    }
    if let Some(errs) = body.get("errors").and_then(|e| e.as_array()) {
        if !errs.is_empty() {
            return Err(anyhow!("bigquery query errors: {errs:?}"));
        }
    }
    Ok(body)
}

#[derive(Debug, Deserialize)]
struct ServiceAccountKey {
    client_email: String,
    private_key: String,
    #[serde(default = "default_token_uri")]
    token_uri: String,
}

fn default_token_uri() -> String {
    "https://oauth2.googleapis.com/token".into()
}

#[derive(Debug, serde::Serialize)]
struct GoogleJwtClaims {
    iss: String,
    scope: &'static str,
    aud: String,
    exp: i64,
    iat: i64,
}
