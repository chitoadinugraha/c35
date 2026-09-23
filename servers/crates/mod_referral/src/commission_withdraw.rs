use c35_proto::{ReqCommissionWithdraw, ResCommissionWithdraw};
use c35_store::snowflake_id;
use sqlx::{PgPool, Row};

pub fn withdraw_amount(currency: &str, amount_usd: f64, amount_idr: f64) -> Result<(String, f64), String> {
    let cur = if currency.trim().is_empty() {
        if amount_idr > 0.0 {
            "IDR".to_string()
        } else {
            "USD".to_string()
        }
    } else {
        currency.trim().to_uppercase()
    };
    let amount = if cur == "IDR" {
        if amount_idr <= 0.0 {
            return Err("amount_idr required".into());
        }
        amount_idr
    } else if amount_usd <= 0.0 {
        return Err("amount_usd required".into());
    } else {
        amount_usd
    };
    Ok((cur, amount))
}

pub fn normalize_name(name: &str) -> String {
    name.trim()
        .to_lowercase()
        .chars()
        .filter(|c| !c.is_whitespace())
        .collect()
}

pub async fn commission_withdraw(
    pool: &PgPool,
    owner_iid: i64,
    req: ReqCommissionWithdraw,
) -> Result<ResCommissionWithdraw, String> {
    if owner_iid <= 0 {
        return Err("unauthorized".into());
    }
    let (cur, amount) = withdraw_amount(&req.currency, req.amount_usd, req.amount_idr)?;
    let method = req.payout_method.trim().to_lowercase();
    if method != "wallet_credit" && method != "bank_transfer" {
        return Err("payout_method must be wallet_credit or bank_transfer".into());
    }
    let bank_id = req.bank_id.trim();
    let account_number = req.account_number.trim();
    let account_name = req.account_name.trim();
    if method == "bank_transfer" {
        if bank_id.is_empty() || account_number.is_empty() || account_name.is_empty() {
            return Err("bank details required".into());
        }
        let registered: Option<String> = sqlx::query_scalar("SELECT name FROM ai.identity WHERE id = $1")
            .bind(owner_iid)
            .fetch_optional(pool)
            .await
            .map_err(|e| e.to_string())?;
        let registered = registered.unwrap_or_default();
        if registered.trim().is_empty() {
            return Err("registered name required".into());
        }
        if normalize_name(account_name) != normalize_name(&registered) {
            return Err("account name must match registered name".into());
        }
    }
    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;
    let acct_row = sqlx::query(
        r#"
        SELECT id,
               COALESCE(commission_available_usd::FLOAT8, 0) AS commission_available_usd,
               COALESCE(commission_available_idr::FLOAT8, 0) AS commission_available_idr,
               COALESCE(balance_usd::FLOAT8, 0) AS balance_usd,
               COALESCE(balance_idr::FLOAT8, 0) AS balance_idr
        FROM ai.billing_account
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        FOR UPDATE
        "#,
    )
    .bind(owner_iid)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;
    let Some(row) = acct_row else {
        return Err("billing account not found".into());
    };
    let acct_id: i64 = row.get("id");
    let available_usd: f64 = row.get("commission_available_usd");
    let available_idr: f64 = row.get("commission_available_idr");
    let mut balance_usd: f64 = row.get("balance_usd");
    let mut balance_idr: f64 = row.get("balance_idr");
    let available = if cur == "IDR" { available_idr } else { available_usd };
    if amount > available + 0.0001 {
        let _ = tx.rollback().await;
        return Err("insufficient commission balance".into());
    }
    if method == "bank_transfer" {
        let pending: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM ai.commission_withdraw_request WHERE owner_iid = $1 AND status = 'pending'",
        )
        .bind(owner_iid)
        .fetch_one(&mut *tx)
        .await
        .map_err(|e| e.to_string())?;
        if pending > 0 {
            let _ = tx.rollback().await;
            return Err("pending withdraw already exists".into());
        }
    }
    let entry_type = if method == "wallet_credit" { "payout_wallet" } else { "payout_withdraw" };
    let ledger_status = if method == "wallet_credit" { "settled" } else { "available" };
    let ledger_id = snowflake_id();
    let request_id = if method == "bank_transfer" { snowflake_id() } else { 0 };
    let (amount_usd, amount_idr) = if cur == "IDR" { (0.0, amount) } else { (amount, 0.0) };
    let reference_id = if method == "bank_transfer" {
        format!("withdraw:{request_id}")
    } else {
        format!("withdraw:{ledger_id}")
    };
    let meta = serde_json::json!({
        "reference_id": reference_id,
        "source_iid": owner_iid,
        "event_type": "withdraw",
        "currency": cur,
    });
    sqlx::query(
        r#"
        INSERT INTO ai.commission_ledger (id, owner_iid, entry_type, status, amount_usd, amount_idr, meta)
        VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb)
        "#,
    )
    .bind(ledger_id)
    .bind(owner_iid)
    .bind(entry_type)
    .bind(ledger_status)
    .bind(amount_usd)
    .bind(amount_idr)
    .bind(meta)
    .execute(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;
    if method == "bank_transfer" {
        sqlx::query(
            r#"
            INSERT INTO ai.commission_withdraw_request (
                id, owner_iid, amount_usd, amount_idr, currency, payout_method,
                bank_id, account_number, account_name, status
            ) VALUES ($1, $2, $3, $4, $5, 'bank_transfer', $6, $7, $8, 'pending')
            "#,
        )
        .bind(request_id)
        .bind(owner_iid)
        .bind(amount_usd)
        .bind(amount_idr)
        .bind(&cur)
        .bind(bank_id)
        .bind(account_number)
        .bind(account_name)
        .execute(&mut *tx)
        .await
        .map_err(|e| e.to_string())?;
    }
    if cur == "IDR" {
        if method == "wallet_credit" {
            balance_idr += amount;
            sqlx::query(
                r#"
                UPDATE ai.billing_account
                SET commission_available_idr = commission_available_idr - $2,
                    balance_idr = balance_idr + $2, updated_ts = NOW()
                WHERE id = $1
                "#,
            )
            .bind(acct_id)
            .bind(amount)
            .execute(&mut *tx)
            .await
            .map_err(|e| e.to_string())?;
        } else {
            sqlx::query(
                r#"
                UPDATE ai.billing_account
                SET commission_available_idr = commission_available_idr - $2,
                    commission_pending_idr = commission_pending_idr + $2,
                    updated_ts = NOW()
                WHERE id = $1
                "#,
            )
            .bind(acct_id)
            .bind(amount)
            .execute(&mut *tx)
            .await
            .map_err(|e| e.to_string())?;
        }
    } else if method == "wallet_credit" {
        balance_usd += amount;
        sqlx::query(
            r#"
            UPDATE ai.billing_account
            SET commission_available_usd = commission_available_usd - $2,
                balance_usd = balance_usd + $2, updated_ts = NOW()
            WHERE id = $1
            "#,
        )
        .bind(acct_id)
        .bind(amount)
        .execute(&mut *tx)
        .await
        .map_err(|e| e.to_string())?;
    } else {
        sqlx::query(
            r#"
            UPDATE ai.billing_account
            SET commission_available_usd = commission_available_usd - $2,
                commission_pending_usd = commission_pending_usd + $2,
                updated_ts = NOW()
            WHERE id = $1
            "#,
        )
        .bind(acct_id)
        .bind(amount)
        .execute(&mut *tx)
        .await
        .map_err(|e| e.to_string())?;
    }
    tx.commit().await.map_err(|e| e.to_string())?;
    Ok(ResCommissionWithdraw {
        success: true,
        commission_available_usd: if cur == "USD" {
            (available_usd - amount).max(0.0)
        } else {
            available_usd
        },
        new_wallet_balance_usd: balance_usd,
        commission_available_idr: if cur == "IDR" {
            (available_idr - amount).max(0.0)
        } else {
            available_idr
        },
        new_wallet_balance_idr: balance_idr,
        currency: cur,
    })
}
