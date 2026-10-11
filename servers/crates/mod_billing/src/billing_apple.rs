//! Apple App Store in-app purchase verification (iOS).

use c35_proto::{ReqBillingPlayVerify, ResBillingPlayVerify};
use c35_store::snowflake_id;
use serde_json::json;
use sqlx::{PgPool, Row};

use crate::billing_play::{
    billing_play_sync_owner, billing_store_commit_purchase, finish_verify_response, parse_play_product,
    play_package_name, play_profile_plan_expires_ms, play_purchase_existing,
};

pub fn apple_stub_enabled() -> bool {
    std::env::var("C35_APPLE_IAP_STUB")
        .map(|v| v == "1" || v.eq_ignore_ascii_case("true"))
        .unwrap_or(false)
}

fn apple_shared_secret() -> Option<String> {
    std::env::var("APPLE_IAP_SHARED_SECRET")
        .ok()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
}

#[derive(serde::Deserialize)]
struct AppleVerifyResponse {
    status: i32,
}

pub async fn billing_apple_verify(
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
        billing_play_sync_owner(pool, owner_iid).await;
        let ent_id: Option<i64> = row.get("entitlement_id");
        let expires = play_profile_plan_expires_ms(pool, owner_iid).await;
        let expires = if expires > 0 {
            expires
        } else {
            chrono::Utc::now().timestamp_millis() + 30 * 86400 * 1000
        };
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

    let stub = apple_stub_enabled();
    let verify_body = if stub {
        json!({ "stub": true, "store": "apple", "product_id": product_id })
    } else if let Some(secret) = apple_shared_secret() {
        let body = json!({
            "receipt-data": purchase_token,
            "password": secret,
            "exclude-old-transactions": true,
        });
        let client = crate::billing_http::billing_http_client();
        let mut resp = post_verify(&client, "https://buy.itunes.apple.com/verifyReceipt", &body)
            .await
            .map_err(|e| e.to_string())?;
        if resp.status == 21007 {
            resp = post_verify(&client, "https://sandbox.itunes.apple.com/verifyReceipt", &body)
                .await
                .map_err(|e| e.to_string())?;
        }
        if resp.status != 0 {
            return Err(format!("Apple verifyReceipt rejected status {}", resp.status));
        }
        json!({ "apple_status": resp.status, "product_id": product_id })
    } else {
        return Err(
            "Apple IAP verify not configured (set APPLE_IAP_SHARED_SECRET or C35_APPLE_IAP_STUB=1 for dev)".into(),
        );
    };

    let order_id = if stub {
        format!("apple-stub-{}", snowflake_id())
    } else {
        format!("apple-{}", snowflake_id())
    };
    let source = if stub { "apple_stub" } else { "apple" };
    let status_tag = if stub { "apple_stub" } else { "apple_verified" };

    billing_store_commit_purchase(
        pool,
        owner_iid,
        product_id,
        purchase_token,
        &package,
        &product,
        &verify_body,
        &order_id,
        source,
        status_tag,
    )
    .await
}

async fn post_verify(
    client: &reqwest::Client,
    url: &str,
    body: &serde_json::Value,
) -> Result<AppleVerifyResponse, anyhow::Error> {
    let res = client.post(url).json(body).send().await?;
    let parsed: AppleVerifyResponse = res.json().await?;
    Ok(parsed)
}