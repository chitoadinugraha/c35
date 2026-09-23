use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::Duration;

use serde::Deserialize;
use tokio::sync::Notify;
use tracing::{info, warn};

use crate::version::AGENT_BUILD;

static ACTIVE_TASKS: AtomicUsize = AtomicUsize::new(0);
static ACTIVE_SESSIONS: AtomicUsize = AtomicUsize::new(0);
static IDLE_NOTIFY: Notify = Notify::const_new();

/// RAII guard to track active task execution.
pub struct TaskGuard;

impl Drop for TaskGuard {
    fn drop(&mut self) {
        let prev = ACTIVE_TASKS.fetch_sub(1, Ordering::SeqCst);
        let current = prev.saturating_sub(1);
        info!(active_tasks = current, "task finished");
        notify_idle_if_ready();
    }
}

/// Begin tracking a task execution. Decrements when guard is dropped.
pub fn task_start() -> TaskGuard {
    let prev = ACTIVE_TASKS.fetch_add(1, Ordering::SeqCst);
    info!(active_tasks = prev + 1, "task started");
    TaskGuard
}

pub fn active_tasks() -> usize {
    ACTIVE_TASKS.load(Ordering::Relaxed)
}

pub fn active_sessions_set(count: usize) {
    let prev = ACTIVE_SESSIONS.swap(count, Ordering::SeqCst);
    if prev != count {
        info!(active_sessions = count, "webrtc active sessions count updated");
        if count == 0 {
            notify_idle_if_ready();
        }
    }
}

pub fn active_sessions() -> usize {
    ACTIVE_SESSIONS.load(Ordering::Relaxed)
}

/// Check if the agent is idle: no running tasks and no active user remote sessions.
pub fn is_idle() -> bool {
    active_tasks() == 0 && active_sessions() == 0
}

/// Check if running in development mode.
pub fn is_dev_mode() -> bool {
    if cfg!(debug_assertions) {
        return true;
    }
    if let Ok(val) = std::env::var("C35_DEV") {
        if val == "1" || val.eq_ignore_ascii_case("true") {
            return true;
        }
    }
    std::env::args().any(|a| a == "--dev" || a == "--cli")
}

pub fn notify_idle_if_ready() {
    if is_idle() {
        IDLE_NOTIFY.notify_waiters();
    }
}

// Backward compatibility alias
pub fn task_busy() -> bool {
    !is_idle()
}

#[derive(Debug, Clone, Deserialize)]
pub struct ReleaseRes {
    pub version: i64,
    #[serde(rename = "versionName")]
    pub version_name: String,
    pub min: i64,
    pub hash: Option<String>,
    pub size: Option<i64>,
    pub url: String,
}

pub fn current_platform() -> &'static str {
    #[cfg(target_os = "windows")]
    return "remote-windows";
    #[cfg(target_os = "macos")]
    return "remote-macos";
    #[cfg(target_os = "linux")]
    return "remote-linux";
    #[cfg(target_os = "android")]
    return "remote-android";
    #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux", target_os = "android")))]
    return "remote-windows";
}

pub fn updates_root() -> PathBuf {
    #[cfg(target_os = "windows")]
    {
        if let Ok(appdata) = std::env::var("LOCALAPPDATA") {
            return PathBuf::from(appdata).join("AlienAI").join("updates").join("remote");
        }
    }
    #[cfg(target_os = "macos")]
    {
        if let Ok(home) = std::env::var("HOME") {
            return PathBuf::from(home)
                .join("Library")
                .join("Application Support")
                .join("AlienAI")
                .join("updates")
                .join("remote");
        }
    }
    #[cfg(target_os = "linux")]
    {
        if let Ok(home) = std::env::var("HOME") {
            return PathBuf::from(home)
                .join(".local")
                .join("share")
                .join("alienai")
                .join("updates")
                .join("remote");
        }
    }
    PathBuf::from(".alienai_updates").join("remote")
}

fn install_dir() -> PathBuf {
    std::env::current_exe()
        .ok()
        .and_then(|p| p.parent().map(Path::to_path_buf))
        .unwrap_or_else(|| PathBuf::from("."))
}

fn staging_dir(version: i64) -> PathBuf {
    updates_root().join(version.to_string())
}

fn ready_marker(version: i64) -> PathBuf {
    staging_dir(version).join(".ready")
}

pub async fn update_poll(base_url: &str) -> Result<Option<ReleaseRes>, anyhow::Error> {
    let url = format!("{}/version/{}", base_url.trim_end_matches('/'), current_platform());
    let res = reqwest::Client::new().get(&url).send().await?;
    if !res.status().is_success() {
        return Ok(None);
    }
    let body: ReleaseRes = res.json().await?;
    if body.version > AGENT_BUILD {
        Ok(Some(body))
    } else {
        Ok(None)
    }
}

pub async fn update_download(_base_url: &str, rel: &ReleaseRes) -> Result<(), anyhow::Error> {
    if rel.hash.as_deref().unwrap_or("").is_empty() {
        anyhow::bail!("release missing hash");
    }
    let staging = staging_dir(rel.version);
    if ready_marker(rel.version).exists() {
        return Ok(());
    }
    if staging.exists() {
        let _ = std::fs::remove_dir_all(&staging);
    }
    std::fs::create_dir_all(&staging)?;

    info!(version = rel.version, url = %rel.url, "downloading agent update in background");
    let bytes = reqwest::Client::new().get(&rel.url).send().await?.bytes().await?;
    if let Some(sz) = rel.size {
        if sz > 0 && bytes.len() as i64 != sz {
            anyhow::bail!("size mismatch: got {} expected {}", bytes.len(), sz);
        }
    }
    let hash = blake3::hash(&bytes).to_hex().to_string();
    let expect = rel.hash.as_deref().unwrap_or("").to_lowercase();
    if hash != expect {
        anyhow::bail!("blake3 mismatch: got {hash} expected {expect}");
    }

    let zip_path = staging.join("bundle.zip");
    std::fs::write(&zip_path, &bytes)?;
    extract_zip(&zip_path, &staging)?;
    let _ = std::fs::remove_file(&zip_path);
    std::fs::write(ready_marker(rel.version), b"ok")?;
    info!(version = rel.version, "agent update staged and verified");
    Ok(())
}

fn extract_zip(zip_path: &Path, out_dir: &Path) -> Result<(), anyhow::Error> {
    let file = std::fs::File::open(zip_path)?;
    let mut archive = zip::ZipArchive::new(file)?;
    for i in 0..archive.len() {
        let mut f = archive.by_index(i)?;
        let name = f.name().replace('\\', "/");
        if name.ends_with('/') {
            continue;
        }
        let out = out_dir.join(Path::new(&name).file_name().unwrap_or(std::path::Component::CurDir.as_os_str()));
        if let Some(parent) = out.parent() {
            std::fs::create_dir_all(parent)?;
        }
        let mut out_file = std::fs::File::create(&out)?;
        std::io::copy(&mut f, &mut out_file)?;
    }
    Ok(())
}

pub fn update_staged_version() -> Option<i64> {
    let root = updates_root();
    if !root.exists() {
        return None;
    }
    let mut best = 0i64;
    for ent in std::fs::read_dir(&root).into_iter().flatten().flatten() {
        let name = ent.file_name().to_string_lossy().to_string();
        if let Ok(v) = name.parse::<i64>() {
            if ready_marker(v).exists() && v > best {
                best = v;
            }
        }
    }
    if best > AGENT_BUILD {
        Some(best)
    } else {
        None
    }
}

pub fn update_apply(version: i64) -> Result<(), anyhow::Error> {
    if is_dev_mode() {
        info!(version, "Dev mode active; skipping update_apply to protect development environment");
        return Ok(());
    }

    let staging = staging_dir(version);
    let exe = staging.join("c_remote_windows.exe");
    if !exe.exists() {
        anyhow::bail!("staged exe missing: {}", exe.display());
    }
    let install = install_dir();
    let script = updates_root().join("apply.ps1");
    let script_body = format!(
        r#"
$staging = '{staging}'
$install = '{install}'
$exe = Join-Path $install 'c_remote_windows.exe'
$deadline = (Get-Date).AddSeconds(8)
while ((Get-Process -Name c_remote_windows -ErrorAction SilentlyContinue) -and ((Get-Date) -lt $deadline)) {{
  Start-Sleep -Milliseconds 200
}}
Get-Process -Name c_remote_windows -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 300
Copy-Item -Path (Join-Path $staging 'c_remote_windows.exe') -Destination $exe -Force
Start-Process $exe
exit 0
"#,
        staging = staging.display().to_string().replace('\'', "''"),
        install = install.display().to_string().replace('\'', "''"),
    );
    std::fs::create_dir_all(script.parent().unwrap())?;
    std::fs::write(&script, script_body)?;

    #[cfg(target_os = "windows")]
    {
        info!(version, "Spawning update apply script and exiting process");
        Command::new("powershell")
            .args([
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-WindowStyle",
                "Hidden",
                "-File",
                script.to_str().unwrap(),
            ])
            .spawn()?;
        std::process::exit(0);
    }
    #[cfg(any(target_os = "linux", target_os = "macos"))]
    {
        let exe_name = if cfg!(target_os = "macos") { "c_remote_macos" } else { "c_remote_linux" };
        let staged_bin = staging.join(exe_name);
        if !staged_bin.exists() {
            anyhow::bail!("staged binary missing: {}", staged_bin.display());
        }
        let dest_bin = install.join(exe_name);
        let script = updates_root().join("apply.sh");
        let script_body = format!(
            r#"#!/bin/sh
sleep 1
cp -f "{staging}/{exe_name}" "{dest_bin}"
chmod +x "{dest_bin}"
nohup "{dest_bin}" > /dev/null 2>&1 &
exit 0
"#,
            staging = staging.display(),
            exe_name = exe_name,
            dest_bin = dest_bin.display(),
        );
        std::fs::create_dir_all(script.parent().unwrap())?;
        std::fs::write(&script, script_body)?;
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            let _ = std::fs::set_permissions(&script, std::fs::Permissions::from_mode(0o755));
        }
        Command::new("sh").arg(script.to_str().unwrap()).spawn()?;
        std::process::exit(0);
    }
    #[cfg(not(any(target_os = "windows", target_os = "linux", target_os = "macos")))]
    {
        anyhow::bail!("auto-update not yet supported on this OS");
    }
}

/// Trigger an immediate background check and download (e.g. from NATS release push).
pub fn trigger_background_update(base_url: String) {
    tokio::spawn(async move {
        match update_poll(&base_url).await {
            Ok(Some(rel)) => {
                if !ready_marker(rel.version).exists() {
                    if let Err(e) = update_download(&base_url, &rel).await {
                        warn!("immediate background update download failed: {e}");
                        return;
                    }
                }
                // Notify active viewers so appbar update button appears
                crate::webrtc::notify_update_ready(rel.version).await;

                if is_idle() {
                    info!(version = rel.version, "agent is idle; applying update now");
                    let _ = update_apply(rel.version);
                } else {
                    info!(
                        version = rel.version,
                        active_tasks = active_tasks(),
                        active_sessions = active_sessions(),
                        "update staged; waiting for agent to become idle before applying"
                    );
                }
            }
            Ok(None) => {}
            Err(e) => warn!("immediate update poll failed: {e}"),
        }
    });
}

pub async fn update_run_loop(base_url: String) {
    let mut tick = tokio::time::interval(Duration::from_secs(300));
    tick.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Delay);
    loop {
        tokio::select! {
            _ = tick.tick() => {
                check_and_stage_update(&base_url).await;
            }
            _ = IDLE_NOTIFY.notified() => {
                if let Some(v) = update_staged_version() {
                    if is_idle() {
                        info!(version = v, "idle signal received; applying staged agent update");
                        if let Err(e) = update_apply(v) {
                            warn!("update apply staged failed: {e}");
                        }
                    }
                }
            }
        }
    }
}

async fn check_and_stage_update(base_url: &str) {
    if let Some(v) = update_staged_version() {
        if is_idle() {
            info!(version = v, "applying staged agent update");
            if let Err(e) = update_apply(v) {
                warn!("update apply staged failed: {e}");
            }
            return;
        }
    }

    match update_poll(base_url).await {
        Ok(Some(rel)) => {
            if !ready_marker(rel.version).exists() {
                if let Err(e) = update_download(base_url, &rel).await {
                    warn!("update download failed: {e}");
                    return;
                }
            }
            crate::webrtc::notify_update_ready(rel.version).await;
            if is_idle() {
                info!(version = rel.version, "agent idle; applying mandatory agent update");
                let _ = update_apply(rel.version);
            } else {
                info!(
                    version = rel.version,
                    active_tasks = active_tasks(),
                    active_sessions = active_sessions(),
                    "agent busy; update held until idle"
                );
            }
        }
        Ok(None) => {}
        Err(e) => warn!("update poll failed: {e}"),
    }
}

pub async fn update_check_on_start(base_url: &str) {
    let base_url = base_url.to_string();
    tokio::spawn(async move {
        match update_poll(&base_url).await {
            Ok(Some(rel)) => {
                if let Err(e) = update_download(&base_url, &rel).await {
                    warn!("startup update download: {e}");
                } else {
                    crate::webrtc::notify_update_ready(rel.version).await;
                }
            }
            Ok(None) => {}
            Err(e) => warn!("startup update poll: {e}"),
        }
    });
}
