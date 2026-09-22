//! Shared helpers for billing integration tests.

#![allow(dead_code)]

use chrono::{Duration, Utc};
use c35_store::{migrate_apply, pool_connect, snowflake_id};
use sqlx::PgPool;
use tokio::sync::OnceCell;

static SCHEMA_READY: OnceCell<()> = OnceCell::const_new();

pub fn db_tests_enabled() -> bool {
    std::env::var("C35_TEST_DB").ok().as_deref() == Some("1")
}

async fn schema_ready(pool: &PgPool) -> bool {
    sqlx::query_scalar::<_, bool>(
        "SELECT to_regclass('ai.billing_promotion_claim') IS NOT NULL",
    )
    .fetch_one(pool)
    .await
    .unwrap_or(false)
}

pub async fn test_pool() -> PgPool {
    std::env::set_var("PG_MAX_CONNECTIONS", "4");
    std::env::set_var("PG_ACQUIRE_TIMEOUT_SECS", "90");
    let pool = pool_connect().await.expect("pool_connect (set YB_* in .env.local)");
    SCHEMA_READY
        .get_or_init(|| async {
            if !schema_ready(&pool).await {
                migrate_apply(&pool).await.expect("migrate_apply");
            }
        })
        .await;
    pool
}

pub async fn test_user_insert(pool: &PgPool, label: &str) -> i64 {
    let id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, name, owner_iid, created_ts, updated_ts)
        VALUES ($1, 'user', '', $2, $1, NOW(), NOW())
        "#,
    )
    .bind(id)
    .bind(label)
    .execute(pool)
    .await
    .expect("insert test user");
    id
}

pub async fn test_billing_account(pool: &PgPool, owner_iid: i64, balance_idr: f64) -> i64 {
    let existing = sqlx::query_scalar::<_, Option<i64>>(
        "SELECT id FROM ai.billing_account WHERE owner_iid = $1 AND deleted_ts IS NULL LIMIT 1",
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .expect("lookup billing account")
    .flatten();
    if let Some(id) = existing {
        sqlx::query("UPDATE ai.billing_account SET balance_idr = $2 WHERE id = $1")
            .bind(id)
            .bind(balance_idr)
            .execute(pool)
            .await
            .expect("update balance");
        return id;
    }
    let id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.billing_account (id, owner_iid, balance_idr, plan_tier)
        VALUES ($1, $2, $3, 'free')
        "#,
    )
    .bind(id)
    .bind(owner_iid)
    .bind(balance_idr)
    .execute(pool)
    .await
    .expect("insert billing account");
    id
}

pub async fn test_package_code(
    pool: &PgPool,
    code: &str,
    issued_by: i64,
    price_idr: f64,
    max_uses: i32,
) {
    let meta = serde_json::json!({
        "type": "package",
        "name": "test package",
        "price_usd": price_idr / 17630.0,
        "price_idr": price_idr,
        "duration_months": 1,
        "base_plan_slug": "plus",
        "max_uses": max_uses
    });
    sqlx::query(
        r#"
        INSERT INTO ai.referral_code (code, issued_by_iid, used_count, expires_at, meta)
        VALUES ($1, $2, 0, NOW() + INTERVAL '30 days', $3::jsonb)
        ON CONFLICT (code) DO UPDATE SET
            used_count = 0,
            meta = EXCLUDED.meta,
            updated_ts = NOW()
        "#,
    )
    .bind(code)
    .bind(issued_by)
    .bind(meta)
    .execute(pool)
    .await
    .expect("insert package code");
}

pub async fn test_promotion_cleanup(pool: &PgPool, promotion_id: i64) {
    let _ = sqlx::query("DELETE FROM ai.billing_promotion_claim WHERE promotion_id = $1")
        .bind(promotion_id)
        .execute(pool)
        .await;
    let _ = sqlx::query("DELETE FROM ai.billing_promotion WHERE id = $1")
        .bind(promotion_id)
        .execute(pool)
        .await;
}

pub async fn test_user_cleanup(pool: &PgPool, user_iid: i64) {
    let _ = sqlx::query("DELETE FROM ai.billing_package_purchase WHERE owner_iid = $1")
        .bind(user_iid)
        .execute(pool)
        .await;
    let _ = sqlx::query("DELETE FROM ai.billing_profile WHERE owner_iid = $1")
        .bind(user_iid)
        .execute(pool)
        .await;
    let _ = sqlx::query("DELETE FROM ai.billing_account WHERE owner_iid = $1")
        .bind(user_iid)
        .execute(pool)
        .await;
    let _ = sqlx::query("DELETE FROM ai.billing_promotion_claim WHERE owner_iid = $1")
        .bind(user_iid)
        .execute(pool)
        .await;
    let _ = sqlx::query("DELETE FROM ai.identity WHERE id = $1")
        .bind(user_iid)
        .execute(pool)
        .await;
}

pub fn promo_code(prefix: &str) -> String {
    format!("{}{}", prefix, snowflake_id())
}

pub fn expired_window() -> (chrono::DateTime<Utc>, chrono::DateTime<Utc>) {
    let now = Utc::now();
    (now - Duration::days(10), now - Duration::days(1))
}

pub fn active_window() -> (chrono::DateTime<Utc>, chrono::DateTime<Utc>) {
    let now = Utc::now();
    (now - Duration::days(1), now + Duration::days(30))
}
