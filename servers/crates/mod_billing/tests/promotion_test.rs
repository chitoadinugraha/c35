//! Integration tests for billing promotions.
//! Run: C35_TEST_DB=1 cargo test -p c35_mod_billing --test promotion_test -- --ignored

mod common;

use chrono::Utc;
use c35_mod_billing::{
    billing_promotion_claim, billing_promotion_create, billing_promotion_get, PromotionCreateFields,
    SIGNUP_TRIAL_ALIEN_IDR, SIGNUP_TRIAL_FRONTIER_IDR,
};
use common::{
    active_window, db_tests_enabled, expired_window, promo_code, test_pool, test_promotion_cleanup,
    test_user_cleanup, test_user_insert,
};

async fn test_admin_insert(pool: &sqlx::PgPool, label: &str) -> i64 {
    let id = c35_store::snowflake_id();
    let meta = serde_json::json!({ "global_roles": ["partner"] });
    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, name, owner_iid, meta, created_ts, updated_ts)
        VALUES ($1, 'user', '', $2, $1, $3::jsonb, NOW(), NOW())
        "#,
    )
    .bind(id)
    .bind(label)
    .bind(meta)
    .execute(pool)
    .await
    .expect("insert admin user");
    id
}

fn ms_pair(from: chrono::DateTime<Utc>, to: chrono::DateTime<Utc>) -> (i64, i64) {
    (from.timestamp_millis(), to.timestamp_millis())
}

#[tokio::test(flavor = "current_thread")]
#[ignore = "requires C35_TEST_DB=1 and YSQL"]
async fn custom_package_created_by_iid_stored() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    let creator = test_admin_insert(&pool, "promo-creator").await;
    let code = promo_code("CUST");
    let promo_id = billing_promotion_create(
        &pool,
        creator,
        PromotionCreateFields {
            code: code.clone(),
            promo_type: "custom_package".into(),
            audience: "single".into(),
            name: "sales deal".into(),
            base_plan_slug: "lite".into(),
            pool_multiplier: 1.0,
            alien_pool_idr: 50_000.0,
            frontier_pool_idr: 10_000.0,
            duration_days: 30,
            duration_minutes: 0,
            max_claims_total: 1,
            max_claims_per_email: 1,
            valid_from_ms: 0,
            valid_to_ms: 0,
            scope: "user".into(),
            is_active: true,
        },
    )
    .await
    .expect("create");

    let promo = billing_promotion_get(&pool, &code)
        .await
        .expect("lookup")
        .expect("promotion row");
    assert_eq!(promo.id, promo_id);
    assert_eq!(promo.created_by_iid, creator);

    test_promotion_cleanup(&pool, promo_id).await;
    test_user_cleanup(&pool, creator).await;
}

#[tokio::test(flavor = "current_thread")]
#[ignore = "requires C35_TEST_DB=1 and YSQL"]
async fn max_claims_per_email_blocks_second_email() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    let creator = test_admin_insert(&pool, "promo-email-cap").await;
    let user_a = test_user_insert(&pool, "promo-claim-a").await;
    let user_b = test_user_insert(&pool, "promo-claim-b").await;
    let code = promo_code("EMAIL");
    let (from, to) = active_window();
    let (valid_from_ms, valid_to_ms) = ms_pair(from, to);
    let promo_id = billing_promotion_create(
        &pool,
        creator,
        PromotionCreateFields {
            code: code.clone(),
            promo_type: "custom_package".into(),
            audience: "multi".into(),
            name: "email cap".into(),
            base_plan_slug: "lite".into(),
            pool_multiplier: 1.0,
            alien_pool_idr: 0.0,
            frontier_pool_idr: 0.0,
            duration_days: 7,
            duration_minutes: 0,
            max_claims_total: 0,
            max_claims_per_email: 1,
            valid_from_ms,
            valid_to_ms,
            scope: "user".into(),
            is_active: true,
        },
    )
    .await
    .expect("create");

    billing_promotion_claim(&pool, user_a, "alice@example.com", &code)
        .await
        .expect("first claim");
    let err = billing_promotion_claim(&pool, user_b, "alice@example.com", &code)
        .await
        .expect_err("second email claim");
    assert!(err.contains("email already claimed"));

    test_promotion_cleanup(&pool, promo_id).await;
    for u in [creator, user_a, user_b] {
        test_user_cleanup(&pool, u).await;
    }
}

#[tokio::test(flavor = "current_thread")]
#[ignore = "requires C35_TEST_DB=1 and YSQL"]
async fn max_claims_total_on_multi_audience() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    let creator = test_admin_insert(&pool, "promo-total-cap").await;
    let users = [
        test_user_insert(&pool, "promo-total-1").await,
        test_user_insert(&pool, "promo-total-2").await,
        test_user_insert(&pool, "promo-total-3").await,
    ];
    let code = promo_code("MULTI");
    let (from, to) = active_window();
    let (valid_from_ms, valid_to_ms) = ms_pair(from, to);
    let promo_id = billing_promotion_create(
        &pool,
        creator,
        PromotionCreateFields {
            code: code.clone(),
            promo_type: "custom_package".into(),
            audience: "multi".into(),
            name: "multi cap".into(),
            base_plan_slug: "lite".into(),
            pool_multiplier: 1.0,
            alien_pool_idr: 0.0,
            frontier_pool_idr: 0.0,
            duration_days: 7,
            duration_minutes: 0,
            max_claims_total: 2,
            max_claims_per_email: 1,
            valid_from_ms,
            valid_to_ms,
            scope: "user".into(),
            is_active: true,
        },
    )
    .await
    .expect("create");

    billing_promotion_claim(&pool, users[0], "one@example.com", &code)
        .await
        .expect("claim 1");
    billing_promotion_claim(&pool, users[1], "two@example.com", &code)
        .await
        .expect("claim 2");
    let err = billing_promotion_claim(&pool, users[2], "three@example.com", &code)
        .await
        .expect_err("claim 3");
    assert!(err.contains("claim limit reached"));

    test_promotion_cleanup(&pool, promo_id).await;
    test_user_cleanup(&pool, creator).await;
    for u in users {
        test_user_cleanup(&pool, u).await;
    }
}

#[tokio::test(flavor = "current_thread")]
#[ignore = "requires C35_TEST_DB=1 and YSQL"]
async fn expired_promotion_rejected() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    let creator = test_admin_insert(&pool, "promo-expired").await;
    let user = test_user_insert(&pool, "promo-expired-user").await;
    let code = promo_code("EXPIRED");
    let (from, to) = expired_window();
    let (valid_from_ms, valid_to_ms) = ms_pair(from, to);
    let promo_id = billing_promotion_create(
        &pool,
        creator,
        PromotionCreateFields {
            code: code.clone(),
            promo_type: "custom_package".into(),
            audience: "multi".into(),
            name: "expired".into(),
            base_plan_slug: "lite".into(),
            pool_multiplier: 1.0,
            alien_pool_idr: 0.0,
            frontier_pool_idr: 0.0,
            duration_days: 0,
            duration_minutes: 0,
            max_claims_total: 10,
            max_claims_per_email: 1,
            valid_from_ms,
            valid_to_ms,
            scope: "user".into(),
            is_active: true,
        },
    )
    .await
    .expect("create");

    let err = billing_promotion_claim(&pool, user, "late@example.com", &code)
        .await
        .expect_err("expired claim");
    assert!(err.contains("expired"));

    test_promotion_cleanup(&pool, promo_id).await;
    test_user_cleanup(&pool, creator).await;
    test_user_cleanup(&pool, user).await;
}

#[tokio::test(flavor = "current_thread")]
#[ignore = "requires C35_TEST_DB=1 and YSQL"]
async fn signup_trial_applies_quarter_lite_pools() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    let creator = test_admin_insert(&pool, "promo-trial").await;
    let user = test_user_insert(&pool, "promo-trial-user").await;
    let code = promo_code("TRIAL");
    let (from, to) = active_window();
    let (valid_from_ms, valid_to_ms) = ms_pair(from, to);

    let promo_id = billing_promotion_create(
        &pool,
        creator,
        PromotionCreateFields {
            code: code.clone(),
            promo_type: "signup_trial".into(),
            audience: "multi".into(),
            name: "signup trial".into(),
            base_plan_slug: "lite".into(),
            pool_multiplier: 0.25,
            alien_pool_idr: 0.0,
            frontier_pool_idr: 0.0,
            duration_days: 7,
            duration_minutes: 0,
            max_claims_total: 0,
            max_claims_per_email: 1,
            valid_from_ms,
            valid_to_ms,
            scope: "user".into(),
            is_active: true,
        },
    )
    .await
    .expect("create");

    let claim = billing_promotion_claim(&pool, user, "trial@example.com", &code)
        .await
        .expect("claim trial");
    assert!((claim.alien_pool_limit_idr - SIGNUP_TRIAL_ALIEN_IDR).abs() < 0.01);
    assert!((claim.frontier_pool_limit_idr - SIGNUP_TRIAL_FRONTIER_IDR).abs() < 0.01);
    assert_eq!(claim.alien_pool_limit_idr, 25_000.0);
    assert_eq!(claim.frontier_pool_limit_idr, 5_000.0);
    assert!(claim.expires_ts_ms > Utc::now().timestamp_millis());

    test_promotion_cleanup(&pool, promo_id).await;
    test_user_cleanup(&pool, creator).await;
    test_user_cleanup(&pool, user).await;
}
