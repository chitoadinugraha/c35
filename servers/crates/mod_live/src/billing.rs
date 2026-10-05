use anyhow::Result;
use async_nats::Client;
use c35_mod_billing::{
    billing_account_ensure, billing_deduct_allowance, billing_gate_with_hold_custom,
    billing_reservation_refund, billing_reservation_settle, billing_to_retail_usd, BillingRow,
};
use c35_mod_log::{log_put, LogPut};
use sqlx::PgPool;

use crate::catalog::{live_retail_usd_per_min, LiveOfferRow};

pub fn live_req_id(raw: &str, sid: &str) -> String {
    let raw = raw.trim();
    if !raw.is_empty() {
        return if raw.starts_with("live-") {
            raw.to_string()
        } else {
            format!("live-{raw}")
        };
    }
    format!("live-{sid}")
}

pub fn live_hold_retail_usd(offer: &LiveOfferRow) -> f64 {
    (live_retail_usd_per_min(offer) * 2.0).max(0.05)
}

pub fn live_wholesale_usd(offer: &LiveOfferRow, duration_secs: f64) -> f64 {
    let mins = (duration_secs / 60.0).max(0.0);
    mins * (offer.input_usd_per_min + offer.output_usd_per_min)
}

pub async fn live_billing_gate(
    pool: &PgPool,
    owner_iid: i64,
    req_id: &str,
    offer: &LiveOfferRow,
) -> Result<BillingRow> {
    let row = billing_account_ensure(pool, owner_iid).await?;
    let hold = live_hold_retail_usd(offer);
    billing_gate_with_hold_custom(pool, owner_iid, &row, req_id, hold).await?;
    Ok(row)
}

pub async fn live_billing_abort(pool: &PgPool, req_id: &str) -> Result<()> {
    billing_reservation_refund(pool, req_id).await
}

pub async fn live_billing_settle(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    row: &BillingRow,
    req_id: &str,
    offer: &LiveOfferRow,
    duration_secs: f64,
) -> Result<()> {
    let wholesale = live_wholesale_usd(offer, duration_secs);
    let duration_ms = (duration_secs * 1000.0).round().clamp(0.0, i32::MAX as f64) as i32;
    let topic = "live.session";
    let text = format!("Live call {} ({duration_secs:.1}s)", offer.id);
    let meta = serde_json::json!({ "offer_id": offer.id, "wholesale_usd": wholesale });
    let _ = voice_style_settle(
        pool,
        nats,
        owner_iid,
        row,
        req_id,
        wholesale,
        topic,
        &text,
        &offer.provider_model,
        duration_ms,
        meta,
    )
    .await?;
    Ok(())
}

async fn voice_style_settle(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    row: &BillingRow,
    req_id: &str,
    wholesale_usd: f64,
    topic: &str,
    text: &str,
    model: &str,
    duration_ms: i32,
    meta: serde_json::Value,
) -> Result<f64> {
    let cost_usd = billing_to_retail_usd(wholesale_usd);
    if cost_usd <= 0.0 {
        billing_reservation_refund(pool, req_id).await?;
        return Ok(0.0);
    }
    let log_id = log_put(
        pool,
        nats,
        LogPut {
            class: None,
            owner_iid,
            kind: "tool",
            topic,
            dv: "",
            req_id: Some(req_id),
            chat_id: None,
            task_id: None,
            device_iid: None,
            text,
            model,
            tokens_in: 0,
            tokens_out: 0,
            duration_ms,
            cost_usd,
            meta,
        },
    )
    .await?;
    let inserted = sqlx::query(
        r#"
        INSERT INTO ai.billing_usage_dedupe (owner_iid, req_id, cost_usd, cost_wholesale_usd, billing_account_id, log_id)
        VALUES ($1, $2, $3, $4, $5, $6)
        ON CONFLICT (owner_iid, req_id) DO NOTHING
        "#,
    )
    .bind(owner_iid)
    .bind(req_id)
    .bind(cost_usd)
    .bind(wholesale_usd)
    .bind(row.id)
    .bind(log_id)
    .execute(pool)
    .await?;
    if inserted.rows_affected() == 0 {
        billing_reservation_refund(pool, req_id).await?;
        return Ok(0.0);
    }
    let row_after = billing_deduct_allowance(pool, owner_iid, cost_usd).await?;
    let acct = sqlx::query_as::<_, (String, String, i64)>(
        "SELECT balance_idr::text, billing_currency, fx_micro_per_usd FROM ai.billing_account WHERE id = $1",
    )
    .bind(row_after.id)
    .fetch_one(pool)
    .await?;
    let balance_idr = acct.0.parse().unwrap_or(0.0);
    billing_reservation_settle(
        pool,
        owner_iid,
        &row_after,
        req_id,
        cost_usd,
        balance_idr,
        &acct.1,
        acct.2,
    )
    .await?;
    c35_mod_billing::billing_notify_owner(pool, nats, owner_iid, None).await;
    Ok(cost_usd)
}
