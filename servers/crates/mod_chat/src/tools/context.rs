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
    pub locale: String,
    pub attachments_json: String,
    pub req_id: String,
    pub http_client: Client,
}

impl ToolContext {
    pub fn new(
        pool: PgPool,
        nats: Option<async_nats::Client>,
        owner_iid: i64,
        chat_id: i64,
        site_iid: Option<i64>,
        mention: MentionContext,
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
            locale: locale.into(),
            attachments_json: attachments_json.into(),
            req_id: req_id.into(),
            http_client,
        }
    }
}
