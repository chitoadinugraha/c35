//! Integration tests for package redeem limits and balance checks.
//! Run: C35_TEST_DB=1 cargo test -p c35_mod_billing --test package_redeem_test -- --ignored

mod common;

use c35_mod_billing::{billing_package_preview, billing_package_redeem};
use common::{
    db_tests_enabled, test_billing_account, test_package_code, test_pool, test_user_cleanup,
    test_user_insert,
};

#[tokio::test(flavor = "current_thread")]
#[ignore = "requires C35_TEST_DB=1 and YSQL"]
async fn max_uses_enforced_on_sequential_redeem() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    let issuer = test_user_insert(&pool, "pkg-issuer").await;
    let buyer_a = test_user_insert(&pool, "pkg-buyer-a").await;
    let buyer_b = test_user_insert(&pool, "pkg-buyer-b").await;
    let code = format!("PKG{}", c35_store::snowflake_id());
    let price = 49_000.0;
    test_billing_account(&pool, buyer_a, 100_000.0).await;
    test_billing_account(&pool, buyer_b, 100_000.0).await;
    test_package_code(&pool, &code, issuer, price, 1).await;

    billing_package_redeem(&pool, buyer_a, &code)
        .await
        .expect("first redeem");
    let err = billing_package_redeem(&pool, buyer_b, &code)
        .await
        .expect_err("second redeem");
    assert!(err.contains("usage limit reached"));

    test_user_cleanup(&pool, issuer).await;
    test_user_cleanup(&pool, buyer_a).await;
    test_user_cleanup(&pool, buyer_b).await;
    let _ = sqlx::query("DELETE FROM ai.referral_code WHERE code = $1")
        .bind(&code)
        .execute(&pool)
        .await;
}

#[tokio::test(flavor = "current_thread")]
#[ignore = "requires C35_TEST_DB=1 and YSQL"]
async fn insufficient_balance_rejected() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    let issuer = test_user_insert(&pool, "pkg-issuer-low").await;
    let buyer = test_user_insert(&pool, "pkg-buyer-low").await;
    let code = format!("LOW{}", c35_store::snowflake_id());
    let price = 99_000.0;
    test_billing_account(&pool, buyer, 10_000.0).await;
    test_package_code(&pool, &code, issuer, price, 0).await;

    let preview = billing_package_preview(&pool, buyer, &code)
        .await
        .expect("preview");
    assert!((preview.amount_idr - price).abs() < 1.0);

    let err = billing_package_redeem(&pool, buyer, &code)
        .await
        .expect_err("redeem without balance");
    assert!(err.contains("insufficient"));

    test_user_cleanup(&pool, issuer).await;
    test_user_cleanup(&pool, buyer).await;
    let _ = sqlx::query("DELETE FROM ai.referral_code WHERE code = $1")
        .bind(&code)
        .execute(&pool)
        .await;
}

#[tokio::test(flavor = "current_thread")]
#[ignore = "requires C35_TEST_DB=1 and YSQL"]
async fn successful_redeem_in_transaction() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    let issuer = test_user_insert(&pool, "pkg-issuer-ok").await;
    let buyer = test_user_insert(&pool, "pkg-buyer-ok").await;
    let code = format!("OK{}", c35_store::snowflake_id());
    let price = 49_000.0;
    let start_balance = 200_000.0;
    test_billing_account(&pool, buyer, start_balance).await;
    test_package_code(&pool, &code, issuer, price, 0).await;

    let res = billing_package_redeem(&pool, buyer, &code)
        .await
        .expect("redeem");
    assert!(res.purchase_id > 0);
    assert!((res.amount_idr - price).abs() < 1.0);
    assert_eq!(res.plan_tier, "plus");

    let balance_after = sqlx::query_scalar::<_, f64>(
        "SELECT balance_idr::float8 FROM ai.billing_account WHERE owner_iid = $1 AND deleted_ts IS NULL",
    )
    .bind(buyer)
    .fetch_one(&pool)
    .await
    .expect("balance");
    assert!((balance_after - (start_balance - price)).abs() < 1.0);

    let used = sqlx::query_scalar::<_, i32>("SELECT used_count FROM ai.referral_code WHERE code = $1")
        .bind(&code)
        .fetch_one(&pool)
        .await
        .expect("used_count");
    assert_eq!(used, 1);

    let purchase_count = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*)::bigint FROM ai.billing_package_purchase WHERE owner_iid = $1 AND referral_code = $2",
    )
    .bind(buyer)
    .bind(&code)
    .fetch_one(&pool)
    .await
    .expect("purchase row");
    assert_eq!(purchase_count, 1);

    test_user_cleanup(&pool, issuer).await;
    test_user_cleanup(&pool, buyer).await;
    let _ = sqlx::query("DELETE FROM ai.referral_code WHERE code = $1")
        .bind(&code)
        .execute(&pool)
        .await;
}
