//! Domain registrar purchase: debit the quote currency, refund if register fails.

use sqlx::{PgPool, Row};

pub struct DomainCharge {
    pub order_id: i64,
    pub currency: String,
    pub amount: f64,
}

fn currency_code_ok(currency: &str) -> bool {
    currency.len() == 3 && currency.bytes().all(|b| b.is_ascii_uppercase())
}

/// `charged` and `refunded` may enter refund (refunded is already done).
/// `registered` must not be credited again.
pub fn domain_purchase_refund_allowed(status: &str) -> Result<(), &'static str> {
    match status {
        "charged" | "refunded" => Ok(()),
        "registered" => Err("already_registered"),
        _ => Err("bad_status"),
    }
}

pub async fn domain_purchase_debit(
    pool: &PgPool,
    order_id: i64,
    owner_iid: i64,
    site_iid: i64,
    hostname: &str,
    currency: &str,
    amount: f64,
) -> Result<DomainCharge, String> {
    if !(amount.is_finite() && amount > 0.0) {
        return Err("bad_amount".into());
    }
    if !currency_code_ok(currency) {
        return Err("bad_currency".into());
    }

    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;

    let updated = sqlx::query(
        r#"
        UPDATE ai.billing_wallet
        SET balance = balance - $3, updated_ts = NOW()
        WHERE owner_iid = $1
          AND currency = $2
          AND deleted_ts IS NULL
          AND balance >= $3
        "#,
    )
    .bind(owner_iid)
    .bind(currency)
    .bind(amount)
    .execute(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;

    if updated.rows_affected() == 0 {
        return Err("insufficient_balance".into());
    }

    sqlx::query(
        r#"
        INSERT INTO site.domain_order (
            id, site_iid, owner_iid, hostname, currency, amount, status
        ) VALUES ($1, $2, $3, $4, $5, $6, 'charged')
        "#,
    )
    .bind(order_id)
    .bind(site_iid)
    .bind(owner_iid)
    .bind(hostname)
    .bind(currency)
    .bind(amount)
    .execute(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;

    tx.commit().await.map_err(|e| e.to_string())?;

    Ok(DomainCharge {
        order_id,
        currency: currency.to_string(),
        amount,
    })
}

pub async fn domain_purchase_refund(pool: &PgPool, order_id: i64) -> Result<(), String> {
    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;

    let row = sqlx::query(
        r#"
        SELECT status, owner_iid, currency, amount::float8 AS amount
        FROM site.domain_order
        WHERE id = $1
        FOR UPDATE
        "#,
    )
    .bind(order_id)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;

    let Some(row) = row else {
        return Err("not_found".into());
    };

    let status: String = row.try_get("status").map_err(|e| e.to_string())?;
    domain_purchase_refund_allowed(&status).map_err(|e| e.to_string())?;
    if status == "refunded" {
        tx.commit().await.map_err(|e| e.to_string())?;
        return Ok(());
    }

    let owner_iid: i64 = row.try_get("owner_iid").map_err(|e| e.to_string())?;
    let currency: String = row.try_get("currency").map_err(|e| e.to_string())?;
    let currency = currency.trim().to_string();
    let amount: f64 = row.try_get("amount").map_err(|e| e.to_string())?;

    let credited = sqlx::query(
        r#"
        UPDATE ai.billing_wallet
        SET balance = balance + $3, updated_ts = NOW()
        WHERE owner_iid = $1
          AND currency = $2
          AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .bind(&currency)
    .bind(amount)
    .execute(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;

    if credited.rows_affected() == 0 {
        return Err("wallet_missing".into());
    }

    sqlx::query(
        r#"
        UPDATE site.domain_order
        SET status = 'refunded', updated_ts = NOW()
        WHERE id = $1 AND status = 'charged'
        "#,
    )
    .bind(order_id)
    .execute(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;

    tx.commit().await.map_err(|e| e.to_string())?;
    Ok(())
}

pub async fn domain_purchase_mark(
    pool: &PgPool,
    order_id: i64,
    status: &str,
    cf_zone_id: &str,
    error: &str,
) -> Result<(), String> {
    let updated = sqlx::query(
        r#"
        UPDATE site.domain_order
        SET status = $2, cf_zone_id = $3, error = $4, updated_ts = NOW()
        WHERE id = $1
        "#,
    )
    .bind(order_id)
    .bind(status)
    .bind(cf_zone_id)
    .bind(error)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;

    if updated.rows_affected() == 0 {
        return Err("not_found".into());
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    #[test]
    fn domain_purchase_refund_allowed() {
        assert!(super::domain_purchase_refund_allowed("charged").is_ok());
        assert!(super::domain_purchase_refund_allowed("refunded").is_ok());
        assert_eq!(
            super::domain_purchase_refund_allowed("registered"),
            Err("already_registered")
        );
        assert_eq!(
            super::domain_purchase_refund_allowed("failed"),
            Err("bad_status")
        );
        assert_eq!(super::domain_purchase_refund_allowed(""), Err("bad_status"));
    }
}
