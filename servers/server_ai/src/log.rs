//! Plain startup lines — no timestamp, level, or target.

use std::io::{IsTerminal, Write};

const RESET: &str = "\x1b[0m";

fn color_enabled() -> bool {
    std::env::var("NO_COLOR").is_err() && std::io::stdout().is_terminal()
}
fn paint(code: &str, s: &str) -> String {
    if color_enabled() {
        format!("\x1b[{code}m{s}{RESET}")
    } else {
        s.to_string()
    }
}
fn label(s: &str) -> String {
    paint("1;36", s)
}
fn ok(s: &str) -> String {
    paint("32", s)
}
fn mute(s: &str) -> String {
    paint("2", s)
}
fn url(s: &str) -> String {
    paint("34", s)
}

fn emit_line(line: &str) {
    println!("{line}");
    let _ = std::io::stdout().flush();
}

pub fn booting(phase: &str) {
    emit_line(&format!("{} {}", label("Booting:"), mute(phase)));
}

pub fn store_connected(yb_ms: u128, nats_ms: Option<u128>, nats_required: bool) {
    let mut line = ok(&format!("YB {yb_ms}ms"));
    match nats_ms {
        Some(ms) => {
            line.push(' ');
            line.push_str(&ok(&format!("NATS {ms}ms")));
        }
        None if nats_required => {
            line.push(' ');
            line.push_str(&paint("31", "NATS failed"));
        }
        None => {}
    }
    emit_line(&format!("{} {line}", label("Store Connected:")));
}

pub fn features(names: &[impl AsRef<str>]) {
    let joined = names
        .iter()
        .map(|s| s.as_ref())
        .collect::<Vec<_>>()
        .join(", ");
    emit_line(&format!("{} {}", label("Features:"), ok(&joined)));
}

pub fn listening(entries: &[(&str, String)]) {
    if entries.is_empty() {
        return;
    }
    if entries.len() == 1 {
        emit_line(&format!("{} {}", label("Listening"), url(&entries[0].1)));
        return;
    }
    emit_line(&label("Listening"));
    for (name, addr) in entries {
        emit_line(&format!("  {} {}", mute(name), url(addr)));
    }
}

pub fn port_in_use(listen: &str) {
    let port = listen.rsplit(':').next().unwrap_or(listen);
    eprintln!("{} {}", label("Listening failed:"), url(listen));
    let pids = port_pids(port);
    if pids.is_empty() {
        return;
    }
    eprintln!();
    if cfg!(windows) {
        eprintln!(
            "Stop-Process -Id {} -Force",
            pids.iter().map(|p| p.to_string()).collect::<Vec<_>>().join(",")
        );
    } else {
        eprintln!(
            "kill -9 {}",
            pids.iter().map(|p| p.to_string()).collect::<Vec<_>>().join(" ")
        );
    }
    eprintln!();
}

#[cfg(windows)]
fn port_pids(port: &str) -> Vec<u32> {
    let script = format!(
        "(Get-NetTCPConnection -LocalPort {port} -ErrorAction SilentlyContinue).OwningProcess | Sort-Object -Unique"
    );
    std::process::Command::new("powershell")
        .args(["-NoProfile", "-NonInteractive", "-Command", &script])
        .output()
        .ok()
        .map(|out| parse_pids(&String::from_utf8_lossy(&out.stdout)))
        .unwrap_or_default()
}

#[cfg(not(windows))]
fn port_pids(port: &str) -> Vec<u32> {
    let script = format!("lsof -t -iTCP:{port} -sTCP:LISTEN 2>/dev/null || lsof -t -i:{port} 2>/dev/null");
    std::process::Command::new("sh")
        .args(["-c", &script])
        .output()
        .ok()
        .map(|out| parse_pids(&String::from_utf8_lossy(&out.stdout)))
        .unwrap_or_default()
}

fn parse_pids(s: &str) -> Vec<u32> {
    s.lines()
        .filter_map(|l| l.trim().parse().ok())
        .filter(|&p| p > 0)
        .collect()
}
