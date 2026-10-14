//! Chrome extension readiness probes and repair actions for `browser.ensure`.

use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::Duration;

use serde_json::{json, Value};

use crate::extension_install::{install_extension_dir, install_extension_manifest_version};
use crate::extension_ipc::{extension_bridge_get, extension_ipc_port_in_use};

const NM_NAME: &str = "com.alienai.c35.remote";
const CHROME_DOWNLOAD_URL: &str = "https://www.google.com/chrome/";

pub async fn browser_ensure(params: &Value) -> anyhow::Result<Value> {
    let run_repairs = params
        .get("run_repairs")
        .and_then(|v| v.as_bool())
        .unwrap_or(true);
    let open_chrome_ui = params
        .get("open_chrome_ui")
        .and_then(|v| v.as_bool())
        .unwrap_or(false);
    let only_actions: Option<Vec<String>> = params.get("actions").and_then(|v| {
        v.as_array().map(|a| {
            a.iter()
                .filter_map(|x| x.as_str().map(str::trim).filter(|s| !s.is_empty()))
                .map(|s| s.to_string())
                .collect()
        })
    });

    if !crate::extension_ipc::extension_ipc_server_is_local() {
        crate::extension_agent::ensure_extension_agent_running();
    }

    let mut repairs_applied: Vec<String> = Vec::new();
    if run_repairs {
        let needed = probe_repair_actions(open_chrome_ui);
        let to_run = match &only_actions {
            Some(list) => needed
                .into_iter()
                .filter(|a| list.iter().any(|x| x == a))
                .collect(),
            None => needed,
        };
        for action in to_run {
            if run_repair(&action).is_ok() {
                repairs_applied.push(action);
            }
        }
        if repairs_applied.iter().any(|a| a == "sync_install" || a == "register_nm") {
            std::thread::sleep(Duration::from_millis(400));
        }
    }

    let mut status = probe_status().await?;
    if run_repairs
        && open_chrome_ui
        && !status.extension_connected
        && status.chrome_installed
    {
        for action in ["load_extension_in_chrome", "open_extensions_page"] {
            if run_repair(action).is_ok() {
                repairs_applied.push(action.to_string());
            }
        }
        std::thread::sleep(Duration::from_millis(800));
        status = probe_status().await?;
    }
    let repair_actions = probe_repair_actions(open_chrome_ui);
    let ok = status.chrome_installed
        && status.nm_ok
        && status.extension_connected
        && status
            .install_version
            .as_ref()
            .is_some_and(|s| !s.is_empty());

    let user_offer = build_user_offer(&status, &repair_actions, ok);
    let llm_summary = if ok {
        "Chrome and the Alien AI Remote extension are connected. You can use browser.tabs and browser.sheets on this device."
    } else {
        "Chrome and/or the Alien AI Remote extension are not ready on this PC. Offer the user the setup steps below (faster sheet/web automation on their Chrome profile, lower cost than cluster web search)."
    };

    Ok(json!({
        "ok": ok,
        "chrome_installed": status.chrome_installed,
        "nm_ok": status.nm_ok,
        "extension_connected": status.extension_connected,
        "install_version": status.install_version,
        "running_version": status.running_version,
        "install_path": status.install_path,
        "repair_actions": repair_actions,
        "repairs_applied": repairs_applied,
        "chrome_download_url": CHROME_DOWNLOAD_URL,
        "user_offer": user_offer,
        "llm": {
            "ok": ok,
            "summary": llm_summary,
        },
    }))
}

fn build_user_offer(status: &ProbeStatus, repair_actions: &[String], ready: bool) -> Value {
    let mut steps: Vec<String> = Vec::new();
    if !status.chrome_installed {
        steps.push(format!(
            "Install Google Chrome from {CHROME_DOWNLOAD_URL} (required for daily-profile automation)."
        ));
    }
    if repair_actions.iter().any(|a| a == "sync_install") || status.install_version.is_none() {
        steps.push(
            "Sync the Alien AI Remote extension files on this PC (browser.ensure run_repairs, or agent OTA).".into(),
        );
    }
    if repair_actions.iter().any(|a| a == "register_nm") || !status.nm_ok {
        steps.push(
            "Register the Chrome native messaging host for Alien AI (automatic with browser.ensure repairs).".into(),
        );
    }
    if repair_actions.iter().any(|a| a == "open_extensions_page")
        || (!status.extension_connected && status.chrome_installed)
    {
        let path = status
            .install_path
            .as_deref()
            .filter(|p| !p.is_empty())
            .unwrap_or("%LOCALAPPDATA%\\AlienAI\\chrome_extension\\install\\alienai_remote");
        steps.push(format!(
            "If Alien AI Remote is not listed after automatic setup: chrome://extensions → Developer mode ON → Load unpacked → folder with manifest.json: C:\\AlienAI-Remote-Extension (or {path}). Enable the extension, then Reload."
        ));
    }
    if steps.is_empty() && !ready {
        steps.push("Open Chrome and confirm the Alien AI Remote extension is enabled.".into());
    }

    json!({
        "title": "Chrome + Alien AI extension",
        "pitch": "Use your real Chrome logins for Google Sheets and sites — faster and cheaper than cloud web search hops.",
        "ready": ready,
        "steps": steps,
        "chrome_download_url": CHROME_DOWNLOAD_URL,
        "install_path": status.install_path,
    })
}

struct ProbeStatus {
    chrome_installed: bool,
    nm_ok: bool,
    extension_connected: bool,
    install_version: Option<String>,
    running_version: Option<String>,
    install_path: Option<String>,
}

async fn probe_status() -> anyhow::Result<ProbeStatus> {
    let chrome_installed = chrome_installed();
    let nm_ok = native_messaging_registered();
    let install_version = install_extension_manifest_version();
    let install_path = install_extension_dir().map(|p| p.display().to_string());
    let extension_connected = extension_ipc_connected().await;
    let running_version = if extension_connected {
        fetch_extension_running_version().await
    } else {
        None
    };
    Ok(ProbeStatus {
        chrome_installed,
        nm_ok,
        extension_connected,
        install_version,
        running_version,
        install_path,
    })
}

fn probe_repair_actions(open_chrome_ui: bool) -> Vec<String> {
    let mut out = Vec::new();
    let connected = extension_version_sync_probe();
    if !chrome_installed() {
        out.push("install_chrome".into());
    }
    if install_extension_manifest_version().is_none() {
        out.push("sync_install".into());
    }
    if !native_messaging_registered() {
        out.push("register_nm".into());
    }
    if !extension_ipc_port_in_use() && !crate::extension_ipc::extension_ipc_server_is_local() {
        out.push("start_extension_agent".into());
    }
    if open_chrome_ui
        && !connected
        && chrome_installed()
        && install_extension_manifest_version().is_some()
    {
        out.push("load_extension_in_chrome".into());
        out.push("open_extensions_page".into());
    }
    out
}

fn run_repair(action: &str) -> anyhow::Result<()> {
    match action {
        "install_chrome" => open_chrome_download_page(),
        "sync_install" => sync_install(),
        "register_nm" => register_native_messaging(),
        "open_extensions_page" => open_extensions_page(),
        "load_extension_in_chrome" => load_extension_in_chrome(),
        "start_extension_agent" => {
            crate::extension_agent::ensure_extension_agent_running();
            Ok(())
        }
        other => anyhow::bail!("unknown repair action: {other}"),
    }
}

fn open_chrome_download_page() -> anyhow::Result<()> {
    open_url_in_browser(CHROME_DOWNLOAD_URL)
}

/// Launch Chrome with `--load-extension` (unpacked install dir). Interactive session only.
fn load_extension_in_chrome() -> anyhow::Result<()> {
    let dir = install_extension_dir().ok_or_else(|| {
        anyhow::anyhow!("extension install folder missing — run sync_install first")
    })?;
    let chrome = chrome_exe_candidates()
        .into_iter()
        .find(|p| p.is_file())
        .ok_or_else(|| anyhow::anyhow!("chrome.exe not found"))?;
    let arg = format!("--load-extension={}", dir.display());
    #[cfg(windows)]
    {
        crate::win_util::spawn_no_console(
            &chrome.to_string_lossy(),
            &[&arg],
        )
        .map_err(|e| anyhow::anyhow!("start chrome with extension: {e}"))?;
        return Ok(());
    }
    #[cfg(not(windows))]
    {
        Command::new(&chrome)
            .arg(&arg)
            .spawn()
            .map_err(|e| anyhow::anyhow!("start chrome with extension: {e}"))?;
        Ok(())
    }
}

fn open_url_in_browser(url: &str) -> anyhow::Result<()> {
    #[cfg(windows)]
    {
        return crate::win_util::shell_open(url);
    }
    #[cfg(target_os = "macos")]
    {
        Command::new("open")
            .arg(url)
            .spawn()
            .map_err(|e| anyhow::anyhow!("open url: {e}"))?;
        return Ok(());
    }
    #[cfg(target_os = "linux")]
    {
        Command::new("xdg-open")
            .arg(url)
            .spawn()
            .map_err(|e| anyhow::anyhow!("xdg-open: {e}"))?;
        return Ok(());
    }
    #[cfg(not(any(windows, target_os = "macos", target_os = "linux")))]
    {
        anyhow::bail!("open browser not supported on this OS");
    }
}

fn chrome_installed() -> bool {
    for path in chrome_exe_candidates() {
        if path.is_file() {
            return true;
        }
    }
    #[cfg(windows)]
    {
        if which_on_path("chrome.exe") {
            return true;
        }
    }
    false
}

fn chrome_exe_candidates() -> Vec<PathBuf> {
    let mut paths = Vec::new();
    if let Ok(pf) = std::env::var("ProgramFiles") {
        paths.push(
            PathBuf::from(pf)
                .join("Google")
                .join("Chrome")
                .join("Application")
                .join("chrome.exe"),
        );
    }
    if let Ok(pf86) = std::env::var("ProgramFiles(x86)") {
        paths.push(
            PathBuf::from(pf86)
                .join("Google")
                .join("Chrome")
                .join("Application")
                .join("chrome.exe"),
        );
    }
    if let Ok(local) = std::env::var("LOCALAPPDATA") {
        paths.push(
            PathBuf::from(local)
                .join("Google")
                .join("Chrome")
                .join("Application")
                .join("chrome.exe"),
        );
    }
    paths
}

#[cfg(windows)]
fn which_on_path(exe: &str) -> bool {
    Command::new("where")
        .arg(exe)
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}

#[cfg(not(windows))]
fn which_on_path(_exe: &str) -> bool {
    false
}

fn native_messaging_manifest_path() -> Option<PathBuf> {
    let local = std::env::var_os("LOCALAPPDATA")?;
    Some(
        PathBuf::from(local)
            .join("AlienAI")
            .join("chrome_extension")
            .join("native_host")
            .join(format!("{NM_NAME}.json")),
    )
}

fn native_messaging_registered() -> bool {
    let manifest = match native_messaging_manifest_path().filter(|p| p.is_file()) {
        Some(p) => p,
        None => return false,
    };
    let raw = match fs::read_to_string(&manifest) {
        Ok(s) => s,
        Err(_) => return false,
    };
    let v: Value = match serde_json::from_str(&raw) {
        Ok(v) => v,
        Err(_) => return false,
    };
    let path = v.get("path").and_then(|x| x.as_str()).unwrap_or("");
    if path.is_empty() || !Path::new(path).is_file() {
        return false;
    }
    #[cfg(windows)]
    {
        let reg_key = format!(r"Software\Google\Chrome\NativeMessagingHosts\{NM_NAME}");
        match crate::win_util::reg_query_default_value(&reg_key) {
            Some(v) => {
                let norm = |s: &str| s.trim().replace('/', "\\");
                norm(&v) == norm(&manifest.display().to_string())
            }
            None => false,
        }
    }
    #[cfg(not(windows))]
    {
        true
    }
}

/// Same predicate as `extension_connected` in ensure probes (MV3 answers `extension.version`).
pub fn extension_version_sync_probe() -> bool {
    if !extension_ipc_port_in_use() {
        return false;
    }
    let Some(bridge) = extension_bridge_get() else {
        return false;
    };
    let bridge = bridge.clone();
    let (tx, rx) = std::sync::mpsc::channel();
    std::thread::spawn(move || {
        let ok = bridge
            .call("extension.version", json!({}), Duration::from_secs(6))
            .ok()
            .and_then(|v| {
                v.get("version")
                    .and_then(|x| x.as_str())
                    .map(str::trim)
                    .filter(|s| !s.is_empty())
                    .map(|_| ())
            })
            .is_some();
        let _ = tx.send(ok);
    });
    rx.recv_timeout(Duration::from_secs(7)).unwrap_or(false)
}

async fn extension_ipc_connected() -> bool {
    if !extension_ipc_port_in_use() {
        return false;
    }
    if tokio::task::spawn_blocking(extension_version_sync_probe)
        .await
        .unwrap_or(false)
    {
        return true;
    }
    fetch_extension_running_version().await.is_some()
}

/// Run once on desktop agent start: sync extension files and NM host only (no Chrome UI).
pub fn bootstrap_desktop_extension() -> anyhow::Result<()> {
    let mut steps: Vec<&str> = Vec::new();
    if install_extension_manifest_version().is_none() {
        if sync_install().is_ok() {
            steps.push("sync_install");
        }
    }
    if !native_messaging_registered() {
        if register_native_messaging().is_ok() {
            steps.push("register_nm");
        }
    }
    tracing::info!(
        steps = ?steps,
        connected = extension_version_sync_probe(),
        "desktop extension bootstrap"
    );
    Ok(())
}

async fn fetch_extension_running_version() -> Option<String> {
    let bridge = extension_bridge_get()?;
    let bridge = bridge.clone();
    let out = tokio::task::spawn_blocking(move || {
        bridge.call("extension.version", json!({}), Duration::from_secs(8))
    })
    .await;
    match out {
        Ok(Ok(v)) => v
            .get("version")
            .and_then(|x| x.as_str())
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .map(|s| s.to_string()),
        _ => None,
    }
}

fn extension_source_dir() -> Option<PathBuf> {
    if let Ok(src) = std::env::var("C35_CHROME_EXTENSION_SRC") {
        let p = PathBuf::from(src.trim());
        if p.join("manifest.json").is_file() {
            return Some(p);
        }
    }
    if let Ok(exe) = std::env::current_exe() {
        if let Some(dir) = exe.parent() {
            let bundled = dir.join("chrome_extension").join("alienai_remote");
            if bundled.join("manifest.json").is_file() {
                return Some(bundled);
            }
            let dev = dir
                .parent()
                .and_then(|p| p.parent())
                .and_then(|p| p.parent())
                .map(|repo| {
                    repo.join("clients")
                        .join("chrome_extension")
                        .join("alienai_remote")
                });
            if dev.as_ref().is_some_and(|p| p.join("manifest.json").is_file()) {
                return dev;
            }
        }
    }
    if let Ok(local) = std::env::var("LOCALAPPDATA") {
        let alt = PathBuf::from(local)
            .join("AlienAI")
            .join("remote")
            .join("chrome_extension")
            .join("alienai_remote");
        if alt.join("manifest.json").is_file() {
            return Some(alt);
        }
    }
    None
}

fn sync_install() -> anyhow::Result<()> {
    let src = extension_source_dir().ok_or_else(|| {
        anyhow::anyhow!("extension source package not found (set C35_CHROME_EXTENSION_SRC)")
    })?;
    let dst = install_extension_dir().unwrap_or_else(|| {
        let local = std::env::var_os("LOCALAPPDATA")
            .map(PathBuf::from)
            .unwrap_or_else(|| PathBuf::from("."));
        local
            .join("AlienAI")
            .join("chrome_extension")
            .join("install")
            .join("alienai_remote")
    });
    fs::create_dir_all(&dst)?;
    fs::create_dir_all(dst.join("dist"))?;
    fs::copy(src.join("manifest.json"), dst.join("manifest.json"))?;
    copy_dir_files(&src.join("dist"), &dst.join("dist"))?;
    if src.join("icons").is_dir() {
        copy_tree(&src.join("icons"), &dst.join("icons"))?;
    }
    let server_url = c_remote_core::config::server_url();
    let url = server_url.trim();
    let url = if url.is_empty() {
        "https://alienai.id"
    } else {
        url
    };
    let cfg = json!({ "server_url": url });
    fs::write(dst.join("config.json"), serde_json::to_string_pretty(&cfg)?)?;
    #[cfg(windows)]
    mirror_windows_extension_short_path(&dst)?;
    Ok(())
}

/// Shallow copy for Chrome "Load unpacked" when AppData paths confuse the file picker.
#[cfg(windows)]
fn mirror_windows_extension_short_path(src: &Path) -> anyhow::Result<()> {
    let short = PathBuf::from(r"C:\AlienAI-Remote-Extension");
    if short.exists() {
        fs::remove_dir_all(&short)?;
    }
    copy_tree(src, &short)?;
    Ok(())
}

#[cfg(not(windows))]
fn mirror_windows_extension_short_path(_src: &Path) -> anyhow::Result<()> {
    Ok(())
}

fn copy_dir_files(src: &Path, dst: &Path) -> anyhow::Result<()> {
    if !src.is_dir() {
        anyhow::bail!("missing dist dir: {}", src.display());
    }
    fs::create_dir_all(dst)?;
    for ent in fs::read_dir(src)? {
        let ent = ent?;
        let path = ent.path();
        if path.is_file() {
            let name = ent.file_name();
            fs::copy(&path, dst.join(name))?;
        }
    }
    Ok(())
}

fn copy_tree(src: &Path, dst: &Path) -> anyhow::Result<()> {
    fs::create_dir_all(dst)?;
    for ent in fs::read_dir(src)? {
        let ent = ent?;
        let path = ent.path();
        let target = dst.join(ent.file_name());
        if path.is_dir() {
            copy_tree(&path, &target)?;
        } else if path.is_file() {
            fs::copy(&path, &target)?;
        }
    }
    Ok(())
}

fn register_native_messaging() -> anyhow::Result<()> {
    let host_exe = std::env::current_exe()?;
    let nm_dir = native_messaging_manifest_path()
        .and_then(|p| p.parent().map(|d| d.to_path_buf()))
        .ok_or_else(|| anyhow::anyhow!("LOCALAPPDATA not set"))?;
    fs::create_dir_all(&nm_dir)?;
    let nm_file = nm_dir.join(format!("{NM_NAME}.json"));
    let body = json!({
        "name": NM_NAME,
        "description": "Alien AI Remote native host",
        "path": host_exe.display().to_string(),
        "type": "stdio",
        "allowed_origins": [
            "chrome-extension://nnijloaplkijpadhmifhleodobafjffi/",
        ],
    });
    fs::write(&nm_file, serde_json::to_string_pretty(&body)?)?;
    #[cfg(windows)]
    {
        let reg_key = format!(r"Software\Google\Chrome\NativeMessagingHosts\{NM_NAME}");
        crate::win_util::reg_set_native_host_manifest(&reg_key, &nm_file.display().to_string())?;
    }
    Ok(())
}

fn open_extensions_page() -> anyhow::Result<()> {
    #[cfg(windows)]
    {
        if let Some(chrome) = chrome_exe_candidates().into_iter().find(|p| p.is_file()) {
            let _ = crate::win_util::spawn_no_console(
                &chrome.to_string_lossy(),
                &["chrome://extensions/"],
            );
        } else {
            crate::win_util::shell_open("chrome://extensions/")?;
        }
        return Ok(());
    }
    #[cfg(not(windows))]
    {
        anyhow::bail!("open_extensions_page is only supported on Windows");
    }
}
