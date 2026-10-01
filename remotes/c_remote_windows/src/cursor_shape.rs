use windows::core::PCWSTR;
use windows::Win32::UI::WindowsAndMessaging::{
    GetCursorInfo, LoadCursorW, CURSORINFO, CURSOR_SHOWING, IDC_APPSTARTING, IDC_ARROW, IDC_CROSS,
    IDC_HAND, IDC_HELP, IDC_IBEAM, IDC_NO, IDC_SIZEALL, IDC_SIZENESW, IDC_SIZENS, IDC_SIZENWSE,
    IDC_SIZEWE, IDC_UPARROW, IDC_WAIT,
};

fn same_cursor(a: windows::Win32::UI::WindowsAndMessaging::HCURSOR, id: PCWSTR) -> bool {
    unsafe {
        let Ok(sys) = LoadCursorW(None, id) else {
            return false;
        };
        a == sys
    }
}

pub fn probe() -> &'static str {
    unsafe {
        let mut info = CURSORINFO {
            cbSize: std::mem::size_of::<CURSORINFO>() as u32,
            flags: CURSOR_SHOWING,
            hCursor: Default::default(),
            ptScreenPos: Default::default(),
        };
        if GetCursorInfo(&mut info).is_err() {
            return "arrow";
        }
        let h = info.hCursor;
        if same_cursor(h, IDC_IBEAM) {
            return "text";
        }
        if same_cursor(h, IDC_HAND) {
            return "click";
        }
        if same_cursor(h, IDC_WAIT) {
            return "wait";
        }
        if same_cursor(h, IDC_APPSTARTING) {
            return "progress";
        }
        if same_cursor(h, IDC_HELP) {
            return "help";
        }
        if same_cursor(h, IDC_NO) {
            return "forbidden";
        }
        if same_cursor(h, IDC_SIZEALL) {
            return "move";
        }
        if same_cursor(h, IDC_CROSS) {
            return "precise";
        }
        if same_cursor(h, IDC_SIZENS) {
            return "resize_ns";
        }
        if same_cursor(h, IDC_SIZEWE) {
            return "resize_ew";
        }
        if same_cursor(h, IDC_SIZENWSE) {
            return "resize_nwse";
        }
        if same_cursor(h, IDC_SIZENESW) {
            return "resize_nesw";
        }
        if same_cursor(h, IDC_UPARROW) || same_cursor(h, IDC_ARROW) {
            return "arrow";
        }
        "arrow"
    }
}
