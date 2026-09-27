use std::sync::{Mutex, OnceLock};

pub fn show_or_focus(hwnd_slot: &OnceLock<Mutex<isize>>) {
    crate::agent_status_window::show_or_focus(hwnd_slot);
}

pub fn run(
    hwnd_slot: &OnceLock<Mutex<isize>>,
    unpair_tx: Option<tokio::sync::mpsc::UnboundedSender<crate::tray::TrayAction>>,
) -> anyhow::Result<()> {
    crate::agent_status_window::run(hwnd_slot, unpair_tx)
}
