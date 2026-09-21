use c35_proto::{BillingHistoryRow, ReqBillingHistory, ResBillingHistory};
use sqlx::{PgPool, Row};

pub async fn billing_history(pool: &PgPool, owner_iid: i64, req: ReqBillingHistory) -> ResBillingHistory {
    let limit = if req.limit <= 0 { 50 } else { req.limit.min(100) };
    let currency = req.currency.trim().to_uppercase();
    if currency.is_empty() {
        return ResBillingHistory { rows: vec![] };
    }

    let topups = if currency == "IDR" {
        sqlx::query(
            r#"
            SELECT amount_idr::float8 AS amount, status, created_ts
            FROM ai.billing_topup_request
            WHERE owner_iid = $1 AND deleted_ts IS NULL AND amount_idr > 0
            ORDER BY created_ts DESC
            LIMIT $2
            "#,
        )
        .bind(owner_iid)
        .bind(limit)
        .fetch_all(pool)
        .await
        .unwrap_or_default()
    } else {
        sqlx::query(
            r#"
            SELECT amount_usd::float8 AS amount, status, created_ts
            FROM ai.billing_topup_request
            WHERE owner_iid = $1 AND deleted_ts IS NULL AND amount_usd > 0
            ORDER BY created_ts DESC
            LIMIT $2
            "#,
        )
        .bind(owner_iid)
        .bind(limit)
        .fetch_all(pool)
        .await
        .unwrap_or_default()
    };

    let usage = sqlx::query(
        r#"
        SELECT d.amount_native::float8 AS amount_native, d.cost_usd::float8 AS cost_usd,
               COALESCE(l.model, '') AS model, d.created_ts
        FROM ai.billing_usage_dedupe d
        LEFT JOIN ai.log l ON l.id = d.log_id
        WHERE d.owner_iid = $1 AND d.currency = $2 AND d.amount_native > 0
        ORDER BY d.created_ts DESC
        LIMIT $3
        "#,
    )
    .bind(owner_iid)
    .bind(&currency)
    .bind(limit)
    .fetch_all(pool)
    .await
    .unwrap_or_default();

    let mut rows = Vec::with_capacity(topups.len() + usage.len());
    for r in topups {
        let status: String = r.get("status");
        let amount: f64 = r.get("amount");
        let ts: chrono::DateTime<chrono::Utc> = r.get("created_ts");
        rows.push(BillingHistoryRow {
            kind: "topup".into(),
            title: format!("Top-up ({status})"),
            amount_usd: if currency == "USD" { amount } else { 0.0 },
            amount_idr: if currency == "IDR" { amount } else { 0.0 },
            status,
            ts_ms: ts.timestamp_millis(),
            currency: currency.clone(),
            amount,
        });
    }
    for r in usage {
        let model: String = r.get("model");
        let amount_native: f64 = r.get("amount_native");
        let cost_usd: f64 = r.get("cost_usd");
        let ts: chrono::DateTime<chrono::Utc> = r.get("created_ts");
        rows.push(BillingHistoryRow {
            kind: "usage".into(),
            title: if model.is_empty() { "AI usage".into() } else { format!("AI usage · {model}") },
            amount_usd: -cost_usd,
            amount_idr: 0.0,
            status: "settled".into(),
            ts_ms: ts.timestamp_millis(),
            currency: currency.clone(),
            amount: -amount_native,
        });
    }
    rows.sort_by(|a, b| b.ts_ms.cmp(&a.ts_ms));
    rows.truncate(limit as usize);
    ResBillingHistory { rows }
}
