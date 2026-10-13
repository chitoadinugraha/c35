//! billing.voucher + billing.redeem tool execution against YSQL when C35_TEST_DB=1.
//! Run: C35_TEST_DB=1 cargo test -p c35_mod_chat --test voucher_tool_test -- --ignored

use c35_mod_chat::tools::builtin::{billing_redeem_tool_exec, billing_voucher_tool_exec};
use c35_mod_chat::tools::ToolContext;
use c35_mod_chat::MentionContext;
use c35_store::{migrate_apply, pool_connect, snowflake_id};
use reqwest::Client;
use serde_json::json;
use sqlx::PgPool;
use tokio::sync::OnceCell;

static SCHEMA_READY: OnceCell<()> = OnceCell::const_new();

fn db_tests_enabled() -> bool {
    std::env::var("C35_TEST_DB").ok().as_deref() == Some("1")
}

async fn schema_ready(pool: &PgPool) -> bool {
    sqlx::query_scalar::<_, bool>("SELECT to_regclass('ai.billing_voucher_redeem') IS NOT NULL")
        .fetch_one(pool)
        .await
        .unwrap_or(false)
}

async fn test_pool() -> PgPool {
    std::env::set_var("PG_MAX_CONNECTIONS", "4");
    let pool = pool_connect().await.expect("pool_connect");
    SCHEMA_READY
        .get_or_init(|| async {
            if !schema_ready(&pool).await {
                migrate_apply(&pool).await.expect("migrate_apply");
            }
        })
        .await;
    pool
}

async fn seed_finance_role(pool: &PgPool, iid: i64) {
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

fn tool_ctx(pool: PgPool, owner_iid: i64) -> ToolContext {
    ToolContext::new(
        pool,
        None,
        owner_iid,
        0,
        None,
        None,
        MentionContext::empty(),
        vec![],
        "",
        "en",
        "",
        "",
        "",
        "",
        "test-req",
        Client::new(),
    )
}

#[tokio::test(flavor = "current_thread")]
#[ignore = "requires C35_TEST_DB=1 and YSQL"]
async fn voucher_tool_issue_list_void_redeem_roundtrip() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    let issuer = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, name, owner_iid, created_ts, updated_ts)
        VALUES ($1, 'user', '', 'voucher-tool-issuer', $1, NOW(), NOW())
        "#,
    )
    .bind(issuer)
    .execute(&pool)
    .await
    .expect("issuer");
    seed_finance_role(&pool, issuer).await;

    let buyer = 33000_i64;
    let code = format!("VTOOL{}", snowflake_id());
    let ctx_issuer = tool_ctx(pool.clone(), issuer);

    let issue = billing_voucher_tool_exec(
        &ctx_issuer,
        &json!({
            "action": "issue",
            "kind": "credit",
            "code": code,
            "name": "Tool test 100k",
            "face_value_idr": 100_000.0,
            "credit_idr": 100_000.0,
        }),
    )
    .await
    .expect("issue exec");
    assert_eq!(issue.get("ok"), Some(&json!(true)));
    assert!(issue.get("codes").is_some());

    let list = billing_voucher_tool_exec(&ctx_issuer, &json!({ "action": "list" }))
        .await
        .expect("list");
    assert_eq!(list.get("ok"), Some(&json!(true)));
    let items = list.get("items").and_then(|v| v.as_array()).expect("items");
    assert!(items.iter().any(|row| row.get("code") == Some(&json!(code))));

    let ctx_buyer = tool_ctx(pool.clone(), buyer);
    let redeem = billing_redeem_tool_exec(&ctx_buyer, &json!({ "code": code }))
        .await
        .expect("redeem");
    assert_eq!(redeem.get("ok"), Some(&json!(true)));
    assert!(redeem.get("entitlement_id").is_some() || redeem.get("balance_idr").is_some());

    let hist = billing_voucher_tool_exec(&ctx_issuer, &json!({ "action": "redeem_history", "limit": 20 }))
        .await
        .expect("history");
    assert_eq!(hist.get("ok"), Some(&json!(true)));

    let code2 = format!("VVOID{}", snowflake_id());
    billing_voucher_tool_exec(
        &ctx_issuer,
        &json!({
            "action": "issue",
            "kind": "credit",
            "code": code2,
            "name": "Void me",
            "face_value_idr": 50_000.0,
            "credit_idr": 50_000.0,
        }),
    )
    .await
    .expect("issue2");
    let voided = billing_voucher_tool_exec(&ctx_issuer, &json!({ "action": "void", "code": code2 }))
        .await
        .expect("void");
    assert_eq!(voided.get("ok"), Some(&json!(true)));

    let _ = sqlx::query("DELETE FROM ai.referral_code WHERE code = ANY($1)")
        .bind(&[code, code2])
        .execute(&pool)
        .await;
    let _ = sqlx::query("DELETE FROM ai.identity WHERE id = $1")
        .bind(issuer)
        .execute(&pool)
        .await;
}
