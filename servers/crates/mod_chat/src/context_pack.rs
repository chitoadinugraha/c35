use crate::prompt::ChatHistoryMsg;

pub const CONTEXT_PACK_BUDGET_RATIO: f64 = 0.65;
pub const CONTEXT_RECENT_MSG_MIN: usize = 8;
pub const CONTEXT_RECENT_MSG_MAX: usize = 12;

pub fn model_context_limit(model: &str) -> i32 {
    let m = model.to_ascii_lowercase();
    if m.contains("gemini") { 1_000_000 } else { 128_000 }
}

pub fn token_estimate(text: &str) -> i32 {
    if text.is_empty() {
        return 0;
    }
    ((text.len() as f64) / 4.0).ceil() as i32
}

pub fn history_prune_for_prompt(content: &str, blocks_json: &str) -> String {
    let mut out = content.trim().to_string();
    if !blocks_json.is_empty() && blocks_json != "[]" {
        if out.is_empty() {
            out = "[tool output omitted from history]".into();
        } else {
            out.push_str("\n[tool output omitted from history]");
        }
    }
    if out.len() > 12_000 {
        out.truncate(12_000);
        out.push_str("…");
    }
    out
}

#[derive(Clone)]
pub struct HistoryRow {
    pub id: i64,
    pub role: String,
    pub content: String,
    pub blocks_json: String,
}

pub struct PackedHistory {
    pub messages: Vec<ChatHistoryMsg>,
    pub tokens_est: i32,
    pub dropped_count: i32,
}

pub fn context_pack_history(
    summary: &str,
    rows: &[HistoryRow],
    model: &str,
    system_tokens_est: i32,
    user_tokens_est: i32,
) -> PackedHistory {
    let limit = model_context_limit(model);
    let budget = ((limit as f64) * CONTEXT_PACK_BUDGET_RATIO).floor() as i32;
    let summary_tokens = token_estimate(summary);
    let reserve = system_tokens_est + user_tokens_est + summary_tokens + 512;
    let mut remaining = (budget - reserve).max(0);
    let mut picked: Vec<ChatHistoryMsg> = Vec::new();
    let mut used_tokens = 0i32;
    for row in rows {
        if picked.len() >= CONTEXT_RECENT_MSG_MAX {
            break;
        }
        let pruned = history_prune_for_prompt(&row.content, &row.blocks_json);
        if pruned.trim().is_empty() {
            continue;
        }
        let tok = token_estimate(&pruned);
        if !picked.is_empty() && tok > remaining && picked.len() >= CONTEXT_RECENT_MSG_MIN {
            break;
        }
        if tok > remaining && picked.len() >= CONTEXT_RECENT_MSG_MIN {
            break;
        }
        picked.push(ChatHistoryMsg { role: row.role.clone(), content: pruned });
        used_tokens += tok;
        remaining = (remaining - tok).max(0);
    }
    let dropped_count = rows.len().saturating_sub(picked.len()) as i32;
    picked.reverse();
    PackedHistory {
        messages: picked,
        tokens_est: summary_tokens + used_tokens,
        dropped_count,
    }
}

pub fn history_with_summary(summary: &str, packed: &[ChatHistoryMsg]) -> Vec<ChatHistoryMsg> {
    let summary = summary.trim();
    if summary.is_empty() {
        return packed.to_vec();
    }
    let mut out = Vec::with_capacity(packed.len() + 1);
    out.push(ChatHistoryMsg {
        role: "user".into(),
        content: format!("[CONVERSATION SUMMARY]\n{summary}"),
    });
    out.extend(packed.iter().cloned());
    out
}
