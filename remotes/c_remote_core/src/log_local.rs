use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::{Mutex, OnceLock};
use std::time::{SystemTime, UNIX_EPOCH};

use tracing_subscriber::{fmt, EnvFilter};

static LOG_SESSION: OnceLock<PathBuf> = OnceLock::new();

pub fn log_dir() -> PathBuf {
    #[cfg(target_os = "windows")]
    if let Ok(appdata) = std::env::var("LOCALAPPDATA") {
        let mut p = PathBuf::from(appdata);
        p.push("AlienAI");
        p.push("logs");
        return p;
    }
    let mut p = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    p.push(".alienai_logs");
    p
}

fn log_stamp() -> String {
    let ms = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis())
        .unwrap_or(0);
    format!("{ms}")
}

pub fn log_session_path() -> PathBuf {
    LOG_SESSION
        .get_or_init(|| {
            let path = log_dir().join(format!(
                "agent-{}-{}.log",
                log_stamp(),
                std::process::id()
            ));
            if let Some(parent) = path.parent() {
                let _ = fs::create_dir_all(parent);
            }
            let _ = log_latest_set(&path);
            path
        })
        .clone()
}

fn log_latest_marker() -> PathBuf {
    log_dir().join("latest.txt")
}

pub fn log_open_path() -> PathBuf {
    log_latest_read().unwrap_or_else(log_session_path)
}

fn log_latest_read() -> Option<PathBuf> {
    let marker = log_latest_marker();
    let text = fs::read_to_string(&marker).ok()?;
    let path = PathBuf::from(text.trim());
    if path.exists() {
        Some(path)
    } else {
        None
    }
}

fn log_latest_set(path: &Path) -> std::io::Result<()> {
    fs::create_dir_all(log_dir())?;
    fs::write(log_latest_marker(), path.display().to_string())
}

pub fn boot_append(msg: &str) {
    let path = log_session_path();
    if let Some(parent) = path.parent() {
        let _ = fs::create_dir_all(parent);
    }
    let ms = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis())
        .unwrap_or(0);
    let line = format!("{ms} {msg}\n");
    let _ = OpenOptions::new()
        .create(true)
        .append(true)
        .open(&path)
        .and_then(|mut f| f.write_all(line.as_bytes()));
}

pub fn init() {
    let path = log_session_path();
    let filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new("info,c_remote_core=debug,c_remote_windows=debug"));
    match OpenOptions::new().create(true).append(true).open(&path) {
        Ok(file) => {
            fmt()
                .with_env_filter(filter)
                .with_writer(Mutex::new(file))
                .with_ansi(false)
                .init();
            tracing::info!(
                path = %path.display(),
                pid = std::process::id(),
                "========== remote agent session start =========="
            );
        }
        Err(e) => {
            fmt().with_env_filter(filter).init();
            tracing::warn!(error = %e, path = %path.display(), "remote agent log file");
        }
    }
}

pub fn log_open() -> anyhow::Result<()> {
    let path = log_open_path();
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    if !path.exists() {
        fs::File::create(&path)?;
    }
    #[cfg(target_os = "windows")]
    {
        std::process::Command::new("cmd")
            .args(["/C", "start", "", &path.display().to_string()])
            .spawn()?;
    }
    #[cfg(not(target_os = "windows"))]
    {
        tracing::info!(path = %path.display(), "log file");
    }
    Ok(())
}
