use c35_mod_chat::prompt_run::{prompt_run_is_terminal, prompt_run_kind_default, PromptRunRow};
use c35_mod_chat::tools::builtin::{delegate_child_row, delegate_result_json};
use serde_json::json;
use sqlx::types::Json;
use c35_mod_chat::{MentionContext, tools::ToolContext};
use reqwest::Client;
use sqlx::PgPool;

fn test_tool_ctx(pool: PgPool, req_id: &str) -> ToolContext {
    ToolContext::new(
        pool,
        None,
        42,
        99,
        None,
        MentionContext::empty(),
        "en",
        "[]",
        req_id,
        Client::new(),
    )
}

#[test]
fn prompt_run_kind_default_maps_topics() {
    assert_eq!(prompt_run_kind_default("research"), "research");
    assert_eq!(prompt_run_kind_default("computer_use"), "computer_use");
    assert_eq!(prompt_run_kind_default("web.builder"), "site_build");
    assert_eq!(prompt_run_kind_default("general"), "research");
}

#[test]
fn prompt_run_is_terminal_statuses() {
    assert!(prompt_run_is_terminal("done"));
    assert!(prompt_run_is_terminal("failed"));
    assert!(prompt_run_is_terminal("cancelled"));
    assert!(!prompt_run_is_terminal("queued"));
    assert!(!prompt_run_is_terminal("running"));
    assert!(!prompt_run_is_terminal("waiting_child"));
}

#[tokio::test]
async fn delegate_child_row_links_parent_and_budget() {
    let pool = PgPool::connect_lazy("postgres://unused").expect("lazy pool");
    let ctx = test_tool_ctx(pool, "parent-req-1");
    let row = delegate_child_row(
        "child-req-1",
        "parent-req-1",
        &ctx,
        "research",
        "Compare Rust vs Go for CLI tools",
        "research",
        "Rust vs Go",
        0,
    );
    assert_eq!(row.parent_req_id.as_deref(), Some("parent-req-1"));
    assert_eq!(row.topic_id, "research");
    assert_eq!(row.kind, "research");
    assert_eq!(row.text, "Compare Rust vs Go for CLI tools");
    assert_eq!(row.budget_usd_cap, 0.20);
    assert_eq!(row.status, "queued");
    assert_eq!(row.checkpoint_json.0["label"], "Rust vs Go");
}

#[test]
fn delegate_result_json_shape() {
    let child = PromptRunRow {
        req_id: "child-1".into(),
        chat_id: 1,
        owner_iid: 2,
        parent_req_id: Some("parent-1".into()),
        kind: "research".into(),
        status: "done".into(),
        topic_id: "research".into(),
        device_iid: 0,
        text: "goal".into(),
        mention_ids_json: Json(json!([])),
        tool_mode: "agent".into(),
        model: String::new(),
        attachments_json: "[]".into(),
        locale: "en".into(),
        cancel_requested: false,
        turn_count: 2,
        max_turns: 100,
        fail_class: None,
        fail_reason: None,
        checkpoint_json: Json(json!({})),
        budget_usd_cap: 0.20,
        accumulated_cost_usd: 0.01,
        tokens_in: 100,
        tokens_out: 50,
        cost_usd: 0.02,
        duration_ms: 1200,
        lease_pod: None,
        delivery_count: 0,
    };
    let out = delegate_result_json(&child, "Child finished.", "delegate.run");
    assert_eq!(out["ok"], true);
    assert_eq!(out["child_req_id"], "child-1");
    assert_eq!(out["summary"], "Child finished.");
    assert_eq!(out["tokens_in"], 100);
    assert_eq!(out["cost_usd"], 0.02);
}

#[tokio::test]
async fn delegate_insert_child_row_db() {
    if std::env::var("C35_TEST_DB").ok().as_deref() != Some("1") {
        return;
    }
    use c35_mod_chat::prompt_run::{prompt_run_get, prompt_run_insert};
    use c35_store::{migrate_apply, pool_connect, snowflake_id};

    let pool = pool_connect().await.expect("pool_connect");
    migrate_apply(&pool).await.expect("migrate_apply");

    let owner_iid = snowflake_id();
    let chat_id = snowflake_id();
    let parent_req_id = snowflake_id().to_string();
    let child_req_id = snowflake_id().to_string();

    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, name, owner_iid, created_ts, updated_ts)
        VALUES ($1, 'user', '', 'delegate-test', $1, NOW(), NOW())
        "#,
    )
    .bind(owner_iid)
    .execute(&pool)
    .await
    .expect("insert identity");

    sqlx::query(
        r#"
        INSERT INTO ai.chat (id, owner_iid, kind, title, created_ts, updated_ts)
        VALUES ($1, $2, 'prompt', 'delegate test', NOW(), NOW())
        "#,
    )
    .bind(chat_id)
    .bind(owner_iid)
    .execute(&pool)
    .await
    .expect("insert chat");

    let ctx = test_tool_ctx(pool.clone(), &parent_req_id);
    let row = delegate_child_row(
        &child_req_id,
        &parent_req_id,
        &ctx,
        "research",
        "Weather in Jakarta",
        "research",
        "Jakarta weather",
        0,
    );
    prompt_run_insert(&pool, &row).await.expect("insert child");

    let loaded = prompt_run_get(&pool, &child_req_id)
        .await
        .expect("get child")
        .expect("child row");
    assert_eq!(loaded.parent_req_id.as_deref(), Some(parent_req_id.as_str()));
    assert_eq!(loaded.topic_id, "research");
    assert_eq!(loaded.text, "Weather in Jakarta");
}
