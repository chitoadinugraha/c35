use c_remote_core::c35_proto::RemoteInputEvent;

use crate::uia::{resolve_element_at, uia_foreground_title};

pub fn observe_remote_input(evt: &RemoteInputEvent) {
    if !c_remote_core::skill_teach::teach_is_recording() {
        return;
    }
    let screen_w = screen_w();
    let screen_h = screen_h();
    let px = (evt.x.clamp(0.0, 1.0) * screen_w as f64).round() as i32;
    let py = (evt.y.clamp(0.0, 1.0) * screen_h as f64).round() as i32;
    match evt.event_type.as_str() {
        "mouse_click" => {
            let (control, window) = resolve_element_at(px, py);
            c_remote_core::skill_teach::teach_record_click(px, py, &window, &control);
        }
        "double_click" => {
            let (control, window) = resolve_element_at(px, py);
            c_remote_core::skill_teach::teach_record_click_kind(
                "double_click",
                px,
                py,
                &window,
                &control,
            );
        }
        "right_click" => {
            let (control, window) = resolve_element_at(px, py);
            c_remote_core::skill_teach::teach_record_click_kind(
                "right_click",
                px,
                py,
                &window,
                &control,
            );
        }
        "type_text" => {
            let window = uia_foreground_title();
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

fn screen_w() -> i32 {
    use windows::Win32::UI::WindowsAndMessaging::{GetSystemMetrics, SM_CXSCREEN};
    unsafe { GetSystemMetrics(SM_CXSCREEN) }
}

fn screen_h() -> i32 {
    use windows::Win32::UI::WindowsAndMessaging::{GetSystemMetrics, SM_CYSCREEN};
    unsafe { GetSystemMetrics(SM_CYSCREEN) }
}
