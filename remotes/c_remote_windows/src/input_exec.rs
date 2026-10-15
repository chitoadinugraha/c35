use std::sync::atomic::{AtomicBool, Ordering};
use c_remote_core::c35_proto::RemoteInputEvent;
use tracing::{info, warn};
use windows::Win32::UI::Input::KeyboardAndMouse::{
    SendInput, INPUT, INPUT_0, INPUT_KEYBOARD, INPUT_MOUSE, KEYBDINPUT, KEYEVENTF_EXTENDEDKEY,
    KEYEVENTF_KEYUP, KEYEVENTF_UNICODE, MAPVK_VK_TO_VSC, MapVirtualKeyW, MOUSEEVENTF_ABSOLUTE,
    MOUSEEVENTF_LEFTDOWN, MOUSEEVENTF_LEFTUP, MOUSEEVENTF_MIDDLEDOWN, MOUSEEVENTF_MIDDLEUP,
    MOUSEEVENTF_MOVE, MOUSEEVENTF_RIGHTDOWN, MOUSEEVENTF_RIGHTUP, MOUSEEVENTF_VIRTUALDESK,
    MOUSEEVENTF_WHEEL, MOUSEINPUT, VIRTUAL_KEY,
};
use windows::Win32::UI::WindowsAndMessaging::{
    GetCursorPos, GetSystemMetrics, SetCursorPos, SM_CXSCREEN, SM_CYSCREEN,
};

static CONTROL_ALLOWED: AtomicBool = AtomicBool::new(true);

pub fn set_control_allowed(allowed: bool) {
    CONTROL_ALLOWED.store(allowed, Ordering::SeqCst);
    info!(allowed, "remote control permission updated");
}

pub fn is_control_allowed() -> bool {
    CONTROL_ALLOWED.load(Ordering::SeqCst)
}

#[cfg(windows)]
struct TeachHookSkipGuard;

#[cfg(windows)]
impl Drop for TeachHookSkipGuard {
    fn drop(&mut self) {
        c_remote_core::skill_teach::teach_skip_hooks(false);
    }
}

pub fn execute_input(evt: &RemoteInputEvent) {
    if !is_control_allowed() {
        warn!("remote input event ignored: host remote control is disabled");
        return;
    }

    #[cfg(windows)]
    let _teach_hook_guard = {
        c_remote_core::skill_teach::teach_skip_hooks(true);
        TeachHookSkipGuard
    };

    #[cfg(windows)]
    crate::skill_teach_remote::observe_remote_input(evt);

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
            sync_remote_pointer(px, py);
        }
        "mouse_down" => {
            sync_remote_pointer(px, py);
            send_mouse_event(mouse_down_flag(evt.button), 0);
        }
        "mouse_up" => {
            sync_remote_pointer(px, py);
            send_mouse_event(mouse_up_flag(evt.button), 0);
        }
        "mouse_click" => {
            sync_remote_pointer(px, py);
            nudge_pointer_hit_test(px, py, w, h);
            std::thread::sleep(std::time::Duration::from_millis(30));
            send_mouse_event(mouse_down_flag(evt.button), 0);
            std::thread::sleep(std::time::Duration::from_millis(60));
            send_mouse_event(mouse_up_flag(evt.button), 0);
        }
        "double_click" => {
            static LAST_DOUBLE_CLICK_MS: std::sync::atomic::AtomicU64 =
                std::sync::atomic::AtomicU64::new(0);
            let now = std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_millis() as u64;
            let last = LAST_DOUBLE_CLICK_MS.load(Ordering::Relaxed);
            if now.saturating_sub(last) < 200 {
                return;
            }
            LAST_DOUBLE_CLICK_MS.store(now, Ordering::Relaxed);

            sync_remote_pointer(px, py);
            nudge_pointer_hit_test(px, py, w, h);
            std::thread::sleep(std::time::Duration::from_millis(30));
            let btn_down = mouse_down_flag(evt.button);
            let btn_up = mouse_up_flag(evt.button);
            send_mouse_event(btn_down, 0);
            std::thread::sleep(std::time::Duration::from_millis(60));
            send_mouse_event(btn_up, 0);
            std::thread::sleep(std::time::Duration::from_millis(50));
            send_mouse_event(btn_down, 0);
            std::thread::sleep(std::time::Duration::from_millis(60));
            send_mouse_event(btn_up, 0);
        }
        "triple_click" => {
            sync_remote_pointer(px, py);
            nudge_pointer_hit_test(px, py, w, h);
            std::thread::sleep(std::time::Duration::from_millis(30));
            let btn_down = mouse_down_flag(evt.button);
            let btn_up = mouse_up_flag(evt.button);
            for i in 0..3 {
                if i > 0 {
                    std::thread::sleep(std::time::Duration::from_millis(50));
                }
                send_mouse_event(btn_down, 0);
                std::thread::sleep(std::time::Duration::from_millis(60));
                send_mouse_event(btn_up, 0);
            }
        }
        "right_click" => {
            sync_remote_pointer(px, py);
            nudge_pointer_hit_test(px, py, w, h);
            std::thread::sleep(std::time::Duration::from_millis(30));
            send_mouse_event(MOUSEEVENTF_RIGHTDOWN, 0);
            std::thread::sleep(std::time::Duration::from_millis(60));
            send_mouse_event(MOUSEEVENTF_RIGHTUP, 0);
        }
        "middle_click" => {
            sync_remote_pointer(px, py);
            nudge_pointer_hit_test(px, py, w, h);
            std::thread::sleep(std::time::Duration::from_millis(30));
            send_mouse_event(MOUSEEVENTF_MIDDLEDOWN, 0);
            std::thread::sleep(std::time::Duration::from_millis(60));
            send_mouse_event(MOUSEEVENTF_MIDDLEUP, 0);
        }
        "click_and_type" => {
            sync_remote_pointer(px, py);
            nudge_pointer_hit_test(px, py, w, h);
            std::thread::sleep(std::time::Duration::from_millis(30));
            let btn_down = mouse_down_flag(evt.button);
            let btn_up = mouse_up_flag(evt.button);
            send_mouse_event(btn_down, 0);
            std::thread::sleep(std::time::Duration::from_millis(60));
            send_mouse_event(btn_up, 0);
            std::thread::sleep(std::time::Duration::from_millis(50));
            if !evt.text.is_empty() {
                execute_shortcut("ctrl+a");
                std::thread::sleep(std::time::Duration::from_millis(20));
                send_key_event(0x08, false);
                std::thread::sleep(std::time::Duration::from_millis(15));
                send_key_event(0x08, true);
                std::thread::sleep(std::time::Duration::from_millis(30));
                for c in evt.text.encode_utf16() {
                    send_unicode_char(c);
                }
            }
        }
        "mouse_drag" => {
            let (start_px, start_py) = if let Some((sx, sy)) = parse_start_coords(&evt.text, w, h) {
                (sx, sy)
            } else {
                let mut cur = windows::Win32::Foundation::POINT::default();
                if unsafe { GetCursorPos(&mut cur) }.is_ok() {
                    (cur.x, cur.y)
                } else {
                    (px, py)
                }
            };
            execute_smooth_drag(start_px, start_py, px, py, evt.button, w, h);
        }
        "mouse_stroke" | "stroke" | "draw" => {
            let mut pts = parse_stroke_points(&evt.text, w, h);
            if pts.is_empty() {
                pts.push((px, py));
            }
            execute_stroke(&pts, evt.button, w, h);
        }
        "wheel" => {
            sync_remote_pointer(px, py);
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
        "clear_text" => {
            execute_shortcut("ctrl+a");
            std::thread::sleep(std::time::Duration::from_millis(20));
            send_key_event(0x08, false);
            std::thread::sleep(std::time::Duration::from_millis(15));
            send_key_event(0x08, true);
        }
        "clipboard_set_text" => {
            #[cfg(windows)]
            {
                if !evt.text.is_empty() {
                    unsafe {
                        let _ = set_clipboard_text(&evt.text);
                    }
                }
            }
        }
        "clipboard_paste" => {
            #[cfg(windows)]
            {
                if !evt.text.is_empty() {
                    unsafe {
                        if set_clipboard_text(&evt.text) {
                            std::thread::sleep(std::time::Duration::from_millis(30));
                        }
                    }
                }
                trigger_paste();
            }
        }
        "clipboard_files" => {
            #[cfg(windows)]
            {
                let paths: Vec<std::path::PathBuf> = evt
                    .text
                    .lines()
                    .map(|l| l.trim())
                    .filter(|l| !l.is_empty())
                    .filter_map(|l| c_remote_core::webrtc::fs::path_resolve(l).ok())
                    .collect();
                if !paths.is_empty() {
                    unsafe {
                        if set_clipboard_files(&paths) {
                            std::thread::sleep(std::time::Duration::from_millis(30));
                            trigger_paste();
                        }
                    }
                }
            }
        }
        "clipboard_image" | "set_clipboard_image" => {
            #[cfg(windows)]
            {
                if !evt.text.is_empty() {
                    unsafe {
                        let _ = set_clipboard_image(&evt.text);
                    }
                }
            }
        }
        "clipboard_paste_image" | "paste_image" => {
            #[cfg(windows)]
            {
                if !evt.text.is_empty() {
                    unsafe {
                        if set_clipboard_image(&evt.text) {
                            std::thread::sleep(std::time::Duration::from_millis(30));
                        }
                    }
                }
                trigger_paste();
            }
        }
        other => {
            info!(event_type = other, "unhandled remote input event");
        }
    }
static LAST_PROBE_MS: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);

fn should_probe_cursor(evt_type: &str) -> bool {
    if evt_type != "mouse_move" {
        return true;
    }
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as u64;
    let last = LAST_PROBE_MS.load(std::sync::atomic::Ordering::Relaxed);
    if now.saturating_sub(last) >= 100 {
        LAST_PROBE_MS.store(now, std::sync::atomic::Ordering::Relaxed);
        true
    } else {
        false
    }
}

    if should_probe_cursor(&evt.event_type)
        && matches!(
            evt.event_type.as_str(),
            "mouse_move"
                | "mouse_down"
                | "mouse_up"
                | "mouse_click"
                | "double_click"
                | "triple_click"
                | "right_click"
                | "middle_click"
                | "click_and_type"
                | "wheel"
                | "mouse_drag"
                | "mouse_stroke"
                | "stroke"
                | "draw"
        )
    {
        if matches!(evt.event_type.as_str(), "mouse_move" | "wheel") {
            nudge_pointer_hit_test(px, py, w, h);
        }
        c_remote_core::webrtc::input_cursor_publish(crate::cursor_shape::probe());
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

fn sync_remote_pointer(px: i32, py: i32) {
    unsafe {
        let _ = SetCursorPos(px, py);
    }
}

/// Absolute move nudge so Windows hit-tests HWND under the remote pointer (I-beam, etc.).
fn nudge_pointer_hit_test(px: i32, py: i32, screen_w: i32, screen_h: i32) {
    if screen_w <= 1 || screen_h <= 1 {
        return;
    }
    let dx = (px as i64 * 65535 / (screen_w as i64 - 1)) as i32;
    let dy = (py as i64 * 65535 / (screen_h as i64 - 1)) as i32;
    let input = INPUT {
        r#type: INPUT_MOUSE,
        Anonymous: INPUT_0 {
            mi: MOUSEINPUT {
                dx,
                dy,
                mouseData: 0,
                dwFlags: MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK,
                time: 0,
                dwExtraInfo: 0,
            },
        },
    };
    unsafe {
        SendInput(&[input], std::mem::size_of::<INPUT>() as i32);
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

#[cfg(windows)]
unsafe fn set_clipboard_text(text: &str) -> bool {
    use windows::Win32::Foundation::HANDLE;
    use windows::Win32::System::DataExchange::{
        CloseClipboard, EmptyClipboard, OpenClipboard, SetClipboardData,
    };
    use windows::Win32::System::Memory::{GlobalAlloc, GlobalLock, GlobalUnlock, GMEM_MOVEABLE};

    if OpenClipboard(None).is_err() {
        return false;
    }
    let _ = EmptyClipboard();

    let utf16: Vec<u16> = text.encode_utf16().chain(std::iter::once(0)).collect();
    let bytes_len = utf16.len() * std::mem::size_of::<u16>();
    let Ok(hmem) = GlobalAlloc(GMEM_MOVEABLE, bytes_len) else {
        let _ = CloseClipboard();
        return false;
    };
    let ptr = GlobalLock(hmem) as *mut u16;
    if ptr.is_null() {
        let _ = CloseClipboard();
        return false;
    }
    std::ptr::copy_nonoverlapping(utf16.as_ptr(), ptr, utf16.len());
    let _ = GlobalUnlock(hmem);

    const CF_UNICODETEXT: u32 = 13;
    let ok = SetClipboardData(CF_UNICODETEXT, HANDLE(hmem.0)).is_ok();
    let _ = CloseClipboard();
    ok
}

#[cfg(windows)]
unsafe fn set_clipboard_files(paths: &[std::path::PathBuf]) -> bool {
    use windows::Win32::Foundation::{HANDLE, POINT};
    use windows::Win32::System::DataExchange::{
        CloseClipboard, EmptyClipboard, OpenClipboard, SetClipboardData,
    };
    use windows::Win32::System::Memory::{GlobalAlloc, GlobalLock, GlobalUnlock, GMEM_MOVEABLE};
    use windows::Win32::UI::Shell::DROPFILES;

    if paths.is_empty() {
        return false;
    }
    if OpenClipboard(None).is_err() {
        return false;
    }
    let _ = EmptyClipboard();

    let mut utf16_buf: Vec<u16> = Vec::new();
    for p in paths {
        let s = p.to_string_lossy();
        utf16_buf.extend(s.encode_utf16());
        utf16_buf.push(0);
    }
    utf16_buf.push(0);

    let header_size = std::mem::size_of::<DROPFILES>();
    let total_bytes = header_size + utf16_buf.len() * std::mem::size_of::<u16>();

    let Ok(hmem) = GlobalAlloc(GMEM_MOVEABLE, total_bytes) else {
        let _ = CloseClipboard();
        return false;
    };
    let ptr = GlobalLock(hmem) as *mut u8;
    if ptr.is_null() {
        let _ = CloseClipboard();
        return false;
    }

    let dropfiles = DROPFILES {
        pFiles: header_size as u32,
        pt: POINT { x: 0, y: 0 },
        fNC: false.into(),
        fWide: true.into(),
    };
    std::ptr::copy_nonoverlapping(&dropfiles as *const DROPFILES as *const u8, ptr, header_size);
    std::ptr::copy_nonoverlapping(
        utf16_buf.as_ptr() as *const u8,
        ptr.add(header_size),
        utf16_buf.len() * std::mem::size_of::<u16>(),
    );
    let _ = GlobalUnlock(hmem);

    const CF_HDROP: u32 = 15;
    let ok = SetClipboardData(CF_HDROP, HANDLE(hmem.0)).is_ok();
    let _ = CloseClipboard();
    ok
}

#[cfg(windows)]
fn trigger_paste() {
    send_key_event(0x11, false);
    send_key_event(0x56, false);
    std::thread::sleep(std::time::Duration::from_millis(30));
    send_key_event(0x56, true);
    send_key_event(0x11, true);
}

fn parse_start_coords(text: &str, w: i32, h: i32) -> Option<(i32, i32)> {
    let t = text.trim();
    if t.is_empty() {
        return None;
    }
    if let Ok(v) = serde_json::from_str::<serde_json::Value>(t) {
        let sx = v.get("start_x").or_else(|| v.get("x")).and_then(|x| x.as_f64());
        let sy = v.get("start_y").or_else(|| v.get("y")).and_then(|y| y.as_f64());
        if let (Some(x), Some(y)) = (sx, sy) {
            let px = (x.clamp(0.0, 1.0) * w as f64).round() as i32;
            let py = (y.clamp(0.0, 1.0) * h as f64).round() as i32;
            return Some((px, py));
        }
    }
    let clean = t.strip_prefix("start:").unwrap_or(t).trim();
    let parts: Vec<&str> = clean.split(',').map(str::trim).collect();
    if parts.len() == 2 {
        if let (Ok(x), Ok(y)) = (parts[0].parse::<f64>(), parts[1].parse::<f64>()) {
            let px = (x.clamp(0.0, 1.0) * w as f64).round() as i32;
            let py = (y.clamp(0.0, 1.0) * h as f64).round() as i32;
            return Some((px, py));
        }
    }
    None
}

fn parse_stroke_points(text: &str, w: i32, h: i32) -> Vec<(i32, i32)> {
    let t = text.trim();
    if t.is_empty() {
        return Vec::new();
    }
    if let Ok(v) = serde_json::from_str::<serde_json::Value>(t) {
        let arr = if let Some(a) = v.as_array() {
            Some(a)
        } else if let Some(a) = v.get("points").and_then(|p| p.as_array()) {
            Some(a)
        } else {
            None
        };
        if let Some(arr) = arr {
            let mut pts = Vec::with_capacity(arr.len());
            for item in arr {
                if let Some(obj) = item.as_object() {
                    let x = obj.get("x").and_then(|v| v.as_f64());
                    let y = obj.get("y").and_then(|v| v.as_f64());
                    if let (Some(x), Some(y)) = (x, y) {
                        let px = (x.clamp(0.0, 1.0) * w as f64).round() as i32;
                        let py = (y.clamp(0.0, 1.0) * h as f64).round() as i32;
                        pts.push((px, py));
                    }
                } else if let Some(coords) = item.as_array() {
                    if coords.len() >= 2 {
                        let x = coords[0].as_f64();
                        let y = coords[1].as_f64();
                        if let (Some(x), Some(y)) = (x, y) {
                            let px = (x.clamp(0.0, 1.0) * w as f64).round() as i32;
                            let py = (y.clamp(0.0, 1.0) * h as f64).round() as i32;
                            pts.push((px, py));
                        }
                    }
                }
            }
            if !pts.is_empty() {
                return pts;
            }
        }
    }
    let mut pts = Vec::new();
    for seg in t.split([';', '\n', '|']) {
        let seg = seg.trim();
        if seg.is_empty() {
            continue;
        }
        let parts: Vec<&str> = seg.split([',', ' ']).filter(|s| !s.is_empty()).collect();
        if parts.len() >= 2 {
            if let (Ok(x), Ok(y)) = (parts[0].parse::<f64>(), parts[1].parse::<f64>()) {
                let px = (x.clamp(0.0, 1.0) * w as f64).round() as i32;
                let py = (y.clamp(0.0, 1.0) * h as f64).round() as i32;
                pts.push((px, py));
            }
        }
    }
    pts
}

fn execute_smooth_drag(
    start_x: i32,
    start_y: i32,
    end_x: i32,
    end_y: i32,
    button: i32,
    w: i32,
    h: i32,
) {
    let btn_down = mouse_down_flag(button);
    let btn_up = mouse_up_flag(button);

    sync_remote_pointer(start_x, start_y);
    nudge_pointer_hit_test(start_x, start_y, w, h);
    std::thread::sleep(std::time::Duration::from_millis(30));

    send_mouse_event(btn_down, 0);
    std::thread::sleep(std::time::Duration::from_millis(35));

    let dx = (end_x - start_x) as f64;
    let dy = (end_y - start_y) as f64;
    let dist = (dx * dx + dy * dy).sqrt();
    let steps = ((dist / 14.0).round() as usize).clamp(8, 45);

    for i in 1..=steps {
        let t = i as f64 / steps as f64;
        let ease = t * t * (3.0 - 2.0 * t);
        let cur_x = (start_x as f64 + dx * ease).round() as i32;
        let cur_y = (start_y as f64 + dy * ease).round() as i32;
        sync_remote_pointer(cur_x, cur_y);
        nudge_pointer_hit_test(cur_x, cur_y, w, h);
        std::thread::sleep(std::time::Duration::from_millis(6));
    }

    sync_remote_pointer(end_x, end_y);
    nudge_pointer_hit_test(end_x, end_y, w, h);
    std::thread::sleep(std::time::Duration::from_millis(35));
    send_mouse_event(btn_up, 0);
    std::thread::sleep(std::time::Duration::from_millis(20));
}

fn execute_stroke(points: &[(i32, i32)], button: i32, w: i32, h: i32) {
    if points.is_empty() {
        return;
    }
    if points.len() == 1 {
        let (px, py) = points[0];
        sync_remote_pointer(px, py);
        nudge_pointer_hit_test(px, py, w, h);
        std::thread::sleep(std::time::Duration::from_millis(30));
        let btn_down = mouse_down_flag(button);
        let btn_up = mouse_up_flag(button);
        send_mouse_event(btn_down, 0);
        std::thread::sleep(std::time::Duration::from_millis(60));
        send_mouse_event(btn_up, 0);
        return;
    }

    let btn_down = mouse_down_flag(button);
    let btn_up = mouse_up_flag(button);

    let (start_x, start_y) = points[0];
    sync_remote_pointer(start_x, start_y);
    nudge_pointer_hit_test(start_x, start_y, w, h);
    std::thread::sleep(std::time::Duration::from_millis(30));

    send_mouse_event(btn_down, 0);
    std::thread::sleep(std::time::Duration::from_millis(30));

    for i in 1..points.len() {
        let (p0_x, p0_y) = points[i - 1];
        let (p1_x, p1_y) = points[i];
        let dx = (p1_x - p0_x) as f64;
        let dy = (p1_y - p0_y) as f64;
        let dist = (dx * dx + dy * dy).sqrt();
        let sub_steps = ((dist / 10.0).round() as usize).clamp(1, 15);

        for s in 1..=sub_steps {
            let t = s as f64 / sub_steps as f64;
            let cx = (p0_x as f64 + dx * t).round() as i32;
            let cy = (p0_y as f64 + dy * t).round() as i32;
            sync_remote_pointer(cx, cy);
            nudge_pointer_hit_test(cx, cy, w, h);
            std::thread::sleep(std::time::Duration::from_millis(5));
        }
    }

    let (end_x, end_y) = points[points.len() - 1];
    sync_remote_pointer(end_x, end_y);
    nudge_pointer_hit_test(end_x, end_y, w, h);
    std::thread::sleep(std::time::Duration::from_millis(30));
    send_mouse_event(btn_up, 0);
    std::thread::sleep(std::time::Duration::from_millis(20));
}

#[cfg(windows)]
unsafe fn set_clipboard_image(input: &str) -> bool {
    use windows::Win32::Foundation::HANDLE;
    use windows::Win32::System::DataExchange::{
        CloseClipboard, EmptyClipboard, OpenClipboard, RegisterClipboardFormatW, SetClipboardData,
    };
    use windows::Win32::System::Memory::{GlobalAlloc, GlobalLock, GlobalUnlock, GMEM_MOVEABLE};

    let trimmed = input.trim();
    if trimmed.is_empty() {
        return false;
    }

    let raw_bytes: Vec<u8> = if trimmed.starts_with("data:image/") {
        if let Some(pos) = trimmed.find(";base64,") {
            let b64 = &trimmed[pos + 8..];
            use base64::Engine;
            base64::engine::general_purpose::STANDARD.decode(b64.trim()).unwrap_or_default()
        } else {
            Vec::new()
        }
    } else if let Ok(bytes) = std::fs::read(trimmed) {
        bytes
    } else if let Some(resolved) = c_remote_core::webrtc::fs::path_resolve(trimmed).ok().and_then(|p| std::fs::read(p).ok()) {
        resolved
    } else {
        use base64::Engine;
        base64::engine::general_purpose::STANDARD.decode(trimmed).unwrap_or_default()
    };

    if raw_bytes.is_empty() {
        warn!("set_clipboard_image: failed to load or decode image bytes");
        return false;
    }

    let dynamic_img = match image::load_from_memory(&raw_bytes) {
        Ok(img) => img,
        Err(e) => {
            warn!("set_clipboard_image: image decoding failed: {e}");
            return false;
        }
    };

    let rgba = dynamic_img.to_rgba8();
    let (width, height) = (rgba.width(), rgba.height());
    if width == 0 || height == 0 {
        return false;
    }

    let header_size = 40usize;
    let row_stride = (width as usize) * 4;
    let dib_size = header_size + row_stride * (height as usize);
    let mut dib_bytes = Vec::with_capacity(dib_size);

    dib_bytes.extend_from_slice(&40u32.to_le_bytes());
    dib_bytes.extend_from_slice(&(width as i32).to_le_bytes());
    dib_bytes.extend_from_slice(&(height as i32).to_le_bytes());
    dib_bytes.extend_from_slice(&1u16.to_le_bytes());
    dib_bytes.extend_from_slice(&32u16.to_le_bytes());
    dib_bytes.extend_from_slice(&0u32.to_le_bytes());
    dib_bytes.extend_from_slice(&((width * height * 4) as u32).to_le_bytes());
    dib_bytes.extend_from_slice(&2835i32.to_le_bytes());
    dib_bytes.extend_from_slice(&2835i32.to_le_bytes());
    dib_bytes.extend_from_slice(&0u32.to_le_bytes());
    dib_bytes.extend_from_slice(&0u32.to_le_bytes());

    for y in (0..height).rev() {
        for x in 0..width {
            let p = rgba.get_pixel(x, y);
            dib_bytes.push(p[2]); // B
            dib_bytes.push(p[1]); // G
            dib_bytes.push(p[0]); // R
            dib_bytes.push(p[3]); // A
        }
    }

    if OpenClipboard(None).is_err() {
        return false;
    }
    let _ = EmptyClipboard();

    let mut success = false;
    if let Ok(hmem_dib) = GlobalAlloc(GMEM_MOVEABLE, dib_bytes.len()) {
        let ptr = GlobalLock(hmem_dib) as *mut u8;
        if !ptr.is_null() {
            std::ptr::copy_nonoverlapping(dib_bytes.as_ptr(), ptr, dib_bytes.len());
            let _ = GlobalUnlock(hmem_dib);
            const CF_DIB: u32 = 8;
            if SetClipboardData(CF_DIB, HANDLE(hmem_dib.0)).is_ok() {
                success = true;
            }
        }
    }

    let png_fmt = RegisterClipboardFormatW(windows::core::w!("PNG"));
    if png_fmt > 0 {
        let png_bytes = if raw_bytes.starts_with(b"\x89PNG\r\n\x1a\n") {
            raw_bytes
        } else {
            let mut buf = std::io::Cursor::new(Vec::new());
            let _ = dynamic_img.write_to(&mut buf, image::ImageFormat::Png);
            buf.into_inner()
        };

        if !png_bytes.is_empty() {
            if let Ok(hmem_png) = GlobalAlloc(GMEM_MOVEABLE, png_bytes.len()) {
                let ptr = GlobalLock(hmem_png) as *mut u8;
                if !ptr.is_null() {
                    std::ptr::copy_nonoverlapping(png_bytes.as_ptr(), ptr, png_bytes.len());
                    let _ = GlobalUnlock(hmem_png);
                    let _ = SetClipboardData(png_fmt, HANDLE(hmem_png.0));
                }
            }
        }
    }

    let _ = CloseClipboard();
    success
}

