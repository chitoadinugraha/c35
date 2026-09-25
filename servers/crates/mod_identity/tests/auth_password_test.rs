use std::sync::Arc;
use axum::{
    body::{to_bytes, Body},
    http::{Request, StatusCode},
};
use c35_ctx::{AppState, OAuthStore};
use c35_mod_identity::{
    alien_id_valid, auth_router, hash_password, referral_code_is_special, referral_code_norm,
    verify_password,
};
use serde_json::Value;
use tower::ServiceExt;

#[test]
fn test_password_hash_and_verify() {
    let pwd = "SuperSecretPassword123!";
    let hash = hash_password(pwd).expect("hash");
    assert!(verify_password(pwd, &hash));
    assert!(!verify_password("WrongPassword!", &hash));
}

#[test]
fn test_alien_id_validation() {
    assert!(alien_id_valid("alice"));
    assert!(alien_id_valid("john_doe-123"));
    assert!(!alien_id_valid(""));
    assert!(!alien_id_valid("Alice")); // no uppercase
    assert!(!alien_id_valid("alice smith")); // no spaces
    assert!(!alien_id_valid("alice@home")); // no @
}

#[test]
fn test_referral_code_special() {
    assert_eq!(referral_code_norm("  chito-keren-sekali-9999 "), "CHITOKERENSEKALI9999");
    assert!(referral_code_is_special("CHITOKERENSEKALI9999"));
    assert!(referral_code_is_special("chitokerensekali9999"));
    assert!(!referral_code_is_special("SOMEOTHERCODE"));
}

#[tokio::test]
async fn test_db_auth_signup_signin_referral_flow() {
    let pool = match c35_store::pool_connect().await {
        Ok(p) => p,
        Err(e) => {
            eprintln!("Skipping DB test, cannot connect: {e}");
            return;
        }
    };

    let state = AppState {
        pool: pool.clone(),
        nats: None,
        jwt_secret: "test_jwt_secret_dev".into(),
        oauth: Arc::new(OAuthStore::default()),
        cas_secret: "test_cas_secret".into(),
        cas_dir: std::env::temp_dir().join("c35_test_cas"),
        public_origin: "https://api.alienai.id".into(),
    };

    let router = auth_router().with_state(state.clone());

    let ts = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_millis();

    // 1. Sign up WITHOUT referral code
    let email_no_ref = format!("test_noref_{ts}@alienai.id");
    let signup_payload = serde_json::json!({
        "name": "Test User No Ref",
        "email": email_no_ref,
        "password": "Password123!"
    });

    let res = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/v1/auth/signup")
                .header("content-type", "application/json")
                .body(Body::from(serde_json::to_vec(&signup_payload).unwrap()))
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(res.status(), StatusCode::OK);
    let body_bytes = to_bytes(res.into_body(), usize::MAX).await.unwrap();
    let body: Value = serde_json::from_slice(&body_bytes).unwrap();
    assert_eq!(body["ok"], true);
    let token = body["token"].as_str().unwrap().to_string();
    let uid = body["identity"]["id"].as_i64().unwrap();
    assert_eq!(body["identity"]["email"], email_no_ref);
    // Alien ID should be null / handle empty
    assert!(body["identity"]["alien_id"].is_null() || body["identity"]["alien_id"] == "");
    assert_eq!(body["identity"]["handle"], "");
    // Default balance should be 10.0 USD = 176,300 IDR
    let balance_idr = body["identity"]["balance_idr"].as_f64().unwrap();
    assert_eq!(balance_idr, 176300.0);
    assert_eq!(body["identity"]["balance_usd"].as_f64().unwrap(), 10.0);
    assert!(body["identity"]["referred_by_iid"].is_null());

    // 2. Sign in with email and password
    let signin_payload = serde_json::json!({
        "login": email_no_ref,
        "password": "Password123!"
    });
    let res = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/v1/auth/signin")
                .header("content-type", "application/json")
                .body(Body::from(serde_json::to_vec(&signin_payload).unwrap()))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::OK);
    let body: Value = serde_json::from_slice(&to_bytes(res.into_body(), usize::MAX).await.unwrap()).unwrap();
    assert_eq!(body["ok"], true);
    assert_eq!(body["identity"]["id"].as_i64().unwrap(), uid);

    // 3. Claim referral code via POST /v1/auth/referral/claim
    // This should add Rp 10.000 bonus
    let claim_res = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/v1/auth/referral/claim")
                .header("authorization", format!("Bearer {token}"))
                .header("content-type", "application/json")
                .body(Body::from(r#"{"code":"CHITOKERENSEKALI9999"}"#))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(claim_res.status(), StatusCode::OK);
    let claim_body: Value = serde_json::from_slice(&to_bytes(claim_res.into_body(), usize::MAX).await.unwrap()).unwrap();
    assert_eq!(claim_body["ok"], true);
    assert_eq!(claim_body["bonus_idr"].as_f64().unwrap(), 10000.0);

    // Verify balance after claim via GET /v1/auth/me: 176300 + 10000 = 186300 IDR
    let me_res = router
        .clone()
        .oneshot(
            Request::builder()
                .method("GET")
                .uri("/v1/auth/me")
                .header("authorization", format!("Bearer {token}"))
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(me_res.status(), StatusCode::OK);
    let me_body: Value = serde_json::from_slice(&to_bytes(me_res.into_body(), usize::MAX).await.unwrap()).unwrap();
    assert_eq!(me_body["ok"], true);
    assert_eq!(me_body["identity"]["balance_idr"].as_f64().unwrap(), 186300.0);
    assert_eq!(me_body["identity"]["referred_by_iid"].as_i64().unwrap(), 99000);

    // 4. Claim Alien ID via POST /v1/auth/alien_id/claim
    let test_alien_id = format!("alienid{ts}");
    let claim_id_res = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/v1/auth/alien_id/claim")
                .header("authorization", format!("Bearer {token}"))
                .header("content-type", "application/json")
                .body(Body::from(serde_json::to_vec(&serde_json::json!({
                    "alien_id": test_alien_id
                })).unwrap()))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(claim_id_res.status(), StatusCode::OK);
    let claim_id_body: Value = serde_json::from_slice(&to_bytes(claim_id_res.into_body(), usize::MAX).await.unwrap()).unwrap();
    assert_eq!(claim_id_body["ok"], true);
    assert_eq!(claim_id_body["alien_id"], test_alien_id);

    // 5. Sign in using the newly claimed Alien ID!
    let signin_alien_id = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/v1/auth/signin")
                .header("content-type", "application/json")
                .body(Body::from(serde_json::to_vec(&serde_json::json!({
                    "login": test_alien_id,
                    "password": "Password123!"
                })).unwrap()))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(signin_alien_id.status(), StatusCode::OK);
    let signin_id_body: Value = serde_json::from_slice(&to_bytes(signin_alien_id.into_body(), usize::MAX).await.unwrap()).unwrap();
    assert_eq!(signin_id_body["identity"]["alien_id"], test_alien_id);
    assert_eq!(signin_id_body["identity"]["handle"], format!("@{test_alien_id}"));
    assert_eq!(signin_id_body["identity"]["balance_idr"].as_f64().unwrap(), 186300.0);

    // 6. Sign up WITH referral code directly at signup
    let email_with_ref = format!("test_withref_{ts}@alienai.id");
    let signup_ref_payload = serde_json::json!({
        "name": "Test User With Ref",
        "email": email_with_ref,
        "password": "Password123!",
        "referral_code": "CHITOKERENSEKALI9999"
    });
    let res = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/v1/auth/signup")
                .header("content-type", "application/json")
                .body(Body::from(serde_json::to_vec(&signup_ref_payload).unwrap()))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::OK);
    let body: Value = serde_json::from_slice(&to_bytes(res.into_body(), usize::MAX).await.unwrap()).unwrap();
    assert_eq!(body["ok"], true);
    // Balance should immediately include Rp 10.000 bonus: 176300 + 10000 = 186300 IDR
    assert_eq!(body["identity"]["balance_idr"].as_f64().unwrap(), 186300.0);
    assert_eq!(body["identity"]["referred_by_iid"].as_i64().unwrap(), 99000);

    // 7. Test Account (ensure testaccount@alienai.id exists with password and alien_id)
    let test_acc_email = "testaccount@alienai.id";
    let test_acc_pwd = "TestPassword123!";
    let test_acc_id = "testaccount";
    
    // Check if testaccount already exists; if not, sign up or update
    let signin_test = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/v1/auth/signin")
                .header("content-type", "application/json")
                .body(Body::from(serde_json::to_vec(&serde_json::json!({
                    "login": test_acc_email,
                    "password": test_acc_pwd
                })).unwrap()))
                .unwrap(),
        )
        .await
        .unwrap();

    let _test_token = if signin_test.status() != StatusCode::OK {
        // Sign up test account
        let signup_test = router
            .clone()
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/auth/signup")
                    .header("content-type", "application/json")
                    .body(Body::from(serde_json::to_vec(&serde_json::json!({
                        "name": "Test Account",
                        "email": test_acc_email,
                        "password": test_acc_pwd,
                        "referral_code": "CHITOKERENSEKALI9999"
                    })).unwrap()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(signup_test.status(), StatusCode::OK);
        let b: Value = serde_json::from_slice(&to_bytes(signup_test.into_body(), usize::MAX).await.unwrap()).unwrap();
        let tok = b["token"].as_str().unwrap().to_string();
        
        // Claim alien_id "testaccount"
        let _ = router
            .clone()
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/auth/alien_id/claim")
                    .header("authorization", format!("Bearer {tok}"))
                    .header("content-type", "application/json")
                    .body(Body::from(serde_json::to_vec(&serde_json::json!({
                        "alien_id": test_acc_id,
                        "referral_code": "CHITOKERENSEKALI9999"
                    })).unwrap()))
                    .unwrap(),
            )
            .await;
        tok
    } else {
        let b: Value = serde_json::from_slice(&to_bytes(signin_test.into_body(), usize::MAX).await.unwrap()).unwrap();
        b["token"].as_str().unwrap().to_string()
    };

    // Verify signing in to Test Account with Alien ID
    let signin_via_alien_id = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/v1/auth/signin")
                .header("content-type", "application/json")
                .body(Body::from(serde_json::to_vec(&serde_json::json!({
                    "login": test_acc_id,
                    "password": test_acc_pwd
                })).unwrap()))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(signin_via_alien_id.status(), StatusCode::OK);
    let b: Value = serde_json::from_slice(&to_bytes(signin_via_alien_id.into_body(), usize::MAX).await.unwrap()).unwrap();
    assert_eq!(b["ok"], true);
    assert_eq!(b["identity"]["name"], "Test Account");
    assert_eq!(b["identity"]["email"], test_acc_email);
    assert_eq!(b["identity"]["alien_id"], test_acc_id);
    assert_eq!(b["identity"]["handle"], format!("@{test_acc_id}"));
    assert_eq!(b["identity"]["balance_idr"].as_f64().unwrap(), 186300.0);

    // Verify signing in to Test Account with @handle
    let signin_via_handle = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/v1/auth/signin")
                .header("content-type", "application/json")
                .body(Body::from(serde_json::to_vec(&serde_json::json!({
                    "login": format!("@{test_acc_id}"),
                    "password": test_acc_pwd
                })).unwrap()))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(signin_via_handle.status(), StatusCode::OK);
}

#[tokio::test]
async fn test_referral_code_limits_and_short_lookup() {
    let pool = match c35_store::pool_connect().await {
        Ok(p) => p,
        Err(e) => {
            eprintln!("Skipping DB test, cannot connect: {e}");
            return;
        }
    };

    let state = AppState {
        pool: pool.clone(),
        nats: None,
        jwt_secret: "test_jwt_secret_dev".into(),
        oauth: Arc::new(OAuthStore::default()),
        cas_secret: "test_cas_secret".into(),
        cas_dir: std::env::temp_dir().join("c35_test_cas"),
        public_origin: "https://api.alienai.id".into(),
    };
    let router = auth_router().with_state(state);

    let ts = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_millis();
    let pkg_code = format!("PKG{ts}");
    let lim_code = format!("LIM{ts}");
    let short_code = format!("S{ts}");

    let _ = sqlx::query(
        r#"
        INSERT INTO ai.referral_code (code, issued_by_iid, used_count, expires_at, meta)
        VALUES ($1, 99000, 0, NULL, '{"type":"package","name":"pkg","price_usd":1}'::jsonb)
        ON CONFLICT (code) DO UPDATE SET meta = EXCLUDED.meta, used_count = 0
        "#,
    )
    .bind(&pkg_code)
    .execute(&pool)
    .await;

    let _ = sqlx::query(
        r#"
        INSERT INTO ai.referral_code (code, issued_by_iid, used_count, expires_at, meta)
        VALUES ($1, 99000, 0, NULL, '{"type":"referral","name":"limited","max_uses":1}'::jsonb)
        ON CONFLICT (code) DO UPDATE SET meta = EXCLUDED.meta, used_count = 0
        "#,
    )
    .bind(&lim_code)
    .execute(&pool)
    .await;

    let _ = sqlx::query(
        r#"
        INSERT INTO ai.referral_code (code, issued_by_iid, used_count, expires_at, meta)
        VALUES ($1, 99000, 0, NULL, '{"type":"referral","name":"short"}'::jsonb)
        ON CONFLICT (code) DO UPDATE SET meta = EXCLUDED.meta, used_count = 0
        "#,
    )
    .bind(&short_code)
    .execute(&pool)
    .await;

    let lookup_short = router
        .clone()
        .oneshot(
            Request::builder()
                .method("GET")
                .uri(format!("/v1/auth/referral/lookup?code={short_code}"))
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(lookup_short.status(), StatusCode::OK);
    let short_body: Value = serde_json::from_slice(&to_bytes(lookup_short.into_body(), usize::MAX).await.unwrap()).unwrap();
    assert_eq!(short_body["valid"], true);
    assert_eq!(short_body["issuer_name"].as_str().unwrap().is_empty(), false);

    let lookup_pkg = router
        .clone()
        .oneshot(
            Request::builder()
                .method("GET")
                .uri(format!("/v1/auth/referral/lookup?code={pkg_code}"))
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(lookup_pkg.status(), StatusCode::OK);
    let pkg_body: Value = serde_json::from_slice(&to_bytes(lookup_pkg.into_body(), usize::MAX).await.unwrap()).unwrap();
    assert_eq!(pkg_body["valid"], false);

    let email1 = format!("ref_lim1_{ts}@alienai.id");
    let signup1 = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/v1/auth/signup")
                .header("content-type", "application/json")
                .body(Body::from(serde_json::to_vec(&serde_json::json!({
                    "name": "Ref Lim One",
                    "email": email1,
                    "password": "Password123!",
                    "referral_code": lim_code
                })).unwrap()))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(signup1.status(), StatusCode::OK);

    let email2 = format!("ref_lim2_{ts}@alienai.id");
    let signup2 = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/v1/auth/signup")
                .header("content-type", "application/json")
                .body(Body::from(serde_json::to_vec(&serde_json::json!({
                    "name": "Ref Lim Two",
                    "email": email2,
                    "password": "Password123!",
                    "referral_code": lim_code
                })).unwrap()))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(signup2.status(), StatusCode::BAD_REQUEST);

    let email_pkg = format!("ref_pkg_{ts}@alienai.id");
    let signup_pkg = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/v1/auth/signup")
                .header("content-type", "application/json")
                .body(Body::from(serde_json::to_vec(&serde_json::json!({
                    "name": "Ref Pkg",
                    "email": email_pkg,
                    "password": "Password123!",
                    "referral_code": pkg_code
                })).unwrap()))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(signup_pkg.status(), StatusCode::BAD_REQUEST);

    let _ = sqlx::query("DELETE FROM ai.referral_code WHERE code = ANY($1)")
        .bind(vec![pkg_code, lim_code, short_code])
        .execute(&pool)
        .await;
}
