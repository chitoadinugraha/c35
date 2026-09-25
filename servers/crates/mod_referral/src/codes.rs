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
               (EXTRACT(EPOCH FROM expires_at) * 1000)::float8 AS expires_at_ms,
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

#[derive(Debug, Clone)]
pub struct ReferralSignupCode {
    pub code: String,
    pub issued_by_iid: i64,
    pub issuer_name: String,
    pub issuer_pic: String,
    pub allow_short_id: bool,
}

fn referral_signup_code_valid(meta: &Value, used_count: i32, expires_at_ms: i64) -> bool {
    if meta_str(meta, "type") == "package" {
        return false;
    }
    if expires_at_ms > 0 && expires_at_ms <= chrono::Utc::now().timestamp_millis() {
        return false;
    }
    let max_uses = meta_i32(meta, "max_uses");
    !(max_uses > 0 && used_count >= max_uses)
}

fn referral_signup_code_from_row(code: &str, row: &sqlx::postgres::PgRow) -> Option<ReferralSignupCode> {
    let meta: Value = row.try_get("meta").unwrap_or(json!({}));
    let used_count: i32 = row.get("used_count");
    let expires_at_ms = row.get::<Option<f64>, _>("expires_at_ms").unwrap_or(0.0) as i64;
    if !referral_signup_code_valid(&meta, used_count, expires_at_ms) {
        return None;
    }
    Some(ReferralSignupCode {
        code: code.to_string(),
        issued_by_iid: row.get("issued_by_iid"),
        issuer_name: row.get("issuer_name"),
        issuer_pic: row.get::<String, _>("issuer_pic"),
        allow_short_id: meta
            .get("allow_short_id")
            .and_then(|v| v.as_bool())
            .unwrap_or(false),
    })
}

const REFERRAL_SIGNUP_CODE_SELECT: &str = r#"
        SELECT rc.code, rc.issued_by_iid, rc.used_count,
               (EXTRACT(EPOCH FROM rc.expires_at) * 1000)::float8 AS expires_at_ms,
               COALESCE(rc.meta, '{}'::jsonb) AS meta,
               i.name AS issuer_name, COALESCE(i.pic, '') AS issuer_pic
        FROM ai.referral_code rc
        JOIN ai.identity i ON i.id = rc.issued_by_iid
        WHERE rc.code = $1
"#;

pub async fn referral_signup_code_lookup(pool: &PgPool, raw_code: &str) -> Result<Option<ReferralSignupCode>, String> {
    let code = normalize_code(raw_code);
    if code.is_empty() {
        return Ok(None);
    }
    let row = sqlx::query(REFERRAL_SIGNUP_CODE_SELECT)
        .bind(&code)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
    Ok(row.as_ref().and_then(|r| referral_signup_code_from_row(&code, r)))
}

pub async fn referral_signup_code_redeem(pool: &PgPool, raw_code: &str) -> Result<ReferralSignupCode, String> {
    let code = normalize_code(raw_code);
    if code.is_empty() {
        return Err("Invalid or expired referral code.".into());
    }
    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;
    let row = sqlx::query(&format!("{REFERRAL_SIGNUP_CODE_SELECT} FOR UPDATE"))
        .bind(&code)
        .fetch_optional(&mut *tx)
        .await
        .map_err(|e| e.to_string())?;
    let Some(row) = row else {
        return Err("Invalid or expired referral code.".into());
    };
    let Some(info) = referral_signup_code_from_row(&code, &row) else {
        return Err("Invalid or expired referral code.".into());
    };
    sqlx::query("UPDATE ai.referral_code SET used_count = used_count + 1, updated_ts = NOW() WHERE code = $1")
        .bind(&code)
        .execute(&mut *tx)
        .await
        .map_err(|e| e.to_string())?;
    tx.commit().await.map_err(|e| e.to_string())?;
    Ok(info)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn referral_signup_code_valid_rejects_package_and_max_uses() {
        let meta = json!({"type": "package", "max_uses": 0});
        assert!(!referral_signup_code_valid(&meta, 0, 0));
        let meta = json!({"type": "referral", "max_uses": 2});
        assert!(referral_signup_code_valid(&meta, 1, 0));
        assert!(!referral_signup_code_valid(&meta, 2, 0));
        let meta = json!({"max_uses": 0});
        assert!(referral_signup_code_valid(&meta, 0, 0));
    }
}