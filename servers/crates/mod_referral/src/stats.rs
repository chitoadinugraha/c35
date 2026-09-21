use c35_mod_admin::require_admin;
use c35_proto::{ReferralStatPeriod, ReferralUserStatColumn, ReqReferralUserStats, ResReferralUserStats};
use sqlx::{PgPool, Row};

async fn stats_can_view(pool: &PgPool, viewer_iid: i64, subject_iid: i64) -> bool {
    if viewer_iid <= 0 || subject_iid <= 0 {
        return false;
    }
    if viewer_iid == subject_iid {
        return true;
    }
    require_admin(pool, viewer_iid).await.is_ok()
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
    Ok(ResReferralUserStats {
        col_a: Some(col_a),
        col_b: Some(col_b),
    })
}
