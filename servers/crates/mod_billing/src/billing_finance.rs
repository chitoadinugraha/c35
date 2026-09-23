use c35_proto::{
    BillingTopupQueueItem, CommissionWithdrawQueueItem, ReqBillingTopupList, ReqBillingTopupReview,
    ReqCommissionWithdrawList, ReqCommissionWithdrawReview, ResBillingTopupList, ResBillingTopupReview,
    ResCommissionWithdrawList, ResCommissionWithdrawReview,
};
use sqlx::{PgPool, Row};
use std::collections::HashSet;

use crate::billing_topup::topup_credit_and_accrue;

#[derive(Debug)]
pub struct FinanceError {
    pub status_code: i32,
    pub message: String,
}

impl FinanceError {
    pub fn bad(msg: impl Into<String>) -> Self {
        Self {
            status_code: 400,
            message: msg.into(),
        }
    }

    pub fn forbidden() -> Self {
        Self {
            status_code: 403,
            message: "forbidden".into(),
        }
    }
}

fn global_roles(meta: &serde_json::Value) -> HashSet<String> {
    meta.get("global_roles")
        .and_then(|v| v.as_array())
        .map(|a| {
            a.iter()
                .filter_map(|x| x.as_str().map(|s| s.to_lowercase()))
                .collect()
        })
        .unwrap_or_default()
}

async fn viewer_meta(pool: &PgPool, viewer_iid: i64) -> Result<serde_json::Value, FinanceError> {
    if viewer_iid <= 0 {
        return Err(FinanceError::forbidden());
    }
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL")
        .bind(viewer_iid)
        .fetch_optional(pool)
        .await
        .map_err(|e| FinanceError::bad(e.to_string()))?;
    Ok(row.map(|r| r.get("meta")).unwrap_or(serde_json::json!({})))
}

pub async fn finance_access(pool: &PgPool, viewer_iid: i64) -> Result<(), FinanceError> {
    let meta = viewer_meta(pool, viewer_iid).await?;
    if meta.get("is_root").and_then(|v| v.as_bool()).unwrap_or(false) {
        return Ok(());
    }
    let roles = global_roles(&meta);
    if roles
        .iter()
        .any(|r| matches!(r.as_str(), "partner" | "finance" | "director" | "marketing" | "root"))
    {
        Ok(())
    } else {
        Err(FinanceError::forbidden())
    }
}

pub async fn finance_review_access(pool: &PgPool, viewer_iid: i64) -> Result<(), FinanceError> {
    let meta = viewer_meta(pool, viewer_iid).await?;
    if meta.get("is_root").and_then(|v| v.as_bool()).unwrap_or(false) {
        return Ok(());
    }
    if global_roles(&meta).contains("finance") {
        Ok(())
    } else {
        Err(FinanceError::forbidden())
    }
}

pub async fn receive_account_put_access(pool: &PgPool, viewer_iid: i64) -> Result<(), FinanceError> {
    let meta = viewer_meta(pool, viewer_iid).await?;
    if meta.get("is_root").and_then(|v| v.as_bool()).unwrap_or(false) {
        return Ok(());
    }
    let roles = global_roles(&meta);
    if roles.iter().any(|r| matches!(r.as_str(), "finance" | "director")) {
        Ok(())
    } else {
        Err(FinanceError::forbidden())
    }
}

fn ts_ms(dt: Option<chrono::DateTime<chrono::Utc>>) -> i64 {
    dt.map(|t| t.timestamp_millis()).unwrap_or(0)
}

const TOPUP_LIST_SELECT: &str = r#"
SELECT t.id, t.owner_iid,
       COALESCE(t.amount_idr::FLOAT8, 0) AS amount_idr,
       COALESCE(t.amount_usd::FLOAT8, 0) AS amount_usd,
       COALESCE(t.proof_url, '') AS proof_url,
       t.status, t.created_ts,
       COALESCE(u.name, '') AS user_name,
       COALESCE(u.pic, '') AS user_pic,
       COALESCE(u.alien_id, '') AS user_handle,
       COALESCE(t.reject_reason, '') AS reject_reason,
       COALESCE(t.reviewed_by_iid, 0) AS reviewed_by_iid,
       COALESCE(rev.name, '') AS reviewer_name,
       COALESCE(rev.pic, '') AS reviewer_pic
FROM ai.billing_topup_request t
LEFT JOIN ai.identity u ON u.id = t.owner_iid
LEFT JOIN ai.identity rev ON rev.id = t.reviewed_by_iid
"#;

pub async fn billing_topup_list(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqBillingTopupList,
) -> Result<ResBillingTopupList, FinanceError> {
    finance_access(pool, viewer_iid).await?;
    let lim = req.limit.clamp(1, 200) as i64;
    let status = req.status.trim().to_lowercase();
    let rows = match status.as_str() {
        "history" => {
            sqlx::query(&format!(
                "{TOPUP_LIST_SELECT} WHERE t.provider = 'manual' AND t.status IN ('settled', 'rejected', 'expired', 'failed') AND t.deleted_ts IS NULL ORDER BY t.created_ts DESC LIMIT $1"
            ))
            .bind(lim)
            .fetch_all(pool)
            .await
        }
        "all" => {
            sqlx::query(&format!(
                "{TOPUP_LIST_SELECT} WHERE t.provider = 'manual' AND t.deleted_ts IS NULL ORDER BY t.created_ts DESC LIMIT $1"
            ))
            .bind(lim)
            .fetch_all(pool)
            .await
        }
        _ => {
            sqlx::query(&format!(
                "{TOPUP_LIST_SELECT} WHERE t.provider = 'manual' AND t.status IN ('pending', 'pending_review') AND t.deleted_ts IS NULL ORDER BY t.created_ts DESC LIMIT $1"
            ))
            .bind(lim)
            .fetch_all(pool)
            .await
        }
    }
    .map_err(|e| FinanceError::bad(e.to_string()))?;
    Ok(ResBillingTopupList {
        requests: rows
            .into_iter()
            .map(|r| BillingTopupQueueItem {
                request_id: r.get("id"),
                owner_iid: r.get("owner_iid"),
                amount_idr: r.get("amount_idr"),
                amount_usd: r.get("amount_usd"),
                proof_url: r.get("proof_url"),
                status: r.get("status"),
                created_ts_ms: ts_ms(r.get("created_ts")),
                user_name: r.get("user_name"),
                user_pic: r.get("user_pic"),
                user_handle: r.get("user_handle"),
                reject_reason: r.get("reject_reason"),
                reviewed_by_iid: r.get("reviewed_by_iid"),
                reviewer_name: r.get("reviewer_name"),
                reviewer_pic: r.get("reviewer_pic"),
            })
            .collect(),
    })
}

pub async fn billing_topup_review(
    pool: &PgPool,
    reviewer_iid: i64,
    req: ReqBillingTopupReview,
) -> Result<ResBillingTopupReview, FinanceError> {
    finance_review_access(pool, reviewer_iid).await?;
    let action = req.action.trim().to_lowercase();
    let request_id = req.request_id;
    if request_id <= 0 {
        return Err(FinanceError::bad("request_id required"));
    }
    if action == "reject" {
        let n = sqlx::query(
            r#"
            UPDATE ai.billing_topup_request
            SET status = 'rejected', reject_reason = $2, reviewed_by_iid = $3, updated_ts = NOW()
            WHERE id = $1 AND provider = 'manual' AND status IN ('pending', 'pending_review')
            "#,
        )
        .bind(request_id)
        .bind(req.reason.trim())
        .bind(reviewer_iid)
        .execute(pool)
        .await
        .map_err(|e| FinanceError::bad(e.to_string()))?
        .rows_affected();
        if n == 0 {
            return Err(FinanceError::bad("request not found"));
        }
        return Ok(ResBillingTopupReview {});
    }
    if action != "approve" {
        return Err(FinanceError::bad("invalid action"));
    }
    let mut tx = pool.begin().await.map_err(|e| FinanceError::bad(e.to_string()))?;
    let row = sqlx::query(
        r#"
        SELECT billing_account_id, owner_iid,
               COALESCE(amount_idr::FLOAT8, 0) AS amount_idr,
               COALESCE(amount_usd::FLOAT8, 0) AS amount_usd,
               status, external_order_id
        FROM ai.billing_topup_request
        WHERE id = $1 AND provider = 'manual'
        FOR UPDATE
        "#,
    )
    .bind(request_id)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|e| FinanceError::bad(e.to_string()))?;
    let Some(row) = row else {
        return Err(FinanceError::bad("request not found"));
    };
    let status: String = row.get("status");
    if status != "pending" && status != "pending_review" {
        return Err(FinanceError::bad("request is not pending"));
    }
    let account_id: i64 = row.get("billing_account_id");
    let owner_iid: i64 = row.get("owner_iid");
    let amount_idr: f64 = row.get("amount_idr");
    let amount_usd: f64 = row.get("amount_usd");
    let order_id: String = row.get("external_order_id");
    let credit_amount = if amount_idr > 0.0 { amount_idr } else { amount_usd };
    let currency = if amount_idr > 0.0 { "IDR" } else { "USD" };
    topup_credit_and_accrue(&mut tx, account_id, credit_amount, currency, &order_id)
        .await
        .map_err(|e| FinanceError::bad(e))?;
    sqlx::query(
        r#"
        UPDATE ai.billing_topup_request
        SET status = 'settled', settled_ts = NOW(), reviewed_by_iid = $2, updated_ts = NOW()
        WHERE id = $1
        "#,
    )
    .bind(request_id)
    .bind(reviewer_iid)
    .execute(&mut *tx)
    .await
    .map_err(|e| FinanceError::bad(e.to_string()))?;
    tx.commit().await.map_err(|e| FinanceError::bad(e.to_string()))?;
    crate::billing_push::billing_notify_owner(pool, None, owner_iid, None).await;
    Ok(ResBillingTopupReview {})
}

const WITHDRAW_LIST_SELECT: &str = r#"
SELECT r.id, r.owner_iid, COALESCE(r.amount_usd::FLOAT8, 0) AS amount_usd,
       COALESCE(r.amount_idr::FLOAT8, 0) AS amount_idr,
       r.currency, r.payout_method, r.bank_id, r.account_number, r.account_name,
       COALESCE(r.note, '') AS note, COALESCE(r.transfer_proof_url, '') AS transfer_proof_url,
       r.status, r.created_ts,
       COALESCE(u.name, '') AS user_name, COALESCE(u.pic, '') AS user_pic,
       COALESCE(r.decline_reason, '') AS decline_reason,
       COALESCE(r.reviewed_by_iid, 0) AS reviewed_by_iid,
       COALESCE(rev.name, '') AS reviewer_name, COALESCE(rev.pic, '') AS reviewer_pic
FROM ai.commission_withdraw_request r
JOIN ai.identity u ON u.id = r.owner_iid
LEFT JOIN ai.identity rev ON rev.id = r.reviewed_by_iid
"#;

fn bank_short_name(bank_id: &str) -> String {
    match bank_id.trim().to_lowercase().as_str() {
        "bca" => "BCA".into(),
        "mandiri" => "Mandiri".into(),
        "bni" => "BNI".into(),
        "bri" => "BRI".into(),
        "bsi" => "BSI".into(),
        other => other.to_uppercase(),
    }
}

pub async fn commission_withdraw_list(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqCommissionWithdrawList,
) -> Result<ResCommissionWithdrawList, FinanceError> {
    finance_access(pool, viewer_iid).await?;
    let lim = req.limit.clamp(1, 200) as i64;
    let status = req.status.trim().to_lowercase();
    let sql = match status.as_str() {
        "history" => format!(
            "{WITHDRAW_LIST_SELECT} WHERE r.status IN ('approved', 'declined', 'cancelled') ORDER BY r.created_ts DESC LIMIT $1"
        ),
        "all" => format!("{WITHDRAW_LIST_SELECT} ORDER BY r.created_ts DESC LIMIT $1"),
        _ => format!("{WITHDRAW_LIST_SELECT} WHERE r.status = 'pending' ORDER BY r.created_ts DESC LIMIT $1"),
    };
    let rows = sqlx::query(&sql)
        .bind(lim)
        .fetch_all(pool)
        .await
        .map_err(|e| FinanceError::bad(e.to_string()))?;
    Ok(ResCommissionWithdrawList {
        requests: rows
            .into_iter()
            .map(|r| {
                let bank_id: String = r.get("bank_id");
                CommissionWithdrawQueueItem {
                    request_id: r.get("id"),
                    owner_iid: r.get("owner_iid"),
                    amount_usd: r.get("amount_usd"),
                    amount_idr: r.get("amount_idr"),
                    currency: r.get("currency"),
                    payout_method: r.get("payout_method"),
                    bank_id: bank_id.clone(),
                    bank_short_name: bank_short_name(&bank_id),
                    account_number: r.get("account_number"),
                    account_name: r.get("account_name"),
                    note: r.get("note"),
                    transfer_proof_url: r.get("transfer_proof_url"),
                    status: r.get("status"),
                    created_ts_ms: ts_ms(r.get("created_ts")),
                    user_name: r.get("user_name"),
                    user_pic: r.get("user_pic"),
                    decline_reason: r.get("decline_reason"),
                    reviewed_by_iid: r.get("reviewed_by_iid"),
                    reviewer_name: r.get("reviewer_name"),
                    reviewer_pic: r.get("reviewer_pic"),
                }
            })
            .collect(),
    })
}

pub async fn commission_withdraw_review(
    pool: &PgPool,
    reviewer_iid: i64,
    req: ReqCommissionWithdrawReview,
) -> Result<ResCommissionWithdrawReview, FinanceError> {
    finance_review_access(pool, reviewer_iid).await?;
    let action = req.action.trim().to_lowercase();
    let request_id = req.request_id;
    if request_id <= 0 {
        return Err(FinanceError::bad("request_id required"));
    }
    if action == "decline" {
        let mut tx = pool.begin().await.map_err(|e| FinanceError::bad(e.to_string()))?;
        let row = sqlx::query(
            r#"
            UPDATE ai.commission_withdraw_request
            SET status = 'declined', reviewed_by_iid = $2, reviewed_ts = NOW(),
                decline_reason = $3, updated_ts = NOW()
            WHERE id = $1 AND status = 'pending'
            RETURNING owner_iid, currency, COALESCE(amount_usd::FLOAT8, 0) AS amount_usd,
                      COALESCE(amount_idr::FLOAT8, 0) AS amount_idr
            "#,
        )
        .bind(request_id)
        .bind(reviewer_iid)
        .bind(req.reason.trim())
        .fetch_optional(&mut *tx)
        .await
        .map_err(|e| FinanceError::bad(e.to_string()))?;
        let Some(row) = row else {
            return Err(FinanceError::bad("request not found"));
        };
        let owner_iid: i64 = row.get("owner_iid");
        let currency: String = row.get("currency");
        let amount_usd: f64 = row.get("amount_usd");
        let amount_idr: f64 = row.get("amount_idr");
        if currency.eq_ignore_ascii_case("IDR") {
            sqlx::query(
                r#"
                UPDATE ai.billing_account
                SET commission_available_idr = commission_available_idr + $2,
                    commission_pending_idr = GREATEST(commission_pending_idr - $2, 0),
                    updated_ts = NOW()
                WHERE owner_iid = $1
                "#,
            )
            .bind(owner_iid)
            .bind(amount_idr)
            .execute(&mut *tx)
            .await
            .map_err(|e| FinanceError::bad(e.to_string()))?;
        } else {
            sqlx::query(
                r#"
                UPDATE ai.billing_account
                SET commission_available_usd = commission_available_usd + $2,
                    commission_pending_usd = GREATEST(commission_pending_usd - $2, 0),
                    updated_ts = NOW()
                WHERE owner_iid = $1
                "#,
            )
            .bind(owner_iid)
            .bind(amount_usd)
            .execute(&mut *tx)
            .await
            .map_err(|e| FinanceError::bad(e.to_string()))?;
        }
        sqlx::query(
            r#"
            UPDATE ai.commission_ledger
            SET status = 'cancelled', updated_ts = NOW()
            WHERE owner_iid = $1 AND entry_type = 'payout_withdraw'
              AND meta->>'reference_id' = $2 AND status = 'available'
            "#,
        )
        .bind(owner_iid)
        .bind(format!("withdraw:{request_id}"))
        .execute(&mut *tx)
        .await
        .map_err(|e| FinanceError::bad(e.to_string()))?;
        tx.commit().await.map_err(|e| FinanceError::bad(e.to_string()))?;
        return Ok(ResCommissionWithdrawReview {});
    }
    if action != "approve" {
        return Err(FinanceError::bad("invalid action"));
    }
    let proof = req.transfer_proof_url.trim();
    if proof.is_empty() {
        return Err(FinanceError::bad("transfer proof required"));
    }
    let mut tx = pool.begin().await.map_err(|e| FinanceError::bad(e.to_string()))?;
    let row = sqlx::query(
        r#"
        SELECT owner_iid, currency, COALESCE(amount_usd::FLOAT8, 0) AS amount_usd,
               COALESCE(amount_idr::FLOAT8, 0) AS amount_idr, status
        FROM ai.commission_withdraw_request
        WHERE id = $1
        FOR UPDATE
        "#,
    )
    .bind(request_id)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|e| FinanceError::bad(e.to_string()))?;
    let Some(row) = row else {
        return Err(FinanceError::bad("request not found"));
    };
    let status: String = row.get("status");
    if status != "pending" {
        return Err(FinanceError::bad("request is not pending"));
    }
    let owner_iid: i64 = row.get("owner_iid");
    let currency: String = row.get("currency");
    let amount_usd: f64 = row.get("amount_usd");
    let amount_idr: f64 = row.get("amount_idr");
    if currency.eq_ignore_ascii_case("IDR") {
        sqlx::query(
            r#"
            UPDATE ai.billing_account
            SET commission_pending_idr = GREATEST(commission_pending_idr - $2, 0), updated_ts = NOW()
            WHERE owner_iid = $1
            "#,
        )
        .bind(owner_iid)
        .bind(amount_idr)
        .execute(&mut *tx)
        .await
        .map_err(|e| FinanceError::bad(e.to_string()))?;
    } else {
        sqlx::query(
            r#"
            UPDATE ai.billing_account
            SET commission_pending_usd = GREATEST(commission_pending_usd - $2, 0), updated_ts = NOW()
            WHERE owner_iid = $1
            "#,
        )
        .bind(owner_iid)
        .bind(amount_usd)
        .execute(&mut *tx)
        .await
        .map_err(|e| FinanceError::bad(e.to_string()))?;
    }
    sqlx::query(
        r#"
        UPDATE ai.commission_ledger
        SET status = 'settled', updated_ts = NOW()
        WHERE owner_iid = $1 AND entry_type = 'payout_withdraw'
          AND meta->>'reference_id' = $2 AND status = 'available'
        "#,
    )
    .bind(owner_iid)
    .bind(format!("withdraw:{request_id}"))
    .execute(&mut *tx)
    .await
    .map_err(|e| FinanceError::bad(e.to_string()))?;
    sqlx::query(
        r#"
        UPDATE ai.commission_withdraw_request
        SET status = 'approved', transfer_proof_url = $2, reviewed_by_iid = $3,
            reviewed_ts = NOW(), updated_ts = NOW()
        WHERE id = $1
        "#,
    )
    .bind(request_id)
    .bind(proof)
    .bind(reviewer_iid)
    .execute(&mut *tx)
    .await
    .map_err(|e| FinanceError::bad(e.to_string()))?;
    tx.commit().await.map_err(|e| FinanceError::bad(e.to_string()))?;
    crate::billing_push::billing_notify_owner(pool, None, owner_iid, None).await;
    Ok(ResCommissionWithdrawReview {})
}
