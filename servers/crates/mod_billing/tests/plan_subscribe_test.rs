//! Integration tests for plan subscribe + profile pools.
//! Run: C35_TEST_DB=1 cargo test -p c35_mod_billing --test plan_subscribe_test -- --ignored

mod common;

use c35_mod_billing::{billing_plan_subscribe, billing_profile_fetch, normalize_billing_period};
use c35_proto::ReqBillingPlanSubscribe;
use common::{db_tests_enabled, test_billing_account, test_pool, test_user_cleanup, test_user_insert};

#[tokio::test(flavor = "current_thread")]
#[ignore = "requires C35_TEST_DB=1 and YSQL"]
async fn subscribe_lite_monthly_applies_idr_pools() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    let user = test_user_insert(&pool, "sub-lite-user").await;
    test_billing_account(&pool, user, 200_000.0).await;

    let res = billing_plan_subscribe(
        &pool,
        user,
        ReqBillingPlanSubscribe {
            plan_slug: "lite".into(),
            currency: "IDR".into(),
            wallet_id: 0,
            direct_purchase: false,
            billing_period: "monthly".into(),
        },
    )
    .await
    .expect("subscribe lite");

    assert_eq!(res.plan_tier, "lite");
    assert!((res.balance_idr - 141_000.0).abs() < 1.0);

    let profile = billing_profile_fetch(&pool, user).await.expect("profile fetch").expect("profile row");
    assert_eq!(profile.plan_tier, "lite");
    assert_eq!(profile.alien_pool_limit_idr, 100_000.0);
    assert_eq!(profile.frontier_pool_limit_idr, 20_000.0);
    assert_eq!(profile.alien_pool_used_idr, 0.0);

    test_user_cleanup(&pool, user).await;
}

#[tokio::test(flavor = "current_thread")]
#[ignore = "requires C35_TEST_DB=1 and YSQL"]
async fn subscribe_lite_yearly_uses_yearly_price() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    let user = test_user_insert(&pool, "sub-lite-year").await;
    test_billing_account(&pool, user, 200_000.0).await;

    let res = billing_plan_subscribe(
        &pool,
        user,
        ReqBillingPlanSubscribe {
            plan_slug: "lite".into(),
            currency: "IDR".into(),
            wallet_id: 0,
            direct_purchase: false,
            billing_period: "yearly".into(),
        },
    )
    .await
    .expect("subscribe yearly");

    assert!((res.balance_idr - 151_000.0).abs() < 1.0);
    assert_eq!(normalize_billing_period("yearly"), "yearly");

    test_user_cleanup(&pool, user).await;
}
