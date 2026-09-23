use c35_proto::{
    BillingReceiveAccount, ReqBillingReceiveAccountList, ReqBillingReceiveAccountPut,
    ResBillingReceiveAccountList, ResBillingReceiveAccountPut,
};
use c35_store::snowflake_id;
use sqlx::{PgPool, Row};

use crate::billing_finance::{finance_access, FinanceError};

#[derive(Clone, Debug)]
pub struct ReceiveAccountRow {
    pub bank_id: String,
    pub account_number: String,
    pub account_name: String,
}

pub async fn receive_account_default(pool: &PgPool, currency: &str) -> Result<ReceiveAccountRow, String> {
    let cur = if currency.trim().is_empty() {
        "IDR".to_string()
    } else {
        currency.trim().to_uppercase()
    };
    let row = sqlx::query(
        r#"
        SELECT bank_id, account_number, account_name
        FROM ai.billing_receive_account
        WHERE deleted_ts IS NULL AND is_active = TRUE AND currency = $1
        ORDER BY is_default DESC, updated_ts DESC
        LIMIT 1
        "#,
    )
    .bind(&cur)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    if let Some(r) = row {
        return Ok(ReceiveAccountRow {
            bank_id: r.get("bank_id"),
            account_number: r.get("account_number"),
            account_name: r.get("account_name"),
        });
    }
    Ok(ReceiveAccountRow {
        bank_id: "BCA".into(),
        account_number: "0113543750".into(),
        account_name: "PT Percepatan Akhir Semesta".into(),
    })
}

pub async fn receive_account_list(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqBillingReceiveAccountList,
) -> Result<ResBillingReceiveAccountList, FinanceError> {
    if !req.active_only {
        finance_access(pool, viewer_iid).await?;
    } else if viewer_iid <= 0 {
        return Err(FinanceError::forbidden());
    }
    let currency = req.currency.trim().to_uppercase();
    let rows = if req.active_only {
        if currency.is_empty() {
            sqlx::query(
                r#"
                SELECT id, bank_id, account_number, account_name, currency, is_active, is_default,
                       label, created_by_iid, meta, created_ts, updated_ts
                FROM ai.billing_receive_account
                WHERE deleted_ts IS NULL AND is_active = TRUE
                ORDER BY currency, is_default DESC, updated_ts DESC
                "#,
            )
            .fetch_all(pool)
            .await
        } else {
            sqlx::query(
                r#"
                SELECT id, bank_id, account_number, account_name, currency, is_active, is_default,
                       label, created_by_iid, meta, created_ts, updated_ts
                FROM ai.billing_receive_account
                WHERE deleted_ts IS NULL AND is_active = TRUE AND currency = $1
                ORDER BY is_default DESC, updated_ts DESC
                "#,
            )
            .bind(&currency)
            .fetch_all(pool)
            .await
        }
    } else if currency.is_empty() {
        sqlx::query(
            r#"
            SELECT id, bank_id, account_number, account_name, currency, is_active, is_default,
                   label, created_by_iid, meta, created_ts, updated_ts
            FROM ai.billing_receive_account
            WHERE deleted_ts IS NULL
            ORDER BY currency, is_default DESC, updated_ts DESC
            "#,
        )
        .fetch_all(pool)
        .await
    } else {
        sqlx::query(
            r#"
            SELECT id, bank_id, account_number, account_name, currency, is_active, is_default,
                   label, created_by_iid, meta, created_ts, updated_ts
            FROM ai.billing_receive_account
            WHERE deleted_ts IS NULL AND currency = $1
            ORDER BY is_default DESC, updated_ts DESC
            "#,
        )
        .bind(&currency)
        .fetch_all(pool)
        .await
    }
    .map_err(|e| FinanceError::bad(e.to_string()))?;
    Ok(ResBillingReceiveAccountList {
        accounts: rows.into_iter().map(receive_account_from_row).collect(),
    })
}

pub async fn receive_account_put(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqBillingReceiveAccountPut,
) -> Result<ResBillingReceiveAccountPut, FinanceError> {
    crate::billing_finance::receive_account_put_access(pool, viewer_iid).await?;
    let doc = req.account.unwrap_or_default();
    let bank_id = doc.bank_id.trim();
    let account_number = doc.account_number.trim();
    let account_name = doc.account_name.trim();
    if bank_id.is_empty() || account_number.is_empty() || account_name.is_empty() {
        return Err(FinanceError::bad("bank_id, account_number, account_name required"));
    }
    let currency = if doc.currency.trim().is_empty() {
        "IDR".into()
    } else {
        doc.currency.trim().to_uppercase()
    };
    let id = if doc.id > 0 { doc.id } else { snowflake_id() };
    let meta: serde_json::Value = if doc.meta_json.trim().is_empty() {
        serde_json::json!({})
    } else {
        serde_json::from_str(&doc.meta_json).unwrap_or(serde_json::json!({}))
    };
    if doc.is_default {
        let _ = sqlx::query(
            "UPDATE ai.billing_receive_account SET is_default = FALSE, updated_ts = NOW() WHERE currency = $1 AND deleted_ts IS NULL",
        )
        .bind(&currency)
        .execute(pool)
        .await;
    }
    sqlx::query(
        r#"
        INSERT INTO ai.billing_receive_account (
            id, bank_id, account_number, account_name, currency, is_active, is_default,
            label, created_by_iid, meta
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10::jsonb)
        ON CONFLICT (id) DO UPDATE SET
            bank_id = EXCLUDED.bank_id,
            account_number = EXCLUDED.account_number,
            account_name = EXCLUDED.account_name,
            currency = EXCLUDED.currency,
            is_active = EXCLUDED.is_active,
            is_default = EXCLUDED.is_default,
            label = EXCLUDED.label,
            meta = EXCLUDED.meta,
            updated_ts = NOW()
        "#,
    )
    .bind(id)
    .bind(bank_id)
    .bind(account_number)
    .bind(account_name)
    .bind(&currency)
    .bind(doc.is_active)
    .bind(doc.is_default)
    .bind(doc.label.trim())
    .bind(viewer_iid)
    .bind(meta)
    .execute(pool)
    .await
    .map_err(|e| FinanceError::bad(e.to_string()))?;
    let row = sqlx::query(
        r#"
        SELECT id, bank_id, account_number, account_name, currency, is_active, is_default,
               label, created_by_iid, meta, created_ts, updated_ts
        FROM ai.billing_receive_account WHERE id = $1
        "#,
    )
    .bind(id)
    .fetch_one(pool)
    .await
    .map_err(|e| FinanceError::bad(e.to_string()))?;
    Ok(ResBillingReceiveAccountPut {
        account: Some(receive_account_from_row(row)),
    })
}

fn receive_account_from_row(r: sqlx::postgres::PgRow) -> BillingReceiveAccount {
    let created: chrono::DateTime<chrono::Utc> = r.get("created_ts");
    let updated: chrono::DateTime<chrono::Utc> = r.get("updated_ts");
    let meta: serde_json::Value = r.try_get("meta").unwrap_or(serde_json::json!({}));
    BillingReceiveAccount {
        id: r.get("id"),
        bank_id: r.get("bank_id"),
        account_number: r.get("account_number"),
        account_name: r.get("account_name"),
        currency: r.get("currency"),
        is_active: r.get("is_active"),
        is_default: r.get("is_default"),
        label: r.get("label"),
        created_by_iid: r.try_get("created_by_iid").unwrap_or(0),
        meta_json: meta.to_string(),
        created_ts_ms: created.timestamp_millis(),
        updated_ts_ms: updated.timestamp_millis(),
    }
}

