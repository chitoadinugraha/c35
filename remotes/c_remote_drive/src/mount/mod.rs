//! Platform-specific Alien AI Drive mount (WinFsp / FUSE).

use crate::vfs::VfsDriveManager;
use crate::vfs_winfsp::QuotaSnapshot;

/// Mount the owner drive for the current OS.
pub fn mount_drive(vfs: &VfsDriveManager, quota: Option<QuotaSnapshot>) -> anyhow::Result<PlatformMount> {
    #[cfg(target_os = "windows")]
    {
        mount_windows::mount(vfs, quota)?;
        Ok(PlatformMount::Windows)
    }
    #[cfg(target_os = "linux")]
    {
        let guard = mount_linux::mount(vfs, quota)?;
        Ok(PlatformMount::Linux(guard))
    }
    #[cfg(not(any(target_os = "windows", target_os = "linux")))]
    {
        let _ = (vfs, quota);
        anyhow::bail!("Alien AI Drive mount is not supported on this platform")
    }
}

/// Drop the platform mount (sync stop is handled separately).
pub fn unmount_drive(mount: PlatformMount) {
    match mount {
        #[cfg(target_os = "windows")]
        PlatformMount::Windows => {}
        #[cfg(target_os = "linux")]
        PlatformMount::Linux(guard) => guard.unmount(),
        #[cfg(not(any(target_os = "windows", target_os = "linux")))]
        PlatformMount::Stub => {}
    }
}

/// Handle returned from [`mount_drive`] for cleanup on unpair / disable.
pub enum PlatformMount {
    #[cfg(target_os = "windows")]
    Windows,
    #[cfg(target_os = "linux")]
    Linux(mount_linux::LinuxMountGuard),
    #[cfg(not(any(target_os = "windows", target_os = "linux")))]
    Stub,
}

/// Cross-platform mount contract (Windows / Linux implementations).
pub trait DriveMount {
    type Handle: Send;

    fn mount(vfs: &VfsDriveManager, quota: Option<QuotaSnapshot>) -> anyhow::Result<Self::Handle>;
    fn unmount(handle: Self::Handle);
}

#[cfg(target_os = "windows")]
pub mod mount_windows;
#[cfg(target_os = "linux")]
pub mod mount_linux;
#[cfg(not(target_os = "linux"))]
pub mod mount_linux;
