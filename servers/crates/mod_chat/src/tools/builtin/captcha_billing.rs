//! Per-solve captcha billing (hold → settle), same pattern as `mod_voice` STT/TTS.
//! Uses a child `req_id` so prompt-turn settlement does not double-charge.

use anyhow::Result;
use c35_mod_billing::{
    billing_account_ensure, billing_can_afford_tool, billing_deduct_personal_profile,
    billing_gate_with_hold_custom, billing_reservation_refund, billing_reservation_settle,
    billing_to_retail_usd, BillingRow,
};
use c35_mod_captcha::{captcha_retail_usd, captcha_wholesale_usd, CaptchaKind};
use c35_mod_log::{log_put, LogPut};
use c35_store::snowflake_id;
use serde_json::json;
use sqlx::PgPool;

pub fn captcha_billing_req_id(parent_req_id: &str, tool_call_id: &str) -> String {
    let tc = tool_call_id.trim();
    if !tc.is_empty() {
        return format!("captcha_{tc}");
    }
    let parent = parent_req_id.trim();
    if parent.is_empty() {
        return format!("captcha_{}", snowflake_id());
    }
    format!("captcha_{parent}_{}", snowflake_id())
}

pub async fn captcha_billing_gate(
    pool: &PgPool,
    owner_iid: i64,
    billing_req_id: &str,
    kind: CaptchaKind,
) -> Result<BillingRow> {
    let retail = captcha_retail_usd(kind);
    if retail <= 0.0 {
        return billing_account_ensure(pool, owner_iid).await;
    }
    let can = billing_can_afford_tool(pool, owner_iid, retail)
        .await
        .unwrap_or(false);
    if !can {
        anyhow::bail!(
            "Not enough balance or quota to solve captcha. Please top up or wait for quota reset."
        );
    }
    let row = billing_account_ensure(pool, owner_iid).await?;
    billing_gate_with_hold_custom(pool, owner_iid, &row, billing_req_id, retail).await?;
    Ok(row)
}

pub async fn captcha_billing_abort(pool: &PgPool, billing_req_id: &str) -> Result<()> {
    billing_reservation_refund(pool, billing_req_id).await
}

pub async fn captcha_billing_settle(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    owner_iid: i64,
    row: &BillingRow,
    billing_req_id: &str,
    parent_req_id: &str,
    kind: CaptchaKind,
    duration_ms: i32,
    device_iid: i64,
    task_id: &str,
) -> Result<f64> {
    let wholesale = captcha_wholesale_usd(kind);
    let cost_usd = billing_to_retail_usd(wholesale);
    if cost_usd <= 0.0 {
        captcha_billing_abort(pool, billing_req_id).await?;
        return Ok(0.0);
    }
    let topic = format!("captcha.solve:{}", kind.billing_kind_key());
    let meta = json!({
        "sku": topic,
        "kind": kind.billing_kind_key(),
        "parent_req_id": parent_req_id,
        "device_iid": device_iid,
        "task_id": task_id,
        "wholesale_usd": wholesale,
    });
    let log_id = log_put(
        pool,
        nats,
        LogPut {
            class: None,
            owner_iid,
            kind: "tool",
            topic: &topic,
            dv: "",
            req_id: Some(billing_req_id),
            chat_id: None,
            task_id: None,
            device_iid: if device_iid > 0 { Some(device_iid) } else { None },
            text: "captcha solve",
            model: "captcha",
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
    .bind(billing_req_id)
    .bind(cost_usd)
    .bind(wholesale)
    .bind(row.id)
    .bind(log_id)
    .execute(pool)
    .await?;
    if inserted.rows_affected() == 0 {
        captcha_billing_abort(pool, billing_req_id).await?;
        return Ok(0.0);
    }
    let row_after =
        billing_deduct_personal_profile(pool, owner_iid, "frontier", cost_usd).await?;
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
        billing_req_id,
        cost_usd,
        balance_idr,
        &acct.1,
        acct.2,
    )
    .await?;
    c35_mod_billing::billing_notify_owner(pool, nats, owner_iid, None).await;
    Ok(cost_usd)
}
