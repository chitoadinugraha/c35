use std::sync::OnceLock;
use std::time::Duration;

use crate::skill_teach_overlay::{
    classify_click, overlay_hide, overlay_hit, overlay_is_agent_ui, overlay_set_last, overlay_show,
    TeachClick,
};
use crate::uia::{resolve_element_at, uia_foreground_title};

enum HookEv {
    Click { x: i32, y: i32 },
    Type { ch: String, vk: u32 },
    Stop,
}

static HOOK_TX: OnceLock<std::sync::mpsc::Sender<HookEv>> = OnceLock::new();
static MERGE_STARTED: OnceLock<()> = OnceLock::new();

pub fn platform_start(title: &str) {
    overlay_show(title);
    spawn_hooks();
}

pub fn platform_stop() {
    overlay_hide();
}

pub fn platform_set_last(ord: i32, label: &str) {
    overlay_set_last(ord, label);
}

fn spawn_hooks() {
    if HOOK_TX.get().is_some() {
        return;
    }
    let (tx, rx) = std::sync::mpsc::channel::<HookEv>();
    let _ = HOOK_TX.set(tx.clone());

    std::thread::Builder::new()
        .name("teach-hooks".into())
        .spawn(move || hook_thread(tx))
        .ok();

    if MERGE_STARTED.get().is_none() {
        let _ = MERGE_STARTED.set(());
        std::thread::Builder::new()
            .name("teach-merge".into())
            .spawn(move || merge_thread(rx))
            .ok();
    }
}

fn merge_thread(rx: std::sync::mpsc::Receiver<HookEv>) {
    loop {
        match rx.recv_timeout(Duration::from_millis(100)) {
            Ok(HookEv::Stop) => {
                let _ = c_remote_core::skill_teach::teach_stop();
            }
            Ok(HookEv::Click { x, y }) => {
                if c_remote_core::skill_teach::teach_hooks_skipped() {
                    continue;
                }
                let hit = overlay_hit(x, y);
                let on_ui = overlay_is_agent_ui(x, y);
                match classify_click(hit, on_ui) {
                    TeachClick::Stop => {
                        let _ = c_remote_core::skill_teach::teach_stop();
                        continue;
                    }
                    TeachClick::Ignore => continue,
                    TeachClick::Record => {}
                }
                if !c_remote_core::skill_teach::teach_is_recording() {
                    continue;
                }
                let (control, window) = resolve_element_at(x, y);
                c_remote_core::skill_teach::teach_record_click(x, y, &window, &control);
            }
            Ok(HookEv::Type { ch, vk }) => {
                if c_remote_core::skill_teach::teach_key_event(vk, &ch) {
                    continue;
                }
                if !c_remote_core::skill_teach::teach_is_recording() {
                    continue;
                }
                let window = uia_foreground_title();
                if let Some((name, is_pwd)) = check_focused_edit() {
                    c_remote_core::skill_teach::teach_focus_field(&window, &name, is_pwd);
                }
            }
            Err(std::sync::mpsc::RecvTimeoutError::Timeout) => {}
            Err(std::sync::mpsc::RecvTimeoutError::Disconnected) => break,
        }
    }
}

fn check_focused_edit() -> Option<(String, bool)> {
    let auto = uiautomation::UIAutomation::new().ok()?;
    let el = auto.get_focused_element().ok()?;
    let ct = el.get_control_type().ok()?;
    if ct == uiautomation::controls::ControlType::Edit {
        let name = el.get_name().unwrap_or_default();
        let auto_id = el.get_automation_id().unwrap_or_default();
        let lower_name = name.to_lowercase();
        let lower_id = auto_id.to_lowercase();
        let is_pwd = lower_name.contains("password")
            || lower_name.contains("passwd")
            || lower_id.contains("password")
            || lower_id.contains("passwd");
        Some((name, is_pwd))
    } else {
        None
    }
}

#[cfg(target_os = "windows")]
fn hook_thread(tx: std::sync::mpsc::Sender<HookEv>) {
    use windows_sys::Win32::Foundation::{LPARAM, LRESULT, WPARAM};
    use windows_sys::Win32::UI::WindowsAndMessaging::{
        CallNextHookEx, DispatchMessageW, GetMessageW, SetWindowsHookExW, TranslateMessage, MSG,
        WH_KEYBOARD_LL, WH_MOUSE_LL, WM_KEYDOWN, WM_LBUTTONDOWN, WM_SYSKEYDOWN,
    };

    static TX: OnceLock<std::sync::mpsc::Sender<HookEv>> = OnceLock::new();
    let _ = TX.set(tx);

    unsafe extern "system" fn mouse_proc(code: i32, wparam: WPARAM, lparam: LPARAM) -> LRESULT {
        if code >= 0 && wparam == WM_LBUTTONDOWN as usize {
            #[repr(C)]
            struct Msll {
                pt_x: i32,
                pt_y: i32,
                _mouse_data: u32,
                _flags: u32,
                _time: u32,
                _extra: usize,
            }
            let info = &*(lparam as *const Msll);
            let x = info.pt_x;
            let y = info.pt_y;
            let hit = overlay_hit(x, y);
            let on_ui = overlay_is_agent_ui(x, y);
            match classify_click(hit, on_ui) {
                TeachClick::Stop => {
                    if let Some(tx) = TX.get() {
                        let _ = tx.send(HookEv::Stop);
                    }
                    return 1;
                }
                TeachClick::Ignore => return 1,
                TeachClick::Record => {
                    if let Some(tx) = TX.get() {
                        let _ = tx.send(HookEv::Click { x, y });
                    }
                }
            }
        }
        unsafe { CallNextHookEx(0 as _, code, wparam, lparam) }
    }

    unsafe extern "system" fn key_proc(code: i32, wparam: WPARAM, lparam: LPARAM) -> LRESULT {
        if code >= 0 && (wparam == WM_KEYDOWN as usize || wparam == WM_SYSKEYDOWN as usize) {
            #[repr(C)]
            struct Kbd {
                vk: u32,
                _scan: u32,
                _flags: u32,
                _time: u32,
                _extra: usize,
            }
            let info = &*(lparam as *const Kbd);
            let vk = info.vk;
            let ch = vk_to_char(vk);
            if let Some(tx) = TX.get() {
                if vk == 0x78 || vk == 0x1B {
                    let _ = tx.send(HookEv::Stop);
                } else {
                    let _ = tx.send(HookEv::Type { ch, vk });
                }
            }
        }
        unsafe { CallNextHookEx(0 as _, code, wparam, lparam) }
    }

    unsafe {
        let _mouse = SetWindowsHookExW(WH_MOUSE_LL, Some(mouse_proc), 0 as _, 0);
        let _key = SetWindowsHookExW(WH_KEYBOARD_LL, Some(key_proc), 0 as _, 0);
        let mut msg: MSG = std::mem::zeroed();
        while GetMessageW(&mut msg, 0 as _, 0, 0) > 0 {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }
}

#[cfg(target_os = "windows")]
fn vk_to_char(vk: u32) -> String {
    if vk == 0x08 || vk == 0x09 || vk == 0x0D || vk == 0x1B {
        return String::new();
    }
    if (0x30..=0x39).contains(&vk) {
        return ((vk as u8) as char).to_string();
    }
    if (0x41..=0x5A).contains(&vk) {
        let shift = unsafe { windows_sys::Win32::UI::Input::KeyboardAndMouse::GetKeyState(0x10) }
            as u16
            & 0x8000
            != 0;
        let c = vk as u8 as char;
        return if shift {
            c.to_string()
        } else {
            c.to_ascii_lowercase().to_string()
        };
    }
    if vk == 0x20 {
        return " ".to_string();
    }
    String::new()
}

#[cfg(not(target_os = "windows"))]
fn hook_thread(_tx: std::sync::mpsc::Sender<HookEv>) {}
