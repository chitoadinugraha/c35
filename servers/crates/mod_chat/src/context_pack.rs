use crate::prompt::ChatHistoryMsg;

pub const CONTEXT_PACK_BUDGET_RATIO: f64 = 0.65;
pub const CONTEXT_RECENT_MSG_MIN: usize = 8;
pub const CONTEXT_RECENT_MSG_MAX: usize = 12;

/// Picker steps: 32k, 64k, 128k, 256k, 512k.
pub const CONTEXT_WINDOW_STEPS: [i32; 5] = [32_768, 65_536, 131_072, 262_144, 524_288];
/// Product default when `ai.chat.context_window` is 0. Not a picker step.
pub const CONTEXT_WINDOW_DEFAULT: i32 = 128_000;
const CONTEXT_WINDOW_ALIEN_CEILING: i32 = 1_000_000;
const CONTEXT_WINDOW_GEMINI_CEILING: i32 = 1_048_576;
const CONTEXT_WINDOW_PICKER_MAX: i32 = 524_288;

pub fn model_context_limit(model: &str) -> i32 {
    let m = model.to_ascii_lowercase();
    if m.contains("gemini") {
        CONTEXT_WINDOW_GEMINI_CEILING
    } else {
        128_000
    }
}

pub fn context_model_is_alien(model: &str) -> bool {
    matches!(
        model.trim().to_ascii_lowercase().as_str(),
        "" | "alien" | "alienai" | "auto" | "cloud"
    )
}

/// Largest window the picker may store for this model.
pub fn context_window_picker_ceiling(model: &str) -> i32 {
    if context_model_is_alien(model) {
        return CONTEXT_WINDOW_ALIEN_CEILING;
    }
    if model.to_ascii_lowercase().contains("gemini") {
        return CONTEXT_WINDOW_PICKER_MAX.min(CONTEXT_WINDOW_GEMINI_CEILING);
    }
    model_context_limit(model)
}

fn context_window_snap_down(n: i32) -> i32 {
    CONTEXT_WINDOW_STEPS
        .iter()
        .rev()
        .find(|&&s| s <= n)
        .copied()
        .unwrap_or(CONTEXT_WINDOW_STEPS[0])
}

/// `stored == 0` → `min(128_000, model ceiling)`. 128_000 stays 128_000 (not snapped to 65_536).
/// A smaller ceiling snaps down to an allowed step.
pub fn context_window_default(model: &str) -> i32 {
    let ceiling = if context_model_is_alien(model) {
        CONTEXT_WINDOW_ALIEN_CEILING
    } else if model.to_ascii_lowercase().contains("gemini") {
        CONTEXT_WINDOW_GEMINI_CEILING
    } else {
        model_context_limit(model)
    };
    let raw = CONTEXT_WINDOW_DEFAULT.min(ceiling);
    if raw >= CONTEXT_WINDOW_DEFAULT {
        CONTEXT_WINDOW_DEFAULT
    } else {
        context_window_snap_down(raw)
    }
}

pub fn context_window_resolve(model: &str, stored: i32) -> i32 {
    if stored <= 0 {
        return context_window_default(model);
    }
    let ceiling = context_window_picker_ceiling(model);
    let capped = if stored > ceiling { ceiling } else { stored };
    if CONTEXT_WINDOW_STEPS.contains(&capped) {
        capped
    } else {
        context_window_snap_down(capped)
    }
}

pub fn context_window_options(model: &str) -> Vec<i32> {
    let ceiling = context_window_picker_ceiling(model);
    CONTEXT_WINDOW_STEPS
        .into_iter()
        .filter(|&s| s <= ceiling)
        .collect()
}

/// `Ok(0)` stores the default. Rejects values above the picker ceiling and values that are not a step.
pub fn context_window_store(model: &str, requested: i32) -> Result<i32, String> {
    if requested <= 0 {
        return Ok(0);
    }
    let ceiling = context_window_picker_ceiling(model);
    if requested > ceiling {
        return Err(format!(
            "context_window {requested} above model ceiling {ceiling}"
        ));
    }
    if !CONTEXT_WINDOW_STEPS.contains(&requested) {
        return Err(format!("context_window {requested} is not an allowed step"));
    }
    Ok(requested)
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

pub fn history_rows_tokens(rows: &[HistoryRow]) -> i32 {
    rows.iter().fold(0i32, |acc, row| {
        acc.saturating_add(token_estimate(&history_prune_for_prompt(
            &row.content,
            &row.blocks_json,
        )))
    })
}

pub fn prompt_tokens_estimate(system_tokens: i32, packed_tokens: i32, user_tokens: i32) -> i32 {
    system_tokens
        .saturating_add(packed_tokens)
        .saturating_add(user_tokens)
}

/// Counts only. Built from the pieces already assembled for the prompt.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct ContextUsageEst {
    pub instructions: i32,
    pub memory: i32,
    pub context: i32,
    pub tools: i32,
    pub conversation: i32,
}

impl ContextUsageEst {
    pub fn total(self) -> i32 {
        self.instructions
            .saturating_add(self.memory)
            .saturating_add(self.context)
            .saturating_add(self.tools)
            .saturating_add(self.conversation)
    }

    pub fn proto(self) -> c35_proto::ContextUsage {
        c35_proto::ContextUsage {
            instructions: self.instructions.max(0),
            memory: self.memory.max(0),
            context: self.context.max(0),
            tools: self.tools.max(0),
            conversation: self.conversation.max(0),
        }
    }
}

pub fn context_pack_history(
    summary: &str,
    rows: &[HistoryRow],
    window: i32,
    system_tokens_est: i32,
    user_tokens_est: i32,
) -> PackedHistory {
    let limit = window.max(1);
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
        picked.push(ChatHistoryMsg {
            role: row.role.clone(),
            content: pruned,
        });
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
