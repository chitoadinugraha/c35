//! Per-chat tool/instruction continuity (10 user messages after a tool-heavy turn).

pub const TURN_CONTINUITY_INITIAL: u8 = 10;

#[derive(Debug, Clone, Default)]
pub struct TurnContinuity {
    pub turns_remaining: u8,
    pub force_tools: Vec<String>,
    pub inst_suffix: String,
}

impl TurnContinuity {
    pub fn fresh() -> Self {
        Self {
            turns_remaining: TURN_CONTINUITY_INITIAL,
            force_tools: Vec::new(),
            inst_suffix: String::new(),
        }
    }

    pub fn active(&self) -> bool {
        self.turns_remaining > 0
            && (!self.force_tools.is_empty() || !self.inst_suffix.is_empty())
    }

    /// Called when the user sends a message in this chat.
    pub fn on_user_message(&mut self) {
        if self.turns_remaining > 0 {
            self.turns_remaining -= 1;
        }
        if self.turns_remaining == 0 {
            self.force_tools.clear();
            self.inst_suffix.clear();
        }
    }

    pub fn apply_hints(&mut self, force_tools: Vec<String>, inst_suffix: String) {
        if force_tools.is_empty() && inst_suffix.is_empty() {
            return;
        }
        self.turns_remaining = TURN_CONTINUITY_INITIAL;
        self.force_tools = force_tools;
        self.inst_suffix = inst_suffix;
    }
}
