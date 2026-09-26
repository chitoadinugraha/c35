use c35_mod_chat::prompt_followup::{
    prompt_followup_append_to_contents, prompt_followup_cancel_rpc, prompt_followup_enabled, prompt_followup_put,
};
use c35_mod_chat::prompt_run::{prompt_run_insert, PromptRunRow};
use c35_proto::PromptFollowupKind;
use c35_store::{migrate_apply, pool_connect, snowflake_id};
use serde_json::json;
use sqlx::types::Json;
use sqlx::PgPool;

fn db_tests_enabled() -> bool {
    std::env::var("C35_TEST_DB").ok().as_deref() == Some("1")
}

async fn test_pool() -> PgPool {
    std::env::set_var("PG_MAX_CONNECTIONS", "4");
    pool_connect().await.expect("pool_connect (set YB_* in .env.local)")
}

async fn ensure_schema(pool: &PgPool) {
    let ready = sqlx::query_scalar::<_, bool>("SELECT to_regclass('ai.prompt_followup') IS NOT NULL")
        .fetch_one(pool)
        .await
        .unwrap_or(false);
    if !ready {
        migrate_apply(pool).await.expect("migrate_apply");
    }
}

fn sample_run(req_id: &str, chat_id: i64, owner_iid: i64) -> PromptRunRow {
    PromptRunRow {
        req_id: req_id.into(),
        chat_id,
        owner_iid,
        parent_req_id: None,
        kind: "main".into(),
        status: "running".into(),
        topic_id: "general".into(),
        device_iid: 0,
        text: "hello".into(),
        mention_ids_json: Json(json!([])),
        tool_mode: "agent".into(),
        model: "".into(),
        attachments_json: "[]".into(),
        locale: "".into(),
        cancel_requested: false,
        turn_count: 0,
        max_turns: 100,
        fail_class: None,
        fail_reason: None,
        checkpoint_json: Json(json!({})),
        budget_usd_cap: 0.50,
        accumulated_cost_usd: 0.0,
        tokens_in: 0,
        tokens_out: 0,
        cost_usd: 0.0,
        duration_ms: 0,
        lease_pod: None,
        delivery_count: 0,
    }
}

#[test]
fn append_steers_to_contents() {
    let mut contents = vec![json!({ "role": "user", "parts": [{ "text": "hi" }] })];
    prompt_followup_append_to_contents(&mut contents, &["use postgres".into()]);
    assert_eq!(contents.len(), 2);
    let t = contents[1]["parts"][0]["text"].as_str().unwrap_or("");
    assert!(t.contains("postgres"));
}

#[test]
fn followup_enabled_default_on() {
    std::env::remove_var("C35_PROMPT_FOLLOWUP");
    assert!(prompt_followup_enabled());
}

#[tokio::test]
async fn followup_put_lite_queue_rejected() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    ensure_schema(&pool).await;
    let owner_iid = snowflake_id();
    let chat_id = snowflake_id();
    let req_id = format!("pf-lite-q-{}", snowflake_id());
    prompt_run_insert(&pool, &sample_run(&req_id, chat_id, owner_iid))
        .await
        .expect("insert run");
    let res = prompt_followup_put(
        &pool,
        owner_iid,
        chat_id,
        &req_id,
        "next please",
        "[]",
        PromptFollowupKind::Queue as i32,
        "app",
        None,
    )
    .await
    .expect("put");
    assert!(res.rejected);
    assert_eq!(res.reject_reason, "plan_cap");
    let _ = sqlx::query("DELETE FROM ai.prompt_followup WHERE req_id = $1")
        .bind(&req_id)
        .execute(&pool)
        .await;
    let _ = sqlx::query("DELETE FROM ai.prompt_run WHERE req_id = $1")
        .bind(&req_id)
        .execute(&pool)
        .await;
}

#[tokio::test]
async fn followup_put_steer_cap_and_cancel_queue() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    ensure_schema(&pool).await;
    let owner_iid = snowflake_id();
    let chat_id = snowflake_id();
    let req_id = format!("pf-steer-{}", snowflake_id());
    prompt_run_insert(&pool, &sample_run(&req_id, chat_id, owner_iid))
        .await
        .expect("insert run");
    for i in 0..3 {
        let text = format!("steer {}", i);
        let res = prompt_followup_put(
            &pool,
            owner_iid,
            chat_id,
            &req_id,
            &text,
            "[]",
            PromptFollowupKind::Steer as i32,
            "app",
            None,
        )
        .await
        .expect("put steer");
        assert!(!res.rejected, "steer {} rejected: {}", i, res.reject_reason);
    }
    let capped = prompt_followup_put(
        &pool,
        owner_iid,
        chat_id,
        &req_id,
        "one too many",
        "[]",
        PromptFollowupKind::Steer as i32,
        "app",
        None,
    )
    .await
    .expect("put cap");
    assert!(capped.rejected);
    assert_eq!(capped.reject_reason, "steer_cap");

    let queue_id = snowflake_id().to_string();
    sqlx::query(
        r#"
        INSERT INTO ai.prompt_followup (id, req_id, chat_id, owner_iid, seq, kind, status, text, attachments_json, source)
        VALUES ($1, $2, $3, $4, 99, 'queue', 'pending', 'hold', '[]', 'app')
        "#,
    )
    .bind(&queue_id)
    .bind(&req_id)
    .bind(chat_id)
    .bind(owner_iid)
    .execute(&pool)
    .await
    .expect("insert queue row");
    let (cancel_res, _) = prompt_followup_cancel_rpc(&pool, owner_iid, &queue_id)
        .await
        .expect("cancel");
    assert!(cancel_res.ok);

    let _ = sqlx::query("DELETE FROM ai.prompt_followup WHERE req_id = $1")
        .bind(&req_id)
        .execute(&pool)
        .await;
    let _ = sqlx::query("DELETE FROM ai.prompt_run WHERE req_id = $1")
        .bind(&req_id)
        .execute(&pool)
        .await;
}
