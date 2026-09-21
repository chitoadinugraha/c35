//! Full pairing flow: register -> poll pending -> claim -> poll claimed.
//! Requires YB: cargo test -p c35_mod_device --test device_pair_e2e -- --ignored --nocapture

use c35_mod_device::{device_pair, device_pair_poll, device_pair_register};
use c35_proto::{ReqDevicePair, ReqDevicePairPoll, ReqDevicePairRegister};
use c35_store::{migrate_apply, pool_connect, snowflake_id};

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
        VALUES ($1, 'user', '', 'pair-e2e-user', $1, NOW(), NOW())
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
#[ignore = "requires YB; run: cargo test -p c35_mod_device --test device_pair_e2e -- --ignored"]
async fn device_pair_register_poll_claim_e2e() {
    let pool = test_pool().await;
    let user_iid = test_user_insert(&pool).await;

    let reg = device_pair_register(
        &pool,
        ReqDevicePairRegister {
            device_name: "e2e-pc".into(),
            device_type: "windows".into(),
        },
    )
    .await
    .expect("register");

    assert_eq!(reg.code.len(), 11, "display code XXXXX-XXXXX");
    assert!(reg.device_secret.starts_with("sec_"));
    assert_eq!(reg.expires_in_sec, 300);

    let pending = device_pair_poll(
        &pool,
        ReqDevicePairPoll {
            device_secret: reg.device_secret.clone(),
        },
    )
    .await
    .expect("poll pending");
    assert_eq!(pending.status, "pending");
    assert!(pending.session_key.is_empty());

    let code = reg.code.replace('-', "");
    let claim = device_pair(
        &pool,
        user_iid,
        ReqDevicePair { code },
    )
    .await
    .expect("claim");
    let device = claim.device.expect("device row");
    assert_eq!(device.identity.as_ref().map(|i| i.owner_iid), Some(user_iid));

    let claimed = device_pair_poll(
        &pool,
        ReqDevicePairPoll {
            device_secret: reg.device_secret.clone(),
        },
    )
    .await
    .expect("poll claimed");
    assert_eq!(claimed.status, "claimed");
    assert!(!claimed.session_key.is_empty());
    assert_eq!(claimed.device_iid, device.identity.as_ref().map(|i| i.iid).unwrap_or(0));

    let device_iid = device.identity.as_ref().map(|i| i.iid).unwrap_or(0);
    test_cleanup(&pool, user_iid, device_iid).await;
}
