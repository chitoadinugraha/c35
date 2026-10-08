use crate::chat_history::{chat_messages, chat_search, ChatHistoryQuery};
use crate::tool;
use crate::tools::ToolContext;
use anyhow::Result;
use serde_json::{json, Value};

fn arg_str(args: &Value, key: &str) -> String {
    args.get(key)
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .trim()
        .to_string()
}

fn arg_i64(args: &Value, key: &str) -> i64 {
    match args.get(key) {
        Some(Value::String(s)) => s.trim().parse().unwrap_or(0),
        Some(Value::Number(n)) => n.as_i64().unwrap_or(0),
        _ => 0,
    }
}

fn history_query(ctx: &ToolContext, args: &Value) -> ChatHistoryQuery {
    ChatHistoryQuery {
        owner_iid: ctx.owner_iid,
        current_chat_id: ctx.chat_id,
        query: arg_str(args, "query"),
        since: arg_str(args, "since"),
        until: arg_str(args, "until"),
        chat_id: arg_i64(args, "chat_id"),
        limit: arg_i64(args, "limit"),
        locale: ctx.locale.clone(),
        user_text: ctx.user_text.clone(),
    }
}

pub async fn chat_search_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    match chat_search(&ctx.pool, &history_query(ctx, args)).await {
        Ok(v) => Ok(v),
        Err(e) => Ok(json!({ "ok": false, "error": e })),
    }
}

pub async fn chat_messages_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    match chat_messages(&ctx.pool, &history_query(ctx, args)).await {
        Ok(v) => Ok(v),
        Err(e) => Ok(json!({ "ok": false, "error": e })),
    }
}

tool! {
    struct: ChatSearchTool,
    name: "chat.search",
    aliases: ["chat_search"],
    description: "Search this user's past chats. Returns matching threads with title, local time, stored summary, and one snippet. Use for what was discussed or whether a past conversation is remembered. Pass topic keywords. since and until are YYYY-MM-DD in the user timezone. Times in the result are already local.",
    topics: ["general"],
    rag_phrases: [
        "based on our conversation",
        "do you remember",
        "remember our conversation",
        "conversation yesterday",
        "what did we discuss",
        "berdasarkan percakapan",
        "berdasarkan obrolan",
        "apakah kamu ingat",
        "kamu ingat",
        "percakapan kemarin",
        "obrolan kemarin",
        "percakapan kita",
        "obrolan kita",
        "apa yang kita bahas",
    ],
    readonly: true,
    parameters: {
        query: (string, "Topic keywords, not the whole question (e.g. remove product A)", optional, default = ""),
        since: (string, "Start date YYYY-MM-DD in the user timezone, inclusive", optional, default = ""),
        until: (string, "End date YYYY-MM-DD in the user timezone, inclusive", optional, default = ""),
        limit: (integer, "Max chats (1-8, default 5)", optional, default = 5),
    },
    execute: |args, ctx| chat_search_exec(ctx, &args).await
}

tool! {
    struct: ChatMessagesTool,
    name: "chat.messages",
    aliases: ["chat_messages"],
    description: "Exact messages from one of this user's chats. Use when the user asks when they said something or wants a quote. Pass chat_id from chat.search, or omit it to read the current chat. Returns role, local timestamp, and text. Times are already in the user timezone.",
    topics: ["general"],
    rag_phrases: [
        "when did i ask",
        "when did i say",
        "exact words",
        "quote what i said",
        "kapan saya minta",
        "kapan saya bilang",
        "kapan aku minta",
        "kapan aku bilang",
        "kata persis",
    ],
    readonly: true,
    parameters: {
        chat_id: (string, "Chat id from chat.search. Omit to use the current chat.", optional, default = ""),
        query: (string, "Words that must appear in the message (e.g. remove product)", optional, default = ""),
        since: (string, "Start date YYYY-MM-DD in the user timezone, inclusive", optional, default = ""),
        until: (string, "End date YYYY-MM-DD in the user timezone, inclusive", optional, default = ""),
        limit: (integer, "Max messages (1-20, default 12)", optional, default = 12),
    },
    execute: |args, ctx| chat_messages_exec(ctx, &args).await
}
