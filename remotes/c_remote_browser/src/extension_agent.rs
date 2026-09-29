//! Extension mode: one background agent (user or login starts it). Native host must not spawn Chrome.

use std::net::TcpStream;
use std::process::Command;
use std::sync::Mutex;
use std::time::Duration;

use crate::extension_ipc::extension_ipc_addr;

fn ipc_reachable() -> bool {
    TcpStream::connect_timeout(&extension_ipc_addr(), Duration::from_millis(300)).is_ok()
}

static SPAWN_LOCK: Mutex<()> = Mutex::new(());

fn auto_start_agent_enabled() -> bool {
    matches!(
        std::env::var("C35_EXTENSION_AUTO_START_AGENT").ok().as_deref(),
        Some("1" | "true" | "TRUE" | "on" | "ON")
    )
}

/// Wait for the user-started WebRTC agent (IPC on 37538). Does not launch Chrome.
pub fn wait_for_extension_agent(max_wait: Duration) {
    let steps = (max_wait.as_millis() / 100).max(1) as usize;
    for _ in 0..steps {
        if ipc_reachable() {
            return;
        }
        std::thread::sleep(Duration::from_millis(100));
    }
}

/// Optional: spawn a hidden agent if IPC is down and auto-start is enabled (off by default).
pub fn ensure_extension_agent_running() {
    if ipc_reachable() {
        return;
    }
    if !auto_start_agent_enabled() {
        return;
    }
    let _guard = SPAWN_LOCK.lock().unwrap_or_else(|e| e.into_inner());
    if ipc_reachable() {
        return;
    }
    for _ in 0..30 {
        if ipc_reachable() {
            return;
        }
        std::thread::sleep(Duration::from_millis(100));
    }
    let exe = match std::env::current_exe() {
        Ok(p) => p,
        Err(_) => return,
    };
    let mut cmd = Command::new(exe);
    cmd.env("C35_BROWSER_ENGINE", "extension");
    if let Ok(v) = std::env::var("C35_SERVER_URL") {
        cmd.env("C35_SERVER_URL", v);
    }
    if let Ok(v) = std::env::var("C35_DEV") {
        cmd.env("C35_DEV", v);
    }
    #[cfg(windows)]
    {
        use std::os::windows::process::CommandExt;
        const CREATE_NO_WINDOW: u32 = 0x0800_0000;
        cmd.creation_flags(CREATE_NO_WINDOW);
    }
    let _ = cmd.spawn();
}
