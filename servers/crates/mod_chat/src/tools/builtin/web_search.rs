use anyhow::bail;
use crate::tool;

use crate::tools::web;

tool! {
    struct: WebSearchTool,
    name: "web.search",
    aliases: ["web_search", "search_web"],
    description: "Search the web via SearXNG and return title/url/snippet JSON. Use for knowledge questions, news, and lookups.",
    topics: ["*"],
    always: ["general", "research"],
    ui_calling_key: "tool.web.search.calling",
    ui_done_key: "tool.web.search.done",
    parameters: {
        query: (string, "Search query", required),
        limit: (integer, "Max results (1-12)", optional, default = 6),
    },
    execute: |args, ctx| {
        let query = args["query"].as_str().unwrap_or_default();
        let limit = args["limit"].as_u64().unwrap_or(6) as u32;
        if query.trim().is_empty() {
            bail!("Search query cannot be empty");
        }
        web::web_search_exec(&ctx.http_client, query, limit).await
    }
}
