//! Ensure the main WebRTC agent is running (extension engine mode).

use std::net::TcpStream;
use std::process::Command;
use std::time::Duration;

use crate::extension_ipc::extension_ipc_addr;

pub fn ensure_extension_agent_running() {
    let addr = extension_ipc_addr();
    if TcpStream::connect_timeout(&addr, Duration::from_millis(400)).is_ok() {
        return;
    }
    let exe = match std::env::current_exe() {
        Ok(p) => p,
        Err(_) => return,
    };
    #[cfg(windows)]
    {
        use std::os::windows::process::CommandExt;
        const CREATE_NO_WINDOW: u32 = 0x0800_0000;
        let _ = Command::new(exe)
            .env("C35_BROWSER_ENGINE", "extension")
            .creation_flags(CREATE_NO_WINDOW)
            .spawn();
    }
    #[cfg(not(windows))]
    {
        let _ = Command::new(exe).env("C35_BROWSER_ENGINE", "extension").spawn();
    }
}
