use std::time::Duration;

use anyhow::bail;
use async_nats::jetstream;
use c35_mod_billing::{
    billing_can_afford_tool, CHILD_BUDGET_USD, CHILD_HOLD_USD, COMPUTER_USE_HOLD_USD,
};
use c35_proto::PromptRunJob;
use c35_store::snowflake_id;
use serde_json::{json, Value};
use sqlx::types::Json;

use crate::prompt_run::{
    prompt_run_insert, prompt_run_job_publish, prompt_run_kind_default, prompt_run_summary,
    prompt_run_wait_terminal, PromptRunRow,
};
use crate::tool;
use crate::tools::ToolContext;

const DELEGATE_WAIT_SECS: u64 = 300;

pub fn delegate_child_row(
    child_req_id: &str,
    parent_req_id: &str,
    ctx: &ToolContext,
    topic_id: &str,
    goal: &str,
    kind: &str,
    label: &str,
    device_iid: i64,
) -> PromptRunRow {
    let checkpoint = if label.is_empty() {
        json!({})
    } else {
        json!({ "label": label })
    };
    PromptRunRow {
        req_id: child_req_id.to_string(),
        chat_id: ctx.chat_id,
        owner_iid: ctx.owner_iid,
        parent_req_id: Some(parent_req_id.to_string()),
        kind: kind.to_string(),
        status: "queued".to_string(),
        topic_id: topic_id.to_string(),
        device_iid,
        text: goal.to_string(),
        mention_ids_json: Json(json!([])),
        tool_mode: "agent".to_string(),
        model: String::new(),
        attachments_json: ctx.attachments_json.clone(),
        locale: ctx.locale.clone(),
        cancel_requested: false,
        turn_count: 0,
        max_turns: 100,
        fail_class: None,
        fail_reason: None,
        checkpoint_json: Json(checkpoint),
        budget_usd_cap: CHILD_BUDGET_USD,
        accumulated_cost_usd: 0.0,
        tokens_in: 0,
        tokens_out: 0,
        cost_usd: 0.0,
        duration_ms: 0,
        lease_pod: None,
        delivery_count: 0,
    }
}

pub fn delegate_result_json(child: &PromptRunRow, summary: &str, tool_name: &str) -> Value {
    let ok = child.status == "done";
    json!({
        "ok": ok,
        "runner": "cluster",
        "tool": tool_name,
        "summary": summary,
        "child_req_id": child.req_id,
        "kind": child.kind,
        "topic_id": child.topic_id,
        "status": child.status,
        "tokens_in": child.tokens_in,
        "tokens_out": child.tokens_out,
        "cost_usd": child.cost_usd,
        "fail_class": child.fail_class,
        "fail_reason": child.fail_reason,
    })
}

pub async fn delegate_run_exec(ctx: &ToolContext, args: &Value) -> anyhow::Result<Value> {
    let topic_id = args["topic_id"].as_str().unwrap_or_default().trim();
    let goal = args["goal"].as_str().unwrap_or_default().trim();
    if topic_id.is_empty() || goal.is_empty() {
        bail!("topic_id and goal are required");
    }
    let parent_req_id = ctx.req_id.trim();
    if parent_req_id.is_empty() {
        bail!("delegate.run requires parent req_id");
    }
    let kind = args["kind"]
        .as_str()
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| prompt_run_kind_default(topic_id));
    let label = args["label"].as_str().unwrap_or_default().trim();
    let device_iid = args["device_iid"].as_u64().unwrap_or(0) as i64;

    let hold_usd = if kind == "computer_use" { COMPUTER_USE_HOLD_USD } else { CHILD_HOLD_USD };
    if ctx.owner_iid > 0 {
        let can_afford = billing_can_afford_tool(&ctx.pool, ctx.owner_iid, hold_usd)
            .await
            .unwrap_or(false);
        if !can_afford {
            bail!("Not enough balance or quota to spawn subagent. Please top up or wait for quota reset.");
        }
    }

    let child_req_id = snowflake_id().to_string();
    let row = delegate_child_row(
        &child_req_id,
        parent_req_id,
        ctx,
        topic_id,
        goal,
        kind,
        label,
        device_iid,
    );
    prompt_run_insert(&ctx.pool, &row).await?;

    if let Some(nats) = &ctx.nats {
        let js = jetstream::new(nats.clone());
        let job = PromptRunJob {
            req_id: child_req_id.clone(),
            owner_iid: ctx.owner_iid,
            chat_id: ctx.chat_id,
        };
        prompt_run_job_publish(&js, &job).await?;
    }

    let child = prompt_run_wait_terminal(
        &ctx.pool,
        &child_req_id,
        Duration::from_secs(DELEGATE_WAIT_SECS),
    )
    .await?;
    let summary = prompt_run_summary(&ctx.pool, &child_req_id).await?;
    Ok(delegate_result_json(&child, &summary, "delegate.run"))
}

pub async fn computer_use_delegate_exec(ctx: &ToolContext, args: &Value) -> anyhow::Result<Value> {
    let device_iid = args["device_iid"].as_i64().unwrap_or(0);
    if device_iid <= 0 {
        bail!("device_iid is required for computer_use.delegate");
    }
    let goal = args["goal"].as_str().unwrap_or_default().trim();
    if goal.is_empty() {
        bail!("goal is required");
    }
    let mut wrapped = args.clone();
    wrapped["topic_id"] = json!("computer_use");
    wrapped["kind"] = json!("computer_use");
    wrapped["device_iid"] = json!(device_iid);
    let out = delegate_run_exec(ctx, &wrapped).await?;
    if let Some(obj) = out.as_object() {
        let mut map = obj.clone();
        map.insert("tool".into(), json!("computer_use.delegate"));
        return Ok(Value::Object(map));
    }
    Ok(out)
}

tool! {
    struct: DelegateRunTool,
    name: "delegate.run",
    aliases: ["delegate_run", "subagent.run"],
    description: "Spawn a child subagent on a topic with its own prompt run, billing hold, and budget. Waits for completion and returns a summary.",
    topics: ["general", "research", "device"],
    ui_calling_key: "tool.delegate.run.calling",
    ui_done_key: "tool.delegate.run.done",
    parameters: {
        topic_id: (string, "Target topic for the child run (e.g. research, computer_use)", required),
        goal: (string, "Goal or question for the child subagent", required),
        kind: (string, "Child run kind; defaults from topic_id", optional),
        label: (string, "Short UI label for the subagent card", optional),
        device_iid: (integer, "Device IID when delegating computer use", optional),
    },
    execute: |args, ctx| delegate_run_exec(ctx, &args).await
}

tool! {
    struct: ComputerUseDelegateTool,
    name: "computer_use.delegate",
    aliases: ["computer_use_delegate", "delegate_computer_use"],
    description: "Spawn a computer-use subagent on a paired device. Requires device_iid; captures screenshots and sends input until the goal is done or safety limits hit.",
    topics: ["general", "research", "device"],
    always: ["device"],
    ui_calling_key: "tool.computer_use.delegate.calling",
    ui_done_key: "tool.computer_use.delegate.done",
    parameters: {
        goal: (string, "Desktop automation goal for the child subagent", required),
        device_iid: (integer, "Target paired device identity ID", required),
        label: (string, "Short UI label for the subagent card", optional),
    },
    execute: |args, ctx| computer_use_delegate_exec(ctx, &args).await
}
