include!(concat!(env!("OUT_DIR"), "/agent_version.rs"));

/// User-facing build number (middle semver segment), kept in sync with `AGENT_BUILD`.
pub fn agent_version_number() -> i64 {
    let parts: Vec<&str> = AGENT_VERSION_NAME.split('.').collect();
    if parts.len() >= 2 {
        if let Ok(n) = parts[1].parse::<i64>() {
            return n;
        }
    }
    AGENT_BUILD
}

pub fn agent_version_label() -> String {
    format!("version: {}", agent_version_number())
}

pub fn agent_version_short() -> String {
    format!("v{}", agent_version_number())
}
