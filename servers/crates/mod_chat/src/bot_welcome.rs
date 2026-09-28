use serde_json::Value;
use sqlx::PgPool;

pub const BOT_BILLING_SHARED: &str = "shared";

pub fn bot_welcome_shared_text(bot_name: &str) -> String {
    let name = bot_name.trim();
    if name.is_empty() {
        "Hi! I am Alien AI. How can I help you today?".into()
    } else {
        format!("Hi! I am Alien AI, here to help with {name}. How can I help you today?")
    }
}

pub fn bot_billing_plan_slug(meta: Option<&Value>) -> &str {
    meta.and_then(|m| m.get("billing_plan_slug"))
        .and_then(|v| v.as_str())
        .unwrap_or(BOT_BILLING_SHARED)
}

pub fn bot_welcome_message_resolve(meta: Option<&Value>, bot_name: &str) -> Option<String> {
    let slug = bot_billing_plan_slug(meta);
    if slug == BOT_BILLING_SHARED || slug.is_empty() {
        return Some(bot_welcome_shared_text(bot_name));
    }
    meta.and_then(|m| m.get("welcome_message"))
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(|s| s.to_string())
}

pub async fn bot_name_load(pool: &PgPool, bot_iid: i64) -> String {
    sqlx::query_scalar::<_, Option<String>>(
        "SELECT name FROM ai.identity WHERE id = $1 AND kind = 'bot' AND deleted_ts IS NULL",
    )
    .bind(bot_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten()
    .flatten()
    .unwrap_or_default()
}

pub async fn bot_meta_load(pool: &PgPool, bot_iid: i64) -> Option<Value> {
    sqlx::query_scalar("SELECT meta FROM ai.identity WHERE id = $1 AND kind = 'bot' AND deleted_ts IS NULL")
        .bind(bot_iid)
        .fetch_optional(pool)
        .await
        .ok()
        .flatten()
}

pub async fn bot_welcome_text(pool: &PgPool, bot_iid: i64) -> Option<String> {
    let name = bot_name_load(pool, bot_iid).await;
    let meta = bot_meta_load(pool, bot_iid).await;
    bot_welcome_message_resolve(meta.as_ref(), &name)
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn shared_uses_alien_ai_template() {
        let t = bot_welcome_message_resolve(Some(&json!({"billing_plan_slug": "shared"})), "Test Cafe").unwrap();
        assert!(t.contains("Alien AI"));
        assert!(t.contains("Test Cafe"));
    }

    #[test]
    fn paid_uses_custom_only() {
        let t = bot_welcome_message_resolve(
            Some(&json!({"billing_plan_slug": "bot.lite", "welcome_message": "Welcome to our shop!"})),
            "Shop",
        )
        .unwrap();
        assert_eq!(t, "Welcome to our shop!");
    }

    #[test]
    fn paid_empty_skips() {
        assert!(bot_welcome_message_resolve(Some(&json!({"billing_plan_slug": "bot.lite"})), "Shop").is_none());
    }
}