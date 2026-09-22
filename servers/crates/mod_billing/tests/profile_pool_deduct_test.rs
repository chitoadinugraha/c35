//! Integration tests for profile pool deduct on LLM turns.
//! Run: C35_TEST_DB=1 cargo test -p c35_mod_billing --test profile_pool_deduct_test -- --ignored

mod common;

use c35_mod_billing::{
    billing_profile_apply_plan_pools, billing_profile_deduct_turn, billing_profile_fetch,
};
use common::{db_tests_enabled, test_pool, test_user_cleanup, test_user_insert};

const FX_MICRO: i64 = 17_630_000_000;

#[tokio::test(flavor = "current_thread")]
#[ignore = "requires C35_TEST_DB=1 and YSQL"]
async fn alien_turn_deducts_alien_pool_only() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    let user = test_user_insert(&pool, "pool-deduct-user").await;
    billing_profile_apply_plan_pools(&pool, user, "lite", 100_000.0, 20_000.0)
        .await
        .expect("apply pools");

    let overflow = billing_profile_deduct_turn(&pool, user, "alienai", 10_000, 2_000, FX_MICRO)
        .await
        .expect("deduct")
        .unwrap_or(0.0);
    assert_eq!(overflow, 0.0);

    let profile = billing_profile_fetch(&pool, user).await.expect("fetch").expect("row");
    assert!(profile.alien_pool_used_idr > 0.0);
    assert_eq!(profile.frontier_pool_used_idr, 0.0);

    test_user_cleanup(&pool, user).await;
}

#[tokio::test(flavor = "current_thread")]
#[ignore = "requires C35_TEST_DB=1 and YSQL"]
async fn frontier_turn_deducts_frontier_pool() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    let user = test_user_insert(&pool, "pool-frontier-user").await;
    billing_profile_apply_plan_pools(&pool, user, "lite", 100_000.0, 20_000.0)
        .await
        .expect("apply pools");

    let overflow = billing_profile_deduct_turn(&pool, user, "gemini-2.5-flash-lite", 10_000, 2_000, FX_MICRO)
        .await
        .expect("deduct")
        .unwrap_or(0.0);
    assert_eq!(overflow, 0.0);

    let profile = billing_profile_fetch(&pool, user).await.expect("fetch").expect("row");
    assert_eq!(profile.alien_pool_used_idr, 0.0);
    assert!(profile.frontier_pool_used_idr > 0.0);

    test_user_cleanup(&pool, user).await;
}
