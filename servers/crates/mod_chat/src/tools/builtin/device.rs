use crate::tool;
use c35_mod_device::{
    remote_device_command_run, remote_device_input_send, remote_device_screenshot_capture,
};
use serde_json::{json, Value};

fn device_fail_class(error: &str) -> (&'static str, bool) {
    let e = error.to_lowercase();
    if e.contains("forbidden") || e.contains("access denied") || e.contains("invalid device") {
        ("fatal_auth", false)
    } else if e.contains("offline")
        || e.contains("not connected")
        || e.contains("disconnected")
        || e.contains("unreachable")
    {
        ("fatal_offline", false)
    } else if e.contains("timeout") || e.contains("timed out") {
        ("transient", true)
    } else {
        ("fatal_env", false)
    }
}

fn device_fail(error: impl Into<String>) -> Value {
    let error = error.into();
    let (fail_class, retryable) = device_fail_class(&error);
    json!({
        "ok": false,
        "error": error,
        "fail_class": fail_class,
        "retryable": retryable,
    })
}

tool! {
    struct: DeviceCommandTool,
    name: "device.command",
    aliases: ["device_command", "run_command_on_device", "exec_device"],
    description: "Run a shell or PowerShell command on a user's paired remote device (e.g. Chito-PC). Prefer this for bulk or repetitive data work (export, join, transform, spreadsheet load); use device.input for one-off UI steps only. Returns command execution stdout, stderr, and exit code.",
    topics: ["computer_use"],
    always: ["computer_use"],
    ui_calling_key: "tool.device.command.calling",
    ui_done_key: "tool.device.command.done",
    parameters: {
        device_iid: (integer, "Target device identity ID", required),
        command: (string, "Shell or PowerShell command to execute", required),
        timeout_sec: (integer, "Execution timeout in seconds (default 15, max 60)", optional),
    },
    execute: |args, ctx| {
        let device_iid = args["device_iid"].as_i64().unwrap_or(0);
        let command = args["command"].as_str().unwrap_or_default().trim();
        let timeout_sec = args["timeout_sec"].as_i64().unwrap_or(15).clamp(1, 60) as u32;
        if device_iid <= 0 {
            return Ok(device_fail("device_iid is required"));
        }
        if command.is_empty() {
            return Ok(device_fail("command cannot be empty"));
        }

        match remote_device_command_run(
            &ctx.pool,
            ctx.nats.as_ref(),
            ctx.owner_iid,
            device_iid,
            command,
            timeout_sec,
        ).await {
            Ok(res) => {
                if !res.ok && !res.error.is_empty() {
                    return Ok(device_fail(format!("Failed to execute command: {}", res.error)));
                }
                Ok(json!({
                    "ok": true,
                    "status": if res.ok { "ok" } else { "failed" },
                    "device_iid": device_iid,
                    "command": command,
                    "exit_code": res.exit_code,
                    "stdout": res.stdout,
                    "stderr": res.stderr,
                }))
            }
            Err(e) => Ok(device_fail(format!("Failed to execute command on device: {e}"))),
        }
    }
}

tool! {
    struct: DeviceScreenshotTool,
    name: "device.screenshot",
    aliases: ["device_screenshot", "take_device_screenshot", "screenshot_device", "device_capture_screen"],
    description: "Capture a JPEG desktop screenshot from a user's paired remote device (e.g. Chito-PC). Returns visual observation of the desktop to inspect UI elements, locate coordinates, and verify actions. Can optionally draw a high-contrast red marker at (marker_x, marker_y) or generate Set-of-Mark (SoM) bounding boxes with UI automation tags.",
    topics: ["*"],
    always: ["device", "computer_use"],
    ui_calling_key: "tool.device.screenshot.calling",
    ui_done_key: "tool.device.screenshot.done",
    readonly: true,
    parameters: {
        device_iid: (integer, "Target device identity ID", required),
        max_width: (integer, "Maximum width in pixels (e.g. 1280 or 1920, default 1280)", optional),
        quality: (integer, "JPEG quality 1-100 (default 72)", optional),
        marker_x: (number, "Optional normalized X coordinate (0.0 to 1.0) to plot a visual red marker", optional),
        marker_y: (number, "Optional normalized Y coordinate (0.0 to 1.0) to plot a visual red marker", optional),
        som: (boolean, "Optional Set-of-Mark (SoM) visual tags and accessibility tree extraction. When true, labels interactive controls with numbered badges and returns exact coordinates.", optional),
    },
    execute: |args, ctx| {
        let device_iid = args["device_iid"].as_i64().unwrap_or(0);
        if device_iid <= 0 {
            return Ok(device_fail("device_iid is required"));
        }
        let max_width = args["max_width"].as_i64().unwrap_or(1280).clamp(320, 3840) as u32;
        let quality = args["quality"].as_i64().unwrap_or(72).clamp(20, 100) as u32;
        let som = args["som"].as_bool().unwrap_or(false);
        let marker = match (args.get("marker_x").and_then(|v| v.as_f64()), args.get("marker_y").and_then(|v| v.as_f64())) {
            (Some(mx), Some(my)) if mx >= 0.0 && my >= 0.0 => Some((mx, my)),
            _ => None,
        };

        match remote_device_screenshot_capture(
            &ctx.pool,
            ctx.nats.as_ref(),
            ctx.owner_iid,
            device_iid,
            max_width,
            quality,
            marker,
            som,
        ).await {
            Ok(res) => {
                if !res.ok {
                    return Ok(device_fail(format!("Failed to capture screenshot: {}", res.error)));
                }
                use base64::Engine;
                let b64 = base64::engine::general_purpose::STANDARD.encode(&res.jpeg_bytes);
                let mut out = json!({
                    "ok": true,
                    "status": "ok",
                    "device_iid": device_iid,
                    "width": res.width,
                    "height": res.height,
                    "image_base64": b64,
                    "mime_type": "image/jpeg",
                    "hint": format!("Captured {}x{} screenshot. Visual observation is attached.", res.width, res.height),
                });
                if !res.axtree_text.is_empty() {
                    out["axtree_text"] = json!(res.axtree_text);
                }
                Ok(out)
            }
            Err(e) => Ok(device_fail(format!("Failed to request screenshot from device: {e}"))),
        }
    }
}

tool! {
    struct: DeviceInputTool,
    name: "device.input",
    aliases: ["device_input", "device_computer_use"],
    description: "Send mouse or keyboard input (mouse_click, double_click, triple_click, right_click, middle_click, mouse_move, mouse_down, mouse_up, mouse_drag, wheel, key_down, key_up, type_text, shortcut) to a user's paired remote device. Coordinates (x, y) are normalized between 0.0 (top-left) and 1.0 (bottom-right) across the desktop/virtual screen. For shortcut, specify key combos in text (e.g. 'ctrl+c', 'alt+tab', 'win+r'). If screenshot_after=true, draws a red action marker showing where the action landed.",
    topics: ["computer_use"],
    always: ["computer_use"],
    ui_calling_key: "tool.device.input.calling",
    ui_done_key: "tool.device.input.done",
    parameters: {
        device_iid: (integer, "Target device identity ID", required),
        event_type: (string, "Input event type: 'mouse_click', 'double_click', 'triple_click', 'right_click', 'middle_click', 'mouse_move', 'mouse_down', 'mouse_up', 'mouse_drag', 'wheel', 'type_text', 'shortcut', 'key_down', 'key_up'", required),
        x: (number, "Normalized X coordinate (0.0 to 1.0, where 0.0 is left edge and 1.0 is right edge)", optional),
        y: (number, "Normalized Y coordinate (0.0 to 1.0, where 0.0 is top edge and 1.0 is bottom edge)", optional),
        text: (string, "Text string to type (for type_text) or key combo like 'ctrl+c', 'alt+tab', 'win+r' (for shortcut)", optional),
        key_code: (integer, "Virtual key code (e.g. 13 for Enter, 27 for Escape, 9 for Tab)", optional),
        button: (integer, "Mouse button (0: left, 1: middle, 2: right)", optional),
        delta_y: (integer, "Wheel scroll delta (positive = up, negative = down)", optional),
        screenshot_after: (boolean, "If true, captures and returns a new screenshot with a red target marker showing where the click landed to verify action", optional),
    },
    execute: |args, ctx| {
        let device_iid = args["device_iid"].as_i64().unwrap_or(0);
        if device_iid <= 0 {
            return Ok(device_fail("device_iid is required"));
        }
        let mut event_type = args["event_type"].as_str().unwrap_or_default().trim().to_lowercase();
        if event_type.is_empty() {
            return Ok(device_fail("event_type is required"));
        }
        if event_type == "click" { event_type = "mouse_click".into(); }
        if event_type == "doubleclick" { event_type = "double_click".into(); }
        if event_type == "tripleclick" { event_type = "triple_click".into(); }
        if event_type == "rightclick" { event_type = "right_click".into(); }
        if event_type == "drag" { event_type = "mouse_drag".into(); }
        if event_type == "hotkey" || event_type == "key_combo" { event_type = "shortcut".into(); }

        let x = args["x"].as_f64().unwrap_or(0.0);
        let y = args["y"].as_f64().unwrap_or(0.0);
        let text = args["text"].as_str().unwrap_or_default().to_string();
        let key_code = args["key_code"].as_i64().unwrap_or(0) as i32;
        let button = args["button"].as_i64().unwrap_or(0) as i32;
        let delta_y = args["delta_y"].as_i64().unwrap_or(0) as i32;
        let screenshot_after = args["screenshot_after"].as_bool().unwrap_or(false);

        let event = c35_proto::RemoteInputEvent {
            event_type: event_type.clone(),
            x,
            y,
            button,
            key_code,
            text,
            delta_y,
        };

        if let Err(e) = remote_device_input_send(
            &ctx.pool,
            ctx.nats.as_ref(),
            ctx.owner_iid,
            device_iid,
            event,
        ).await {
            return Ok(device_fail(format!("Failed to send input to device: {e}")));
        }

        let mut out = json!({ "ok": true, "status": "dispatched", "device_iid": device_iid, "event_type": event_type });

        if screenshot_after {
            tokio::time::sleep(std::time::Duration::from_millis(200)).await;
            let marker = if event_type.contains("click") || event_type.contains("move") || event_type.contains("drag") {
                Some((x, y))
            } else {
                None
            };
            if let Ok(res) = remote_device_screenshot_capture(
                &ctx.pool,
                ctx.nats.as_ref(),
                ctx.owner_iid,
                device_iid,
                1280,
                72,
                marker,
                false,
            ).await {
                if res.ok {
                    use base64::Engine;
                    let b64 = base64::engine::general_purpose::STANDARD.encode(&res.jpeg_bytes);
                    out["screenshot"] = json!({
                        "width": res.width,
                        "height": res.height,
                    });
                    out["image_base64"] = json!(b64);
                    out["mime_type"] = json!("image/jpeg");
                    out["hint"] = json!(format!("Follow-up screenshot captured ({}x{}). Observation is attached with red action marker.", res.width, res.height));
                }
            }
        }

        Ok(out)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn device_fail_class_maps_auth() {
        let (c, r) = device_fail_class("forbidden");
        assert_eq!(c, "fatal_auth");
        assert!(!r);
    }

    #[test]
    fn device_fail_class_maps_offline() {
        let (c, r) = device_fail_class("agent offline");
        assert_eq!(c, "fatal_offline");
        assert!(!r);
    }

    #[test]
    fn device_fail_class_maps_timeout() {
        let (c, r) = device_fail_class("screenshot capture timed out");
        assert_eq!(c, "transient");
        assert!(r);
    }
}
