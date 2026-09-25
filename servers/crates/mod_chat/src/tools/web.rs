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

#[derive(Debug, Clone, Default)]
pub struct SearchGeoContext {
    pub city: String,
    pub region: String,
    pub country: String,
    pub locale: String,
}

impl SearchGeoContext {
    pub fn from_tool_ctx(city: &str, region: &str, country: &str, locale: &str) -> Self {
        Self {
            city: city.trim().to_string(),
            region: region.trim().to_string(),
            country: country.trim().to_ascii_uppercase(),
            locale: locale.trim().to_string(),
        }
    }

    pub fn is_empty(&self) -> bool {
        self.city.is_empty() && self.region.is_empty() && self.country.is_empty() && self.locale.is_empty()
    }
}

/// SearXNG `language` query param from user country + locale (no lat/lng API).
pub fn searx_language_tag(country: &str, locale: &str) -> String {
    let country = country.trim().to_ascii_uppercase();
    let loc = locale.trim().to_ascii_lowercase();
    match country.as_str() {
        "ID" => "id-ID".into(),
        "SG" => "en-SG".into(),
        "MY" if loc.starts_with("ms") => "ms-MY".into(),
        "MY" => "en-MY".into(),
        "JP" => "ja-JP".into(),
        "AU" => "en-AU".into(),
        "GB" | "IE" => "en-GB".into(),
        _ if loc.starts_with("id") => "id-ID".into(),
        _ if loc.starts_with("en") => "en-US".into(),
        _ => String::new(),
    }
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

pub async fn web_search_exec(
    client: &Client,
    query: &str,
    limit: u32,
    geo: Option<&SearchGeoContext>,
) -> Result<Value> {
    let query = query.trim();
    if query.is_empty() {
        bail!("Search query cannot be empty");
    }
    let limit = limit.clamp(1, 12);
    let base = std::env::var("SEARX_URL")
        .ok()
        .filter(|s| !s.trim().is_empty())
        .unwrap_or_else(|| "http://searxng.searx.svc.cluster.local:8080".into());
    let search_language = geo
        .map(|g| searx_language_tag(&g.country, &g.locale))
        .filter(|s| !s.is_empty())
        .unwrap_or_default();
    let mut url = format!(
        "{}/search?q={}&format=json&categories=general",
        base.trim_end_matches('/'),
        urlencoding::encode(query)
    );
    if !search_language.is_empty() {
        url.push_str("&language=");
        url.push_str(&urlencoding::encode(&search_language));
    }
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
        "search_language": search_language,
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

    #[test]
    fn searx_language_tag_indonesia() {
        assert_eq!(searx_language_tag("ID", "id-ID"), "id-ID");
        assert_eq!(searx_language_tag("ID", "en_US"), "id-ID");
        assert_eq!(searx_language_tag("", "id-ID"), "id-ID");
    }

    #[test]
    fn searx_language_tag_singapore_malaysia() {
        assert_eq!(searx_language_tag("SG", "en"), "en-SG");
        assert_eq!(searx_language_tag("MY", "ms-MY"), "ms-MY");
        assert_eq!(searx_language_tag("MY", "en"), "en-MY");
    }

    #[test]
    fn searx_language_tag_default_empty_for_unknown() {
        assert_eq!(searx_language_tag("DE", "de"), "");
        assert_eq!(searx_language_tag("", "fr"), "");
    }
}
