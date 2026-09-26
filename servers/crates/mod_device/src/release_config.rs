use serde_json::Value;
use sqlx::PgPool;

const CONFIG_PREFIX: &str = "app.release.c35.";

pub async fn release_config_get(pool: &PgPool, platform_key: &str) -> Result<Option<Value>, String> {
    let key = format!("{CONFIG_PREFIX}{platform_key}");
    let row = sqlx::query_scalar::<_, Value>(r#"SELECT value FROM ai.config WHERE key = $1"#)
        .bind(&key)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
    Ok(row)
}

pub fn release_needs_update(current_build: i64, rel: &Value) -> bool {
    if current_build <= 0 {
        return false;
    }
    let latest = rel.get("version").and_then(|v| v.as_i64()).unwrap_or(0);
    let min = rel.get("min").and_then(|v| v.as_i64()).unwrap_or(0);
    current_build < min || current_build < latest
}

pub fn release_summary(rel: &Value) -> (i64, String, i64) {
    let version = rel.get("version").and_then(|v| v.as_i64()).unwrap_or(0);
    let min = rel.get("min").and_then(|v| v.as_i64()).unwrap_or(0);
    let name = rel
        .get("versionName")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();
    (version, name, min)
}

pub fn client_platform_release_key(platform: i32) -> Option<&'static str> {
    match platform {
        1 => Some("android"),
        3 => Some("windows"),
        4 => Some("web"),
        _ => None,
    }
}