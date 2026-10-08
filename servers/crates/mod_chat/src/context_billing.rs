use serde_json::{json, Value};

#[derive(Debug, Clone, Default)]
pub struct ContextBillingExtra {
    pub compaction_cost_usd: f64,
    pub compaction_tokens_in: i32,
    pub compaction_tokens_out: i32,
    pub memory_extract_cost_usd: f64,
    pub memory_extract_writes: i32,
    pub doc_ocr_cost_usd: f64,
    pub doc_ocr_tokens_in: i32,
    pub doc_ocr_tokens_out: i32,
    pub doc_ocr_pages: i32,
}

impl ContextBillingExtra {
    pub fn total_extra_usd(&self) -> f64 {
        self.compaction_cost_usd + self.memory_extract_cost_usd + self.doc_ocr_cost_usd
    }

    pub fn merge(&mut self, other: &ContextBillingExtra) {
        self.compaction_cost_usd += other.compaction_cost_usd;
        self.compaction_tokens_in += other.compaction_tokens_in;
        self.compaction_tokens_out += other.compaction_tokens_out;
        self.memory_extract_cost_usd += other.memory_extract_cost_usd;
        self.memory_extract_writes += other.memory_extract_writes;
        self.doc_ocr_cost_usd += other.doc_ocr_cost_usd;
        self.doc_ocr_tokens_in += other.doc_ocr_tokens_in;
        self.doc_ocr_tokens_out += other.doc_ocr_tokens_out;
        self.doc_ocr_pages += other.doc_ocr_pages;
    }

    pub fn to_log_meta(&self) -> Value {
        let doc_ocr = self.doc_ocr_pages > 0 || self.doc_ocr_cost_usd > 0.0;
        if self.total_extra_usd() <= 0.0 && self.memory_extract_writes == 0 && !doc_ocr {
            return json!({});
        }
        let mut meta = json!({
            "compaction_cost_usd": self.compaction_cost_usd,
            "compaction_tokens_in": self.compaction_tokens_in,
            "compaction_tokens_out": self.compaction_tokens_out,
            "memory_extract_cost_usd": self.memory_extract_cost_usd,
            "memory_extract_writes": self.memory_extract_writes,
        });
        if doc_ocr {
            if let Some(obj) = meta.as_object_mut() {
                obj.insert("doc_ocr_cost_usd".into(), json!(self.doc_ocr_cost_usd));
                obj.insert("doc_ocr_tokens_in".into(), json!(self.doc_ocr_tokens_in));
                obj.insert("doc_ocr_tokens_out".into(), json!(self.doc_ocr_tokens_out));
                obj.insert("doc_ocr_pages".into(), json!(self.doc_ocr_pages));
            }
        }
        meta
    }
}
