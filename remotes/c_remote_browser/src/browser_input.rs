use std::time::Duration;

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

fn extension_params(event: &RemoteInputEvent) -> Option<Value> {
    let x = event.x.clamp(0.0, 1.0);
    let y = event.y.clamp(0.0, 1.0);
    match event.event_type.as_str() {
        "mouse_move" => Some(json!({ "event_type": "mouse_move", "x": x, "y": y })),
        "mouse_down" => Some(json!({
            "event_type": "mouse_down",
            "x": x,
            "y": y,
            "button": event.button
        })),
        "mouse_up" => Some(json!({
            "event_type": "mouse_up",
            "x": x,
            "y": y,
            "button": event.button
        })),
        "mouse_click" | "right_click" | "middle_click" => {
            let button = if event.event_type == "right_click" {
                2
            } else if event.event_type == "middle_click" {
                1
            } else {
                event.button
            };
            Some(json!({
                "event_type": "mouse_click",
                "x": x,
                "y": y,
                "button": button
            }))
        }
        "double_click" => Some(json!({
            "event_type": "double_click",
            "x": x,
            "y": y,
            "button": event.button
        })),
        "wheel" => Some(json!({
            "event_type": "wheel",
            "x": x,
            "y": y,
            "delta_y": event.delta_y
        })),
        "key_down" => Some(json!({
            "event_type": "key_down",
            "text": event.text,
            "key_code": event.key_code
        })),
        "key_up" => Some(json!({
            "event_type": "key_up",
            "text": event.text,
            "key_code": event.key_code
        })),
        "type_text" => Some(json!({ "event_type": "type_text", "text": event.text })),
        "shortcut" | "hotkey" | "key_combo" => Some(json!({
            "event_type": "shortcut",
            "text": event.text
        })),
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
        tokio::task::spawn_blocking(move || {
            if let Err(e) = bridge.call("input.inject", params, Duration::from_millis(750)) {
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
