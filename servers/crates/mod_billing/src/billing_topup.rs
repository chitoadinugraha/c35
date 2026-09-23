use c35_proto::{
    BillingTopupMethodOption, BillingTopupRequest, ReqBillingTopupGet, ReqBillingTopupMethods,
    ReqBillingTopupPut, ResBillingTopupGet, ResBillingTopupMethods, ResBillingTopupPut,
};
use c35_store::snowflake_id;
use sqlx::{PgPool, Postgres, Row, Transaction};
use tracing::{info, warn};

use crate::billing_midtrans::{
    midtrans_fee_idr, midtrans_fee_is_percent, midtrans_fee_rate_bps, payment_channel_label,
    payment_create, resolve_topup_amounts, snap_merchant_payment_channels, Notification, SettlePlan,
    TOPUP_MIN_IDR,
};
use crate::fx_live::fx_live_idr_per_usd;
use crate::billing_receive_account::receive_account_default;
use crate::billing_runtime::billing_runtime;

const FX_MICRO_DEFAULT: i64 = 17_630_000_000;

pub async fn billing_topup_put(
    pool: &PgPool,
    owner_iid: i64,
    req: ReqBillingTopupPut,
) -> Result<ResBillingTopupPut, String> {
    if owner_iid <= 0 {
        return Err("unauthorized".into());
    }
    let provider = if req.provider.trim().is_empty() {
        "manual".into()
    } else {
        req.provider.trim().to_lowercase()
    };
    if provider == "manual" {
        return billing_manual_topup_put(pool, owner_iid, req).await;
    }
    if provider != "midtrans" {
        return Err(format!("unsupported provider: {provider}"));
    }
    billing_midtrans_topup_put(pool, owner_iid, req).await
}

async fn billing_account_row(pool: &PgPool, owner_iid: i64) -> Result<sqlx::postgres::PgRow, String> {
    sqlx::query(
        r#"SELECT id, balance_idr, fx_micro_per_usd FROM ai.billing_account
           WHERE owner_iid = $1 AND deleted_ts IS NULL LIMIT 1"#,
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    .ok_or_else(|| "billing account not found".to_string())
}

async fn billing_manual_topup_put(
    pool: &PgPool,
    owner_iid: i64,
    req: ReqBillingTopupPut,
) -> Result<ResBillingTopupPut, String> {
    if req.proof_url.trim().is_empty() {
        return Err("transfer proof URL is required".into());
    }
    let account = billing_account_row(pool, owner_iid).await?;
    let account_id: i64 = account.get("id");
    let _fx_micro: i64 = account.try_get("fx_micro_per_usd").unwrap_or(FX_MICRO_DEFAULT);
    let rt = billing_runtime();
    let usd_idr = topup_usd_idr_rate(rt.midtrans_usd_idr);
    let (amount_idr, amount_usd) = resolve_topup_amounts(req.amount_usd, req.amount_idr, usd_idr)
        .map_err(|e| e.to_string())?;
    let receive = receive_account_default(pool, "IDR").await?;
    let instruction = format!(
        "Transfer {} to {} · {} ({}). Balance credits after review.",
        wallet_idr_label(amount_idr as i64),
        receive.bank_id,
        receive.account_number,
        receive.account_name
    );
    let id = snowflake_id();
    let order_id = format!("c35-manual-{id}");
    let payment_type = if req.payment_type.trim().is_empty() {
        "bank_transfer".into()
    } else {
        req.payment_type.trim().to_string()
    };
    let now_ms = chrono::Utc::now().timestamp_millis();
    sqlx::query(
        r#"
        INSERT INTO ai.billing_topup_request (
            id, owner_iid, billing_account_id, amount_usd, amount_idr,
            provider, payment_type, external_order_id, proof_url, status
        ) VALUES ($1, $2, $3, $4, $5, 'manual', $6, $7, $8, 'pending_review')
        "#,
    )
    .bind(id)
    .bind(owner_iid)
    .bind(account_id)
    .bind(amount_usd)
    .bind(amount_idr as f64)
    .bind(&payment_type)
    .bind(&order_id)
    .bind(req.proof_url.trim())
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    let request = BillingTopupRequest {
        id,
        owner_iid,
        billing_account_id: account_id,
        amount_usd,
        amount_idr: amount_idr as f64,
        provider: "manual".into(),
        payment_type,
        external_order_id: order_id.clone(),
        proof_url: req.proof_url.trim().to_string(),
        status: "pending_review".into(),
        created_ts_ms: now_ms,
        ..Default::default()
    };
    Ok(ResBillingTopupPut {
        request: Some(request),
        order_id,
        payment_url: String::new(),
        qr_code_data: String::new(),
        instruction,
        status: "pending_review".into(),
        credit_amount_idr: amount_idr as f64,
        fee_amount_idr: 0.0,
        gross_amount_idr: amount_idr as f64,
    })
}

pub async fn billing_topup_methods(
    pool: &PgPool,
    owner_iid: i64,
    req: ReqBillingTopupMethods,
) -> Result<ResBillingTopupMethods, String> {
    if owner_iid <= 0 {
        return Err("unauthorized".into());
    }
    let sample = if req.sample_amount_idr > 0.0 {
        req.sample_amount_idr.round() as i64
    } else {
        TOPUP_MIN_IDR
    };
    let mut methods = vec![BillingTopupMethodOption {
        id: "manual".into(),
        label: "Manual transfer".into(),
        provider: "manual".into(),
        payment_type: "bank_transfer".into(),
        note: "Must wait Admin approval".into(),
        fee_amount_idr: 0.0,
        fee_is_percent: false,
        fee_rate_bps: 0.0,
    }];
    let rt = billing_runtime();
    match snap_merchant_payment_channels(&rt.http, &rt.midtrans_server_key, rt.midtrans_is_production).await {
        Ok(channels) => {
            for ch in channels {
                let fee = midtrans_fee_idr(&ch, sample) as f64;
                methods.push(BillingTopupMethodOption {
                    id: ch.clone(),
                    label: payment_channel_label(&ch),
                    provider: "midtrans".into(),
                    payment_type: ch.clone(),
                    note: "Fee added to total".into(),
                    fee_amount_idr: fee,
                    fee_is_percent: midtrans_fee_is_percent(&ch),
                    fee_rate_bps: midtrans_fee_rate_bps(&ch),
                });
            }
        }
        Err(e) => {
            warn!("[c35:billing] midtrans payment channels fallback: {e:#}");
            for ch in ["qris", "bca_va", "bni_va", "gopay", "shopeepay"] {
                let fee = midtrans_fee_idr(ch, sample) as f64;
                methods.push(BillingTopupMethodOption {
                    id: ch.into(),
                    label: payment_channel_label(ch),
                    provider: "midtrans".into(),
                    payment_type: ch.into(),
                    note: "Fee added to total".into(),
                    fee_amount_idr: fee,
                    fee_is_percent: midtrans_fee_is_percent(ch),
                    fee_rate_bps: midtrans_fee_rate_bps(ch),
                });
            }
        }
    }
    let _ = pool;
    Ok(ResBillingTopupMethods { methods })
}

pub async fn billing_topup_get(pool: &PgPool, owner_iid: i64, req: ReqBillingTopupGet) -> Result<ResBillingTopupGet, String> {
    if owner_iid <= 0 {
        return Err("unauthorized".into());
    }
    let order_id = req.order_id.trim();
    if order_id.is_empty() {
        return Err("order_id required".into());
    }
    let row = sqlx::query(
        r#"
        SELECT id, owner_iid, billing_account_id, amount_usd, amount_idr, provider, payment_type,
               external_order_id, proof_url, status, created_ts
        FROM ai.billing_topup_request
        WHERE owner_iid = $1 AND external_order_id = $2
        LIMIT 1
        "#,
    )
    .bind(owner_iid)
    .bind(order_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    let r = row.ok_or_else(|| "top-up not found".to_string())?;
    let created = r
        .try_get::<chrono::DateTime<chrono::Utc>, _>("created_ts")
        .map(|t| t.timestamp_millis())
        .unwrap_or(0);
    Ok(ResBillingTopupGet {
        request: Some(BillingTopupRequest {
            id: r.get("id"),
            owner_iid: r.get("owner_iid"),
            billing_account_id: r.get("billing_account_id"),
            amount_usd: r.get("amount_usd"),
            amount_idr: r.get("amount_idr"),
            provider: r.get("provider"),
            payment_type: r.get("payment_type"),
            external_order_id: r.get("external_order_id"),
            proof_url: r.get("proof_url"),
            status: r.get("status"),
            created_ts_ms: created,
            ..Default::default()
        }),
    })
}

async fn billing_midtrans_topup_put(
    pool: &PgPool,
    owner_iid: i64,
    req: ReqBillingTopupPut,
) -> Result<ResBillingTopupPut, String> {
    let rt = billing_runtime();
    let usd_idr = topup_usd_idr_rate(rt.midtrans_usd_idr);
    let (credit_idr, amount_usd) = resolve_topup_amounts(req.amount_usd, req.amount_idr, usd_idr)
        .map_err(|e| e.to_string())?;
    let account = billing_account_row(pool, owner_iid).await?;
    let account_id: i64 = account.get("id");
    let payment_method = if req.payment_type.trim().is_empty() {
        "qris".into()
    } else {
        req.payment_type.trim().to_string()
    };
    let fee_idr = midtrans_fee_idr(&payment_method, credit_idr);
    let charge_idr = credit_idr + fee_idr;
    let topup_id = snowflake_id();
    let order_id = format!("c35-{topup_id}");
    let item_name = if req.amount_idr > 0.0 {
        format!("Alien AI wallet {}", wallet_idr_label(credit_idr))
    } else {
        format!("Alien AI wallet ${amount_usd:.2}")
    };
    sqlx::query(
        r#"
        INSERT INTO ai.billing_topup_request (
            id, owner_iid, billing_account_id, amount_usd, amount_idr,
            provider, payment_type, external_order_id, proof_url, status, meta
        ) VALUES ($1, $2, $3, $4, $5, 'midtrans', $6, $7, '', 'pending', $8)
        "#,
    )
    .bind(topup_id)
    .bind(owner_iid)
    .bind(account_id)
    .bind(amount_usd)
    .bind(credit_idr as f64)
    .bind(&payment_method)
    .bind(&order_id)
    .bind(serde_json::json!({
        "usd_idr": usd_idr,
        "owner_iid": owner_iid,
        "credit_idr": credit_idr,
        "fee_idr": fee_idr,
        "gross_idr": charge_idr,
        "amount_usd": amount_usd,
    }))
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    let created = match payment_create(
        &rt.http,
        &rt.midtrans_server_key,
        rt.midtrans_is_production,
        &order_id,
        charge_idr,
        &item_name,
        &payment_method,
    )
    .await
    {
        Ok(p) => p,
        Err(e) => {
            let _ = sqlx::query(
                "UPDATE ai.billing_topup_request SET status = 'failed', meta = COALESCE(meta, '{}'::jsonb) || $2::jsonb WHERE id = $1",
            )
            .bind(topup_id)
            .bind(serde_json::json!({ "create_error": e.to_string() }))
            .execute(pool)
            .await;
            return Err(e.to_string());
        }
    };
    let _ = sqlx::query(
        "UPDATE ai.billing_topup_request SET meta = COALESCE(meta, '{}'::jsonb) || $2::jsonb WHERE id = $1",
    )
    .bind(topup_id)
    .bind(serde_json::json!({
        "snap_token": created.snap_token,
        "payment_url": created.payment_url,
    }))
    .execute(pool)
    .await;
    let now_ms = chrono::Utc::now().timestamp_millis();
    let fee_f = fee_idr as f64;
    let credit_f = credit_idr as f64;
    let gross_f = charge_idr as f64;
    Ok(ResBillingTopupPut {
        request: Some(BillingTopupRequest {
            id: topup_id,
            owner_iid,
            billing_account_id: account_id,
            amount_usd,
            amount_idr: credit_f,
            provider: "midtrans".into(),
            payment_type: payment_method,
            external_order_id: created.order_id.clone(),
            status: "pending".into(),
            created_ts_ms: now_ms,
            ..Default::default()
        }),
        order_id: created.order_id,
        payment_url: created.payment_url,
        qr_code_data: created.qr_code_data,
        instruction: if fee_idr > 0 {
            format!(
                "Pay {} total ({} credit + {} Midtrans fee)",
                wallet_idr_label(charge_idr),
                wallet_idr_label(credit_idr),
                wallet_idr_label(fee_idr)
            )
        } else {
            String::new()
        },
        status: "pending".into(),
        credit_amount_idr: credit_f,
        fee_amount_idr: fee_f,
        gross_amount_idr: gross_f,
    })
}

pub async fn topup_credit_and_accrue(
    tx: &mut Transaction<'_, Postgres>,
    account_id: i64,
    amount: f64,
    currency: &str,
    order_id: &str,
) -> Result<i64, String> {
    if currency.eq_ignore_ascii_case("IDR") {
        sqlx::query(
            "UPDATE ai.billing_account SET balance_idr = balance_idr + $1, updated_ts = NOW() WHERE id = $2",
        )
        .bind(amount)
        .bind(account_id)
        .execute(&mut **tx)
        .await
        .map_err(|e| e.to_string())?;
    } else {
        sqlx::query(
            "UPDATE ai.billing_account SET balance_usd = balance_usd + $1, updated_ts = NOW() WHERE id = $2",
        )
        .bind(amount)
        .bind(account_id)
        .execute(&mut **tx)
        .await
        .map_err(|e| e.to_string())?;
    }
    let owner_iid: Option<i64> = sqlx::query_scalar(
        "SELECT owner_iid FROM ai.billing_account WHERE id = $1",
    )
    .bind(account_id)
    .fetch_optional(&mut **tx)
    .await
    .map_err(|e| e.to_string())?;
    let owner_iid = owner_iid.filter(|u| *u > 0).unwrap_or(0);
    if owner_iid > 0 {
        c35_mod_referral::commission_accrue_on_topup_tx(tx, owner_iid, amount, currency, order_id)
            .await?;
    }
    Ok(owner_iid)
}

pub async fn billing_topup_settle(pool: &PgPool, n: &Notification, raw: &[u8]) -> Result<String, String> {
    let row = sqlx::query(
        r#"
        SELECT owner_iid, billing_account_id,
               COALESCE(amount_usd::FLOAT8, 0) AS amount_usd,
               COALESCE(amount_idr::FLOAT8, 0) AS amount_idr,
               status
        FROM ai.billing_topup_request WHERE external_order_id = $1
        "#,
    )
    .bind(&n.order_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    let (_owner_iid, account_id, _amount_usd, amount_idr, status) = match &row {
        Some(r) => (
            r.get::<i64, _>("owner_iid"),
            r.get::<i64, _>("billing_account_id"),
            r.get::<f64, _>("amount_usd"),
            r.get::<f64, _>("amount_idr"),
            r.get::<String, _>("status"),
        ),
        None => {
            warn!("[c35:billing] webhook order {} not found", n.order_id);
            return Ok("ignored".into());
        }
    };
    let plan = crate::billing_midtrans::settle_plan(Some(status.as_str()), n);
    let meta = serde_json::json!({
        "webhook": serde_json::from_slice::<serde_json::Value>(raw).unwrap_or_else(|_| serde_json::json!({ "raw": String::from_utf8_lossy(raw) })),
        "transaction_status": n.transaction_status,
        "payment_type": n.payment_type,
        "transaction_id": n.transaction_id,
    });
    match plan {
        SettlePlan::AlreadySettled => {
            info!("[c35:billing] order {} already settled", n.order_id);
            Ok("already-settled".into())
        }
        SettlePlan::Ignore | SettlePlan::NotFound => Ok("ok".into()),
        SettlePlan::MarkExpired => {
            let _ = sqlx::query(
                "UPDATE ai.billing_topup_request SET status = 'expired', meta = COALESCE(meta, '{}'::jsonb) || $2::jsonb WHERE external_order_id = $1 AND status = 'pending'",
            )
            .bind(&n.order_id)
            .bind(&meta)
            .execute(pool)
            .await;
            Ok("expired".into())
        }
        SettlePlan::MarkFailed => {
            let _ = sqlx::query(
                "UPDATE ai.billing_topup_request SET status = 'failed', meta = COALESCE(meta, '{}'::jsonb) || $2::jsonb WHERE external_order_id = $1 AND status = 'pending'",
            )
            .bind(&n.order_id)
            .bind(&meta)
            .execute(pool)
            .await;
            Ok("failed".into())
        }
        SettlePlan::Credit => {
            let mut tx = pool.begin().await.map_err(|e| e.to_string())?;
            let updated = sqlx::query(
                r#"
                UPDATE ai.billing_topup_request
                SET status = 'settled', settled_ts = NOW(), meta = COALESCE(meta, '{}'::jsonb) || $2::jsonb
                WHERE external_order_id = $1 AND status = 'pending'
                RETURNING billing_account_id
                "#,
            )
            .bind(&n.order_id)
            .bind(&meta)
            .fetch_optional(&mut *tx)
            .await
            .map_err(|e| e.to_string())?;
            if updated.is_none() {
                tx.commit().await.map_err(|e| e.to_string())?;
                info!("[c35:billing] order {} already settled (race)", n.order_id);
                return Ok("already-settled".into());
            }
            let credited_owner = topup_credit_and_accrue(&mut tx, account_id, amount_idr, "IDR", &n.order_id).await?;
            tx.commit().await.map_err(|e| e.to_string())?;
            if credited_owner > 0 {
                crate::billing_push::billing_notify_owner(pool, None, credited_owner, None).await;
            }
            info!(
                "[c35:billing] credited Rp {:.0} to account {account_id} for {}",
                amount_idr,
                n.order_id
            );
            Ok("settled".into())
        }
    }
}

fn topup_usd_idr_rate(fallback: f64) -> f64 {
    let live = fx_live_idr_per_usd();
    if live > 0.0 { live } else { fallback }
}

fn wallet_idr_label(idr: i64) -> String {
    let s = idr.abs().to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 {
            out.push('.');
        }
        out.push(ch);
    }
    format!("Rp {out}")
}
