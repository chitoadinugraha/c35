use webrtc::api::setting_engine::SettingEngine;

/// Skip Hyper-V / VirtualBox host-only adapters (UDP STUN/TURN -> Win error 10051, network unreachable).
pub fn setting_engine() -> SettingEngine {
    let mut se = SettingEngine::default();
    #[cfg(windows)]
    se.set_interface_filter(Box::new(|iface: &str| {
        let n = iface.to_ascii_lowercase();
        !(n.contains("hyper-v") || n.contains("vethernet") || n.contains("virtualbox"))
    }));
    se
}