use std::path::PathBuf;
use std::process::Stdio;
use std::sync::Arc;

use anyhow::{Context, Result};
use tokio::process::{Child, Command};
use tracing::{info, warn};

use super::ipc::{stdout_reader_loop, EngineBridge};
use crate::browser_state::BrowserState;

pub struct EngineProcess {
    pub child: Child,
    pub bridge: Arc<EngineBridge>,
    reader: tokio::task::JoinHandle<()>,
    pub slot_id: String,
}

fn config_root() -> PathBuf {
    let mut p = c_remote_core::config::config_path();
    p.pop();
    p
}

pub fn sanitize_slot_id(slot_id: &str) -> String {
    let s: String = slot_id
        .chars()
        .map(|c| {
            if c.is_ascii_alphanumeric() || c == '_' || c == '-' {
                c
            } else {
                '_'
            }
        })
        .collect();
    if s.is_empty() {
        "default".into()
    } else {
        s
    }
}

pub fn slot_paths(slot_id: &str) -> (PathBuf, PathBuf) {
    let id = sanitize_slot_id(slot_id);
    let user_data = config_root().join("slots").join(&id);
    let downloads = user_data.join("downloads");
    let _ = std::fs::create_dir_all(&downloads);
    let _ = std::fs::create_dir_all(&user_data);
    (user_data, downloads)
}

pub async fn spawn_engine(headless: bool, slot_id: &str) -> Result<EngineProcess> {
    let worker = resolve_worker_script()?;
    let node = std::env::var("C35_NODE").unwrap_or_else(|_| "node".into());
    let slot_id = sanitize_slot_id(slot_id);
    let (profile, downloads) = slot_paths(&slot_id);
    info!(
        worker = %worker.display(),
        headless,
        slot_id = %slot_id,
        profile = %profile.display(),
        "spawning browser_engine"
    );

    let mut child = Command::new(&node)
        .arg(&worker)
        .env("C35_BROWSER_HEADLESS", if headless { "1" } else { "0" })
        .env("C35_BROWSER_PROFILE", profile.to_string_lossy().to_string())
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .spawn()
        .with_context(|| format!("spawn {node} {}", worker.display()))?;

    let stdin = child.stdin.take().context("engine stdin")?;
    let stdout = child.stdout.take().context("engine stdout")?;
    let bridge = Arc::new(EngineBridge::new(stdin));
    let reader = tokio::spawn(stdout_reader_loop(bridge.clone(), stdout));

    tokio::time::sleep(std::time::Duration::from_millis(150)).await;

    bridge
        .call(
            "launch",
            serde_json::json!({
                "headless": headless,
                "userDataDir": profile.to_string_lossy(),
                "downloadsPath": downloads.to_string_lossy(),
                "slot_id": slot_id,
                "viewport": { "width": 1280, "height": 800 }
            }),
        )
        .await?;

    let _ = bridge.call("screencast.start", serde_json::json!({})).await;

    Ok(EngineProcess {
        child,
        bridge,
        reader,
        slot_id,
    })
}

pub async fn ensure_engine(
    state: &BrowserState,
    headless: bool,
    slot_id: &str,
) -> Result<Arc<EngineBridge>> {
    let slot_id = sanitize_slot_id(slot_id);
    let (needs_spawn, old) = {
        let mut guard = state
            .engine
            .lock()
            .map_err(|_| anyhow::anyhow!("engine lock"))?;
        let restart = guard
            .as_ref()
            .map(|e| e.slot_id != slot_id)
            .unwrap_or(true);
        if guard.is_none() || restart {
            (true, guard.take())
        } else {
            (false, None)
        }
    };
    if needs_spawn {
        if let Some(mut e) = old {
            shutdown_engine(&mut e).await;
        }
        let proc = spawn_engine(headless, &slot_id).await?;
        let bridge = proc.bridge.clone();
        state
            .engine
            .lock()
            .map_err(|_| anyhow::anyhow!("engine lock"))?
            .replace(proc);
        return Ok(bridge);
    }
    let guard = state
        .engine
        .lock()
        .map_err(|_| anyhow::anyhow!("engine lock"))?;
    Ok(guard
        .as_ref()
        .ok_or_else(|| anyhow::anyhow!("engine missing"))?
        .bridge
        .clone())
}

pub async fn shutdown_engine(proc: &mut EngineProcess) {
    let _ = proc.bridge.call("shutdown", serde_json::json!({})).await;
    proc.reader.abort();
    if let Err(e) = proc.child.kill().await {
        warn!("engine kill: {e}");
    }
}

fn resolve_worker_script() -> Result<PathBuf> {
    if let Ok(p) = std::env::var("C35_BROWSER_ENGINE_WORKER") {
        return Ok(PathBuf::from(p));
    }
    let exe = std::env::current_exe().context("current_exe")?;
    let dir = exe.parent().context("exe parent")?;
    let candidate = dir.join("browser_engine").join("dist").join("worker.js");
    if candidate.is_file() {
        return Ok(candidate);
    }
    let dev = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("..")
        .join("browser_engine")
        .join("dist")
        .join("worker.js");
    if dev.is_file() {
        return Ok(dev);
    }
    anyhow::bail!("browser_engine worker not found");
}