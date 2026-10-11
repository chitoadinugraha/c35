//! Extension mode: embedded agent in the Chrome native-host process + optional detached child.

use std::net::TcpStream;
use std::path::PathBuf;
use std::process::Command;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Mutex;
use std::thread;
use std::time::Duration;

use tracing::{info, warn};

use crate::extension_ipc::{
    extension_ipc_addr, extension_ipc_listener_pid, extension_ipc_port_in_use, kill_process_pid,
    HostIpcClient,
};

fn ipc_reachable() -> bool {
    TcpStream::connect_timeout(&extension_ipc_addr(), Duration::from_millis(300)).is_ok()
}

static SPAWN_LOCK: Mutex<()> = Mutex::new(());
static EMBEDDED_AGENT: AtomicBool = AtomicBool::new(false);

pub fn embedded_agent_active() -> bool {
    EMBEDDED_AGENT.load(Ordering::SeqCst)
}

fn ipc_agent_healthy() -> bool {
    if embedded_agent_active() {
        return true;
    }
    match HostIpcClient::connect_quick() {
        Ok(c) => c
            .fetch_agent_status(Duration::from_millis(1200))
            .is_ok(),
        Err(_) => false,
    }
}

/// Start or recover the WebRTC agent (embedded in NM host, or detached exe).
pub fn ensure_extension_agent_running() {
    if ipc_agent_healthy() {
        return;
    }
    let _guard = SPAWN_LOCK.lock().unwrap_or_else(|e| e.into_inner());
    if ipc_agent_healthy() {
        return;
    }
    let my_pid = std::process::id();
    if extension_ipc_port_in_use() {
        if let Some(pid) = extension_ipc_listener_pid() {
            if pid != my_pid {
                info!(pid, "extension agent: stopping stale listener");
                kill_process_pid(pid);
                thread::sleep(Duration::from_millis(400));
            }
        }
    }
    if !extension_ipc_port_in_use() {
        if EMBEDDED_AGENT.load(Ordering::SeqCst) {
            EMBEDDED_AGENT.store(false, Ordering::SeqCst);
        }
        spawn_embedded_extension_agent();
        wait_for_extension_agent(Duration::from_secs(12));
    }
    if !ipc_agent_healthy() {
        ensure_detached_extension_agent();
    }
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

fn install_agent_exe() -> Option<PathBuf> {
    let local = std::env::var_os("LOCALAPPDATA")?;
    let p = PathBuf::from(local)
        .join("AlienAI")
        .join("chrome_extension")
        .join("install")
        .join("alienai_remote_browser.exe");
    if p.is_file() { Some(p) } else { None }
}

fn spawn_detached_agent_exe(exe: &std::path::Path) -> bool {
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
        const DETACHED_PROCESS: u32 = 0x00000008;
        cmd.creation_flags(CREATE_NO_WINDOW | DETACHED_PROCESS);
    }
    cmd.spawn().is_ok()
}

/// Spawn a fresh extension agent (install dir exe or current exe), then exit this process so IPC can rebind.
pub fn restart_extension_agent() -> anyhow::Result<()> {
    let exe = install_agent_exe()
        .or_else(|| std::env::current_exe().ok())
        .ok_or_else(|| anyhow::anyhow!("agent exe not found"))?;
    if !spawn_detached_agent_exe(&exe) {
        anyhow::bail!("failed to spawn extension agent");
    }
    info!(path = %exe.display(), "agent.restart: spawned replacement");
    thread::spawn(|| {
        thread::sleep(Duration::from_millis(800));
        std::process::exit(0);
    });
    Ok(())
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
    let exe = install_agent_exe().or_else(|| std::env::current_exe().ok());
    let Some(exe) = exe else { return };
    if !spawn_detached_agent_exe(&exe) {
        return;
    }
    wait_for_extension_agent(Duration::from_secs(12));
}
