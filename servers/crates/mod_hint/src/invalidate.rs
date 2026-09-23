use std::collections::HashSet;

use anyhow::Result;
use sqlx::PgPool;

pub async fn hint_invalidate(pool: &PgPool, user_iid: i64) -> Result<()> {
    sqlx::query("DELETE FROM ai.hint_bundle WHERE user_iid = $1")
        .bind(user_iid)
        .execute(pool)
        .await?;
    Ok(())
}

pub async fn hint_invalidate_all(pool: &PgPool) -> Result<()> {
    sqlx::query("DELETE FROM ai.hint_bundle").execute(pool).await?;
    Ok(())
}

pub async fn hint_invalidate_for_asset(pool: &PgPool, asset_iid: i64) -> Result<()> {
    let owner_iid: Option<i64> = sqlx::query_scalar(
        "SELECT owner_iid FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL",
    )
    .bind(asset_iid)
    .fetch_optional(pool)
    .await?;

    let grantees: Vec<i64> = sqlx::query_scalar(
        "SELECT grantee_iid FROM ai.identity_grant WHERE resource_iid = $1 AND deleted_ts IS NULL",
    )
    .bind(asset_iid)
    .fetch_all(pool)
    .await
    .unwrap_or_default();

    let touch_users: Vec<i64> = sqlx::query_scalar(
        "SELECT user_iid FROM ai.user_asset_touch WHERE asset_iid = $1 AND deleted_ts IS NULL",
    )
    .bind(asset_iid)
    .fetch_all(pool)
    .await
    .unwrap_or_default();

    let mut users = HashSet::new();
    if let Some(o) = owner_iid {
        users.insert(o);
    }
    for u in grantees.into_iter().chain(touch_users) {
        users.insert(u);
    }
    for u in users {
        hint_invalidate(pool, u).await?;
    }
    Ok(())
}
