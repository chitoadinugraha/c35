use c35_mod_chat::prompt_run::{
    checkpoint_error_fingerprint, checkpoint_record_error, checkpoint_record_screenshot_hash_hex,
    checkpoint_screenshot_stuck,
    checkpoint_set_fatal, prompt_run_cancel_children, prompt_run_cancel_request,
    prompt_run_checkpoint_save, prompt_run_get, prompt_run_insert, prompt_run_is_cancelled,
    prompt_run_should_stop, prompt_run_status_set, PromptRunRow,
};
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
    let ready = sqlx::query_scalar::<_, bool>("SELECT to_regclass('ai.prompt_run') IS NOT NULL")
        .fetch_one(pool)
        .await
        .unwrap_or(false);
    if !ready {
        migrate_apply(pool).await.expect("migrate_apply");
    }
}

fn sample_row(req_id: &str, chat_id: i64, owner_iid: i64) -> PromptRunRow {
    PromptRunRow {
        req_id: req_id.into(),
        chat_id,
        owner_iid,
        parent_req_id: None,
        kind: "main".into(),
        status: "queued".into(),
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
fn checkpoint_error_fingerprint_stable() {
    let a = checkpoint_error_fingerprint("timeout connecting to device");
    let b = checkpoint_error_fingerprint("timeout connecting to device");
    let c = checkpoint_error_fingerprint("access denied");
    assert_eq!(a, b);
    assert_ne!(a, c);
}

#[test]
fn checkpoint_error_repeat_marks_fatal() {
    let mut ck = json!({});
    checkpoint_record_error(&mut ck, "agent offline");
    checkpoint_record_error(&mut ck, "agent offline");
    assert_eq!(ck["error_count"], 2);
    let row = PromptRunRow {
        req_id: "r".into(),
        chat_id: 1,
        owner_iid: 1,
        parent_req_id: None,
        kind: "main".into(),
        status: "running".into(),
        topic_id: "general".into(),
        device_iid: 0,
        text: "".into(),
        mention_ids_json: Json(json!([])),
        tool_mode: "agent".into(),
        model: "".into(),
        attachments_json: "[]".into(),
        locale: "".into(),
        cancel_requested: false,
        turn_count: 1,
        max_turns: 100,
        fail_class: None,
        fail_reason: None,
        checkpoint_json: Json(ck),
        budget_usd_cap: 0.50,
        accumulated_cost_usd: 0.0,
        tokens_in: 0,
        tokens_out: 0,
        cost_usd: 0.0,
        duration_ms: 0,
        lease_pod: None,
        delivery_count: 0,
    };
    assert_eq!(prompt_run_should_stop(&row), Some("fatal_repeat"));
}

#[test]
fn checkpoint_screenshot_stuck_detects_three_identical() {
    let mut ck = json!({});
    checkpoint_record_screenshot_hash_hex(&mut ck, "abc");
    checkpoint_record_screenshot_hash_hex(&mut ck, "abc");
    assert!(!checkpoint_screenshot_stuck(&ck));
    checkpoint_record_screenshot_hash_hex(&mut ck, "abc");
    assert!(checkpoint_screenshot_stuck(&ck));
    let row = PromptRunRow {
        req_id: "r".into(),
        chat_id: 1,
        owner_iid: 1,
        parent_req_id: None,
        kind: "computer_use".into(),
        status: "running".into(),
        topic_id: "computer_use".into(),
        device_iid: 0,
        text: "".into(),
        mention_ids_json: Json(json!([])),
        tool_mode: "agent".into(),
        model: "".into(),
        attachments_json: "[]".into(),
        locale: "".into(),
        cancel_requested: false,
        turn_count: 1,
        max_turns: 100,
        fail_class: None,
        fail_reason: None,
        checkpoint_json: Json(ck),
        budget_usd_cap: 0.50,
        accumulated_cost_usd: 0.0,
        tokens_in: 0,
        tokens_out: 0,
        cost_usd: 0.0,
        duration_ms: 0,
        lease_pod: None,
        delivery_count: 0,
    };
    assert_eq!(prompt_run_should_stop(&row), Some("stuck_ui"));
}

#[test]
fn should_stop_turn_cap_budget_cancel() {
    let base = sample_row("r", 1, 1);
    let mut turn_cap = base.clone();
    turn_cap.status = "running".into();
    turn_cap.turn_count = 100;
    assert_eq!(prompt_run_should_stop(&turn_cap), Some("turn_cap"));

    let mut budget = base.clone();
    budget.status = "running".into();
    budget.accumulated_cost_usd = 0.50;
    assert_eq!(prompt_run_should_stop(&budget), Some("budget"));

    let mut cancel = base.clone();
    cancel.cancel_requested = true;
    assert_eq!(prompt_run_should_stop(&cancel), Some("cancel"));

    let mut fatal_ck = base.clone();
    fatal_ck.status = "running".into();
    checkpoint_set_fatal(&mut fatal_ck.checkpoint_json.0, "fatal_offline", "agent offline");
    assert_eq!(prompt_run_should_stop(&fatal_ck), Some("fatal_checkpoint"));
}

#[tokio::test]
async fn prompt_run_crud_lifecycle() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    ensure_schema(&pool).await;

    let owner_iid = snowflake_id();
    let chat_id = snowflake_id();
    let req_id = format!("test-{}", snowflake_id());
    let child_req_id = format!("child-{}", snowflake_id());

    let row = sample_row(&req_id, chat_id, owner_iid);
    prompt_run_insert(&pool, &row).await.expect("insert");

    let got = prompt_run_get(&pool, &req_id).await.expect("get").expect("row");
    assert_eq!(got.req_id, req_id);
    assert_eq!(got.status, "queued");

    let ck = json!({"hop": 1});
    prompt_run_checkpoint_save(&pool, &req_id, &ck, 2, 100, 50, 0.12)
        .await
        .expect("checkpoint");
    prompt_run_status_set(&pool, &req_id, "running", None, None)
        .await
        .expect("status running");

    let running = prompt_run_get(&pool, &req_id).await.expect("get").expect("row");
    assert_eq!(running.status, "running");
    assert_eq!(running.turn_count, 2);
    assert_eq!(running.tokens_in, 100);
    assert_eq!(running.tokens_out, 50);
    assert!((running.accumulated_cost_usd - 0.12).abs() < 0.0001);

    let child = PromptRunRow {
        parent_req_id: Some(req_id.clone()),
        req_id: child_req_id.clone(),
        kind: "research".into(),
        status: "queued".into(),
        ..sample_row(&child_req_id, chat_id, owner_iid)
    };
    prompt_run_insert(&pool, &child).await.expect("insert child");

    assert!(!prompt_run_is_cancelled(&pool, &req_id).await.expect("is_cancelled"));
    assert!(prompt_run_cancel_request(&pool, &req_id).await.expect("cancel"));
    assert!(prompt_run_is_cancelled(&pool, &req_id).await.expect("is_cancelled"));

    prompt_run_cancel_children(&pool, &req_id).await.expect("cancel children");
    assert!(prompt_run_is_cancelled(&pool, &child_req_id).await.expect("child cancelled"));

    prompt_run_status_set(&pool, &req_id, "cancelled", None, None)
        .await
        .expect("status cancelled");
    let done = prompt_run_get(&pool, &req_id).await.expect("get").expect("row");
    assert_eq!(done.status, "cancelled");
    assert_eq!(prompt_run_should_stop(&done), Some("cancel"));

    let _ = sqlx::query("DELETE FROM ai.prompt_run WHERE req_id = ANY($1)")
        .bind(vec![req_id, child_req_id])
        .execute(&pool)
        .await;
}
