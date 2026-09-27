use std::sync::{Mutex, OnceLock};

pub fn show_or_focus(_hwnd_slot: &OnceLock<Mutex<isize>>) {
    let snap = c_remote_core::agent_ui::snapshot();
    let device = if snap.device_name.is_empty() {
        crate::pair_loop::device_name()
    } else {
        snap.device_name.clone()
    };
    let owner = snap.owner_label.clone();
    let ver = c_remote_core::version::agent_version_tray_label();
    let summary = format!(
        "Device: {}\nAccount: {}\nVersion: {}\nCloud: {}\nWebRTC viewers: {}\nStreaming: {}\nControl: {}\nBoot: {}",
        device,
        if owner.is_empty() { "(load when online)" } else { &owner },
        ver,
        if snap.ws_connected { "on" } else { "off" },
        snap.webrtc_sessions,
        if snap.capture_active { "yes" } else { "no" },
        if snap.control_allowed { "allowed" } else { "blocked" },
        if snap.autostart_enabled { "on" } else { "off" },
    );
    let log_path = c_remote_core::log_local::log_open_path();
    let path = log_path.display().to_string().replace('\'', "''");
    let ps = format!(
        "$h=@'\n{summary}\n'@; $h | Out-GridView -Title 'Alien AI Agent'; Get-Content -LiteralPath '{path}' -Tail 500 | Out-GridView -Title 'Agent log (today file, tail)'"
    );
    let _ = std::process::Command::new("powershell")
        .args(["-NoProfile", "-Command", &ps])
        .spawn();
}

pub fn run(
    _hwnd_slot: &OnceLock<Mutex<isize>>,
    _unpair_tx: Option<tokio::sync::mpsc::UnboundedSender<crate::tray::TrayAction>>,
) -> anyhow::Result<()> {
    Ok(())
}
