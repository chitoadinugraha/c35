use std::sync::atomic::{AtomicBool, Ordering};

use c_remote_core::c35_proto::RemoteInputEvent;
use tracing::{info, warn};

static CONTROL_ALLOWED: AtomicBool = AtomicBool::new(true);

pub fn set_control_allowed(allowed: bool) {
    CONTROL_ALLOWED.store(allowed, Ordering::SeqCst);
    info!(allowed, "remote control permission updated");
}

pub fn is_control_allowed() -> bool {
    CONTROL_ALLOWED.load(Ordering::SeqCst)
}

#[cfg(not(target_os = "linux"))]
pub fn execute_input(evt: &RemoteInputEvent) {
    warn!(
        event_type = evt.event_type.as_str(),
        "remote input not implemented on this build target (Linux agent only)"
    );
}

#[cfg(target_os = "linux")]
pub fn execute_input(evt: &RemoteInputEvent) {
    crate::input::execute_input(evt);
}
