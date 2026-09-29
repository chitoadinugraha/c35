//! WinFsp silent install + mount helpers.
use std::path::PathBuf;
use tracing::{info, warn};

use crate::vfs::VfsDriveManager;

pub struct QuotaSnapshot {
    pub used_bytes: u64,
    pub limit_bytes: u64,
}

impl QuotaSnapshot {
    pub fn label(&self) -> String {
        "Alien AI".to_string()
    }
}

pub const WINFSP_DLL_NAME: &str = "winfsp-x64.dll";

pub const WINFSP_MSI_URL: &str =
    "https://github.com/winfsp/winfsp/releases/download/v2.1/winfsp-2.1.25156.msi";

fn winfsp_dll_beside_exe() -> Option<PathBuf> {
    std::env::current_exe().ok().and_then(|exe| {
        let dll = exe.parent()?.join(WINFSP_DLL_NAME);
        dll.exists().then_some(dll)
    })
}

pub fn winfsp_dll_path() -> Option<PathBuf> {
    winfsp_dll_beside_exe().or_else(|| {
        [
            r"C:\Program Files (x86)\WinFsp\bin\winfsp-x64.dll",
            r"C:\Program Files\WinFsp\bin\winfsp-x64.dll",
        ]
        .into_iter()
        .map(PathBuf::from)
        .find(|p| p.exists())
    })
}

#[cfg(target_os = "windows")]
pub fn init_winfsp_dll_path() {
    use std::os::windows::ffi::OsStrExt;
    if let Some(dll) = winfsp_dll_path() {
        if let Some(dir) = dll.parent() {
            let wide: Vec<u16> = dir.as_os_str().encode_wide().chain(std::iter::once(0)).collect();
            unsafe {
                let _ = windows::Win32::System::LibraryLoader::SetDllDirectoryW(
                    windows::core::PCWSTR(wide.as_ptr()),
                );
            }
            if let Ok(current_path) = std::env::var("PATH") {
                let dir_str = dir.to_string_lossy();
                if !current_path.split(';').any(|p| p.eq_ignore_ascii_case(&dir_str)) {
                    let new_path = format!("{};{}", dir_str, current_path);
                    std::env::set_var("PATH", new_path);
                }
            }
        }
    }
}

#[cfg(not(target_os = "windows"))]
pub fn init_winfsp_dll_path() {}

#[cfg(target_os = "windows")]
pub fn ensure_winfsp_installed() -> anyhow::Result<()> {
    if winfsp_dll_path().is_some() {
        init_winfsp_dll_path();
        return Ok(());
    }
    info!("WinFsp missing — attempting silent install");
    let local = std::env::var("LOCALAPPDATA").unwrap_or_else(|_| r"C:\AlienAI".into());
    let dir = PathBuf::from(local).join("AlienAI");
    std::fs::create_dir_all(&dir)?;
    let _msi_path = dir.join("winfsp.msi");
    let ps = format!(
        "$ErrorActionPreference='Stop'; \
         $dir='{dir}'; \
         New-Item -ItemType Directory -Force -Path $dir | Out-Null; \
         $msi=Join-Path $dir 'winfsp.msi'; \
         Invoke-WebRequest -Uri '{url}' -OutFile $msi; \
         $p=Start-Process msiexec.exe -ArgumentList @('/i',$msi,'/quiet','/norestart','ADDLOCAL=ALL') -Wait -PassThru; \
         if ($p.ExitCode -ne 0) {{ exit $p.ExitCode }}",
        dir = dir.to_string_lossy().replace('\'', "''"),
        url = WINFSP_MSI_URL,
    );
    let status = c_remote_core::win_powershell::command_status(&ps)?;
    if !status.success() {
        anyhow::bail!("WinFsp silent install failed with status {status:?}");
    }
    if winfsp_dll_path().is_none() {
        anyhow::bail!("WinFsp install finished but winfsp-x64.dll not found");
    }
    info!("WinFsp installed successfully");
    init_winfsp_dll_path();
    Ok(())
}

#[cfg(not(target_os = "windows"))]
pub fn ensure_winfsp_installed() -> anyhow::Result<()> {
    anyhow::bail!("WinFsp is Windows-only")
}

pub fn mount_virtual_drive(vfs: &VfsDriveManager, quota: Option<QuotaSnapshot>) -> anyhow::Result<()> {
    vfs.prepare_layout()?;
    let quota = quota.unwrap_or(QuotaSnapshot {
        used_bytes: 0,
        limit_bytes: 1024 * 1024 * 1024,
    });
    #[cfg(target_os = "windows")]
    {
        let icon_dest = vfs.system_dir().join("alienai.ico");
        vfs.configure_windows_drive_icons(&icon_dest);
    }
    #[cfg(all(target_os = "windows", feature = "winfsp"))]
    {
        if std::env::var("ALIENAI_VFS_WINFSP").map(|v| v != "0").unwrap_or(true) {
            match ensure_winfsp_installed() {
                Ok(()) => match crate::vfs_winfsp_mount::start_winfsp_volume(
                    &vfs.drive_letter,
                    vfs.backing_dir.clone(),
                    quota.limit_bytes,
                    quota.used_bytes,
                ) {
                    Ok(host) => {
                        Box::leak(Box::new(host));
                        info!("WinFsp mount active for {}", vfs.drive_letter);
                        update_explorer_quota_label(vfs, &quota);
                        return Ok(());
                    }
                    Err(e) => warn!("WinFsp mount failed ({e:#}); falling back to subst"),
                },
                Err(e) => warn!("WinFsp install failed ({e:#}); falling back to subst"),
            }
        }
    }
    vfs.mount_subst();
    update_explorer_quota_label(vfs, &quota);
    Ok(())
}

pub fn update_explorer_quota_label(vfs: &VfsDriveManager, quota: &QuotaSnapshot) {
    #[cfg(target_os = "windows")]
    {
        let drive_clean = vfs.drive_letter.trim_end_matches(':').trim_end_matches('\\');
        let label = quota.label().replace('\'', "''");
        let ps = format!(
            "$p='HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\DriveIcons\\{drive_clean}\\DefaultLabel'; \
             New-Item -Path $p -Force | Out-Null; \
             Set-ItemProperty -Path $p -Name '(Default)' -Value '{label}';",
        );
        let _ = c_remote_core::win_powershell::command_status(&ps);
    }
    #[cfg(not(target_os = "windows"))]
    {
        let _ = (vfs, quota);
    }
}

pub fn file_service_url(api_base: &str) -> String {
    std::env::var("FILE_SERVICE_URL").unwrap_or_else(|_| api_base.trim_end_matches('/').to_string())
}

pub async fn quota_from_device_storage(client: &reqwest::Client, api_base: &str, session_key: &str) -> Option<QuotaSnapshot> {
    let url = format!("{}/v1/agent/storage", api_base.trim_end_matches('/'));
    let res = client.get(url).header("X-Device-Session", session_key).send().await.ok()?;
    if !res.status().is_success() {
        return None;
    }
    let body: serde_json::Value = res.json().await.ok()?;
    let used = body.get("storage_used_bytes").and_then(|v| v.as_u64()).unwrap_or(0);
    let limit = body.get("storage_limit_bytes").and_then(|v| v.as_u64()).unwrap_or(1024 * 1024 * 1024);
    Some(QuotaSnapshot { used_bytes: used, limit_bytes: limit })
}

pub async fn quota_from_billing_api(client: &reqwest::Client, base_url: &str, token: &str) -> Option<QuotaSnapshot> {
    let url = format!("{}/v1/auth/me", base_url.trim_end_matches('/'));
    let res = client.get(url).bearer_auth(token).send().await.ok()?;
    if !res.status().is_success() {
        return None;
    }
    let body: serde_json::Value = res.json().await.ok()?;
    let used = body.get("storage_used_bytes").and_then(|v| v.as_u64()).unwrap_or(0);
    let limit = body.get("storage_limit_bytes").and_then(|v| v.as_u64()).unwrap_or(1024 * 1024 * 1024);
    Some(QuotaSnapshot { used_bytes: used, limit_bytes: limit })
}

pub async fn quota_from_agent_storage(client: &reqwest::Client, api_base: &str, session_key: &str) -> Option<QuotaSnapshot> {
    quota_from_device_storage(client, api_base, session_key).await
}
