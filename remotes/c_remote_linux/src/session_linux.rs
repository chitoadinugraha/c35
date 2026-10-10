//! Linux session detection and backend selection (Wayland portal vs X11 xcap).

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LinuxSessionKind {
    Wayland,
    X11,
    Unknown,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CaptureBackendPref {
    Auto,
    Portal,
    Xcap,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InputBackendPref {
    Auto,
    Libei,
    Enigo,
}

pub fn session_kind() -> LinuxSessionKind {
    #[cfg(target_os = "linux")]
    {
        match std::env::var("XDG_SESSION_TYPE")
            .unwrap_or_default()
            .to_ascii_lowercase()
            .as_str()
        {
            "wayland" => LinuxSessionKind::Wayland,
            "x11" => LinuxSessionKind::X11,
            _ => {
                if std::env::var_os("WAYLAND_DISPLAY").is_some() {
                    LinuxSessionKind::Wayland
                } else if std::env::var_os("DISPLAY").is_some() {
                    LinuxSessionKind::X11
                } else {
                    LinuxSessionKind::Unknown
                }
            }
        }
    }
    #[cfg(not(target_os = "linux"))]
    {
        LinuxSessionKind::Unknown
    }
}

pub fn capture_env_pref() -> CaptureBackendPref {
    match std::env::var("C35_LINUX_CAPTURE")
        .unwrap_or_default()
        .to_ascii_lowercase()
        .as_str()
    {
        "portal" => CaptureBackendPref::Portal,
        "xcap" => CaptureBackendPref::Xcap,
        _ => CaptureBackendPref::Auto,
    }
}

fn parse_input_pref() -> InputBackendPref {
    match std::env::var("C35_LINUX_INPUT")
        .unwrap_or_default()
        .to_ascii_lowercase()
        .as_str()
    {
        "libei" => InputBackendPref::Libei,
        "enigo" => InputBackendPref::Enigo,
        _ => InputBackendPref::Auto,
    }
}

/// Preferred capture backend for this process.
pub fn capture_backend_choice() -> CaptureBackendPref {
    let pref = capture_env_pref();
    if pref != CaptureBackendPref::Auto {
        return pref;
    }
    match session_kind() {
        LinuxSessionKind::Wayland => CaptureBackendPref::Portal,
        LinuxSessionKind::X11 => CaptureBackendPref::Xcap,
        LinuxSessionKind::Unknown => CaptureBackendPref::Xcap,
    }
}

/// Preferred input backend for this process.
pub fn input_backend_choice() -> InputBackendPref {
    let pref = parse_input_pref();
    if pref != InputBackendPref::Auto {
        return pref;
    }
    match session_kind() {
        LinuxSessionKind::Wayland => InputBackendPref::Libei,
        LinuxSessionKind::X11 => InputBackendPref::Enigo,
        LinuxSessionKind::Unknown => InputBackendPref::Enigo,
    }
}

pub fn log_session_startup() {
    let kind = session_kind();
    let cap = capture_backend_choice();
    let inp = input_backend_choice();
    tracing::info!(
        session = ?kind,
        capture_env = ?capture_env_pref(),
        capture_backend = ?cap,
        input_backend = ?inp,
        "linux session backends"
    );
}
