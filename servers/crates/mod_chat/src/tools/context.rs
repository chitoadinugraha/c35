use std::sync::{Arc, Mutex};

use reqwest::Client;
use sqlx::PgPool;

use c35_mod_billing::BillingContext;

use crate::context_billing::ContextBillingExtra;
use crate::mention_context::MentionContext;

/// Context passed to every tool execution.
#[derive(Clone)]
pub struct ToolContext {
    pub pool: PgPool,
    pub nats: Option<async_nats::Client>,
    pub owner_iid: i64,
    pub chat_id: i64,
    pub site_iid: Option<i64>,
    pub guest_visitor_id: Option<String>,
    pub mention: MentionContext,
    pub mention_ids: Vec<String>,
    pub user_text: String,
    pub locale: String,
    pub location_city: String,
    pub location_region: String,
    pub location_country: String,
    pub attachments_json: String,
    pub req_id: String,
    /// Same id as `TurnTracer::tool_result` when set by `cluster_tool_exec`.
    pub tool_call_id: String,
    pub http_client: Client,
    /// Set for `/v1/mcp/agent` tool_exec (skips freemium block on operator device tools).
    pub mcp_agent: bool,
    title_slot: Option<Arc<Mutex<Option<String>>>>,
    /// OCR charges for this turn. One Arc shared with `TurnCtx`; MCP uses a fresh one.
    pub doc_ocr: Arc<Mutex<ContextBillingExtra>>,
    /// Payer for `doc.extract` OCR. Empty on MCP `tool_exec`.
    pub billing: Option<BillingContext>,
    /// Memoized freemium check for tool calls in this context/session.
    pub is_freemium_slot: Arc<Mutex<Option<bool>>>,
    pub run_kind: String,
}

impl ToolContext {
    pub fn new(
        pool: PgPool,
        nats: Option<async_nats::Client>,
        owner_iid: i64,
        chat_id: i64,
        site_iid: Option<i64>,
        guest_visitor_id: Option<String>,
        mention: MentionContext,
        mention_ids: impl Into<Vec<String>>,
        user_text: impl Into<String>,
        locale: impl Into<String>,
        location_city: impl Into<String>,
        location_region: impl Into<String>,
        location_country: impl Into<String>,
        attachments_json: impl Into<String>,
        req_id: impl Into<String>,
        http_client: Client,
    ) -> Self {
        Self {
            pool,
            nats,
            owner_iid,
            chat_id,
            site_iid,
            guest_visitor_id,
            mention,
            mention_ids: mention_ids.into(),
            user_text: user_text.into(),
            locale: locale.into(),
            location_city: location_city.into(),
            location_region: location_region.into(),
            location_country: location_country.into(),
            attachments_json: attachments_json.into(),
            req_id: req_id.into(),
            tool_call_id: String::new(),
            http_client,
            mcp_agent: false,
            title_slot: None,
            doc_ocr: Arc::new(Mutex::new(ContextBillingExtra::default())),
            billing: None,
            is_freemium_slot: Arc::new(Mutex::new(None)),
            run_kind: "main".to_string(),
        }
    }

    pub fn with_run_kind(mut self, run_kind: impl Into<String>) -> Self {
        self.run_kind = run_kind.into();
        self
    }

    pub fn with_doc_ocr(mut self, doc_ocr: Arc<Mutex<ContextBillingExtra>>) -> Self {
        self.doc_ocr = doc_ocr;
        self
    }

    pub fn with_billing(mut self, billing: Option<BillingContext>) -> Self {
        self.billing = billing;
        self
    }

    pub fn with_mcp_agent(mut self, mcp_agent: bool) -> Self {
        self.mcp_agent = mcp_agent;
        self
    }

    pub fn with_tool_call_id(mut self, tool_call_id: impl Into<String>) -> Self {
        self.tool_call_id = tool_call_id.into();
        self
    }

    pub fn with_title_slot(mut self, slot: Arc<Mutex<Option<String>>>) -> Self {
        self.title_slot = Some(slot);
        self
    }

    pub fn set_title(&self, title: impl Into<String>) {
        let t = title.into().trim().to_string();
        if t.is_empty() || self.chat_id == 0 {
            return;
        }
        if let Some(slot) = &self.title_slot {
            if let Ok(mut g) = slot.lock() {
                *g = Some(t);
            }
        }
    }

    /// Returns whether the user is restricted to freemium limits, cached for this context/turn.
    pub async fn is_freemium(&self) -> bool {
        if self.owner_iid <= 0 {
            return false;
        }
        if let Ok(guard) = self.is_freemium_slot.lock() {
            if let Some(val) = *guard {
                return val;
            }
        }
        let applies = c35_mod_billing::billing_freemium_applies_nats(
            &self.pool,
            self.nats.as_ref(),
            self.owner_iid,
        )
        .await
        .unwrap_or(false);
        if let Ok(mut guard) = self.is_freemium_slot.lock() {
            *guard = Some(applies);
        }
        applies
    }
}
