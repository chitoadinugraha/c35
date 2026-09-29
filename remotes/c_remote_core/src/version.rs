use std::sync::OnceLock;

struct AgentMeta {
    name: &'static str,
    build: i64,
}

static META: OnceLock<AgentMeta> = OnceLock::new();

/// Called once from each agent binary (`c_remote_windows` / `c_remote_browser`) at startup.
pub fn register(name: &'static str, build: i64) {
    META.get_or_init(|| AgentMeta { name, build });
}

fn meta() -> &'static AgentMeta {
    META.get().expect(
        "agent version not registered — call c_remote_windows::agent_version::register() or c_remote_browser::agent_version::register() from main",
    )
}

pub fn agent_version_name() -> &'static str {
    meta().name
}

pub fn agent_build() -> i64 {
    meta().build
}

/// User-facing build number (middle semver segment), kept in sync with `agent_build()`.
pub fn agent_version_number() -> i64 {
    let parts: Vec<&str> = agent_version_name().split('.').collect();
    if parts.len() >= 2 {
        if let Ok(n) = parts[1].parse::<i64>() {
            return n;
        }
    }
    agent_build()
}

pub fn agent_version_label() -> String {
    format!("version: {}", agent_version_number())
}

pub fn agent_version_short() -> String {
    format!("v{}", agent_version_number())
}

/// Tray tooltip / menu version snippet, e.g. `Version 20`.
pub fn agent_version_tray_label() -> String {
    format!("Version {}", agent_build())
}
