include!(concat!(env!("OUT_DIR"), "/agent_version.rs"));

pub fn register() {
    c_remote_core::version::register(AGENT_VERSION_NAME, AGENT_BUILD);
}