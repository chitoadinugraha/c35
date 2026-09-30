use anyhow::{anyhow, Result};
use serde_json::Value;

use crate::bot_inbox::{bot_inbox_query_run, bot_iid_from_params};
use crate::tool;
use crate::tools::ToolContext;

fn params_json_resolve(args: &Value) -> Result<String> {
    if let Some(raw) = args.get("params_json").and_then(|v| v.as_str()) {
        return Ok(raw.to_string());
    }
    if let Some(params) = args.get("params") {
        return Ok(serde_json::to_string(params)?);
    }
    Ok("{}".into())
}

pub async fn bot_inbox_query_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let query_id = args
        .get("query_id")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .ok_or_else(|| anyhow!("query_id is required"))?;
    let bot_iid = bot_iid_from_params(&ctx.mention.bots, args)?;
    let params_json = params_json_resolve(args)?;
    bot_inbox_query_run(&ctx.pool, ctx.owner_iid, bot_iid, query_id, &params_json).await
}

tool! {
    struct: BotInboxQueryTool,
    name: "bot.inbox.query",
    aliases: ["bot_inbox_query"],
    description: "Readonly analytics for a @mentioned bot channel inbox: top user questions, peer messages by day, message counts today by channel (WhatsApp/Telegram), and average messages per day. Requires @bot mention. query_id: top_questions | peer_messages | stats_today | stats_daily_avg.",
    topics: ["general", "bot"],
    rag_phrases: [
        "apa yang biasa ditanya",
        "pertanyaan user",
        "hari ini tanya apa",
        "jumlah chat hari ini",
        "berapa chat",
        "rata-rata chat",
        "top questions bot",
        "inbox bot",
    ],
    requires_kinds: ["bot"],
    readonly: true,
    parameters: {
        query_id: (string, "Catalog id: top_questions, peer_messages, stats_today, stats_daily_avg", required),
        bot_iid: (integer, "Bot identity id; omit when exactly one @bot is mentioned", optional),
        params: (object, "Query params: days, limit, peer, day (YYYY-MM-DD), tz (e.g. Asia/Jakarta), exclude_app (default true)", optional),
        params_json: (string, "Same as params but JSON string", optional),
    },
    execute: |args, ctx| {
        bot_inbox_query_exec(ctx, &args).await
    }
}