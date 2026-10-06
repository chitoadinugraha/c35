//! Manage Windows Auto-Start via HKCU\Software\Microsoft\Windows\CurrentVersion\Run
//! and keep-alive power management.

use anyhow::Result;
use tracing::info;

#[cfg(windows)]
const RUN_KEY: windows::core::PCWSTR = windows::core::w!("Software\\Microsoft\\Windows\\CurrentVersion\\Run");
#[cfg(windows)]
const APP_NAME: windows::core::PCWSTR = windows::core::w!("AlienAI Remote Agent");

#[cfg(windows)]
pub fn is_autostart_enabled() -> bool {
    use windows::Win32::System::Registry::{
        RegCloseKey, RegOpenKeyExW, RegQueryValueExW, HKEY_CURRENT_USER, KEY_READ,
    };
    unsafe {
        let mut hkey = windows::Win32::System::Registry::HKEY::default();
        if RegOpenKeyExW(HKEY_CURRENT_USER, RUN_KEY, 0, KEY_READ, &mut hkey).is_ok() {
            let mut data_len = 0u32;
            let res = RegQueryValueExW(
                hkey,
                APP_NAME,
                None,
                None,
                None,
                Some(&mut data_len),
            );
            let _ = RegCloseKey(hkey);
            res.is_ok()
        } else {
            false
        }
    }
}

#[cfg(windows)]
pub fn ensure_autostart_when_paired(paired: bool) {
    if !paired {
        return;
    }
    if let Err(e) = set_autostart_enabled(true) {
        tracing::warn!(error = %e, "failed to register Windows logon autostart (HKCU Run)");
    }
}

#[cfg(not(windows))]
pub fn ensure_autostart_when_paired(_paired: bool) {}

#[cfg(windows)]
pub fn set_autostart_enabled(enabled: bool) -> Result<()> {
    use windows::Win32::System::Registry::{
        RegCloseKey, RegDeleteValueW, RegOpenKeyExW, RegSetValueExW, HKEY_CURRENT_USER, KEY_WRITE,
        REG_SZ,
    };

    unsafe {
        let mut hkey = windows::Win32::System::Registry::HKEY::default();
        RegOpenKeyExW(HKEY_CURRENT_USER, RUN_KEY, 0, KEY_WRITE, &mut hkey).ok()?;

        if enabled {
            let exe_path = std::env::current_exe()?;
            let val_str = format!("\"{}\"", exe_path.display());
            let val_wide: Vec<u16> = val_str.encode_utf16().chain(std::iter::once(0)).collect();

            let bytes = std::slice::from_raw_parts(
                val_wide.as_ptr() as *const u8,
                val_wide.len() * std::mem::size_of::<u16>(),
            );

            let res = RegSetValueExW(hkey, APP_NAME, 0, REG_SZ, Some(bytes));
            let _ = RegCloseKey(hkey);
            res.ok()?;
            info!(path = %val_str, "Windows autostart registered in HKCU Run key");
        } else {
            let _ = RegDeleteValueW(hkey, APP_NAME);
            let _ = RegCloseKey(hkey);
            info!("Windows autostart removed from HKCU Run key");
        }
    }
    Ok(())
}

#[cfg(windows)]
pub fn prevent_sleep() {
    use windows::Win32::System::Power::{
        SetThreadExecutionState, ES_AWAYMODE_REQUIRED, ES_CONTINUOUS, ES_SYSTEM_REQUIRED,
    };
    unsafe {
        let _ = SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_AWAYMODE_REQUIRED);
    }
    info!("Power state configured: system and network stay awake for remote automation");
}

#[cfg(windows)]
pub fn ensure_firewall_and_network_ready() {
    // 1. Try to register firewall rule silently via netsh (effective if run with administrative privileges or service).
    if let Ok(exe) = std::env::current_exe() {
        let exe_str = exe.to_string_lossy().to_string();
        std::thread::spawn(move || {
            use std::os::windows::process::CommandExt;
            const CREATE_NO_WINDOW: u32 = 0x08000000;
            let _ = std::process::Command::new("netsh")
                .args(&[
                    "advfirewall",
                    "firewall",
                    "add",
                    "rule",
                    "name=AlienAI Remote Agent",
                    "dir=in",
                    "action=allow",
                    &format!("program={}", exe_str),
                    "enable=yes",
                    "profile=any",
                ])
                .creation_flags(CREATE_NO_WINDOW)
                .output();
        });
    }

    // 2. Pre-bind a UDP listener on startup so Windows Firewall triggers its
    // permission prompt immediately upon application launch while the user is present,
    // rather than hours later during an unattended incoming WebRTC session.
    std::thread::spawn(|| {
        if let Ok(socket) = std::net::UdpSocket::bind("0.0.0.0:0") {
            std::thread::sleep(std::time::Duration::from_millis(1500));
            drop(socket);
        }
    });
}

#[cfg(not(windows))]
pub fn is_autostart_enabled() -> bool {
    false
}

#[cfg(not(windows))]
pub fn set_autostart_enabled(_enabled: bool) -> Result<()> {
    Ok(())
}

#[cfg(not(windows))]
pub fn prevent_sleep() {}

#[cfg(not(windows))]
pub fn ensure_firewall_and_network_ready() {}

/// Spawn a fresh agent process (same exe + args), then exit the current process.
pub fn agent_restart_spawn() -> Result<()> {
    let exe = std::env::current_exe()?;
    let args: Vec<String> = std::env::args().skip(1).collect();
    #[cfg(windows)]
    {
        use std::os::windows::process::CommandExt;
        use std::process::Command;
        const CREATE_NEW_PROCESS_GROUP: u32 = 0x00000200;
        const DETACHED_PROCESS: u32 = 0x00000008;
        Command::new(&exe)
            .args(&args)
            .creation_flags(CREATE_NEW_PROCESS_GROUP | DETACHED_PROCESS)
            .spawn()?;
    }
    #[cfg(not(windows))]
    {
        use std::process::Command;
        Command::new(&exe).args(&args).spawn()?;
    }
    info!(path = %exe.display(), "spawned agent restart");
    Ok(())
}
