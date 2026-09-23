use serde_json::{json, Value};

pub struct ParseOut {
    pub text: String,
    pub thought: String,
    pub function_call: Option<(String, Value)>,
    pub in_tok: i32,
    pub out_tok: i32,
    pub model_content: Value,
}

pub fn thinking_level(raw: &str) -> String {
    let t = raw.trim();
    if t.is_empty() { "off".into() } else { t.to_string() }
}

pub fn part_is_thought(part: &Value) -> bool {
    match part.get("thought") {
        Some(Value::Bool(true)) => true,
        Some(Value::String(s)) if !s.is_empty() => true,
        _ => false,
    }
}

pub fn gemini_thinking_config(model: &str, level: &str) -> Value {
    let m = model.to_ascii_lowercase();
    let gemini3 = m.contains("gemini-3") || (m.contains("flash-lite") && m.contains("3."));
    let lvl = level.trim().to_ascii_lowercase();
    if gemini3 {
        let thinking_level = match lvl.as_str() {
            "off" | "none" | "minimal" => "MINIMAL",
            "medium" => "MEDIUM",
            "high" => "HIGH",
            _ => "LOW",
        };
        return json!({ "thinkingLevel": thinking_level, "includeThoughts": thinking_level != "MINIMAL" });
    }
    let budget = match lvl.as_str() {
        "off" | "none" => 0,
        "medium" => 8192,
        "high" => 24576,
        _ => 1024,
    };
    json!({ "thinkingBudget": budget, "includeThoughts": budget > 0 })
}

pub fn parse_candidate(v: &Value) -> ParseOut {
    let in_tok = v["usageMetadata"]["promptTokenCount"].as_i64().unwrap_or(0) as i32;
    let out_tok = v["usageMetadata"]["candidatesTokenCount"].as_i64().unwrap_or(0) as i32;
    let content = v["candidates"][0]["content"].clone();
    let parts = content["parts"].as_array().cloned().unwrap_or_default();
    let mut text = String::new();
    let mut thought = String::new();
    let mut function_call = None;
    for part in &parts {
        if let Some(t) = part_thought_text(part) {
            let (th, vis) = thought_split(t);
            thought_push(&mut thought, &th);
            thought_push(&mut thought, &vis);
            continue;
        }
        if let Some(t) = part["text"].as_str() {
            let (th, vis) = thought_split(t);
            thought_push(&mut thought, &th);
            text.push_str(&vis);
        }
        if let Some(fc) = part.get("functionCall") {
            if function_call.is_none() {
                let name = fc.get("name").and_then(|n| n.as_str()).unwrap_or("").replace('_', ".");
                let args = fc.get("args").cloned().unwrap_or(json!({}));
                function_call = Some((name, args));
            }
        }
    }
    ParseOut { text, thought, function_call, in_tok, out_tok, model_content: content }
}

pub fn thought_split(raw: &str) -> (String, String) {
    let mut thought = String::new();
    let mut text = String::new();
    let mut rest = raw;
    while !rest.is_empty() {
        if let Some((name, body, next)) = take_channel(rest) {
            if matches!(name.as_str(), "thought" | "analysis" | "thinking") {
                thought_push(&mut thought, &body);
            } else {
                text.push_str(&body);
            }
            rest = next;
            continue;
        }
        if let Some((body, next)) = take_xml(rest, "thought").or_else(|| take_xml(rest, "think")) {
            thought_push(&mut thought, &body);
            rest = next;
            continue;
        }
        if rest.starts_with("<|") {
            if let Some(end) = rest.find("|>") {
                rest = &rest[end + 2..];
                continue;
            }
        }
        let ch = rest.chars().next().unwrap();
        let n = ch.len_utf8();
        if is_junk_control(ch) {
            rest = &rest[n..];
            continue;
        }
        text.push(ch);
        rest = &rest[n..];
    }
    (thought_clean(&thought), visible_clean(&text))
}

pub fn thought_push(dst: &mut String, piece: &str) {
    let p = piece.trim();
    if p.is_empty() { return; }
    if !dst.is_empty() { dst.push('\n'); }
    dst.push_str(p);
}

pub fn part_thought_text(part: &Value) -> Option<&str> {
    if !part_is_thought(part) { return None; }
    if let Some(t) = part["text"].as_str().filter(|s| !s.is_empty()) { return Some(t); }
    part.get("thought").and_then(|t| t.as_str()).filter(|s| !s.is_empty())
}

fn find_ci(hay: &str, needle: &str) -> Option<usize> {
    let h = hay.as_bytes();
    let n = needle.as_bytes();
    if n.is_empty() || h.len() < n.len() { return None; }
    (0..=h.len() - n.len()).find(|&i| h[i..i + n.len()].eq_ignore_ascii_case(n))
}

fn take_channel(rest: &str) -> Option<(String, String, &str)> {
    if find_ci(rest, "<|channel|>") != Some(0) { return None; }
    let after = &rest["<|channel|>".len()..];
    let msg_at = find_ci(after, "<|message|>")?;
    let name = after[..msg_at].trim().to_ascii_lowercase();
    let body_src = &after[msg_at + "<|message|>".len()..];
    let end = find_ci(body_src, "<|channel|>").or_else(|| find_ci(body_src, "<|end|>")).unwrap_or(body_src.len());
    Some((name, body_src[..end].to_string(), &body_src[end..]))
}

fn take_xml<'a>(rest: &'a str, tag: &str) -> Option<(String, &'a str)> {
    let open = format!("<{tag}>");
    let close = format!("</{tag}>");
    if find_ci(rest, &open) != Some(0) { return None; }
    let inner = &rest[open.len()..];
    let c = find_ci(inner, &close)?;
    Some((inner[..c].to_string(), &inner[c + close.len()..]))
}

fn is_junk_control(c: char) -> bool {
    let u = c as u32;
    (u < 32 && c != '\n' && c != '\t') || (0x7F..=0x9F).contains(&u)
}

fn thought_clean(raw: &str) -> String { visible_clean(raw) }

fn visible_clean(raw: &str) -> String {
    raw.chars().filter(|c| !is_junk_control(*c)).collect::<String>().trim().to_string()
}
