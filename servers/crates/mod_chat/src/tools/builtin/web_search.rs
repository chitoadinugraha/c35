use anyhow::bail;
use crate::tool;

use crate::tools::web;

tool! {
    struct: WebSearchTool,
    name: "web.search",
    aliases: ["web_search", "search_web"],
    description: "Search the web via SearXNG and return title/url/snippet JSON. Use for knowledge questions, news, live listings, schedules, and lookups.",
    topics: ["*"],
    always: ["general", "research"],
    rag_phrases: [
        "film bioskop", "jadwal bioskop", "apa yang tayang", "jadwal nonton", "cinema schedule",
        "what is playing", "showtimes", "cuaca hari ini", "harga terbaru", "berita terbaru",
        "cari di internet", "search the web", "film di malang", "tayang sekarang",
    ],
    ui_calling_key: "tool.web.search.calling",
    ui_done_key: "tool.web.search.done",
    parameters: {
        query: (string, "Search query", required),
        limit: (integer, "Max results (1-12)", optional, default = 6),
    },
    execute: |args, ctx| {
        let query = web::search_query_from_args(&args);
        let limit = args["limit"].as_u64().unwrap_or(6) as u32;
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
        web::web_search_exec(&ctx.http_client, &query, limit, geo_ref).await
    }
}
