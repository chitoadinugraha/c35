use anyhow::bail;
use reqwest::Client;
use serde_json::{json, Value};

use crate::tool;
use crate::tools::web;
use super::web_visit::web_visit_exec;

pub async fn web_research_exec(
    client: &Client,
    query: &str,
    search_limit: u32,
    visit_top: u32,
    geo: Option<&web::SearchGeoContext>,
) -> anyhow::Result<Value> {
    let search_res = web::web_search_exec(client, query, search_limit, geo).await?;
    let results = search_res
        .get("results")
        .and_then(|r| r.as_array())
        .cloned()
        .unwrap_or_default();

    if results.is_empty() {
        return Ok(json!({
            "ok": false,
            "runner": "cluster",
            "tool": "web.research",
            "query": query,
            "error": "No search results found to research",
            "sources": []
        }));
    }

    let visit_count = (visit_top as usize).clamp(1, 4);
    let mut dossier = Vec::new();

    for item in results.iter().take(visit_count) {
        let url = item.get("url").and_then(|u| u.as_str()).unwrap_or("");
        let title = item.get("title").and_then(|t| t.as_str()).unwrap_or("");
        let snippet = item.get("snippet").and_then(|s| s.as_str()).unwrap_or("");

        if url.is_empty() {
            continue;
        }

        let visit_res = web_visit_exec(client, url, Some(3000)).await.unwrap_or(Value::Null);
        let content = visit_res.get("content").and_then(|c| c.as_str()).unwrap_or(snippet);

        dossier.push(json!({
            "title": title,
            "url": url,
            "summary": content,
        }));
    }

    Ok(json!({
        "ok": true,
        "runner": "cluster",
        "tool": "web.research",
        "query": query,
        "visited_pages": dossier.len(),
        "dossier": dossier,
    }))
}

tool! {
    struct: WebResearchTool,
    name: "web.research",
    aliases: ["web_research", "deep_research"],
    description: "Perform comprehensive deep research: queries web search and reads top pages into an aggregated dossier.",
    topics: ["research"],
    always: ["research"],
    ui_calling_key: "tool.web.research.calling",
    ui_done_key: "tool.web.research.done",
    parameters: {
        query: (string, "The research topic or question", required),
        search_limit: (integer, "Number of search results to inspect (1-8)", optional, default = 5),
        visit_top: (integer, "Number of top pages to deep-read (1-4)", optional, default = 2),
    },
    execute: |args, ctx| {
        let query = web::search_query_from_args(&args);
        let search_limit = args["search_limit"].as_u64().unwrap_or(5) as u32;
        let visit_top = args["visit_top"].as_u64().unwrap_or(2) as u32;
        if query.is_empty() {
            bail!("Search query cannot be empty");
        }
        let geo = web::SearchGeoContext::from_tool_ctx(
            &ctx.location_city,
            &ctx.location_region,
            &ctx.location_country,
            &ctx.locale,
        );
        let geo_ref = if geo.is_empty() { None } else { Some(&geo) };
        web_research_exec(&ctx.http_client, &query, search_limit, visit_top, geo_ref).await
    }
}
