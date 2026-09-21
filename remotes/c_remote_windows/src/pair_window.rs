use std::sync::{Arc, Condvar, Mutex};
use std::time::{Duration, Instant};

use tracing::warn;

#[derive(Clone, Debug)]
struct PairUiState {
    code: String,
    status: String,
    deadline: Option<Instant>,
}

impl Default for PairUiState {
    fn default() -> Self {
        Self {
            code: "----------".into(),
            status: "Requesting a pairing code…".into(),
            deadline: None,
        }
    }
}

pub struct PairWindow {
    inner: Arc<Mutex<PairUiState>>,
    #[cfg(target_os = "windows")]
    hwnd: Arc<Mutex<isize>>,
    #[cfg(target_os = "windows")]
    ready: Arc<(Mutex<bool>, Condvar)>,
}

impl PairWindow {
    pub fn spawn() -> Self {
        let inner = Arc::new(Mutex::new(PairUiState::default()));
        #[cfg(target_os = "windows")]
        {
            let hwnd = Arc::new(Mutex::new(0isize));
            let ready = Arc::new((Mutex::new(false), Condvar::new()));
            let inner_t = inner.clone();
            let hwnd_t = hwnd.clone();
            let ready_t = ready.clone();
            let _ = std::thread::Builder::new()
                .name("c35-pair-ui".into())
                .spawn(move || {
                    if let Err(e) = run_pair_window(inner_t, hwnd_t, ready_t) {
                        warn!("Pairing window failed ({e}); code will also print to the console.");
                    }
                });
            let window = Self { inner, hwnd, ready };
            window.wait_ready();
            window
        }
        #[cfg(not(target_os = "windows"))]
        {
            Self { inner }
        }
    }

    #[cfg(target_os = "windows")]
    fn wait_ready(&self) {
        let (lock, cv) = &*self.ready;
        let started = Instant::now();
        let mut ready = lock.lock().unwrap();
        while !*ready && started.elapsed() < Duration::from_secs(2) {
            let (g, _) = cv.wait_timeout(ready, Duration::from_millis(100)).unwrap();
            ready = g;
        }
    }

    pub fn set_code(&self, code: &str, expires_in_sec: i64) {
        {
            let mut g = self.inner.lock().unwrap();
            g.code = code.to_string();
            g.status = "Enter this in Alien AI → Devices → Pair with Code".into();
            g.deadline = Some(Instant::now() + Duration::from_secs(expires_in_sec.max(1) as u64));
        }
        println!();
        println!("============================================================");
        println!(">>> Alien AI Remote Agent - Pairing Required");
        println!(">>> Enter this in Alien AI → Devices → Pair with Code");
        println!(">>> [ {} ]", code);
        println!("============================================================");
        self.invalidate();
    }

    pub fn set_status(&self, status: &str) {
        self.inner.lock().unwrap().status = status.to_string();
        println!(">>> {status}");
        self.invalidate();
    }

    pub fn close(&self) {
        #[cfg(target_os = "windows")]
        unsafe {
            use windows::Win32::Foundation::{HWND, LPARAM, WPARAM};
            use windows::Win32::UI::WindowsAndMessaging::{PostMessageW, WM_CLOSE};
            let hwnd = *self.hwnd.lock().unwrap();
            if hwnd != 0 {
                let _ = PostMessageW(HWND(hwnd as *mut core::ffi::c_void), WM_CLOSE, WPARAM(0), LPARAM(0));
            }
        }
    }

    fn invalidate(&self) {
        #[cfg(target_os = "windows")]
        unsafe {
            use windows::Win32::Foundation::HWND;
            use windows::Win32::Graphics::Gdi::InvalidateRect;
            let hwnd = *self.hwnd.lock().unwrap();
            if hwnd != 0 {
                let _ = InvalidateRect(HWND(hwnd as *mut core::ffi::c_void), None, true);
            }
        }
    }
}

#[cfg(target_os = "windows")]
fn run_pair_window(
    state: Arc<Mutex<PairUiState>>,
    hwnd_slot: Arc<Mutex<isize>>,
    ready: Arc<(Mutex<bool>, Condvar)>,
) -> anyhow::Result<()> {
    use windows::core::w;
    use windows::Win32::Foundation::{COLORREF, HWND, LPARAM, LRESULT, RECT, WPARAM};
    use windows::Win32::Graphics::Gdi::{
        BeginPaint, CreateSolidBrush, DeleteObject, DrawTextW, EndPaint, FillRect, SetBkMode,
        SetTextColor, DT_CENTER, DT_SINGLELINE, DT_WORDBREAK, HDC, HGDIOBJ, PAINTSTRUCT, TRANSPARENT,
    };
    use windows::Win32::UI::WindowsAndMessaging::{
        CreateWindowExW, DefWindowProcW, DestroyWindow, DispatchMessageW, GetClientRect, GetMessageW,
        GetSystemMetrics, KillTimer, LoadCursorW, PostQuitMessage, RegisterClassExW, SetTimer, SetWindowPos,
        ShowWindow, TranslateMessage, CS_HREDRAW, CS_VREDRAW, HMENU, HWND_TOPMOST, IDC_ARROW, MSG,
        SM_CXSCREEN, SM_CYSCREEN, SWP_NOMOVE, SWP_NOSIZE, SW_SHOW, WM_CLOSE, WM_DESTROY, WM_PAINT,
        WM_TIMER, WNDCLASSEXW, WS_CAPTION, WS_EX_APPWINDOW, WS_EX_TOPMOST, WS_OVERLAPPED, WS_VISIBLE,
    };

    const WM_TIMER_ID: usize = 1;

    struct Ctx {
        state: Arc<Mutex<PairUiState>>,
    }

    unsafe extern "system" fn window_proc(hwnd: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) -> LRESULT {
        match msg {
            WM_PAINT => {
                let mut ps = PAINTSTRUCT::default();
                let hdc = BeginPaint(hwnd, &mut ps);
                paint_pair(hwnd, hdc);
                let _ = EndPaint(hwnd, &ps);
                LRESULT(0)
            }
            WM_TIMER => {
                let _ = windows::Win32::Graphics::Gdi::InvalidateRect(hwnd, None, true);
                LRESULT(0)
            }
            WM_CLOSE | WM_DESTROY => {
                let _ = KillTimer(hwnd, WM_TIMER_ID);
                PostQuitMessage(0);
                LRESULT(0)
            }
            _ => DefWindowProcW(hwnd, msg, wparam, lparam),
        }
    }

    unsafe fn paint_pair(hwnd: HWND, hdc: HDC) {
        let mut rc = RECT::default();
        let _ = GetClientRect(hwnd, &mut rc);
        let bg = CreateSolidBrush(COLORREF(0x000A0A08));
        let _ = FillRect(hdc, &rc, bg);
        let _ = DeleteObject(HGDIOBJ(bg.0));
        SetBkMode(hdc, TRANSPARENT);
        let ctx = window_ctx();
        let snap = ctx.state.lock().unwrap().clone();
        SetTextColor(hdc, COLORREF(0x00E7E4E4));
        let mut title = wide("Alien AI Remote Agent");
        let mut title_rc = RECT {
            left: 24,
            top: 24,
            right: rc.right - 24,
            bottom: 56,
        };
        DrawTextW(hdc, &mut title, &mut title_rc, DT_CENTER | DT_SINGLELINE);
        SetTextColor(hdc, COLORREF(0x0099D334));
        let mut code = wide(&snap.code.replace('-', " - "));
        let mut code_rc = RECT {
            left: 16,
            top: 80,
            right: rc.right - 16,
            bottom: 140,
        };
        DrawTextW(hdc, &mut code, &mut code_rc, DT_CENTER | DT_SINGLELINE);
        SetTextColor(hdc, COLORREF(0x00AAA1A1));
        let mut status = wide(&snap.status);
        let mut status_rc = RECT {
            left: 28,
            top: 150,
            right: rc.right - 28,
            bottom: 210,
        };
        DrawTextW(hdc, &mut status, &mut status_rc, DT_CENTER | DT_WORDBREAK);
        let remain = snap
            .deadline
            .map(|d| d.saturating_duration_since(Instant::now()))
            .unwrap_or(Duration::ZERO);
        let secs = remain.as_secs();
        let expire = if snap.deadline.is_some() {
            format!("Code expires in {}:{:02}", secs / 60, secs % 60)
        } else {
            String::new()
        };
        let mut exp = wide(&expire);
        let mut exp_rc = RECT {
            left: 24,
            top: 214,
            right: rc.right - 24,
            bottom: 248,
        };
        DrawTextW(hdc, &mut exp, &mut exp_rc, DT_CENTER | DT_SINGLELINE);
    }

    fn wide(s: &str) -> Vec<u16> {
        s.encode_utf16().chain(std::iter::once(0)).collect()
    }

    thread_local! {
        static CTX: std::cell::RefCell<Option<Ctx>> = const { std::cell::RefCell::new(None) };
    }

    fn window_ctx() -> Ctx {
        CTX.with(|c| c.borrow().as_ref().unwrap().clone_ctx())
    }

    impl Ctx {
        fn clone_ctx(&self) -> Ctx {
            Ctx {
                state: self.state.clone(),
            }
        }
    }

    unsafe {
        CTX.with(|c| {
            *c.borrow_mut() = Some(Ctx { state: state.clone() });
        });

        let class_name = w!("AlienAIPairWindow");
        let wnd_class = WNDCLASSEXW {
            cbSize: std::mem::size_of::<WNDCLASSEXW>() as u32,
            style: CS_HREDRAW | CS_VREDRAW,
            lpfnWndProc: Some(window_proc),
            hInstance: windows::Win32::Foundation::HINSTANCE::default(),
            hCursor: LoadCursorW(None, IDC_ARROW).unwrap_or_default(),
            lpszClassName: class_name,
            ..Default::default()
        };
        let _ = RegisterClassExW(&wnd_class);

        let cw = GetSystemMetrics(SM_CXSCREEN);
        let ch = GetSystemMetrics(SM_CYSCREEN);
        let ww = 460;
        let wh = 300;
        let hwnd = CreateWindowExW(
            WS_EX_TOPMOST | WS_EX_APPWINDOW,
            class_name,
            w!("Alien AI Remote Agent"),
            WS_OVERLAPPED | WS_CAPTION | WS_VISIBLE,
            (cw - ww) / 2,
            (ch - wh) / 2,
            ww,
            wh,
            HWND::default(),
            HMENU::default(),
            windows::Win32::Foundation::HINSTANCE::default(),
            None,
        )?;

        *hwnd_slot.lock().unwrap() = hwnd.0 as isize;
        let _ = SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
        let _ = ShowWindow(hwnd, SW_SHOW);
        let _ = SetTimer(hwnd, WM_TIMER_ID, 1000, None);

        {
            let (lock, cv) = &*ready;
            *lock.lock().unwrap() = true;
            cv.notify_all();
        }

        let mut msg = MSG::default();
        while GetMessageW(&mut msg, HWND::default(), 0, 0).as_bool() {
            let _ = TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
        let _ = DestroyWindow(hwnd);
        *hwnd_slot.lock().unwrap() = 0;
    }
    Ok(())
}
