use c35_mod_admin::require_admin;
use c35_proto::{
    ReferralStatPeriod, ReferralUserStatColumn, ReferralUserWalletSnapshot, ReqReferralUserStats,
    ResReferralUserStats,
};
use sqlx::{PgPool, Row};

async fn viewer_is_root_or_director(pool: &PgPool, viewer_iid: i64) -> bool {
    if viewer_iid == 99_000 {
        return true;
    }
    if viewer_iid <= 0 {
        return false;
    }
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL AND is_active = true")
        .bind(viewer_iid)
        .fetch_optional(pool)
        .await
        .ok()
        .flatten();
    let Some(row) = row else {
        return false;
    };
    let meta: serde_json::Value = row.try_get("meta").unwrap_or(serde_json::json!({}));
    if meta
        .get("is_root")
        .and_then(|v| v.as_bool())
        .or_else(|| meta.get("is_root").and_then(|v| v.as_str()).map(|s| s == "true"))
        .unwrap_or(false)
    {
        return true;
    }
    meta.get("global_roles")
        .and_then(|v| v.as_array())
        .map(|a| {
            a.iter().any(|x| {
                matches!(x.as_str(), Some("director") | Some("root"))
            })
        })
        .unwrap_or(false)
}

async fn stats_can_view(pool: &PgPool, viewer_iid: i64, subject_iid: i64) -> bool {
    if viewer_iid <= 0 || subject_iid <= 0 {
        return false;
    }
    if viewer_iid == subject_iid {
        return true;
    }
    if require_admin(pool, viewer_iid).await.is_ok() {
        return true;
    }
    viewer_is_root_or_director(pool, viewer_iid).await
}

fn period_bounds(
    period: &ReferralStatPeriod,
) -> Option<(chrono::DateTime<chrono::Utc>, chrono::DateTime<chrono::Utc>)> {
    if period.from_ms <= 0 || period.to_ms <= 0 || period.to_ms <= period.from_ms {
        return None;
    }
    let from = chrono::DateTime::from_timestamp_millis(period.from_ms)?;
    let to = chrono::DateTime::from_timestamp_millis(period.to_ms)?;
    Some((from, to))
}

async fn referral_count(
    pool: &PgPool,
    iid: i64,
    from: chrono::DateTime<chrono::Utc>,
    to: chrono::DateTime<chrono::Utc>,
) -> i32 {
    sqlx::query_scalar(
        r#"
        SELECT COUNT(*)::bigint FROM ai.identity
        WHERE referred_by_iid = $1 AND kind = 'user' AND deleted_ts IS NULL
          AND created_ts >= $2 AND created_ts < $3
        "#,
    )
    .bind(iid)
    .bind(from)
    .bind(to)
    .fetch_one(pool)
    .await
    .unwrap_or(0) as i32
}

async fn commission_sum(
    pool: &PgPool,
    iid: i64,
    from: chrono::DateTime<chrono::Utc>,
    to: chrono::DateTime<chrono::Utc>,
) -> (f64, f64) {
    let row = sqlx::query(
        r#"
        SELECT COALESCE(SUM(amount_idr::FLOAT8), 0) AS idr,
               COALESCE(SUM(amount_usd::FLOAT8), 0) AS usd
        FROM ai.commission_ledger
        WHERE owner_iid = $1 AND entry_type = 'accrual' AND status <> 'cancelled'
          AND created_ts >= $2 AND created_ts < $3
        "#,
    )
    .bind(iid)
    .bind(from)
    .bind(to)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();
    row.map(|r| (r.get::<f64, _>("idr"), r.get::<f64, _>("usd")))
        .unwrap_or((0.0, 0.0))
}

async fn token_sums(
    pool: &PgPool,
    iid: i64,
    from: chrono::DateTime<chrono::Utc>,
    to: chrono::DateTime<chrono::Utc>,
) -> (i64, i64) {
    let row = sqlx::query(
        r#"
        SELECT COALESCE(SUM(tokens_in + tokens_out), 0)::bigint AS tokens_alien
        FROM ai.chat_msg
        WHERE owner_iid = $1 AND deleted_ts IS NULL
          AND created_ts >= $2 AND created_ts < $3
          AND (tokens_in + tokens_out) > 0
        "#,
    )
    .bind(iid)
    .bind(from)
    .bind(to)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();
    row.map(|r| (r.get::<i64, _>("tokens_alien"), 0_i64))
        .unwrap_or((0, 0))
}

async fn column_for_period(
    pool: &PgPool,
    iid: i64,
    period: &ReferralStatPeriod,
) -> ReferralUserStatColumn {
    let Some((from, to)) = period_bounds(period) else {
        return ReferralUserStatColumn::default();
    };
    let referral_count = referral_count(pool, iid, from, to).await;
    let (commission_idr, commission_usd) = commission_sum(pool, iid, from, to).await;
    let (tokens_alien, tokens_api) = token_sums(pool, iid, from, to).await;
    ReferralUserStatColumn {
        referral_count,
        commission_idr,
        commission_usd,
        tokens_alien,
        tokens_api,
    }
}

async fn subject_auth_contact(pool: &PgPool, subject_iid: i64) -> (String, String) {
    let rows = sqlx::query(
        r#"
        SELECT kind, identifier
        FROM ai.identity_provider
        WHERE identity_iid = $1 AND deleted_ts IS NULL AND kind IN ('google', 'email', 'phone')
        ORDER BY CASE kind WHEN 'google' THEN 0 WHEN 'email' THEN 1 ELSE 2 END
        "#,
    )
    .bind(subject_iid)
    .fetch_all(pool)
    .await
    .unwrap_or_default();
    let mut email = String::new();
    let mut phone = String::new();
    for r in rows {
        let kind: String = r.get("kind");
        let id: String = r.get("identifier");
        if kind == "phone" {
            if phone.is_empty() {
                phone = id.trim().to_string();
            }
            continue;
        }
        if email.is_empty() {
            let lower = id.trim().to_lowercase();
            if lower.contains('@') && !lower.ends_with("@alienai.id") {
                email = lower;
            }
        }
    }
    if email.is_empty() {
        let meta: Option<serde_json::Value> = sqlx::query_scalar(
            "SELECT meta FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL",
        )
        .bind(subject_iid)
        .fetch_optional(pool)
        .await
        .ok()
        .flatten();
        if let Some(m) = meta {
            if let Some(e) = m.get("email").and_then(|v| v.as_str()) {
                let lower = e.trim().to_lowercase();
                if lower.contains('@') && !lower.ends_with("@alienai.id") {
                    email = lower;
                }
            }
        }
    }
    (email, phone)
}

async fn wallet_snapshot(pool: &PgPool, owner_iid: i64) -> Option<ReferralUserWalletSnapshot> {
    let row = sqlx::query(
        r#"
        SELECT COALESCE(balance_usd::FLOAT8, 0) AS balance_usd,
               COALESCE(balance_idr::FLOAT8, 0) AS balance_idr,
               COALESCE(commission_available_usd::FLOAT8, 0) AS commission_available_usd,
               COALESCE(commission_available_idr::FLOAT8, 0) AS commission_available_idr,
               COALESCE(billing_currency, 'IDR') AS billing_currency
        FROM ai.billing_account
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten()?;
    Some(ReferralUserWalletSnapshot {
        balance_usd: row.get("balance_usd"),
        balance_idr: row.get("balance_idr"),
        commission_available_usd: row.get("commission_available_usd"),
        commission_available_idr: row.get("commission_available_idr"),
        billing_currency: row.get("billing_currency"),
    })
}

pub async fn referral_user_stats(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqReferralUserStats,
) -> Result<ResReferralUserStats, String> {
    let subject = if req.subject_uid > 0 {
        req.subject_uid
    } else {
        viewer_iid
    };
    if !stats_can_view(pool, viewer_iid, subject).await {
        return Err("forbidden".into());
    }
    let col_a = column_for_period(pool, subject, &req.col_a.unwrap_or_default()).await;
    let col_b = column_for_period(pool, subject, &req.col_b.unwrap_or_default()).await;
    let wallet = wallet_snapshot(pool, subject).await;
    let (auth_email, auth_phone) = if viewer_is_root_or_director(pool, viewer_iid).await {
        subject_auth_contact(pool, subject).await
    } else {
        (String::new(), String::new())
    };
    Ok(ResReferralUserStats {
        col_a: Some(col_a),
        col_b: Some(col_b),
        wallet,
        auth_email,
        auth_phone,
    })
}
