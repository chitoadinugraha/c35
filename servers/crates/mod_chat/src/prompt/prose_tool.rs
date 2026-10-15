use serde_json::{json, Map, Value};

use super::thought::{FunctionCallItem, ParseOut};
use crate::tools::ToolDef;

/// When the model prints a fenced tool call as text, recover and run it like a native functionCall.
pub fn apply_prose_tool_calls(mut out: ParseOut, tools: &[ToolDef]) -> ParseOut {
    if !out.function_calls.is_empty() {
        return out;
    }
    let calls = prose_tool_calls_from_text(&out.text, tools);
    if calls.is_empty() {
        return out;
    }
    out.function_calls = calls;
    out.function_call = out.function_calls.first().cloned();
    out.text = strip_prose_tool_blocks(&out.text);
    out
}

fn tool_name_known(name: &str, tools: &[ToolDef]) -> bool {
    let n = name.trim();
    if n.is_empty() {
        return false;
    }
    let dotted = n.replace('_', ".");
    let underscored = n.replace('.', "_");
    tools.iter().any(|t| t.name == n || t.name == dotted || t.name == underscored)
}

fn normalize_tool_name(name: &str, tools: &[ToolDef]) -> String {
    let n = name.trim();
    let dotted = n.replace('_', ".");
    if tools.iter().any(|t| t.name == dotted) {
        return dotted;
    }
    let underscored = n.replace('.', "_");
    if tools.iter().any(|t| t.name == underscored) {
        return underscored;
    }
    dotted
}

fn parse_tool_call_object(v: &Value) -> Option<(String, Value)> {
    let name = v
        .get("name")
        .and_then(|n| n.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())?;
    let args = v
        .get("arguments")
        .or_else(|| v.get("args"))
        .cloned()
        .unwrap_or_else(|| json!({}));
    Some((name.to_string(), args))
}

fn try_push_call(
    out: &mut Vec<FunctionCallItem>,
    name: &str,
    args: Value,
    tools: &[ToolDef],
) -> bool {
    if !tool_name_known(name, tools) {
        return false;
    }
    let norm = normalize_tool_name(name, tools);
    out.push((norm, args, None));
    true
}

pub fn prose_tool_calls_from_text(text: &str, tools: &[ToolDef]) -> Vec<FunctionCallItem> {
    let mut out = Vec::new();
    for block in fenced_code_blocks(text) {
        let trimmed = block.trim();
        if trimmed.is_empty() {
            continue;
        }
        if let Some((name, args)) = parse_tool_pseudo_call(trimmed) {
            if try_push_call(&mut out, &name, args, tools) {
                continue;
            }
        }
        if let Ok(v) = serde_json::from_str::<Value>(trimmed) {
            if let Some((name, args)) = parse_tool_call_object(&v) {
                if try_push_call(&mut out, &name, args, tools) {
                    continue;
                }
            }
        }
        if let Some((name, args)) = parse_tool_name_then_json(trimmed) {
            try_push_call(&mut out, &name, args, tools);
        }
    }
    out
}

/// `admin.user.registrations.list(range="today", count_only=true)`
fn parse_tool_pseudo_call(block: &str) -> Option<(String, Value)> {
    let s = block.trim();
    let open = s.find('(')?;
    let close = s.rfind(')')?;
    if close <= open {
        return None;
    }
    let name = s[..open].trim();
    if !name.contains('.') && !name.contains('_') {
        return None;
    }
    let inner = s[open + 1..close].trim();
    let args = parse_simple_call_args(inner)?;
    Some((name.to_string(), args))
}

fn parse_simple_call_args(inner: &str) -> Option<Value> {
    if inner.is_empty() {
        return Some(json!({}));
    }
    let mut map = Map::new();
    for part in split_call_arg_parts(inner) {
        let part = part.trim();
        if part.is_empty() {
            continue;
        }
        let (key, val_raw) = part.split_once('=')?;
        let key = key.trim();
        if key.is_empty() {
            return None;
        }
        map.insert(key.to_string(), parse_simple_value(val_raw.trim())?);
    }
    Some(Value::Object(map))
}

fn split_call_arg_parts(inner: &str) -> Vec<String> {
    let mut parts = Vec::new();
    let mut cur = String::new();
    let mut in_quote = false;
    let mut quote_ch = '"';
    for ch in inner.chars() {
        if in_quote {
            cur.push(ch);
            if ch == quote_ch {
                in_quote = false;
            }
            continue;
        }
        if ch == '"' || ch == '\'' {
            in_quote = true;
            quote_ch = ch;
            cur.push(ch);
            continue;
        }
        if ch == ',' {
            parts.push(cur);
            cur = String::new();
            continue;
        }
        cur.push(ch);
    }
    if !cur.is_empty() {
        parts.push(cur);
    }
    parts
}

fn parse_simple_value(raw: &str) -> Option<Value> {
    if raw.eq_ignore_ascii_case("true") {
        return Some(Value::Bool(true));
    }
    if raw.eq_ignore_ascii_case("false") {
        return Some(Value::Bool(false));
    }
    if raw.eq_ignore_ascii_case("null") {
        return Some(Value::Null);
    }
    if (raw.starts_with('"') && raw.ends_with('"') && raw.len() >= 2)
        || (raw.starts_with('\'') && raw.ends_with('\'') && raw.len() >= 2)
    {
        return Some(Value::String(raw[1..raw.len() - 1].to_string()));
    }
    if let Ok(n) = raw.parse::<i64>() {
        return Some(json!(n));
    }
    if let Ok(n) = raw.parse::<f64>() {
        return Some(json!(n));
    }
    if !raw.is_empty() {
        return Some(Value::String(raw.to_string()));
    }
    None
}

fn parse_tool_name_then_json(block: &str) -> Option<(String, Value)> {
    let mut lines = block.lines();
    let first = lines.next()?.trim();
    if first.is_empty() || first.starts_with('{') {
        return None;
    }
    if let Some((name, args)) = parse_tool_pseudo_call(first) {
        return Some((name, args));
    }
    let name = first.trim_start_matches("```").trim().to_string();
    if !name.contains('.') && !name.contains('_') {
        return None;
    }
    let rest_joined = lines.collect::<Vec<_>>().join("\n");
    let rest = rest_joined.trim();
    if rest.is_empty() {
        return Some((name, json!({})));
    }
    let args = serde_json::from_str::<Value>(rest).ok()?;
    Some((name, args))
}

fn block_looks_like_tool_call(block: &str) -> bool {
    let trimmed = block.trim();
    if trimmed.is_empty() {
        return false;
    }
    if parse_tool_pseudo_call(trimmed).is_some() {
        return true;
    }
    if let Ok(v) = serde_json::from_str::<Value>(trimmed) {
        if parse_tool_call_object(&v).is_some() {
            return true;
        }
    }
    parse_tool_name_then_json(trimmed).is_some()
}

fn fenced_code_blocks(text: &str) -> Vec<String> {
    let mut blocks = Vec::new();
    let parts: Vec<&str> = text.split("```").collect();
    if parts.len() < 3 {
        return blocks;
    }
    let mut i = 1;
    while i + 1 < parts.len() {
        let mut body = parts[i].to_string();
        if let Some(stripped) = body.strip_prefix("json") {
            body = stripped
                .trim_start_matches('\n')
                .trim_start_matches('\r')
                .to_string();
        } else if let Some((lang, rest)) = body.split_once('\n') {
            if lang.chars().all(|c| c.is_ascii_alphanumeric() || c == '-' || c == '_')
                && !lang.contains('.')
            {
                body = rest.to_string();
            }
        }
        blocks.push(body);
        i += 2;
    }
    blocks
}

fn strip_prose_tool_blocks(text: &str) -> String {
    let mut out = String::new();
    let parts: Vec<&str> = text.split("```").collect();
    for (idx, part) in parts.iter().enumerate() {
        if idx % 2 == 1 {
            if block_looks_like_tool_call(part) {
                continue;
            }
            out.push_str("```");
            out.push_str(part);
            out.push_str("```");
            continue;
        }
        out.push_str(part);
    }
    out.trim().to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn reg_tool() -> ToolDef {
        ToolDef::new(
            "admin.user.registrations.list".into(),
            String::new(),
            json!({}),
        )
    }

    #[test]
    fn prose_json_name_arguments() {
        let text = "```json\n{\"name\":\"admin.user.registrations.list\",\"arguments\":{\"range\":\"today\",\"count_only\":true}}\n```";
        let calls = prose_tool_calls_from_text(text, &[reg_tool()]);
        assert_eq!(calls.len(), 1);
        assert_eq!(calls[0].0, "admin.user.registrations.list");
        assert_eq!(calls[0].1["range"], "today");
    }

    #[test]
    fn prose_tool_name_fence() {
        let text = "```admin.user.registrations.list\n{\"preset\":\"today\"}\n```";
        let calls = prose_tool_calls_from_text(text, &[reg_tool()]);
        assert_eq!(calls.len(), 1);
        assert_eq!(calls[0].1["preset"], "today");
    }

    #[test]
    fn prose_pseudo_function_call() {
        let text = "```admin.user.registrations.list(range=\"today\", count_only=true)```";
        let calls = prose_tool_calls_from_text(text, &[reg_tool()]);
        assert_eq!(calls.len(), 1);
        assert_eq!(calls[0].0, "admin.user.registrations.list");
        assert_eq!(calls[0].1["range"], "today");
        assert_eq!(calls[0].1["count_only"], true);
    }
}
