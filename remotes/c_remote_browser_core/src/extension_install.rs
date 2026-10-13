//! Chrome MV3 extension files under %LOCALAPPDATA%/AlienAI/chrome_extension/install/alienai_remote.
//! The native host reads manifest.version so the service worker can auto-reload when dist is synced.

use std::path::PathBuf;

use serde_json::Value;

pub fn install_extension_dir() -> Option<PathBuf> {
    let local = std::env::var_os("LOCALAPPDATA")?;
    let p = PathBuf::from(local)
        .join("AlienAI")
        .join("chrome_extension")
        .join("install")
        .join("alienai_remote");
    if p.is_dir() {
        Some(p)
    } else {
        None
    }
}

pub fn install_extension_manifest_version() -> Option<String> {
    let dir = install_extension_dir()?;
    let path = dir.join("manifest.json");
    let raw = std::fs::read_to_string(&path).ok()?;
    let v: Value = serde_json::from_str(&raw).ok()?;
    v.get("version")
        .and_then(|x| x.as_str())
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
}
