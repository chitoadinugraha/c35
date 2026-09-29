//! Prepaid voucher issue + redeem (package + credit).
//! Run: C35_TEST_DB=1 cargo test -p c35_mod_billing --test voucher_prepaid_test -- --ignored

mod common;

use c35_mod_billing::{billing_entitlement_list, billing_package_redeem, billing_voucher_issue};
use c35_proto::ReqBillingVoucherIssue;
use common::{db_tests_enabled, test_billing_account, test_pool, test_user_cleanup, test_user_insert};

async fn seed_finance_issuer(pool: &sqlx::PgPool, iid: i64) {
    sqlx::query(
        r#"
        UPDATE ai.identity
        SET meta = COALESCE(meta, '{}'::jsonb) || '{"global_roles":["finance"]}'::jsonb,
            updated_ts = NOW()
        WHERE id = $1
        "#,
    )
    .bind(iid)
    .execute(pool)
    .await
    .expect("finance role");
}

#[tokio::test(flavor = "current_thread")]
#[ignore = "requires C35_TEST_DB=1 and YSQL"]
async fn prepaid_package_stacks_pools_without_wallet_debit() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    let issuer = test_user_insert(&pool, "voucher-issuer").await;
    seed_finance_issuer(&pool, issuer).await;
    let buyer = 33000_i64;
    let start_balance = 50_000.0;
    test_billing_account(&pool, buyer, start_balance).await;

    let code = format!("PKGPRE{}", c35_store::snowflake_id());
    let issue = billing_voucher_issue(
        &pool,
        issuer,
        ReqBillingVoucherIssue {
            kind: "package".into(),
            plan_slug: "plus".into(),
            duration_months: 1,
            credit_idr: 0.0,
            face_value_idr: 105_000.0,
            max_uses: 1,
            expires_at_ms: 0,
            payment_ref: "test".into(),
            code: code.clone(),
            name: "Plus 1mo".into(),
            scope: "user".into(),
            billing_period: "monthly".into(),
            list_price_idr: 0.0,
            alien_pool_limit_idr: 0.0,
            frontier_pool_limit_idr: 0.0,
            quantity: 1,
        },
    )
    .await
    .expect("issue");

    let res = billing_package_redeem(&pool, buyer, &issue.code)
        .await
        .expect("redeem");
    assert!(res.entitlement_id > 0);
    assert_eq!(res.plan_tier, "plus");

    let balance_after = sqlx::query_scalar::<_, f64>(
        "SELECT balance_idr::float8 FROM ai.billing_account WHERE owner_iid = $1 AND deleted_ts IS NULL",
    )
    .bind(buyer)
    .fetch_one(&pool)
    .await
    .expect("balance");
    assert!((balance_after - start_balance).abs() < 1.0, "wallet must not be debited");

    let alien_limit = sqlx::query_scalar::<_, f64>(
        "SELECT alien_pool_limit_idr::float8 FROM ai.billing_profile WHERE owner_iid = $1 AND deleted_ts IS NULL",
    )
    .bind(buyer)
    .fetch_one(&pool)
    .await
    .expect("pool");
    assert!(alien_limit >= 175_000.0);

    let list = billing_entitlement_list(&pool, buyer).await.expect("list");
    assert!(!list.items.is_empty());

    test_user_cleanup(&pool, issuer).await;
    let _ = sqlx::query("DELETE FROM ai.referral_code WHERE code = $1")
        .bind(&issue.code)
        .execute(&pool)
        .await;
    let _ = sqlx::query("DELETE FROM ai.billing_entitlement WHERE owner_iid = $1")
        .bind(buyer)
        .execute(&pool)
        .await;
}

#[tokio::test(flavor = "current_thread")]
#[ignore = "requires C35_TEST_DB=1 and YSQL"]
async fn prepaid_credit_adds_wallet_balance() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    let issuer = test_user_insert(&pool, "voucher-issuer-cr").await;
    seed_finance_issuer(&pool, issuer).await;
    let buyer = 33000_i64;
    let start_balance = 10_000.0;
    test_billing_account(&pool, buyer, start_balance).await;

    let code = format!("CRPRE{}", c35_store::snowflake_id());
    let credit = 75_000.0;
    let issue = billing_voucher_issue(
        &pool,
        issuer,
        ReqBillingVoucherIssue {
            kind: "credit".into(),
            plan_slug: String::new(),
            duration_months: 0,
            credit_idr: credit,
            face_value_idr: credit,
            max_uses: 1,
            expires_at_ms: 0,
            payment_ref: String::new(),
            code: code.clone(),
            name: "Credit pack".into(),
            scope: "user".into(),
            billing_period: "monthly".into(),
            list_price_idr: 0.0,
            alien_pool_limit_idr: 0.0,
            frontier_pool_limit_idr: 0.0,
            quantity: 1,
        },
    )
    .await
    .expect("issue");

    billing_package_redeem(&pool, buyer, &issue.code)
        .await
        .expect("redeem");

    let balance_after = sqlx::query_scalar::<_, f64>(
        "SELECT balance_idr::float8 FROM ai.billing_account WHERE owner_iid = $1 AND deleted_ts IS NULL",
    )
    .bind(buyer)
    .fetch_one(&pool)
    .await
    .expect("balance");
    assert!((balance_after - (start_balance + credit)).abs() < 1.0);

    test_user_cleanup(&pool, issuer).await;
    let _ = sqlx::query("DELETE FROM ai.referral_code WHERE code = $1")
        .bind(&issue.code)
        .execute(&pool)
        .await;
    let _ = sqlx::query("DELETE FROM ai.billing_entitlement WHERE owner_iid = $1")
        .bind(buyer)
        .execute(&pool)
        .await;
}
