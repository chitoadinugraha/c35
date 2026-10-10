//! Shared helpers for remote input backends (normalized coords, key maps).

use c_remote_core::c35_proto::RemoteInputEvent;

pub fn screen_size() -> (i32, i32) {
    if let Ok(monitors) = xcap::Monitor::all() {
        if let Some(m) = monitors.first() {
            return (m.width().max(1) as i32, m.height().max(1) as i32);
        }
    }
    (1920, 1080)
}

pub fn pixel_coords(evt: &RemoteInputEvent) -> (i32, i32) {
    let (w, h) = screen_size();
    let px = (evt.x.clamp(0.0, 1.0) * w as f64).round() as i32;
    let py = (evt.y.clamp(0.0, 1.0) * h as f64).round() as i32;
    (px, py)
}

/// Linux input-event-codes.h button codes (BTN_*).
pub fn evdev_button(btn: &str) -> u32 {
    match btn.to_ascii_lowercase().as_str() {
        "right" => 0x111,
        "middle" => 0x112,
        _ => 0x110,
    }
}

/// Map Windows virtual-key style codes from the app to Linux evdev key codes.
pub fn vk_to_evdev(code: i32) -> Option<u32> {
    if code <= 0 {
        return None;
    }
    match code {
        0x08 => Some(14), // KEY_BACKSPACE
        0x09 => Some(15), // KEY_TAB
        0x0D => Some(28), // KEY_ENTER
        0x1B => Some(1), // KEY_ESC
        0x20 => Some(57), // KEY_SPACE
        0x25 => Some(105), // KEY_LEFT
        0x26 => Some(103), // KEY_UP
        0x27 => Some(106), // KEY_RIGHT
        0x28 => Some(108), // KEY_DOWN
        0x2D => Some(110), // KEY_INSERT
        0x2E => Some(111), // KEY_DELETE
        _ => None,
    }
}

pub fn apply_staged_update() {
    if let Some(v) = c_remote_core::update::update_staged_version() {
        if let Err(e) = c_remote_core::update::update_apply(v) {
            tracing::warn!("update_apply failed: {e}");
        }
    } else {
        tracing::warn!("apply_update requested but no update is staged");
    }
}

#[cfg(target_os = "linux")]
pub fn monotonic_us() -> u64 {
    let mut ts = libc::timespec {
        tv_sec: 0,
        tv_nsec: 0,
    };
    // SAFETY: timespec is valid; CLOCK_MONOTONIC is always available on Linux.
    let rc = unsafe { libc::clock_gettime(libc::CLOCK_MONOTONIC, &mut ts) };
    if rc != 0 {
        return 0;
    }
    (ts.tv_sec as u64) * 1_000_000 + (ts.tv_nsec as u64) / 1_000
}
