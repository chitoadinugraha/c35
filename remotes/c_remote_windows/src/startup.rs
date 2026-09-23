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
