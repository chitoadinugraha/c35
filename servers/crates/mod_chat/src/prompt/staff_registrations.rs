use serde_json::{json, Value};

use crate::tools::ToolDef;

pub fn staff_registrations_should_prefetch(matched_inst_ids: &[String], tools: &[ToolDef]) -> bool {
    matched_inst_ids.iter().any(|id| id == "inst.staff.registrations")
        && tools.iter().any(|t| t.name == "admin.user.registrations.list")
}

/// Staff signup/list wording — skip generic web prefetch (`siapa ` heuristics, etc.).
pub fn user_text_looks_like_staff_registrations_intent(text: &str) -> bool {
    let t = text.trim().to_ascii_lowercase();
    if t.is_empty() {
        return false;
    }
    [
        "mendaftar",
        "registrasi",
        "signups",
        "who registered",
        "user registrations",
        "daftar user",
        "list user baru",
        "user baru",
        "new users",
    ]
    .iter()
    .any(|k| t.contains(k))
        || t == "siapa saja"
        || t.contains("siapa saja")
        || t.contains("siapa aja")
        || t.contains("daftar siapa")
        || t.contains("siapa yang mendaftar")
        || t.contains("berapa user")
        || t.contains("berapa yang mendaftar")
}

pub fn staff_registrations_tool_args(user_text: &str) -> Value {
    let preset = registrations_preset_from_user(user_text);
    let count_only = registrations_count_only_from_user(user_text);
    json!({
        "preset": preset,
        "count_only": count_only,
    })
}

fn registrations_preset_from_user(text: &str) -> String {
    let t = text.to_ascii_lowercase();
    if t.contains("minggu lalu") || t.contains("last week") {
        return "last_week".into();
    }
    if t.contains("minggu ini") || t.contains("this week") {
        return "this_week".into();
    }
    if t.contains("bulan lalu") || t.contains("last month") {
        return "last_month".into();
    }
    if t.contains("bulan ini") || t.contains("this month") {
        return "this_month".into();
    }
    if t.contains("kemarin") || t.contains("yesterday") {
        return "yesterday".into();
    }
    if t.contains("hari ini") || t.contains("today") {
        return "today".into();
    }
    "today".into()
}

fn registrations_count_only_from_user(text: &str) -> bool {
    let t = text.to_ascii_lowercase();
    t.contains("berapa")
        || t.contains("how many")
        || t.contains("jumlah")
        || t.contains("total")
        || t.contains("count")
}

/// Gemini 3-safe: inject tool JSON on the latest user turn (no synthetic functionCall).
pub fn staff_registrations_append_user_context(contents: &mut Vec<Value>, result: &Value) {
    let mut block = String::from("[STAFF REGISTRATIONS — answer only from this data]\n");
    if result.get("ok").and_then(|v| v.as_bool()) == Some(true) {
        if let Some(count) = result.get("count").and_then(|v| v.as_i64()) {
            block.push_str(&format!("count: {count}\n"));
        }
        if let Some(users) = result.get("users").and_then(|v| v.as_array()) {
            if !users.is_empty() {
                block.push_str(&serde_json::to_string_pretty(users).unwrap_or_default());
                block.push('\n');
            }
        }
        if let Some(tz) = result.get("timezone_used").and_then(|v| v.as_str()) {
            block.push_str(&format!("timezone: {tz}\n"));
        }
    } else {
        block.push_str(&serde_json::to_string_pretty(result).unwrap_or_default());
        block.push('\n');
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
    contents.push(json!({
        "role": "user",
        "parts": [part]
    }));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn preset_today_for_hari_ini() {
        assert_eq!(
            registrations_preset_from_user("berapa yang mendaftar hari ini ?"),
            "today"
        );
    }

    #[test]
    fn count_only_for_berapa() {
        assert!(registrations_count_only_from_user("berapa yang mendaftar hari ini ?"));
    }

    #[test]
    fn staff_intent_siapa_saja() {
        assert!(user_text_looks_like_staff_registrations_intent("siapa saja"));
    }

    #[test]
    fn staff_intent_not_apa_itu() {
        assert!(!user_text_looks_like_staff_registrations_intent("apa itu alien ai"));
    }
}
