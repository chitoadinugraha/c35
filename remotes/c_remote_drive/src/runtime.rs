use std::sync::Mutex;

use tokio::task::JoinHandle;
use tracing::info;

use crate::mount::{mount_drive, unmount_drive, PlatformMount};
use crate::sync::SyncEngine;
use crate::vfs::VfsDriveManager;

struct DriveRuntime {
    vfs: VfsDriveManager,
    sync_handle: JoinHandle<()>,
    mount: PlatformMount,
}

static RUNTIME: Mutex<Option<DriveRuntime>> = Mutex::new(None);

fn new_vfs_manager() -> VfsDriveManager {
    if cfg!(target_os = "windows") {
        VfsDriveManager::new("A:")
    } else {
        VfsDriveManager::new("")
    }
}

pub async fn drive_mount(session_key: &str, base_url: &str) -> anyhow::Result<()> {
    let key = session_key.trim();
    if key.is_empty() {
        anyhow::bail!("drive mount: empty session key");
    }
    {
        let guard = RUNTIME
            .lock()
            .map_err(|_| anyhow::anyhow!("drive runtime lock poisoned"))?;
        if guard.is_some() {
            return Ok(());
        }
    }
    let vfs = new_vfs_manager();
    let client = reqwest::Client::new();
    let quota = crate::vfs_winfsp::quota_from_agent_storage(&client, base_url, key).await;
    let mount = mount_drive(&vfs, quota)?;
    let file_base = crate::vfs_winfsp::file_service_url(base_url);
    #[cfg(target_os = "windows")]
    crate::watch_windows::start_drive_watcher(vfs.backing_dir.clone());
    #[cfg(target_os = "linux")]
    crate::watch_linux::start_drive_watcher(vfs.backing_dir.clone());
    let engine = SyncEngine::from_session(key, &file_base, vfs.backing_dir.clone());
    let sync_handle = tokio::spawn(async move {
        engine.run_loop().await;
    });
    let mut guard = RUNTIME
        .lock()
        .map_err(|_| anyhow::anyhow!("drive runtime lock poisoned"))?;
    if guard.is_some() {
        sync_handle.abort();
        unmount_drive(mount);
        #[cfg(target_os = "windows")]
        vfs.unmount_subst();
        #[cfg(target_os = "linux")]
        crate::mount::mount_linux::try_unmount_mount_point();
        return Ok(());
    }
    info!("Alien AI Drive mounted");
    *guard = Some(DriveRuntime { vfs, sync_handle, mount });
    Ok(())
}

pub fn drive_unmount() {
    let mut guard = match RUNTIME.lock() {
        Ok(g) => g,
        Err(_) => return,
    };
    if let Some(rt) = guard.take() {
        rt.sync_handle.abort();
        unmount_drive(rt.mount);
        #[cfg(target_os = "windows")]
        rt.vfs.unmount_subst();
        #[cfg(target_os = "linux")]
        crate::mount::mount_linux::try_unmount_mount_point();
        info!("Alien AI Drive unmounted");
    }
}
