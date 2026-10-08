use std::collections::HashMap;

use anyhow::Result;
use serde::Deserialize;
use serde_json::Value;
use sqlx::{PgPool, Row};

use crate::bot_peer::BOT_APP_CHANNEL_ID;

#[derive(Debug, Clone, Deserialize)]
struct ChannelMetaRow {
    id: String,
    platform: String,
}

pub fn platform_display_label(platform: &str) -> &'static str {
    match platform.trim().to_lowercase().as_str() {
        "whatsapp" => "WhatsApp",
        "telegram" => "Telegram",
        "app" => "App",
        _ => "Channel",
    }
}

pub fn channel_id_platform(channel_id: &str, platform_map: &HashMap<String, String>) -> String {
    if channel_id == BOT_APP_CHANNEL_ID {
        return "app".into();
    }
    platform_map
        .get(channel_id)
        .cloned()
        .unwrap_or_else(|| "unknown".into())
}

pub async fn bot_channel_platform_map(
    pool: &PgPool,
    bot_iid: i64,
) -> Result<HashMap<String, String>> {
    let row = sqlx::query(
        "SELECT meta FROM ai.identity WHERE id = $1 AND kind = 'bot' AND deleted_ts IS NULL",
    )
    .bind(bot_iid)
    .fetch_optional(pool)
    .await?;
    let mut out = HashMap::new();
    let Some(row) = row else {
        return Ok(out);
    };
    let meta: Value = row.get("meta");
    let channels = meta
        .get("channels")
        .and_then(|v| v.as_array())
        .cloned()
        .unwrap_or_default();
    for item in channels {
        if let Ok(ch) = serde_json::from_value::<ChannelMetaRow>(item) {
            if !ch.id.is_empty() {
                out.insert(ch.id, ch.platform);
            }
        }
    }
    Ok(out)
}
