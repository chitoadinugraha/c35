use anyhow::{Context, Result};
use sqlx::PgPool;

use crate::config::DATA_SOURCE_SYNCING_STUCK_SEC;

/// Claim due bindings for background sync (sharded via `FOR UPDATE SKIP LOCKED`).
pub async fn sync_due_claim_batch(pool: &PgPool, ttl_sec: i64, limit: i64) -> Result<Vec<i64>> {
    let rows = sqlx::query_scalar::<_, i64>(
        r#"
        WITH due AS (
            SELECT d.id
            FROM ai.data_source d
            INNER JOIN ai.data_source_sync s ON s.data_source_id = d.id
            WHERE d.deleted_ts IS NULL
              AND s.synced_ts < NOW() - make_interval(secs => $1)
              AND (
                s.status IN ('ok', 'error', 'stale')
                OR (s.status = 'syncing' AND s.updated_ts < NOW() - make_interval(secs => $3))
              )
            ORDER BY s.synced_ts ASC
            LIMIT $2
            FOR UPDATE OF s SKIP LOCKED
        )
        UPDATE ai.data_source_sync s
        SET status = 'syncing', updated_ts = NOW()
        FROM due
        WHERE s.data_source_id = due.id
        RETURNING s.data_source_id
        "#,
    )
    .bind(ttl_sec)
    .bind(limit)
    .bind(DATA_SOURCE_SYNCING_STUCK_SEC)
    .fetch_all(pool)
    .await
    .context("sync_due_claim_batch")?;
    Ok(rows)
}
