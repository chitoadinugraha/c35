use std::sync::Mutex;

use c35_mod_billing::billing_cost_usd;
use c35_mod_log::{log_put, LogPut};
use serde_json::Value;
use sqlx::PgPool;

use crate::compose::ComposeTrace;
use crate::memory::MemoryRetrieveTrace;

pub struct TurnTracer {
    pool: PgPool,
    nats: Option<async_nats::Client>,
    owner_iid: i64,
    chat_id: i64,
    req_id: String,
    hop: Mutex<u8>,
}

impl TurnTracer {
    pub fn new(
        pool: PgPool,
        nats: Option<async_nats::Client>,
        owner_iid: i64,
        chat_id: i64,
        req_id: &str,
    ) -> Self {
        Self {
            pool,
            nats,
            owner_iid,
            chat_id,
            req_id: req_id.to_string(),
            hop: Mutex::new(0),
        }
    }

    async fn put(
        &self,
        kind: &str,
        topic: &str,
        text: &str,
        meta: Value,
        model: &str,
        tokens_in: i32,
        tokens_out: i32,
        duration_ms: i32,
        cost_usd: f64,
    ) {
        let _ = log_put(
            &self.pool,
            self.nats.as_ref(),
            LogPut {
                owner_iid: self.owner_iid,
                kind,
                topic,
                dv: "",
                req_id: Some(&self.req_id),
                chat_id: Some(self.chat_id),
                task_id: None,
                device_iid: None,
                text,
                model,
                tokens_in,
                tokens_out,
                duration_ms,
                cost_usd,
                meta,
            },
        )
        .await;
    }

    fn branch_meta(step: u32, branch: &str, parallel_group: &str) -> Value {
        serde_json::json!({
            "step": step,
            "branch": branch,
            "parallel": true,
            "parallel_group": parallel_group,
        })
    }

    pub async fn trace_prepare(&self, trace: &ComposeTrace, user_text: &str, prepare_ms: i64, context_tokens_est: i32) {
        const STEP: u32 = 1;
        const GROUP: &str = "prepare";
        let fed = trace.candidates.iter().filter(|c| c.fed).count();
        let mut tool_meta = Self::branch_meta(STEP, "tools", GROUP);
        if let Some(obj) = tool_meta.as_object_mut() {
            obj.insert("topic".into(), serde_json::json!("trace_tool_filter"));
            obj.insert("inst_ids".into(), serde_json::json!(trace.inst_ids));
            obj.insert("rag_skipped".into(), serde_json::json!(trace.rag_skipped));
            obj.insert("rag_skip_reason".into(), serde_json::json!(trace.rag_skip_reason));
            obj.insert("candidates".into(), serde_json::json!(trace.candidates));
            obj.insert("dropped_gap".into(), serde_json::json!(trace.dropped_gap));
            obj.insert("duration_ms".into(), serde_json::json!(trace.duration_ms));
        }
        self.put(
            "system",
            "trace_tool_filter",
            &format!("Tool filter · {fed} fed · {} ranked", trace.candidates.len()),
            tool_meta,
            "",
            0,
            0,
            trace.duration_ms as i32,
            0.0,
        ).await;
        let mut prep_meta = Self::branch_meta(STEP, "compose", GROUP);
        if let Some(obj) = prep_meta.as_object_mut() {
            obj.insert("topic".into(), serde_json::json!("trace_prepare"));
            obj.insert("duration_ms".into(), serde_json::json!(prepare_ms));
            obj.insert("compose_ms".into(), serde_json::json!(trace.duration_ms));
            obj.insert("context_tokens_est".into(), serde_json::json!(context_tokens_est));
            obj.insert("user_prompt".into(), serde_json::json!(user_text));
            obj.insert("inst_ids".into(), serde_json::json!(trace.inst_ids));
        }
        self.put(
            "system",
            "trace_prepare",
            &format!("Prepare · {prepare_ms}ms"),
            prep_meta,
            "",
            0,
            0,
            prepare_ms as i32,
            0.0,
        ).await;
    }

    pub async fn trace_memory(&self, trace: &MemoryRetrieveTrace) {
        if trace.memory_count == 0 && trace.duration_ms == 0 {
            return;
        }
        let mut meta = Self::branch_meta(1, "memory", "prepare");
        if let Some(obj) = meta.as_object_mut() {
            obj.insert("topic".into(), serde_json::json!("trace_memory"));
            obj.insert("duration_ms".into(), serde_json::json!(trace.duration_ms));
            obj.insert("memory_count".into(), serde_json::json!(trace.memory_count));
            obj.insert("embed_ms".into(), serde_json::json!(trace.embed_ms));
            obj.insert("embed_cached".into(), serde_json::json!(trace.embed_cached));
            obj.insert("embed_skipped".into(), serde_json::json!(trace.embed_skipped));
        }
        self.put(
            "system",
            "trace_memory",
            &format!("Memory · {} rows", trace.memory_count),
            meta,
            "",
            0,
            0,
            trace.duration_ms as i32,
            0.0,
        ).await;
    }

    pub async fn llm_call(&self, hop: u8, model: &str, token_in: i32, token_out: i32, duration_ms: i64, cost_usd: f64, reply_preview: &str) {
        let step = hop as u32 + 1;
        if let Ok(mut h) = self.hop.lock() {
            *h = hop;
        }
        let retail = if cost_usd > 0.0 { cost_usd } else { billing_cost_usd(model, token_in, token_out) };
        self.put(
            "llm",
            "llm_call",
            reply_preview,
            serde_json::json!({
                "topic": "llm_call",
                "step": step,
                "hop": hop,
                "prompt_tokens": token_in,
                "completion_tokens": token_out,
                "duration_ms": duration_ms,
                "cost_retail_usd": retail,
            }),
            model,
            token_in,
            token_out,
            duration_ms as i32,
            retail,
        ).await;
    }

    pub async fn tool_result(&self, tool: &str, tool_call_id: &str, args: &Value, result: &Value, ok: bool, duration_ms: i64) {
        let hop = self.hop.lock().map(|h| *h).unwrap_or(1);
        let step = hop as u32 + 1;
        let tool_id = tool.replace('_', ".");
        let preview = serde_json::to_string(result).unwrap_or_default();
        let preview = if preview.len() > 4000 {
            format!("{}…", preview.chars().take(4000).collect::<String>())
        } else {
            preview
        };
        let topic = if ok { "tool_result" } else { "tool_error" };
        self.put(
            "tool",
            topic,
            &preview,
            serde_json::json!({
                "topic": topic,
                "step": step,
                "hop": hop,
                "branch": tool_id,
                "parallel": true,
                "parallel_group": format!("hop_{hop}"),
                "tool": tool_id,
                "tool_call_id": tool_call_id,
                "args": args,
                "ok": ok,
                "output_preview": preview,
                "duration_ms": duration_ms,
            }),
            "",
            0,
            0,
            duration_ms as i32,
            0.0,
        ).await;
    }

    pub async fn llm_turn(&self, model: &str, token_in: i32, token_out: i32, duration_ms: i64, prepare_ms: i64, cost_usd: f64, text: &str) {
        let retail = if cost_usd > 0.0 { cost_usd } else { billing_cost_usd(model, token_in, token_out) };
        self.put(
            "llm",
            "llm_turn",
            text,
            serde_json::json!({
                "topic": "llm_turn",
                "step": 9999,
                "prepare_ms": prepare_ms,
                "duration_ms": duration_ms,
                "prompt_tokens": token_in,
                "completion_tokens": token_out,
                "cost_retail_usd": retail,
            }),
            model,
            token_in,
            token_out,
            duration_ms as i32,
            retail,
        ).await;
    }
}
