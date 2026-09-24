use anyhow::Result;
use c35_proto::ReqPrompt;
use serde_json::Value;
use sqlx::types::Json;
use sqlx::PgPool;

use super::checkpoint::{PROMPT_RUN_MAX_TURNS_DEFAULT, PROMPT_RUN_MAX_DELIVER};

#[derive(Clone, Debug)]
pub struct PromptRunRow {
    pub req_id: String,
    pub chat_id: i64,
    pub owner_iid: i64,
    pub parent_req_id: Option<String>,
    pub kind: String,
    pub status: String,
    pub topic_id: String,
    pub device_iid: i64,
    pub text: String,
    pub mention_ids_json: Json<Value>,
    pub tool_mode: String,
    pub model: String,
    pub attachments_json: String,
    pub locale: String,
    pub cancel_requested: bool,
    pub turn_count: i32,
    pub max_turns: i32,
    pub fail_class: Option<String>,
    pub fail_reason: Option<String>,
    pub checkpoint_json: Json<Value>,
    pub budget_usd_cap: f64,
    pub accumulated_cost_usd: f64,
    pub tokens_in: i32,
    pub tokens_out: i32,
    pub cost_usd: f64,
    pub duration_ms: i32,
    pub lease_pod: Option<String>,
    pub delivery_count: i32,
}

pub fn prompt_run_row_new(req_id: &str, owner_iid: i64, chat_id: i64, req: &ReqPrompt, locale: &str) -> PromptRunRow {
    let mention_ids: Value = serde_json::to_value(&req.mention_ids).unwrap_or(Value::Array(vec![]));
    let device_iid = req.device_iids.first().copied().unwrap_or(0);
    PromptRunRow {
        req_id: req_id.into(),
        chat_id,
        owner_iid,
        parent_req_id: None,
        kind: "main".into(),
        status: "queued".into(),
        topic_id: if req.topic_id.is_empty() { "general".into() } else { req.topic_id.clone() },
        device_iid,
        text: req.text.clone(),
        mention_ids_json: Json(mention_ids),
        tool_mode: if req.tool_mode.trim().is_empty() { "agent".into() } else { req.tool_mode.trim().into() },
        model: req.model.clone(),
        attachments_json: req.attachments_json.clone(),
        locale: locale.into(),
        cancel_requested: false,
        turn_count: 0,
        max_turns: PROMPT_RUN_MAX_TURNS_DEFAULT,
        fail_class: None,
        fail_reason: None,
        checkpoint_json: Json(serde_json::json!({})),
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

impl PromptRunRow {
    pub fn to_req_prompt(&self) -> ReqPrompt {
        let mention_ids: Vec<String> = self
            .mention_ids_json
            .0
            .as_array()
            .map(|a| a.iter().filter_map(|v| v.as_str().map(str::to_string)).collect())
            .unwrap_or_default();
        ReqPrompt {
            chat_id: self.chat_id,
            model: self.model.clone(),
            text: self.text.clone(),
            attachments_json: self.attachments_json.clone(),
            thinking: String::new(),
            mention_ids,
            topic_id: self.topic_id.clone(),
            tool_mode: self.tool_mode.clone(),
            device_iids: if self.device_iid > 0 { vec![self.device_iid] } else { vec![] },
        }
    }
}

fn f64_col(s: Option<String>) -> f64 {
    s.unwrap_or_else(|| "0".into()).parse().unwrap_or(0.0)
}

fn row_from_db(
    req_id: String,
    chat_id: i64,
    owner_iid: i64,
    parent_req_id: Option<String>,
    kind: String,
    status: String,
    topic_id: String,
    device_iid: i64,
    text: String,
    mention_ids_json: Json<Value>,
    tool_mode: String,
    model: String,
    attachments_json: String,
    locale: String,
    cancel_requested: bool,
    turn_count: i32,
    max_turns: i32,
    fail_class: Option<String>,
    fail_reason: Option<String>,
    checkpoint_json: Json<Value>,
    budget_usd_cap: Option<String>,
    accumulated_cost_usd: Option<String>,
    tokens_in: i32,
    tokens_out: i32,
    cost_usd: Option<String>,
    duration_ms: i32,
    lease_pod: Option<String>,
    delivery_count: i32,
) -> PromptRunRow {
    PromptRunRow {
        req_id,
        chat_id,
        owner_iid,
        parent_req_id,
        kind,
        status,
        topic_id,
        device_iid,
        text,
        mention_ids_json,
        tool_mode,
        model,
        attachments_json,
        locale,
        cancel_requested,
        turn_count,
        max_turns,
        fail_class,
        fail_reason,
        checkpoint_json,
        budget_usd_cap: f64_col(budget_usd_cap),
        accumulated_cost_usd: f64_col(accumulated_cost_usd),
        tokens_in,
        tokens_out,
        cost_usd: f64_col(cost_usd),
        duration_ms,
        lease_pod,
        delivery_count,
    }
}

pub async fn prompt_run_insert(pool: &PgPool, row: &PromptRunRow) -> Result<()> {
    sqlx::query(
        r#"
        INSERT INTO ai.prompt_run (
            req_id, chat_id, owner_iid, parent_req_id, kind, status, topic_id, device_iid,
            text, mention_ids_json, tool_mode, model, attachments_json, locale,
            cancel_requested, turn_count, max_turns, checkpoint_json, budget_usd_cap,
            accumulated_cost_usd, tokens_in, tokens_out, cost_usd, duration_ms, delivery_count,
            created_ts, updated_ts
        )
        VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8,
            $9, $10, $11, $12, $13, $14,
            $15, $16, $17, $18, $19,
            $20, $21, $22, $23, $24, $25,
            NOW(), NOW()
        )
        ON CONFLICT (req_id) DO NOTHING
        "#,
    )
    .bind(&row.req_id)
    .bind(row.chat_id)
    .bind(row.owner_iid)
    .bind(&row.parent_req_id)
    .bind(&row.kind)
    .bind(&row.status)
    .bind(&row.topic_id)
    .bind(row.device_iid)
    .bind(&row.text)
    .bind(&row.mention_ids_json)
    .bind(&row.tool_mode)
    .bind(&row.model)
    .bind(&row.attachments_json)
    .bind(&row.locale)
    .bind(row.cancel_requested)
    .bind(row.turn_count)
    .bind(row.max_turns)
    .bind(&row.checkpoint_json)
    .bind(row.budget_usd_cap)
    .bind(row.accumulated_cost_usd)
    .bind(row.tokens_in)
    .bind(row.tokens_out)
    .bind(row.cost_usd)
    .bind(row.duration_ms)
    .bind(row.delivery_count)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn prompt_run_get(pool: &PgPool, req_id: &str) -> Result<Option<PromptRunRow>> {
    use sqlx::Row;
    let row = sqlx::query(
        r#"
        SELECT
            req_id, chat_id, owner_iid, parent_req_id, kind, status, topic_id, device_iid,
            text, mention_ids_json, tool_mode, model, attachments_json, locale,
            cancel_requested, turn_count, max_turns, fail_class, fail_reason, checkpoint_json,
            budget_usd_cap::text, accumulated_cost_usd::text,
            tokens_in, tokens_out, cost_usd::text, duration_ms, lease_pod, delivery_count
        FROM ai.prompt_run
        WHERE req_id = $1
        "#,
    )
    .bind(req_id)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(|r| {
        row_from_db(
            r.try_get("req_id").unwrap_or_default(),
            r.try_get("chat_id").unwrap_or(0),
            r.try_get("owner_iid").unwrap_or(0),
            r.try_get("parent_req_id").ok(),
            r.try_get("kind").unwrap_or_default(),
            r.try_get("status").unwrap_or_default(),
            r.try_get("topic_id").unwrap_or_default(),
            r.try_get("device_iid").unwrap_or(0),
            r.try_get("text").unwrap_or_default(),
            r.try_get("mention_ids_json").unwrap_or(Json(Value::Array(vec![]))),
            r.try_get("tool_mode").unwrap_or_default(),
            r.try_get("model").unwrap_or_default(),
            r.try_get("attachments_json").unwrap_or_default(),
            r.try_get("locale").unwrap_or_default(),
            r.try_get("cancel_requested").unwrap_or(false),
            r.try_get("turn_count").unwrap_or(0),
            r.try_get("max_turns").unwrap_or(PROMPT_RUN_MAX_TURNS_DEFAULT),
            r.try_get("fail_class").ok(),
            r.try_get("fail_reason").ok(),
            r.try_get("checkpoint_json").unwrap_or(Json(Value::Object(Default::default()))),
            r.try_get::<Option<String>, _>("budget_usd_cap").ok().flatten(),
            r.try_get::<Option<String>, _>("accumulated_cost_usd").ok().flatten(),
            r.try_get("tokens_in").unwrap_or(0),
            r.try_get("tokens_out").unwrap_or(0),
            r.try_get::<Option<String>, _>("cost_usd").ok().flatten(),
            r.try_get("duration_ms").unwrap_or(0),
            r.try_get("lease_pod").ok(),
            r.try_get("delivery_count").unwrap_or(0),
        )
    }))
}

pub async fn prompt_run_status_set(
    pool: &PgPool,
    req_id: &str,
    status: &str,
    fail_class: Option<&str>,
    fail_reason: Option<&str>,
) -> Result<()> {
    sqlx::query(
        r#"
        UPDATE ai.prompt_run
        SET status = $2, fail_class = $3, fail_reason = $4, updated_ts = NOW()
        WHERE req_id = $1
        "#,
    )
    .bind(req_id)
    .bind(status)
    .bind(fail_class)
    .bind(fail_reason)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn prompt_run_checkpoint_save(
    pool: &PgPool,
    req_id: &str,
    checkpoint: &Value,
    turn_count: i32,
    tokens_in: i32,
    tokens_out: i32,
    cost_usd: f64,
) -> Result<()> {
    sqlx::query(
        r#"
        UPDATE ai.prompt_run
        SET checkpoint_json = $2, turn_count = $3, tokens_in = $4, tokens_out = $5,
            accumulated_cost_usd = $6, updated_ts = NOW()
        WHERE req_id = $1
        "#,
    )
    .bind(req_id)
    .bind(Json(checkpoint.clone()))
    .bind(turn_count)
    .bind(tokens_in)
    .bind(tokens_out)
    .bind(cost_usd)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn prompt_run_cancel_request(pool: &PgPool, req_id: &str) -> Result<bool> {
    let r = sqlx::query(
        r#"
        UPDATE ai.prompt_run
        SET cancel_requested = TRUE, updated_ts = NOW()
        WHERE req_id = $1 AND status IN ('queued', 'running', 'waiting_child')
        "#,
    )
    .bind(req_id)
    .execute(pool)
    .await?;
    Ok(r.rows_affected() > 0)
}

pub async fn prompt_run_cancel_children(pool: &PgPool, parent_req_id: &str) -> Result<()> {
    sqlx::query(
        r#"
        UPDATE ai.prompt_run
        SET cancel_requested = TRUE, updated_ts = NOW()
        WHERE parent_req_id = $1 AND status IN ('queued', 'running', 'waiting_child')
        "#,
    )
    .bind(parent_req_id)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn prompt_run_is_cancelled(pool: &PgPool, req_id: &str) -> Result<bool> {
    let row = sqlx::query_as::<_, (bool,)>(
        "SELECT cancel_requested FROM ai.prompt_run WHERE req_id = $1",
    )
    .bind(req_id)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(|r| r.0).unwrap_or(false))
}

pub async fn prompt_run_lease_touch(pool: &PgPool, req_id: &str, pod: &str, ttl_secs: i64) -> Result<()> {
    sqlx::query(
        r#"
        UPDATE ai.prompt_run
        SET lease_pod = $2, lease_expires_ts = NOW() + make_interval(secs => $3::double precision),
            status = CASE WHEN status = 'queued' THEN 'running' ELSE status END,
            updated_ts = NOW()
        WHERE req_id = $1
        "#,
    )
    .bind(req_id)
    .bind(pod)
    .bind(ttl_secs as f64)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn prompt_run_delivery_inc(pool: &PgPool, req_id: &str) -> Result<i32> {
    let row = sqlx::query_as::<_, (i32,)>(
        r#"
        UPDATE ai.prompt_run
        SET delivery_count = delivery_count + 1, updated_ts = NOW()
        WHERE req_id = $1
        RETURNING delivery_count
        "#,
    )
    .bind(req_id)
    .fetch_one(pool)
    .await?;
    Ok(row.0)
}

pub async fn prompt_run_finish(
    pool: &PgPool,
    req_id: &str,
    status: &str,
    tokens_in: i32,
    tokens_out: i32,
    cost_usd: f64,
    duration_ms: i32,
    fail_class: Option<&str>,
    fail_reason: Option<&str>,
) -> Result<()> {
    sqlx::query(
        r#"
        UPDATE ai.prompt_run
        SET status = $2, tokens_in = $3, tokens_out = $4, cost_usd = $5, duration_ms = $6,
            fail_class = $7, fail_reason = $8, updated_ts = NOW()
        WHERE req_id = $1
        "#,
    )
    .bind(req_id)
    .bind(status)
    .bind(tokens_in)
    .bind(tokens_out)
    .bind(cost_usd)
    .bind(duration_ms)
    .bind(fail_class)
    .bind(fail_reason)
    .execute(pool)
    .await?;
    Ok(())
}

pub fn prompt_run_over_max_deliver(count: i32) -> bool {
    count > PROMPT_RUN_MAX_DELIVER
}

pub fn prompt_run_is_terminal(status: &str) -> bool {
    matches!(status, "done" | "failed" | "cancelled")
}

pub fn prompt_run_kind_default(topic_id: &str) -> &'static str {
    match topic_id {
        "research" => "research",
        "computer_use" => "computer_use",
        "web.builder" | "site_build" => "site_build",
        _ => "research",
    }
}

pub async fn prompt_run_summary(pool: &PgPool, req_id: &str) -> Result<String> {
    let msg = sqlx::query_scalar::<_, Option<String>>(
        r#"
        SELECT content
        FROM ai.chat_msg
        WHERE req_id = $1 AND role = 'assistant' AND deleted_ts IS NULL
        ORDER BY created_ts DESC
        LIMIT 1
        "#,
    )
    .bind(req_id)
    .fetch_optional(pool)
    .await?;
    Ok(msg.flatten().unwrap_or_default())
}

#[derive(Debug, Clone)]
pub struct PromptRunActiveDiag {
    pub req_id: String,
    pub owner_iid: i64,
    pub status: String,
    pub lease_pod: Option<String>,
    pub turn_count: i32,
    pub prompt_preview: String,
}

pub async fn prompt_run_list_active(pool: &PgPool) -> Result<Vec<PromptRunActiveDiag>> {
    let rows = sqlx::query_as::<_, (String, i64, String, Option<String>, i32, String)>(
        r#"
        SELECT req_id, owner_iid, status, lease_pod, turn_count, left(text, 200)
        FROM ai.prompt_run
        WHERE status IN ('queued', 'running', 'waiting_child')
        ORDER BY updated_ts DESC
        LIMIT 32
        "#,
    )
    .fetch_all(pool)
    .await?;
    Ok(rows
        .into_iter()
        .map(
            |(req_id, owner_iid, status, lease_pod, turn_count, prompt_preview)| PromptRunActiveDiag {
                req_id,
                owner_iid,
                status,
                lease_pod,
                turn_count,
                prompt_preview,
            },
        )
        .collect())
}

pub async fn prompt_run_list_queued(pool: &PgPool) -> Result<Vec<(String, i64, i64)>> {
    let rows = sqlx::query_as::<_, (String, i64, i64)>(
        r#"
        SELECT req_id, owner_iid, chat_id
        FROM ai.prompt_run
        WHERE status = 'queued'
        ORDER BY created_ts
        "#,
    )
    .fetch_all(pool)
    .await?;
    Ok(rows)
}

pub async fn prompt_run_wait_terminal(
    pool: &PgPool,
    req_id: &str,
    timeout: std::time::Duration,
) -> anyhow::Result<PromptRunRow> {
    use std::time::Instant;
    let deadline = Instant::now() + timeout;
    while Instant::now() < deadline {
        if let Some(row) = prompt_run_get(pool, req_id).await? {
            if prompt_run_is_terminal(&row.status) {
                return Ok(row);
            }
        }
        tokio::time::sleep(std::time::Duration::from_millis(500)).await;
    }
    anyhow::bail!("delegate child timed out waiting for terminal status")
}
