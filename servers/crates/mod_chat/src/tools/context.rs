use std::sync::{Arc, Mutex};

use reqwest::Client;
use sqlx::PgPool;

use crate::mention_context::MentionContext;

/// Context passed to every tool execution.
#[derive(Clone)]
pub struct ToolContext {
    pub pool: PgPool,
    pub nats: Option<async_nats::Client>,
    pub owner_iid: i64,
    pub chat_id: i64,
    pub site_iid: Option<i64>,
    pub mention: MentionContext,
    pub mention_ids: Vec<String>,
    pub user_text: String,
    pub locale: String,
    pub attachments_json: String,
    pub req_id: String,
    pub http_client: Client,
    title_slot: Option<Arc<Mutex<Option<String>>>>,
}

impl ToolContext {
    pub fn new(
        pool: PgPool,
        nats: Option<async_nats::Client>,
        owner_iid: i64,
        chat_id: i64,
        site_iid: Option<i64>,
        mention: MentionContext,
        mention_ids: impl Into<Vec<String>>,
        user_text: impl Into<String>,
        locale: impl Into<String>,
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
            mention,
            mention_ids: mention_ids.into(),
            user_text: user_text.into(),
            locale: locale.into(),
            attachments_json: attachments_json.into(),
            req_id: req_id.into(),
            http_client,
            title_slot: None,
        }
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
}
