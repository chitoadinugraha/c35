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

pub fn show_or_focus() {
    #[cfg(windows)]
    crate::agent_window_ui::show_or_focus(&HWND_SLOT);
}

#[cfg(windows)]
fn run_ui_loop() -> anyhow::Result<()> {
    crate::agent_window_ui::run(&HWND_SLOT, UNPAIR_TX.get().cloned())
}

#[cfg(not(windows))]
fn run_ui_loop() -> anyhow::Result<()> {
    Ok(())
}
