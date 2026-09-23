use anyhow::Result;
use sqlx::PgPool;

use crate::invalidate::hint_invalidate;

pub async fn hint_touch(pool: &PgPool, user_iid: i64, asset_iid: i64, asset_kind: &str) -> Result<()> {
    sqlx::query(
        r#"
        INSERT INTO ai.user_asset_touch (user_iid, asset_iid, asset_kind, last_accessed_ts, created_ts, updated_ts)
        VALUES ($1, $2, $3, NOW(), NOW(), NOW())
        ON CONFLICT (user_iid, asset_iid) DO UPDATE SET
            asset_kind = EXCLUDED.asset_kind,
            last_accessed_ts = NOW(),
            updated_ts = NOW(),
            deleted_ts = NULL
        "#,
    )
    .bind(user_iid)
    .bind(asset_iid)
    .bind(asset_kind)
    .execute(pool)
    .await?;
    hint_invalidate(pool, user_iid).await
}
