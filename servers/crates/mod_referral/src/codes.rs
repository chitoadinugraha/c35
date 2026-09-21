use c35_proto::ReferralCodeDoc;
use serde_json::{json, Value};
use sqlx::{PgPool, Row};

const FX_IDR_PER_USD: f64 = 17_630.0;

#[derive(Debug, Clone)]
pub struct ReferralPackage {
    pub code: String,
    pub issued_by_iid: i64,
    pub name: String,
    pub price_usd: f64,
    pub price_idr: f64,
    pub duration_months: i32,
    pub base_plan_slug: String,
    pub max_uses: i32,
    pub used_count: i32,
    pub expires_at_ms: i64,
}

fn meta_str(meta: &Value, key: &str) -> String {
    meta.get(key)
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .trim()
        .to_string()
}

fn meta_f64(meta: &Value, key: &str) -> f64 {
    meta.get(key).and_then(|v| v.as_f64()).unwrap_or(0.0)
}

fn meta_i32(meta: &Value, key: &str) -> i32 {
    meta.get(key).and_then(|v| v.as_i64()).unwrap_or(0) as i32
}

pub fn referral_code_doc_from_row(code: &str, issued_by: i64, used_count: i32, expires_at_ms: i64, meta: Value) -> ReferralCodeDoc {
    ReferralCodeDoc {
        code: code.to_string(),
        r#type: meta_str(&meta, "type").if_empty_then("referral"),
        name: meta_str(&meta, "name"),
        issued_by,
        price_usd: meta_f64(&meta, "price_usd"),
        duration_months: meta_i32(&meta, "duration_months"),
        base_plan_slug: meta_str(&meta, "base_plan_slug"),
        max_uses: meta_i32(&meta, "max_uses"),
        used_count,
        expires_at_ms,
    }
}

trait IfEmptyThen {
    fn if_empty_then(self, fallback: &str) -> String;
}

impl IfEmptyThen for String {
    fn if_empty_then(self, fallback: &str) -> String {
        if self.is_empty() { fallback.to_string() } else { self }
    }
}

pub fn referral_code_meta_from_doc(doc: &ReferralCodeDoc) -> Value {
    let price_usd = doc.price_usd.max(0.0);
    let price_idr = (price_usd * FX_IDR_PER_USD).round();
    json!({
        "type": if doc.r#type.trim().is_empty() { "referral" } else { doc.r#type.trim() },
        "name": doc.name.trim(),
        "price_usd": price_usd,
        "price_idr": price_idr,
        "duration_months": doc.duration_months.max(0),
        "base_plan_slug": doc.base_plan_slug.trim(),
        "max_uses": doc.max_uses.max(0),
    })
}

pub async fn referral_package_get(pool: &PgPool, raw_code: &str) -> Result<Option<ReferralPackage>, String> {
    let code = normalize_code(raw_code);
    if code.is_empty() {
        return Ok(None);
    }
    let row = sqlx::query(
        r#"
        SELECT code, issued_by_iid, used_count,
               EXTRACT(EPOCH FROM expires_at) * 1000 AS expires_at_ms,
               COALESCE(meta, '{}'::jsonb) AS meta
        FROM ai.referral_code
        WHERE code = $1
        "#,
    )
    .bind(&code)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    let Some(row) = row else {
        return Ok(None);
    };
    let meta: Value = row.try_get("meta").unwrap_or(json!({}));
    let code_type = meta_str(&meta, "type");
    if code_type != "package" {
        return Ok(None);
    }
    let expires_at_ms = row.get::<Option<f64>, _>("expires_at_ms").unwrap_or(0.0) as i64;
    if expires_at_ms > 0 && expires_at_ms <= chrono::Utc::now().timestamp_millis() {
        return Ok(None);
    }
    let price_usd = meta_f64(&meta, "price_usd");
    let price_idr = meta_f64(&meta, "price_idr");
    let price_idr = if price_idr > 0.0 { price_idr } else { (price_usd * FX_IDR_PER_USD).round() };
    Ok(Some(ReferralPackage {
        code,
        issued_by_iid: row.get("issued_by_iid"),
        name: meta_str(&meta, "name"),
        price_usd,
        price_idr,
        duration_months: meta_i32(&meta, "duration_months"),
        base_plan_slug: meta_str(&meta, "base_plan_slug"),
        max_uses: meta_i32(&meta, "max_uses"),
        used_count: row.get("used_count"),
        expires_at_ms,
    }))
}

pub fn normalize_code(raw: &str) -> String {
    raw.chars()
        .filter(|c| c.is_ascii_alphanumeric())
        .collect::<String>()
        .to_uppercase()
}