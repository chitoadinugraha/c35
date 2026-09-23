use std::path::PathBuf;

use anyhow::Context;
use tracing::warn;

pub fn config_path() -> PathBuf {
    #[cfg(target_os = "windows")]
    {
        if let Ok(appdata) = std::env::var("LOCALAPPDATA") {
            let mut p = PathBuf::from(appdata);
            p.push("AlienAI");
            let _ = std::fs::create_dir_all(&p);
            p.push("config.json");
            return p;
        }
    }
    let mut p = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    p.push(".alienai_config.json");
    p
}

pub fn config_load() -> Option<serde_json::Value> {
    let content = std::fs::read_to_string(config_path()).ok()?;
    serde_json::from_str(&content).ok()
}

pub fn session_key_load() -> Option<String> {
    let json = config_load()?;
    let tok = json.get("session_key").and_then(|v| v.as_str())?.trim();
    if tok.is_empty() {
        return None;
    }
    Some(tok.to_string())
}

pub fn device_iid_load() -> Option<i64> {
    config_load()
        .and_then(|j| j.get("device_iid").and_then(|v| v.as_i64()))
        .filter(|id| *id > 0)
}

pub fn session_key_save(session_key: &str, device_iid: i64) -> anyhow::Result<()> {
    let trimmed = session_key.trim();
    if trimmed.is_empty() {
        anyhow::bail!("session_key is empty");
    }
    let path = config_path();
    if let Some(dir) = path.parent() {
        std::fs::create_dir_all(dir)
            .with_context(|| format!("create config dir {}", dir.display()))?;
    }
    let json = serde_json::json!({
        "session_key": trimmed,
        "device_iid": device_iid,
        "saved_at": unix_now_secs(),
    });
    std::fs::write(&path, json.to_string())
        .with_context(|| format!("write config {}", path.display()))
}

pub fn session_key_clear() -> anyhow::Result<()> {
    let path = config_path();
    match std::fs::remove_file(&path) {
        Ok(()) => Ok(()),
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(()),
        Err(e) => {
            warn!("Failed to clear session key: {e}");
            Err(e).with_context(|| format!("remove config {}", path.display()))
        }
    }
}

pub fn server_url() -> String {
    std::env::var("C35_SERVER_URL")
        .or_else(|_| std::env::var("C35_SERVER"))
        .unwrap_or_else(|_| "https://alienai.id".to_string())
        .trim()
        .trim_end_matches('/')
        .to_string()
}

fn unix_now_secs() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}
