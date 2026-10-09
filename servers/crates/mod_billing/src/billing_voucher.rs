use c35_mod_referral::normalize_code;
use c35_proto::{
    BillingVoucherDoc, BillingVoucherRedeemDoc, ReqBillingVoucherIssue, ReqBillingVoucherLimitGet,
    ReqBillingVoucherLimitPut, ReqBillingVoucherList, ReqBillingVoucherRedeemList, ReqBillingVoucherVoid,
    ResBillingVoucherIssue, ResBillingVoucherLimit, ResBillingVoucherList, ResBillingVoucherRedeemList,
    ResBillingVoucherVoid,
};
use c35_store::snowflake_id;
use serde_json::json;
use sqlx::{PgPool, Row};

use crate::billing_entitlement::EntitlementGrantSpec;

const VOUCHER_ISSUE_ROLES: &[&str] = &["marketing", "finance", "director", "root"];

pub async fn billing_voucher_issue(
    pool: &PgPool,
    issuer_iid: i64,
    req: ReqBillingVoucherIssue,
) -> Result<ResBillingVoucherIssue, String> {
    voucher_issue_access(pool, issuer_iid).await?;
    let kind = req.kind.trim().to_lowercase();
    let face = req.face_value_idr.max(0.0);
    if face <= 0.0 {
        return Err("face_value_idr required".into());
    }
    let qty = req.quantity.max(1).min(50);
    let max_uses = 1;
    let expires = if req.expires_at_ms > 0 {
        chrono::DateTime::from_timestamp_millis(req.expires_at_ms)
    } else if req.expires_at_ms == 0 {
        None
    } else {
        None
    };
    let scope = req.scope.trim().to_lowercase();
    let scope = if scope.is_empty() { "user" } else { scope.as_str() };
    let billing_period = req.billing_period.trim().to_lowercase();
    let billing_period = if billing_period.is_empty() {
        "monthly"
    } else {
        billing_period.as_str()
    };
    let list_price = req.list_price_idr.max(0.0);
    let channel = issuer_channel(pool, issuer_iid).await?;
    let custom_alien = req.alien_pool_limit_idr.max(0.0);
    let custom_frontier = req.frontier_pool_limit_idr.max(0.0);
    let mut codes = Vec::new();
    for _ in 0..qty {
        marketing_limit_charge(pool, issuer_iid, face).await?;
        let code = if qty == 1 && !req.code.trim().is_empty() {
            normalize_voucher_code(&req.code)
        } else {
            normalize_voucher_code("")
        };
        if code.is_empty() {
            return Err("invalid code".into());
        }
        let meta = match kind.as_str() {
            "credit" => {
                let credit = req.credit_idr.max(0.0);
                if credit <= 0.0 {
                    return Err("credit_idr required".into());
                }
                json!({
                    "type": "credit",
                    "prepaid": true,
                    "name": req.name.trim(),
                    "face_value_idr": face,
                    "marketing_face_idr": face,
                    "list_price_idr": list_price,
                    "price_idr": 0.0,
                    "price_usd": 0.0,
                    "credit_idr": credit,
                    "max_uses": max_uses,
                    "payment_ref": req.payment_ref.trim(),
                    "issued_channel": channel,
                    "scope": scope,
                    "billing_period": billing_period,
                })
            }
            "package" | "" => {
                let slug = req.plan_slug.trim();
                if slug.is_empty() && custom_alien <= 0.0 {
                    return Err("plan_slug or custom pools required".into());
                }
                let months = if billing_period == "yearly" {
                    12
                } else {
                    req.duration_months.max(1)
                };
                let mut m = json!({
                    "type": "package",
                    "prepaid": true,
                    "name": req.name.trim(),
                    "face_value_idr": face,
                    "marketing_face_idr": face,
                    "list_price_idr": list_price,
                    "price_idr": 0.0,
                    "price_usd": 0.0,
                    "base_plan_slug": slug,
                    "duration_months": months,
                    "max_uses": max_uses,
                    "payment_ref": req.payment_ref.trim(),
                    "issued_channel": channel,
                    "scope": scope,
                    "billing_period": billing_period,
                });
                if custom_alien > 0.0 || custom_frontier > 0.0 {
                    if let Some(obj) = m.as_object_mut() {
                        obj.insert("alien_pool_limit_idr".into(), json!(custom_alien));
                        obj.insert("frontier_pool_limit_idr".into(), json!(custom_frontier));
                        obj.insert("custom_package".into(), json!(true));
                    }
                }
                m
            }
            _ => return Err("kind must be package or credit".into()),
        };

        sqlx::query(
            r#"
            INSERT INTO ai.referral_code (code, issued_by_iid, used_count, expires_at, meta)
            VALUES ($1, $2, 0, $3, $4::jsonb)
            "#,
        )
        .bind(&code)
        .bind(issuer_iid)
        .bind(expires)
        .bind(meta)
        .execute(pool)
        .await
        .map_err(|e| e.to_string())?;
        codes.push(code);
    }

    let first = codes.first().cloned().unwrap_or_default();
    Ok(ResBillingVoucherIssue {
        code: first,
        face_value_idr: face,
        codes,
    })
}

fn normalize_voucher_code(raw: &str) -> String {
    let n = normalize_code(raw);
    if !n.is_empty() {
        return n;
    }
    format!("V{}", snowflake_id())
}

pub async fn voucher_issue_access(pool: &PgPool, issuer_iid: i64) -> Result<(), String> {
    if issuer_iid == 99_000 {
        return Ok(());
    }
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL")
        .bind(issuer_iid)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
    let Some(row) = row else {
        return Err("forbidden".into());
    };
    let meta: serde_json::Value = row.get("meta");
    if meta.get("is_root").and_then(|v| v.as_bool()).unwrap_or(false) {
        return Ok(());
    }
    let roles = meta
        .get("global_roles")
        .and_then(|v| v.as_array())
        .map(|a| {
            a.iter()
                .filter_map(|x| x.as_str().map(|s| s.to_lowercase()))
                .collect::<Vec<_>>()
        })
        .unwrap_or_default();
    if roles.iter().any(|r| VOUCHER_ISSUE_ROLES.contains(&r.as_str())) {
        Ok(())
    } else {
        Err("forbidden".into())
    }
}

async fn issuer_channel(pool: &PgPool, issuer_iid: i64) -> Result<String, String> {
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1")
        .bind(issuer_iid)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
    let meta: serde_json::Value = row.map(|r| r.get("meta")).unwrap_or(json!({}));
    if meta.get("is_root").and_then(|v| v.as_bool()).unwrap_or(false) {
        return Ok("root".into());
    }
    for role in ["director", "finance", "marketing"] {
        if meta
            .get("global_roles")
            .and_then(|v| v.as_array())
            .map(|a| a.iter().any(|x| x.as_str() == Some(role)))
            .unwrap_or(false)
        {
            return Ok(role.into());
        }
    }
    Ok("staff".into())
}

async fn marketing_limit_charge(pool: &PgPool, issuer_iid: i64, face_idr: f64) -> Result<(), String> {
    if issuer_iid == 99_000 {
        return Ok(());
    }
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL")
        .bind(issuer_iid)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
    let Some(row) = row else {
        return Err("forbidden".into());
    };
    let mut meta: serde_json::Value = row.get("meta");
    if meta.get("is_root").and_then(|v| v.as_bool()).unwrap_or(false) {
        return Ok(());
    }
    let roles: Vec<String> = meta
        .get("global_roles")
        .and_then(|v| v.as_array())
        .map(|a| {
            a.iter()
                .filter_map(|x| x.as_str().map(|s| s.to_lowercase()))
                .collect()
        })
        .unwrap_or_default();
    if roles.iter().any(|r| matches!(r.as_str(), "finance" | "director" | "root")) {
        return Ok(());
    }
    if !roles.contains(&"marketing".to_string()) {
        return Ok(());
    }
    let limit = meta
        .get("voucher_issue_limit_idr")
        .and_then(|v| v.as_f64())
        .unwrap_or(0.0);
    let used = meta
        .get("voucher_issue_used_idr")
        .and_then(|v| v.as_f64())
        .unwrap_or(0.0);
    if limit <= 0.0 {
        return Err("marketing voucher issue limit not allocated (limit is 0)".into());
    }
    if used + face_idr > limit + 0.01 {
        return Err("voucher issue credit limit exceeded".into());
    }
    if let Some(obj) = meta.as_object_mut() {
        obj.insert(
            "voucher_issue_used_idr".into(),
            json!(used + face_idr),
        );
    }
    sqlx::query("UPDATE ai.identity SET meta = $2::jsonb, updated_ts = NOW() WHERE id = $1")
        .bind(issuer_iid)
        .bind(meta)
        .execute(pool)
        .await
        .map_err(|e| e.to_string())?;
    Ok(())
}

pub async fn billing_voucher_limit_get(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqBillingVoucherLimitGet,
) -> Result<ResBillingVoucherLimit, String> {
    voucher_limit_edit_access(pool, viewer_iid).await?;
    let target = req.target_iid;
    if target <= 0 {
        return Err("target_iid required".into());
    }
    let (limit, used) = voucher_limit_meta_for_issuer(pool, target).await?;
    Ok(ResBillingVoucherLimit {
        target_iid: target,
        limit_idr: limit,
        used_idr: used,
    })
}

pub async fn billing_voucher_limit_put(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqBillingVoucherLimitPut,
) -> Result<ResBillingVoucherLimit, String> {
    voucher_limit_edit_access(pool, viewer_iid).await?;
    let target = req.target_iid;
    if target <= 0 {
        return Err("target_iid required".into());
    }
    if req.limit_idr < 0.0 {
        return Err("limit_idr invalid".into());
    }
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL")
        .bind(target)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
    let Some(row) = row else {
        return Err("user not found".into());
    };
    let mut meta: serde_json::Value = row.get("meta");
    if let Some(obj) = meta.as_object_mut() {
        obj.insert("voucher_issue_limit_idr".into(), json!(req.limit_idr));
    }
    sqlx::query("UPDATE ai.identity SET meta = $2::jsonb, updated_ts = NOW() WHERE id = $1")
        .bind(target)
        .bind(meta)
        .execute(pool)
        .await
        .map_err(|e| e.to_string())?;
    let (limit, used) = voucher_limit_meta_for_issuer(pool, target).await?;
    Ok(ResBillingVoucherLimit {
        target_iid: target,
        limit_idr: limit,
        used_idr: used,
    })
}

async fn voucher_limit_edit_access(pool: &PgPool, viewer_iid: i64) -> Result<(), String> {
    if viewer_iid == 99_000 {
        return Ok(());
    }
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL")
        .bind(viewer_iid)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
    let Some(row) = row else {
        return Err("forbidden".into());
    };
    let meta: serde_json::Value = row.get("meta");
    if meta.get("is_root").and_then(|v| v.as_bool()).unwrap_or(false) {
        return Ok(());
    }
    let roles = meta
        .get("global_roles")
        .and_then(|v| v.as_array())
        .map(|a| {
            a.iter()
                .filter_map(|x| x.as_str().map(|s| s.to_lowercase()))
                .collect::<Vec<_>>()
        })
        .unwrap_or_default();
    if roles.iter().any(|r| matches!(r.as_str(), "director" | "root")) {
        Ok(())
    } else {
        Err("forbidden".into())
    }
}

pub async fn voucher_limit_meta_for_issuer(pool: &PgPool, target_iid: i64) -> Result<(f64, f64), String> {
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL")
        .bind(target_iid)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
    let meta: serde_json::Value = row.map(|r| r.get("meta")).unwrap_or(json!({}));
    let limit = meta
        .get("voucher_issue_limit_idr")
        .and_then(|v| v.as_f64())
        .unwrap_or(0.0);
    let used = meta
        .get("voucher_issue_used_idr")
        .and_then(|v| v.as_f64())
        .unwrap_or(0.0);
    Ok((limit, used))
}

pub fn voucher_meta_bool(meta: &serde_json::Value, key: &str) -> bool {
    meta.get(key).and_then(|v| v.as_bool()).unwrap_or(false)
}

pub fn voucher_meta_f64(meta: &serde_json::Value, key: &str) -> f64 {
    meta.get(key).and_then(|v| v.as_f64()).unwrap_or(0.0)
}

fn voucher_meta_str(meta: &serde_json::Value, key: &str) -> String {
    meta.get(key).and_then(|v| v.as_str()).unwrap_or("").trim().to_string()
}

pub fn voucher_is_prepaid(meta: &serde_json::Value) -> bool {
    voucher_meta_bool(meta, "prepaid")
}

pub async fn marketing_limit_restore(pool: &PgPool, issuer_iid: i64, face_idr: f64) -> Result<(), String> {
    if issuer_iid == 99_000 || face_idr <= 0.0 {
        return Ok(());
    }
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL")
        .bind(issuer_iid)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
    let Some(row) = row else {
        return Ok(());
    };
    let mut meta: serde_json::Value = row.get("meta");
    if meta.get("is_root").and_then(|v| v.as_bool()).unwrap_or(false) {
        return Ok(());
    }
    let roles: Vec<String> = meta
        .get("global_roles")
        .and_then(|v| v.as_array())
        .map(|a| a.iter().filter_map(|x| x.as_str().map(|s| s.to_lowercase())).collect())
        .unwrap_or_default();
    if !roles.contains(&"marketing".to_string()) {
        return Ok(());
    }
    let used = meta.get("voucher_issue_used_idr").and_then(|v| v.as_f64()).unwrap_or(0.0);
    let next = (used - face_idr).max(0.0);
    if let Some(obj) = meta.as_object_mut() {
        obj.insert("voucher_issue_used_idr".into(), json!(next));
    }
    sqlx::query("UPDATE ai.identity SET meta = $2::jsonb, updated_ts = NOW() WHERE id = $1")
        .bind(issuer_iid)
        .bind(meta)
        .execute(pool)
        .await
        .map_err(|e| e.to_string())?;
    Ok(())
}

async fn voucher_mark_meta_released(pool: &PgPool, code: &str) -> Result<(), String> {
    sqlx::query(
        r#"UPDATE ai.referral_code SET meta = COALESCE(meta, '{}'::jsonb) || '{"marketing_limit_released":true}'::jsonb, updated_ts = NOW() WHERE code = $1"#,
    )
    .bind(code)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub async fn voucher_marketing_limit_release_for_code(pool: &PgPool, code: &str) -> Result<(), String> {
    let row = sqlx::query(
        "SELECT issued_by_iid, COALESCE(meta, '{}'::jsonb) AS meta FROM ai.referral_code WHERE code = $1",
    )
    .bind(code)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    let Some(row) = row else {
        return Ok(());
    };
    let meta: serde_json::Value = row.get("meta");
    if !voucher_is_prepaid(&meta) || voucher_meta_bool(&meta, "marketing_limit_released") {
        return Ok(());
    }
    let issuer: i64 = row.get("issued_by_iid");
    let face = voucher_meta_f64(&meta, "marketing_face_idr").max(voucher_meta_f64(&meta, "face_value_idr"));
    marketing_limit_restore(pool, issuer, face).await?;
    voucher_mark_meta_released(pool, code).await?;
    Ok(())
}

pub async fn voucher_settle_expired_code(pool: &PgPool, code: &str) -> Result<(), String> {
    let row = sqlx::query(
        "SELECT used_count, expires_at, COALESCE(meta, '{}'::jsonb) AS meta FROM ai.referral_code WHERE code = $1",
    )
    .bind(code)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    let Some(row) = row else {
        return Ok(());
    };
    let meta: serde_json::Value = row.get("meta");
    if !voucher_is_prepaid(&meta) || voucher_meta_bool(&meta, "void") || voucher_meta_bool(&meta, "marketing_limit_released") {
        return Ok(());
    }
    let used: i32 = row.get("used_count");
    let max_uses = meta.get("max_uses").and_then(|v| v.as_i64()).unwrap_or(1) as i32;
    if used >= max_uses.max(1) {
        return Ok(());
    }
    let expires_at: Option<chrono::DateTime<chrono::Utc>> = row.get("expires_at");
    let Some(exp) = expires_at else {
        return Ok(());
    };
    if exp > chrono::Utc::now() {
        return Ok(());
    }
    voucher_marketing_limit_release_for_code(pool, code).await?;
    sqlx::query(
        r#"UPDATE ai.referral_code SET meta = COALESCE(meta, '{}'::jsonb) || '{"status":"expired"}'::jsonb, updated_ts = NOW() WHERE code = $1"#,
    )
    .bind(code)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(())
}

async fn voucher_settle_expired_for_issuer(pool: &PgPool, issuer_iid: i64) -> Result<(), String> {
    let codes = sqlx::query_scalar::<_, String>(
        r#"
        SELECT code FROM ai.referral_code
        WHERE issued_by_iid = $1 AND expires_at IS NOT NULL AND expires_at <= NOW()
          AND COALESCE((meta->>'prepaid')::boolean, false) = true
          AND used_count < COALESCE((meta->>'max_uses')::int, 1)
          AND COALESCE((meta->>'marketing_limit_released')::boolean, false) = false
        LIMIT 200
        "#,
    )
    .bind(issuer_iid)
    .fetch_all(pool)
    .await
    .map_err(|e| e.to_string())?;
    for code in codes {
        let _ = voucher_settle_expired_code(pool, &code).await;
    }
    Ok(())
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct VoucherPublicView {
    pub code: String,
    pub name: String,
    pub face_value_idr: f64,
    pub kind: String,
    pub status: String,
    pub redeemable: bool,
}

pub enum VoucherPublicFail {
    NotFound,
    Unavailable(String),
}

/// Public card for a prepaid voucher. Omits issuer, commission, and payment reference.
pub async fn billing_voucher_public(pool: &PgPool, raw_code: &str) -> Result<VoucherPublicView, VoucherPublicFail> {
    let code = normalize_code(raw_code);
    if code.is_empty() || code.len() > 32 {
        return Err(VoucherPublicFail::NotFound);
    }
    if voucher_settle_expired_code(pool, &code).await.is_err() {
        tracing::warn!("voucher public settle failed");
    }
    let row = sqlx::query(
        r#"
        SELECT code, used_count, expires_at, COALESCE(meta, '{}'::jsonb) AS meta
        FROM ai.referral_code
        WHERE code = $1
        "#,
    )
    .bind(&code)
    .fetch_optional(pool)
    .await
    .map_err(|e| VoucherPublicFail::Unavailable(e.to_string()))?;
    let Some(row) = row else {
        return Err(VoucherPublicFail::NotFound);
    };
    let meta: serde_json::Value = row.try_get("meta").unwrap_or(json!({}));
    if !voucher_is_prepaid(&meta) {
        return Err(VoucherPublicFail::NotFound);
    }
    let used_count: i32 = row.try_get("used_count").unwrap_or(0);
    let expires_at: Option<chrono::DateTime<chrono::Utc>> = row.try_get("expires_at").ok().flatten();
    let status = voucher_doc_status(&meta, used_count, expires_at);
    let mut name = voucher_meta_str(&meta, "name");
    if name.is_empty() {
        name = "Voucher".into();
    }
    let kind = voucher_meta_str(&meta, "type");
    Ok(VoucherPublicView {
        code,
        name,
        face_value_idr: voucher_meta_f64(&meta, "face_value_idr"),
        kind,
        redeemable: status == "active",
        status,
    })
}

fn voucher_doc_status(meta: &serde_json::Value, used_count: i32, expires_at: Option<chrono::DateTime<chrono::Utc>>) -> String {
    if voucher_meta_bool(meta, "void") {
        return "void".into();
    }
    let max_uses = meta.get("max_uses").and_then(|v| v.as_i64()).unwrap_or(1) as i32;
    if used_count >= max_uses.max(1) {
        return "redeemed".into();
    }
    if let Some(exp) = expires_at {
        if exp <= chrono::Utc::now() {
            return "expired".into();
        }
    }
    "active".into()
}

trait VoucherStrOr {
    fn or_user(self) -> String;
}

impl VoucherStrOr for String {
    fn or_user(self) -> String {
        if self.is_empty() { "user".into() } else { self }
    }
}

pub async fn billing_voucher_list(pool: &PgPool, issuer_iid: i64, _req: ReqBillingVoucherList) -> Result<ResBillingVoucherList, String> {
    voucher_issue_access(pool, issuer_iid).await?;
    voucher_settle_expired_for_issuer(pool, issuer_iid).await?;
    let rows = sqlx::query(
        r#"
        SELECT rc.code, rc.used_count, rc.expires_at,
               (EXTRACT(EPOCH FROM rc.expires_at) * 1000)::float8 AS expires_at_ms,
               COALESCE(rc.meta, '{}'::jsonb) AS meta,
               vr.buyer_iid, (EXTRACT(EPOCH FROM vr.redeemed_ts) * 1000)::float8 AS redeemed_ts_ms,
               i.name AS buyer_name
        FROM ai.referral_code rc
        LEFT JOIN LATERAL (
            SELECT buyer_iid, redeemed_ts FROM ai.billing_voucher_redeem
            WHERE referral_code = rc.code ORDER BY redeemed_ts DESC LIMIT 1
        ) vr ON true
        LEFT JOIN ai.identity i ON i.id = vr.buyer_iid
        WHERE rc.issued_by_iid = $1 AND COALESCE((rc.meta->>'prepaid')::boolean, false) = true
        ORDER BY rc.created_ts DESC LIMIT 200
        "#,
    )
    .bind(issuer_iid)
    .fetch_all(pool)
    .await
    .map_err(|e| e.to_string())?;
    let items = rows
        .into_iter()
        .map(|r| {
            let meta: serde_json::Value = r.get("meta");
            let expires_at: Option<chrono::DateTime<chrono::Utc>> = r.get("expires_at");
            let expires_ms = r.get::<Option<f64>, _>("expires_at_ms").unwrap_or(0.0) as i64;
            let used_count: i32 = r.get("used_count");
            BillingVoucherDoc {
                code: r.get("code"),
                kind: voucher_meta_str(&meta, "type"),
                name: voucher_meta_str(&meta, "name"),
                status: voucher_doc_status(&meta, used_count, expires_at),
                face_value_idr: voucher_meta_f64(&meta, "face_value_idr"),
                list_price_idr: voucher_meta_f64(&meta, "list_price_idr"),
                expires_at_ms: if expires_at.is_some() { expires_ms } else { 0 },
                scope: voucher_meta_str(&meta, "scope").or_user(),
                plan_slug: voucher_meta_str(&meta, "base_plan_slug"),
                duration_months: meta.get("duration_months").and_then(|v| v.as_i64()).unwrap_or(1) as i32,
                credit_idr: voucher_meta_f64(&meta, "credit_idr"),
                redeemed_ts_ms: r.get::<Option<f64>, _>("redeemed_ts_ms").unwrap_or(0.0) as i64,
                redeemed_by_iid: r.get::<Option<i64>, _>("buyer_iid").unwrap_or(0),
                redeemed_by_name: r.get::<Option<String>, _>("buyer_name").unwrap_or_default(),
                used_count,
                max_uses: meta.get("max_uses").and_then(|v| v.as_i64()).unwrap_or(1) as i32,
                billing_period: voucher_meta_str(&meta, "billing_period").if_empty_or("monthly"),
            }
        })
        .collect();
    let (limit, used) = voucher_limit_meta_for_issuer(pool, issuer_iid).await?;
    Ok(ResBillingVoucherList {
        items,
        limit: Some(ResBillingVoucherLimit {
            target_iid: issuer_iid,
            limit_idr: limit,
            used_idr: used,
        }),
    })
}

trait VoucherIfEmpty {
    fn if_empty_or(self, fallback: &str) -> String;
}

impl VoucherIfEmpty for String {
    fn if_empty_or(self, fallback: &str) -> String {
        if self.is_empty() { fallback.to_string() } else { self }
    }
}

pub async fn billing_voucher_redeem_list(
    pool: &PgPool,
    issuer_iid: i64,
    req: ReqBillingVoucherRedeemList,
) -> Result<ResBillingVoucherRedeemList, String> {
    voucher_issue_access(pool, issuer_iid).await?;
    let take = if req.limit <= 0 { 100 } else { req.limit.min(500) };
    let rows = sqlx::query(
        r#"
        SELECT v.id, v.referral_code, v.buyer_iid, v.face_value_idr::float8 AS face_value_idr,
               v.list_price_idr::float8 AS list_price_idr,
               (EXTRACT(EPOCH FROM v.redeemed_ts) * 1000)::float8 AS redeemed_ts_ms, i.name AS buyer_name
        FROM ai.billing_voucher_redeem v
        LEFT JOIN ai.identity i ON i.id = v.buyer_iid
        WHERE v.issuer_iid = $1 ORDER BY v.redeemed_ts DESC LIMIT $2
        "#,
    )
    .bind(issuer_iid)
    .bind(take)
    .fetch_all(pool)
    .await
    .map_err(|e| e.to_string())?;
    let items = rows
        .into_iter()
        .map(|r| BillingVoucherRedeemDoc {
            id: r.get("id"),
            code: r.get("referral_code"),
            buyer_iid: r.get("buyer_iid"),
            buyer_name: r.get::<Option<String>, _>("buyer_name").unwrap_or_default(),
            face_value_idr: r.get("face_value_idr"),
            list_price_idr: r.get("list_price_idr"),
            redeemed_ts_ms: r.get::<Option<f64>, _>("redeemed_ts_ms").unwrap_or(0.0) as i64,
        })
        .collect();
    Ok(ResBillingVoucherRedeemList { items })
}

pub async fn billing_voucher_void(pool: &PgPool, issuer_iid: i64, req: ReqBillingVoucherVoid) -> Result<ResBillingVoucherVoid, String> {
    voucher_issue_access(pool, issuer_iid).await?;
    let code = normalize_code(&req.code);
    if code.is_empty() {
        return Err("code required".into());
    }
    let row = sqlx::query(
        "SELECT issued_by_iid, used_count, COALESCE(meta, '{}'::jsonb) AS meta FROM ai.referral_code WHERE code = $1 FOR UPDATE",
    )
    .bind(&code)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    .ok_or_else(|| "code not found".to_string())?;
    let owner: i64 = row.get("issued_by_iid");
    if owner != issuer_iid && issuer_iid != 99_000 {
        return Err("forbidden".into());
    }
    if row.get::<i32, _>("used_count") > 0 {
        return Err("voucher already redeemed".into());
    }
    let meta: serde_json::Value = row.get("meta");
    if !voucher_is_prepaid(&meta) {
        return Err("not a prepaid voucher".into());
    }
    voucher_marketing_limit_release_for_code(pool, &code).await?;
    sqlx::query(
        r#"UPDATE ai.referral_code SET meta = COALESCE(meta, '{}'::jsonb) || '{"void":true,"status":"void"}'::jsonb, updated_ts = NOW() WHERE code = $1"#,
    )
    .bind(&code)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(ResBillingVoucherVoid { ok: true })
}

pub async fn voucher_log_redeem(
    pool: &PgPool,
    code: &str,
    issuer_iid: i64,
    buyer_iid: i64,
    purchase_id: i64,
    face_idr: f64,
    list_price_idr: f64,
) -> Result<(), String> {
    let id = snowflake_id();
    sqlx::query(
        r#"INSERT INTO ai.billing_voucher_redeem (id, referral_code, issuer_iid, buyer_iid, purchase_id, face_value_idr, list_price_idr) VALUES ($1,$2,$3,$4,$5,$6,$7)"#,
    )
    .bind(id)
    .bind(code)
    .bind(issuer_iid)
    .bind(buyer_iid)
    .bind(purchase_id)
    .bind(face_idr)
    .bind(list_price_idr)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub async fn voucher_on_redeemed(pool: &PgPool, code: &str) -> Result<(), String> {
    voucher_marketing_limit_release_for_code(pool, code).await
}

pub async fn billing_voucher_before_code_delete(pool: &PgPool, issuer_iid: i64, raw_code: &str) -> Result<(), String> {
    let code = normalize_code(raw_code);
    let row = sqlx::query(
        "SELECT used_count, COALESCE(meta, '{}'::jsonb) AS meta FROM ai.referral_code WHERE code = $1",
    )
    .bind(&code)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    let Some(row) = row else {
        return Ok(());
    };
    let meta: serde_json::Value = row.get("meta");
    if !voucher_is_prepaid(&meta) {
        return Ok(());
    }
    if row.get::<i32, _>("used_count") > 0 {
        return Err("cannot delete redeemed voucher".into());
    }
    let _ = billing_voucher_void(pool, issuer_iid, ReqBillingVoucherVoid { code: code.clone() }).await;
    Ok(())
}

pub async fn billing_voucher_redeem_credit(
    pool: &PgPool,
    buyer_iid: i64,
    code: &str,
    meta: &serde_json::Value,
    purchase_id: i64,
    expires_ts: chrono::DateTime<chrono::Utc>,
) -> Result<(), String> {
    let credit = meta
        .get("credit_idr")
        .and_then(|v| v.as_f64())
        .unwrap_or(0.0);
    if credit <= 0.0 {
        return Err("invalid credit voucher".into());
    }
    let face = meta
        .get("face_value_idr")
        .and_then(|v| v.as_f64())
        .unwrap_or(credit);
    crate::billing_entitlement::billing_entitlement_grant(
        pool,
        EntitlementGrantSpec {
            owner_iid: buyer_iid,
            source: "voucher".into(),
            referral_code: Some(code.to_string()),
            purchase_id: Some(purchase_id),
            plan_slug: String::new(),
            duration_months: 0,
            credit_idr: credit,
            highlight: true,
            expires_ts: Some(expires_ts),
            alien_pool_override: None,
            frontier_pool_override: None,
        },
    )
    .await
    .map_err(|e| e.to_string())?;
    let amount_idr_i64 = face.round() as i64;
    if let Err(e) = c35_mod_referral::commission_accrue_on_purchase(
        pool,
        buyer_iid,
        amount_idr_i64,
        &purchase_id.to_string(),
        "voucher_credit",
    )
    .await
    {
        tracing::warn!("commission accrue on credit voucher: {e}");
    }
    Ok(())
}
