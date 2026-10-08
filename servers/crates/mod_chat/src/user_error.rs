const CHAT_USER_ERROR_FALLBACK: &str = "Something went wrong. Please try again.";

/// User-visible prompt/chat error (wire + clients). Full detail stays in `ai.chat_msg.error_text` for ops/root.
pub fn chat_user_error_message(raw: &str) -> String {
    let s = raw.trim();
    if s.is_empty() {
        return String::new();
    }
    if chat_error_is_user_facing(s) {
        return s.to_string();
    }
    if chat_error_looks_technical(s) || s.len() > 220 || s.contains('{') || s.contains('\n') {
        return CHAT_USER_ERROR_FALLBACK.into();
    }
    s.to_string()
}

fn chat_error_is_user_facing(s: &str) -> bool {
    let lower = s.to_ascii_lowercase();
    lower.contains("quota")
        || lower.contains("freemium")
        || lower.contains("allowance exhausted")
        || lower.contains("not enough balance")
        || lower.contains("session expired")
        || lower.contains("sign out and sign in")
        || lower.contains("daily message limit")
        || lower.contains("aborted")
}

fn chat_error_looks_technical(s: &str) -> bool {
    let lower = s.to_ascii_lowercase();
    lower.contains("gemini http")
        || lower.contains("invalid_argument")
        || lower.contains("failed_precondition")
        || lower.contains("thought_signature")
        || lower.contains("generativelanguage.googleapis.com")
        || lower.contains("openai")
        || lower.contains("anthropic")
        || lower.contains("vertex")
        || lower.contains("cloudflare")
        || (lower.contains("bad request") && lower.contains("gemini"))
        || (lower.contains("\"error\"") && s.contains('{'))
        || (lower.contains("\"status\"") && lower.contains("invalid"))
}

/// Prompt-end `trace_json` for WS + inbox (usage fallback + allowance pool hint).
pub fn prompt_end_trace_json(billing_included: bool, cost_usd: f64) -> String {
    serde_json::json!({
        "billing_included": billing_included,
        "cost_usd": cost_usd,
    })
    .to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hides_gemini_json_blob() {
        let raw = "gemini HTTP 400 Bad Request: {\n  \"error\": { \"status\": \"INVALID_ARGUMENT\" }\n}\n";
        assert_eq!(chat_user_error_message(raw), CHAT_USER_ERROR_FALLBACK);
    }

    #[test]
    fn keeps_quota_copy() {
        let raw = "quota exceeded: freemium daily limit: 30 messages per day used.";
        assert_eq!(chat_user_error_message(raw), raw);
    }
}
