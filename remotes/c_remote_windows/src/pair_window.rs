use std::sync::{Arc, Condvar, Mutex};
use std::time::{Duration, Instant};

use tracing::warn;

use c_remote_core::version::agent_version_label;

const INSTRUCTION: &str = "Enter this code in Alien AI app -> Device -> Pair with Code";
const SITE_URL: &str = "https://alienai.id";
const WINDOW_TITLE: &str = "Alien AI - Pair Device";

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum PairPhase {
    Connecting,
    Code,
}

#[derive(Clone, Debug)]
struct PairUiState {
    phase: PairPhase,
    code: String,
    status: String,
    deadline: Option<Instant>,
    expires_total: Duration,
    spinner: u8,
}

impl Default for PairUiState {
    fn default() -> Self {
        Self {
            phase: PairPhase::Connecting,
            code: String::new(),
            status: "Connecting…".into(),
            deadline: None,
            expires_total: Duration::from_secs(300),
            spinner: 0,
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
        while !*ready && started.elapsed() < Duration::from_secs(5) {
            let (g, _) = cv.wait_timeout(ready, Duration::from_millis(50)).unwrap();
            ready = g;
        }
    }

    pub fn set_connecting(&self) {
        {
            let mut g = self.inner.lock().unwrap();
            g.phase = PairPhase::Connecting;
            g.code.clear();
            g.status = "Connecting…".into();
            g.deadline = None;
        }
        self.invalidate_all();
    }

    pub fn set_code(&self, code: &str, expires_in_sec: i64) {
        let total = Duration::from_secs(expires_in_sec.max(1) as u64);
        {
            let mut g = self.inner.lock().unwrap();
            g.phase = PairPhase::Code;
            g.code = code.to_string();
            g.status = INSTRUCTION.into();
            g.expires_total = total;
            g.deadline = Some(Instant::now() + total);
        }
        println!();
        println!("============================================================");
        println!(">>> {}", WINDOW_TITLE);
        println!(">>> {}", INSTRUCTION);
        println!(">>> [ {} ]", code);
        println!("============================================================");
        self.invalidate_all();
    }

    pub fn set_status(&self, status: &str) {
        self.inner.lock().unwrap().status = status.to_string();
        println!(">>> {status}");
        self.invalidate_all();
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

    fn invalidate_all(&self) {
        self.post_refresh(true);
    }

    fn post_refresh(&self, full: bool) {
        #[cfg(target_os = "windows")]
        unsafe {
            use windows::Win32::Foundation::{HWND, LPARAM, WPARAM};
            use windows::Win32::UI::WindowsAndMessaging::{PostMessageW, WM_USER};
            let hwnd = *self.hwnd.lock().unwrap();
            if hwnd != 0 {
                let _ = PostMessageW(
                    HWND(hwnd as *mut core::ffi::c_void),
                    WM_USER + 201,
                    WPARAM(if full { 1 } else { 0 }),
                    LPARAM(0),
                );
            }
        }
    }
}

fn code_is_pin(code: &str) -> bool {
    let parts: Vec<&str> = code.split('-').collect();
    parts.len() == 2
        && parts[0].len() == 5
        && parts[1].len() == 5
        && parts[0].chars().all(|c| c.is_ascii_alphanumeric())
        && parts[1].chars().all(|c| c.is_ascii_alphanumeric())
}

#[cfg(target_os = "windows")]
fn run_pair_window(
    state: Arc<Mutex<PairUiState>>,
    hwnd_slot: Arc<Mutex<isize>>,
    ready: Arc<(Mutex<bool>, Condvar)>,
) -> anyhow::Result<()> {
    use windows::core::w;
    use windows::Win32::Foundation::{COLORREF, HANDLE, HWND, LPARAM, LRESULT, POINT, RECT, WPARAM};
    use windows::Win32::Graphics::Gdi::{
        BeginPaint, CreateFontW, CreatePen, CreateSolidBrush, DeleteObject, DrawTextW, Ellipse, EndPaint,
        FillRect, GetStockObject, InvalidateRect, LineTo, MoveToEx, RoundRect, ScreenToClient, SelectObject,
        SetBkMode, SetTextColor, DEFAULT_CHARSET, DRAW_TEXT_FORMAT, DT_CENTER, DT_RIGHT, DT_SINGLELINE, DT_VCENTER,
        DT_WORDBREAK,
        FW_BOLD, FW_NORMAL, FW_SEMIBOLD, HDC, HFONT, HGDIOBJ, NULL_BRUSH, OUT_DEFAULT_PRECIS, PAINTSTRUCT,
        PS_SOLID, TRANSPARENT, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, FF_DONTCARE,
    };
    use windows::Win32::System::DataExchange::{CloseClipboard, EmptyClipboard, OpenClipboard, SetClipboardData};
    use windows::Win32::System::Ole::CF_UNICODETEXT;
    use windows::Win32::System::LibraryLoader::GetModuleHandleW;
    use windows::Win32::System::Memory::{GlobalAlloc, GlobalLock, GlobalUnlock, GMEM_MOVEABLE};
    use windows::Win32::UI::WindowsAndMessaging::{
        CreateWindowExW, DefWindowProcW, DestroyWindow, DispatchMessageW, GetClientRect, GetMessageW,
        GetSystemMetrics, GetWindowLongPtrW, KillTimer, LoadCursorW, PostQuitMessage,
        RegisterClassExW, SetTimer, SetWindowLongPtrW, SetWindowPos, ShowWindow, TranslateMessage,
        CS_HREDRAW, CS_VREDRAW, GWLP_USERDATA, HMENU, HWND_TOPMOST, IDC_ARROW, MSG, SM_CXSCREEN,
        SM_CYSCREEN, SWP_NOMOVE, SWP_NOSIZE, SW_SHOW, WM_CLOSE, WM_DESTROY, WM_ERASEBKGND, WM_LBUTTONDOWN,
        WM_MOUSEMOVE, WM_NCHITTEST, WM_PAINT, WM_TIMER, WM_USER, WNDCLASSEXW, WS_EX_APPWINDOW,
        WS_EX_TOPMOST, WS_POPUP, WS_VISIBLE, HTCAPTION, HTCLIENT,
    };

    const WM_REFRESH: u32 = WM_USER + 201;
    const WM_TIMER_SPIN: usize = 1;
    const WM_TIMER_TICK: usize = 2;
    const TITLE_H: i32 = 36;
    const FOOTER_H: i32 = 26;
    const CLOSE_SZ: i32 = 36;
    const WIN_W: i32 = 460;
    const WIN_H: i32 = 268;

    const CLR_BG: u32 = 0x000A0A08;
    const CLR_TITLE: u32 = 0x00141412;
    const CLR_FOOTER: u32 = 0x0010100E;
    const CLR_TEXT: u32 = 0x00E7E4E4;
    const CLR_MUTED: u32 = 0x00AAA1A1;
    const CLR_ACCENT: u32 = 0x00E7E4E4;
    const CLR_LINK: u32 = 0x00B8B4B4;
    const CLR_LINK_HOVER: u32 = 0x00FFFFFF;
    const CLR_PIN_BG: u32 = 0x001C1C1A;
    const CLR_PIN_BORDER: u32 = 0x003A3838;
    const CLR_BTN_BG: u32 = 0x00282826;
    const CLR_BTN_BORDER: u32 = 0x0040403E;
    const CLR_BTN_HOVER: u32 = 0x00343432;
    const CLR_CLOSE: u32 = 0x00C8C4C4;
    const CLR_CLOSE_HOVER: u32 = 0x00FFFFFF;
    const CLR_CLOSE_BG_HOVER: u32 = 0x00E81123;
    const CLR_BAR_BG: u32 = 0x00242422;
    const CLR_BAR_FILL: u32 = 0x00A8A4A4;

    struct Fonts {
        title: HFONT,
        code: HFONT,
        body: HFONT,
        small: HFONT,
    }

    impl Fonts {
        unsafe fn create() -> Self {
            Self {
                title: create_font(-15, FW_SEMIBOLD, w!("Segoe UI")),
                code: create_font(-24, FW_BOLD, w!("Consolas")),
                body: create_font(-12, FW_NORMAL, w!("Segoe UI")),
                small: create_font(-11, FW_NORMAL, w!("Segoe UI")),
            }
        }

        unsafe fn drop(&self) {
            for f in [self.title, self.code, self.body, self.small] {
                if !f.is_invalid() {
                    let _ = DeleteObject(HGDIOBJ(f.0));
                }
            }
        }
    }

    unsafe fn create_font(
        height: i32,
        weight: windows::Win32::Graphics::Gdi::FONT_WEIGHT,
        face: windows::core::PCWSTR,
    ) -> HFONT {
        CreateFontW(
            height,
            0,
            0,
            0,
            weight.0 as i32,
            0,
            0,
            0,
            DEFAULT_CHARSET.0 as u32,
            OUT_DEFAULT_PRECIS.0 as u32,
            CLIP_DEFAULT_PRECIS.0 as u32,
            DEFAULT_QUALITY.0 as u32,
            FF_DONTCARE.0 as u32,
            face,
        )
    }

    struct Ctx {
        state: Arc<Mutex<PairUiState>>,
        fonts: Fonts,
        close_hover: bool,
        copy_hover: bool,
        link_hover: bool,
        copied_until: Option<Instant>,
        last_expire_secs: u64,
        last_bar_px: i32,
    }

    fn footer_link_rect(rc: &RECT) -> RECT {
        RECT {
            left: 8,
            top: rc.bottom - FOOTER_H,
            right: 120,
            bottom: rc.bottom,
        }
    }

    fn progress_area_rect(rc: &RECT) -> RECT {
        RECT {
            left: 0,
            top: rc.bottom - FOOTER_H - 40,
            right: rc.right,
            bottom: rc.bottom - FOOTER_H,
        }
    }

    fn progress_inner_width(rc: &RECT) -> i32 {
        rc.right - 56
    }

    unsafe fn open_url(url: &str) {
        use windows::core::w;
        use windows::Win32::UI::Shell::ShellExecuteW;
        use windows::Win32::UI::WindowsAndMessaging::SW_SHOWNORMAL;
        let wide: Vec<u16> = url.encode_utf16().chain([0]).collect();
        let _ = ShellExecuteW(None, w!("open"), windows::core::PCWSTR(wide.as_ptr()), None, None, SW_SHOWNORMAL);
    }

    unsafe fn ctx_get(hwnd: HWND) -> Option<&'static mut Ctx> {
        let ptr = GetWindowLongPtrW(hwnd, GWLP_USERDATA) as *mut Ctx;
        if ptr.is_null() {
            None
        } else {
            Some(&mut *ptr)
        }
    }

    fn close_rect(rc: &RECT) -> RECT {
        RECT {
            left: rc.right - CLOSE_SZ,
            top: 0,
            right: rc.right,
            bottom: TITLE_H,
        }
    }

    fn copy_rect(rc: &RECT) -> RECT {
        let w = 76i32;
        let h = 28i32;
        RECT {
            left: (rc.right - w) / 2,
            top: 124,
            right: (rc.right + w) / 2,
            bottom: 124 + h,
        }
    }

    fn spinner_rect(rc: &RECT) -> RECT {
        RECT {
            left: rc.right / 2 - 40,
            top: 52,
            right: rc.right / 2 + 40,
            bottom: 132,
        }
    }

    fn bottom_rect(rc: &RECT) -> RECT {
        RECT {
            left: 0,
            top: rc.bottom - FOOTER_H - 44,
            right: rc.right,
            bottom: rc.bottom,
        }
    }

    fn footer_rect(rc: &RECT) -> RECT {
        RECT {
            left: 0,
            top: rc.bottom - FOOTER_H,
            right: rc.right,
            bottom: rc.bottom,
        }
    }

    fn in_rect(pt: POINT, r: &RECT) -> bool {
        pt.x >= r.left && pt.x < r.right && pt.y >= r.top && pt.y < r.bottom
    }

    fn wide(s: &str) -> Vec<u16> {
        s.encode_utf16().collect()
    }

    unsafe fn invalidate(hwnd: HWND, r: Option<RECT>) {
        let ptr = r.as_ref().map(|rc| rc as *const RECT);
        let _ = InvalidateRect(hwnd, ptr, false);
    }

    unsafe fn draw_text(hdc: HDC, font: HFONT, color: u32, text: &str, rc: RECT, flags: DRAW_TEXT_FORMAT) {
        if text.is_empty() {
            return;
        }
        let old_font = SelectObject(hdc, HGDIOBJ(font.0));
        SetBkMode(hdc, TRANSPARENT);
        SetTextColor(hdc, COLORREF(color));
        let mut wide = wide(text);
        let mut rc = rc;
        let _ = DrawTextW(hdc, &mut wide, &mut rc, flags);
        SelectObject(hdc, old_font);
    }

    unsafe fn draw_round_btn(hdc: HDC, rc: &RECT, hover: bool, _label: &str) {
        let pen = CreatePen(PS_SOLID, 1, COLORREF(CLR_BTN_BORDER));
        let brush = CreateSolidBrush(COLORREF(if hover { CLR_BTN_HOVER } else { CLR_BTN_BG }));
        let old_pen = SelectObject(hdc, HGDIOBJ(pen.0));
        let old_brush = SelectObject(hdc, HGDIOBJ(brush.0));
        let _ = RoundRect(hdc, rc.left, rc.top, rc.right, rc.bottom, 6, 6);
        SelectObject(hdc, old_brush);
        SelectObject(hdc, old_pen);
        let _ = DeleteObject(HGDIOBJ(brush.0));
        let _ = DeleteObject(HGDIOBJ(pen.0));
    }

    unsafe fn draw_spinner(hdc: HDC, cx: i32, cy: i32, r: i32, frame: u8) {
        let pen = CreatePen(PS_SOLID, 2, COLORREF(CLR_ACCENT));
        let hollow = SelectObject(hdc, GetStockObject(NULL_BRUSH));
        let old_pen = SelectObject(hdc, HGDIOBJ(pen.0));
        let _ = Ellipse(hdc, cx - r, cy - r, cx + r, cy + r);
        let angle = (frame as f32) * 45.0;
        let rad = angle.to_radians();
        let x1 = cx + (r as f32 * rad.cos()) as i32;
        let y1 = cy + (r as f32 * rad.sin()) as i32;
        let x2 = cx + (r as f32 * (rad + 1.2).cos()) as i32;
        let y2 = cy + (r as f32 * (rad + 1.2).sin()) as i32;
        let accent_pen = CreatePen(PS_SOLID, 3, COLORREF(CLR_TEXT));
        SelectObject(hdc, HGDIOBJ(accent_pen.0));
        let mut pt = POINT::default();
        let _ = MoveToEx(hdc, x1, y1, Some(&mut pt));
        let _ = LineTo(hdc, x2, y2);
        SelectObject(hdc, old_pen);
        SelectObject(hdc, hollow);
        let _ = DeleteObject(HGDIOBJ(pen.0));
        let _ = DeleteObject(HGDIOBJ(accent_pen.0));
    }

    unsafe fn draw_pin_boxes(hdc: HDC, font: HFONT, rc: &RECT, code: &str) {
        if !code_is_pin(code) {
            return;
        }
        let parts: Vec<&str> = code.split('-').collect();
        let box_w = 34i32;
        let box_h = 42i32;
        let gap = 5i32;
        let group_gap = 14i32;
        let chars1: Vec<char> = parts[0].chars().collect();
        let chars2: Vec<char> = parts[1].chars().collect();
        let count = (chars1.len() + chars2.len()) as i32;
        let total_w = count * box_w + (count - 1) * gap + group_gap;
        let mut x = (rc.right - total_w) / 2;
        let y = 48i32;

        let pen = CreatePen(PS_SOLID, 1, COLORREF(CLR_PIN_BORDER));
        let brush = CreateSolidBrush(COLORREF(CLR_PIN_BG));
        let old_pen = SelectObject(hdc, HGDIOBJ(pen.0));
        let old_brush = SelectObject(hdc, HGDIOBJ(brush.0));

        for (i, ch) in chars1.iter().chain(chars2.iter()).enumerate() {
            if i == chars1.len() {
                x += group_gap - gap;
            }
            let box_rc = RECT {
                left: x,
                top: y,
                right: x + box_w,
                bottom: y + box_h,
            };
            let _ = RoundRect(hdc, box_rc.left, box_rc.top, box_rc.right, box_rc.bottom, 6, 6);
            draw_text(
                hdc,
                font,
                CLR_ACCENT,
                &ch.to_string(),
                box_rc,
                DT_CENTER | DT_SINGLELINE | DT_VCENTER,
            );
            x += box_w + gap;
        }

        SelectObject(hdc, old_brush);
        SelectObject(hdc, old_pen);
        let _ = DeleteObject(HGDIOBJ(brush.0));
        let _ = DeleteObject(HGDIOBJ(pen.0));
    }

    unsafe fn draw_progress(hdc: HDC, rc: &RECT, remain: Duration, total: Duration) {
        let margin = 28i32;
        let bar_h = 4i32;
        let y = rc.bottom - FOOTER_H - 16;
        let bar_rc = RECT {
            left: margin,
            top: y,
            right: rc.right - margin,
            bottom: y + bar_h,
        };
        let bg = CreateSolidBrush(COLORREF(CLR_BAR_BG));
        let _ = FillRect(hdc, &bar_rc, bg);
        let _ = DeleteObject(HGDIOBJ(bg.0));

        let frac = if total.is_zero() {
            0.0
        } else {
            (remain.as_secs_f32() / total.as_secs_f32()).clamp(0.0, 1.0)
        };
        let fill_w = ((bar_rc.right - bar_rc.left) as f32 * frac) as i32;
        if fill_w > 0 {
            let fill_rc = RECT {
                left: bar_rc.left,
                top: bar_rc.top,
                right: bar_rc.left + fill_w,
                bottom: bar_rc.bottom,
            };
            let fill = CreateSolidBrush(COLORREF(CLR_BAR_FILL));
            let _ = FillRect(hdc, &fill_rc, fill);
            let _ = DeleteObject(HGDIOBJ(fill.0));
        }
    }

    unsafe fn copy_code_to_clipboard(hwnd: HWND, code: &str) -> bool {
        let wide: Vec<u16> = code.encode_utf16().chain([0]).collect();
        let bytes = wide.len() * 2;
        if OpenClipboard(hwnd).is_err() {
            return false;
        }
        let _ = EmptyClipboard();
        let hmem = match GlobalAlloc(GMEM_MOVEABLE, bytes) {
            Ok(h) => h,
            Err(_) => {
                let _ = CloseClipboard();
                return false;
            }
        };
        let ptr = GlobalLock(hmem);
        if ptr.is_null() {
            let _ = CloseClipboard();
            return false;
        }
        std::ptr::copy_nonoverlapping(wide.as_ptr() as *const u8, ptr as *mut u8, bytes);
        let _ = GlobalUnlock(hmem);
        let ok = SetClipboardData(CF_UNICODETEXT.0 as u32, HANDLE(hmem.0)).is_ok();
        let _ = CloseClipboard();
        ok
    }

    unsafe fn paint_pair(hwnd: HWND, hdc: HDC) {
        let ctx = match ctx_get(hwnd) {
            Some(c) => c,
            None => return,
        };

        let snap = {
            let g = ctx.state.lock().unwrap();
            g.clone()
        };

        let mut rc = RECT::default();
        let _ = GetClientRect(hwnd, &mut rc);

        let bg = CreateSolidBrush(COLORREF(CLR_BG));
        let _ = FillRect(hdc, &rc, bg);
        let _ = DeleteObject(HGDIOBJ(bg.0));

        let title_bg = CreateSolidBrush(COLORREF(CLR_TITLE));
        let title_rc = RECT { left: 0, top: 0, right: rc.right, bottom: TITLE_H };
        let _ = FillRect(hdc, &title_rc, title_bg);
        let _ = DeleteObject(HGDIOBJ(title_bg.0));

        let footer_bg = CreateSolidBrush(COLORREF(CLR_FOOTER));
        let ftr = footer_rect(&rc);
        let _ = FillRect(hdc, &ftr, footer_bg);
        let _ = DeleteObject(HGDIOBJ(footer_bg.0));

        let close = close_rect(&rc);
        if ctx.close_hover {
            let hover = CreateSolidBrush(COLORREF(CLR_CLOSE_BG_HOVER));
            let _ = FillRect(hdc, &close, hover);
            let _ = DeleteObject(HGDIOBJ(hover.0));
        }

        draw_text(
            hdc,
            ctx.fonts.title,
            if ctx.close_hover { CLR_CLOSE_HOVER } else { CLR_CLOSE },
            "X",
            close,
            DT_CENTER | DT_SINGLELINE | DT_VCENTER,
        );
        draw_text(
            hdc,
            ctx.fonts.title,
            CLR_TEXT,
            WINDOW_TITLE,
            RECT {
                left: 14,
                top: 0,
                right: rc.right - CLOSE_SZ,
                bottom: TITLE_H,
            },
            DT_SINGLELINE | DT_VCENTER,
        );

        draw_text(
            hdc,
            ctx.fonts.small,
            if ctx.link_hover { CLR_LINK_HOVER } else { CLR_LINK },
            "alienai.id",
            footer_link_rect(&rc),
            DT_SINGLELINE | DT_VCENTER,
        );
        let ver = agent_version_label();
        draw_text(
            hdc,
            ctx.fonts.small,
            CLR_MUTED,
            &ver,
            RECT {
                left: rc.right / 2,
                top: ftr.top,
                right: rc.right - 14,
                bottom: ftr.bottom,
            },
            DRAW_TEXT_FORMAT(DT_RIGHT.0 | DT_SINGLELINE.0 | DT_VCENTER.0),
        );

        if snap.phase == PairPhase::Connecting {
            draw_spinner(hdc, rc.right / 2, 88, 18, snap.spinner);
            draw_text(
                hdc,
                ctx.fonts.body,
                CLR_MUTED,
                &snap.status,
                RECT {
                    left: 24,
                    top: 112,
                    right: rc.right - 24,
                    bottom: 156,
                },
                DT_CENTER | DT_WORDBREAK,
            );
            return;
        }

        if snap.phase == PairPhase::Code {
            draw_pin_boxes(hdc, ctx.fonts.code, &rc, &snap.code);
        }

        if snap.phase == PairPhase::Code && code_is_pin(&snap.code) {
            let copy = copy_rect(&rc);
            let copied = ctx.copied_until.is_some_and(|t| t > Instant::now());
            let label = if copied { "Copied!" } else { "Copy" };
            draw_round_btn(hdc, &copy, ctx.copy_hover || copied, label);
            draw_text(
                hdc,
                ctx.fonts.body,
                if copied { CLR_ACCENT } else { CLR_TEXT },
                label,
                copy,
                DT_CENTER | DT_SINGLELINE | DT_VCENTER,
            );
        }

        draw_text(
            hdc,
            ctx.fonts.body,
            CLR_MUTED,
            &snap.status,
            RECT {
                left: 24,
                top: 94,
                right: rc.right - 24,
                bottom: 122,
            },
            DT_CENTER | DT_WORDBREAK,
        );

        let remain = snap
            .deadline
            .map(|d| d.saturating_duration_since(Instant::now()))
            .unwrap_or(Duration::ZERO);
        let secs = remain.as_secs();
        if snap.deadline.is_some() {
            let expire = format!("Code Refresh in {}:{:02}", secs / 60, secs % 60);
            draw_text(
                hdc,
                ctx.fonts.body,
                CLR_MUTED,
                &expire,
                RECT {
                    left: 24,
                    top: rc.bottom - FOOTER_H - 36,
                    right: rc.right - 24,
                    bottom: rc.bottom - FOOTER_H - 20,
                },
                DT_CENTER | DT_SINGLELINE,
            );
            draw_progress(hdc, &rc, remain, snap.expires_total);
        }
    }

    unsafe extern "system" fn window_proc(hwnd: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) -> LRESULT {
        match msg {
            WM_ERASEBKGND => LRESULT(1),
            WM_REFRESH => {
                let full = wparam.0 != 0;
                if full {
                    invalidate(hwnd, None);
                } else {
                    let mut rc = RECT::default();
                    let _ = GetClientRect(hwnd, &mut rc);
                    invalidate(hwnd, Some(bottom_rect(&rc)));
                }
                LRESULT(0)
            }
            WM_PAINT => {
                let mut ps = PAINTSTRUCT::default();
                let hdc = BeginPaint(hwnd, &mut ps);
                paint_pair(hwnd, hdc);
                let _ = EndPaint(hwnd, &ps);
                LRESULT(0)
            }
            WM_TIMER if wparam.0 == WM_TIMER_SPIN => {
                if let Some(ctx) = ctx_get(hwnd) {
                    if ctx.state.lock().unwrap().phase == PairPhase::Connecting {
                        let mut g = ctx.state.lock().unwrap();
                        g.spinner = (g.spinner + 1) % 8;
                        let mut rc = RECT::default();
                        let _ = GetClientRect(hwnd, &mut rc);
                        invalidate(hwnd, Some(spinner_rect(&rc)));
                    }
                }
                LRESULT(0)
            }
            WM_TIMER if wparam.0 == WM_TIMER_TICK => {
                if let Some(ctx) = ctx_get(hwnd) {
                    if ctx.copied_until.is_some_and(|t| t <= Instant::now()) {
                        ctx.copied_until = None;
                        let mut rc = RECT::default();
                        let _ = GetClientRect(hwnd, &mut rc);
                        invalidate(hwnd, Some(copy_rect(&rc)));
                    }
                    let snap = ctx.state.lock().unwrap().clone();
                    if snap.phase == PairPhase::Code {
                        if let Some(deadline) = snap.deadline {
                            let remain = deadline.saturating_duration_since(Instant::now());
                            let secs = remain.as_secs();
                            let total = snap.expires_total.as_secs().max(1);
                            let mut rc = RECT::default();
                            let _ = GetClientRect(hwnd, &mut rc);
                            let inner = progress_inner_width(&rc);
                            let fill_w = ((inner as f32) * (remain.as_secs_f32() / total as f32)).clamp(0.0, inner as f32) as i32;
                            if secs != ctx.last_expire_secs || fill_w != ctx.last_bar_px {
                                ctx.last_expire_secs = secs;
                                ctx.last_bar_px = fill_w;
                                let mut rc = RECT::default();
                                let _ = GetClientRect(hwnd, &mut rc);
                                invalidate(hwnd, Some(progress_area_rect(&rc)));
                            }
                        }
                    }
                }
                LRESULT(0)
            }
            WM_NCHITTEST => {
                let mut rc = RECT::default();
                let _ = GetClientRect(hwnd, &mut rc);
                let mut pt = POINT {
                    x: (lparam.0 & 0xFFFF) as i16 as i32,
                    y: ((lparam.0 >> 16) & 0xFFFF) as i16 as i32,
                };
                let _ = ScreenToClient(hwnd, &mut pt);
                if in_rect(pt, &close_rect(&rc)) {
                    return LRESULT(HTCLIENT as isize);
                }
                if pt.y < TITLE_H {
                    return LRESULT(HTCAPTION as isize);
                }
                LRESULT(HTCLIENT as isize)
            }
            WM_MOUSEMOVE => {
                let mut rc = RECT::default();
                let _ = GetClientRect(hwnd, &mut rc);
                let pt = POINT {
                    x: (lparam.0 & 0xFFFF) as i16 as i32,
                    y: ((lparam.0 >> 16) & 0xFFFF) as i16 as i32,
                };
                if let Some(ctx) = ctx_get(hwnd) {
                    let close_hover = in_rect(pt, &close_rect(&rc));
                    let copy_hover = in_rect(pt, &copy_rect(&rc));
                    let link_hover = in_rect(pt, &footer_link_rect(&rc));
                    if ctx.close_hover != close_hover {
                        ctx.close_hover = close_hover;
                        invalidate(hwnd, Some(close_rect(&rc)));
                    }
                    if ctx.copy_hover != copy_hover {
                        ctx.copy_hover = copy_hover;
                        invalidate(hwnd, Some(copy_rect(&rc)));
                    }
                    if ctx.link_hover != link_hover {
                        ctx.link_hover = link_hover;
                        invalidate(hwnd, Some(footer_rect(&rc)));
                    }
                }
                LRESULT(0)
            }
            WM_LBUTTONDOWN => {
                let mut rc = RECT::default();
                let _ = GetClientRect(hwnd, &mut rc);
                let pt = POINT {
                    x: (lparam.0 & 0xFFFF) as i16 as i32,
                    y: ((lparam.0 >> 16) & 0xFFFF) as i16 as i32,
                };
                if in_rect(pt, &close_rect(&rc)) {
                    let _ = PostQuitMessage(0);
                    return LRESULT(0);
                }
                if in_rect(pt, &copy_rect(&rc)) {
                    if let Some(ctx) = ctx_get(hwnd) {
                        let code = ctx.state.lock().unwrap().code.clone();
                        if code_is_pin(&code) && copy_code_to_clipboard(hwnd, &code) {
                            ctx.copied_until = Some(Instant::now() + Duration::from_secs(2));
                            invalidate(hwnd, Some(copy_rect(&rc)));
                        }
                    }
                }
                if in_rect(pt, &footer_link_rect(&rc)) {
                    open_url(SITE_URL);
                }
                LRESULT(0)
            }
            WM_CLOSE => {
                let _ = KillTimer(hwnd, WM_TIMER_SPIN);
                let _ = KillTimer(hwnd, WM_TIMER_TICK);
                let _ = DestroyWindow(hwnd);
                LRESULT(0)
            }
            WM_DESTROY => {
                let ptr = GetWindowLongPtrW(hwnd, GWLP_USERDATA) as *mut Ctx;
                if !ptr.is_null() {
                    let boxed = Box::from_raw(ptr);
                    boxed.fonts.drop();
                    SetWindowLongPtrW(hwnd, GWLP_USERDATA, 0);
                }
                PostQuitMessage(0);
                LRESULT(0)
            }
            _ => DefWindowProcW(hwnd, msg, wparam, lparam),
        }
    }

    unsafe {
        let hinstance = GetModuleHandleW(None)?.into();
        let class_name = w!("AlienAIPairWindowV3");
        let app_icon = crate::icon::load_app_icon(32, 32);
        let wnd_class = WNDCLASSEXW {
            cbSize: std::mem::size_of::<WNDCLASSEXW>() as u32,
            style: CS_HREDRAW | CS_VREDRAW,
            lpfnWndProc: Some(window_proc),
            hInstance: hinstance,
            hIcon: app_icon,
            hCursor: LoadCursorW(None, IDC_ARROW).unwrap_or_default(),
            lpszClassName: class_name,
            ..Default::default()
        };
        let _ = RegisterClassExW(&wnd_class);

        let cw = GetSystemMetrics(SM_CXSCREEN);
        let ch = GetSystemMetrics(SM_CYSCREEN);
        let hwnd = CreateWindowExW(
            WS_EX_TOPMOST | WS_EX_APPWINDOW,
            class_name,
            w!("Alien AI - Pair Device"),
            WS_POPUP | WS_VISIBLE,
            (cw - WIN_W) / 2,
            (ch - WIN_H) / 2,
            WIN_W,
            WIN_H,
            HWND::default(),
            HMENU::default(),
            hinstance,
            None,
        )?;

        let ctx = Box::new(Ctx {
            state: state.clone(),
            fonts: Fonts::create(),
            close_hover: false,
            copy_hover: false,
            link_hover: false,
            copied_until: None,
            last_expire_secs: u64::MAX,
            last_bar_px: -1,
        });
        SetWindowLongPtrW(hwnd, GWLP_USERDATA, Box::into_raw(ctx) as isize);

        use windows::Win32::Foundation::WPARAM;
        use windows::Win32::UI::WindowsAndMessaging::{SendMessageW, WM_SETICON, ICON_BIG, ICON_SMALL};
        let _ = SendMessageW(hwnd, WM_SETICON, WPARAM(ICON_BIG as usize), LPARAM(app_icon.0 as isize));
        let _ = SendMessageW(hwnd, WM_SETICON, WPARAM(ICON_SMALL as usize), LPARAM(app_icon.0 as isize));

        *hwnd_slot.lock().unwrap() = hwnd.0 as isize;
        let _ = SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
        let _ = ShowWindow(hwnd, SW_SHOW);
        let _ = SetTimer(hwnd, WM_TIMER_SPIN, 250, None);
        let _ = SetTimer(hwnd, WM_TIMER_TICK, 1000, None);

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

        *hwnd_slot.lock().unwrap() = 0;
    }
    Ok(())
}
