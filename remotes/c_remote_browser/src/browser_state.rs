use std::sync::{Arc, Mutex};

use c_remote_core::c35_proto::RemoteInputEvent;
use serde_json::Value;

use super::engine::process::EngineProcess;

#[derive(Clone, Default)]
pub struct ExtensionInputHint {
    pub tab_id: String,
    pub marker_x: f64,
    pub marker_y: f64,
    pub marker_set: bool,
}

pub struct ScreencastFrame {
    pub width: u16,
    pub height: u16,
    pub jpeg: Vec<u8>,
}

pub struct BrowserState {
    pub engine: Mutex<Option<EngineProcess>>,
    pub frame: Mutex<Option<ScreencastFrame>>,
    pub extension_tabs: Mutex<Option<Value>>,
    extension_hint: Mutex<ExtensionInputHint>,
}

impl BrowserState {
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            engine: Mutex::new(None),
            frame: Mutex::new(None),
            extension_tabs: Mutex::new(None),
            extension_hint: Mutex::new(ExtensionInputHint::default()),
        })
    }

    pub fn record_extension_input(&self, event: &RemoteInputEvent) {
        if let Ok(mut g) = self.extension_hint.lock() {
            let tid = event.tab_id.trim();
            if !tid.is_empty() {
                g.tab_id = tid.to_string();
            }
            let et = event.event_type.as_str();
            let pointer = et.contains("click")
                || et.contains("move")
                || et == "mouse_down"
                || et == "mouse_up"
                || et.contains("drag");
            if pointer {
                g.marker_x = event.x.clamp(0.0, 1.0);
                g.marker_y = event.y.clamp(0.0, 1.0);
                g.marker_set = true;
            }
        }
    }

    pub fn extension_hint_tab(&self) -> String {
        self.extension_hint
            .lock()
            .ok()
            .map(|g| g.tab_id.clone())
            .unwrap_or_default()
    }

    pub fn extension_hint_marker(&self) -> Option<(f64, f64)> {
        self.extension_hint
            .lock()
            .ok()
            .and_then(|g| {
                if g.marker_set {
                    Some((g.marker_x, g.marker_y))
                } else {
                    None
                }
            })
    }

    pub fn set_frame(&self, width: u16, height: u16, jpeg: Vec<u8>) {
        if let Ok(mut g) = self.frame.lock() {
            *g = Some(ScreencastFrame { width, height, jpeg });
        }
    }

    pub fn take_frame(&self) -> Option<ScreencastFrame> {
        self.frame.lock().ok().and_then(|mut g| g.take())
    }

    /// Latest JPEG screencast (clone) for H.264 RTP; does not consume the slot.
    pub fn latest_frame(&self) -> Option<ScreencastFrame> {
        self.frame.lock().ok().and_then(|g| {
            g.as_ref().map(|f| ScreencastFrame {
                width: f.width,
                height: f.height,
                jpeg: f.jpeg.clone(),
            })
        })
    }
}

static STATE: Mutex<Option<Arc<BrowserState>>> = Mutex::new(None);

pub fn init(state: Arc<BrowserState>) {
    if let Ok(mut g) = STATE.lock() {
        *g = Some(state);
    }
}

pub fn global() -> Option<Arc<BrowserState>> {
    STATE.lock().ok().and_then(|g| g.clone())
}