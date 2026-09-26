use std::sync::atomic::{AtomicBool, Ordering};
use c_remote_core::c35_proto::RemoteInputEvent;
use tracing::{info, warn};
use windows::Win32::UI::Input::KeyboardAndMouse::{
    SendInput, INPUT, INPUT_0, INPUT_KEYBOARD, INPUT_MOUSE, KEYBDINPUT, KEYEVENTF_EXTENDEDKEY,
    KEYEVENTF_KEYUP, KEYEVENTF_UNICODE, MAPVK_VK_TO_VSC, MapVirtualKeyW, MOUSEEVENTF_LEFTDOWN,
    MOUSEEVENTF_LEFTUP, MOUSEEVENTF_MIDDLEDOWN, MOUSEEVENTF_MIDDLEUP, MOUSEEVENTF_RIGHTDOWN,
    MOUSEEVENTF_RIGHTUP, MOUSEEVENTF_WHEEL, MOUSEINPUT, VIRTUAL_KEY,
};
use windows::Win32::UI::WindowsAndMessaging::{
    GetSystemMetrics, SetCursorPos, SM_CXSCREEN, SM_CYSCREEN,
};

static CONTROL_ALLOWED: AtomicBool = AtomicBool::new(true);

pub fn set_control_allowed(allowed: bool) {
    CONTROL_ALLOWED.store(allowed, Ordering::SeqCst);
    info!(allowed, "remote control permission updated");
}

pub fn is_control_allowed() -> bool {
    CONTROL_ALLOWED.load(Ordering::SeqCst)
}

pub fn execute_input(evt: &RemoteInputEvent) {
    if !is_control_allowed() {
        warn!("remote input event ignored: host remote control is disabled");
        return;
    }

    // Primary monitor bounds matching DXGI display 0 capture
    let screen_w = unsafe { GetSystemMetrics(SM_CXSCREEN) };
    let screen_h = unsafe { GetSystemMetrics(SM_CYSCREEN) };
    let (w, h) = if screen_w > 0 && screen_h > 0 {
        (screen_w, screen_h)
    } else {
        (1920, 1080)
    };
    let px = (evt.x.clamp(0.0, 1.0) * w as f64).round() as i32;
    let py = (evt.y.clamp(0.0, 1.0) * h as f64).round() as i32;

    match evt.event_type.as_str() {
        "apply_update" => {
            info!("Remote user triggered immediate agent update");
            if let Some(v) = c_remote_core::update::update_staged_version() {
                info!(version = v, "applying staged update per remote user command");
                if let Err(e) = c_remote_core::update::update_apply(v) {
                    warn!("update_apply failed: {e}");
                }
            } else {
                warn!("apply_update requested by remote user, but no update is staged");
            }
        }
        "mouse_move" => {
            unsafe {
                let _ = SetCursorPos(px, py);
            }
        }
        "mouse_down" => {
            unsafe {
                let _ = SetCursorPos(px, py);
            }
            send_mouse_event(mouse_down_flag(evt.button), 0);
        }
        "mouse_up" => {
            unsafe {
                let _ = SetCursorPos(px, py);
            }
            send_mouse_event(mouse_up_flag(evt.button), 0);
        }
        "mouse_click" => {
            unsafe {
                let _ = SetCursorPos(px, py);
            }
            send_mouse_event(mouse_down_flag(evt.button), 0);
            send_mouse_event(mouse_up_flag(evt.button), 0);
        }
        "double_click" => {
            unsafe {
                let _ = SetCursorPos(px, py);
            }
            let btn_down = mouse_down_flag(evt.button);
            let btn_up = mouse_up_flag(evt.button);
            send_mouse_event(btn_down, 0);
            send_mouse_event(btn_up, 0);
            std::thread::sleep(std::time::Duration::from_millis(50));
            send_mouse_event(btn_down, 0);
            send_mouse_event(btn_up, 0);
        }
        "triple_click" => {
            unsafe {
                let _ = SetCursorPos(px, py);
            }
            let btn_down = mouse_down_flag(evt.button);
            let btn_up = mouse_up_flag(evt.button);
            for i in 0..3 {
                if i > 0 {
                    std::thread::sleep(std::time::Duration::from_millis(50));
                }
                send_mouse_event(btn_down, 0);
                send_mouse_event(btn_up, 0);
            }
        }
        "right_click" => {
            unsafe {
                let _ = SetCursorPos(px, py);
            }
            send_mouse_event(MOUSEEVENTF_RIGHTDOWN, 0);
            send_mouse_event(MOUSEEVENTF_RIGHTUP, 0);
        }
        "middle_click" => {
            unsafe {
                let _ = SetCursorPos(px, py);
            }
            send_mouse_event(MOUSEEVENTF_MIDDLEDOWN, 0);
            send_mouse_event(MOUSEEVENTF_MIDDLEUP, 0);
        }
        "mouse_drag" => {
            let btn_down = mouse_down_flag(evt.button);
            let btn_up = mouse_up_flag(evt.button);
            send_mouse_event(btn_down, 0);
            std::thread::sleep(std::time::Duration::from_millis(20));
            unsafe {
                let _ = SetCursorPos(px, py);
            }
            std::thread::sleep(std::time::Duration::from_millis(40));
            send_mouse_event(btn_up, 0);
        }
        "wheel" => {
            send_mouse_event(MOUSEEVENTF_WHEEL, evt.delta_y * 120);
        }
        "key_down" => {
            let vk = if evt.key_code > 0 {
                evt.key_code as u16
            } else {
                vk_from_str(&evt.text).unwrap_or(0)
            };
            if vk > 0 {
                send_key_event(vk, false);
            }
        }
        "key_up" => {
            let vk = if evt.key_code > 0 {
                evt.key_code as u16
            } else {
                vk_from_str(&evt.text).unwrap_or(0)
            };
            if vk > 0 {
                send_key_event(vk, true);
            }
        }
        "shortcut" | "hotkey" | "key_combo" => {
            execute_shortcut(&evt.text);
        }
        "type_text" => {
            for c in evt.text.encode_utf16() {
                send_unicode_char(c);
            }
        }
        other => {
            info!(event_type = other, "unhandled remote input event");
        }
    }
    crate::screen_capture::mark_screen_dirty();
}

pub fn execute_shortcut(combo: &str) {
    let parts: Vec<&str> = combo.split(['+', '-']).collect();
    let mut vks = Vec::with_capacity(parts.len());
    for p in parts {
        let p_trimmed = p.trim();
        if !p_trimmed.is_empty() {
            if let Some(vk) = vk_from_str(p_trimmed) {
                vks.push(vk);
            } else {
                warn!("unknown shortcut token: {p_trimmed}");
            }
        }
    }
    if vks.is_empty() {
        return;
    }
    for &vk in &vks {
        send_key_event(vk, false);
        std::thread::sleep(std::time::Duration::from_millis(15));
    }
    std::thread::sleep(std::time::Duration::from_millis(30));
    for &vk in vks.iter().rev() {
        send_key_event(vk, true);
        std::thread::sleep(std::time::Duration::from_millis(15));
    }
}

pub fn vk_from_str(s: &str) -> Option<u16> {
    let lower = s.trim().to_lowercase();
    match lower.as_str() {
        "ctrl" | "control" => Some(0x11), // VK_CONTROL
        "alt" | "menu" => Some(0x12), // VK_MENU
        "shift" => Some(0x10), // VK_SHIFT
        "win" | "windows" | "super" | "meta" | "cmd" => Some(0x5B), // VK_LWIN
        "enter" | "return" => Some(0x0D), // VK_RETURN
        "esc" | "escape" => Some(0x1B), // VK_ESCAPE
        "tab" => Some(0x09), // VK_TAB
        "backspace" | "back" => Some(0x08), // VK_BACK
        "space" | "spacebar" => Some(0x20), // VK_SPACE
        "delete" | "del" => Some(0x2E), // VK_DELETE
        "insert" | "ins" => Some(0x2D), // VK_INSERT
        "home" => Some(0x24), // VK_HOME
        "end" => Some(0x23), // VK_END
        "pageup" | "pgup" => Some(0x21), // VK_PRIOR
        "pagedown" | "pgdn" => Some(0x22), // VK_NEXT
        "up" => Some(0x26), // VK_UP
        "down" => Some(0x28), // VK_DOWN
        "left" => Some(0x25), // VK_LEFT
        "right" => Some(0x27), // VK_RIGHT
        "capslock" => Some(0x14), // VK_CAPITAL
        "f1" => Some(0x70),
        "f2" => Some(0x71),
        "f3" => Some(0x72),
        "f4" => Some(0x73),
        "f5" => Some(0x74),
        "f6" => Some(0x75),
        "f7" => Some(0x76),
        "f8" => Some(0x77),
        "f9" => Some(0x78),
        "f10" => Some(0x79),
        "f11" => Some(0x7A),
        "f12" => Some(0x7B),
        other if other.len() == 1 => {
            let c = other.chars().next().unwrap();
            if c.is_ascii_alphabetic() {
                Some(c.to_ascii_uppercase() as u16)
            } else if c.is_ascii_digit() {
                Some(c as u16)
            } else {
                None
            }
        }
        _ => None,
    }
}

fn mouse_down_flag(button: i32) -> windows::Win32::UI::Input::KeyboardAndMouse::MOUSE_EVENT_FLAGS {
    match button {
        1 => MOUSEEVENTF_MIDDLEDOWN,
        2 => MOUSEEVENTF_RIGHTDOWN,
        _ => MOUSEEVENTF_LEFTDOWN,
    }
}

fn mouse_up_flag(button: i32) -> windows::Win32::UI::Input::KeyboardAndMouse::MOUSE_EVENT_FLAGS {
    match button {
        1 => MOUSEEVENTF_MIDDLEUP,
        2 => MOUSEEVENTF_RIGHTUP,
        _ => MOUSEEVENTF_LEFTUP,
    }
}

fn send_mouse_event(
    flags: windows::Win32::UI::Input::KeyboardAndMouse::MOUSE_EVENT_FLAGS,
    data: i32,
) {
    let input = INPUT {
        r#type: INPUT_MOUSE,
        Anonymous: INPUT_0 {
            mi: MOUSEINPUT {
                dx: 0,
                dy: 0,
                mouseData: data as u32,
                dwFlags: flags,
                time: 0,
                dwExtraInfo: 0,
            },
        },
    };
    unsafe {
        SendInput(&[input], std::mem::size_of::<INPUT>() as i32);
    }
}

fn send_key_event(vk: u16, key_up: bool) {
    let mut flags = if key_up {
        KEYEVENTF_KEYUP
    } else {
        windows::Win32::UI::Input::KeyboardAndMouse::KEYBD_EVENT_FLAGS(0)
    };
    // Extended keys: arrows, home, end, pgup, pgdn, ins, del, win keys, numpad divide, numlock
    if matches!(vk, 0x21..=0x28 | 0x2D | 0x2E | 0x5B | 0x5C | 0x5D | 0x6F | 0x90) {
        flags |= KEYEVENTF_EXTENDEDKEY;
    }
    let scan = unsafe { MapVirtualKeyW(vk as u32, MAPVK_VK_TO_VSC) as u16 };
    let input = INPUT {
        r#type: INPUT_KEYBOARD,
        Anonymous: INPUT_0 {
            ki: KEYBDINPUT {
                wVk: VIRTUAL_KEY(vk),
                wScan: scan,
                dwFlags: flags,
                time: 0,
                dwExtraInfo: 0,
            },
        },
    };
    unsafe {
        SendInput(&[input], std::mem::size_of::<INPUT>() as i32);
    }
}

fn send_unicode_char(ch: u16) {
    let down = INPUT {
        r#type: INPUT_KEYBOARD,
        Anonymous: INPUT_0 {
            ki: KEYBDINPUT {
                wVk: VIRTUAL_KEY(0),
                wScan: ch,
                dwFlags: KEYEVENTF_UNICODE,
                time: 0,
                dwExtraInfo: 0,
            },
        },
    };
    let up = INPUT {
        r#type: INPUT_KEYBOARD,
        Anonymous: INPUT_0 {
            ki: KEYBDINPUT {
                wVk: VIRTUAL_KEY(0),
                wScan: ch,
                dwFlags: KEYEVENTF_UNICODE | KEYEVENTF_KEYUP,
                time: 0,
                dwExtraInfo: 0,
            },
        },
    };
    unsafe {
        SendInput(&[down, up], std::mem::size_of::<INPUT>() as i32);
    }
}
