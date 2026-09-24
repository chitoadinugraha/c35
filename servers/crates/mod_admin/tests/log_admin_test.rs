use c35_mod_admin::{admin_log_list, admin_log_report, require_root};
use c35_proto::{ReqAdminLogList, ReqAdminLogReport};
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

#[tokio::test]
async fn admin_log_report_rejects_non_root() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    ensure_schema(&pool).await;
    let user = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, name, owner_iid, created_ts, updated_ts)
        VALUES ($1, 'user', '', 'report test user', $1, NOW(), NOW())
        "#,
    )
    .bind(user)
    .execute(&pool)
    .await
    .expect("insert user");
    let err = admin_log_report(
        &pool,
        user,
        ReqAdminLogReport {
            since_ms: 0,
            until_ms: 0,
            limit: 10,
            owner_iid: None,
        },
    )
    .await
    .unwrap_err();
    assert_eq!(err.status_code, 403);
}

#[tokio::test]
async fn admin_log_report_aggregates_kinds() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    ensure_schema(&pool).await;
    let root = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, name, owner_iid, meta, created_ts, updated_ts)
        VALUES ($1, 'user', '', 'root', $1, '{"is_root": true}'::jsonb, NOW(), NOW())
        "#,
    )
    .bind(root)
    .execute(&pool)
    .await
    .expect("insert root");
    let owner = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, name, owner_iid, created_ts, updated_ts)
        VALUES ($1, 'user', '', 'owner', $1, NOW(), NOW())
        "#,
    )
    .bind(owner)
    .execute(&pool)
    .await
    .expect("insert owner");
    for (kind, n) in [("tool", 3_i64), ("llm_call", 2_i64)] {
        for _ in 0..n {
            sqlx::query(
                r#"
                INSERT INTO ai.log (id, owner_iid, kind, topic, text, created_ts, updated_ts)
                VALUES ($1, $2, $3, 'test', 'row', NOW(), NOW())
                "#,
            )
            .bind(snowflake_id())
            .bind(owner)
            .bind(kind)
            .execute(&pool)
            .await
            .expect("insert log");
        }
    }
    let res = admin_log_report(
        &pool,
        root,
        ReqAdminLogReport {
            owner_iid: Some(owner),
            since_ms: 0,
            until_ms: 0,
            limit: 10,
        },
    )
    .await
    .expect("admin_log_report");
    assert_eq!(res.widgets.len(), 3);
    let total = res.widgets[0]
        .element
        .as_ref()
        .and_then(|e| match e {
            c35_proto::ui_widget::Element::MetricsCard(c) => Some(c.value.clone()),
            _ => None,
        })
        .unwrap_or_default();
    assert_eq!(total, "5");
    let table = res.widgets[2]
        .element
        .as_ref()
        .and_then(|e| match e {
            c35_proto::ui_widget::Element::Table(t) => Some(t.rows.clone()),
            _ => None,
        })
        .unwrap_or_default();
    assert_eq!(table.len(), 2);
    assert_eq!(table[0].cells, vec!["tool", "3"]);
    assert_eq!(table[1].cells, vec!["llm_call", "2"]);
}
