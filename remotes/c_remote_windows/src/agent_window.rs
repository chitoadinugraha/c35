use std::sync::{Mutex, OnceLock};
use tracing::warn;

static HWND_SLOT: OnceLock<Mutex<isize>> = OnceLock::new();
static UNPAIR_TX: OnceLock<tokio::sync::mpsc::UnboundedSender<crate::tray::TrayAction>> = OnceLock::new();

pub fn start(unpair_tx: tokio::sync::mpsc::UnboundedSender<crate::tray::TrayAction>) {
    let _ = UNPAIR_TX.set(unpair_tx);
    HWND_SLOT.get_or_init(|| Mutex::new(0));
    std::thread::Builder::new()
        .name("alienai-agent-ui".into())
        .spawn(|| {
            if let Err(e) = run_ui_loop() {
                warn!("Agent window error: {e:#}");
            }
        })
        .expect("agent ui thread");
}

pub fn arm_show() {
    #[cfg(windows)]
    crate::agent_status_window::arm_show();
}

pub fn show_or_focus() {
    #[cfg(windows)]
    crate::agent_window_ui::show_or_focus(&HWND_SLOT);
}

/// Ask an already-running agent to open its status window, then the caller exits.
#[cfg(not(windows))]
pub fn signal_show_existing() {}

#[cfg(windows)]
pub fn signal_show_existing() {
    use windows::core::w;
    use windows::Win32::Foundation::{HWND, LPARAM, WPARAM};
    use windows::Win32::UI::WindowsAndMessaging::{FindWindowW, PostMessageW, WM_USER};
    const WM_AGENT_SHOW: u32 = WM_USER + 302;
    for _ in 0..40 {
        let found = unsafe { FindWindowW(w!("AlienAIAgentStatusV2"), None) };
        if let Ok(hwnd) = found {
            if hwnd != HWND::default() {
                let _ = unsafe { PostMessageW(hwnd, WM_AGENT_SHOW, WPARAM(0), LPARAM(0)) };
                return;
            }
        }
        std::thread::sleep(std::time::Duration::from_millis(100));
    }
}

#[cfg(windows)]
fn run_ui_loop() -> anyhow::Result<()> {
    crate::agent_window_ui::run(&HWND_SLOT, UNPAIR_TX.get().cloned())
}

#[cfg(not(windows))]
fn run_ui_loop() -> anyhow::Result<()> {
    Ok(())
}
