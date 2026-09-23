use c35_proto::{
    BillingAdminAdjustEntry, BillingAdminAdjustReasonTotal, ReqBillingAdminAdjust,
    ReqBillingAdminAdjustList, ResBillingAdminAdjust, ResBillingAdminAdjustList,
};
use c35_store::snowflake_id;
use sqlx::{PgPool, Postgres, Row, Transaction};

use crate::billing_finance::{billing_admin_adjust_access, FinanceError};
use crate::billing_push::billing_notify_owner;

pub const ADMIN_ADJUST_REASONS: &[&str] = &[
    "promotional",
    "compensation",
    "correction",
    "manual_accrual",
    "commission_clawback",
    "refund",
    "topup_manual",
    "migration",
    "internal_test",
    "withdraw_reversal",
    "other",
];

fn normalize_kind(raw: &str) -> Result<&'static str, FinanceError> {
    match raw.trim().to_lowercase().as_str() {
        "balance" => Ok("balance"),
        "commission" => Ok("commission"),
        _ => Err(FinanceError::bad("kind must be balance or commission")),
    }
}

fn normalize_direction(raw: &str) -> Result<&'static str, FinanceError> {
    match raw.trim().to_lowercase().as_str() {
        "credit" | "+" | "add" => Ok("credit"),
        "debit" | "-" | "remove" => Ok("debit"),
        _ => Err(FinanceError::bad("direction must be credit or debit")),
    }
}

fn normalize_reason(raw: &str) -> Result<&'static str, FinanceError> {
    let reason = raw.trim().to_lowercase();
    ADMIN_ADJUST_REASONS
        .iter()
        .find(|r| **r == reason)
        .copied()
        .ok_or_else(|| FinanceError::bad("invalid reason"))
}

fn resolve_amount(currency: &str, amount_usd: f64, amount_idr: f64) -> Result<(String, f64, f64), FinanceError> {
    let cur = if currency.trim().is_empty() {
        if amount_idr > 0.0 {
            "IDR".to_string()
        } else {
            "USD".to_string()
        }
    } else {
        currency.trim().to_uppercase()
    };
    let (usd, idr) = if cur == "IDR" {
        if amount_idr <= 0.0 {
            return Err(FinanceError::bad("amount_idr must be positive"));
        }
        (0.0, amount_idr)
    } else if amount_usd <= 0.0 {
        return Err(FinanceError::bad("amount_usd must be positive"));
    } else {
        (amount_usd, 0.0)
    };
    Ok((cur, usd, idr))
}

fn signed_amount(direction: &str, usd: f64, idr: f64) -> (f64, f64) {
    if direction == "debit" {
        (-usd, -idr)
    } else {
        (usd, idr)
    }
}

async fn wallet_snapshot(
    tx: &mut Transaction<'_, Postgres>,
    owner_iid: i64,
) -> Result<ResBillingAdminAdjust, FinanceError> {
    let row = sqlx::query(
        r#"
        SELECT COALESCE(balance_usd::FLOAT8, 0) AS balance_usd,
               COALESCE(balance_idr::FLOAT8, 0) AS balance_idr,
               COALESCE(commission_available_usd::FLOAT8, 0) AS commission_available_usd,
               COALESCE(commission_available_idr::FLOAT8, 0) AS commission_available_idr,
               COALESCE(billing_currency, 'IDR') AS billing_currency
        FROM ai.billing_account
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .fetch_optional(&mut **tx)
    .await
    .map_err(|e| FinanceError::bad(e.to_string()))?;
    let Some(row) = row else {
        return Err(FinanceError::bad("billing account not found"));
    };
    Ok(ResBillingAdminAdjust {
        balance_usd: row.get("balance_usd"),
        balance_idr: row.get("balance_idr"),
        commission_available_usd: row.get("commission_available_usd"),
        commission_available_idr: row.get("commission_available_idr"),
        currency: row.get("billing_currency"),
    })
}

pub async fn billing_admin_adjust(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqBillingAdminAdjust,
) -> Result<ResBillingAdminAdjust, FinanceError> {
    billing_admin_adjust_access(pool, viewer_iid).await?;
    let subject = req.subject_uid;
    if subject <= 0 {
        return Err(FinanceError::bad("subject_uid required"));
    }
    let kind = normalize_kind(&req.kind)?;
    let direction = normalize_direction(&req.direction)?;
    let reason = normalize_reason(&req.reason)?;
    let note = req.note.trim();
    if reason == "other" && note.is_empty() {
        return Err(FinanceError::bad("note required when reason is other"));
    }
    let (currency, amount_usd, amount_idr) =
        resolve_amount(&req.currency, req.amount_usd, req.amount_idr)?;
    let (delta_usd, delta_idr) = signed_amount(direction, amount_usd, amount_idr);

    let mut tx = pool.begin().await.map_err(|e| FinanceError::bad(e.to_string()))?;
    let acct = sqlx::query(
        r#"
        SELECT id,
               COALESCE(balance_usd::FLOAT8, 0) AS balance_usd,
               COALESCE(balance_idr::FLOAT8, 0) AS balance_idr,
               COALESCE(commission_available_usd::FLOAT8, 0) AS commission_available_usd,
               COALESCE(commission_available_idr::FLOAT8, 0) AS commission_available_idr,
               COALESCE(commission_earned_usd::FLOAT8, 0) AS commission_earned_usd,
               COALESCE(commission_earned_idr::FLOAT8, 0) AS commission_earned_idr
        FROM ai.billing_account
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        FOR UPDATE
        "#,
    )
    .bind(subject)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|e| FinanceError::bad(e.to_string()))?;
    let Some(acct) = acct else {
        return Err(FinanceError::bad("billing account not found"));
    };
    let account_id: i64 = acct.get("id");
    let balance_usd: f64 = acct.get("balance_usd");
    let balance_idr: f64 = acct.get("balance_idr");
    let commission_available_usd: f64 = acct.get("commission_available_usd");
    let commission_available_idr: f64 = acct.get("commission_available_idr");

    if kind == "balance" {
        let new_usd = balance_usd + delta_usd;
        let new_idr = balance_idr + delta_idr;
        if new_usd < -0.0001 || new_idr < -0.0001 {
            return Err(FinanceError::bad("insufficient balance"));
        }
        sqlx::query(
            "UPDATE ai.billing_account SET balance_usd = $1, balance_idr = $2, updated_ts = NOW() WHERE id = $3",
        )
        .bind(new_usd.max(0.0))
        .bind(new_idr.max(0.0))
        .bind(account_id)
        .execute(&mut *tx)
        .await
        .map_err(|e| FinanceError::bad(e.to_string()))?;
    } else {
        let new_avail_usd = commission_available_usd + delta_usd;
        let new_avail_idr = commission_available_idr + delta_idr;
        if new_avail_usd < -0.0001 || new_avail_idr < -0.0001 {
            return Err(FinanceError::bad("insufficient commission balance"));
        }
        let earned_usd: f64 = acct.get("commission_earned_usd");
        let earned_idr: f64 = acct.get("commission_earned_idr");
        let new_earned_usd = if direction == "credit" {
            earned_usd + amount_usd
        } else {
            earned_usd
        };
        let new_earned_idr = if direction == "credit" {
            earned_idr + amount_idr
        } else {
            earned_idr
        };
        sqlx::query(
            r#"
            UPDATE ai.billing_account
            SET commission_available_usd = $1,
                commission_available_idr = $2,
                commission_earned_usd = $3,
                commission_earned_idr = $4,
                updated_ts = NOW()
            WHERE id = $5
            "#,
        )
        .bind(new_avail_usd.max(0.0))
        .bind(new_avail_idr.max(0.0))
        .bind(new_earned_usd.max(0.0))
        .bind(new_earned_idr.max(0.0))
        .bind(account_id)
        .execute(&mut *tx)
        .await
        .map_err(|e| FinanceError::bad(e.to_string()))?;

        let ledger_id = snowflake_id();
        let reference_id = format!("admin_adjust:{ledger_id}");
        let ledger_meta = serde_json::json!({
            "reference_id": reference_id,
            "source_iid": subject,
            "event_type": "admin_adjust",
            "currency": currency,
            "direction": direction,
            "reason": reason,
            "note": note,
            "adjusted_by_iid": viewer_iid,
        });
        sqlx::query(
            r#"
            INSERT INTO ai.commission_ledger (id, owner_iid, entry_type, status, amount_usd, amount_idr, meta)
            VALUES ($1, $2, 'adjustment', 'active', $3, $4, $5::jsonb)
            "#,
        )
        .bind(ledger_id)
        .bind(subject)
        .bind(delta_usd)
        .bind(delta_idr)
        .bind(ledger_meta)
        .execute(&mut *tx)
        .await
        .map_err(|e| FinanceError::bad(e.to_string()))?;
    }

    let adjust_id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.billing_admin_adjustment (
            id, owner_iid, billing_account_id, kind, amount_usd, amount_idr,
            currency, direction, reason, note, adjusted_by_iid, meta
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12::jsonb)
        "#,
    )
    .bind(adjust_id)
    .bind(subject)
    .bind(account_id)
    .bind(kind)
    .bind(amount_usd)
    .bind(amount_idr)
    .bind(&currency)
    .bind(direction)
    .bind(reason)
    .bind(note)
    .bind(viewer_iid)
    .bind(serde_json::json!({ "adjust_id": adjust_id.to_string() }))
    .execute(&mut *tx)
    .await
    .map_err(|e| FinanceError::bad(e.to_string()))?;

    let out = wallet_snapshot(&mut tx, subject).await?;
    tx.commit().await.map_err(|e| FinanceError::bad(e.to_string()))?;
    billing_notify_owner(pool, None, subject, None).await;
    Ok(out)
}

fn ts_bounds(from_ms: i64, to_ms: i64) -> Option<(chrono::DateTime<chrono::Utc>, chrono::DateTime<chrono::Utc>)> {
    if from_ms <= 0 || to_ms <= 0 || to_ms <= from_ms {
        return None;
    }
    let from = chrono::DateTime::from_timestamp_millis(from_ms)?;
    let to = chrono::DateTime::from_timestamp_millis(to_ms)?;
    Some((from, to))
}

pub async fn billing_admin_adjust_list(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqBillingAdminAdjustList,
) -> Result<ResBillingAdminAdjustList, FinanceError> {
    billing_admin_adjust_access(pool, viewer_iid).await?;
    let limit = if req.limit > 0 && req.limit <= 200 {
        req.limit
    } else {
        50
    };
    let kind = req.kind.trim().to_lowercase();
    let reason = req.reason.trim().to_lowercase();
    let subject = req.subject_uid;
    let bounds = ts_bounds(req.from_ms, req.to_ms);

    let mut sql = String::from(
        r#"
        SELECT a.id, a.owner_iid, a.kind, a.amount_usd::FLOAT8 AS amount_usd,
               a.amount_idr::FLOAT8 AS amount_idr, a.currency, a.direction, a.reason,
               a.note, a.adjusted_by_iid, a.created_ts,
               COALESCE(u.name, '') AS owner_name,
               COALESCE(adj.name, '') AS adjusted_by_name
        FROM ai.billing_admin_adjustment a
        LEFT JOIN ai.identity u ON u.id = a.owner_iid
        LEFT JOIN ai.identity adj ON adj.id = a.adjusted_by_iid
        WHERE 1=1
        "#,
    );
    if subject > 0 {
        sql.push_str(" AND a.owner_iid = $1");
    }
    if !kind.is_empty() {
        sql.push_str(" AND a.kind = $2");
    }
    if !reason.is_empty() {
        sql.push_str(" AND a.reason = $3");
    }
    if bounds.is_some() {
        sql.push_str(" AND a.created_ts >= $4 AND a.created_ts < $5");
    }
    sql.push_str(" ORDER BY a.created_ts DESC LIMIT $6");

    let mut q = sqlx::query(&sql);
    if subject > 0 {
        q = q.bind(subject);
    }
    if !kind.is_empty() {
        q = q.bind(&kind);
    }
    if !reason.is_empty() {
        q = q.bind(&reason);
    }
    if let Some((from, to)) = bounds {
        q = q.bind(from).bind(to);
    }
    q = q.bind(limit);

    let rows = q.fetch_all(pool).await.map_err(|e| FinanceError::bad(e.to_string()))?;
    let items = rows
        .into_iter()
        .map(|r| {
            let created: chrono::DateTime<chrono::Utc> = r.get("created_ts");
            BillingAdminAdjustEntry {
                id: r.get("id"),
                owner_iid: r.get("owner_iid"),
                kind: r.get("kind"),
                amount_usd: r.get("amount_usd"),
                amount_idr: r.get("amount_idr"),
                currency: r.get("currency"),
                direction: r.get("direction"),
                reason: r.get("reason"),
                note: r.get("note"),
                adjusted_by_iid: r.get("adjusted_by_iid"),
                adjusted_by_name: r.get("adjusted_by_name"),
                owner_name: r.get("owner_name"),
                created_ts_ms: created.timestamp_millis(),
            }
        })
        .collect::<Vec<_>>();

    let mut totals_sql = String::from(
        r#"
        SELECT reason,
               COALESCE(SUM(CASE WHEN direction = 'credit' THEN amount_idr ELSE -amount_idr END), 0)::FLOAT8 AS amount_idr,
               COALESCE(SUM(CASE WHEN direction = 'credit' THEN amount_usd ELSE -amount_usd END), 0)::FLOAT8 AS amount_usd,
               COUNT(*)::int AS count
        FROM ai.billing_admin_adjustment
        WHERE 1=1
        "#,
    );
    if subject > 0 {
        totals_sql.push_str(" AND owner_iid = $1");
    }
    if !kind.is_empty() {
        totals_sql.push_str(" AND kind = $2");
    }
    if !reason.is_empty() {
        totals_sql.push_str(" AND reason = $3");
    }
    if bounds.is_some() {
        totals_sql.push_str(" AND created_ts >= $4 AND created_ts < $5");
    }
    totals_sql.push_str(" GROUP BY reason ORDER BY reason");

    let mut tq = sqlx::query(&totals_sql);
    if subject > 0 {
        tq = tq.bind(subject);
    }
    if !kind.is_empty() {
        tq = tq.bind(&kind);
    }
    if !reason.is_empty() {
        tq = tq.bind(&reason);
    }
    if let Some((from, to)) = bounds {
        tq = tq.bind(from).bind(to);
    }
    let total_rows = tq.fetch_all(pool).await.map_err(|e| FinanceError::bad(e.to_string()))?;
    let totals = total_rows
        .into_iter()
        .map(|r| BillingAdminAdjustReasonTotal {
            reason: r.get("reason"),
            amount_idr: r.get("amount_idr"),
            amount_usd: r.get("amount_usd"),
            count: r.get("count"),
        })
        .collect();

    Ok(ResBillingAdminAdjustList { items, totals })
}
