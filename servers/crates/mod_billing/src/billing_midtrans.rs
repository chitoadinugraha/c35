use anyhow::{anyhow, Result};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha512};
use tracing::warn;

pub const USD_IDR_DEFAULT: f64 = 16_000.0;
pub const TOPUP_MIN_IDR: i64 = 50_000;
pub const TOPUP_MIN_USD: f64 = 10.0;

pub fn amount_usd_ok(amount_usd: f64) -> bool {
    amount_usd + 0.001 >= TOPUP_MIN_USD
}

pub fn amount_idr_ok(amount_idr: i64) -> bool {
    amount_idr >= TOPUP_MIN_IDR
}

pub fn resolve_topup_amounts(amount_usd: f64, amount_idr: f64, usd_idr: f64) -> Result<(i64, f64)> {
    let rate = if usd_idr > 0.0 { usd_idr } else { USD_IDR_DEFAULT };
    if amount_idr > 0.0 {
        let idr = amount_idr.round() as i64;
        if !amount_idr_ok(idr) {
            return Err(anyhow!("amount_idr must be at least {TOPUP_MIN_IDR}"));
        }
        let usd = ((amount_idr / rate) * 100.0).round() / 100.0;
        return Ok((idr, usd));
    }
    if !amount_usd_ok(amount_usd) {
        return Err(anyhow!("amount_usd must be at least {TOPUP_MIN_USD}"));
    }
    Ok((usd_to_idr(amount_usd, rate), amount_usd))
}

pub fn usd_to_idr(amount_usd: f64, usd_idr: f64) -> i64 {
    let rate = if usd_idr > 0.0 { usd_idr } else { USD_IDR_DEFAULT };
    (amount_usd * rate).round() as i64
}

pub fn signature_hex(order_id: &str, status_code: &str, gross_amount: &str, server_key: &str) -> String {
    let mut hasher = Sha512::new();
    hasher.update(order_id.as_bytes());
    hasher.update(status_code.as_bytes());
    hasher.update(gross_amount.as_bytes());
    hasher.update(server_key.as_bytes());
    hasher.finalize().iter().map(|b| format!("{:02x}", b)).collect()
}

pub fn signature_verify(order_id: &str, status_code: &str, gross_amount: &str, server_key: &str, signature_key: &str) -> bool {
    !server_key.is_empty()
        && signature_hex(order_id, status_code, gross_amount, server_key)
            .eq_ignore_ascii_case(signature_key.trim())
}

pub fn snap_host(is_production: bool) -> &'static str {
    if is_production {
        "https://app.midtrans.com"
    } else {
        "https://app.sandbox.midtrans.com"
    }
}

pub fn api_host(is_production: bool) -> &'static str {
    if is_production {
        "https://api.midtrans.com"
    } else {
        "https://api.sandbox.midtrans.com"
    }
}

pub fn snap_payments(payment_type: &str) -> Vec<String> {
    match payment_type {
        "qris" | "" => vec!["qris".into()],
        "bank_transfer" => vec![
            "bca_va".into(),
            "bni_va".into(),
            "bri_va".into(),
            "permata_va".into(),
            "echannel".into(),
        ],
        "credit_card" => vec!["credit_card".into()],
        _ => vec![
            "qris".into(),
            "gopay".into(),
            "shopeepay".into(),
            "bca_va".into(),
            "bni_va".into(),
            "bri_va".into(),
        ],
    }
}

#[derive(Debug, Clone, Deserialize)]
pub struct Notification {
    #[serde(default)]
    pub order_id: String,
    #[serde(default)]
    pub status_code: String,
    #[serde(default)]
    pub gross_amount: String,
    #[serde(default)]
    pub signature_key: String,
    #[serde(default)]
    pub transaction_status: String,
    pub fraud_status: Option<String>,
    pub payment_type: Option<String>,
    pub transaction_id: Option<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SettlePlan {
    Credit,
    AlreadySettled,
    MarkExpired,
    MarkFailed,
    Ignore,
    NotFound,
}

pub fn is_paid_status(transaction_status: &str, fraud_status: Option<&str>) -> bool {
    match transaction_status {
        "settlement" => true,
        "capture" => fraud_status.unwrap_or("accept") == "accept",
        _ => false,
    }
}

pub fn settle_plan(row_status: Option<&str>, n: &Notification) -> SettlePlan {
    match row_status {
        None => SettlePlan::NotFound,
        Some("settled") => SettlePlan::AlreadySettled,
        Some("pending") if is_paid_status(&n.transaction_status, n.fraud_status.as_deref()) => SettlePlan::Credit,
        Some("pending") if matches!(n.transaction_status.as_str(), "expire" | "expired") => SettlePlan::MarkExpired,
        Some("pending")
            if matches!(n.transaction_status.as_str(), "deny" | "cancel" | "failure" | "failed") =>
        {
            SettlePlan::MarkFailed
        }
        _ => SettlePlan::Ignore,
    }
}

#[derive(Debug, Clone, Default)]
pub struct PaymentCreated {
    pub order_id: String,
    pub payment_url: String,
    pub qr_code_data: String,
    pub snap_token: String,
}

#[derive(Serialize)]
struct TxDetails {
    order_id: String,
    gross_amount: i64,
}

#[derive(Serialize)]
struct ItemDetail {
    id: String,
    price: i64,
    quantity: i32,
    name: String,
}

#[derive(Serialize)]
struct SnapReq {
    transaction_details: TxDetails,
    item_details: Vec<ItemDetail>,
    enabled_payments: Vec<String>,
}

#[derive(Deserialize)]
struct SnapRes {
    token: Option<String>,
    redirect_url: Option<String>,
    error_messages: Option<Vec<String>>,
}

#[derive(Serialize)]
struct QrisReq {
    payment_type: String,
    transaction_details: TxDetails,
    qris: serde_json::Value,
}

#[derive(Deserialize)]
struct ChargeRes {
    qr_string: Option<String>,
    redirect_url: Option<String>,
    actions: Option<Vec<ChargeAction>>,
    status_code: Option<String>,
    status_message: Option<String>,
    error_messages: Option<Vec<String>>,
}

#[derive(Deserialize)]
struct ChargeAction {
    name: Option<String>,
    url: Option<String>,
}

fn require_server_key(server_key: &str) -> Result<()> {
    if server_key.is_empty() {
        Err(anyhow!(
            "MIDTRANS_SERVER_KEY is not configured; Snap/QRIS top-up disabled until keys are set"
        ))
    } else {
        Ok(())
    }
}

pub async fn snap_create(
    client: &reqwest::Client,
    server_key: &str,
    is_production: bool,
    order_id: &str,
    gross_idr: i64,
    item_name: &str,
    payment_type: &str,
) -> Result<PaymentCreated> {
    require_server_key(server_key)?;
    let url = format!("{}/snap/v1/transactions", snap_host(is_production));
    let body = SnapReq {
        transaction_details: TxDetails {
            order_id: order_id.to_string(),
            gross_amount: gross_idr,
        },
        item_details: vec![ItemDetail {
            id: format!("wallet-{}", order_id),
            price: gross_idr,
            quantity: 1,
            name: item_name.to_string(),
        }],
        enabled_payments: snap_payments(payment_type),
    };
    let res = client.post(&url).basic_auth(server_key, Some("")).json(&body).send().await?;
    let status = res.status();
    let text = res.text().await.unwrap_or_default();
    if !status.is_success() {
        return Err(anyhow!("Midtrans Snap HTTP {}: {}", status, text));
    }
    let parsed: SnapRes =
        serde_json::from_str(&text).map_err(|e| anyhow!("Midtrans Snap decode: {e}; body={text}"))?;
    if let Some(errs) = parsed.error_messages.filter(|e| !e.is_empty()) {
        return Err(anyhow!("Midtrans Snap: {}", errs.join("; ")));
    }
    let payment_url = parsed.redirect_url.unwrap_or_default();
    Ok(PaymentCreated {
        order_id: order_id.to_string(),
        qr_code_data: if payment_type == "qris" {
            payment_url.clone()
        } else {
            String::new()
        },
        payment_url,
        snap_token: parsed.token.unwrap_or_default(),
    })
}

pub async fn qris_charge(
    client: &reqwest::Client,
    server_key: &str,
    is_production: bool,
    order_id: &str,
    gross_idr: i64,
) -> Result<PaymentCreated> {
    require_server_key(server_key)?;
    let url = format!("{}/v2/charge", api_host(is_production));
    let body = QrisReq {
        payment_type: "qris".into(),
        transaction_details: TxDetails {
            order_id: order_id.to_string(),
            gross_amount: gross_idr,
        },
        qris: serde_json::json!({ "acquirer": "gopay" }),
    };
    let res = client.post(&url).basic_auth(server_key, Some("")).json(&body).send().await?;
    let status = res.status();
    let text = res.text().await.unwrap_or_default();
    if !status.is_success() {
        return Err(anyhow!("Midtrans QRIS HTTP {}: {}", status, text));
    }
    let parsed: ChargeRes =
        serde_json::from_str(&text).map_err(|e| anyhow!("Midtrans QRIS decode: {e}; body={text}"))?;
    if let Some(errs) = parsed.error_messages.filter(|e| !e.is_empty()) {
        return Err(anyhow!("Midtrans QRIS: {}", errs.join("; ")));
    }
    if let Some(code) = parsed.status_code.as_deref() {
        if !(code == "201" || code == "200") {
            return Err(anyhow!(
                "Midtrans QRIS status {}: {}",
                code,
                parsed.status_message.unwrap_or_default()
            ));
        }
    }
    let action_url = parsed.actions.unwrap_or_default().into_iter().find_map(|a| {
        let name = a.name.unwrap_or_default();
        if name.contains("qr") { a.url } else { None }
    });
    let qr = parsed.qr_string.unwrap_or_default();
    let payment_url = parsed.redirect_url.or(action_url).unwrap_or_default();
    Ok(PaymentCreated {
        order_id: order_id.to_string(),
        payment_url,
        qr_code_data: qr,
        snap_token: String::new(),
    })
}

pub async fn payment_create(
    client: &reqwest::Client,
    server_key: &str,
    is_production: bool,
    order_id: &str,
    gross_idr: i64,
    item_name: &str,
    payment_type: &str,
) -> Result<PaymentCreated> {
    let qris = payment_type.is_empty() || payment_type == "qris";
    if qris {
        match qris_charge(client, server_key, is_production, order_id, gross_idr).await {
            Ok(p) => return Ok(p),
            Err(e) => warn!("[c35:billing] QRIS charge failed, falling back to Snap: {e:#}"),
        }
    }
    snap_create(client, server_key, is_production, order_id, gross_idr, item_name, payment_type).await
}

#[cfg(test)]
mod tests {
    use super::*;

    const FIXTURE_ORDER: &str = "cs-topup-1";
    const FIXTURE_STATUS: &str = "200";
    const FIXTURE_GROSS: &str = "160000.00";
    const FIXTURE_KEY: &str = "SB-Mid-server-testkey";
    const FIXTURE_SIG: &str =
        "6502ed53175e0264e4b60d5eaea21ec359dfcb63ed961f040620d6feded92bf1d8f574f60e7703849c62ce85c6a5046844dab117e866e355ca143419f308e9fd";

    #[test]
    fn signature_verify_matches_sha512_fixture() {
        assert!(signature_verify(
            FIXTURE_ORDER,
            FIXTURE_STATUS,
            FIXTURE_GROSS,
            FIXTURE_KEY,
            FIXTURE_SIG
        ));
        assert_eq!(
            signature_hex(FIXTURE_ORDER, FIXTURE_STATUS, FIXTURE_GROSS, FIXTURE_KEY),
            FIXTURE_SIG
        );
    }

    #[test]
    fn signature_verify_rejects_tamper() {
        assert!(!signature_verify(FIXTURE_ORDER, "202", FIXTURE_GROSS, FIXTURE_KEY, FIXTURE_SIG));
        assert!(!signature_verify(FIXTURE_ORDER, FIXTURE_STATUS, FIXTURE_GROSS, "", FIXTURE_SIG));
        assert!(!signature_verify(
            FIXTURE_ORDER,
            FIXTURE_STATUS,
            FIXTURE_GROSS,
            FIXTURE_KEY,
            "deadbeef"
        ));
    }

    #[test]
    fn usd_packs_convert_at_16000_idr() {
        assert_eq!(usd_to_idr(10.0, USD_IDR_DEFAULT), 160_000);
        assert_eq!(usd_to_idr(20.0, USD_IDR_DEFAULT), 320_000);
        assert!(amount_usd_ok(10.0) && amount_usd_ok(20.0) && amount_usd_ok(15.0) && !amount_usd_ok(5.0));
        assert!(amount_idr_ok(50_000) && amount_idr_ok(75_000) && !amount_idr_ok(10_000));
        let (idr, usd) = resolve_topup_amounts(0.0, 100_000.0, USD_IDR_DEFAULT).unwrap();
        assert_eq!(idr, 100_000);
        assert!((usd - 6.25).abs() < 0.01);
    }

    #[test]
    fn settle_is_idempotent_when_already_settled() {
        let n = Notification {
            order_id: "cs-1".into(),
            status_code: "200".into(),
            gross_amount: "160000.00".into(),
            signature_key: FIXTURE_SIG.into(),
            transaction_status: "settlement".into(),
            fraud_status: Some("accept".into()),
            payment_type: Some("qris".into()),
            transaction_id: None,
        };
        assert_eq!(settle_plan(Some("pending"), &n), SettlePlan::Credit);
        assert_eq!(settle_plan(Some("settled"), &n), SettlePlan::AlreadySettled);
        assert_eq!(settle_plan(None, &n), SettlePlan::NotFound);
        let mut pending = n.clone();
        pending.transaction_status = "pending".into();
        assert_eq!(settle_plan(Some("pending"), &pending), SettlePlan::Ignore);
        pending.transaction_status = "expire".into();
        assert_eq!(settle_plan(Some("pending"), &pending), SettlePlan::MarkExpired);
    }
}
