//! Ring vs account/pool leak guards (unit + optional DB).
//! Run DB: C35_TEST_DB=1 cargo test -p c35_mod_billing --test ring_leak_test -- --ignored

mod common;

use c35_mod_billing::{
    billing_profile_apply_plan_rings, billing_profile_deduct_rings, billing_profile_fetch,
    profile_has_pools, profile_has_rings, ring_deduct_pair, ProfilePoolRow, ProfileRingRow,
};
use chrono::Utc;
use common::{db_tests_enabled, test_pool, test_user_cleanup, test_user_insert};

fn sample_profile_with_rings_and_pools() -> ProfilePoolRow {
    ProfilePoolRow {
        id: 1,
        owner_iid: 1,
        plan_tier: "pro".to_string(),
        alien_pool_limit_idr: 565_000.0,
        alien_pool_used_idr: 0.0,
        frontier_pool_limit_idr: 115_000.0,
        frontier_pool_used_idr: 0.0,
        rings: ProfileRingRow {
            alien_allow_5h_used: 0.0,
            alien_allow_5h_limit: 1.0,
            alien_allow_weekly_used: 0.0,
            alien_allow_weekly_limit: 20.0,
            frontier_allow_5h_used: 0.0,
            frontier_allow_5h_limit: 0.2,
            frontier_allow_weekly_used: 0.0,
            frontier_allow_weekly_limit: 4.0,
            window_5h_start: Utc::now(),
            window_weekly_start: Utc::now(),
        },
    }
}

#[test]
fn profile_has_rings_when_ring_limits_set_even_with_pools() {
    let row = sample_profile_with_rings_and_pools();
    assert!(profile_has_pools(&row));
    assert!(profile_has_rings(&row));
}

#[test]
fn ring_deduct_pair_charges_both_windows_once_not_double_bucket() {
    let (u5, uw, take, ov) = ring_deduct_pair(0.0, 0.05, 0.0, 1.0, 0.03);
    assert!((take - 0.03).abs() < 1e-9);
    assert!((u5 - 0.03).abs() < 1e-9);
    assert!((uw - 0.03).abs() < 1e-9);
    assert!((ov - 0.0).abs() < 1e-9);
    let (_, _, take2, ov2) = ring_deduct_pair(0.04, 0.05, 0.99, 1.0, 0.02);
    assert!((take2 - 0.01).abs() < 1e-9);
    assert!((ov2 - 0.01).abs() < 1e-9);
}

#[tokio::test(flavor = "current_thread")]
#[ignore = "requires C35_TEST_DB=1 and YSQL"]
async fn frontier_deduct_uses_frontier_ring_not_alien() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    let user = test_user_insert(&pool, "ring-leak-frontier").await;
    billing_profile_apply_plan_rings(&pool, user, 1.0, 20.0, 0.2, 4.0, "pro")
        .await
        .expect("apply rings");

    let overflow = billing_profile_deduct_rings(&pool, user, "frontier", 0.01)
        .await
        .expect("deduct")
        .unwrap_or(0.0);
    assert_eq!(overflow, 0.0);

    let profile = billing_profile_fetch(&pool, user).await.expect("fetch").expect("row");
    assert_eq!(profile.rings.alien_allow_5h_used, 0.0);
    assert!((profile.rings.frontier_allow_5h_used - 0.01).abs() < 1e-9);

    test_user_cleanup(&pool, user).await;
}
