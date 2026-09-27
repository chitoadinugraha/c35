use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{OnceLock, RwLock};

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
    }
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