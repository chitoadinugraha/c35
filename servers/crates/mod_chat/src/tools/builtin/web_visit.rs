use std::time::Duration;

use anyhow::{bail, Result};
use reqwest::Client;
use serde_json::{json, Value};

use crate::tool;

const DEFAULT_MAX_CHARS: usize = 4000;
const ABSOLUTE_MAX_CHARS: usize = 8000;
const VISIT_TIMEOUT_SECS: u64 = 15;

pub async fn web_visit_exec(client: &Client, url_str: &str, max_chars: Option<usize>) -> Result<Value> {
    let url_str = url_str.trim();
    if url_str.is_empty() {
        bail!("URL cannot be empty");
    }
    let max_len = max_chars.unwrap_or(DEFAULT_MAX_CHARS).clamp(500, ABSOLUTE_MAX_CHARS);
    let res = match client
        .get(url_str)
        .timeout(Duration::from_secs(VISIT_TIMEOUT_SECS))
        .header(
            "User-Agent",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 AlienAIAgent/1.0",
        )
        .header("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,text/plain;q=0.8,*/*;q=0.7")
        .header("Accept-Language", "en-US,en;q=0.9,id;q=0.8")
        .send()
        .await
    {
        Ok(r) => r,
        Err(e) => {
            return Ok(json!({
                "ok": false,
                "runner": "cluster",
                "tool": "web.visit",
                "url": url_str,
                "error": format!("Failed to fetch URL: {}", e),
            }));
        }
    };
    if !res.status().is_success() {
        return Ok(json!({
            "ok": false,
            "runner": "cluster",
            "tool": "web.visit",
            "url": url_str,
            "status_code": res.status().as_u16(),
            "error": format!("HTTP error {}", res.status()),
        }));
    }
    let final_url = res.url().to_string();
    let body_html = res.text().await.unwrap_or_default();
    let title = extract_title(&body_html);
    let description = extract_description(&body_html);
    let clean_text = extract_readable_text(&body_html, max_len);
    Ok(json!({
        "ok": true,
        "runner": "cluster",
        "tool": "web.visit",
        "url": final_url,
        "title": title,
        "description": description,
        "content": clean_text,
        "length": clean_text.chars().count(),
    }))
}

pub fn extract_title(html: &str) -> String {
    let lower = html.to_lowercase();
    if let Some(pos) = lower.find("<title") {
        if let Some(close_tag) = html[pos..].find('>') {
            let start = pos + close_tag + 1;
            if let Some(end) = html[start..].to_lowercase().find("</title>") {
                return decode_html_entities(html[start..start + end].trim());
            }
        }
    }
    String::new()
}

pub fn extract_description(html: &str) -> String {
    let lower = html.to_lowercase();
    for target in ["name=\"description\"", "property=\"og:description\"", "name=\"og:description\""] {
        if let Some(pos) = lower.find(target) {
            let tag_start = html[..pos].rfind('<').unwrap_or(0);
            let tag_end = html[pos..].find('>').map(|p| pos + p).unwrap_or(html.len());
            let tag_content = &html[tag_start..tag_end];
            if let Some(c_pos) = tag_content.to_lowercase().find("content=\"") {
                let val_start = c_pos + 9;
                if let Some(val_end) = tag_content[val_start..].find('"') {
                    return decode_html_entities(&tag_content[val_start..val_start + val_end]);
                }
            }
        }
    }
    String::new()
}

pub fn extract_readable_text(html: &str, max_chars: usize) -> String {
    let mut s = html.to_string();
    while let Some(start) = s.find("<!--") {
        if let Some(end) = s[start..].find("-->") {
            s.replace_range(start..start + end + 3, " ");
        } else {
            break;
        }
    }
    for tag in ["script", "style", "noscript", "svg", "nav", "footer", "header", "form", "aside"] {
        let open_pat = format!("<{tag}");
        let close_pat = format!("</{tag}>");
        while let Some(start) = s.to_lowercase().find(&open_pat) {
            if let Some(end) = s[start..].to_lowercase().find(&close_pat) {
                s.replace_range(start..start + end + close_pat.len(), "\n");
            } else if let Some(tag_end) = s[start..].find('>') {
                s.replace_range(start..start + tag_end + 1, " ");
            } else {
                break;
            }
        }
    }
    s = s.replace("<br>", "\n").replace("<br/>", "\n").replace("<br />", "\n");
    s = s.replace("<p>", "\n\n").replace("</p>", "\n");
    let mut out = String::with_capacity(s.len());
    let mut in_tag = false;
    for ch in s.chars() {
        if ch == '<' {
            in_tag = true;
        } else if ch == '>' {
            in_tag = false;
        } else if !in_tag {
            out.push(ch);
        }
    }
    let decoded = decode_html_entities(&out);
    let formatted = decoded.lines().map(str::trim).filter(|l| !l.is_empty()).collect::<Vec<_>>().join("\n");
    if formatted.chars().count() <= max_chars {
        return formatted;
    }
    formatted.chars().take(max_chars).collect::<String>() + "…"
}

fn decode_html_entities(s: &str) -> String {
    s.replace("&amp;", "&")
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&quot;", "\"")
        .replace("&#39;", "'")
        .replace("&nbsp;", " ")
}

tool! {
    struct: WebVisitTool,
    name: "web.visit",
    aliases: ["web_visit", "fetch_url"],
    description: "Visit an HTTP/HTTPS URL, strip HTML, and return readable text. Use after web.search when you need page content.",
    topics: ["*", "research"],
    always: ["research"],
    ui_calling_key: "tool.web.visit.calling",
    ui_done_key: "tool.web.visit.done",
    parameters: {
        url: (string, "Full HTTP/HTTPS URL", required),
        max_chars: (integer, "Max readable characters (default 4000)", optional, default = 4000),
    },
    execute: |args, ctx| {
        let url = args["url"].as_str().unwrap_or_default();
        let max_chars = args["max_chars"].as_u64().map(|n| n as usize);
        if url.trim().is_empty() {
            bail!("URL cannot be empty");
        }
        web_visit_exec(&ctx.http_client, url, max_chars).await
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn extract_readable_text_strips_tags() {
        let html = "<html><body><p>Hello <b>world</b></p></body></html>";
        assert!(extract_readable_text(html, 100).contains("Hello"));
    }
}
