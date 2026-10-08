use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{LazyLock, OnceLock, RwLock};

use c35_proto::RemoteConnectionMode;

/// Optional platform hooks (e.g. Windows tray reads capture / control / autostart).
pub struct AgentUiBoolProviders {
    pub capture_active: Option<fn() -> bool>,
    pub control_allowed: Option<fn() -> bool>,
    pub autostart_enabled: Option<fn() -> bool>,
}

static BOOL_PROVIDERS: OnceLock<AgentUiBoolProviders> = OnceLock::new();

pub fn bool_providers_set(providers: AgentUiBoolProviders) {
    let _ = BOOL_PROVIDERS.set(providers);
}

fn call_bool(slot: Option<fn() -> bool>) -> bool {
    slot.map(|f| f()).unwrap_or(false)
}

static WS_CONNECTED: AtomicBool = AtomicBool::new(false);
static WEBRTC_CONNECTING: AtomicBool = AtomicBool::new(false);

static UPDATE_CHECK_MSG: RwLock<String> = RwLock::new(String::new());
static OWNER_LABEL: RwLock<String> = RwLock::new(String::new());
static DEVICE_NAME: RwLock<String> = RwLock::new(String::new());
static PERSONAL_PACKAGE: RwLock<String> = RwLock::new(String::new());
static DEVICE_PACKAGE: RwLock<String> = RwLock::new(String::new());
static DRIVE_ENABLED: AtomicBool = AtomicBool::new(true);
static DRIVE_STORAGE_USED: RwLock<Option<i64>> = RwLock::new(None);
static DRIVE_STORAGE_LIMIT: RwLock<Option<i64>> = RwLock::new(None);
static USER_APP_SESSIONS: LazyLock<RwLock<HashMap<String, RemoteConnectionMode>>> =
    LazyLock::new(|| RwLock::new(HashMap::new()));

#[derive(Debug, Clone)]
pub struct AgentUiSnapshot {
    pub ws_connected: bool,
    pub webrtc_sessions: usize,
    pub webrtc_connecting: bool,
    pub capture_active: bool,
    pub control_allowed: bool,
    pub autostart_enabled: bool,
    pub update_staged_version: Option<i64>,
    pub last_update_check_msg: String,
    pub owner_label: String,
    pub device_name: String,
    pub personal_package_name: String,
    pub device_package_name: String,
    pub drive_enabled: bool,
    pub drive_storage_used_bytes: Option<i64>,
    pub drive_storage_limit_bytes: Option<i64>,
    pub user_app_lines: Vec<String>,
}

pub fn snapshot() -> AgentUiSnapshot {
    let providers = BOOL_PROVIDERS.get();
    let capture_active = providers.map(|p| call_bool(p.capture_active)).unwrap_or(false);
    let control_allowed = providers.map(|p| call_bool(p.control_allowed)).unwrap_or(false);
    let autostart_enabled = providers.map(|p| call_bool(p.autostart_enabled)).unwrap_or(false);

    AgentUiSnapshot {
        ws_connected: ws_connected(),
        webrtc_sessions: crate::update::active_sessions(),
        webrtc_connecting: webrtc_connecting(),
        capture_active,
        control_allowed,
        autostart_enabled,
        update_staged_version: crate::update::update_staged_version(),
        last_update_check_msg: last_update_check_msg(),
        owner_label: owner_label(),
        device_name: device_name(),
        personal_package_name: personal_package_name(),
        device_package_name: device_package_name(),
        drive_enabled: drive_enabled(),
        drive_storage_used_bytes: drive_storage_used_bytes(),
        drive_storage_limit_bytes: drive_storage_limit_bytes(),
        user_app_lines: user_app_lines(),
    }
}

pub fn user_app_session_set(session_id: &str, mode: RemoteConnectionMode) {
    let sid = session_id.trim();
    if sid.is_empty() {
        return;
    }
    if let Ok(mut g) = USER_APP_SESSIONS.write() {
        g.insert(sid.to_string(), mode);
    }
}

pub fn user_app_session_clear(session_id: &str) {
    let sid = session_id.trim();
    if sid.is_empty() {
        return;
    }
    if let Ok(mut g) = USER_APP_SESSIONS.write() {
        g.remove(sid);
    }
}

fn mode_line(mode: RemoteConnectionMode) -> &'static str {
    match mode {
        RemoteConnectionMode::Relay => "Proxied",
        RemoteConnectionMode::Direct => "Direct Connection",
        RemoteConnectionMode::Unspecified => "Direct Connection",
    }
}

pub fn user_app_lines() -> Vec<String> {
    USER_APP_SESSIONS
        .read()
        .map(|g| g.values().map(|m| mode_line(*m).to_string()).collect())
        .unwrap_or_default()
}

pub fn user_app_connected_count() -> usize {
    USER_APP_SESSIONS.read().map(|g| g.len()).unwrap_or(0)
}

/// Subtitle for the User App status card (one line; multiple sessions joined with ·).
pub fn user_app_subtitle(connecting: bool) -> String {
    let lines = user_app_lines();
    if lines.is_empty() {
        return if connecting {
            "Connecting…".to_string()
        } else {
            "Not Connected".to_string()
        };
    }
    lines.join(" · ")
}

pub fn ws_connected_set(connected: bool) {
    WS_CONNECTED.store(connected, Ordering::SeqCst);
}

pub fn ws_connected() -> bool {
    WS_CONNECTED.load(Ordering::SeqCst)
}

pub fn webrtc_connecting_set(connecting: bool) {
    WEBRTC_CONNECTING.store(connecting, Ordering::SeqCst);
}

pub fn webrtc_connecting() -> bool {
    WEBRTC_CONNECTING.load(Ordering::SeqCst)
}

pub fn last_update_check_msg_set(msg: impl Into<String>) {
    if let Ok(mut g) = UPDATE_CHECK_MSG.write() {
        *g = msg.into();
    }
}

pub fn last_update_check_msg() -> String {
    UPDATE_CHECK_MSG
        .read()
        .map(|g| g.clone())
        .unwrap_or_default()
}

pub fn owner_label_set(label: impl Into<String>) {
    if let Ok(mut g) = OWNER_LABEL.write() {
        *g = label.into();
    }
}

pub fn owner_label() -> String {
    OWNER_LABEL.read().map(|g| g.clone()).unwrap_or_default()
}

pub fn device_name_set(name: impl Into<String>) {
    if let Ok(mut g) = DEVICE_NAME.write() {
        *g = name.into();
    }
}

pub fn device_name() -> String {
    DEVICE_NAME.read().map(|g| g.clone()).unwrap_or_default()
}

pub fn package_labels_set(personal: impl Into<String>, device: impl Into<String>) {
    if let Ok(mut g) = PERSONAL_PACKAGE.write() {
        *g = personal.into();
    }
    if let Ok(mut g) = DEVICE_PACKAGE.write() {
        *g = device.into();
    }
}

pub fn personal_package_name() -> String {
    PERSONAL_PACKAGE.read().map(|g| g.clone()).unwrap_or_default()
}

pub fn device_package_name() -> String {
    DEVICE_PACKAGE.read().map(|g| g.clone()).unwrap_or_default()
}

pub fn drive_enabled_set(enabled: bool) {
    DRIVE_ENABLED.store(enabled, Ordering::SeqCst);
}

pub fn drive_enabled() -> bool {
    DRIVE_ENABLED.load(Ordering::SeqCst)
}

pub fn drive_storage_set(used_bytes: i64, limit_bytes: Option<i64>) {
    if let Ok(mut g) = DRIVE_STORAGE_USED.write() {
        *g = Some(used_bytes.max(0));
    }
    if let Ok(mut g) = DRIVE_STORAGE_LIMIT.write() {
        *g = limit_bytes.filter(|n| *n >= 0);
    }
}

pub fn drive_storage_used_bytes() -> Option<i64> {
    DRIVE_STORAGE_USED.read().ok().and_then(|g| *g)
}

pub fn drive_storage_limit_bytes() -> Option<i64> {
    DRIVE_STORAGE_LIMIT.read().ok().and_then(|g| *g)
}

/// Human-readable `used / limit` in one unit (scale follows limit), with digit grouping.
pub fn drive_storage_label() -> Option<String> {
    let used = drive_storage_used_bytes()?;
    let limit = drive_storage_limit_bytes()?;
    Some(format_storage_pair_compact(used, limit))
}

/// Fraction in `[0, 1]` for progress UI; `None` when limit is missing or zero.
pub fn drive_storage_usage_fraction() -> Option<f64> {
    let used = drive_storage_used_bytes()?;
    let limit = drive_storage_limit_bytes()?;
    if limit <= 0 {
        return None;
    }
    Some((used as f64 / limit as f64).clamp(0.0, 1.0))
}

/// Agent status row: one unit at the end (e.g. `0 / 15 GB`).
fn format_storage_pair_compact(used: i64, limit: i64) -> String {
    let scale = storage_unit_index(limit.max(0));
    const UNITS: [&str; 5] = ["B", "KB", "MB", "GB", "TB"];
    let unit = UNITS[scale.min(4) as usize];
    if scale == 0 {
        return format!(
            "{} / {} {}",
            format_integer_grouped(used.max(0)),
            format_integer_grouped(limit.max(0)),
            unit
        );
    }
    let divisor = 1024u64.pow(scale) as f64;
    format!(
        "{} / {} {}",
        format_storage_amount(used.max(0) as f64 / divisor),
        format_storage_amount(limit.max(0) as f64 / divisor),
        unit
    )
}

fn format_storage_amount(value: f64) -> String {
    let rounded = value.round();
    if (value - rounded).abs() < 0.05 {
        format!("{}", rounded as i64)
    } else {
        format!("{value:.1}")
    }
}

fn storage_unit_index(limit_bytes: i64) -> u32 {
    let mut idx = 0u32;
    let mut n = limit_bytes.max(0) as f64;
    while n >= 1024.0 && idx < 4 {
        n /= 1024.0;
        idx += 1;
    }
    idx
}

fn format_integer_grouped(n: i64) -> String {
    let s = n.abs().to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 {
            out.push(',');
        }
        out.push(ch);
    }
    if n < 0 {
        format!("-{out}")
    } else {
        out
    }
}

#[cfg(test)]
mod drive_storage_format_tests {
    use super::*;

    #[test]
    fn pair_uses_limit_unit() {
        let limit = 15 * 1024 * 1024 * 1024;
        let label = format_storage_pair_compact(26_241, limit);
        assert!(label.contains("GB"));
        assert!(label.contains("/"));
        assert!(!label.contains("GiB"));
        assert!(!label.contains(" B /"));
    }

    #[test]
    fn compact_pair_one_unit_gb() {
        let limit = 15 * 1024 * 1024 * 1024;
        let label = format_storage_pair_compact(26_241, limit);
        assert_eq!(label, "0 / 15 GB");
    }

    #[test]
    fn grouping_on_bytes() {
        let s = format_storage_pair_compact(1_234, 900);
        assert_eq!(s, "1,234 / 900 B");
    }
}
