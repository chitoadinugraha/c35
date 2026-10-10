use anyhow::Result;
use tracing::{error, warn};

use crate::session_linux::{
    CaptureBackendPref, LinuxSessionKind, capture_env_pref, session_kind,
};

mod portal_pipewire;
mod xcap;

pub fn capture_primary_bgra() -> Result<(u32, u32, Vec<u8>)> {
    let env = capture_env_pref();
    let kind = session_kind();

    let try_portal = match env {
        CaptureBackendPref::Portal => true,
        CaptureBackendPref::Xcap => false,
        CaptureBackendPref::Auto => true,
    };

    if try_portal {
        match portal_pipewire::capture_primary_bgra() {
            Ok(frame) => return Ok(frame),
            Err(portal_err) => {
                if env == CaptureBackendPref::Auto && kind != LinuxSessionKind::Wayland {
                    warn!(error = %portal_err, "portal capture failed; falling back to xcap");
                    return xcap::capture_primary_bgra();
                }
                if kind == LinuxSessionKind::Wayland {
                    error!(
                        error = %portal_err,
                        "Wayland screen capture requires xdg-desktop-portal ScreenCast (PipeWire): \
                         approve the Screen Share dialog and install xdg-desktop-portal-gtk or \
                         xdg-desktop-portal-kde plus pipewire"
                    );
                }
                return Err(portal_err);
            }
        }
    }

    xcap::capture_primary_bgra()
}

pub fn desktop_width_cap() -> u32 {
    let env = capture_env_pref();
    if env == CaptureBackendPref::Portal || env == CaptureBackendPref::Auto {
        let w = portal_pipewire::desktop_width_cap();
        if w > 0 {
            return w;
        }
    }
    xcap::desktop_width_cap()
}
