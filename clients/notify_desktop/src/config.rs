//! Config for `alienai_notify`.
//!
//! JWT (required for `/v1/ws`):
//! - `C35_NOTIFY_JWT` — session token directly
//! - `C35_NOTIFY_JWT_FILE` — path to a file containing the JWT (default:
//!   `%LOCALAPPDATA%/AlienAI/notify/jwt.txt` on Windows)
//! - IPC line `set_jwt <token>` from Flutter after login (overrides until restart)
//!
//! API base (HTTP URL, converted to WS):
//! - `C35_NOTIFY_API_BASE` — default `https://api.alienai.id` (same as Flutter `C35Config`)

use std::path::PathBuf;

pub fn api_base() -> String {
    std::env::var("C35_NOTIFY_API_BASE")
        .ok()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| "https://api.alienai.id".to_string())
}

pub fn jwt_from_env_or_file() -> Option<String> {
    if let Ok(v) = std::env::var("C35_NOTIFY_JWT") {
        let t = v.trim();
        if !t.is_empty() {
            return Some(t.to_string());
        }
    }
    let path = jwt_file_path();
    if let Ok(content) = std::fs::read_to_string(&path) {
        let t = content.trim();
        if !t.is_empty() {
            return Some(t.to_string());
        }
    }
    None
}

pub fn jwt_file_path() -> PathBuf {
    if let Ok(p) = std::env::var("C35_NOTIFY_JWT_FILE") {
        let t = p.trim();
        if !t.is_empty() {
            return PathBuf::from(t);
        }
    }
    storage_dir().join("jwt.txt")
}

pub fn storage_dir() -> PathBuf {
    #[cfg(target_os = "windows")]
    {
        if let Ok(appdata) = std::env::var("LOCALAPPDATA") {
            let mut p = PathBuf::from(appdata);
            p.push("AlienAI");
            p.push("notify");
            let _ = std::fs::create_dir_all(&p);
            return p;
        }
    }
    let mut p = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    p.push(".alienai");
    p.push("notify");
    let _ = std::fs::create_dir_all(&p);
    p
}

pub fn ws_url(api_base: &str, jwt: &str) -> String {
    let base = api_base.trim_end_matches('/');
    let ws_base = if base.starts_with("https://") {
        format!("wss://{}", base.trim_start_matches("https://"))
    } else if base.starts_with("http://") {
        format!("ws://{}", base.trim_start_matches("http://"))
    } else {
        format!("wss://{}", base.trim_start_matches('/'))
    };
    format!(
        "{}/v1/ws?jwt={}&platform=3",
        ws_base,
        urlencoding::encode(jwt.trim())
    )
}

pub fn client_id() -> String {
    let host = hostname::get()
        .ok()
        .and_then(|h| h.into_string().ok())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| "unknown".to_string());
    let safe = host
        .chars()
        .map(|c| if c.is_ascii_alphanumeric() || c == '-' || c == '_' { c } else { '-' })
        .collect::<String>();
    format!("win-notify-{}", safe)
}
