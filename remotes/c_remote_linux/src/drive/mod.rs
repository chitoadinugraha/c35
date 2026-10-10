use std::sync::atomic::{AtomicBool, Ordering};

use c_remote_core::config::{drive_enabled_load, drive_enabled_save, server_url, session_key_load};
use tracing::{info, warn};

static MOUNTED: AtomicBool = AtomicBool::new(false);

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
        anyhow::bail!("drive mount skipped: disabled");
    }
    let key = session_key_load().filter(|k| !k.trim().is_empty());
    if key.is_none() {
        anyhow::bail!("drive mount skipped: not paired");
    }
    if MOUNTED.load(Ordering::SeqCst) {
        return Ok(());
    }
    let key = key.unwrap();
    let base = server_url();
    match c_remote_drive::runtime::drive_mount(&key, &base).await {
        Ok(()) => {
            MOUNTED.store(true, Ordering::SeqCst);
            info!("Alien AI Drive mounted");
            Ok(())
        }
        Err(e) => {
            warn!("Alien AI Drive mount failed: {e:#}");
            Err(e)
        }
    }
}

pub fn drive_unmount() {
    if !MOUNTED.swap(false, Ordering::SeqCst) {
        return;
    }
    c_remote_drive::runtime::drive_unmount();
    info!("Alien AI Drive unmounted");
}
