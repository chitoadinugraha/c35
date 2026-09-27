use serde_json::Value;
use sqlx::PgPool;

pub struct BotTurnMeta {
    pub strict_mode: bool,
    pub auto_block_spammer: bool,
    pub web_search: bool,
}

pub fn bot_turn_meta_parse(meta: Option<&Value>) -> BotTurnMeta {
    let Some(m) = meta else {
        return BotTurnMeta {
            strict_mode: true,
            auto_block_spammer: true,
            web_search: false,
        };
    };
    let strict_mode = m.get("strict_mode").and_then(|v| v.as_bool()).unwrap_or(true);
    let auto_block_spammer = m.get("auto_block_spammer").and_then(|v| v.as_bool()).unwrap_or(true);
    let web_search = m.get("web_search").and_then(|v| v.as_bool()).unwrap_or(false);
    BotTurnMeta {
        strict_mode,
        auto_block_spammer,
        web_search,
    }
}

pub fn bot_auto_block_enabled(meta: &BotTurnMeta) -> bool {
    meta.strict_mode && meta.auto_block_spammer
}

pub async fn bot_turn_meta_load(pool: &PgPool, bot_iid: i64) -> BotTurnMeta {
    let meta: Option<Value> = sqlx::query_scalar(
        "SELECT meta FROM ai.identity WHERE id = $1 AND kind = 'bot' AND deleted_ts IS NULL",
    )
    .bind(bot_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();
    bot_turn_meta_parse(meta.as_ref())
}

pub fn bot_turn_signals(meta: &BotTurnMeta) -> Vec<String> {
    let mut out = Vec::new();
    if meta.strict_mode {
        out.push("bot:strict".into());
    }
    if meta.web_search {
        out.push("bot:web_search".into());
    }
    out
}

pub const BOT_TOPIC: &str = "bot";

pub const BOT_WEB_TOOL_EXCLUDE: &[&str] = &["web.search", "web.visit", "web.research"];
