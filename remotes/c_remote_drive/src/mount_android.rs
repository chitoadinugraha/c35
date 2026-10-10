//! Android (and headless) drive sync: cloud cache only, no FUSE / WinFsp mount.
//!
//! Cache layout: `{agent config dir}/alienai/drive_a` where the config dir is
//! `C35_AGENT_STORAGE` on Android (see `c_remote_android` daemon).

use std::path::PathBuf;
use std::sync::Mutex;

use tokio::task::JoinHandle;
use tracing::{info, warn};

use crate::sync::SyncEngine;
use crate::vfs::VfsDriveManager;
use crate::vfs_winfsp::file_service_url;

struct SyncRuntime {
    sync_handle: JoinHandle<()>,
}

static RUNTIME: Mutex<Option<SyncRuntime>> = Mutex::new(None);

/// Local cloud file cache exposed to Android `DocumentsProvider` as "Alien AI".
pub fn drive_cache_dir() -> PathBuf {
    c_remote_core::config::config_path()
        .parent()
        .map(|p| p.join("alienai").join("drive_a"))
        .unwrap_or_else(|| PathBuf::from("alienai").join("drive_a"))
}

pub async fn drive_sync_start(session_key: &str, api_base: &str) -> anyhow::Result<()> {
    let key = session_key.trim();
    if key.is_empty() {
        anyhow::bail!("drive sync: empty session key");
    }
    {
        let guard = RUNTIME
            .lock()
            .map_err(|_| anyhow::anyhow!("drive sync runtime lock poisoned"))?;
        if guard.is_some() {
            return Ok(());
        }
    }

    let backing = drive_cache_dir();
    let vfs = VfsDriveManager::with_backing_dir("", backing.clone());
    vfs.prepare_layout()?;

    let file_base = file_service_url(api_base);
    let cache_for_log = backing.display().to_string();
    let engine = SyncEngine::from_session(key, &file_base, backing);
    let sync_handle = tokio::spawn(async move {
        engine.run_loop().await;
    });

    let mut guard = RUNTIME
        .lock()
        .map_err(|_| anyhow::anyhow!("drive sync runtime lock poisoned"))?;
    if guard.is_some() {
        sync_handle.abort();
        return Ok(());
    }
    info!(dir = %cache_for_log, "Alien AI Drive sync started (cache only)");
    *guard = Some(SyncRuntime { sync_handle });
    Ok(())
}

pub fn drive_sync_stop() {
    let mut guard = match RUNTIME.lock() {
        Ok(g) => g,
        Err(_) => return,
    };
    if let Some(rt) = guard.take() {
        rt.sync_handle.abort();
        info!("Alien AI Drive sync stopped");
    }
}

pub async fn drive_sync_apply(enabled: bool, session_key: &str, api_base: &str) {
    if enabled {
        if let Err(e) = drive_sync_start(session_key, api_base).await {
            warn!("Alien AI Drive sync start failed: {e:#}");
        }
    } else {
        drive_sync_stop();
    }
}
