use serde_json::Value;
use sqlx::PgPool;

const CONFIG_PREFIX: &str = "app.release.c35.";

/// `playwright` when absent — see _/specs/browser-extension.md.
pub fn meta_browser_engine(meta: &Value) -> &str {
    meta.get("browser_engine")
        .and_then(|v| v.as_str())
        .filter(|s| !s.is_empty())
        .unwrap_or("playwright")
}

/// `true` when the unified desktop agent reports extension IPC + NM healthy (U2).
pub fn meta_browser_ready(meta: &Value) -> bool {
    meta.get("browser_ready")
        .and_then(|v| v.as_bool())
        .unwrap_or(false)
}

pub fn device_type_is_unified_desktop(typ: &str) -> bool {
    typ.eq_ignore_ascii_case("windows") || typ.eq_ignore_ascii_case("linux")
}

pub fn device_release_platform_key(device_type: &str, meta: &Value) -> &'static str {
    if device_type.eq_ignore_ascii_case("browser") {
        if meta_browser_engine(meta).eq_ignore_ascii_case("extension") {
            "chrome-extension"
        } else {
            "remote-browser"
        }
    } else if device_type.eq_ignore_ascii_case("android") {
        "remote-android"
    } else {
        "remote-windows"
    }
}

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

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn meta_browser_ready_parses_bool() {
        assert!(!meta_browser_ready(&json!({})));
        assert!(meta_browser_ready(&json!({"browser_ready": true})));
    }
}

pub fn client_platform_release_key(platform: i32) -> Option<&'static str> {
    match platform {
        1 => Some("android"),
        3 => Some("windows"),
        4 => Some("web"),
        _ => None,
    }
}