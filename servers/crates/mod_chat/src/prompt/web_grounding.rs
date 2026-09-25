use serde_json::Value;

pub const WEB_GROUNDED_REPLY_RULE: &str =
    "\n\n[WEB GROUNDING] Answer only from web.search / web.visit tool results in this conversation. Never invent schedules or use placeholder titles (Film A, Film B, Film C, etc.). If results are empty or unclear, say you could not load live listings and suggest official cinema apps.";

pub fn search_payload(result: &Value) -> &Value {
    result.get("llm").filter(|v| v.is_object()).unwrap_or(result)
}

pub fn search_result_urls(result: &Value, limit: usize) -> Vec<String> {
    let root = search_payload(result);
    root.get("results")
        .and_then(|r| r.as_array())
        .map(|arr| {
            arr.iter()
                .take(limit)
                .filter_map(|item| item.get("url").and_then(|u| u.as_str()))
                .map(|s| s.trim())
                .filter(|u| u.starts_with("http"))
                .map(|s| s.to_string())
                .collect()
        })
        .unwrap_or_default()
}

pub fn pick_visit_url(search_result: &Value) -> Option<String> {
    let urls = search_result_urls(search_result, 10);
    if urls.is_empty() {
        return None;
    }
    const PREFER: &[&str] = &[
        "jadwalnonton",
        "21cineplex",
        "xxi",
        "tix.id",
        "cgv",
        "cinepolis",
        "cinema",
        "bioskop",
    ];
    for key in PREFER {
        if let Some(u) = urls.iter().find(|u| u.to_ascii_lowercase().contains(key)) {
            return Some(u.clone());
        }
    }
    urls.first().cloned()
}

pub fn reply_looks_like_web_placeholder(text: &str) -> bool {
    let t = text.to_ascii_lowercase();
    ["film a", "film b", "film c", "**film a**", "**film b**"]
        .iter()
        .any(|k| t.contains(k))
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn pick_visit_url_prefers_cinema_site() {
        let search = json!({
            "results": [
                { "url": "https://wikipedia.org/wiki/Cinema" },
                { "url": "https://jadwalnonton.com/bioskop/malang" }
            ]
        });
        assert_eq!(
            pick_visit_url(&search).as_deref(),
            Some("https://jadwalnonton.com/bioskop/malang")
        );
    }

    #[test]
    fn reply_placeholder_detected() {
        assert!(reply_looks_like_web_placeholder("Film A and Film B today"));
        assert!(!reply_looks_like_web_placeholder("Dune: Part Three — 14:30"));
    }
}
