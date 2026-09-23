use c35_proto::{CommissionLedgerEntry, ReqReferralLedgerList, ResReferralLedgerList};
use sqlx::{PgPool, Row};

pub async fn referral_ledger_list(
    pool: &PgPool,
    owner_iid: i64,
    req: ReqReferralLedgerList,
) -> ResReferralLedgerList {
    let limit = if req.limit > 0 && req.limit <= 200 { req.limit } else { 50 };
    let rows = sqlx::query(
        r#"
        SELECT id, entry_type,
               COALESCE(amount_usd::FLOAT8, 0) AS amount_usd,
               COALESCE(amount_idr::FLOAT8, 0) AS amount_idr,
               status, meta, created_ts
        FROM ai.commission_ledger
        WHERE owner_iid = $1
        ORDER BY created_ts DESC
        LIMIT $2
        "#,
    )
    .bind(owner_iid)
    .bind(limit)
    .fetch_all(pool)
    .await
    .unwrap_or_default();
    ResReferralLedgerList {
        items: rows.into_iter().map(ledger_entry_from_row).collect(),
    }
}

fn ledger_entry_from_row(r: sqlx::postgres::PgRow) -> CommissionLedgerEntry {
    let meta: serde_json::Value = r.try_get("meta").unwrap_or(serde_json::json!({}));
    let currency = meta
        .get("currency")
        .and_then(|v| v.as_str())
        .unwrap_or_else(|| {
            if r.get::<f64, _>("amount_idr") > 0.0 {
                "IDR"
            } else {
                "USD"
            }
        });
    let created: chrono::DateTime<chrono::Utc> = r.get("created_ts");
    CommissionLedgerEntry {
        id: r.get("id"),
        entry_type: r.get("entry_type"),
        amount_usd: r.get("amount_usd"),
        amount_idr: r.get("amount_idr"),
        currency: currency.to_string(),
        status: r.get("status"),
        source_iid: meta.get("source_iid").and_then(|v| v.as_i64()).unwrap_or(0),
        event_type: meta
            .get("event_type")
            .and_then(|v| v.as_str())
            .unwrap_or_default()
            .to_string(),
        reference_id: meta
            .get("reference_id")
            .and_then(|v| v.as_str())
            .unwrap_or_default()
            .to_string(),
        created_ts_ms: created.timestamp_millis(),
    }
}
