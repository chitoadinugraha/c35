use std::sync::atomic::{AtomicBool, Ordering};

use c_remote_core::config::{drive_enabled_load, drive_enabled_save, server_url, session_key_load};
use tracing::info;

static SYNCING: AtomicBool = AtomicBool::new(false);

pub fn drive_start_on_agent_ready() {
    c_remote_drive::ws_drive::register_ws_drive_sync_handler();
    c_remote_core::agent_ui::drive_enabled_set(drive_enabled_load());
}

pub async fn drive_apply(enabled: bool) -> anyhow::Result<()> {
    drive_enabled_save(enabled)?;
    c_remote_core::agent_ui::drive_enabled_set(enabled);
    if enabled {
        drive_mount().await
    } else {
        drive_unmount();
        Ok(())
    }
}

pub async fn drive_mount() -> anyhow::Result<()> {
    if !drive_enabled_load() {
        anyhow::bail!("drive sync skipped: disabled");
    }
    let key = session_key_load().filter(|k| !k.trim().is_empty());
    if key.is_none() {
        anyhow::bail!("drive sync skipped: not paired");
    }
    if SYNCING.load(Ordering::SeqCst) {
        return Ok(());
    }
    let key = key.unwrap();
    let base = server_url();
    c_remote_drive::mount_android::drive_sync_start(&key, &base).await?;
    SYNCING.store(true, Ordering::SeqCst);
    info!("Alien AI Drive cache sync running");
    Ok(())
}

pub fn drive_unmount() {
    c_remote_drive::mount_android::drive_sync_stop();
    SYNCING.store(false, Ordering::SeqCst);
    info!("Alien AI Drive cache sync stopped");
}

pub fn drive_cache_dir_display() -> String {
    c_remote_drive::mount_android::drive_cache_dir()
        .to_string_lossy()
        .into_owned()
}
