//! Pair this dev PC to owner 99000 via YB (run from desktop with .env.local YB_*).
//! cargo test -p c35_mod_device --test pair_chito_local -- --ignored --nocapture

use c35_mod_device::{device_pair, device_pair_poll, device_pair_register};
use c35_proto::{ReqDevicePair, ReqDevicePairPoll, ReqDevicePairRegister};
use c35_store::{migrate_apply, pool_connect};

#[tokio::test]
#[ignore = "dev desktop: pairs hostname Chito to uid 99000; prints session_key"]
async fn pair_chito_local_machine() {
    let pool = pool_connect().await.expect("pool_connect (YB_* in .env.local)");
    migrate_apply(&pool).await.expect("migrate_apply");
    let reg = device_pair_register(
        &pool,
        ReqDevicePairRegister {
            device_name: "Chito".into(),
            device_type: "windows".into(),
        },
    )
    .await
    .expect("register");
    let code = reg.code.replace('-', "");
    device_pair(&pool, 99000, ReqDevicePair { code })
        .await
        .expect("claim for 99000");
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
    println!("device_iid={}", claimed.device_iid);
    println!("session_key={}", claimed.session_key);
}