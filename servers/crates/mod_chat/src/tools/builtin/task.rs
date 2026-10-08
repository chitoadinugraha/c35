use crate::mention_context::{device_iid_resolve, json_device_iid_field};
use crate::tool;
use crate::tools::context::ToolContext;
use c35_mod_task::{
    task_delete_rpc, task_list_rpc, task_put_rpc, task_run_cancel_device_rpc, task_run_cancel_rpc,
    task_run_get, task_run_list_rpc, task_run_start_rpc,
};
use c35_proto::{
    ReqTaskList, ReqTaskPut, ReqTaskRunCancel, ReqTaskRunCancelDevice, ReqTaskRunList,
    ReqTaskRunStart, Task, TaskRun, TaskRunStatus, TaskTrigger,
};
use serde_json::{json, Value};

fn task_fail(error: impl Into<String>) -> Value {
    json!({ "ok": false, "error": error.into() })
}

fn resolve_device_iid(args: &Value, ctx: &ToolContext) -> Result<i64, Value> {
    let direct = json_device_iid_field(args, "device_iid");
    device_iid_resolve(&ctx.mention, &ctx.mention_ids, direct).map_err(|e| task_fail(e.to_string()))
}

fn task_run_status_str(status: TaskRunStatus) -> &'static str {
    match status {
        TaskRunStatus::Queued => "queued",
        TaskRunStatus::Leased => "leased",
        TaskRunStatus::Running => "running",
        TaskRunStatus::Done => "done",
        TaskRunStatus::Failed => "failed",
        TaskRunStatus::Cancelled => "cancelled",
        TaskRunStatus::Unspecified => "unknown",
    }
}

fn task_run_json(run: &TaskRun) -> Value {
    let meta: Value = serde_json::from_str(run.meta_json.trim()).unwrap_or(json!({}));
    json!({
        "ok": true,
        "run_id": run.id,
        "device_iid": run.device_iid,
        "task_id": run.task_id,
        "chat_id": run.chat_id,
        "req_id": run.req_id,
        "status": task_run_status_str(run.status()),
        "step_index": run.step_index,
        "summary": run.summary,
        "error": run.error,
        "meta": meta,
        "tokens_in": run.tokens_in,
        "tokens_out": run.tokens_out,
        "cost_usd": run.cost_usd,
        "duration_ms": run.duration_ms,
        "started_ts_ms": run.started_ts_ms,
        "finished_ts_ms": run.finished_ts_ms,
        "created_ts_ms": run.created_ts_ms,
        "updated_ts_ms": run.updated_ts_ms,
    })
}

fn prompt_from_args(args: &Value) -> Result<String, Value> {
    if let Some(s) = args.get("prompt").and_then(|v| v.as_str()) {
        let t = s.trim();
        if !t.is_empty() {
            return Ok(t.to_string());
        }
    }
    if args.get("prompt").map(|v| v.is_object() || v.is_array()).unwrap_or(false) {
        return Ok(args["prompt"].to_string());
    }
    if let Some(recipe) = args.get("recipe") {
        if recipe.is_object() || recipe.is_array() {
            return Ok(recipe.to_string());
        }
    }
    Ok(String::new())
}

async fn task_run_start_exec(ctx: &ToolContext, args: &Value) -> anyhow::Result<Value> {
    let device_iid = match resolve_device_iid(args, ctx) {
        Ok(iid) => iid,
        Err(v) => return Ok(v),
    };
    let task_id = args["task_id"].as_i64().unwrap_or(0);
    let prompt = match prompt_from_args(args) {
        Ok(p) => p,
        Err(v) => return Ok(v),
    };
    if task_id <= 0 && prompt.is_empty() {
        return Ok(task_fail("task_id or prompt (recipe JSON) is required"));
    }
    let skill_id = args["skill_id"].as_i64().unwrap_or(0);
    let model = args["model"].as_str().unwrap_or_default().trim().to_string();
    let req = ReqTaskRunStart {
        device_iid,
        task_id,
        prompt,
        skill_id,
        model,
        chat_id: ctx.chat_id,
        req_id: ctx.req_id.to_string(),
    };
    match task_run_start_rpc(&ctx.pool, ctx.nats.as_ref(), ctx.owner_iid, req).await {
        Ok(res) => match res.run.as_ref() {
            Some(run) => Ok(task_run_json(run)),
            None => Ok(task_fail("task run start returned empty run")),
        },
        Err(e) => Ok(task_fail(e)),
    }
}

async fn task_run_cancel_exec(ctx: &ToolContext, args: &Value) -> anyhow::Result<Value> {
    let run_id = args["run_id"].as_i64().unwrap_or(0);
    if run_id <= 0 {
        return Ok(task_fail("run_id is required"));
    }
    let req = ReqTaskRunCancel { run_id };
    match task_run_cancel_rpc(&ctx.pool, ctx.nats.as_ref(), ctx.owner_iid, req).await {
        Ok(res) => match res.run.as_ref() {
            Some(run) => Ok(task_run_json(run)),
            None => Ok(task_fail("cancel returned empty run")),
        },
        Err(e) => Ok(task_fail(e)),
    }
}

async fn task_run_cancel_device_exec(ctx: &ToolContext, args: &Value) -> anyhow::Result<Value> {
    let device_iid = match resolve_device_iid(args, ctx) {
        Ok(iid) => iid,
        Err(v) => return Ok(v),
    };
    let req = ReqTaskRunCancelDevice { device_iid };
    match task_run_cancel_device_rpc(&ctx.pool, ctx.nats.as_ref(), ctx.owner_iid, req).await {
        Ok(res) => {
            let runs: Vec<Value> = res.runs.iter().map(task_run_json).collect();
            Ok(json!({
                "ok": true,
                "device_iid": device_iid,
                "cancelled_count": res.cancelled_count,
                "runs": runs,
            }))
        }
        Err(e) => Ok(task_fail(e)),
    }
}

async fn task_run_status_exec(ctx: &ToolContext, args: &Value) -> anyhow::Result<Value> {
    let run_id = args["run_id"].as_i64().unwrap_or(0);
    if run_id > 0 {
        return match task_run_get(&ctx.pool, ctx.owner_iid, run_id).await {
            Some(run) => Ok(task_run_json(&run)),
            None => Ok(task_fail("run not found")),
        };
    }
    let device_iid = args["device_iid"].as_i64().unwrap_or(0);
    let task_id = args["task_id"].as_i64().unwrap_or(0);
    let limit = args["limit"].as_i64().unwrap_or(5).clamp(1, 20) as i32;
    if device_iid <= 0 && task_id <= 0 {
        return Ok(task_fail("run_id or device_iid or task_id is required"));
    }
    let req = ReqTaskRunList {
        device_iid,
        since_ms: 0,
        limit,
        task_id,
    };
    let res = task_run_list_rpc(&ctx.pool, ctx.owner_iid, req).await;
    let runs: Vec<Value> = res.runs.iter().map(task_run_json).collect();
    Ok(json!({ "ok": true, "runs": runs, "count": runs.len() }))
}

tool! {
    struct: TaskRunStartTool,
    name: "task.run_start",
    aliases: ["task_run_start", "task.run.start"],
    description: "Start a durable server-orchestrated task run on a paired browser device (Task tab). Use for batch recipes such as browser.sheet_row_backfill (JSON prompt with tab_id, sheet columns, parallel, limits). Requires billing hold; progress streams on the Task tab via task.run_status.",
    topics: ["device", "general"],
    rag_phrases: [
        "task run", "start task", "sheet backfill", "e-pus", "batch rows", "parallel rows",
        "browser.sheet_row_backfill", "task tab", "run on device",
    ],
    ui_calling_key: "tool.task.run_start.calling",
    ui_done_key: "tool.task.run_start.done",
    parameters: {
        device_iid: (integer, "Paired browser device identity ID", required),
        task_id: (integer, "Saved ai.task id; omit for ad-hoc prompt/recipe", optional),
        prompt: (string, "Recipe JSON string (e.g. browser.sheet_row_backfill) when task_id is 0", optional),
        recipe: (object, "Recipe JSON object (alias for prompt)", optional),
        skill_id: (integer, "Optional skill id", optional),
        model: (string, "Optional model override", optional),
    },
    execute: |args, ctx| task_run_start_exec(ctx, &args).await
}

tool! {
    struct: TaskRunCancelTool,
    name: "task.run_cancel",
    aliases: ["task_run_cancel", "task.run.cancel"],
    description: "Cancel one queued, leased, or running task_run by run_id. Prefer task.run_cancel_device to stop all active runs on a device.",
    topics: ["device", "general"],
    rag_phrases: ["stop task", "cancel task run", "abort batch", "hentikan task"],
    ui_calling_key: "tool.task.run_cancel.calling",
    ui_done_key: "tool.task.run_cancel.done",
    parameters: {
        run_id: (integer, "task_run id from task.run_start or Task tab", required),
    },
    execute: |args, ctx| task_run_cancel_exec(ctx, &args).await
}

tool! {
    struct: TaskRunCancelDeviceTool,
    name: "task.run_cancel_device",
    aliases: ["task_run_cancel_device", "task.run.cancel_device", "task.run_stop_device"],
    description: "Cancel every queued, leased, or running task_run on a device (Stop all on Task tab).",
    topics: ["device", "general"],
    rag_phrases: ["stop all tasks", "cancel all runs", "stop device tasks", "hentikan semua"],
    ui_calling_key: "tool.task.run_cancel_device.calling",
    ui_done_key: "tool.task.run_cancel_device.done",
    parameters: {
        device_iid: (integer, "Paired device identity ID", required),
    },
    execute: |args, ctx| task_run_cancel_device_exec(ctx, &args).await
}

tool! {
    struct: TaskRunStatusTool,
    name: "task.run_status",
    aliases: ["task_run_status", "task.run.status"],
    description: "Read task_run progress: pass run_id for one run, or device_iid/task_id with limit for recent runs. Returns status, summary, meta_json progress (done/total/pct), tokens, and cost.",
    topics: ["device", "general"],
    rag_phrases: [
        "task progress", "how many rows done", "task status", "percent complete",
        "progress task", "berapa persen",
    ],
    ui_calling_key: "tool.task.run_status.calling",
    ui_done_key: "tool.task.run_status.done",
    readonly: true,
    parameters: {
        run_id: (integer, "Single task_run id", optional),
        device_iid: (integer, "List recent runs for device", optional),
        task_id: (integer, "Filter list by saved task id", optional),
        limit: (integer, "Max runs when listing (default 5, max 20)", optional, default = 5),
    },
    execute: |args, ctx| task_run_status_exec(ctx, &args).await
}

async fn task_create_exec(ctx: &ToolContext, args: &Value) -> anyhow::Result<Value> {
    let name = args["name"].as_str().unwrap_or_default().trim();
    if name.is_empty() {
        return Ok(task_fail("name is required"));
    }
    let prompt = prompt_from_args(args).unwrap_or_default();
    if prompt.is_empty() {
        return Ok(task_fail("prompt is required"));
    }
    let device_iid = resolve_device_iid(args, ctx).unwrap_or(0);
    let skill_id = args["skill_id"].as_i64().unwrap_or(0);
    let model = args["model"].as_str().unwrap_or("cloud").trim().to_string();

    let mut triggers = Vec::new();
    let cron_expr = args["cron_expr"].as_str().map(str::trim).unwrap_or("");
    let interval_sec = args["interval_sec"].as_i64().unwrap_or(0);
    let run_at_str = args["run_at"].as_str().map(str::trim).unwrap_or("");

    if interval_sec > 0 {
        triggers.push(TaskTrigger {
            id: 0,
            task_id: 0,
            owner_iid: ctx.owner_iid,
            kind: 2,
            label: format!("Every {}s", interval_sec),
            cron_expr: format!("*/{} * * * * *", interval_sec),
            timezone: "UTC".to_string(),
            run_at_ms: 0,
            webhook_secret: String::new(),
            is_active: true,
            created_ts_ms: 0,
            updated_ts_ms: 0,
            deleted_ts_ms: 0,
        });
    } else if !cron_expr.is_empty() {
        triggers.push(TaskTrigger {
            id: 0,
            task_id: 0,
            owner_iid: ctx.owner_iid,
            kind: 2,
            label: "Cron schedule".to_string(),
            cron_expr: cron_expr.to_string(),
            timezone: "UTC".to_string(),
            run_at_ms: 0,
            webhook_secret: String::new(),
            is_active: true,
            created_ts_ms: 0,
            updated_ts_ms: 0,
            deleted_ts_ms: 0,
        });
    } else if !run_at_str.is_empty() {
        if let Ok(dt) = chrono::DateTime::parse_from_rfc3339(run_at_str) {
            triggers.push(TaskTrigger {
                id: 0,
                task_id: 0,
                owner_iid: ctx.owner_iid,
                kind: 1,
                label: "Run once".to_string(),
                cron_expr: String::new(),
                timezone: "UTC".to_string(),
                run_at_ms: dt.timestamp_millis(),
                webhook_secret: String::new(),
                is_active: true,
                created_ts_ms: 0,
                updated_ts_ms: 0,
                deleted_ts_ms: 0,
            });
        }
    }

    let task = Task {
        id: 0,
        owner_iid: ctx.owner_iid,
        device_iid,
        name: name.to_string(),
        skill_id,
        prompt: prompt.clone(),
        model,
        is_active: true,
        triggers,
        created_ts_ms: 0,
        updated_ts_ms: 0,
        deleted_ts_ms: 0,
    };

    let req = ReqTaskPut { task: Some(task) };
    match task_put_rpc(&ctx.pool, ctx.nats.as_ref(), ctx.owner_iid, req).await {
        Ok(res) => {
            let saved = res.task.unwrap_or_default();
            Ok(json!({
                "ok": true,
                "task_id": saved.id,
                "name": saved.name,
                "device_iid": saved.device_iid,
                "prompt": saved.prompt,
                "trigger_count": saved.triggers.len(),
                "triggers": saved.triggers.iter().map(|tr| json!({
                    "id": tr.id,
                    "kind": if tr.kind == 2 { "cron" } else { "once" },
                    "cron_expr": tr.cron_expr,
                    "label": tr.label,
                    "is_active": tr.is_active,
                })).collect::<Vec<_>>(),
            }))
        }
        Err(e) => Ok(task_fail(format!("failed to create task: {e}"))),
    }
}

async fn task_delete_exec(ctx: &ToolContext, args: &Value) -> anyhow::Result<Value> {
    let task_id = args["task_id"].as_i64().unwrap_or(0);
    if task_id <= 0 {
        return Ok(task_fail("task_id is required"));
    }
    match task_delete_rpc(&ctx.pool, ctx.nats.as_ref(), ctx.owner_iid, task_id).await {
        Ok(_) => Ok(json!({ "ok": true, "task_id": task_id, "deleted": true })),
        Err(e) => Ok(task_fail(format!("failed to delete task: {e}"))),
    }
}

async fn task_list_exec(ctx: &ToolContext, args: &Value) -> anyhow::Result<Value> {
    let device_iid = args["device_iid"].as_i64().unwrap_or(0);
    let req = ReqTaskList {
        device_iid,
        include_inactive: false,
    };
    let res = task_list_rpc(&ctx.pool, ctx.owner_iid, req).await;
    let list: Vec<Value> = res.tasks.iter().map(|t| json!({
        "id": t.id,
        "name": t.name,
        "device_iid": t.device_iid,
        "prompt": t.prompt,
        "is_active": t.is_active,
        "triggers": t.triggers.iter().map(|tr| json!({
            "id": tr.id,
            "kind": if tr.kind == 2 { "cron" } else { "once" },
            "cron_expr": tr.cron_expr,
            "label": tr.label,
            "is_active": tr.is_active,
        })).collect::<Vec<_>>(),
    })).collect();
    Ok(json!({ "ok": true, "count": list.len(), "tasks": list }))
}

tool! {
    struct: TaskCreateTool,
    name: "task.create",
    aliases: ["task_create", "task.schedule", "create_task", "schedule_task"],
    description: "Create and optionally schedule an automation task. Use when user wants a task added to their task list and/or executed on a schedule (cron_expr or interval_sec). If device_iid is provided, it targets that remote device (e.g. running powershell or automation).",
    topics: ["device", "general"],
    rag_phrases: ["create task", "schedule task", "add task", "buat task", "jadwalkan task", "every 10 second", "setiap 10 detik"],
    ui_calling_key: "tool.task.create.calling",
    ui_done_key: "tool.task.create.done",
    parameters: {
        name: (string, "Descriptive name for the task", required),
        prompt: (string, "Execution command or prompt (e.g. 'powershell: Get-Date | Out-File ...')", required),
        device_iid: (integer, "Target remote device identity ID", optional),
        cron_expr: (string, "Cron expression or '@every 10s' for recurring schedule", optional),
        interval_sec: (integer, "Interval in seconds (e.g. 10 for every 10 seconds)", optional),
        run_at: (string, "RFC3339 timestamp for a one-time future execution", optional),
    },
    execute: |args, ctx| task_create_exec(ctx, &args).await
}

tool! {
    struct: TaskDeleteTool,
    name: "task.delete",
    aliases: ["task_delete", "delete_task", "remove_task"],
    description: "Delete/remove an automation task, disarming any active NATS schedules.",
    topics: ["device", "general"],
    rag_phrases: ["delete task", "remove task", "hapus task"],
    ui_calling_key: "tool.task.delete.calling",
    ui_done_key: "tool.task.delete.done",
    parameters: {
        task_id: (integer, "ID of the task to delete", required),
    },
    execute: |args, ctx| task_delete_exec(ctx, &args).await
}

tool! {
    struct: TaskListTool,
    name: "task.list",
    aliases: ["task_list", "list_tasks"],
    description: "List tasks and their schedules/triggers for the user or a specific device.",
    topics: ["device", "general"],
    rag_phrases: ["list tasks", "my tasks", "daftar task"],
    ui_calling_key: "tool.task.list.calling",
    ui_done_key: "tool.task.list.done",
    readonly: true,
    parameters: {
        device_iid: (integer, "Optional filter by device identity ID", optional),
    },
    execute: |args, ctx| task_list_exec(ctx, &args).await
}
