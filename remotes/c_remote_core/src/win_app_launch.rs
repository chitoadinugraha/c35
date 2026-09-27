//! Open GUI apps via ShellExecute (same as double-click), without PowerShell.

use std::path::{Path, PathBuf};

#[cfg(windows)]
pub fn try_direct_launch(command: &str) -> Option<Result<(), String>> {
    let target = launch_target_parse(command)?;
    Some(shell_open(&target))
}

#[cfg(not(windows))]
pub fn try_direct_launch(_command: &str) -> Option<Result<(), String>> {
    None
}

fn launch_target_parse(command: &str) -> Option<String> {
    let raw = command.trim();
    if raw.is_empty() {
        return None;
    }
    let lower = raw.to_ascii_lowercase();
    if lower.contains('|') || lower.contains(';') || raw.lines().count() > 1 {
        return None;
    }
    if lower.starts_with("start-process") {
        return start_process_target(raw);
    }
    if lower.starts_with("start ") {
        let rest = raw.get(6..)?.trim().trim_matches('"');
        if rest.is_empty() {
            return None;
        }
        return Some(resolve_launch_target(rest));
    }
    if is_simple_launch_token(raw) {
        return Some(resolve_launch_target(raw.trim_matches('"')));
    }
    None
}

fn is_simple_launch_token(raw: &str) -> bool {
    let t = raw.trim().trim_matches('"');
    if t.is_empty() {
        return false;
    }
    if t.contains('\\') || t.ends_with(".exe") || t.ends_with(".lnk") {
        return true;
    }
    matches!(
        t.to_ascii_lowercase().as_str(),
        "chrome"
            | "google chrome"
            | "msedge"
            | "edge"
            | "microsoft edge"
            | "firefox"
            | "notepad"
            | "calc"
            | "calculator"
            | "explorer"
    )
}

fn start_process_target(raw: &str) -> Option<String> {
    let lower = raw.to_ascii_lowercase();
    let idx = lower.find("start-process")?;
    let mut rest = raw.get(idx + 13..)?.trim();
    let lower = rest.to_ascii_lowercase();
    if let Some(i) = lower.find("-filepath") {
        rest = rest.get(i + 9..)?.trim();
    }
    let token = first_arg_token(rest)?;
    Some(resolve_launch_target(token))
}

fn first_arg_token(s: &str) -> Option<&str> {
    let t = s.trim();
    if t.is_empty() {
        return None;
    }
    if t.starts_with('"') {
        let end = t[1..].find('"')? + 1;
        return Some(t.get(1..end)?.trim());
    }
    Some(t.split_whitespace().next()?.trim_matches('"'))
}

fn resolve_launch_target(name: &str) -> String {
    let t = name.trim().trim_matches('"');
    if t.contains('\\') || t.ends_with(".exe") || t.ends_with(".lnk") {
        return t.to_string();
    }
    match t.to_ascii_lowercase().as_str() {
        "chrome" | "google chrome" => find_existing(&chrome_paths()).unwrap_or_else(|| "chrome".into()),
        "msedge" | "edge" | "microsoft edge" => find_existing(&edge_paths()).unwrap_or_else(|| "msedge".into()),
        "firefox" => find_existing(&firefox_paths()).unwrap_or_else(|| "firefox".into()),
        "notepad" => "notepad.exe".into(),
        "calc" | "calculator" => "calc.exe".into(),
        "explorer" => "explorer.exe".into(),
        _ => t.to_string(),
    }
}

fn chrome_paths() -> [PathBuf; 3] {
    [
        local_appdata().join(r"Google\Chrome\Application\chrome.exe"),
        PathBuf::from(r"C:\Program Files\Google\Chrome\Application\chrome.exe"),
        PathBuf::from(r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"),
    ]
}

fn edge_paths() -> [PathBuf; 2] {
    [
        PathBuf::from(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"),
        PathBuf::from(r"C:\Program Files\Microsoft\Edge\Application\msedge.exe"),
    ]
}

fn firefox_paths() -> [PathBuf; 1] {
    [PathBuf::from(r"C:\Program Files\Mozilla Firefox\firefox.exe")]
}

fn local_appdata() -> PathBuf {
    std::env::var_os("LOCALAPPDATA")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from(r"C:\Users\Default\AppData\Local"))
}

fn find_existing(paths: &[PathBuf]) -> Option<String> {
    paths
        .iter()
        .find(|p| Path::new(p).is_file())
        .map(|p| p.to_string_lossy().into_owned())
}

#[cfg(windows)]
fn shell_open(path: &str) -> Result<(), String> {
    use windows::core::w;
    use windows::Win32::UI::Shell::ShellExecuteW;
    use windows::Win32::UI::WindowsAndMessaging::SW_SHOWNORMAL;
    let wide: Vec<u16> = path.encode_utf16().chain([0u16]).collect();
    unsafe {
        let code = ShellExecuteW(
            None,
            w!("open"),
            windows::core::PCWSTR(wide.as_ptr()),
            None,
            None,
            SW_SHOWNORMAL,
        );
        if code.0 as isize <= 32 {
            return Err(format!("ShellExecute failed ({})", code.0 as isize));
        }
    }
    Ok(())
}