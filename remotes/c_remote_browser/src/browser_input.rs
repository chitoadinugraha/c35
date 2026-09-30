use std::sync::Mutex;
use std::time::Duration;

static EXTENSION_INPUT_LOCK: Mutex<()> = Mutex::new(());

use c_remote_core::c35_proto::RemoteInputEvent;
use serde_json::{json, Value};
use tracing::debug;

const VW: f64 = 1280.0;
const VH: f64 = 800.0;

fn px(evt: &RemoteInputEvent) -> (f64, f64) {
    (
        evt.x.clamp(0.0, 1.0) * VW,
        evt.y.clamp(0.0, 1.0) * VH,
    )
}

fn button(evt: &RemoteInputEvent) -> &'static str {
    match evt.button {
        2 => "right",
        1 => "middle",
        _ => "left",
    }
}

fn with_tab_id(mut params: Value, event: &RemoteInputEvent) -> Value {
    let tid = event.tab_id.trim();
    if !tid.is_empty() {
        if let Some(obj) = params.as_object_mut() {
            obj.insert("tab_id".into(), json!(tid));
        }
    }
    params
}

fn extension_params(event: &RemoteInputEvent) -> Option<Value> {
    let x = event.x.clamp(0.0, 1.0);
    let y = event.y.clamp(0.0, 1.0);
    match event.event_type.as_str() {
        "mouse_move" => Some(with_tab_id(
            json!({ "event_type": "mouse_move", "x": x, "y": y }),
            event,
        )),
        "mouse_down" => Some(with_tab_id(
            json!({
                "event_type": "mouse_down",
                "x": x,
                "y": y,
                "button": event.button
            }),
            event,
        )),
        "mouse_up" => Some(with_tab_id(
            json!({
                "event_type": "mouse_up",
                "x": x,
                "y": y,
                "button": event.button
            }),
            event,
        )),
        "mouse_click" | "right_click" | "middle_click" => {
            let button = if event.event_type == "right_click" {
                2
            } else if event.event_type == "middle_click" {
                1
            } else {
                event.button
            };
            Some(with_tab_id(
                json!({
                    "event_type": "mouse_click",
                    "x": x,
                    "y": y,
                    "button": button
                }),
                event,
            ))
        }
        "double_click" => Some(with_tab_id(
            json!({
                "event_type": "double_click",
                "x": x,
                "y": y,
                "button": event.button
            }),
            event,
        )),
        "wheel" => Some(with_tab_id(
            json!({
                "event_type": "wheel",
                "x": x,
                "y": y,
                "delta_y": event.delta_y
            }),
            event,
        )),
        "key_down" => Some(with_tab_id(
            json!({
                "event_type": "key_down",
                "text": event.text,
                "key_code": event.key_code
            }),
            event,
        )),
        "key_up" => Some(with_tab_id(
            json!({
                "event_type": "key_up",
                "text": event.text,
                "key_code": event.key_code
            }),
            event,
        )),
        "type_text" => Some(with_tab_id(
            json!({ "event_type": "type_text", "text": event.text }),
            event,
        )),
        "shortcut" | "hotkey" | "key_combo" => Some(with_tab_id(
            json!({
                "event_type": "shortcut",
                "text": event.text
            }),
            event,
        )),
        other => {
            debug!(other, "unknown browser input event");
            None
        }
    }
}

fn playwright_payload(event: &RemoteInputEvent) -> Option<Value> {
    let (x, y) = px(event);
    match event.event_type.as_str() {
        "mouse_move" => Some(json!({ "type": "mouseMove", "x": x, "y": y })),
        "mouse_down" => {
            Some(json!({ "type": "mouseDown", "button": button(event), "x": x, "y": y }))
        }
        "mouse_up" => Some(json!({ "type": "mouseUp", "button": button(event), "x": x, "y": y })),
        "mouse_click" => Some(json!({
            "type": "mouseClick",
            "button": button(event),
            "x": x,
            "y": y,
            "clickCount": 1
        })),
        "wheel" => Some(json!({
            "type": "wheel",
            "x": x,
            "y": y,
            "deltaX": 0,
            "deltaY": event.delta_y
        })),
        "key_down" => Some(json!({ "type": "keyDown", "key": event.text })),
        "key_up" => Some(json!({ "type": "keyUp", "key": event.text })),
        "type_text" => Some(json!({ "type": "text", "text": event.text })),
        other => {
            debug!(other, "unknown browser input event");
            None
        }
    }
}

pub fn execute(event: &RemoteInputEvent) {
    if crate::mode::is_extension_engine() {
        let bridge = crate::extension_ipc::extension_bridge_get();
        let Some(bridge) = bridge else {
            debug!("browser input ignored: no extension bridge");
            return;
        };
        let Some(params) = extension_params(event) else {
            return;
        };
        if let Some(st) = crate::browser_state::global() {
            st.record_extension_input(event);
        }
        let timeout = if event.event_type.contains("click") {
            Duration::from_millis(3000)
        } else if event.event_type == "type_text" {
            Duration::from_millis(8000)
        } else {
            Duration::from_millis(2500)
        };
        tokio::task::spawn_blocking(move || {
            let _guard = EXTENSION_INPUT_LOCK.lock().unwrap_or_else(|e| e.into_inner());
            if let Err(e) = bridge.call("input.inject", params, timeout) {
                debug!("browser input inject: {e}");
            }
        });
        return;
    }

    let st = crate::browser_state::global();
    let bridge = st.and_then(|s| {
        s.engine
            .lock()
            .ok()
            .and_then(|g| g.as_ref().map(|p| p.bridge.clone()))
    });
    let Some(bridge) = bridge else {
        debug!("browser input ignored: no engine");
        return;
    };
    let Some(payload) = playwright_payload(event) else {
        return;
    };
    tokio::spawn(async move {
        if let Err(e) = bridge.call("input", payload).await {
            debug!("browser input ipc: {e}");
        }
    });
}
