use std::collections::HashMap;

use anyhow::{bail, Context, Result};
use chrono::NaiveDate;
use c35_store::snowflake_id;
use serde_json::json;
use sqlx::PgPool;

use crate::fetch::{
    cf_category_for_label, gcp_classify_category, oci_service_category, parse_cf_invoice_csv,
    wasabi_category,
};

#[derive(Debug)]
pub struct VendorCostLine {
    pub vendor: &'static str,
    pub category: &'static str,
    pub sku: String,
    pub description: String,
    pub period_start: NaiveDate,
    pub period_end: NaiveDate,
    pub amount_native: f64,
    pub currency: String,
    pub source: &'static str,
    pub external_ref: String,
    pub status: &'static str,
    pub meta: serde_json::Value,
}

pub async fn vendor_cost_upsert_batch(pool: &PgPool, lines: &[VendorCostLine]) -> Result<usize> {
    let mut n = 0usize;
    for line in lines {
        let amount_usd = crate::fx_usd::amount_to_usd(pool, line.amount_native, &line.currency).await?;
        if line.external_ref.is_empty() {
            sqlx::query(
                r#"
                INSERT INTO ai.platform_vendor_cost (
                    id, vendor, category, sku, description,
                    period_start, period_end,
                    amount_native, currency, amount_usd,
                    source, external_ref, status, meta, fetched_ts
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14::jsonb, NOW())
                "#,
            )
            .bind(snowflake_id())
            .bind(line.vendor)
            .bind(line.category)
            .bind(&line.sku)
            .bind(&line.description)
            .bind(line.period_start)
            .bind(line.period_end)
            .bind(line.amount_native)
            .bind(&line.currency)
            .bind(amount_usd)
            .bind(line.source)
            .bind(&line.external_ref)
            .bind(line.status)
            .bind(&line.meta)
            .execute(pool)
            .await
            .context("platform_vendor_cost insert")?;
        } else {
            sqlx::query(
                r#"
                INSERT INTO ai.platform_vendor_cost (
                    id, vendor, category, sku, description,
                    period_start, period_end,
                    amount_native, currency, amount_usd,
                    source, external_ref, status, meta, fetched_ts
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14::jsonb, NOW())
                ON CONFLICT (vendor, external_ref) WHERE external_ref <> '' AND deleted_ts IS NULL
                DO UPDATE SET
                    category = EXCLUDED.category,
                    sku = EXCLUDED.sku,
                    description = EXCLUDED.description,
                    period_start = EXCLUDED.period_start,
                    period_end = EXCLUDED.period_end,
                    amount_native = EXCLUDED.amount_native,
                    currency = EXCLUDED.currency,
                    amount_usd = EXCLUDED.amount_usd,
                    source = EXCLUDED.source,
                    status = EXCLUDED.status,
                    meta = EXCLUDED.meta,
                    fetched_ts = NOW(),
                    updated_ts = NOW()
                "#,
            )
            .bind(snowflake_id())
            .bind(line.vendor)
            .bind(line.category)
            .bind(&line.sku)
            .bind(&line.description)
            .bind(line.period_start)
            .bind(line.period_end)
            .bind(line.amount_native)
            .bind(&line.currency)
            .bind(amount_usd)
            .bind(line.source)
            .bind(&line.external_ref)
            .bind(line.status)
            .bind(&line.meta)
            .execute(pool)
            .await
            .context("platform_vendor_cost upsert")?;
        }
        n += 1;
    }
    Ok(n)
}

pub fn parse_vendor_csv(
    vendor: &str,
    bytes: &[u8],
    period_start: NaiveDate,
    period_end: NaiveDate,
    default_category: &str,
    finalized: bool,
) -> Result<Vec<VendorCostLine>> {
    let status = if finalized { "finalized" } else { "estimated" };
    let lines = match vendor {
        "cf" => parse_cf_invoice_csv(bytes)?,
        "oci" | "gcp" | "wasabi" => {
            parse_generic_vendor_csv(vendor, bytes, default_category, period_start, period_end)?
        }
        other => bail!("unsupported vendor for csv import: {}", other),
    };
    Ok(lines
        .into_iter()
        .map(|line| apply_csv_import_params(line, vendor, period_start, period_end, status))
        .collect())
}

fn apply_csv_import_params(
    mut line: VendorCostLine,
    vendor: &str,
    period_start: NaiveDate,
    period_end: NaiveDate,
    status: &'static str,
) -> VendorCostLine {
    line.period_start = period_start;
    line.period_end = period_end;
    line.status = status;
    if line.source == "csv" {
        let hash = line.external_ref.rsplit(':').next().unwrap_or("");
        line.external_ref = format!("{}:csv:{}:{}:{}", vendor, line.sku, period_start, hash);
    }
    line
}

fn parse_generic_vendor_csv(
    vendor: &str,
    bytes: &[u8],
    default_category: &str,
    period_start: NaiveDate,
    period_end: NaiveDate,
) -> Result<Vec<VendorCostLine>> {
    let text = std::str::from_utf8(bytes).context("vendor csv utf8")?;
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
            vendor_csv_header_key(h).as_str(),
            "sku" | "description" | "amount" | "currency" | "category"
        )
    });
    let data_rows = if has_header { &rows[1..] } else { &rows[..] };
    let default_cat = normalize_vendor_category(default_category);
    let mut lines = Vec::new();
    for (i, row) in data_rows.iter().enumerate() {
        if row.iter().all(|c| c.trim().is_empty()) {
            continue;
        }
        let map = vendor_row_to_map(&header, row, has_header);
        let description = map
            .get("description")
            .or_else(|| map.get("line item"))
            .or_else(|| map.get("product"))
            .or_else(|| map.get("service"))
            .cloned()
            .filter(|s| !s.is_empty())
            .unwrap_or_else(|| format!("{} line {}", vendor, i + 1));
        let amount_raw = map
            .get("amount")
            .or_else(|| map.get("cost"))
            .or_else(|| map.get("total"))
            .or_else(|| map.get("price"))
            .context("vendor csv: amount column missing")?;
        let amount_native = parse_csv_amount(amount_raw)?;
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
        let sku = map
            .get("sku")
            .cloned()
            .filter(|s| !s.is_empty())
            .unwrap_or_else(|| vendor_sku_slug(&description));
        let category = map
            .get("category")
            .map(|c| normalize_vendor_category(c))
            .unwrap_or_else(|| {
                let inferred = vendor_category_for_label(vendor, &description, &sku, default_cat);
                if inferred == "other" {
                    default_cat
                } else {
                    inferred
                }
            });
        let row_period_start = map
            .get("period_start")
            .and_then(|s| NaiveDate::parse_from_str(s, "%Y-%m-%d").ok())
            .unwrap_or(period_start);
        let row_period_end = map
            .get("period_end")
            .and_then(|s| NaiveDate::parse_from_str(s, "%Y-%m-%d").ok())
            .unwrap_or(period_end);
        let hash = blake3::hash(format!("{}|{}|{}", description, amount_native, currency).as_bytes())
            .to_hex()
            .to_string();
        let external_ref = format!(
            "{}:csv:{}:{}:{}",
            vendor,
            sku,
            row_period_start,
            &hash[..16]
        );
        lines.push(VendorCostLine {
            vendor: vendor_static(vendor),
            category,
            sku,
            description,
            period_start: row_period_start,
            period_end: row_period_end,
            amount_native,
            currency,
            source: "csv",
            external_ref,
            status: "estimated",
            meta: json!({ "import": "vendor_csv", "row": i + 1 }),
        });
    }
    Ok(lines)
}

fn vendor_static(vendor: &str) -> &'static str {
    match vendor {
        "oci" => "oci",
        "gcp" => "gcp",
        "cf" => "cf",
        "wasabi" => "wasabi",
        _ => "other",
    }
}

fn vendor_category_for_label(
    vendor: &str,
    description: &str,
    sku: &str,
    default: &'static str,
) -> &'static str {
    match vendor {
        "oci" => oci_service_category(description),
        "gcp" => gcp_classify_category(description, sku),
        "wasabi" => wasabi_category(description),
        "cf" => cf_category_for_label(description),
        _ => default,
    }
}

fn normalize_vendor_category(raw: &str) -> &'static str {
    match raw.trim().to_ascii_lowercase().as_str() {
        "ai_api" | "ai" | "ai-api" => "ai_api",
        "dns" => "dns",
        "network" | "net" => "network",
        "compute" => "compute",
        "storage" => "storage",
        "other" => "other",
        _ => "other",
    }
}

fn vendor_sku_slug(label: &str) -> String {
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

fn vendor_csv_header_key(raw: &str) -> String {
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

fn vendor_row_to_map(header: &[String], row: &[String], has_header: bool) -> HashMap<String, String> {
    let mut map = HashMap::new();
    if has_header {
        for (i, key) in header.iter().enumerate() {
            if key.is_empty() {
                continue;
            }
            let val = row.get(i).cloned().unwrap_or_default();
            map.insert(vendor_csv_header_key(key), val);
        }
    } else if row.len() >= 3 {
        map.insert("sku".into(), row[0].clone());
        map.insert("description".into(), row[1].clone());
        map.insert("amount".into(), row[2].clone());
        if row.len() > 3 {
            map.insert("currency".into(), row[3].clone());
        }
        if row.len() > 4 {
            map.insert("category".into(), row[4].clone());
        }
    }
    map
}

fn parse_csv_amount(raw: &str) -> Result<f64> {
    let s = raw.trim().replace('$', "").replace(',', "");
    if s.is_empty() {
        return Ok(0.0);
    }
    if let Some(inner) = s.strip_prefix('(').and_then(|x| x.strip_suffix(')')) {
        return Ok(-inner.parse::<f64>().context("vendor csv amount")?);
    }
    s.parse::<f64>().context("vendor csv amount")
}

pub async fn vendor_cost_finalize_period(
    pool: &PgPool,
    vendor: &str,
    period_start: NaiveDate,
    period_end: NaiveDate,
) -> Result<u64> {
    let r = sqlx::query(
        r#"
        UPDATE ai.platform_vendor_cost
        SET status = 'finalized', updated_ts = NOW()
        WHERE vendor = $1
          AND period_start = $2
          AND period_end = $3
          AND deleted_ts IS NULL
        "#,
    )
    .bind(vendor)
    .bind(period_start)
    .bind(period_end)
    .execute(pool)
    .await
    .context("platform_vendor_cost finalize")?;
    Ok(r.rows_affected())
}
