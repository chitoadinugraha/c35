use serde_json::{json, Value};

pub const WEB_GROUNDED_REPLY_RULE: &str =
    "\n\n[WEB GROUNDING] Answer only from web.search / web.visit tool results in this conversation. Summarize what the tools returned (titles, times, venues, links). Never refuse with \"I cannot show\" when tool results are present. Never invent schedules or use placeholder titles (Film A, Film B, Film C, etc.). If results are empty or unclear, say you could not load live listings and suggest official cinema apps.";

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

pub fn user_query_wants_showtimes(query: &str) -> bool {
    let q = query.to_ascii_lowercase();
    [
        "jadwal",
        "jam tayang",
        "tayang",
        "showtime",
        "now playing",
        "nonton",
        "bioskop",
        "cinema",
        "film",
    ]
    .iter()
    .any(|k| q.contains(k))
}

pub fn pick_visit_url_for_query(search_result: &Value, user_query: &str) -> Option<String> {
    let urls = search_result_urls(search_result, 10);
    if urls.is_empty() {
        return None;
    }
    if user_query_wants_showtimes(user_query) {
        for u in &urls {
            let l = u.to_ascii_lowercase();
            if l.contains("now-playing") || l.contains("nowplaying") {
                return Some(u.clone());
            }
        }
        for u in &urls {
            let l = u.to_ascii_lowercase();
            if l.contains("21cineplex.com/theater/") || l.contains("teater.co/nowplaying") {
                return Some(u.clone());
            }
        }
    }
    pick_visit_url(search_result)
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

/// Append prefetch web.search / web.visit payloads to the latest user turn (Gemini 3-safe; no synthetic functionCall).
pub fn web_grounding_append_user_context(contents: &mut Vec<Value>, search: &Value, visit: Option<&Value>) {
    let root = search_payload(search);
    let mut block = String::from("[WEB SEARCH RESULTS — answer only from this data]\n");
    if let Some(results) = root.get("results").and_then(|r| r.as_array()) {
        for (i, item) in results.iter().take(6).enumerate() {
            let title = item.get("title").and_then(|v| v.as_str()).unwrap_or("").trim();
            let url = item.get("url").and_then(|v| v.as_str()).unwrap_or("").trim();
            let snippet = item.get("snippet").and_then(|v| v.as_str()).unwrap_or("").trim();
            block.push_str(&format!("\n{}. {}\n   {}\n   {}\n", i + 1, title, url, snippet));
        }
    }
    if let Some(visit) = visit {
        let url = visit.get("url").and_then(|v| v.as_str()).unwrap_or("").trim();
        let title = visit.get("title").and_then(|v| v.as_str()).unwrap_or("").trim();
        let content = visit
            .get("content")
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .trim();
        let clip = if content.len() > 12_000 {
            format!("{}…", &content[..12_000])
        } else {
            content.to_string()
        };
        block.push_str(&format!("\n[WEB PAGE — {}]\n{}\n{}\n", url, title, clip));
    }
    let part = json!({ "text": block });
    if let Some(last) = contents.last_mut() {
        if last.get("role").and_then(|r| r.as_str()) == Some("user") {
            if let Some(parts) = last.get_mut("parts").and_then(|p| p.as_array_mut()) {
                parts.push(part);
                return;
            }
        }
    }
    contents.push(json!({ "role": "user", "parts": [part] }));
}

pub fn reply_looks_like_web_placeholder(text: &str) -> bool {
    let t = text.to_ascii_lowercase();
    ["film a", "film b", "film c", "**film a**", "**film b**"]
        .iter()
        .any(|k| t.contains(k))
}

/// Model deflection despite web tools (links-only / \"cannot display live data\").
pub fn reply_looks_like_web_deferral(text: &str) -> bool {
    let t = text.to_ascii_lowercase();
    [
        "tidak dapat menampilkan",
        "cannot display",
        "can't display",
        "cannot show",
        "can't show",
        "unable to display",
        "unable to show",
        "secara langsung karena data",
        "bersifat dinamis",
        "berubah setiap saat",
        "real-time",
        "real time",
    ]
    .iter()
    .any(|k| t.contains(k))
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn pick_visit_url_for_query_prefers_now_playing() {
        let search = json!({
            "results": [
                { "url": "https://jadwalnonton.com/bioskop/di-malang/" },
                { "url": "https://jadwalnonton.com/now-playing/?city=23&page=1" }
            ]
        });
        assert_eq!(
            pick_visit_url_for_query(&search, "jadwal film malang hari ini").as_deref(),
            Some("https://jadwalnonton.com/now-playing/?city=23&page=1")
        );
    }

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

    #[test]
    fn reply_deferral_detected() {
        assert!(reply_looks_like_web_deferral(
            "Saya tidak dapat menampilkan daftar film dan jam tayang secara langsung"
        ));
        assert!(!reply_looks_like_web_deferral("Araya XXI — Dune 14:30, 17:00"));
    }

    #[test]
    fn web_grounding_appends_to_last_user_turn() {
        let search = json!({
            "results": [{ "title": "T1", "url": "https://example.com", "snippet": "S1" }]
        });
        let mut contents = vec![
            json!({ "role": "user", "parts": [{ "text": "hello" }] }),
        ];
        web_grounding_append_user_context(&mut contents, &search, None);
        assert_eq!(contents.len(), 1);
        let parts = contents[0]["parts"].as_array().unwrap();
        assert_eq!(parts.len(), 2);
        assert!(parts[1]["text"].as_str().unwrap().contains("WEB SEARCH RESULTS"));
    }
}
