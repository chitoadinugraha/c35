//! Device unpair: locked push payload + optional YB E2E.
//! Requires YB: cargo test -p c35_mod_device --test device_unpair_e2e -- --ignored --nocapture

use c35_mod_device::{
    agent_session_resolve, device_pair, device_pair_poll, device_pair_register, device_unpair,
    DEVICE_UNPAIR_PUSH,
};
use sqlx::Row;
use c35_proto::{ReqDevicePair, ReqDevicePairPoll, ReqDevicePairRegister};
use c35_store::{migrate_apply, pool_connect, snowflake_id};

#[test]
fn unpair_push_payload_locked() {
    assert_eq!(DEVICE_UNPAIR_PUSH, b"c35.unpair");
}

async fn test_pool() -> sqlx::PgPool {
    let pool = pool_connect().await.expect("pool_connect (set YB_* in .env.local)");
    migrate_apply(&pool).await.expect("migrate_apply");
    pool
}

async fn test_user_insert(pool: &sqlx::PgPool) -> i64 {
    let id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, name, owner_iid, created_ts, updated_ts)
        VALUES ($1, 'user', '', 'unpair-e2e-user', $1, NOW(), NOW())
        "#,
    )
    .bind(id)
    .execute(pool)
    .await
    .expect("insert test user");
    id
}

async fn test_cleanup(pool: &sqlx::PgPool, user_iid: i64, device_iid: i64) {
    let _ = sqlx::query("DELETE FROM ai.identity_grant WHERE resource_iid = $1 OR grantee_iid = $2")
        .bind(device_iid)
        .bind(user_iid)
        .execute(pool)
        .await;
    let _ = sqlx::query("DELETE FROM ai.identity WHERE id = ANY($1)")
        .bind([user_iid, device_iid])
        .execute(pool)
        .await;
}

#[tokio::test]
#[ignore = "requires YB; run: cargo test -p c35_mod_device --test device_unpair_e2e -- --ignored"]
async fn device_unpair_e2e() {
    let pool = test_pool().await;
    let user_iid = test_user_insert(&pool).await;

    let reg = device_pair_register(
        &pool,
        ReqDevicePairRegister {
            device_name: "e2e-unpair-pc".into(),
            device_type: "windows".into(),
        },
    )
    .await
    .expect("register");

    let code = reg.code.replace('-', "");
    let claim = device_pair(&pool, user_iid, ReqDevicePair { code })
        .await
        .expect("claim");
    let device_iid = claim
        .device
        .expect("device row")
        .identity
        .as_ref()
        .map(|i| i.iid)
        .unwrap_or(0);
    assert!(device_iid > 0);

    let claimed = device_pair_poll(
        &pool,
        ReqDevicePairPoll {
            device_secret: reg.device_secret.clone(),
        },
    )
    .await
    .expect("poll claimed");
    assert_eq!(claimed.status, "claimed");
    let session_key = claimed.session_key;
    assert!(!session_key.is_empty());

    let session = agent_session_resolve(&pool, &session_key)
        .await
        .expect("resolve before unpair");
    assert!(session.is_some(), "session should resolve before unpair");

    device_unpair(&pool, None, device_iid)
        .await
        .expect("device_unpair");

    let session_after = agent_session_resolve(&pool, &session_key)
        .await
        .expect("resolve after unpair");
    assert!(session_after.is_none(), "session should not resolve after unpair");

    let row = sqlx::query("SELECT deleted_ts FROM ai.identity WHERE id = $1")
        .bind(device_iid)
        .fetch_one(&pool)
        .await
        .expect("identity row");
    assert!(
        row.get::<Option<chrono::DateTime<chrono::Utc>>, _>("deleted_ts").is_some(),
        "deleted_ts should be set"
    );

    test_cleanup(&pool, user_iid, device_iid).await;
}
