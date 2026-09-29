#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct PxRect {
    pub x: i32,
    pub y: i32,
    pub w: i32,
    pub h: i32,
}

impl PxRect {
    pub fn contains(self, px: i32, py: i32) -> bool {
        px >= self.x && py >= self.y && px < self.x + self.w && py < self.y + self.h
    }

    pub fn from_ltrb(l: i32, t: i32, r: i32, b: i32) -> Self {
        Self { x: l, y: t, w: (r - l).max(0), h: (b - t).max(0) }
    }

    pub fn offset(self, ox: i32, oy: i32) -> Self {
        Self { x: self.x + ox, y: self.y + oy, w: self.w, h: self.h }
    }
}

pub const CHIP_W: i32 = 380;
pub const CHIP_H: i32 = 52;
pub const CHIP_MARGIN: i32 = 16;
pub const STOP_W: i32 = 68;
pub const STOP_H: i32 = 32;
pub const BORDER_THICKNESS: i32 = 4;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ChipHit {
    Outside,
    Body,
    Stop,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TeachClick {
    Record,
    Ignore,
    Stop,
}

pub fn chip_stop_local() -> PxRect {
    PxRect { x: CHIP_W - STOP_W - 10, y: (CHIP_H - STOP_H) / 2, w: STOP_W, h: STOP_H }
}

pub fn chip_screen_rect(_screen_w: i32, _screen_h: i32) -> PxRect {
    // Top-left corner as requested
    PxRect { x: CHIP_MARGIN, y: CHIP_MARGIN, w: CHIP_W, h: CHIP_H }
}

pub fn chip_hit(win: PxRect, stop_local: PxRect, x: i32, y: i32) -> ChipHit {
    if !win.contains(x, y) {
        return ChipHit::Outside;
    }
    if stop_local.offset(win.x, win.y).contains(x, y) {
        return ChipHit::Stop;
    }
    ChipHit::Body
}

pub fn classify_click(hit: ChipHit, on_agent_ui: bool) -> TeachClick {
    match hit {
        ChipHit::Stop => TeachClick::Stop,
        ChipHit::Body => TeachClick::Ignore,
        ChipHit::Outside if on_agent_ui => TeachClick::Ignore,
        ChipHit::Outside => TeachClick::Record,
    }
}

pub fn click_label(window: &str, name: &str) -> String {
    let control = if name.trim().is_empty() { "a control" } else { name.trim() };
    let w = window.trim();
    if w.is_empty() {
        format!("Click {control}")
    } else {
        format!("In {w}, click {control}")
    }
}

pub fn type_label(window: &str, field: &str, text: &str, is_password: bool, enter: bool) -> String {
    let field = if field.trim().is_empty() { "the field" } else { field.trim() };
    let verb = if is_password {
        format!("fill password in {field}")
    } else if text.len() > 40 {
        format!("fill {field} with text")
    } else {
        format!("fill {field} with \"{text}\"")
    };
    let loc = if window.trim().is_empty() {
        let mut c = verb.chars();
        match c.next() {
            Some(ch) => format!("{}{}", ch.to_uppercase(), c.as_str()),
            None => verb,
        }
    } else {
        format!("In {}, {verb}", window.trim())
    };
    if enter { format!("{loc}, then press Enter") } else { loc }
}

pub fn overlay_hit(x: i32, y: i32) -> ChipHit {
    #[cfg(target_os = "windows")]
    {
        win::hit(x, y)
    }
    #[cfg(not(target_os = "windows"))]
    {
        let _ = (x, y);
        ChipHit::Outside
    }
}

pub fn overlay_is_agent_ui(x: i32, y: i32) -> bool {
    #[cfg(target_os = "windows")]
    {
        win::is_agent_ui(x, y)
    }
    #[cfg(not(target_os = "windows"))]
    {
        let _ = (x, y);
        false
    }
}

pub fn overlay_show(title: &str) {
    #[cfg(target_os = "windows")]
    win::show(title);
    #[cfg(not(target_os = "windows"))]
    let _ = title;
}

pub fn overlay_hide() {
    #[cfg(target_os = "windows")]
    win::hide();
}

pub fn overlay_set_last(ord: i32, label: &str) {
    #[cfg(target_os = "windows")]
    win::set_last(ord, label);
    #[cfg(not(target_os = "windows"))]
    let _ = (ord, label);
}

// ============================================================= Windows Native Win32 Impl
#[cfg(target_os = "windows")]
mod win {
    use super::*;
    use std::sync::{Mutex, OnceLock};
    use windows_sys::Win32::Foundation::{HWND, LPARAM, LRESULT, POINT, RECT, WPARAM};
    use windows_sys::Win32::Graphics::Gdi::{
        BeginPaint, CreateSolidBrush, DeleteObject, DrawTextW, EndPaint, FillRect, InvalidateRect,
        SetBkMode, SetTextColor, DT_CENTER, DT_END_ELLIPSIS, DT_SINGLELINE, DT_VCENTER, HDC,
        HGDIOBJ, PAINTSTRUCT, TRANSPARENT,
    };
    use windows_sys::Win32::UI::WindowsAndMessaging::{
        CreateWindowExW, DefWindowProcW, DestroyWindow, DispatchMessageW, GetAncestor,
        GetClassNameW, GetClientRect, GetMessageW, GetSystemMetrics, GetWindowRect, GetWindowTextW,
        LoadCursorW, PostMessageW, PostQuitMessage, RegisterClassExW, SetLayeredWindowAttributes,
        SetWindowPos, ShowWindow, TranslateMessage, WindowFromPoint, CS_HREDRAW, CS_VREDRAW,
        GA_ROOT, HWND_TOPMOST, IDC_ARROW, LWA_ALPHA, LWA_COLORKEY, MA_NOACTIVATE, MSG,
        SM_CXSCREEN, SM_CYSCREEN, SW_HIDE, SW_SHOWNOACTIVATE, SWP_NOACTIVATE, SWP_SHOWWINDOW,
        WM_CLOSE, WM_DESTROY, WM_LBUTTONDOWN, WM_MOUSEACTIVATE, WM_PAINT, WNDCLASSEXW,
        WS_EX_LAYERED, WS_EX_NOACTIVATE, WS_EX_TOOLWINDOW, WS_EX_TOPMOST, WS_EX_TRANSPARENT,
        WS_POPUP,
    };

    const WM_CHIP_UPDATE: u32 = 0x0401;

    struct OverlayUi {
        chip_hwnd: isize,
        border_hwnd: isize,
        title: String,
        ord: i32,
        label: String,
    }

    static OVERLAY: OnceLock<Mutex<OverlayUi>> = OnceLock::new();

    fn state() -> &'static Mutex<OverlayUi> {
        OVERLAY.get_or_init(|| {
            Mutex::new(OverlayUi {
                chip_hwnd: 0,
                border_hwnd: 0,
                title: String::new(),
                ord: 0,
                label: String::new(),
            })
        })
    }

    pub fn hit(x: i32, y: i32) -> ChipHit {
        let hwnd = state().lock().unwrap().chip_hwnd;
        if hwnd == 0 {
            return ChipHit::Outside;
        }
        let mut rc = RECT { left: 0, top: 0, right: 0, bottom: 0 };
        unsafe {
            if GetWindowRect(hwnd as HWND, &mut rc) == 0 {
                return ChipHit::Outside;
            }
        }
        chip_hit(PxRect::from_ltrb(rc.left, rc.top, rc.right, rc.bottom), chip_stop_local(), x, y)
    }

    pub fn is_agent_ui(x: i32, y: i32) -> bool {
        unsafe {
            let hwnd = WindowFromPoint(POINT { x, y });
            if hwnd.is_null() {
                return false;
            }
            if class_of(hwnd) == "AlienAITeachChip" || class_of(hwnd) == "AlienAITeachBorder" {
                return true;
            }
            let root = GetAncestor(hwnd, GA_ROOT);
            let check = if root.is_null() { hwnd } else { root };
            let title = title_of(check);
            title.contains("Alien AI Agent") || class_of(check) == "AlienAITeachChip"
        }
    }

    fn class_of(hwnd: HWND) -> String {
        let mut buf = [0u16; 128];
        let n = unsafe { GetClassNameW(hwnd, buf.as_mut_ptr(), buf.len() as i32) };
        if n <= 0 {
            return String::new();
        }
        String::from_utf16_lossy(&buf[..n as usize])
    }

    fn title_of(hwnd: HWND) -> String {
        let mut buf = [0u16; 256];
        let n = unsafe { GetWindowTextW(hwnd, buf.as_mut_ptr(), buf.len() as i32) };
        if n <= 0 {
            return String::new();
        }
        String::from_utf16_lossy(&buf[..n as usize])
    }

    pub fn show(title: &str) {
        {
            let mut g = state().lock().unwrap();
            g.title = title.to_string();
            g.ord = 0;
            g.label = "Show me the steps...".into();
            if g.chip_hwnd != 0 && g.border_hwnd != 0 {
                invalidate(g.chip_hwnd);
                unsafe {
                    ShowWindow(g.border_hwnd as HWND, SW_SHOWNOACTIVATE);
                    ShowWindow(g.chip_hwnd as HWND, SW_SHOWNOACTIVATE);
                }
                return;
            }
        }
        let _ = std::thread::Builder::new()
            .name("teach-overlay".into())
            .spawn(run_overlay_thread);
    }

    pub fn hide() {
        let (chip, border) = {
            let g = state().lock().unwrap();
            (g.chip_hwnd, g.border_hwnd)
        };
        unsafe {
            if border != 0 {
                ShowWindow(border as HWND, SW_HIDE);
            }
            if chip != 0 {
                ShowWindow(chip as HWND, SW_HIDE);
            }
        }
    }

    pub fn set_last(ord: i32, label: &str) {
        let hwnd = {
            let mut g = state().lock().unwrap();
            g.ord = ord;
            g.label = label.to_string();
            g.chip_hwnd
        };
        if hwnd != 0 {
            invalidate(hwnd);
        }
    }

    fn invalidate(hwnd: isize) {
        unsafe {
            InvalidateRect(hwnd as HWND, std::ptr::null(), 1);
            PostMessageW(hwnd as HWND, WM_CHIP_UPDATE, 0, 0);
        }
    }

    fn wide_null(s: &str) -> Vec<u16> {
        s.encode_utf16().chain(std::iter::once(0)).collect()
    }

    fn run_overlay_thread() {
        unsafe {
            let chip_class = wide_null("AlienAITeachChip");
            let border_class = wide_null("AlienAITeachBorder");

            let chip_wnd_class = WNDCLASSEXW {
                cbSize: std::mem::size_of::<WNDCLASSEXW>() as u32,
                style: CS_HREDRAW | CS_VREDRAW,
                lpfnWndProc: Some(chip_window_proc),
                cbClsExtra: 0,
                cbWndExtra: 0,
                hInstance: 0 as _,
                hIcon: 0 as _,
                hCursor: LoadCursorW(0 as _, IDC_ARROW),
                hbrBackground: 0 as _,
                lpszMenuName: std::ptr::null(),
                lpszClassName: chip_class.as_ptr(),
                hIconSm: 0 as _,
            };
            RegisterClassExW(&chip_wnd_class);

            let border_wnd_class = WNDCLASSEXW {
                cbSize: std::mem::size_of::<WNDCLASSEXW>() as u32,
                style: CS_HREDRAW | CS_VREDRAW,
                lpfnWndProc: Some(border_window_proc),
                cbClsExtra: 0,
                cbWndExtra: 0,
                hInstance: 0 as _,
                hIcon: 0 as _,
                hCursor: LoadCursorW(0 as _, IDC_ARROW),
                hbrBackground: 0 as _,
                lpszMenuName: std::ptr::null(),
                lpszClassName: border_class.as_ptr(),
                hIconSm: 0 as _,
            };
            RegisterClassExW(&border_wnd_class);

            let screen_w = GetSystemMetrics(SM_CXSCREEN);
            let screen_h = GetSystemMetrics(SM_CYSCREEN);

            // 1. Green Screen-Edge Border Window (fullscreen, 100% click-through)
            let border_title = wide_null("Alien AI Teach Border");
            let border_hwnd = CreateWindowExW(
                WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE | WS_EX_LAYERED | WS_EX_TRANSPARENT,
                border_class.as_ptr(),
                border_title.as_ptr(),
                WS_POPUP,
                0,
                0,
                screen_w,
                screen_h,
                0 as _,
                0 as _,
                0 as _,
                std::ptr::null(),
            );

            if !border_hwnd.is_null() {
                // Color key 0x00000000 (pure black) is transparent
                SetLayeredWindowAttributes(border_hwnd, 0x00000000, 0, LWA_COLORKEY);
                SetWindowPos(
                    border_hwnd,
                    HWND_TOPMOST,
                    0,
                    0,
                    screen_w,
                    screen_h,
                    SWP_NOACTIVATE | SWP_SHOWWINDOW,
                );
                ShowWindow(border_hwnd, SW_SHOWNOACTIVATE);
                state().lock().unwrap().border_hwnd = border_hwnd as isize;
            }

            // 2. Top-Left HUD Chip Window (x: 16, y: 16, clickable Stop button)
            let chip_title = wide_null("Alien AI Teach Chip");
            let pos = chip_screen_rect(screen_w, screen_h);
            let chip_hwnd = CreateWindowExW(
                WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE | WS_EX_LAYERED,
                chip_class.as_ptr(),
                chip_title.as_ptr(),
                WS_POPUP,
                pos.x,
                pos.y,
                pos.w,
                pos.h,
                0 as _,
                0 as _,
                0 as _,
                std::ptr::null(),
            );

            if !chip_hwnd.is_null() {
                SetLayeredWindowAttributes(chip_hwnd, 0, 245, LWA_ALPHA);
                SetWindowPos(
                    chip_hwnd,
                    HWND_TOPMOST,
                    pos.x,
                    pos.y,
                    pos.w,
                    pos.h,
                    SWP_NOACTIVATE | SWP_SHOWWINDOW,
                );
                ShowWindow(chip_hwnd, SW_SHOWNOACTIVATE);
                state().lock().unwrap().chip_hwnd = chip_hwnd as isize;
            }

            let mut msg: MSG = std::mem::zeroed();
            while GetMessageW(&mut msg, 0 as _, 0, 0) > 0 {
                TranslateMessage(&msg);
                DispatchMessageW(&msg);
            }

            {
                let mut g = state().lock().unwrap();
                g.chip_hwnd = 0;
                g.border_hwnd = 0;
            }
            if !chip_hwnd.is_null() {
                DestroyWindow(chip_hwnd);
            }
            if !border_hwnd.is_null() {
                DestroyWindow(border_hwnd);
            }
        }
    }

    unsafe extern "system" fn border_window_proc(
        hwnd: HWND,
        msg: u32,
        wparam: WPARAM,
        lparam: LPARAM,
    ) -> LRESULT {
        match msg {
            WM_MOUSEACTIVATE => MA_NOACTIVATE as LRESULT,
            WM_PAINT => {
                let mut ps: PAINTSTRUCT = std::mem::zeroed();
                let hdc = BeginPaint(hwnd, &mut ps);
                paint_border(hwnd, hdc);
                EndPaint(hwnd, &ps);
                0
            }
            WM_CLOSE | WM_DESTROY => {
                PostQuitMessage(0);
                0
            }
            _ => DefWindowProcW(hwnd, msg, wparam, lparam),
        }
    }

    unsafe extern "system" fn chip_window_proc(
        hwnd: HWND,
        msg: u32,
        wparam: WPARAM,
        lparam: LPARAM,
    ) -> LRESULT {
        match msg {
            WM_MOUSEACTIVATE => MA_NOACTIVATE as LRESULT,
            WM_PAINT => {
                let mut ps: PAINTSTRUCT = std::mem::zeroed();
                let hdc = BeginPaint(hwnd, &mut ps);
                paint_chip(hwnd, hdc);
                EndPaint(hwnd, &ps);
                0
            }
            WM_LBUTTONDOWN => {
                let x = (lparam as i32) & 0xFFFF;
                let y = ((lparam as i32) >> 16) & 0xFFFF;
                if chip_stop_local().contains(x, y) {
                    let _ = c_remote_core::skill_teach::teach_stop();
                }
                0
            }
            WM_CLOSE | WM_DESTROY => {
                PostQuitMessage(0);
                0
            }
            WM_CHIP_UPDATE => {
                InvalidateRect(hwnd, std::ptr::null(), 1);
                0
            }
            _ => DefWindowProcW(hwnd, msg, wparam, lparam),
        }
    }

    unsafe fn paint_border(hwnd: HWND, hdc: HDC) {
        let mut rc: RECT = std::mem::zeroed();
        GetClientRect(hwnd, &mut rc);

        // 1. Fill entire window with black color key (transparent)
        let bg = CreateSolidBrush(0x00000000);
        FillRect(hdc, &rc, bg);
        DeleteObject(bg as HGDIOBJ);

        // 2. Draw 4-pixel border in neon green (#22C55E -> 0x005EC522 in 0x00BBGGRR)
        let green = CreateSolidBrush(0x005EC522);

        // Top edge
        let top_rc = RECT { left: rc.left, top: rc.top, right: rc.right, bottom: rc.top + BORDER_THICKNESS };
        FillRect(hdc, &top_rc, green);

        // Bottom edge
        let bottom_rc = RECT { left: rc.left, top: rc.bottom - BORDER_THICKNESS, right: rc.right, bottom: rc.bottom };
        FillRect(hdc, &bottom_rc, green);

        // Left edge
        let left_rc = RECT { left: rc.left, top: rc.top, right: rc.left + BORDER_THICKNESS, bottom: rc.bottom };
        FillRect(hdc, &left_rc, green);

        // Right edge
        let right_rc = RECT { left: rc.right - BORDER_THICKNESS, top: rc.top, right: rc.right, bottom: rc.bottom };
        FillRect(hdc, &right_rc, green);

        DeleteObject(green as HGDIOBJ);
    }

    unsafe fn paint_chip(hwnd: HWND, hdc: HDC) {
        let mut rc: RECT = std::mem::zeroed();
        GetClientRect(hwnd, &mut rc);

        // Dark background (RGB: 20, 20, 18 -> 0x00121414)
        let bg = CreateSolidBrush(0x00121414);
        FillRect(hdc, &rc, bg);
        DeleteObject(bg as HGDIOBJ);

        SetBkMode(hdc, TRANSPARENT as i32);
        let snap = state().lock().unwrap();
        let stop = chip_stop_local();

        // Draw Stop button pill background (emerald green #22C55E -> 0x005EC522)
        let mut stop_rc = RECT { left: stop.x, top: stop.y, right: stop.x + stop.w, bottom: stop.y + stop.h };
        let stop_bg = CreateSolidBrush(0x005EC522);
        FillRect(hdc, &stop_rc, stop_bg);
        DeleteObject(stop_bg as HGDIOBJ);

        // Draw "Stop" text
        SetTextColor(hdc, 0x00121414);
        let mut stop_txt = wide_null("Stop");
        DrawTextW(hdc, stop_txt.as_mut_ptr(), -1, &mut stop_rc, DT_SINGLELINE | DT_VCENTER | DT_CENTER);

        // Draw step label
        SetTextColor(hdc, 0x00E4E4E7);
        let line = if snap.ord > 0 {
            format!("{}  {}", snap.ord, snap.label)
        } else {
            snap.label.clone()
        };
        let mut text = wide_null(&line);
        let mut text_rc = RECT { left: 14, top: 0, right: stop.x - 8, bottom: CHIP_H };
        DrawTextW(hdc, text.as_mut_ptr(), -1, &mut text_rc, DT_SINGLELINE | DT_VCENTER | DT_END_ELLIPSIS);
    }
}
