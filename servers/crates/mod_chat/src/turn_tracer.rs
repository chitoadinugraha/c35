use std::future::Future;
use std::sync::Mutex;
use std::time::Instant;

use c35_mod_billing::billing_cost_usd;
use c35_mod_log::{log_put, LogPut};
use serde::Serialize;
use serde_json::Value;
use sqlx::PgPool;
use tokio::task::JoinHandle;

use crate::compose::ComposeTrace;
use crate::memory::MemoryRetrieveTrace;
use crate::scope_instruction::ScopeInstructionTrace;
use crate::user_asset_rag::UserAssetRetrieveTrace;
use crate::tools::device_screenshot_artifact::{
    tool_result_preview_trim, tool_screenshot_log_text, tool_screenshot_meta_from_result,
};

/// One timed sub-stage of a turn (offsets are relative to the turn start).
#[derive(Debug, Clone, Serialize)]
pub struct StageRow {
    pub key: String,
    pub label: String,
    pub start_ms: i64,
    pub ms: i64,
    pub parallel: bool,
}

/// Collects sub-stage timings for the prepare / settle phases of a turn.
pub struct StageClock {
    t0: Instant,
    rows: Vec<StageRow>,
}

impl StageClock {
    pub fn new(t0: Instant) -> Self {
        Self {
            t0,
            rows: Vec::new(),
        }
    }

    pub fn elapsed_ms(&self) -> i64 {
        self.t0.elapsed().as_millis() as i64
    }

    fn push(&mut self, key: &str, label: &str, started: Instant, ms: i64, parallel: bool) {
        let start_ms = started.saturating_duration_since(self.t0).as_millis() as i64;
        self.rows.push(StageRow {
            key: key.to_string(),
            label: label.to_string(),
            start_ms,
            ms,
            parallel,
        });
    }

    /// Stage that ran alone (nothing else in flight).
    pub fn seq(&mut self, key: &str, label: &str, started: Instant) {
        let ms = started.elapsed().as_millis() as i64;
        self.push(key, label, started, ms, false);
    }

    /// Sequential stage with an explicit duration (e.g. a sub-part of a measured stage).
    pub fn seq_ms(&mut self, key: &str, label: &str, started: Instant, ms: i64) {
        self.push(key, label, started, ms.max(0), false);
    }

    /// Branch measured with [`timed`] that ran concurrently with other branches.
    pub fn par(&mut self, key: &str, label: &str, started: Instant, ms: i64) {
        self.push(key, label, started, ms, true);
    }

    pub fn rows(&self) -> &[StageRow] {
        &self.rows
    }
}

/// Await `f`, returning its output with its start instant and duration in ms.
pub async fn timed<F: Future>(f: F) -> (F::Output, Instant, i64) {
    let started = Instant::now();
    let out = f.await;
    let ms = started.elapsed().as_millis() as i64;
    (out, started, ms)
}

pub struct TurnTracer {
    pool: PgPool,
    nats: Option<async_nats::Client>,
    owner_iid: i64,
    chat_id: i64,
    req_id: String,
    hop: Mutex<u8>,
    pending: Mutex<Vec<JoinHandle<()>>>,
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
            pending: Mutex::new(Vec::new()),
        }
    }

    /// Log rows are written in the background so the turn never waits on trace I/O.
    /// Call [`TurnTracer::flush`] before the turn returns so readers see every row.
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
        let pool = self.pool.clone();
        let nats = self.nats.clone();
        let owner_iid = self.owner_iid;
        let chat_id = self.chat_id;
        let req_id = self.req_id.clone();
        let kind = kind.to_string();
        let topic = topic.to_string();
        let text = text.to_string();
        let model = model.to_string();
        let handle = tokio::spawn(async move {
            let _ = log_put(
                &pool,
                nats.as_ref(),
                LogPut {
                    class: None,
                    owner_iid,
                    kind: &kind,
                    topic: &topic,
                    dv: "",
                    req_id: Some(&req_id),
                    chat_id: Some(chat_id),
                    task_id: None,
                    device_iid: None,
                    text: &text,
                    model: &model,
                    tokens_in,
                    tokens_out,
                    duration_ms,
                    cost_usd,
                    meta,
                },
            )
            .await;
        });
        if let Ok(mut v) = self.pending.lock() {
            v.retain(|h| !h.is_finished());
            v.push(handle);
        }
    }

    /// Wait for all background log writes issued so far (no-op when already done).
    pub async fn flush(&self) {
        let handles: Vec<JoinHandle<()>> = match self.pending.lock() {
            Ok(mut v) => std::mem::take(&mut *v),
            Err(_) => return,
        };
        for h in handles {
            let _ = h.await;
        }
    }

    /// Per-stage timeline of the prepare phase (`prepare_ms` = wall time from turn start).
    pub async fn trace_prepare_stages(&self, clock: &StageClock, prepare_ms: i64) {
        self.put(
            "system",
            "trace_stages",
            &format!("Prepare stages · {prepare_ms}ms"),
            serde_json::json!({
                "topic": "trace_stages",
                "step": 1,
                "branch": "stages",
                "prepare_ms": prepare_ms,
                "duration_ms": prepare_ms,
                "stages": clock.rows(),
            }),
            "",
            0,
            0,
            prepare_ms as i32,
            0.0,
        )
        .await;
    }

    /// Post-reply work (memory extract, billing, persist) shown as the Settle step.
    pub async fn trace_settle(&self, clock: &StageClock, settle_ms: i64) {
        self.put(
            "system",
            "trace_settle",
            &format!("Settle · {settle_ms}ms"),
            serde_json::json!({
                "topic": "trace_settle",
                "step": 9998,
                "duration_ms": settle_ms,
                "stages": clock.rows(),
            }),
            "",
            0,
            0,
            settle_ms as i32,
            0.0,
        )
        .await;
    }

    fn branch_meta(step: u32, branch: &str, parallel_group: &str, concurrent_kind: &str) -> Value {
        serde_json::json!({
            "step": step,
            "branch": branch,
            "parallel": true,
            "parallel_group": parallel_group,
            "concurrent_kind": concurrent_kind,
        })
    }

    fn subagent_meta_from_result(tool_id: &str, result: &Value) -> Option<Value> {
        let norm = tool_id.replace('_', ".");
        if norm != "delegate.run" && norm != "computer_use.delegate" {
            return None;
        }
        let child = result
            .get("child_req_id")
            .and_then(|v| v.as_str())
            .filter(|s| !s.is_empty())?;
        Some(serde_json::json!({
            "child_req_id": child,
            "kind": result.get("kind").and_then(|v| v.as_str()).unwrap_or(""),
            "status": result.get("status").and_then(|v| v.as_str()).unwrap_or(""),
            "topic_id": result.get("topic_id").and_then(|v| v.as_str()).unwrap_or(""),
        }))
    }

    pub async fn trace_prepare(
        &self,
        trace: &ComposeTrace,
        user_text: &str,
        prepare_ms: i64,
        context_tokens_est: i32,
    ) {
        const STEP: u32 = 1;
        const GROUP: &str = "prepare";
        let fed = trace.candidates.iter().filter(|c| c.fed).count();
        if trace.tool_embed_ms > 0 || trace.tool_embed_token_in > 0 {
            let embed_label = if trace.tool_embed_cached {
                format!("Prompt embed · cached · {} tok", trace.tool_embed_token_in)
            } else {
                format!("Prompt embed · {} tok", trace.tool_embed_token_in)
            };
            let mut embed_meta = Self::branch_meta(STEP, "embed", GROUP, "compose_parallel");
            if let Some(obj) = embed_meta.as_object_mut() {
                obj.insert("topic".into(), serde_json::json!("trace_tool_embed"));
                obj.insert("duration_ms".into(), serde_json::json!(trace.tool_embed_ms));
                obj.insert(
                    "embed_cached".into(),
                    serde_json::json!(trace.tool_embed_cached),
                );
                obj.insert("task".into(), serde_json::json!("retrieval_query"));
            }
            self.put(
                "system",
                "trace_tool_embed",
                &embed_label,
                embed_meta,
                &trace.tool_embed_model,
                trace.tool_embed_token_in,
                0,
                trace.tool_embed_ms as i32,
                trace.tool_embed_cost_usd,
            )
            .await;
        }
        let inst_meta = {
            let mut m = Self::branch_meta(STEP, "inst", GROUP, "compose_parallel");
            if let Some(obj) = m.as_object_mut() {
                obj.insert("topic".into(), serde_json::json!("trace_inst_enrich"));
                obj.insert("inst_ids".into(), serde_json::json!(trace.inst_ids));
                obj.insert(
                    "enrich_keys".into(),
                    serde_json::json!(trace.inst_enrich_keys),
                );
                obj.insert(
                    "duration_ms".into(),
                    serde_json::json!(trace.inst_enrich_ms),
                );
            }
            m
        };
        let inst_label = if trace.inst_enrich_keys.is_empty() {
            format!("Inst · {} matched", trace.inst_ids.len())
        } else {
            format!(
                "Inst · {} · enrich {}",
                trace.inst_ids.len(),
                trace.inst_enrich_keys.join(", ")
            )
        };
        self.put(
            "system",
            "trace_inst_enrich",
            &inst_label,
            inst_meta,
            "",
            0,
            0,
            trace.inst_enrich_ms as i32,
            0.0,
        )
        .await;
        let mut tool_meta = Self::branch_meta(STEP, "tools", GROUP, "compose_parallel");
        if let Some(obj) = tool_meta.as_object_mut() {
            obj.insert("topic".into(), serde_json::json!("trace_tool_filter"));
            obj.insert("inst_ids".into(), serde_json::json!(trace.inst_ids));
            obj.insert("rag_skipped".into(), serde_json::json!(trace.rag_skipped));
            obj.insert(
                "rag_skip_reason".into(),
                serde_json::json!(trace.rag_skip_reason),
            );
            obj.insert("candidates".into(), serde_json::json!(trace.candidates));
            obj.insert("dropped_gap".into(), serde_json::json!(trace.dropped_gap));
            obj.insert(
                "duration_ms".into(),
                serde_json::json!(trace.tool_filter_ms),
            );
        }
        self.put(
            "system",
            "trace_tool_filter",
            &format!(
                "Tool filter · {fed} fed · {} ranked",
                trace.candidates.len()
            ),
            tool_meta,
            "",
            0,
            0,
            trace.tool_filter_ms as i32,
            0.0,
        )
        .await;
        let mut prep_meta = Self::branch_meta(STEP, "compose", GROUP, "compose_parallel");
        if let Some(obj) = prep_meta.as_object_mut() {
            obj.insert("topic".into(), serde_json::json!("trace_prepare"));
            obj.insert("duration_ms".into(), serde_json::json!(prepare_ms));
            obj.insert("compose_ms".into(), serde_json::json!(trace.duration_ms));
            obj.insert(
                "context_tokens_est".into(),
                serde_json::json!(context_tokens_est),
            );
            obj.insert("user_prompt".into(), serde_json::json!(user_text));
            obj.insert("inst_ids".into(), serde_json::json!(trace.inst_ids));
        }
        self.put(
            "system",
            "trace_prepare",
            &format!("Prepare Â· {prepare_ms}ms"),
            prep_meta,
            "",
            0,
            0,
            prepare_ms as i32,
            0.0,
        )
        .await;
    }

    pub async fn trace_user_assets(&self, trace: &UserAssetRetrieveTrace) {
        if trace.sites.is_empty() && trace.bots.is_empty() && !trace.injected {
            return;
        }
        let applied_sites = trace.sites.iter().filter(|e| e.injected).count();
        let applied_bots = trace.bots.iter().filter(|e| e.injected).count();
        let mut meta = Self::branch_meta(1, "user_assets", "prepare", "compose_parallel");
        if let Some(obj) = meta.as_object_mut() {
            obj.insert("topic".into(), serde_json::json!("trace_user_assets"));
            obj.insert("injected".into(), serde_json::json!(trace.injected));
            obj.insert("block_chars".into(), serde_json::json!(trace.block_chars));
            obj.insert("duration_ms".into(), serde_json::json!(trace.duration_ms));
            obj.insert("embed_ms".into(), serde_json::json!(trace.embed_ms));
            obj.insert("embed_cached".into(), serde_json::json!(trace.embed_cached));
            obj.insert("embed_skipped".into(), serde_json::json!(trace.embed_skipped));
            obj.insert("sites".into(), serde_json::to_value(&trace.sites).unwrap_or_default());
            obj.insert("bots".into(), serde_json::to_value(&trace.bots).unwrap_or_default());
        }
        let label = if trace.injected {
            format!(
                "User assets · {applied_sites} sites · {applied_bots} bots · {} chars",
                trace.block_chars
            )
        } else {
            format!(
                "User assets · {} scored · not injected",
                trace.sites.len() + trace.bots.len()
            )
        };
        self.put(
            "system",
            "trace_user_assets",
            &label,
            meta,
            &trace.embed_model,
            trace.embed_token_in,
            0,
            trace.duration_ms as i32,
            trace.embed_cost_usd,
        )
        .await;
    }

    pub async fn trace_scope_instruction(&self, trace: &ScopeInstructionTrace) {
        if trace.entries.is_empty() && !trace.injected {
            return;
        }
        let applied_n = trace.entries.iter().filter(|e| e.applied).count();
        let mut meta = Self::branch_meta(1, "scope_instruction", "prepare", "compose_parallel");
        if let Some(obj) = meta.as_object_mut() {
            obj.insert("topic".into(), serde_json::json!("trace_scope_instruction"));
            obj.insert("injected".into(), serde_json::json!(trace.injected));
            obj.insert("block_chars".into(), serde_json::json!(trace.block_chars));
            obj.insert("block_preview".into(), serde_json::json!(trace.block_preview));
            obj.insert(
                "entries".into(),
                serde_json::to_value(&trace.entries).unwrap_or_else(|_| serde_json::json!([])),
            );
        }
        let label = if trace.injected {
            format!(
                "Scope instructions · {applied_n} applied · {} chars",
                trace.block_chars
            )
        } else if applied_n > 0 {
            format!("Scope instructions · {applied_n} matched · not injected")
        } else {
            format!("Scope instructions · {} configured", trace.entries.len())
        };
        self.put(
            "system",
            "trace_scope_instruction",
            &label,
            meta,
            "",
            0,
            0,
            0,
            0.0,
        )
        .await;
    }

    pub async fn trace_memory(&self, trace: &MemoryRetrieveTrace) {
        if trace.memory_count == 0 && trace.duration_ms == 0 {
            return;
        }
        let mut meta = Self::branch_meta(1, "memory", "prepare", "compose_parallel");
        if let Some(obj) = meta.as_object_mut() {
            obj.insert("topic".into(), serde_json::json!("trace_memory"));
            obj.insert("duration_ms".into(), serde_json::json!(trace.duration_ms));
            obj.insert("memory_count".into(), serde_json::json!(trace.memory_count));
            obj.insert("embed_ms".into(), serde_json::json!(trace.embed_ms));
            obj.insert("embed_cached".into(), serde_json::json!(trace.embed_cached));
            obj.insert(
                "embed_skipped".into(),
                serde_json::json!(trace.embed_skipped),
            );
            obj.insert("pinned_count".into(), serde_json::json!(trace.pinned_count));
            obj.insert("active_count".into(), serde_json::json!(trace.active_count));
        }
        self.put(
            "system",
            "trace_memory",
            &format!("Memory · {} rows", trace.memory_count),
            meta,
            &trace.embed_model,
            trace.embed_token_in,
            0,
            trace.duration_ms as i32,
            trace.embed_cost_usd,
        )
        .await;
    }

    pub async fn llm_call(
        &self,
        hop: u8,
        model: &str,
        token_in: i32,
        token_out: i32,
        duration_ms: i64,
        cost_usd: f64,
        reply_preview: &str,
    ) {
        let step = hop as u32 + 1;
        if let Ok(mut h) = self.hop.lock() {
            *h = hop;
        }
        let retail = if cost_usd > 0.0 {
            cost_usd
        } else {
            billing_cost_usd(model, token_in, token_out)
        };
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
        )
        .await;
    }

    pub async fn tool_result(
        &self,
        tool: &str,
        tool_call_id: &str,
        args: &Value,
        result: &Value,
        ok: bool,
        duration_ms: i64,
    ) {
        let hop = self.hop.lock().map(|h| *h).unwrap_or(1);
        let step = hop as u32 + 1;
        let tool_id = tool.replace('_', ".");
        let slim = tool_result_preview_trim(result);
        let preview = serde_json::to_string(&slim).unwrap_or_default();
        let preview = if preview.len() > 4000 {
            format!("{}…", preview.chars().take(4000).collect::<String>())
        } else {
            preview
        };
        let text = if tool_screenshot_meta_from_result(result).is_some() {
            tool_screenshot_log_text(&tool_id, result)
        } else {
            preview.clone()
        };
        let topic = if ok { "tool_result" } else { "tool_error" };
        let mut meta = serde_json::json!({
            "topic": topic,
            "step": step,
            "hop": hop,
            "branch": tool_id,
            "parallel": true,
            "parallel_group": format!("hop_{hop}"),
            "concurrent_kind": "tools_same_hop",
            "tool": tool_id,
            "tool_call_id": tool_call_id,
            "args": args,
            "ok": ok,
            "output_preview": preview,
            "duration_ms": duration_ms,
        });
        if let Some(subagent) = Self::subagent_meta_from_result(&tool_id, result) {
            if let Some(obj) = meta.as_object_mut() {
                obj.insert("subagent".into(), subagent);
                obj.insert("concurrent_kind".into(), serde_json::json!("subagent"));
            }
        }
        if let Some(screenshot) = tool_screenshot_meta_from_result(result) {
            if let Some(obj) = meta.as_object_mut() {
                obj.insert("screenshot".into(), screenshot);
            }
        }
        self.put(
            "tool",
            topic,
            &text,
            meta,
            "",
            0,
            0,
            duration_ms as i32,
            0.0,
        )
        .await;
    }

    pub async fn llm_turn(
        &self,
        model: &str,
        token_in: i32,
        token_out: i32,
        duration_ms: i64,
        prepare_ms: i64,
        cost_usd: f64,
        text: &str,
    ) {
        let retail = if cost_usd > 0.0 {
            cost_usd
        } else {
            billing_cost_usd(model, token_in, token_out)
        };
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
        )
        .await;
    }
}
