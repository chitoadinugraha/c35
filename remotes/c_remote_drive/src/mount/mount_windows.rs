use tracing::{info, warn};

use crate::vfs::VfsDriveManager;
use crate::vfs_winfsp::{QuotaSnapshot, ensure_winfsp_installed};

impl super::DriveMount for WindowsMount {
    type Handle = ();

    fn mount(vfs: &VfsDriveManager, quota: Option<QuotaSnapshot>) -> anyhow::Result<()> {
        mount(vfs, quota)
    }

    fn unmount(_handle: ()) {}
}

pub struct WindowsMount;

pub fn mount(vfs: &VfsDriveManager, quota: Option<QuotaSnapshot>) -> anyhow::Result<()> {
    vfs.prepare_layout()?;
    let quota = quota.unwrap_or(QuotaSnapshot {
        used_bytes: 0,
        limit_bytes: 1024 * 1024 * 1024,
    });
    let icon_dest = vfs.system_dir().join("alienai.ico");
    vfs.configure_windows_drive_icons(&icon_dest);
    #[cfg(feature = "winfsp")]
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
                        std::thread::sleep(std::time::Duration::from_millis(250));
                        if vfs.is_mounted() {
                            info!("WinFsp mount active for {}", vfs.drive_letter);
                            update_explorer_quota_label(vfs, &quota);
                            notify_explorer_drive(&vfs.drive_letter);
                            return Ok(());
                        }
                        warn!(
                            "WinFsp mount returned ok but {} is not visible; falling back to subst",
                            vfs.drive_letter
                        );
                    }
                    Err(e) => warn!("WinFsp mount failed ({e:#}); falling back to subst"),
                },
                Err(e) => warn!("WinFsp install failed ({e:#}); falling back to subst"),
            }
        }
    }
    vfs.mount_subst();
    if !vfs.is_mounted() {
        anyhow::bail!("Alien AI Drive is not visible after WinFsp and subst");
    }
    update_explorer_quota_label(vfs, &quota);
    notify_explorer_drive(&vfs.drive_letter);
    Ok(())
}

fn notify_explorer_drive(drive_letter: &str) {
    let drive = drive_letter.trim_end_matches('\\');
    let root = if drive.ends_with('\\') {
        drive.to_string()
    } else {
        format!("{drive}\\")
    };
    let ps = format!(
        "Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class AlienDriveNotify {{ [DllImport(\"shell32.dll\", CharSet=CharSet.Unicode)] public static extern void SHChangeNotify(uint ev, uint flags, string item1, System.IntPtr item2); }}' -ErrorAction SilentlyContinue; \
         [AlienDriveNotify]::SHChangeNotify(0x100, 0x5, '{root}', [IntPtr]::Zero); \
         [AlienDriveNotify]::SHChangeNotify(0x08000000, 0, $null, [IntPtr]::Zero);"
    );
    let _ = c_remote_core::win_powershell::command_status(&ps);
}

pub(crate) fn update_explorer_quota_label(vfs: &VfsDriveManager, quota: &QuotaSnapshot) {
    let drive_clean = vfs.drive_letter.trim_end_matches(':').trim_end_matches('\\');
    let label = quota.label().replace('\'', "''");
    let ps = format!(
        "$p='HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\DriveIcons\\{drive_clean}\\DefaultLabel'; \
         New-Item -Path $p -Force | Out-Null; \
         Set-ItemProperty -Path $p -Name '(Default)' -Value '{label}';",
    );
    let _ = c_remote_core::win_powershell::command_status(&ps);
}
