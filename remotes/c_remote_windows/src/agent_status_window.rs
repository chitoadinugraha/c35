use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Mutex, OnceLock};

static WANT_SHOW: AtomicBool = AtomicBool::new(false);
static ACTION_TX: OnceLock<Option<tokio::sync::mpsc::UnboundedSender<crate::tray::TrayAction>>> =
    OnceLock::new();

pub fn show_or_focus(hwnd_slot: &OnceLock<Mutex<isize>>) {
    WANT_SHOW.store(true, Ordering::SeqCst);
    if let Some(slot) = hwnd_slot.get() {
        if let Ok(guard) = slot.lock() {
            if *guard != 0 {
                post_agent_show(*guard);
            }
        }
    }
}

fn post_agent_show(hwnd: isize) {
    use windows::Win32::Foundation::{HWND, LPARAM, WPARAM};
    use windows::Win32::UI::WindowsAndMessaging::{PostMessageW, WM_USER};
    const WM_AGENT_SHOW: u32 = WM_USER + 302;
    let _ = unsafe { PostMessageW(HWND(hwnd as *mut _), WM_AGENT_SHOW, WPARAM(0), LPARAM(0)) };
}

struct StatusCopy {
    device: String,
    account: String,
    version: String,
    cloud_on: bool,
    user_app_subtitle: String,
    user_app_connected: usize,
    webrtc_connecting: bool,
    capture_active: bool,
    control_allowed: bool,
    autostart: bool,
    update_staged: Option<i64>,
    update_check_msg: String,
    personal_package: String,
    device_package: String,
    drive_enabled: bool,
    drive_storage: Option<String>,
    log_lines: Vec<String>,
}

fn status_copy() -> StatusCopy {
    let snap = c_remote_core::agent_ui::snapshot();
    let device = if snap.device_name.is_empty() {
        crate::pair_loop::device_name()
    } else {
        snap.device_name.clone()
    };
    let account = if snap.owner_label.is_empty() {
        "(loads when online)".into()
    } else {
        snap.owner_label.clone()
    };
    let log_lines: Vec<String> = c_remote_core::log_ring::tail(40)
        .iter()
        .map(|l| c_remote_core::log_ring::format_line(l))
        .collect();
    StatusCopy {
        device,
        account,
        version: c_remote_core::version::agent_version_tray_label(),
        cloud_on: snap.ws_connected,
        user_app_subtitle: c_remote_core::agent_ui::user_app_subtitle(snap.webrtc_connecting),
        user_app_connected: snap.user_app_lines.len(),
        webrtc_connecting: snap.webrtc_connecting,
        capture_active: snap.capture_active,
        control_allowed: snap.control_allowed,
        autostart: snap.autostart_enabled,
        update_staged: snap.update_staged_version,
        update_check_msg: snap.last_update_check_msg.trim().to_string(),
        personal_package: {
            let s = snap.personal_package_name.trim();
            if s.is_empty() { "—".into() } else { s.to_string() }
        },
        device_package: {
            let s = snap.device_package_name.trim();
            if s.is_empty() { "—".into() } else { s.to_string() }
        },
        drive_enabled: snap.drive_enabled,
        drive_storage: c_remote_core::agent_ui::drive_storage_label(),
        log_lines,
    }
}

pub fn run(
    hwnd_slot: &OnceLock<Mutex<isize>>,
    action_tx: Option<tokio::sync::mpsc::UnboundedSender<crate::tray::TrayAction>>,
) -> anyhow::Result<()> {
    let _ = ACTION_TX.set(action_tx);
    use windows::core::w;
    use windows::Win32::Foundation::{COLORREF, HWND, LPARAM, LRESULT, POINT, RECT, WPARAM};
    use windows::Win32::Graphics::Gdi::{
        BeginPaint, CreateFontW, CreatePen, CreateSolidBrush, DeleteObject, DrawTextW, Ellipse,
        EndPaint, FillRect, GetStockObject, InvalidateRect, RoundRect, SelectObject, SetBkMode,
        SetTextColor, DEFAULT_CHARSET, DRAW_TEXT_FORMAT, DT_CENTER, DT_LEFT, DT_SINGLELINE,
        DT_VCENTER, DT_WORDBREAK, FW_BOLD, FW_NORMAL, FW_SEMIBOLD, HDC, HFONT, HGDIOBJ,
        NULL_BRUSH, OUT_DEFAULT_PRECIS, PAINTSTRUCT, PS_SOLID, TRANSPARENT,
        CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, FF_DONTCARE,
    };
    use windows::Win32::System::LibraryLoader::GetModuleHandleW;
    use windows::Win32::UI::HiDpi::GetDpiForWindow;
    use windows::Win32::UI::WindowsAndMessaging::{
        CreateWindowExW, DefWindowProcW, DispatchMessageW, GetClientRect, GetMessageW,
        GetSystemMetrics, GetWindowLongPtrW, KillTimer, LoadCursorW, PostQuitMessage,
        RegisterClassExW, SendMessageW, SetForegroundWindow, SetWindowLongPtrW, SetWindowPos,
        ShowWindow, TranslateMessage, CS_HREDRAW, CS_VREDRAW, GWLP_USERDATA, HICON, HMENU,
        HWND_TOP, ICON_BIG, ICON_SMALL, IDC_ARROW, SM_CXSCREEN, SM_CYSCREEN, SW_HIDE, SW_SHOW,
        SWP_NOSIZE, WM_CLOSE, WM_CREATE, WM_DESTROY, WM_ERASEBKGND, WM_LBUTTONDOWN,
        WM_MOUSEMOVE, WM_NCHITTEST, WM_PAINT, WM_SETICON, WM_SIZE, WM_TIMER, WM_USER,
        WNDCLASSEXW, WS_EX_APPWINDOW, WS_POPUP, HTCAPTION, HTCLIENT, WINDOW_EX_STYLE,
    };

    const WM_AGENT_SHOW: u32 = WM_USER + 302;
    const TIMER_ID: usize = 1;

    const CLR_BG: u32 = 0x000A0A08;
    const CLR_TITLE: u32 = 0x00141412;
    const CLR_FOOTER: u32 = 0x0010100E;
    const CLR_TEXT: u32 = 0x00E7E4E4;
    const CLR_MUTED: u32 = 0x00AAA1A1;
    const CLR_CARD: u32 = 0x001C1C1A;
    const CLR_CARD_BORDER: u32 = 0x003A3838;
    const CLR_BTN_BG: u32 = 0x00282826;
    const CLR_BTN_BORDER: u32 = 0x0040403E;
    const CLR_BTN_HOVER: u32 = 0x00343432;
    const CLR_CLOSE: u32 = 0x00C8C4C4;
    const CLR_CLOSE_HOVER: u32 = 0x00FFFFFF;
    const CLR_CLOSE_BG: u32 = 0x00E81123;
    const CLR_DOT_ON: u32 = 0x0050C878;
    const CLR_DOT_WARN: u32 = 0x004DB8FF;
    const CLR_DOT_IDLE: u32 = 0x00666666;
    const CLR_DOT_OFF: u32 = 0x00E81123;
    const CLR_LOG_BG: u32 = 0x0010100E;

    const WIN_W: i32 = 480;
    const WIN_H: i32 = 588;

    struct UiScale {
        dpi: u32,
    }

    impl UiScale {
        fn from_hwnd(hwnd: HWND) -> Self {
            let dpi = unsafe {
                let d = GetDpiForWindow(hwnd);
                if d == 0 { 96 } else { d }
            };
            Self { dpi }
        }

        fn px(&self, logical: i32) -> i32 {
            ((logical as i64 * self.dpi as i64 + 48) / 96) as i32
        }
    }

    struct Fonts {
        title: HFONT,
        body: HFONT,
        small: HFONT,
        log: HFONT,
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

    impl Fonts {
        unsafe fn create(scale: &UiScale) -> Self {
            Self {
                title: create_font(-scale.px(15), FW_SEMIBOLD, w!("Segoe UI")),
                body: create_font(-scale.px(12), FW_NORMAL, w!("Segoe UI")),
                small: create_font(-scale.px(11), FW_NORMAL, w!("Segoe UI")),
                log: create_font(-scale.px(10), FW_NORMAL, w!("Consolas")),
            }
        }

        unsafe fn drop(&self) {
            for f in [self.title, self.body, self.small, self.log] {
                if !f.is_invalid() {
                    let _ = DeleteObject(HGDIOBJ(f.0));
                }
            }
        }
    }

    struct Ctx {
        app_icon: HICON,
        scale: UiScale,
        fonts: Fonts,
        action_tx: Option<tokio::sync::mpsc::UnboundedSender<crate::tray::TrayAction>>,
        close_hover: bool,
        drive_toggle_hover: bool,
        btn_log_hover: bool,
        btn_folder_hover: bool,
        btn_update_hover: bool,
        btn_unpair_hover: bool,
    }

    unsafe fn ctx_get(hwnd: HWND) -> Option<&'static mut Ctx> {
        let ptr = GetWindowLongPtrW(hwnd, GWLP_USERDATA) as *mut Ctx;
        if ptr.is_null() {
            None
        } else {
            Some(&mut *ptr)
        }
    }

    fn wide(s: &str) -> Vec<u16> {
        s.encode_utf16().collect()
    }

    unsafe fn draw_text(
        hdc: HDC,
        font: HFONT,
        color: u32,
        text: &str,
        rc: RECT,
        flags: DRAW_TEXT_FORMAT,
    ) {
        if text.is_empty() {
            return;
        }
        let old = SelectObject(hdc, HGDIOBJ(font.0));
        SetBkMode(hdc, TRANSPARENT);
        SetTextColor(hdc, COLORREF(color));
        let mut w = wide(text);
        let mut rc = rc;
        let _ = DrawTextW(hdc, &mut w, &mut rc, flags);
        SelectObject(hdc, old);
    }

    unsafe fn draw_dot(hdc: HDC, cx: i32, cy: i32, r: i32, color: u32) {
        let brush = CreateSolidBrush(COLORREF(color));
        let pen = CreatePen(PS_SOLID, 1, COLORREF(color));
        let ob = SelectObject(hdc, HGDIOBJ(brush.0));
        let op = SelectObject(hdc, HGDIOBJ(pen.0));
        let _ = Ellipse(hdc, cx - r, cy - r, cx + r, cy + r);
        SelectObject(hdc, ob);
        SelectObject(hdc, op);
        let _ = DeleteObject(HGDIOBJ(brush.0));
        let _ = DeleteObject(HGDIOBJ(pen.0));
    }

    unsafe fn draw_round_btn(hdc: HDC, scale: &UiScale, rc: &RECT, hover: bool) {
        let radius = scale.px(6);
        let pen = CreatePen(PS_SOLID, 1, COLORREF(CLR_BTN_BORDER));
        let brush = CreateSolidBrush(COLORREF(if hover { CLR_BTN_HOVER } else { CLR_BTN_BG }));
        let op = SelectObject(hdc, HGDIOBJ(pen.0));
        let ob = SelectObject(hdc, HGDIOBJ(brush.0));
        let _ = RoundRect(hdc, rc.left, rc.top, rc.right, rc.bottom, radius, radius);
        SelectObject(hdc, ob);
        SelectObject(hdc, op);
        let _ = DeleteObject(HGDIOBJ(brush.0));
        let _ = DeleteObject(HGDIOBJ(pen.0));
    }

    fn title_h(scale: &UiScale) -> i32 {
        scale.px(36)
    }

    fn footer_h(scale: &UiScale) -> i32 {
        scale.px(52)
    }

    fn close_rect(scale: &UiScale, rc: &RECT) -> RECT {
        let sz = scale.px(36);
        RECT {
            left: rc.right - sz,
            top: 0,
            right: rc.right,
            bottom: title_h(scale),
        }
    }

    fn btn_row(scale: &UiScale, rc: &RECT) -> [RECT; 4] {
        let fh = footer_h(scale);
        let margin = scale.px(10);
        let gap = scale.px(6);
        let btn_h = scale.px(32);
        let y = rc.bottom - fh + (fh - btn_h) / 2;
        let count: i32 = 4;
        let w = (rc.right - margin * 2 - gap * (count - 1)) / count;
        let mut out = [RECT::default(), RECT::default(), RECT::default(), RECT::default()];
        for i in 0..count as usize {
            out[i] = RECT {
                left: margin + (i as i32) * (w + gap),
                top: y,
                right: margin + (i as i32) * (w + gap) + w,
                bottom: y + btn_h,
            };
        }
        out
    }

    unsafe fn confirm_unpair(hwnd: HWND, action_tx: &Option<tokio::sync::mpsc::UnboundedSender<crate::tray::TrayAction>>) {
        use windows::core::w;
        use windows::Win32::UI::WindowsAndMessaging::{
            MessageBoxW, MB_ICONWARNING, MB_YESNO, IDYES,
        };
        let text = "Unpair this PC from your Alien AI account?\r\n\r\nRemote control will stop until you pair again.";
        let wide: Vec<u16> = text.encode_utf16().chain([0]).collect();
        let r = MessageBoxW(
            hwnd,
            windows::core::PCWSTR(wide.as_ptr()),
            w!("Unpair device"),
            MB_YESNO | MB_ICONWARNING,
        );
        if r == IDYES {
            if let Some(tx) = action_tx {
                let _ = tx.send(crate::tray::TrayAction::Unpair);
            }
            let _ = ShowWindow(hwnd, SW_HIDE);
        }
    }

    fn in_rect(pt: POINT, r: &RECT) -> bool {
        pt.x >= r.left && pt.x < r.right && pt.y >= r.top && pt.y < r.bottom
    }

    fn cloud_dot_color(on: bool) -> u32 {
        if on { CLR_DOT_ON } else { CLR_DOT_OFF }
    }

    fn drive_row(scale: &UiScale, rc: &RECT, top: i32) -> (RECT, RECT) {
        let margin = scale.px(16);
        let switch_w = scale.px(44);
        let switch_h = scale.px(22);
        let row_h = scale.px(36);
        let switch = RECT {
            left: rc.right - margin - switch_w,
            top: top + (row_h - switch_h) / 2,
            right: rc.right - margin,
            bottom: top + (row_h - switch_h) / 2 + switch_h,
        };
        let row = RECT {
            left: margin,
            top,
            right: rc.right - margin,
            bottom: top + row_h,
        };
        (row, switch)
    }

    unsafe fn draw_toggle(
        hdc: HDC,
        scale: &UiScale,
        rc: &RECT,
        on: bool,
        hover: bool,
    ) {
        let radius = scale.px(11);
        let track_color = if on {
            if hover { 0x0038A858 } else { 0x0050C878 }
        } else if hover {
            0x00484846
        } else {
            0x0030302E
        };
        let pen = CreatePen(PS_SOLID, 1, COLORREF(CLR_CARD_BORDER));
        let brush = CreateSolidBrush(COLORREF(track_color));
        let op = SelectObject(hdc, HGDIOBJ(pen.0));
        let ob = SelectObject(hdc, HGDIOBJ(brush.0));
        let _ = RoundRect(hdc, rc.left, rc.top, rc.right, rc.bottom, radius, radius);
        SelectObject(hdc, ob);
        SelectObject(hdc, op);
        let _ = DeleteObject(HGDIOBJ(brush.0));
        let _ = DeleteObject(HGDIOBJ(pen.0));

        let pad = scale.px(2);
        let thumb_r = (rc.bottom - rc.top) / 2 - pad;
        let thumb_cx = if on {
            rc.right - pad - thumb_r
        } else {
            rc.left + pad + thumb_r
        };
        let thumb_cy = (rc.top + rc.bottom) / 2;
        draw_dot(hdc, thumb_cx, thumb_cy, thumb_r, CLR_TEXT);
    }

    fn user_app_dot_color(connected: usize, connecting: bool) -> u32 {
        if connected > 0 {
            CLR_DOT_ON
        } else if connecting {
            CLR_DOT_WARN
        } else {
            CLR_DOT_IDLE
        }
    }

    unsafe fn paint(hwnd: HWND) {
        let ctx = match ctx_get(hwnd) {
            Some(c) => c,
            None => return,
        };
        let snap = status_copy();
        let mut rc = RECT::default();
        if GetClientRect(hwnd, &mut rc).is_err() {
            return;
        }
        let mut ps = PAINTSTRUCT::default();
        let hdc = BeginPaint(hwnd, &mut ps);
        if hdc.is_invalid() {
            return;
        }

        let scale = &ctx.scale;
        let th = title_h(scale);
        let fh = footer_h(scale);

        let bg = CreateSolidBrush(COLORREF(CLR_BG));
        let _ = FillRect(hdc, &rc, bg);
        let _ = DeleteObject(HGDIOBJ(bg.0));

        let title_bg = CreateSolidBrush(COLORREF(CLR_TITLE));
        let title_rc = RECT {
            left: 0,
            top: 0,
            right: rc.right,
            bottom: th,
        };
        let _ = FillRect(hdc, &title_rc, title_bg);
        let _ = DeleteObject(HGDIOBJ(title_bg.0));

        let footer_rc = RECT {
            left: 0,
            top: rc.bottom - fh,
            right: rc.right,
            bottom: rc.bottom,
        };
        let foot_bg = CreateSolidBrush(COLORREF(CLR_FOOTER));
        let _ = FillRect(hdc, &footer_rc, foot_bg);
        let _ = DeleteObject(HGDIOBJ(foot_bg.0));

        let close = close_rect(scale, &rc);
        if ctx.close_hover {
            let h = CreateSolidBrush(COLORREF(CLR_CLOSE_BG));
            let _ = FillRect(hdc, &close, h);
            let _ = DeleteObject(HGDIOBJ(h.0));
        }
        draw_text(
            hdc,
            ctx.fonts.title,
            if ctx.close_hover { CLR_CLOSE_HOVER } else { CLR_CLOSE },
            "×",
            close,
            DT_CENTER | DT_SINGLELINE | DT_VCENTER,
        );

        let icon_sz = scale.px(20);
        let icon_x = scale.px(10);
        let icon_y = (th - icon_sz) / 2;
        use windows::Win32::UI::WindowsAndMessaging::{DrawIconEx, DI_NORMAL};
        let _ = DrawIconEx(
            hdc,
            icon_x,
            icon_y,
            ctx.app_icon,
            icon_sz,
            icon_sz,
            0,
            None,
            DI_NORMAL,
        );

        let title_text_rc = RECT {
            left: scale.px(38),
            top: 0,
            right: close.left,
            bottom: th,
        };
        draw_text(
            hdc,
            ctx.fonts.title,
            CLR_TEXT,
            "Alien AI Agent",
            title_text_rc,
            DT_LEFT | DT_SINGLELINE | DT_VCENTER,
        );

        let card_y = th + scale.px(12);
        let card_h = scale.px(72);
        let margin = scale.px(16);
        let card_w = (rc.right - margin * 3) / 2;
        let cards = [
            RECT {
                left: margin,
                top: card_y,
                right: margin + card_w,
                bottom: card_y + card_h,
            },
            RECT {
                left: margin * 2 + card_w,
                top: card_y,
                right: rc.right - margin,
                bottom: card_y + card_h,
            },
        ];

        for (i, card) in cards.iter().enumerate() {
            let pen = CreatePen(PS_SOLID, 1, COLORREF(CLR_CARD_BORDER));
            let brush = CreateSolidBrush(COLORREF(CLR_CARD));
            let op = SelectObject(hdc, HGDIOBJ(pen.0));
            let ob = SelectObject(hdc, HGDIOBJ(brush.0));
            let _ = RoundRect(
                hdc,
                card.left,
                card.top,
                card.right,
                card.bottom,
                scale.px(8),
                scale.px(8),
            );
            SelectObject(hdc, ob);
            SelectObject(hdc, op);
            let _ = DeleteObject(HGDIOBJ(brush.0));
            let _ = DeleteObject(HGDIOBJ(pen.0));

            let dot_cx = card.left + scale.px(20);
            let dot_cy = card.top + card_h / 2;
            let (title, sub, dot) = if i == 0 {
                (
                    "Alien AI Cloud",
                    if snap.cloud_on {
                        "Connected".to_string()
                    } else {
                        "Offline".to_string()
                    },
                    cloud_dot_color(snap.cloud_on),
                )
            } else {
                (
                    "User App",
                    snap.user_app_subtitle.clone(),
                    user_app_dot_color(snap.user_app_connected, snap.webrtc_connecting),
                )
            };
            draw_dot(hdc, dot_cx, dot_cy, scale.px(6), dot);
            let text_rc = RECT {
                left: card.left + scale.px(36),
                top: card.top + scale.px(14),
                right: card.right - scale.px(8),
                bottom: card.bottom - scale.px(8),
            };
            draw_text(
                hdc,
                ctx.fonts.body,
                CLR_TEXT,
                title,
                RECT {
                    left: text_rc.left,
                    top: text_rc.top,
                    right: text_rc.right,
                    bottom: text_rc.top + scale.px(20),
                },
                DT_LEFT | DT_SINGLELINE | DT_VCENTER,
            );
            draw_text(
                hdc,
                ctx.fonts.small,
                CLR_MUTED,
                sub.as_str(),
                RECT {
                    left: text_rc.left,
                    top: text_rc.top + scale.px(22),
                    right: text_rc.right,
                    bottom: text_rc.bottom,
                },
                DT_LEFT | DT_SINGLELINE | DT_VCENTER,
            );
        }

        let info_y = card_y + card_h + scale.px(16);
        let mut info_lines = vec![
            format!("Device: {}", snap.device),
            format!("Account: {}", snap.account),
            snap.version.clone(),
            format!("Package (personal): {}", snap.personal_package),
            format!("Package (device): {}", snap.device_package),
            format!(
                "Control: {} · Boot: {}",
                if snap.control_allowed { "allowed" } else { "blocked" },
                if snap.autostart { "on" } else { "off" }
            ),
        ];
        if let Some(v) = snap.update_staged {
            info_lines.push(format!("Update ready: build {v} (tray when idle)"));
        }
        if !snap.update_check_msg.is_empty() {
            info_lines.push(format!("Last update check: {}", snap.update_check_msg));
        }
        for (i, line) in info_lines.iter().enumerate() {
            let line_rc = RECT {
                left: margin,
                top: info_y + (i as i32) * scale.px(18),
                right: rc.right - margin,
                bottom: info_y + (i as i32 + 1) * scale.px(18),
            };
            draw_text(hdc, ctx.fonts.small, CLR_MUTED, line, line_rc, DT_LEFT | DT_SINGLELINE);
        }

        let drive_top = info_y + (info_lines.len() as i32) * scale.px(18) + scale.px(10);
        let (drive_row, drive_switch) = drive_row(scale, &rc, drive_top);
        draw_text(
            hdc,
            ctx.fonts.body,
            CLR_TEXT,
            "Alien AI Drive",
            RECT {
                left: drive_row.left,
                top: drive_row.top + scale.px(2),
                right: drive_switch.left - scale.px(8),
                bottom: drive_row.top + scale.px(22),
            },
            DT_LEFT | DT_SINGLELINE | DT_VCENTER,
        );
        if let Some(label) = snap.drive_storage.as_deref() {
            draw_text(
                hdc,
                ctx.fonts.small,
                CLR_MUTED,
                label,
                RECT {
                    left: drive_row.left,
                    top: drive_row.top + scale.px(20),
                    right: drive_switch.left - scale.px(8),
                    bottom: drive_row.bottom,
                },
                DT_LEFT | DT_SINGLELINE | DT_VCENTER,
            );
        }
        draw_toggle(hdc, scale, &drive_switch, snap.drive_enabled, ctx.drive_toggle_hover);

        let log_top = drive_top + scale.px(52) + scale.px(4);
        let log_bottom = rc.bottom - fh - scale.px(8);
        let log_box = RECT {
            left: margin,
            top: log_top,
            right: rc.right - margin,
            bottom: log_bottom,
        };
        let log_bg = CreateSolidBrush(COLORREF(CLR_LOG_BG));
        let _ = FillRect(hdc, &log_box, log_bg);
        let _ = DeleteObject(HGDIOBJ(log_bg.0));

        draw_text(
            hdc,
            ctx.fonts.small,
            CLR_MUTED,
            "Recent activity",
            RECT {
                left: log_box.left + scale.px(8),
                top: log_box.top + scale.px(6),
                right: log_box.right,
                bottom: log_box.top + scale.px(22),
            },
            DT_LEFT | DT_SINGLELINE,
        );

        let mut y = log_box.top + scale.px(26);
        for line in snap.log_lines.iter().rev().take(12).rev() {
            if y + scale.px(14) > log_box.bottom - scale.px(4) {
                break;
            }
            let line_rc = RECT {
                left: log_box.left + scale.px(8),
                top: y,
                right: log_box.right - scale.px(8),
                bottom: y + scale.px(14),
            };
            draw_text(hdc, ctx.fonts.log, CLR_TEXT, line, line_rc, DT_LEFT | DT_SINGLELINE);
            y += scale.px(14);
        }

        let btns = btn_row(scale, &rc);
        let labels = ["Open log", "Logs", "Update", "Unpair"];
        let hovers = [
            ctx.btn_log_hover,
            ctx.btn_folder_hover,
            ctx.btn_update_hover,
            ctx.btn_unpair_hover,
        ];
        for (i, btn_rc) in btns.iter().enumerate() {
            draw_round_btn(hdc, scale, btn_rc, hovers[i]);
            draw_text(
                hdc,
                ctx.fonts.small,
                CLR_TEXT,
                labels[i],
                *btn_rc,
                DT_CENTER | DT_SINGLELINE | DT_VCENTER,
            );
        }

        let _ = EndPaint(hwnd, &ps);
    }

    unsafe fn invalidate_all(hwnd: HWND) {
        let _ = InvalidateRect(hwnd, None, false);
    }

    unsafe fn present(hwnd: HWND) {
        let _ = ShowWindow(hwnd, SW_SHOW);
        let _ = SetForegroundWindow(hwnd);
        invalidate_all(hwnd);
    }

    unsafe extern "system" fn wnd_proc(
        hwnd: HWND,
        msg: u32,
        wparam: WPARAM,
        lparam: LPARAM,
    ) -> LRESULT {
        use windows::Win32::UI::WindowsAndMessaging::SetTimer;

        match msg {
            WM_CREATE => {
                let app_icon = crate::icon::load_app_icon(24, 24);
                let scale = UiScale::from_hwnd(hwnd);
                let fonts = Fonts::create(&scale);
                let ctx = Box::new(Ctx {
                    app_icon,
                    scale,
                    fonts,
                    action_tx: ACTION_TX.get().cloned().unwrap_or(None),
                    close_hover: false,
                    drive_toggle_hover: false,
                    btn_log_hover: false,
                    btn_folder_hover: false,
                    btn_update_hover: false,
                    btn_unpair_hover: false,
                });
                SetWindowLongPtrW(hwnd, GWLP_USERDATA, Box::into_raw(ctx) as isize);
                let _ = SetTimer(hwnd, TIMER_ID, 1000, None);
                if WANT_SHOW.load(Ordering::SeqCst) {
                    present(hwnd);
                } else {
                    let _ = ShowWindow(hwnd, SW_HIDE);
                }
                LRESULT(0)
            }
            WM_AGENT_SHOW => {
                present(hwnd);
                LRESULT(0)
            }
            WM_ERASEBKGND => LRESULT(1),
            WM_PAINT => {
                paint(hwnd);
                LRESULT(0)
            }
            WM_TIMER if wparam.0 == TIMER_ID => {
                invalidate_all(hwnd);
                LRESULT(0)
            }
            WM_SIZE => {
                if let Some(ctx) = ctx_get(hwnd) {
                    ctx.scale = UiScale::from_hwnd(hwnd);
                    ctx.fonts.drop();
                    ctx.fonts = Fonts::create(&ctx.scale);
                }
                invalidate_all(hwnd);
                LRESULT(0)
            }
            WM_MOUSEMOVE => {
                let x = (lparam.0 & 0xFFFF) as i16 as i32;
                let y = ((lparam.0 >> 16) & 0xFFFF) as i16 as i32;
                let pt = POINT { x, y };
                let mut rc = RECT::default();
                let _ = GetClientRect(hwnd, &mut rc);
                if let Some(ctx) = ctx_get(hwnd) {
                    let scale = &ctx.scale;
                    let close = close_rect(scale, &rc);
                    let btns = btn_row(scale, &rc);
                    let info_y = title_h(scale) + scale.px(12) + scale.px(72) + scale.px(16);
                    let info_count = 6i32
                        + if status_copy().update_staged.is_some() { 1 } else { 0 }
                        + if status_copy().update_check_msg.is_empty() { 0 } else { 1 };
                    let drive_top = info_y + info_count * scale.px(18) + scale.px(10);
                    let (_, drive_switch) = drive_row(scale, &rc, drive_top);
                    let nh = (
                        in_rect(pt, &close),
                        in_rect(pt, &drive_switch),
                        in_rect(pt, &btns[0]),
                        in_rect(pt, &btns[1]),
                        in_rect(pt, &btns[2]),
                        in_rect(pt, &btns[3]),
                    );
                    let oh = (
                        ctx.close_hover,
                        ctx.drive_toggle_hover,
                        ctx.btn_log_hover,
                        ctx.btn_folder_hover,
                        ctx.btn_update_hover,
                        ctx.btn_unpair_hover,
                    );
                    if nh != oh {
                        ctx.close_hover = nh.0;
                        ctx.drive_toggle_hover = nh.1;
                        ctx.btn_log_hover = nh.2;
                        ctx.btn_folder_hover = nh.3;
                        ctx.btn_update_hover = nh.4;
                        ctx.btn_unpair_hover = nh.5;
                        invalidate_all(hwnd);
                    }
                }
                LRESULT(0)
            }
            WM_LBUTTONDOWN => {
                let x = (lparam.0 & 0xFFFF) as i16 as i32;
                let y = ((lparam.0 >> 16) & 0xFFFF) as i16 as i32;
                let pt = POINT { x, y };
                let mut rc = RECT::default();
                let _ = GetClientRect(hwnd, &mut rc);
                let scale = UiScale::from_hwnd(hwnd);
                let close = close_rect(&scale, &rc);
                if in_rect(pt, &close) {
                    let _ = ShowWindow(hwnd, SW_HIDE);
                    return LRESULT(0);
                }
                let snap = status_copy();
                let info_y = title_h(&scale) + scale.px(12) + scale.px(72) + scale.px(16);
                let mut info_count = 6i32;
                if snap.update_staged.is_some() {
                    info_count += 1;
                }
                if !snap.update_check_msg.is_empty() {
                    info_count += 1;
                }
                let drive_top = info_y + info_count * scale.px(18) + scale.px(10);
                let (_, drive_switch) = drive_row(&scale, &rc, drive_top);
                if in_rect(pt, &drive_switch) {
                    let new_on = !snap.drive_enabled;
                    if let Err(e) = c_remote_core::config::drive_enabled_save(new_on) {
                        tracing::warn!("drive_enabled_save: {e:#}");
                    } else {
                        c_remote_core::agent_ui::drive_enabled_set(new_on);
                        if let Some(ctx) = ctx_get(hwnd) {
                            if let Some(tx) = &ctx.action_tx {
                                let _ = tx.send(crate::tray::TrayAction::DriveSet(new_on));
                            }
                        }
                        invalidate_all(hwnd);
                    }
                    return LRESULT(0);
                }
                let btns = btn_row(&scale, &rc);
                if in_rect(pt, &btns[0]) {
                    let _ = c_remote_core::log_local::log_open();
                } else if in_rect(pt, &btns[1]) {
                    let dir = c_remote_core::log_local::log_dir();
                    let _ = std::process::Command::new("explorer.exe")
                        .arg(dir.display().to_string())
                        .spawn();
                } else if in_rect(pt, &btns[2]) {
                    c_remote_core::update::update_check_now();
                } else if in_rect(pt, &btns[3]) {
                    if let Some(ctx) = ctx_get(hwnd) {
                        let tx = ctx.action_tx.clone();
                        confirm_unpair(hwnd, &tx);
                    }
                }
                LRESULT(0)
            }
            WM_NCHITTEST => {
                let x = (lparam.0 & 0xFFFF) as i16 as i32;
                let y = ((lparam.0 >> 16) & 0xFFFF) as i16 as i32;
                let mut pt = POINT { x, y };
                let mut rc = RECT::default();
                let _ = GetClientRect(hwnd, &mut rc);
                unsafe {
                    let _ = windows::Win32::Graphics::Gdi::ScreenToClient(hwnd, &mut pt);
                }
                let scale = UiScale::from_hwnd(hwnd);
                let close = close_rect(&scale, &rc);
                if in_rect(pt, &close) {
                    return LRESULT(HTCLIENT as isize);
                }
                if pt.y < title_h(&scale) {
                    return LRESULT(HTCAPTION as isize);
                }
                LRESULT(DefWindowProcW(hwnd, msg, wparam, lparam).0)
            }
            WM_CLOSE => {
                let _ = ShowWindow(hwnd, SW_HIDE);
                LRESULT(0)
            }
            WM_DESTROY => {
                let _ = KillTimer(hwnd, TIMER_ID);
                let ptr = GetWindowLongPtrW(hwnd, GWLP_USERDATA) as *mut Ctx;
                if !ptr.is_null() {
                    unsafe {
                        (*ptr).fonts.drop();
                    }
                    drop(Box::from_raw(ptr));
                    SetWindowLongPtrW(hwnd, GWLP_USERDATA, 0);
                }
                PostQuitMessage(0);
                LRESULT(0)
            }
            _ => DefWindowProcW(hwnd, msg, wparam, lparam),
        }
    }

    unsafe {
        let hinstance = GetModuleHandleW(None)?;
        let class_name = w!("AlienAIAgentStatusV2");
        let app_icon: HICON = crate::icon::load_app_icon(32, 32);
        let wnd_class = WNDCLASSEXW {
            cbSize: std::mem::size_of::<WNDCLASSEXW>() as u32,
            style: CS_HREDRAW | CS_VREDRAW,
            lpfnWndProc: Some(wnd_proc),
            hInstance: hinstance.into(),
            hIcon: app_icon,
            hCursor: LoadCursorW(None, IDC_ARROW)?,
            lpszClassName: class_name,
            ..Default::default()
        };
        RegisterClassExW(&wnd_class);

        let cw = GetSystemMetrics(SM_CXSCREEN);
        let ch = GetSystemMetrics(SM_CYSCREEN);
        let hwnd = CreateWindowExW(
            WS_EX_APPWINDOW,
            class_name,
            w!("Alien AI Agent"),
            WS_POPUP,
            (cw - WIN_W) / 2,
            (ch - WIN_H) / 2,
            WIN_W,
            WIN_H,
            HWND::default(),
            HMENU::default(),
            hinstance,
            None,
        )?;

        let _ = SendMessageW(hwnd, WM_SETICON, WPARAM(ICON_BIG as usize), LPARAM(app_icon.0 as isize));
        let _ = SendMessageW(
            hwnd,
            WM_SETICON,
            WPARAM(ICON_SMALL as usize),
            LPARAM(app_icon.0 as isize),
        );

        if let Ok(mut guard) = hwnd_slot.get_or_init(|| Mutex::new(0)).lock() {
            *guard = hwnd.0 as isize;
        }

        let _ = SetWindowPos(hwnd, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE);

        let mut msg = windows::Win32::UI::WindowsAndMessaging::MSG::default();
        while GetMessageW(&mut msg, HWND::default(), 0, 0).as_bool() {
            let _ = TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }

    Ok(())
}
