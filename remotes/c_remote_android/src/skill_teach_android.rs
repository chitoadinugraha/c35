//! Skill teach step recording from remote viewer input (Accessibility metadata).

use c_remote_core::c35_proto::RemoteInputEvent;

use crate::webrtc_bridge::latest_frame_size;
use crate::JAVA_VM;

pub fn register() {
    c_remote_core::skill_teach::register_platform(
        |_title| {},
        || {},
        |_ord, _label| {},
    );
}

pub fn observe_remote_input(evt: &RemoteInputEvent) {
    if !c_remote_core::skill_teach::teach_is_recording() {
        return;
    }
    let (window, control) = accessibility_target_hint();
    match evt.event_type.as_str() {
        "mouse_click" => {
            let px = norm_px(evt.x, 0);
            let py = norm_px(evt.y, 1);
            c_remote_core::skill_teach::teach_record_click(px, py, &window, &control);
        }
        "double_click" => {
            let px = norm_px(evt.x, 0);
            let py = norm_px(evt.y, 1);
            c_remote_core::skill_teach::teach_record_click_kind(
                "double_click",
                px,
                py,
                &window,
                &control,
            );
        }
        "right_click" => {
            let px = norm_px(evt.x, 0);
            let py = norm_px(evt.y, 1);
            c_remote_core::skill_teach::teach_record_click_kind(
                "right_click",
                px,
                py,
                &window,
                &control,
            );
        }
        "type_text" => {
            c_remote_core::skill_teach::teach_focus_field(&window, "", false);
            for c in evt.text.chars() {
                if c_remote_core::skill_teach::teach_key_event(0, &c.to_string()) {
                    return;
                }
            }
        }
        "key_down" => {
            if evt.key_code > 0 {
                let _ = c_remote_core::skill_teach::teach_key_event(evt.key_code as u32, "");
            }
        }
        _ => {}
    }
}

fn norm_px(norm: f64, axis: u32) -> i32 {
    let (w, h) = latest_frame_size();
    let dim = if axis == 0 { w } else { h }.max(1) as f64;
    (norm.clamp(0.0, 1.0) * dim).round() as i32
}

fn accessibility_target_hint() -> (String, String) {
    let vm = JAVA_VM.get();
    if vm.is_none() {
        return ("Android".into(), String::new());
    }
    let mut env = match vm.unwrap().attach_current_thread() {
        Ok(e) => e,
        Err(_) => return ("Android".into(), String::new()),
    };
    let json: String = match env.call_static_method(
        "id/alienai/remote/service/AccessControlService",
        "teachTargetHintJson",
        "()Ljava/lang/String;",
        &[],
    ) {
        Ok(v) => {
            let j = v.l().unwrap_or_default();
            if j.is_null() {
                "{}".to_string()
            } else {
                let js = jni::objects::JString::from(j);
                env.get_string(&js)
                    .map(|s| s.to_string_lossy().into_owned())
                    .unwrap_or_else(|_| "{}".to_string())
            }
        }
        Err(_) => "{}".to_string(),
    };
    if let Ok(v) = serde_json::from_str::<serde_json::Value>(&json) {
        let window = v
            .get("window")
            .and_then(|x| x.as_str())
            .unwrap_or("Android")
            .to_string();
        let control = v
            .get("control")
            .and_then(|x| x.as_str())
            .unwrap_or("")
            .to_string();
        return (window, control);
    }
    ("Android".into(), String::new())
}
