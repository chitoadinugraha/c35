use c_remote_core::c35_proto::RemoteInputEvent;
use serde_json::json;
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

pub fn execute(event: &RemoteInputEvent) {
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
    let (x, y) = px(event);
    let payload = match event.event_type.as_str() {
        "mouse_move" => json!({ "type": "mouseMove", "x": x, "y": y }),
        "mouse_down" => json!({ "type": "mouseDown", "button": button(event), "x": x, "y": y }),
        "mouse_up" => json!({ "type": "mouseUp", "button": button(event), "x": x, "y": y }),
        "mouse_click" => json!({ "type": "mouseDown", "button": button(event), "x": x, "y": y }),
        "wheel" => json!({
            "type": "wheel",
            "x": x,
            "y": y,
            "deltaX": 0,
            "deltaY": event.delta_y
        }),
        "key_down" => json!({ "type": "keyDown", "key": event.text }),
        "key_up" => json!({ "type": "keyUp", "key": event.text }),
        "type_text" => json!({ "type": "text", "text": event.text }),
        other => {
            debug!(other, "unknown browser input event");
            return;
        }
    };
    tokio::spawn(async move {
        if let Err(e) = bridge.call("input", payload).await {
            debug!("browser input ipc: {e}");
        }
    });
}