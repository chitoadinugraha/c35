use anyhow::{Context, Result};
use c35_proto::PlatformUserMetricsWindowCounts;
use sqlx::{PgPool, Row};

#[derive(Debug, Clone, Copy)]
pub struct PlatformUserMetrics {
    pub users: PlatformUserMetricsWindowCounts,
    pub active_users: PlatformUserMetricsWindowCounts,
    pub paid_users: PlatformUserMetricsWindowCounts,
    pub total_users: i64,
}

/// Registrations (created_ts), app opens (identity_client.last_ws_ts_ms), settled top-up/purchase.
pub async fn platform_user_metrics_query(pool: &PgPool) -> Result<PlatformUserMetrics> {
    let signup = signup_counts(pool).await?;
    let active = active_counts(pool).await?;
    let paid = paid_counts(pool).await?;
    let total_users = sqlx::query_scalar(
        "SELECT COUNT(*)::bigint FROM ai.identity WHERE kind = 'user' AND deleted_ts IS NULL",
    )
    .fetch_one(pool)
    .await
    .context("total users")?;
    Ok(PlatformUserMetrics {
        users: signup,
        active_users: active,
        paid_users: paid,
        total_users,
    })
}

async fn signup_counts(pool: &PgPool) -> Result<PlatformUserMetricsWindowCounts> {
    let row = sqlx::query(
        r#"
        SELECT
            COUNT(*) FILTER (WHERE created_ts >= NOW() - INTERVAL '24 hours')::bigint AS h24,
            COUNT(*) FILTER (WHERE created_ts >= NOW() - INTERVAL '7 days')::bigint AS d7,
            COUNT(*) FILTER (WHERE created_ts >= NOW() - INTERVAL '30 days')::bigint AS d30,
            COUNT(*) FILTER (WHERE created_ts >= NOW() - INTERVAL '1 year')::bigint AS y1
        FROM ai.identity
        WHERE kind = 'user' AND deleted_ts IS NULL
        "#,
    )
    .fetch_one(pool)
    .await
    .context("signup metrics")?;
    Ok(row_to_counts(&row))
}

async fn active_counts(pool: &PgPool) -> Result<PlatformUserMetricsWindowCounts> {
    let row = sqlx::query(
        r#"
        WITH last_seen AS (
            SELECT identity_iid, MAX(last_ws_ts_ms) AS ws_ms
            FROM ai.identity_client
            WHERE deleted_ts IS NULL
            GROUP BY identity_iid
        )
        SELECT
            COUNT(*) FILTER (
                WHERE ws_ms >= (EXTRACT(EPOCH FROM NOW() - INTERVAL '24 hours') * 1000)::bigint
            )::bigint AS h24,
            COUNT(*) FILTER (
                WHERE ws_ms >= (EXTRACT(EPOCH FROM NOW() - INTERVAL '7 days') * 1000)::bigint
            )::bigint AS d7,
            COUNT(*) FILTER (
                WHERE ws_ms >= (EXTRACT(EPOCH FROM NOW() - INTERVAL '30 days') * 1000)::bigint
            )::bigint AS d30,
            COUNT(*) FILTER (
                WHERE ws_ms >= (EXTRACT(EPOCH FROM NOW() - INTERVAL '1 year') * 1000)::bigint
            )::bigint AS y1
        FROM last_seen ls
        INNER JOIN ai.identity i ON i.id = ls.identity_iid
        WHERE i.kind = 'user' AND i.deleted_ts IS NULL
        "#,
    )
    .fetch_one(pool)
    .await
    .context("active user metrics")?;
    Ok(row_to_counts(&row))
}

async fn paid_counts(pool: &PgPool) -> Result<PlatformUserMetricsWindowCounts> {
    let row = sqlx::query(
        r#"
        WITH paid_events AS (
            SELECT t.owner_iid, COALESCE(t.settled_ts, t.created_ts) AS at
            FROM ai.billing_topup_request t
            INNER JOIN ai.identity i ON i.id = t.owner_iid
                AND i.kind = 'user' AND i.deleted_ts IS NULL
            WHERE t.status = 'settled' AND t.deleted_ts IS NULL
            UNION ALL
            SELECT p.owner_iid, COALESCE(p.settled_ts, p.created_ts) AS at
            FROM ai.billing_purchase p
            INNER JOIN ai.identity i ON i.id = p.owner_iid
                AND i.kind = 'user' AND i.deleted_ts IS NULL
            WHERE p.status = 'settled'
        )
        SELECT
            COUNT(DISTINCT owner_iid) FILTER (WHERE at >= NOW() - INTERVAL '24 hours')::bigint AS h24,
            COUNT(DISTINCT owner_iid) FILTER (WHERE at >= NOW() - INTERVAL '7 days')::bigint AS d7,
            COUNT(DISTINCT owner_iid) FILTER (WHERE at >= NOW() - INTERVAL '30 days')::bigint AS d30,
            COUNT(DISTINCT owner_iid) FILTER (WHERE at >= NOW() - INTERVAL '1 year')::bigint AS y1
        FROM paid_events
        "#,
    )
    .fetch_one(pool)
    .await
    .context("paid user metrics")?;
    Ok(row_to_counts(&row))
}

fn row_to_counts(row: &sqlx::postgres::PgRow) -> PlatformUserMetricsWindowCounts {
    PlatformUserMetricsWindowCounts {
        h24: row.get("h24"),
        d7: row.get("d7"),
        d30: row.get("d30"),
        y1: row.get("y1"),
    }
}
