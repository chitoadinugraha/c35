use blake3;
use serde_json::{json, Value};

use super::store::PromptRunRow;

pub const PROMPT_RUN_MAX_TURNS_DEFAULT: i32 = 100;
pub const PROMPT_RUN_MAX_DELIVER: i32 = 3;
pub const PROMPT_RUN_MAX_CONCURRENT_DEFAULT: usize = 8;

pub fn prompt_run_max_concurrent() -> usize {
    std::env::var("PROMPT_RUN_MAX_CONCURRENT")
        .ok()
        .and_then(|s| s.parse().ok())
        .filter(|n| *n >= 1)
        .unwrap_or(PROMPT_RUN_MAX_CONCURRENT_DEFAULT)
}

pub const CK_ERROR_FINGERPRINT: &str = "error_fingerprint";
pub const CK_ERROR_COUNT: &str = "error_count";
pub const CK_SCREENSHOT_HASHES: &str = "screenshot_hashes";
pub const CK_DEVICE_INPUT_COUNT: &str = "device_input_count";
pub const CK_SCREENSHOT_COUNT: &str = "screenshot_count";
pub const CK_FAIL_CLASS: &str = "fail_class";
pub const CK_FAIL_REASON: &str = "fail_reason";

pub const FATAL_ERROR_THRESHOLD: i32 = 2;
pub const SCREENSHOT_STUCK_LEN: usize = 3;
pub const COMPUTER_USE_MAX_ROUNDS: u8 = 16;
pub const COMPUTER_USE_MAX_DEVICE_INPUT: i32 = 12;
pub const COMPUTER_USE_MAX_SCREENSHOTS: i32 = 20;

pub fn chat_tool_rounds_max(run_kind: &str) -> u8 {
    if run_kind == "computer_use" {
        COMPUTER_USE_MAX_ROUNDS
    } else {
        24
    }
}

pub fn checkpoint_error_fingerprint(error: &str) -> String {
    blake3::hash(error.trim().as_bytes()).to_hex().to_string()
}

pub fn checkpoint_record_error(checkpoint: &mut Value, error: &str) -> Value {
    let fp = checkpoint_error_fingerprint(error);
    let prev_fp = checkpoint
        .get(CK_ERROR_FINGERPRINT)
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let count = checkpoint
        .get(CK_ERROR_COUNT)
        .and_then(|v| v.as_i64())
        .unwrap_or(0) as i32;
    let new_count = if prev_fp == fp { count + 1 } else { 1 };
    checkpoint[CK_ERROR_FINGERPRINT] = json!(fp);
    checkpoint[CK_ERROR_COUNT] = json!(new_count);
    checkpoint.clone()
}

pub fn checkpoint_error_is_fatal(checkpoint: &Value, threshold: i32) -> bool {
    checkpoint
        .get(CK_ERROR_COUNT)
        .and_then(|v| v.as_i64())
        .unwrap_or(0) as i32
        >= threshold
}

pub fn checkpoint_record_screenshot_hash(checkpoint: &mut Value, image_bytes: &[u8]) -> Value {
    let hash = blake3::hash(image_bytes).to_hex().to_string();
    checkpoint_record_screenshot_hash_hex(checkpoint, &hash)
}

pub fn checkpoint_record_screenshot_hash_hex(checkpoint: &mut Value, hash: &str) -> Value {
    let mut list = checkpoint
        .get(CK_SCREENSHOT_HASHES)
        .and_then(|v| v.as_array())
        .cloned()
        .unwrap_or_default();
    list.push(json!(hash));
    while list.len() > SCREENSHOT_STUCK_LEN {
        list.remove(0);
    }
    checkpoint[CK_SCREENSHOT_HASHES] = json!(list);
    checkpoint.clone()
}

pub fn checkpoint_screenshot_stuck(checkpoint: &Value) -> bool {
    let hashes = match checkpoint.get(CK_SCREENSHOT_HASHES).and_then(|v| v.as_array()) {
        Some(h) => h,
        None => return false,
    };
    if hashes.len() < SCREENSHOT_STUCK_LEN {
        return false;
    }
    let tail = &hashes[hashes.len() - SCREENSHOT_STUCK_LEN..];
    let a = tail[0].as_str().filter(|s| !s.is_empty());
    let b = tail[1].as_str();
    let c = tail[2].as_str();
    matches!((a, b, c), (Some(a), Some(b), Some(c)) if a == b && b == c)
}

pub fn checkpoint_fatal_class(checkpoint: &Value) -> Option<&str> {
    checkpoint
        .get(CK_FAIL_CLASS)
        .and_then(|v| v.as_str())
        .filter(|s| s.starts_with("fatal_"))
}

pub fn checkpoint_fatal_fail_class(checkpoint: &Value) -> Option<String> {
    checkpoint_fatal_class(checkpoint).map(str::to_string)
}

pub fn checkpoint_set_fatal(checkpoint: &mut Value, fail_class: &str, fail_reason: &str) {
    checkpoint[CK_FAIL_CLASS] = json!(fail_class);
    checkpoint[CK_FAIL_REASON] = json!(fail_reason);
}

pub fn checkpoint_fail_reason(checkpoint: &Value) -> Option<&str> {
    checkpoint.get(CK_FAIL_REASON).and_then(|v| v.as_str())
}

fn checkpoint_image_b64(result: &Value) -> Option<&str> {
    result
        .get("llm")
        .and_then(|v| v.get("image_base64"))
        .or_else(|| result.get("image_base64"))
        .and_then(|v| v.as_str())
        .filter(|s| !s.is_empty())
}

pub fn checkpoint_record_tool(checkpoint: &mut Value, tool_name: &str, result: &Value) {
    let norm = tool_name.replace('_', ".");
    if norm == "device.input" {
        let n = checkpoint
            .get(CK_DEVICE_INPUT_COUNT)
            .and_then(|v| v.as_i64())
            .unwrap_or(0)
            + 1;
        checkpoint[CK_DEVICE_INPUT_COUNT] = json!(n);
    }
    if norm == "device.screenshot" {
        let n = checkpoint
            .get(CK_SCREENSHOT_COUNT)
            .and_then(|v| v.as_i64())
            .unwrap_or(0)
            + 1;
        checkpoint[CK_SCREENSHOT_COUNT] = json!(n);
        if let Some(b64) = checkpoint_image_b64(result) {
            checkpoint_record_screenshot_hash(checkpoint, b64.as_bytes());
        }
    }
    let ok = result.get("ok").and_then(|v| v.as_bool()).unwrap_or(true);
    if !ok {
        let err = result
            .get("error")
            .and_then(|v| v.as_str())
            .unwrap_or("tool failed");
        checkpoint_record_error(checkpoint, err);
    }
}

pub fn checkpoint_tool_should_stop(checkpoint: &Value, kind: &str) -> Option<(&'static str, &'static str)> {
    if checkpoint_fatal_class(checkpoint).is_some() {
        return Some(("fatal_checkpoint", "checkpoint marked fatal"));
    }
    if checkpoint_error_is_fatal(checkpoint, FATAL_ERROR_THRESHOLD) {
        return Some(("fatal_repeat", "same tool error repeated twice"));
    }
    if checkpoint_screenshot_stuck(checkpoint) {
        return Some(("stuck_ui", "desktop unchanged across last 3 screenshots"));
    }
    if kind != "computer_use" {
        return None;
    }
    let inputs = checkpoint
        .get(CK_DEVICE_INPUT_COUNT)
        .and_then(|v| v.as_i64())
        .unwrap_or(0) as i32;
    if inputs >= COMPUTER_USE_MAX_DEVICE_INPUT {
        return Some(("turn_cap", "device.input limit reached"));
    }
    let shots = checkpoint
        .get(CK_SCREENSHOT_COUNT)
        .and_then(|v| v.as_i64())
        .unwrap_or(0) as i32;
    if shots >= COMPUTER_USE_MAX_SCREENSHOTS {
        return Some(("turn_cap", "screenshot limit reached"));
    }
    None
}

pub fn prompt_run_should_stop(row: &PromptRunRow) -> Option<&'static str> {
    if row.cancel_requested {
        return Some("cancel");
    }
    if row.turn_count >= row.max_turns {
        return Some("turn_cap");
    }
    if row.accumulated_cost_usd >= row.budget_usd_cap && row.budget_usd_cap > 0.0 {
        return Some("budget");
    }
    if row
        .fail_class
        .as_deref()
        .is_some_and(|s| s.starts_with("fatal_"))
    {
        return Some("fatal");
    }
    let cp = &row.checkpoint_json.0;
    if checkpoint_fatal_fail_class(cp).is_some() {
        return Some("fatal_checkpoint");
    }
    if checkpoint_error_is_fatal(cp, FATAL_ERROR_THRESHOLD) {
        return Some("fatal_repeat");
    }
    if checkpoint_screenshot_stuck(cp) {
        return Some("stuck_ui");
    }
    if row.kind == "computer_use" {
        let inputs = cp
            .get(CK_DEVICE_INPUT_COUNT)
            .and_then(|v| v.as_i64())
            .unwrap_or(0) as i32;
        if inputs >= COMPUTER_USE_MAX_DEVICE_INPUT {
            return Some("turn_cap");
        }
        let shots = cp
            .get(CK_SCREENSHOT_COUNT)
            .and_then(|v| v.as_i64())
            .unwrap_or(0) as i32;
        if shots >= COMPUTER_USE_MAX_SCREENSHOTS {
            return Some("turn_cap");
        }
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn screenshot_stuck_after_three_identical_hashes() {
        let mut cp = json!({});
        checkpoint_record_screenshot_hash_hex(&mut cp, "abc");
        assert!(!checkpoint_screenshot_stuck(&cp));
        checkpoint_record_screenshot_hash_hex(&mut cp, "abc");
        assert!(!checkpoint_screenshot_stuck(&cp));
        checkpoint_record_screenshot_hash_hex(&mut cp, "abc");
        assert!(checkpoint_screenshot_stuck(&cp));
    }

    #[test]
    fn error_fingerprint_fatal_at_two() {
        let mut cp = json!({});
        checkpoint_record_error(&mut cp, "agent offline");
        assert!(!checkpoint_error_is_fatal(&cp, FATAL_ERROR_THRESHOLD));
        checkpoint_record_error(&mut cp, "agent offline");
        assert!(checkpoint_error_is_fatal(&cp, FATAL_ERROR_THRESHOLD));
        assert_eq!(
            checkpoint_tool_should_stop(&cp, "computer_use"),
            Some(("fatal_repeat", "same tool error repeated twice"))
        );
    }

    #[test]
    fn device_input_cap_for_computer_use() {
        let cp = json!({ CK_DEVICE_INPUT_COUNT: COMPUTER_USE_MAX_DEVICE_INPUT });
        assert_eq!(
            checkpoint_tool_should_stop(&cp, "computer_use"),
            Some(("turn_cap", "device.input limit reached"))
        );
        assert!(checkpoint_tool_should_stop(&cp, "main").is_none());
    }
}
