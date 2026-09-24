use std::time::Duration;

use anyhow::{bail, Result};
use reqwest::Client;
use serde_json::{json, Value};

/// Resolve search text from tool args — models sometimes send `queries` (array) instead of `query`.
pub fn search_query_from_args(args: &Value) -> String {
    if let Some(q) = args.get("query").and_then(|v| v.as_str()) {
        let q = q.trim();
        if !q.is_empty() {
            return q.to_string();
        }
    }
    if let Some(q) = args.get("q").and_then(|v| v.as_str()) {
        let q = q.trim();
        if !q.is_empty() {
            return q.to_string();
        }
    }
    if let Some(arr) = args.get("queries").and_then(|v| v.as_array()) {
        for item in arr {
            if let Some(q) = item.as_str() {
                let q = q.trim();
                if !q.is_empty() {
                    return q.to_string();
                }
            }
        }
    }
    String::new()
}

pub fn search_def() -> (String, String, Value) {
    (
        "web.search".into(),
        "Search the web via SearXNG and return title/url/snippet JSON. Use for knowledge questions, news, and lookups.".into(),
        json!({
            "type": "object",
            "properties": {
                "query": { "type": "string", "description": "Search query" },
                "limit": { "type": "integer", "description": "Max results (1-12)" }
            },
            "required": ["query"]
        }),
    )
}

pub async fn web_search_exec(client: &Client, query: &str, limit: u32) -> Result<Value> {
    let query = query.trim();
    if query.is_empty() {
        bail!("Search query cannot be empty");
    }
    let limit = limit.clamp(1, 12);
    let base = std::env::var("SEARX_URL")
        .ok()
        .filter(|s| !s.trim().is_empty())
        .unwrap_or_else(|| "http://searxng.searx.svc.cluster.local:8080".into());
    let url = format!(
        "{}/search?q={}&format=json&categories=general",
        base.trim_end_matches('/'),
        urlencoding::encode(query)
    );
    let res = match client.get(&url).timeout(Duration::from_secs(15)).send().await {
        Ok(r) => r,
        Err(e) => {
            return Ok(json!({
                "ok": false,
                "runner": "cluster",
                "tool": "web.search",
                "query": query,
                "error": format!("Web search service unavailable: {}", e),
                "results": []
            }));
        }
    };
    if !res.status().is_success() {
        return Ok(json!({
            "ok": false,
            "runner": "cluster",
            "tool": "web.search",
            "query": query,
            "error": format!("SearXNG returned HTTP {}", res.status()),
            "results": []
        }));
    }
    let body: Value = res.json().await?;
    let results: Vec<Value> = body
        .get("results")
        .and_then(|r| r.as_array())
        .map(|arr| {
            arr.iter()
                .take(limit as usize)
                .filter_map(|item| {
                    Some(json!({
                        "title": item.get("title")?.as_str()?,
                        "url": item.get("url")?.as_str()?,
                        "snippet": item.get("content").or_else(|| item.get("snippet"))?.as_str().unwrap_or(""),
                    }))
                })
                .collect()
        })
        .unwrap_or_default();
    Ok(json!({
        "ok": !results.is_empty(),
        "runner": "cluster",
        "tool": "web.search",
        "query": query,
        "count": results.len(),
        "results": results
    }))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn search_query_from_args_prefers_query_string() {
        let args = json!({ "query": "bioskop malang", "queries": ["other"] });
        assert_eq!(search_query_from_args(&args), "bioskop malang");
    }

    #[test]
    fn search_query_from_args_falls_back_to_queries_array() {
        let args = json!({ "queries": ["", "bioskop malang film"] });
        assert_eq!(search_query_from_args(&args), "bioskop malang film");
    }

    #[test]
    fn search_query_from_args_empty_when_missing() {
        assert!(search_query_from_args(&json!({})).is_empty());
        assert!(search_query_from_args(&json!({ "queries": [] })).is_empty());
    }
}
