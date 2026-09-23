use c35_mod_admin::{admin_log_list, require_root};
use c35_proto::ReqAdminLogList;
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
    let ready = sqlx::query_scalar::<_, bool>("SELECT to_regclass('ai.log') IS NOT NULL")
        .fetch_one(pool)
        .await
        .unwrap_or(false);
    if !ready {
        migrate_apply(pool).await.expect("migrate_apply");
    }
}

#[tokio::test]
async fn require_root_rejects_zero_iid() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    ensure_schema(&pool).await;
    let err = require_root(&pool, 0).await.unwrap_err();
    assert_eq!(err.status_code, 403);
}

#[tokio::test]
async fn admin_log_list_rejects_non_root() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    ensure_schema(&pool).await;
    let user = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, name, owner_iid, created_ts, updated_ts)
        VALUES ($1, 'user', '', 'log test user', $1, NOW(), NOW())
        "#,
    )
    .bind(user)
    .execute(&pool)
    .await
    .expect("insert user");
    let err = admin_log_list(
        &pool,
        user,
        ReqAdminLogList {
            since_ms: 0,
            until_ms: 0,
            text: String::new(),
            kind: None,
            topic: None,
            limit: 10,
            before_id: None,
            owner_iid: None,
        },
    )
    .await
    .unwrap_err();
    assert_eq!(err.status_code, 403);
}

#[tokio::test]
async fn admin_log_list_root_filters_owner() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    ensure_schema(&pool).await;
    let owner = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, name, owner_iid, meta, created_ts, updated_ts)
        VALUES ($1, 'user', '', 'owner', $1, '{"is_root": true}'::jsonb, NOW(), NOW())
        "#,
    )
    .bind(owner)
    .execute(&pool)
    .await
    .expect("insert root");
    let other = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, name, owner_iid, created_ts, updated_ts)
        VALUES ($1, 'user', '', 'other', $1, NOW(), NOW())
        "#,
    )
    .bind(other)
    .execute(&pool)
    .await
    .expect("insert other");
    let log_id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.log (id, owner_iid, kind, topic, text, created_ts, updated_ts)
        VALUES ($1, $2, 'system', 'test', 'hello admin', NOW(), NOW())
        "#,
    )
    .bind(log_id)
    .bind(other)
    .execute(&pool)
    .await
    .expect("insert log");
    let res = admin_log_list(
        &pool,
        owner,
        ReqAdminLogList {
            owner_iid: Some(other),
            since_ms: 0,
            until_ms: 0,
            text: "hello".into(),
            kind: None,
            topic: None,
            limit: 10,
            before_id: None,
        },
    )
    .await
    .expect("admin_log_list");
    assert_eq!(res.logs.len(), 1);
    assert_eq!(res.logs[0].id, log_id);
}
