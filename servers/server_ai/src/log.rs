//! Plain startup lines — no timestamp, level, or target.

use std::io::IsTerminal;

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
    println!("{} {line}", label("Store Connected:"));
}

pub fn features(names: &[&str]) {
    println!("{} {}", label("Features:"), ok(&names.join(", ")));
}

pub fn listening(entries: &[(&str, String)]) {
    if entries.is_empty() {
        return;
    }
    if entries.len() == 1 {
        println!("{} {}", label("Listening"), url(&entries[0].1));
        return;
    }
    println!("{}", label("Listening"));
    for (name, addr) in entries {
        println!("  {} {}", mute(name), url(addr));
    }
}

pub fn port_in_use(port: &str) {
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
