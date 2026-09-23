include!(concat!(env!("OUT_DIR"), "/agent_version.rs"));

pub fn agent_version_label() -> String {
    format!("Alien AI Remote Agent v{}", AGENT_VERSION_NAME)
}

pub fn agent_version_short() -> String {
    format!("v{}", AGENT_VERSION_NAME)
}
