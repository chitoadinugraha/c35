use serde_json::{json, Value};

#[derive(Debug, Clone, Default)]
pub struct ContextBillingExtra {
    pub compaction_cost_usd: f64,
    pub compaction_tokens_in: i32,
    pub compaction_tokens_out: i32,
    pub memory_extract_cost_usd: f64,
    pub memory_extract_writes: i32,
}

impl ContextBillingExtra {
    pub fn total_extra_usd(&self) -> f64 {
        self.compaction_cost_usd + self.memory_extract_cost_usd
    }

    pub fn merge(&mut self, other: &ContextBillingExtra) {
        self.compaction_cost_usd += other.compaction_cost_usd;
        self.compaction_tokens_in += other.compaction_tokens_in;
        self.compaction_tokens_out += other.compaction_tokens_out;
        self.memory_extract_cost_usd += other.memory_extract_cost_usd;
        self.memory_extract_writes += other.memory_extract_writes;
    }

    pub fn to_log_meta(&self) -> Value {
        if self.total_extra_usd() <= 0.0 && self.memory_extract_writes == 0 {
            return json!({});
        }
        json!({
            "compaction_cost_usd": self.compaction_cost_usd,
            "compaction_tokens_in": self.compaction_tokens_in,
            "compaction_tokens_out": self.compaction_tokens_out,
            "memory_extract_cost_usd": self.memory_extract_cost_usd,
            "memory_extract_writes": self.memory_extract_writes,
        })
    }
}
