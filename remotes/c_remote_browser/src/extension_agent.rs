//! Extension mode: embedded agent in the Chrome native-host process + optional detached child.

use std::net::TcpStream;
use std::process::Command;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Mutex;
use std::thread;
use std::time::Duration;

use tracing::warn;

use crate::extension_ipc::{extension_ipc_addr, extension_ipc_port_in_use};

fn ipc_reachable() -> bool {
    TcpStream::connect_timeout(&extension_ipc_addr(), Duration::from_millis(300)).is_ok()
}

static SPAWN_LOCK: Mutex<()> = Mutex::new(());
static EMBEDDED_AGENT: AtomicBool = AtomicBool::new(false);

pub fn embedded_agent_active() -> bool {
    EMBEDDED_AGENT.load(Ordering::SeqCst)
}

/// Wait for extension IPC (agent on 37538).
pub fn wait_for_extension_agent(max_wait: Duration) {
    let steps = (max_wait.as_millis() / 100).max(1) as usize;
    for _ in 0..steps {
        if ipc_reachable() {
            return;
        }
        thread::sleep(Duration::from_millis(100));
    }
}

/// Chrome native host: run the WebRTC agent in-process (shared `agent_ui` — no TCP status hop).
pub fn spawn_embedded_extension_agent() {
    if extension_ipc_port_in_use() {
        return;
    }
    if EMBEDDED_AGENT.swap(true, Ordering::SeqCst) {
        return;
    }
    thread::spawn(|| {
        std::env::set_var("C35_BROWSER_ENGINE", "extension");
        std::env::set_var("C35_SKIP_OTA", "1");
        match crate::run_agent_blocking() {
            Ok(()) => {}
            Err(e) => warn!("embedded extension agent: {e:#}"),
        }
        EMBEDDED_AGENT.store(false, Ordering::SeqCst);
    });
}

/// Fallback: detached hidden agent when IPC is still down (e.g. dev `start_chrome_remote_agent.ps1` not run).
pub fn ensure_detached_extension_agent() {
    if ipc_reachable() {
        return;
    }
    let _guard = SPAWN_LOCK.lock().unwrap_or_else(|e| e.into_inner());
    if ipc_reachable() {
        return;
    }
    let exe = match std::env::current_exe() {
        Ok(p) => p,
        Err(_) => return,
    };
    let mut cmd = Command::new(exe);
    cmd.env("C35_BROWSER_ENGINE", "extension");
    cmd.env("C35_SKIP_OTA", "1");
    if let Ok(v) = std::env::var("C35_SERVER_URL") {
        cmd.env("C35_SERVER_URL", v);
    }
    #[cfg(windows)]
    {
        use std::os::windows::process::CommandExt;
        const CREATE_NO_WINDOW: u32 = 0x0800_0000;
        cmd.creation_flags(CREATE_NO_WINDOW);
    }
    if cmd.spawn().is_err() {
        return;
    }
    wait_for_extension_agent(Duration::from_secs(12));
}
