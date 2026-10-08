use tracing::{info, warn};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TrayAction {
    Unpair,
    Quit,
    Restart,
    DriveSet(bool),
}

pub fn start_tray_thread(tx: tokio::sync::mpsc::UnboundedSender<TrayAction>) {
    #[cfg(target_os = "windows")]
    {
        std::thread::Builder::new()
            .name("alienai-tray".to_string())
            .spawn(move || {
                if let Err(e) = run_tray_loop(tx) {
                    warn!("System tray encountered error: {e}");
                }
            })
            .expect("Failed to spawn tray thread");
    }

    #[cfg(not(target_os = "windows"))]
    {
        let _ = tx;
        info!("System tray icon is currently implemented for Windows.");
    }
}

#[cfg(target_os = "windows")]
thread_local! {
    static TRAY_TX: std::cell::RefCell<Option<tokio::sync::mpsc::UnboundedSender<TrayAction>>> =
        const { std::cell::RefCell::new(None) };
}

#[cfg(target_os = "windows")]
pub fn load_alien_icon(width: i32, height: i32) -> windows::Win32::UI::WindowsAndMessaging::HICON {
    crate::icon::load_app_icon(width, height)
}

#[cfg(target_os = "windows")]
fn run_tray_loop(tx: tokio::sync::mpsc::UnboundedSender<TrayAction>) -> anyhow::Result<()> {
    use std::sync::atomic::{AtomicBool, Ordering};
    use windows::core::{w, HSTRING, PCWSTR};
    use windows::Win32::Foundation::{HINSTANCE, HWND, LPARAM, LRESULT, POINT, WPARAM};
    use windows::Win32::UI::Shell::{
        Shell_NotifyIconW, NIF_ICON, NIF_MESSAGE, NIF_TIP, NIM_ADD, NIM_DELETE, NOTIFYICONDATAW,
    };
    use windows::Win32::UI::WindowsAndMessaging::{
        AppendMenuW, CreatePopupMenu, CreateWindowExW, DefWindowProcW, DestroyMenu, DestroyWindow,
        DispatchMessageW, GetCursorPos, GetMessageW, KillTimer, PostMessageW, PostQuitMessage,
        RegisterClassExW, RegisterWindowMessageW, SetForegroundWindow, SetTimer, TrackPopupMenu,
        TranslateMessage, HICON, HMENU, MF_SEPARATOR, MF_STRING, MSG, TPM_BOTTOMALIGN,
        TPM_RIGHTBUTTON, WINDOW_EX_STYLE, WM_COMMAND, WM_CONTEXTMENU, WM_DESTROY, WM_NULL,
        WM_LBUTTONDBLCLK, WM_RBUTTONUP, WM_TIMER, WM_USER, WNDCLASSEXW, WS_OVERLAPPEDWINDOW,
    };

    const WM_TRAYICON: u32 = WM_USER + 100;
    const ID_OPEN_APP: usize = 1000;
    const ID_CHECK_UPDATE: usize = 1006;
    const ID_UNPAIR: usize = 1001;
    const ID_RESTART: usize = 1007;
    const ID_QUIT: usize = 1002;
    const TRAY_TIMER_ID: usize = 99;

    static IS_EXITING: AtomicBool = AtomicBool::new(false);
    static WM_TASKBAR_CREATED: std::sync::atomic::AtomicU32 = std::sync::atomic::AtomicU32::new(0);
    static TRAY_ATTACHED: AtomicBool = AtomicBool::new(false);

    TRAY_TX.with(|c| *c.borrow_mut() = Some(tx));

    unsafe fn build_tray_nid(hwnd: HWND) -> NOTIFYICONDATAW {
        let icon: HICON = load_alien_icon(0, 0);
        let mut tip_chars = [0u16; 128];
        let cloud = if c_remote_core::agent_ui::ws_connected() { "online" } else { "offline" };
        let tip_text = format!(
            "Alien AI Remote — {} ({})",
            c_remote_core::version::agent_version_tray_label(),
            cloud
        );
        for (i, c) in tip_text.encode_utf16().take(127).enumerate() {
            tip_chars[i] = c;
        }
        NOTIFYICONDATAW {
            cbSize: std::mem::size_of::<NOTIFYICONDATAW>() as u32,
            hWnd: hwnd,
            uID: 1,
            uFlags: NIF_MESSAGE | NIF_ICON | NIF_TIP,
            uCallbackMessage: WM_TRAYICON,
            hIcon: icon,
            szTip: tip_chars,
            ..Default::default()
        }
    }

    unsafe fn show_tray_menu(hwnd: HWND) {
        let mut pt = POINT::default();
        let _ = GetCursorPos(&mut pt);
        if let Ok(hmenu) = CreatePopupMenu() {
            let _ = AppendMenuW(hmenu, MF_STRING, ID_OPEN_APP, w!("Open Alien AI Agent"));
            let check_label = HSTRING::from(format!(
                "Check for update — {}",
                c_remote_core::version::agent_version_tray_label()
            ));
            let _ = AppendMenuW(
                hmenu,
                MF_STRING,
                ID_CHECK_UPDATE,
                PCWSTR(check_label.as_ptr()),
            );
            if let Some(v) = c_remote_core::update::update_staged_version() {
                let apply = HSTRING::from(format!("Apply update (v{v})…"));
                let _ = AppendMenuW(hmenu, MF_STRING, 1005, PCWSTR(apply.as_ptr()));
            }
            let _ = AppendMenuW(hmenu, MF_STRING, ID_UNPAIR, w!("Unpair"));
            let _ = AppendMenuW(hmenu, MF_SEPARATOR, 0, PCWSTR::null());
            let _ = AppendMenuW(hmenu, MF_STRING, ID_RESTART, w!("Restart Agent"));
            let _ = AppendMenuW(hmenu, MF_STRING, ID_QUIT, w!("Quit"));
            let _ = SetForegroundWindow(hwnd);
            let _ = TrackPopupMenu(
                hmenu,
                TPM_RIGHTBUTTON | TPM_BOTTOMALIGN,
                pt.x,
                pt.y,
                0,
                hwnd,
                None,
            );
            let _ = PostMessageW(hwnd, WM_NULL, WPARAM(0), LPARAM(0));
            let _ = DestroyMenu(hmenu);
        }
    }

    unsafe extern "system" fn window_proc(
        hwnd: HWND,
        msg: u32,
        wparam: WPARAM,
        lparam: LPARAM,
    ) -> LRESULT {
        let taskbar_created = WM_TASKBAR_CREATED.load(Ordering::Relaxed);
        if taskbar_created != 0 && msg == taskbar_created {
            let mut nid = build_tray_nid(hwnd);
            if Shell_NotifyIconW(NIM_ADD, &mut nid).as_bool() {
                TRAY_ATTACHED.store(true, Ordering::Relaxed);
                info!("System tray icon registered via TaskbarCreated.");
            }
            return LRESULT(0);
        }

        match msg {
            WM_TIMER if wparam.0 == TRAY_TIMER_ID => {
                if !TRAY_ATTACHED.load(Ordering::Relaxed) {
                    let mut nid = build_tray_nid(hwnd);
                    if Shell_NotifyIconW(NIM_ADD, &mut nid).as_bool() {
                        TRAY_ATTACHED.store(true, Ordering::Relaxed);
                        let _ = KillTimer(hwnd, TRAY_TIMER_ID);
                        info!("System tray icon successfully attached to Windows taskbar.");
                    }
                } else {
                    let _ = KillTimer(hwnd, TRAY_TIMER_ID);
                }
                LRESULT(0)
            }
            WM_TRAYICON => {
                let event = lparam.0 as u32;
                if event == WM_LBUTTONDBLCLK {
                    crate::agent_window::show_or_focus();
                } else if event == WM_RBUTTONUP || event == WM_CONTEXTMENU {
                    show_tray_menu(hwnd);
                }
                LRESULT(0)
            }
            WM_COMMAND => {
                let id = wparam.0 as usize;
                if id == ID_OPEN_APP {
                    crate::agent_window::show_or_focus();
                }
                if id == 1005 {
                    c_remote_core::update::update_apply_now();
                }
                if id == ID_CHECK_UPDATE {
                    info!("tray: check for update");
                    c_remote_core::update::update_check_now();
                }
                if id == ID_UNPAIR {
                    info!("tray: unpair");
                    TRAY_TX.with(|c| {
                        if let Some(tx) = c.borrow().as_ref() {
                            let _ = tx.send(TrayAction::Unpair);
                        }
                    });
                }
                if id == ID_RESTART {
                    info!("tray: restart agent");
                    TRAY_TX.with(|c| {
                        if let Some(tx) = c.borrow().as_ref() {
                            let _ = tx.send(TrayAction::Restart);
                        }
                    });
                }
                if id == ID_QUIT {
                    info!("User selected Quit from Alien AI system tray menu.");
                    IS_EXITING.store(true, Ordering::Relaxed);
                    TRAY_TX.with(|c| {
                        if let Some(tx) = c.borrow().as_ref() {
                            let _ = tx.send(TrayAction::Quit);
                        }
                    });
                    let mut nid = build_tray_nid(hwnd);
                    let _ = Shell_NotifyIconW(NIM_DELETE, &mut nid);
                    let _ = DestroyWindow(hwnd);
                    PostQuitMessage(0);
                    std::process::exit(0);
                }
                LRESULT(0)
            }
            WM_DESTROY => {
                let mut nid = build_tray_nid(hwnd);
                let _ = Shell_NotifyIconW(NIM_DELETE, &mut nid);
                PostQuitMessage(0);
                LRESULT(0)
            }
            _ => DefWindowProcW(hwnd, msg, wparam, lparam),
        }
    }

    unsafe {
        let hinstance: HINSTANCE = windows::Win32::System::LibraryLoader::GetModuleHandleW(None)
            .unwrap_or_default()
            .into();
        let class_name = w!("AlienAITrayWindow");

        let wnd_class = WNDCLASSEXW {
            cbSize: std::mem::size_of::<WNDCLASSEXW>() as u32,
            lpfnWndProc: Some(window_proc),
            hInstance: hinstance,
            lpszClassName: class_name,
            ..Default::default()
        };

        let _ = RegisterClassExW(&wnd_class);

        let hwnd = CreateWindowExW(
            WINDOW_EX_STYLE(0),
            class_name,
            w!("Alien AI Remote Tray"),
            WS_OVERLAPPEDWINDOW,
            0,
            0,
            0,
            0,
            HWND::default(),
            HMENU::default(),
            hinstance,
            None,
        )?;

        let taskbar_msg = RegisterWindowMessageW(w!("TaskbarCreated"));
        if taskbar_msg != 0 {
            WM_TASKBAR_CREATED.store(taskbar_msg, Ordering::Relaxed);
        }

        let mut nid = build_tray_nid(hwnd);
        let mut added = false;
        for _ in 0..5 {
            if Shell_NotifyIconW(NIM_ADD, &mut nid).as_bool() {
                added = true;
                TRAY_ATTACHED.store(true, Ordering::Relaxed);
                info!("System tray icon active. Right-click for menu, double-click to open.");
                break;
            }
            std::thread::sleep(std::time::Duration::from_millis(200));
        }

        if !added {
            let _ = SetTimer(hwnd, TRAY_TIMER_ID, 2000, None);
            info!("System tray icon registered; retrying attachment until taskbar is interactive.");
        }

        let mut msg = MSG::default();
        while GetMessageW(&mut msg, HWND::default(), 0, 0).as_bool() {
            let _ = TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }

        let _ = Shell_NotifyIconW(NIM_DELETE, &mut nid);
    }

    Ok(())
}
