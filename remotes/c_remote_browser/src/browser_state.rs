use std::sync::{Arc, Mutex};

use serde_json::Value;

use super::engine::process::EngineProcess;

pub struct ScreencastFrame {
    pub width: u16,
    pub height: u16,
    pub jpeg: Vec<u8>,
}

pub struct BrowserState {
    pub engine: Mutex<Option<EngineProcess>>,
    pub frame: Mutex<Option<ScreencastFrame>>,
    pub extension_tabs: Mutex<Option<Value>>,
}

impl BrowserState {
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            engine: Mutex::new(None),
            frame: Mutex::new(None),
            extension_tabs: Mutex::new(None),
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