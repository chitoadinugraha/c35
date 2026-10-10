use c_remote_core::c35_proto::RemoteInputEvent;
use enigo::{Axis, Button, Coordinate, Direction, Enigo, Key, Keyboard, Mouse, Settings};
use std::sync::Mutex;
use tracing::info;

static ENIGO: Mutex<Option<Enigo>> = Mutex::new(None);

fn with_enigo<F: FnOnce(&mut Enigo)>(f: F) {
    let mut guard = ENIGO.lock().unwrap_or_else(|e| e.into_inner());
    if guard.is_none() {
        *guard = Enigo::new(&Settings::default()).ok();
    }
    if let Some(enigo) = guard.as_mut() {
        f(enigo);
    }
}

fn screen_size() -> (i32, i32) {
    if let Ok(w) = crate::capture::desktop_width_cap() {
        return (w.max(1) as i32, 1080);
    }
    (1920, 1080)
}

fn mouse_button(btn: &str) -> Button {
    match btn.to_ascii_lowercase().as_str() {
        "right" => Button::Right,
        "middle" => Button::Middle,
        _ => Button::Left,
    }
}

fn key_from_code(code: i32) -> Option<Key> {
    if code <= 0 {
        return None;
    }
    match code {
        0x08 => Some(Key::Backspace),
        0x09 => Some(Key::Tab),
        0x0D => Some(Key::Return),
        0x1B => Some(Key::Escape),
        0x20 => Some(Key::Space),
        0x25 => Some(Key::LeftArrow),
        0x26 => Some(Key::UpArrow),
        0x27 => Some(Key::RightArrow),
        0x28 => Some(Key::DownArrow),
        0x2D => Some(Key::Insert),
        0x2E => Some(Key::Delete),
        _ => None,
    }
}

pub fn execute_input(evt: &RemoteInputEvent) {
    let (w, h) = screen_size();
    let px = (evt.x.clamp(0.0, 1.0) * w as f64).round() as i32;
    let py = (evt.y.clamp(0.0, 1.0) * h as f64).round() as i32;

    match evt.event_type.as_str() {
        "apply_update" => {
            if let Some(v) = c_remote_core::update::update_staged_version() {
                let _ = c_remote_core::update::update_apply(v);
            }
        }
        "mouse_move" => with_enigo(|e| e.move_mouse(px, py, Coordinate::Abs)),
        "mouse_down" => with_enigo(|e| {
            e.move_mouse(px, py, Coordinate::Abs);
            e.button(mouse_button(&evt.button), Direction::Press);
        }),
        "mouse_up" => with_enigo(|e| {
            e.move_mouse(px, py, Coordinate::Abs);
            e.button(mouse_button(&evt.button), Direction::Release);
        }),
        "mouse_click" | "double_click" | "triple_click" => {
            let clicks = match evt.event_type.as_str() {
                "double_click" => 2,
                "triple_click" => 3,
                _ => 1,
            };
            with_enigo(|e| {
                e.move_mouse(px, py, Coordinate::Abs);
                let btn = mouse_button(&evt.button);
                for _ in 0..clicks {
                    e.button(btn, Direction::Click);
                }
            });
        }
        "right_click" => with_enigo(|e| {
            e.move_mouse(px, py, Coordinate::Abs);
            e.button(Button::Right, Direction::Click);
        }),
        "middle_click" => with_enigo(|e| {
            e.move_mouse(px, py, Coordinate::Abs);
            e.button(Button::Middle, Direction::Click);
        }),
        "wheel" => with_enigo(|e| e.scroll(evt.delta_y, Axis::Vertical)),
        "key_down" => with_enigo(|e| {
            if let Some(key) = key_from_code(evt.key_code) {
                e.key(key, Direction::Press);
            } else if let Some(ch) = evt.text.chars().next() {
                e.key(Key::Unicode(ch), Direction::Press);
            }
        }),
        "key_up" => with_enigo(|e| {
            if let Some(key) = key_from_code(evt.key_code) {
                e.key(key, Direction::Release);
            } else if let Some(ch) = evt.text.chars().next() {
                e.key(Key::Unicode(ch), Direction::Release);
            }
        }),
        "type_text" => with_enigo(|e| e.text(&evt.text)),
        other => info!(event_type = other, "unhandled remote input event (enigo)"),
    }
}
