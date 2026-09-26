use serde_json::Value;

pub struct BotTurnMeta {
    pub strict_mode: bool,
    pub web_search: bool,
}

pub fn bot_turn_meta_parse(meta: Option<&Value>) -> BotTurnMeta {
    let Some(m) = meta else {
        return BotTurnMeta { strict_mode: true, web_search: false };
    };
    let strict_mode = m.get("strict_mode").and_then(|v| v.as_bool()).unwrap_or(true);
    let web_search = m.get("web_search").and_then(|v| v.as_bool()).unwrap_or(false);
    BotTurnMeta { strict_mode, web_search }
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
