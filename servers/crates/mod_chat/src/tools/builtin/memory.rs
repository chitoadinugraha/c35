use crate::memory::{memory_delete, memory_list_active, memory_put};
use crate::tool;
use crate::tools::ToolContext;
use anyhow::Result;
use serde_json::{json, Value};

pub async fn memory_save_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let key = args
        .get("key")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .trim();
    let content = args
        .get("content")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .trim();
    let category = args
        .get("category")
        .and_then(|v| v.as_str())
        .unwrap_or("fact")
        .trim();

    if key.is_empty() {
        return Ok(json!({ "ok": false, "error": "key required" }));
    }
    if content.is_empty() {
        return Ok(json!({ "ok": false, "error": "content required" }));
    }

    let id = memory_put(
        &ctx.pool,
        ctx.owner_iid,
        None,
        key,
        content,
        category,
        &ctx.req_id,
    )
    .await?;
    Ok(json!({
        "ok": true,
        "id": id.to_string(),
        "key": key,
        "category": category,
        "content": content,
    }))
}

pub async fn memory_forget_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let key = args
        .get("key")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .trim();
    if key.is_empty() {
        return Ok(json!({ "ok": false, "error": "key required" }));
    }

    let deleted = memory_delete(&ctx.pool, ctx.owner_iid, None, key).await?;
    Ok(json!({
        "ok": true,
        "key": key,
        "deleted": deleted,
    }))
}

pub async fn memory_list_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let limit = args
        .get("limit")
        .and_then(|v| v.as_i64())
        .unwrap_or(20)
        .clamp(1, 50);
    let rows = memory_list_active(&ctx.pool, ctx.owner_iid, None, limit).await?;
    let items: Vec<Value> = rows
        .into_iter()
        .map(|(k, c)| json!({ "key": k, "content": c }))
        .collect();
    Ok(json!({
        "ok": true,
        "count": items.len(),
        "memories": items,
    }))
}

tool! {
    struct: MemorySaveTool,
    name: "memory.save",
    aliases: ["memory_save"],
    description: "Save or update a durable fact or preference about the user in long-term memory.",
    topics: ["general"],
    always: ["general"],
    parameters: {
        key: (string, "Concise snake_case key (e.g. user_name, diet_preference, currency)"),
        content: (string, "Durable fact or preference value to remember"),
        category: (string, "Category: identity, preference, fact, task (default: fact)", optional, default = "fact"),
    },
    execute: |args, ctx| memory_save_exec(ctx, &args).await
}

tool! {
    struct: MemoryForgetTool,
    name: "memory.forget",
    aliases: ["memory_forget"],
    description: "Forget or delete a previously stored fact from long-term memory.",
    topics: ["general"],
    always: ["general"],
    parameters: {
        key: (string, "Key of the memory to forget"),
    },
    execute: |args, ctx| memory_forget_exec(ctx, &args).await
}

tool! {
    struct: MemoryListTool,
    name: "memory.list",
    aliases: ["memory_list"],
    description: "List currently stored long-term memories for the active user.",
    topics: ["general"],
    always: ["general"],
    readonly: true,
    parameters: {
        limit: (integer, "Max memories to list (1-50, default 20)", optional, default = 20),
    },
    execute: |args, ctx| memory_list_exec(ctx, &args).await
}
