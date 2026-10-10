use c_remote_core::c35_proto::RemoteInputEvent;

use crate::session_linux::{InputBackendPref, LinuxSessionKind, input_backend_choice, session_kind};

mod enigo_backend;
mod shared;

#[cfg(feature = "reis-libei")]
mod libei_backend;

pub fn execute_input(evt: &RemoteInputEvent) {
    if !crate::input_exec::is_control_allowed() {
        tracing::warn!("remote input event ignored: host remote control is disabled");
        return;
    }

    let pref = input_backend_choice();
    if pref == InputBackendPref::Libei
        || (pref == InputBackendPref::Auto && session_kind() == LinuxSessionKind::Wayland)
    {
        #[cfg(feature = "reis-libei")]
        {
            if libei_backend::try_execute(evt) {
                return;
            }
            if session_kind() == LinuxSessionKind::Wayland {
                tracing::warn!("libei input failed on Wayland; remote control may be unavailable");
                return;
            }
        }
        #[cfg(not(feature = "reis-libei"))]
        {
            if session_kind() == LinuxSessionKind::Wayland {
                tracing::warn!("libei support not compiled in; build with default features on Linux");
                return;
            }
        }
    }

    enigo_backend::execute_input(evt);
}
