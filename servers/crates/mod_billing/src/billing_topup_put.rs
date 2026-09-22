use c35_proto::{BillingTopupRequest, ReqBillingTopupPut, ResBillingTopupPut};
use c35_store::snowflake_id;
use sqlx::{PgPool, Row};

const MIN_TOPUP_IDR: f64 = 50_000.0;
const MIN_TOPUP_USD: f64 = 10.0;
const FX_MICRO_DEFAULT: i64 = 17_630_000_000;

pub async fn billing_topup_put(
    pool: &PgPool,
    owner_iid: i64,
    req: ReqBillingTopupPut,
) -> Result<ResBillingTopupPut, String> {
    let provider = if req.provider.trim().is_empty() {
        "manual".into()
    } else {
        req.provider.trim().to_lowercase()
    };
    if provider != "manual" {
        return Err("only manual top-up is supported in-app for now".into());
    }
    if req.proof_url.trim().is_empty() {
        return Err("transfer proof URL is required".into());
    }

    let account = sqlx::query(
        r#"SELECT id, balance_idr, fx_micro_per_usd FROM ai.billing_account
           WHERE owner_iid = $1 AND deleted_ts IS NULL LIMIT 1"#,
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    .ok_or_else(|| "billing account not found".to_string())?;
    let account_id: i64 = account.get("id");
    let fx_micro: i64 = account.try_get("fx_micro_per_usd").unwrap_or(FX_MICRO_DEFAULT);

    let (amount_idr, amount_usd) = topup_amounts_resolve(req.amount_usd, req.amount_idr, fx_micro);
    if amount_idr + 0.01 < MIN_TOPUP_IDR && amount_usd + 0.001 < MIN_TOPUP_USD {
        return Err(format!("minimum top-up is Rp {} or ${MIN_TOPUP_USD}", MIN_TOPUP_IDR as i64));
    }

    let id = snowflake_id();
    let order_id = format!("c35-topup-{id}");
    let payment_type = if req.payment_type.trim().is_empty() {
        "bank_transfer".into()
    } else {
        req.payment_type.trim().to_string()
    };

    sqlx::query(
        r#"
        INSERT INTO ai.billing_topup_request (
            id, owner_iid, billing_account_id, amount_usd, amount_idr,
            provider, payment_type, external_order_id, proof_url, status
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'pending')
        "#,
    )
    .bind(id)
    .bind(owner_iid)
    .bind(account_id)
    .bind(amount_usd)
    .bind(amount_idr)
    .bind(&provider)
    .bind(&payment_type)
    .bind(&order_id)
    .bind(req.proof_url.trim())
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;

    Ok(ResBillingTopupPut {
        request: Some(BillingTopupRequest {
            id,
            owner_iid,
            billing_account_id: account_id,
            amount_usd,
            amount_idr,
            provider,
            payment_type,
            external_order_id: order_id,
            proof_url: req.proof_url.trim().to_string(),
            status: "pending".into(),
            created_ts_ms: chrono::Utc::now().timestamp_millis(),
            ..Default::default()
        }),
    })
}

fn topup_amounts_resolve(amount_usd: f64, amount_idr: f64, fx_micro: i64) -> (f64, f64) {
    if amount_idr > 0.0 {
        let idr = amount_idr.round();
        let usd = crate::billing_on_demand::native_to_usd(idr, fx_micro);
        return (idr, usd);
    }
    let usd = amount_usd.max(0.0);
    let idr = crate::billing_on_demand::usd_to_native(usd, fx_micro).round();
    (idr, usd)
}
