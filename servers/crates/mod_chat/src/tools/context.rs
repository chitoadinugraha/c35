use reqwest::Client;
use sqlx::PgPool;

/// Context passed to every tool execution.
#[derive(Clone)]
pub struct ToolContext {
    pub pool: PgPool,
    pub owner_iid: i64,
    pub chat_id: i64,
    pub locale: String,
    pub attachments_json: String,
    pub http_client: Client,
}

impl ToolContext {
    pub fn new(
        pool: PgPool,
        owner_iid: i64,
        chat_id: i64,
        locale: impl Into<String>,
        attachments_json: impl Into<String>,
        http_client: Client,
    ) -> Self {
        Self {
            pool,
            owner_iid,
            chat_id,
            locale: locale.into(),
            attachments_json: attachments_json.into(),
            http_client,
        }
    }
}
