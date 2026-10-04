use std::sync::Mutex;

use tokio::task::JoinHandle;
use tracing::info;

use crate::sync::SyncEngine;
use crate::vfs::VfsDriveManager;
use crate::vfs_winfsp;

struct DriveRuntime {
    vfs: VfsDriveManager,
    sync_handle: JoinHandle<()>,
}

static RUNTIME: Mutex<Option<DriveRuntime>> = Mutex::new(None);

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
    let vfs = VfsDriveManager::new("A:");
    vfs.prepare_layout()?;
    let client = reqwest::Client::new();
    let quota = vfs_winfsp::quota_from_agent_storage(&client, base_url, key).await;
    vfs_winfsp::mount_virtual_drive(&vfs, quota)?;
    let file_base = vfs_winfsp::file_service_url(base_url);
    crate::watch_windows::start_drive_watcher(vfs.backing_dir.clone());
    let engine = SyncEngine::from_session(key, &file_base, vfs.backing_dir.clone());
    let sync_handle = tokio::spawn(async move {
        engine.run_loop().await;
    });
    let mut guard = RUNTIME
        .lock()
        .map_err(|_| anyhow::anyhow!("drive runtime lock poisoned"))?;
    if guard.is_some() {
        sync_handle.abort();
        #[cfg(target_os = "windows")]
        vfs.unmount_subst();
        return Ok(());
    }
    info!("Alien AI Drive mounted");
    *guard = Some(DriveRuntime { vfs, sync_handle });
    Ok(())
}

pub fn drive_unmount() {
    let mut guard = match RUNTIME.lock() {
        Ok(g) => g,
        Err(_) => return,
    };
    if let Some(rt) = guard.take() {
        rt.sync_handle.abort();
        #[cfg(target_os = "windows")]
        rt.vfs.unmount_subst();
        info!("Alien AI Drive unmounted");
    }
}