//! Google Play in-app purchase verification (Android Publisher API).

use std::path::{Path, PathBuf};
use std::sync::{Arc, OnceLock};
use std::time::{Duration, Instant};

use anyhow::{anyhow, Context, Result};
use c35_proto::{
    BillingPlayProductDoc, ReqBillingPlayProductList, ReqBillingPlayVerify, ResBillingPlayProductList,
    ResBillingPlayVerify,
};
use c35_store::snowflake_id;
use chrono::Utc;
use jsonwebtoken::{encode, Algorithm, EncodingKey, Header};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use sqlx::{PgPool, Row};
use tokio::sync::Mutex;
use crate::billing_entitlement::{billing_entitlement_grant, billing_entitlement_list, EntitlementGrantSpec};
use crate::billing_http::billing_http_client;

pub const PLAY_MARKUP: f64 = 1.15;
const PLAY_SCOPE: &str = "https://www.googleapis.com/auth/androidpublisher";
const TOKEN_URL: &str = "https://oauth2.googleapis.com/token";
const DEFAULT_PACKAGE: &str = "id.alienai";
const PLAN_PREFIX: &str = "id.alienai.plan.";
const CREDIT_PREFIX: &str = "id.alienai.credit.";
const USER_PLAN_SLUGS: &[&str] = &["lite", "plus", "pro", "ultra"];

#[derive(Clone, Debug)]
enum PlayProduct {
    Plan { slug: String, period: String, months: i32 },
    Credit { amount_idr: f64 },
}

#[derive(Deserialize)]
struct ServiceAccount {
    client_email: String,
    private_key: String,
}

struct PlayApi {
    client_email: String,
    encoding_key: EncodingKey,
    http: Client,
    access: Mutex<CachedToken>,
}

struct CachedToken {
    value: String,
    expires_at: Instant,
}

#[derive(Serialize)]
struct JwtClaims<'a> {
    iss: &'a str,
    scope: &'a str,
    aud: &'a str,
    iat: u64,
    exp: u64,
}

#[derive(Deserialize)]
struct TokenResponse {
    access_token: String,
    expires_in: u64,
}

#[derive(Deserialize)]
struct ProductPurchase {
    #[serde(default)]
    purchase_state: Option<i32>,
    #[serde(default, rename = "purchaseState")]
    purchase_state_camel: Option<i32>,
    #[serde(default)]
    order_id: Option<String>,
    #[serde(default, rename = "orderId")]
    order_id_camel: Option<String>,
}

#[derive(Deserialize)]
struct SubscriptionPurchase {
    #[serde(default)]
    payment_state: Option<i32>,
    #[serde(default, rename = "paymentState")]
    payment_state_camel: Option<i32>,
    #[serde(default)]
    order_id: Option<String>,
    #[serde(default, rename = "orderId")]
    order_id_camel: Option<String>,
    #[serde(default)]
    expiry_time_millis: Option<String>,
    #[serde(default, rename = "expiryTimeMillis")]
    expiry_time_millis_camel: Option<String>,
}

#[derive(Deserialize)]
struct SubscriptionPurchaseV2 {
    #[serde(default)]
    subscription_state: Option<String>,
    #[serde(default, rename = "subscriptionState")]
    subscription_state_camel: Option<String>,
    #[serde(default)]
    latest_order_id: Option<String>,
    #[serde(default, rename = "latestOrderId")]
    latest_order_id_camel: Option<String>,
}

static PLAY_API: OnceLock<Option<Arc<PlayApi>>> = OnceLock::new();

pub fn play_price_idr(web_idr: f64) -> f64 {
    (web_idr * PLAY_MARKUP).round()
}

async fn plan_web_price_idr(pool: &PgPool, slug: &str, period: &str) -> Result<i64, String> {
    let amount: Option<f64> = sqlx::query_scalar(
        r#"
        SELECT amount::float8
        FROM ai.billing_plan_price
        WHERE plan_slug = $1 AND billing_period = $2 AND currency = 'IDR' AND is_active = TRUE
        LIMIT 1
        "#,
    )
    .bind(slug.trim())
    .bind(period.trim())
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    amount
        .filter(|v| *v > 0.0)
        .map(|v| v.round() as i64)
        .ok_or_else(|| "plan price not found".into())
}

pub fn play_stub_enabled() -> bool {
    std::env::var("C35_PLAY_VERIFY_STUB")
        .ok()
        .map(|v| v == "1" || v.eq_ignore_ascii_case("true"))
        .unwrap_or(false)
}

fn play_package_name(override_name: &str) -> String {
    let trimmed = override_name.trim();
    if !trimmed.is_empty() {
        return trimmed.to_string();
    }
    std::env::var("PLAY_STORE_PACKAGE_NAME")
        .ok()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| DEFAULT_PACKAGE.to_string())
}

fn parse_play_product(product_id: &str) -> Result<PlayProduct, String> {
    let mut id = product_id.trim();
    if let Some(rest) = id.strip_prefix("id.alienai.") {
        id = rest;
    }

    // Check if it's a credit product (e.g. credit.50000, credit_50000, credit.50k)
    if id.starts_with("credit.") || id.starts_with("credit_") {
        let amount_part = id.strip_prefix("credit.").or_else(|| id.strip_prefix("credit_")).unwrap_or("");
        let amount_lower = amount_part.trim().to_lowercase();
        let amount: f64 = if let Some(k) = amount_lower.strip_suffix('k') {
            k.parse::<f64>().map(|v| v * 1_000.0).map_err(|_| "invalid credit amount in product id".to_string())?
        } else if let Some(m) = amount_lower.strip_suffix('m') {
            m.parse::<f64>().map(|v| v * 1_000_000.0).map_err(|_| "invalid credit amount in product id".to_string())?
        } else {
            amount_lower.parse::<f64>().map_err(|_| "invalid credit amount in product id".to_string())?
        };
        if amount < 1.0 {
            return Err("credit amount must be positive".into());
        }
        return Ok(PlayProduct::Credit { amount_idr: amount });
    }

    // Check if it's a plan product
    let mut plan_part = id;
    if let Some(rest) = plan_part.strip_prefix("plan.") {
        plan_part = rest;
    } else if let Some(rest) = plan_part.strip_prefix("plan_") {
        plan_part = rest;
    }

    // Normalize separators: replace '_' with '.'
    let normalized = plan_part.replace('_', ".");
    let mut parts = normalized.split('.');
    let slug = parts.next().unwrap_or("").trim().to_lowercase();
    let period_raw = parts.next().unwrap_or("monthly").trim().to_lowercase();

    if slug.is_empty() {
        return Err("invalid plan product id".into());
    }
    if !USER_PLAN_SLUGS.contains(&slug.as_str()) {
        return Err(format!("unknown plan slug: {slug}"));
    }
    let (period, months) = match period_raw.as_str() {
        "yearly" | "annual" | "1y" => ("yearly".to_string(), 12),
        "monthly" | "1m" | "" => ("monthly".to_string(), 1),
        _ => return Err("billing_period must be monthly or yearly".into()),
    };

    Ok(PlayProduct::Plan {
        slug,
        period,
        months,
    })
}

fn repo_root() -> Option<PathBuf> {
    if let Ok(exe) = std::env::current_exe() {
        let mut dir = exe.parent()?.to_path_buf();
        for _ in 0..8 {
            if dir.join("servers").join("Cargo.toml").exists() {
                return Some(dir);
            }
            dir = dir.parent()?.to_path_buf();
        }
    }
    std::env::current_dir()
        .ok()
        .filter(|d| d.join("servers").join("Cargo.toml").exists())
}

fn load_service_account_json() -> Result<Option<String>> {
    if let Ok(json) = std::env::var("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON") {
        if !json.trim().is_empty() {
            return Ok(Some(json));
        }
    }
    if let Ok(path) = std::env::var("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH") {
        if !path.trim().is_empty() {
            let raw = std::fs::read_to_string(Path::new(path.trim()))
                .with_context(|| format!("read GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH"))?;
            return Ok(Some(raw));
        }
    }
    if let Some(root) = repo_root() {
        let default = root.join("_").join("certs").join("google-play-upload-service-account.json");
        if default.is_file() {
            let raw = std::fs::read_to_string(&default)
                .with_context(|| format!("read {}", default.display()))?;
            return Ok(Some(raw));
        }
    }
    Ok(None)
}

fn play_api() -> Result<Option<Arc<PlayApi>>> {
    if let Some(cached) = PLAY_API.get() {
        return Ok(cached.clone());
    }
    let api = match load_service_account_json()? {
        Some(raw) => {
            let sa: ServiceAccount = serde_json::from_str(&raw).context("parse play service account json")?;
            Some(Arc::new(PlayApi {
                client_email: sa.client_email,
                encoding_key: EncodingKey::from_rsa_pem(sa.private_key.as_bytes())
                    .context("parse play service account private key")?,
                http: billing_http_client(),
                access: Mutex::new(CachedToken {
                    value: String::new(),
                    expires_at: Instant::now(),
                }),
            }))
        }
        None => None,
    };
    let _ = PLAY_API.set(api.clone());
    Ok(api)
}

async fn access_token(api: &PlayApi) -> Result<String> {
    {
        let cached = api.access.lock().await;
        if !cached.value.is_empty() && cached.expires_at > Instant::now() {
            return Ok(cached.value.clone());
        }
    }
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    let claims = JwtClaims {
        iss: &api.client_email,
        scope: PLAY_SCOPE,
        aud: TOKEN_URL,
        iat: now,
        exp: now + 3600,
    };
    let assertion = encode(&Header::new(Algorithm::RS256), &claims, &api.encoding_key)
        .context("sign play jwt")?;
    let res = api
        .http
        .post(TOKEN_URL)
        .form(&[
            ("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer"),
            ("assertion", assertion.as_str()),
        ])
        .send()
        .await
        .context("request google access token")?
        .error_for_status()
        .context("google access token http error")?
        .json::<TokenResponse>()
        .await
        .context("parse google access token")?;
    let expires_at = Instant::now() + Duration::from_secs(res.expires_in.saturating_sub(60));
    let mut cached = api.access.lock().await;
    cached.value = res.access_token.clone();
    cached.expires_at = expires_at;
    Ok(res.access_token)
}

async fn verify_with_google(
    api: &PlayApi,
    package: &str,
    product_id: &str,
    token: &str,
    product: &PlayProduct,
) -> Result<(String, Value)> {
    let access = access_token(api).await?;
    match product {
        PlayProduct::Plan { .. } => {
            // First try subscriptions v1 API
            let v1_url = format!(
                "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{package}/purchases/subscriptions/{product_id}/tokens/{token}"
            );
            let res = api
                .http
                .get(&v1_url)
                .bearer_auth(&access)
                .send()
                .await
                .context("play verify http v1")?;

            let status = res.status();
            if status.is_success() {
                let body: Value = res.json().await.context("parse play verify v1 json")?;
                let sub: SubscriptionPurchase = serde_json::from_value(body.clone())
                    .context("parse subscription purchase")?;
                let payment = sub.payment_state.or(sub.payment_state_camel).unwrap_or(-1);
                if payment != 1 && payment != 2 {
                    return Err(anyhow!("subscription payment not received (state={payment})"));
                }
                if let Some(exp_ms) = sub
                    .expiry_time_millis
                    .or(sub.expiry_time_millis_camel)
                    .and_then(|s| s.parse::<i64>().ok())
                {
                    if exp_ms <= Utc::now().timestamp_millis() {
                        return Err(anyhow!("subscription expired"));
                    }
                }
                let order_id = sub.order_id.or(sub.order_id_camel).unwrap_or_default();
                return Ok((order_id, body));
            }

            // If v1 returned 404 (common for modern Play Billing subscriptions), try subscriptions v2 API
            if status.as_u16() == 404 {
                let v2_url = format!(
                    "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{package}/purchases/subscriptionsv2/tokens/{token}"
                );
                let res2 = api
                    .http
                    .get(&v2_url)
                    .bearer_auth(&access)
                    .send()
                    .await
                    .context("play verify http v2")?;

                let status2 = res2.status();
                if status2.is_success() {
                    let body2: Value = res2.json().await.context("parse play verify v2 json")?;
                    let sub2: SubscriptionPurchaseV2 = serde_json::from_value(body2.clone())
                        .context("parse subscription purchase v2")?;
                    let state = sub2.subscription_state
                        .or(sub2.subscription_state_camel)
                        .unwrap_or_default()
                        .to_uppercase();
                    if !state.is_empty() && !state.contains("ACTIVE") && !state.contains("GRACE") {
                        return Err(anyhow!("subscription not active in Google Play (state={state})"));
                    }
                    let order_id = sub2.latest_order_id.or(sub2.latest_order_id_camel).unwrap_or_default();
                    return Ok((order_id, body2));
                } else {
                    let err2 = res2.text().await.unwrap_or_default();
                    return Err(anyhow!("google play verify v2 rejected ({status2}): {err2}"));
                }
            }

            let err = res.text().await.unwrap_or_default();
            Err(anyhow!("google play verify v1 rejected ({status}): {err}"))
        }
        PlayProduct::Credit { .. } => {
            let url = format!(
                "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{package}/purchases/products/{product_id}/tokens/{token}"
            );
            let res = api
                .http
                .get(&url)
                .bearer_auth(&access)
                .send()
                .await
                .context("play verify product http")?;
            let status = res.status();
            if !status.is_success() {
                let err = res.text().await.unwrap_or_default();
                return Err(anyhow!("google play product verify rejected ({status}): {err}"));
            }
            let body: Value = res.json().await.context("parse product purchase json")?;
            let prod: ProductPurchase =
                serde_json::from_value(body.clone()).context("parse product purchase")?;
            let state = prod.purchase_state.or(prod.purchase_state_camel).unwrap_or(-1);
            if state != 0 {
                return Err(anyhow!("product not purchased (state={state})"));
            }
            let order_id = prod.order_id.or(prod.order_id_camel).unwrap_or_default();
            Ok((order_id, body))
        }
    }
}

async fn play_purchase_existing(
    pool: &PgPool,
    token: &str,
) -> Result<Option<sqlx::postgres::PgRow>, String> {
    sqlx::query(
        r#"
        SELECT id, owner_iid, product_id, plan_slug, credit_idr::float8 AS credit_idr,
               duration_months, entitlement_id, kind, status
        FROM ai.billing_play_purchase
        WHERE purchase_token = $1
        "#,
    )
    .bind(token)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())
}

async fn balance_idr(pool: &PgPool, owner_iid: i64) -> Result<f64, String> {
    let row = sqlx::query(
        r#"SELECT balance_idr::float8 AS balance_idr
           FROM ai.billing_account
           WHERE owner_iid = $1 AND deleted_ts IS NULL LIMIT 1"#,
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(row.map(|r| r.get("balance_idr")).unwrap_or(0.0))
}

async fn finish_verify_response(
    pool: &PgPool,
    owner_iid: i64,
    product_id: &str,
    plan_slug: &str,
    duration_months: i32,
    credit_idr: f64,
    entitlement_id: i64,
    play_purchase_id: i64,
    expires_ts_ms: i64,
    already: bool,
) -> Result<ResBillingPlayVerify, String> {
    let list = billing_entitlement_list(pool, owner_iid).await?;
    Ok(ResBillingPlayVerify {
        status: if already {
            "already_redeemed".into()
        } else {
            "ok".into()
        },
        product_id: product_id.to_string(),
        plan_slug: plan_slug.to_string(),
        duration_months,
        credit_idr,
        entitlement_id,
        play_purchase_id,
        balance_idr: balance_idr(pool, owner_iid).await?,
        entitlements: list.items,
        expires_ts_ms,
    })
}

pub async fn billing_play_verify(
    pool: &PgPool,
    owner_iid: i64,
    req: ReqBillingPlayVerify,
) -> Result<ResBillingPlayVerify, String> {
    let product_id = req.product_id.trim();
    let purchase_token = req.purchase_token.trim();
    if product_id.is_empty() || purchase_token.is_empty() {
        return Err("product_id and purchase_token required".into());
    }
    let product = parse_play_product(product_id)?;
    let package = play_package_name(&req.package_name);

    if let Some(row) = play_purchase_existing(pool, purchase_token).await? {
        let existing_owner: i64 = row.get("owner_iid");
        if existing_owner != owner_iid {
            return Err("purchase token already redeemed".into());
        }
        let ent_id: Option<i64> = row.get("entitlement_id");
        let expires = Utc::now().timestamp_millis() + 30 * 86400 * 1000;
        return finish_verify_response(
            pool,
            owner_iid,
            row.get("product_id"),
            row.get("plan_slug"),
            row.get("duration_months"),
            row.get("credit_idr"),
            ent_id.unwrap_or(0),
            row.get("id"),
            expires,
            true,
        )
        .await;
    }

    let api = play_api().map_err(|e| e.to_string())?;
    let stub = api.is_none() && play_stub_enabled();
    if api.is_none() && !stub {
        return Err("google play credentials missing (set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON or C35_PLAY_VERIFY_STUB=1)".into());
    }

    let (order_id, google_body, status_tag) = if stub {
        (
            format!("stub-{}", snowflake_id()),
            json!({ "stub": true, "product_id": product_id }),
            "stub",
        )
    } else {
        let api = api.ok_or_else(|| "play api unavailable".to_string())?;
        let (order_id, body) = verify_with_google(&api, &package, product_id, purchase_token, &product)
            .await
            .map_err(|e| e.to_string())?;
        (order_id, body, "verified")
    };

    let (kind, plan_slug, billing_period, duration_months, credit_idr, expires_ts) = match &product {
        PlayProduct::Plan { slug, period, months } => (
            "plan",
            slug.clone(),
            period.clone(),
            *months,
            0.0,
            Utc::now() + chrono::Duration::days(30 * (*months as i64)),
        ),
        PlayProduct::Credit { amount_idr } => (
            "credit",
            String::new(),
            String::new(),
            0,
            *amount_idr,
            Utc::now() + chrono::Duration::days(3650),
        ),
    };

    let play_purchase_id = snowflake_id();
    let entitlement_id = billing_entitlement_grant(
        pool,
        EntitlementGrantSpec {
            owner_iid,
            source: if stub { "play_stub".into() } else { "play".into() },
            referral_code: None,
            purchase_id: Some(play_purchase_id),
            plan_slug: plan_slug.clone(),
            duration_months: duration_months.max(1),
            credit_idr,
            highlight: true,
            expires_ts: Some(expires_ts),
            alien_pool_override: None,
            frontier_pool_override: None,
        },
    )
    .await
    .map_err(|e| e.to_string())?;

    sqlx::query(
        r#"
        INSERT INTO ai.billing_play_purchase (
            id, owner_iid, product_id, purchase_token, order_id, package_name,
            kind, plan_slug, billing_period, credit_idr, duration_months,
            entitlement_id, google_response, status
        ) VALUES (
            $1, $2, $3, $4, $5, $6,
            $7, $8, $9, $10, $11,
            $12, $13::jsonb, $14
        )
        "#,
    )
    .bind(play_purchase_id)
    .bind(owner_iid)
    .bind(product_id)
    .bind(purchase_token)
    .bind(&order_id)
    .bind(&package)
    .bind(kind)
    .bind(&plan_slug)
    .bind(&billing_period)
    .bind(credit_idr)
    .bind(duration_months)
    .bind(entitlement_id)
    .bind(google_body)
    .bind(status_tag)
    .execute(pool)
    .await
    .map_err(|e| {
        if e.to_string().contains("uq_billing_play_purchase_token") {
            "purchase token already redeemed".into()
        } else {
            e.to_string()
        }
    })?;

    if kind == "plan" && !plan_slug.is_empty() {
        let commission_idr = plan_web_price_idr(pool, &plan_slug, &billing_period)
            .await
            .unwrap_or(0);
        if commission_idr > 0 {
            let purchase_ref = format!("play:{play_purchase_id}");
            if let Err(e) = c35_mod_referral::commission_accrue_on_purchase(
                pool,
                owner_iid,
                commission_idr,
                &purchase_ref,
                "plan_subscribe",
            )
            .await
            {
                tracing::warn!("commission accrue on play plan: {e}");
            }
        }
    }

    finish_verify_response(
        pool,
        owner_iid,
        product_id,
        &plan_slug,
        duration_months,
        credit_idr,
        entitlement_id,
        play_purchase_id,
        expires_ts.timestamp_millis(),
        false,
    )
    .await
}

pub const PLAY_CREDIT_PACKS: &[f64] = &[50_000.0, 100_000.0, 200_000.0, 500_000.0, 1_000_000.0];

pub async fn billing_play_product_list(
    pool: &PgPool,
    _req: ReqBillingPlayProductList,
) -> Result<ResBillingPlayProductList, String> {
    let rows = sqlx::query(
        r#"
        SELECT p.plan_slug, p.billing_period, p.amount::float8 AS amount, bp.name
        FROM ai.billing_plan_price p
        JOIN ai.billing_plan bp ON bp.slug = p.plan_slug
        WHERE p.currency = 'IDR' AND p.is_active = TRUE
          AND bp.scope = 'user' AND bp.is_active = TRUE
          AND p.plan_slug = ANY($1)
        ORDER BY bp.sort_order, p.billing_period
        "#,
    )
    .bind(USER_PLAN_SLUGS)
    .fetch_all(pool)
    .await
    .map_err(|e| e.to_string())?;

    let mut products: Vec<BillingPlayProductDoc> = rows
        .into_iter()
        .map(|r| {
            let slug: String = r.get("plan_slug");
            let period: String = r.get("billing_period");
            let web: f64 = r.get("amount");
            BillingPlayProductDoc {
                product_id: format!("{PLAN_PREFIX}{slug}.{period}"),
                kind: "plan".into(),
                plan_slug: slug,
                billing_period: period,
                credit_idr: 0.0,
                web_price_idr: web,
                play_price_idr: play_price_idr(web),
            }
        })
        .collect();

    for &credit in PLAY_CREDIT_PACKS {
        products.push(BillingPlayProductDoc {
            product_id: format!("{CREDIT_PREFIX}{}", credit.round() as i64),
            kind: "credit".into(),
            plan_slug: String::new(),
            billing_period: String::new(),
            credit_idr: credit,
            web_price_idr: credit,
            play_price_idr: play_price_idr(credit),
        });
    }

    Ok(ResBillingPlayProductList { products })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn play_price_markup() {
        assert_eq!(play_price_idr(100_000.0), 115_000.0);
    }

    #[test]
    fn parse_plan_product() {
        let p = parse_play_product("id.alienai.plan.pro.monthly").unwrap();
        match p {
            PlayProduct::Plan { slug, period, months } => {
                assert_eq!(slug, "pro");
                assert_eq!(period, "monthly");
                assert_eq!(months, 1);
            }
            _ => panic!("expected plan"),
        }

        // Test unprefixed and underscore formats
        let p2 = parse_play_product("plan.lite.monthly").unwrap();
        match p2 {
            PlayProduct::Plan { slug, period, months } => {
                assert_eq!(slug, "lite");
                assert_eq!(period, "monthly");
                assert_eq!(months, 1);
            }
            _ => panic!("expected plan"),
        }

        let p3 = parse_play_product("ultra_yearly").unwrap();
        match p3 {
            PlayProduct::Plan { slug, period, months } => {
                assert_eq!(slug, "ultra");
                assert_eq!(period, "yearly");
                assert_eq!(months, 12);
            }
            _ => panic!("expected plan"),
        }

        let p4 = parse_play_product("lite").unwrap();
        match p4 {
            PlayProduct::Plan { slug, period, months } => {
                assert_eq!(slug, "lite");
                assert_eq!(period, "monthly");
                assert_eq!(months, 1);
            }
            _ => panic!("expected plan"),
        }
    }

    #[test]
    fn parse_credit_product() {
        let p = parse_play_product("id.alienai.credit.50000").unwrap();
        match p {
            PlayProduct::Credit { amount_idr } => assert_eq!(amount_idr, 50_000.0),
            _ => panic!("expected credit"),
        }

        let p2 = parse_play_product("credit.100k").unwrap();
        match p2 {
            PlayProduct::Credit { amount_idr } => assert_eq!(amount_idr, 100_000.0),
            _ => panic!("expected credit"),
        }

        let p3 = parse_play_product("credit_50000").unwrap();
        match p3 {
            PlayProduct::Credit { amount_idr } => assert_eq!(amount_idr, 50_000.0),
            _ => panic!("expected credit"),
        }
    }
}
