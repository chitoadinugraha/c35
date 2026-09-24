use anyhow::{anyhow, Context, Result};
use async_trait::async_trait;
use chrono::{Datelike, NaiveDate, Utc};
use c35_mod_fetch::FetchCtx;
use reqwest::Client;
use serde_json::{json, Value};

use crate::fetch_vendor::VendorBillSource;
use crate::VendorCostLine;

const CF_GRAPHQL_URL: &str = "https://api.cloudflare.com/client/v4/graphql";

pub struct CfVendorSource {
    account_id: String,
    api_token: String,
}

impl Default for CfVendorSource {
    fn default() -> Self {
        Self {
            account_id: String::new(),
            api_token: String::new(),
        }
    }
}

pub fn cf_from_env() -> Option<CfVendorSource> {
    let account_id = std::env::var("CLOUDFLARE_ACCOUNT_ID")
        .ok()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())?;
    let api_token = std::env::var("CLOUDFLARE_API_TOKEN")
        .ok()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())?;
    Some(CfVendorSource {
        account_id,
        api_token,
    })
}

#[async_trait]
impl VendorBillSource for CfVendorSource {
    fn vendor(&self) -> &'static str {
        "cf"
    }

    async fn fetch_lines(
        &self,
        ctx: &FetchCtx,
        window: (NaiveDate, NaiveDate),
    ) -> Result<Vec<VendorCostLine>> {
        let body = cf_graphql_query(
            &ctx.http,
            &self.account_id,
            &self.api_token,
            window,
        )
        .await?;
        Ok(parse_cf_graphql_response(&body, window))
    }
}

async fn cf_graphql_query(
    client: &Client,
    account_id: &str,
    api_token: &str,
    window: (NaiveDate, NaiveDate),
) -> Result<Value> {
    let since = format!("{}T00:00:00Z", window.0);
    let until = format!("{}T23:59:59Z", window.1);
    let query = r#"
query CfVendorBill($accountId: String!, $since: Time!, $until: Time!) {
  viewer {
    accounts(filter: { accountTag: $accountId }) {
      workersAiInferenceAdaptiveGroups(
        limit: 10000
        filter: { datetime_geq: $since, datetime_leq: $until }
        orderBy: [datetime_ASC]
      ) {
        dimensions { datetime model }
        sum { neurons }
      }
      aiGatewayRequestsAdaptiveGroups(
        limit: 10000
        filter: { datetime_geq: $since, datetime_leq: $until }
        orderBy: [datetime_ASC]
      ) {
        dimensions { datetime }
        sum { requests }
      }
      billingMetricsAdaptiveGroups(
        limit: 10000
        filter: { datetime_geq: $since, datetime_leq: $until }
        orderBy: [datetime_ASC]
      ) {
        dimensions { datetime metricName product }
        sum { cost }
      }
    }
  }
}
"#;
    let res = client
        .post(CF_GRAPHQL_URL)
        .header("Authorization", format!("Bearer {api_token}"))
        .json(&json!({
            "query": query,
            "variables": {
                "accountId": account_id,
                "since": since,
                "until": until,
            }
        }))
        .send()
        .await
        .context("cf graphql request")?;
    let status = res.status();
    let body: Value = res.json().await.context("cf graphql json")?;
    if !status.is_success() {
        return Err(anyhow!("cf graphql http {status}: {body}"));
    }
    if let Some(errs) = body.get("errors").and_then(Value::as_array) {
        if !errs.is_empty() {
            return Err(anyhow!("cf graphql errors: {errs:?}"));
        }
    }
    Ok(body)
}

pub fn parse_cf_graphql_response(body: &Value, window: (NaiveDate, NaiveDate)) -> Vec<VendorCostLine> {
    let account = body
        .pointer("/data/viewer/accounts/0")
        .or_else(|| body.pointer("/data/viewer/accounts").and_then(|a| a.get(0)));
    if account.is_none() {
        return vec![];
    }
    let account = account.unwrap();
    let mut lines = Vec::new();
    lines.extend(parse_cf_workers_ai_groups(account, window));
    lines.extend(parse_cf_ai_gateway_groups(account, window));
    lines.extend(parse_cf_billing_metric_groups(account, window));
    lines
}

fn parse_cf_workers_ai_groups(account: &Value, window: (NaiveDate, NaiveDate)) -> Vec<VendorCostLine> {
    let groups = account
        .get("workersAiInferenceAdaptiveGroups")
        .and_then(Value::as_array);
    let Some(groups) = groups else {
        return vec![];
    };
    let mut by_day: std::collections::BTreeMap<NaiveDate, f64> = std::collections::BTreeMap::new();
    for g in groups {
        let day = cf_group_day(g).unwrap_or(window.0);
        let neurons = g.pointer("/sum/neurons").and_then(Value::as_f64).unwrap_or(0.0);
        by_day.entry(day).and_modify(|v| *v += neurons).or_insert(neurons);
    }
    by_day
        .into_iter()
        .filter(|(_, neurons)| *neurons > 0.0)
        .map(|(day, neurons)| {
            let amount = cf_workers_ai_cost_usd(neurons);
            VendorCostLine {
                vendor: "cf",
                category: "ai_api",
                sku: "workers-ai".into(),
                description: format!("Workers AI inference ({:.0} neurons)", neurons),
                period_start: day,
                period_end: day,
                amount_native: amount,
                currency: "USD".into(),
                source: "api",
                external_ref: format!("cf:ai_api:workers-ai:{}", day),
                status: "estimated",
                meta: json!({ "neurons": neurons, "estimate": true }),
            }
        })
        .collect()
}

fn parse_cf_ai_gateway_groups(account: &Value, window: (NaiveDate, NaiveDate)) -> Vec<VendorCostLine> {
    let groups = account
        .get("aiGatewayRequestsAdaptiveGroups")
        .and_then(Value::as_array);
    let Some(groups) = groups else {
        return vec![];
    };
    let mut by_day: std::collections::BTreeMap<NaiveDate, f64> = std::collections::BTreeMap::new();
    for g in groups {
        let day = cf_group_day(g).unwrap_or(window.0);
        let requests = g.pointer("/sum/requests").and_then(Value::as_f64).unwrap_or(0.0);
        by_day.entry(day).and_modify(|v| *v += requests).or_insert(requests);
    }
    by_day
        .into_iter()
        .filter(|(_, requests)| *requests > 0.0)
        .map(|(day, requests)| {
            VendorCostLine {
                vendor: "cf",
                category: "ai_api",
                sku: "ai-gateway".into(),
                description: format!("AI Gateway requests ({:.0})", requests),
                period_start: day,
                period_end: day,
                amount_native: 0.0,
                currency: "USD".into(),
                source: "api",
                external_ref: format!("cf:ai_api:ai-gateway:{}", day),
                status: "estimated",
                meta: json!({ "requests": requests, "estimate": true }),
            }
        })
        .collect()
}

fn parse_cf_billing_metric_groups(account: &Value, window: (NaiveDate, NaiveDate)) -> Vec<VendorCostLine> {
    let groups = account
        .get("billingMetricsAdaptiveGroups")
        .and_then(Value::as_array);
    let Some(groups) = groups else {
        return vec![];
    };
    groups
        .iter()
        .filter_map(|g| {
            let day = cf_group_day(g).unwrap_or(window.0);
            let metric = g
                .pointer("/dimensions/metricName")
                .and_then(Value::as_str)
                .unwrap_or("");
            let product = g
                .pointer("/dimensions/product")
                .and_then(Value::as_str)
                .unwrap_or("");
            let label = format!("{product} {metric}").trim().to_string();
            let category = cf_category_for_label(&label);
            let cost = g.pointer("/sum/cost").and_then(Value::as_f64).unwrap_or(0.0);
            if cost <= 0.0 {
                return None;
            }
            let sku = cf_sku_slug(&label);
            let external_ref = format!("cf:{}:{}:{}", category, sku, day);
            Some(VendorCostLine {
                vendor: "cf",
                category,
                sku,
                description: if label.is_empty() {
                    "Cloudflare billing metric".into()
                } else {
                    label.clone()
                },
                period_start: day,
                period_end: day,
                amount_native: cost,
                currency: "USD".into(),
                source: "api",
                external_ref,
                status: "estimated",
                meta: json!({ "metric": metric, "product": product }),
            })
        })
        .collect()
}

fn cf_workers_ai_cost_usd(neurons: f64) -> f64 {
    // Cloudflare Workers AI list price ~$0.011 per 1k neurons (estimate).
    (neurons / 1000.0) * 0.011
}

fn cf_group_day(group: &Value) -> Option<NaiveDate> {
    let dt = group
        .pointer("/dimensions/datetime")
        .and_then(Value::as_str)?;
    NaiveDate::parse_from_str(dt.split('T').next().unwrap_or(dt), "%Y-%m-%d").ok()
}

pub fn cf_category_for_label(label: &str) -> &'static str {
    let s = label.to_ascii_lowercase();
    if s.contains("workers ai")
        || s.contains("workersai")
        || s.contains("ai gateway")
        || s.contains("aig")
        || s.contains("inference")
    {
        "ai_api"
    } else if s.contains("dns") || s.contains("registrar") || s.contains("domain") {
        "dns"
    } else if s.contains("zero trust")
        || s.contains("tunnel")
        || s.contains("warp")
        || s.contains("network")
    {
        "network"
    } else {
        "other"
    }
}

fn cf_sku_slug(label: &str) -> String {
    label
        .to_ascii_lowercase()
        .chars()
        .map(|c| if c.is_ascii_alphanumeric() { c } else { '-' })
        .collect::<String>()
        .split('-')
        .filter(|p| !p.is_empty())
        .take(6)
        .collect::<Vec<_>>()
        .join("-")
}

pub fn parse_cf_invoice_csv(bytes: &[u8]) -> Result<Vec<VendorCostLine>> {
    let text = std::str::from_utf8(bytes).context("cf invoice csv utf8")?;
    let rows = parse_csv_rows(text);
    if rows.is_empty() {
        return Ok(vec![]);
    }
    let header = rows[0]
        .iter()
        .map(|h| h.trim().to_ascii_lowercase())
        .collect::<Vec<_>>();
    let has_header = rows[0].iter().any(|h| {
        matches!(
            cf_csv_header_key(h).as_str(),
            "description" | "amount" | "currency" | "sku" | "category"
        )
    });
    let data_rows = if has_header { &rows[1..] } else { &rows[..] };
    let default_period = cf_invoice_default_period();
    let mut lines = Vec::new();
    for (i, row) in data_rows.iter().enumerate() {
        if row.iter().all(|c| c.trim().is_empty()) {
            continue;
        }
        let map = row_to_map(&header, row, has_header);
        let description = map
            .get("description")
            .or_else(|| map.get("line item"))
            .or_else(|| map.get("product"))
            .or_else(|| map.get("service"))
            .cloned()
            .filter(|s| !s.is_empty())
            .unwrap_or_else(|| format!("Cloudflare line {}", i + 1));
        let amount_raw = map
            .get("amount")
            .or_else(|| map.get("cost"))
            .or_else(|| map.get("total"))
            .or_else(|| map.get("price"))
            .context("cf invoice csv: amount column missing")?;
        let amount_native = parse_amount(amount_raw)?;
        if amount_native == 0.0 {
            continue;
        }
        let currency = map
            .get("currency")
            .or_else(|| map.get("curr"))
            .cloned()
            .filter(|s| !s.is_empty())
            .unwrap_or_else(|| "USD".into())
            .to_ascii_uppercase();
        let category = map
            .get("category")
            .map(|c| cf_normalize_category(c))
            .unwrap_or_else(|| cf_category_for_label(&description));
        let sku = map
            .get("sku")
            .cloned()
            .filter(|s| !s.is_empty())
            .unwrap_or_else(|| cf_sku_slug(&description));
        let period_start = map
            .get("period_start")
            .or_else(|| map.get("billing_period_start"))
            .and_then(|s| NaiveDate::parse_from_str(s, "%Y-%m-%d").ok())
            .unwrap_or(default_period.0);
        let period_end = map
            .get("period_end")
            .or_else(|| map.get("billing_period_end"))
            .and_then(|s| NaiveDate::parse_from_str(s, "%Y-%m-%d").ok())
            .unwrap_or(default_period.1);
        let hash = blake3::hash(format!("{}|{}|{}", description, amount_native, currency).as_bytes())
            .to_hex()
            .to_string();
        let external_ref = format!("cf:csv:{}:{}:{}", sku, period_start, &hash[..16]);
        lines.push(VendorCostLine {
            vendor: "cf",
            category,
            sku,
            description,
            period_start,
            period_end,
            amount_native,
            currency,
            source: "csv",
            external_ref,
            status: "finalized",
            meta: json!({ "import": "cf_invoice_csv", "row": i + 1 }),
        });
    }
    Ok(lines)
}

fn cf_normalize_category(raw: &str) -> &'static str {
    match raw.trim().to_ascii_lowercase().as_str() {
        "ai_api" | "ai" | "ai-api" => "ai_api",
        "dns" => "dns",
        "network" => "network",
        "compute" => "compute",
        "storage" => "storage",
        _ => cf_category_for_label(raw),
    }
}

fn cf_invoice_default_period() -> (NaiveDate, NaiveDate) {
    let today = Utc::now().date_naive();
    let first_this_month = NaiveDate::from_ymd_opt(today.year(), today.month(), 1).unwrap();
    let last_prev = first_this_month - chrono::Duration::days(1);
    let first_prev = NaiveDate::from_ymd_opt(last_prev.year(), last_prev.month(), 1).unwrap();
    (first_prev, last_prev)
}

fn parse_csv_rows(text: &str) -> Vec<Vec<String>> {
    text.lines()
        .filter(|l| !l.trim().is_empty())
        .map(parse_csv_line)
        .collect()
}

fn parse_csv_line(line: &str) -> Vec<String> {
    let mut fields = Vec::new();
    let mut cur = String::new();
    let mut in_quotes = false;
    for ch in line.chars() {
        match ch {
            '"' => in_quotes = !in_quotes,
            ',' if !in_quotes => {
                fields.push(cur.trim().to_string());
                cur.clear();
            }
            _ => cur.push(ch),
        }
    }
    fields.push(cur.trim().to_string());
    fields
}

fn cf_csv_header_key(raw: &str) -> String {
    match raw.trim().to_ascii_lowercase().as_str() {
        "description" | "line item" | "product" | "service" | "item" => "description".into(),
        "amount" | "cost" | "total" | "price" | "charge" => "amount".into(),
        "currency" | "curr" | "ccy" => "currency".into(),
        "sku" => "sku".into(),
        "category" | "cat" => "category".into(),
        "period_start" | "billing_period_start" | "start" => "period_start".into(),
        "period_end" | "billing_period_end" | "end" => "period_end".into(),
        other => other.into(),
    }
}

fn row_to_map(header: &[String], row: &[String], has_header: bool) -> std::collections::HashMap<String, String> {
    let mut map = std::collections::HashMap::new();
    if has_header {
        for (i, key) in header.iter().enumerate() {
            if key.is_empty() {
                continue;
            }
            let val = row.get(i).cloned().unwrap_or_default();
            map.insert(cf_csv_header_key(key), val);
        }
    } else if row.len() >= 3 {
        map.insert("description".into(), row[0].clone());
        map.insert("amount".into(), row[1].clone());
        map.insert("currency".into(), row[2].clone());
    }
    map
}

fn parse_amount(raw: &str) -> Result<f64> {
    let s = raw.trim().replace('$', "").replace(',', "");
    if s.is_empty() {
        return Ok(0.0);
    }
    if let Some(inner) = s.strip_prefix('(').and_then(|x| x.strip_suffix(')')) {
        return Ok(-inner.parse::<f64>().context("cf invoice amount")?);
    }
    s.parse::<f64>().context("cf invoice amount")
}
