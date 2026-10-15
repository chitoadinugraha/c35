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

use crate::prompt::google_forms::ComputerUseToolCounts;
use crate::prompt_run::{
    prompt_run_insert, prompt_run_job_publish, prompt_run_kind_normalize, prompt_run_summary,
    prompt_run_tool_counts, prompt_run_wait_terminal, PromptRunRow,
};
use crate::mention_registry::mention_ref_iid;
use crate::mention_context::{device_iid_resolve, json_device_iid_field};
use crate::prompt::computer_use::{
    computer_use_final_text_acceptable, computer_use_goal_met_with_goal,
    COMPUTER_USE_PARENT_INCOMPLETE_HINT,
};
use crate::prompt::google_forms::{
    google_forms_playbook_block, user_text_looks_like_google_forms,
};
use crate::prompt::google_sheets::{
    google_sheets_playbook_block, user_text_looks_like_google_sheets_desktop,
};

fn delegate_json_goal_met(v: &Value) -> bool {
    v.get("goal_met")
        .and_then(|x| x.as_bool())
        .unwrap_or_else(|| v.get("ok").and_then(|x| x.as_bool()).unwrap_or(false))
}
use crate::tool;
use crate::tools::ToolContext;

const DELEGATE_WAIT_SECS: u64 = 300;

fn computer_use_delegate_retry_goal(goal: &str) -> String {
    let g = goal.to_ascii_lowercase();
    if g.contains("google sheet")
        || g.contains("spreadsheet")
        || g.contains("sheets.new")
        || g.contains("lembar kerja")
    {
        return format!(
            "{goal}\n\n[RETRY] The previous computer-use run did not finish. \
Reuse the existing Chrome Google Sheets tab shown in screenshot (do not open a new blank sheet). \
device.screenshot with som=true before each action; use ctrl+g and the name box for cells — finish on device, no human handoff."
        );
    }
    format!(
        "{goal}\n\n[RETRY] The previous computer-use run did not finish. \
Reuse the existing Chrome Google Forms tab shown in screenshot (do not open forms.new again). \
Close duplicate Forms tabs only if they block Blank. device.screenshot som=true, then finish every step (no human handoff)."
    )
}

pub(crate) fn delegate_goal_augment_for_computer_use(kind: &str, goal: &str) -> String {
    if kind != "computer_use" {
        return goal.to_string();
    }
    if user_text_looks_like_google_forms(goal) {
        if goal.contains("[GOOGLE FORMS TAB RESUME]") {
            return goal.to_string();
        }
        return format!("{goal}\n\n{}", google_forms_playbook_block());
    }
    if user_text_looks_like_google_sheets_desktop(goal) {
        if goal.contains("[GOOGLE SHEETS ON DEVICE]") {
            return goal.to_string();
        }
        return format!("{goal}\n\n{}", google_sheets_playbook_block());
    }
    goal.to_string()
}

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
        mention_ids_json: Json(if device_iid > 0 {
            json!([mention_ref_iid(device_iid)])
        } else if !ctx.mention_ids.is_empty() {
            json!(ctx.mention_ids.clone())
        } else {
            json!([])
        }),
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

pub fn delegate_result_json(
    child: &PromptRunRow,
    summary: &str,
    tool_name: &str,
    tool_counts: ComputerUseToolCounts,
) -> Value {
    let goal_met = computer_use_goal_met_with_goal(
        &child.kind,
        &child.status,
        summary,
        &child.text,
        tool_counts,
    );
    let ok = goal_met;
    let incomplete = child.kind == "computer_use" && child.status == "done" && !goal_met;
    let mut out = json!({
        "ok": ok,
        "goal_met": goal_met,
        "incomplete": incomplete,
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
    });
    if incomplete {
        let reason = if !computer_use_final_text_acceptable(summary) {
            "child_summary_handoff_or_give_up"
        } else {
            "child_insufficient_device_tooling"
        };
        out["incomplete_reason"] = json!(reason);
        out["parent_reply_rule"] = json!(COMPUTER_USE_PARENT_INCOMPLETE_HINT);
        if reason == "child_insufficient_device_tooling" {
            out["tool_counts"] = json!({
                "device_input": tool_counts.device_input,
                "device_screenshot": tool_counts.device_screenshot,
            });
        }
    }
    out
}

pub async fn delegate_run_exec(ctx: &ToolContext, args: &Value) -> anyhow::Result<Value> {
    let topic_id = args["topic_id"].as_str().unwrap_or_default().trim();
    let goal = args["goal"].as_str().unwrap_or_default().trim();
    if topic_id.is_empty() || goal.is_empty() {
        bail!("topic_id and goal are required");
    }
    let kind_raw = args["kind"].as_str().map(str::trim).unwrap_or("");
    let kind_preview = prompt_run_kind_normalize(kind_raw, topic_id);
    let goal_stored = delegate_goal_augment_for_computer_use(&kind_preview, goal);
    let parent_req_id = ctx.req_id.trim();
    if parent_req_id.is_empty() {
        bail!("delegate.run requires parent req_id");
    }
    let kind = kind_preview;
    let label = args["label"].as_str().unwrap_or_default().trim();
    let direct = json_device_iid_field(args, "device_iid");
    let device_iid = if direct > 0
        || !ctx.mention.devices.is_empty()
        || ctx.mention_ids.iter().any(|m| m.starts_with("iid:"))
    {
        device_iid_resolve(&ctx.mention, &ctx.mention_ids, direct)?
    } else {
        0
    };

    let hold_usd = if kind == "computer_use" {
        COMPUTER_USE_HOLD_USD
    } else {
        CHILD_HOLD_USD
    };
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
        &goal_stored,
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
    let tool_counts = prompt_run_tool_counts(&ctx.pool, &child_req_id).await?;
    Ok(delegate_result_json(&child, &summary, "delegate.run", tool_counts))
}

pub async fn computer_use_delegate_exec(ctx: &ToolContext, args: &Value) -> anyhow::Result<Value> {
    let direct = json_device_iid_field(args, "device_iid");
    let device_iid = device_iid_resolve(&ctx.mention, &ctx.mention_ids, direct)?;
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
    let out = if !delegate_json_goal_met(&out) {
        let retry_goal = computer_use_delegate_retry_goal(goal);
        wrapped["goal"] = json!(retry_goal);
        wrapped["label"] = json!("computer_use_retry");
        delegate_run_exec(ctx, &wrapped).await?
    } else {
        out
    };
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
    rag_phrases: [
        "multitask", "multi task", "multi-task", "parallel tasks", "run in parallel",
        "subagent", "sub-agent", "two at once", "simultaneously", "at the same time",
        "bersamaan", "dua sekaligus", "multitasking",
    ],
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
    description: "Spawn a computer-use subagent on a paired device. Requires device_iid; uses device.screenshot and device.input (normalized coords, screenshot_after, shortcuts) until the goal is done or safety limits hit. Goal should include clearing foreground blockers on Windows (e.g. Task Manager via Stop-Process or Alt+F4) before clicking Chrome UI.",
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
