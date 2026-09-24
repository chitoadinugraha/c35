use c35_mod_admin::admin_platform_pnl;
use c35_mod_platform::pnl_ai_cogs_drift_pct;
use c35_proto::ReqAdminPlatformPnl;
use c35_store::{migrate_apply, pool_connect, snowflake_id};
use sqlx::PgPool;

fn db_tests_enabled() -> bool {
    std::env::var("C35_TEST_DB").ok().as_deref() == Some("1")
}

async fn test_pool() -> PgPool {
    std::env::set_var("PG_MAX_CONNECTIONS", "4");
    pool_connect().await.expect("pool_connect (set YB_* in .env.local)")
}

async fn ensure_schema(pool: &PgPool) {
    let ready = sqlx::query_scalar::<_, bool>("SELECT to_regclass('ai.platform_vendor_cost') IS NOT NULL")
        .fetch_one(pool)
        .await
        .unwrap_or(false);
    if !ready {
        migrate_apply(pool).await.expect("migrate_apply");
    }
}

#[test]
fn pnl_ai_cogs_drift_pct_zero_when_both_zero() {
    assert_eq!(pnl_ai_cogs_drift_pct(0.0, 0.0), 0.0);
}

#[test]
fn pnl_ai_cogs_drift_pct_five_percent_at_threshold() {
    assert!((pnl_ai_cogs_drift_pct(100.0, 105.0) - 5.0).abs() < 0.001);
    assert!((pnl_ai_cogs_drift_pct(105.0, 100.0) - 4.7619047619).abs() < 0.001);
}

#[test]
fn pnl_ai_cogs_drift_pct_hundred_when_one_side_zero() {
    assert_eq!(pnl_ai_cogs_drift_pct(0.0, 50.0), 100.0);
    assert_eq!(pnl_ai_cogs_drift_pct(80.0, 0.0), 100.0);
}

#[tokio::test]
async fn admin_platform_pnl_rejects_non_root() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    ensure_schema(&pool).await;
    let user = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, name, owner_iid, created_ts, updated_ts)
        VALUES ($1, 'user', '', 'pnl test user', $1, NOW(), NOW())
        "#,
    )
    .bind(user)
    .execute(&pool)
    .await
    .expect("insert user");
    let err = admin_platform_pnl(
        &pool,
        user,
        ReqAdminPlatformPnl {
            since_ms: 0,
            until_ms: 0,
        },
    )
    .await
    .unwrap_err();
    assert_eq!(err.status_code, 403);
}
