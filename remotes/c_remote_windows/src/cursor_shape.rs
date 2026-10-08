use std::sync::OnceLock;
use windows::core::PCWSTR;
use windows::Win32::UI::WindowsAndMessaging::{
    GetCursorInfo, LoadCursorW, CURSORINFO, CURSOR_SHOWING, HCURSOR, IDC_APPSTARTING, IDC_ARROW,
    IDC_CROSS, IDC_HAND, IDC_HELP, IDC_IBEAM, IDC_NO, IDC_SIZEALL, IDC_SIZENESW, IDC_SIZENS,
    IDC_SIZENWSE, IDC_SIZEWE, IDC_UPARROW, IDC_WAIT,
};

struct SystemCursors {
    ibeam: Option<HCURSOR>,
    hand: Option<HCURSOR>,
    wait: Option<HCURSOR>,
    appstarting: Option<HCURSOR>,
    help: Option<HCURSOR>,
    no: Option<HCURSOR>,
    sizeall: Option<HCURSOR>,
    cross: Option<HCURSOR>,
    sizens: Option<HCURSOR>,
    sizewe: Option<HCURSOR>,
    sizenwse: Option<HCURSOR>,
    sizenesw: Option<HCURSOR>,
    uparrow: Option<HCURSOR>,
    arrow: Option<HCURSOR>,
}

unsafe impl Send for SystemCursors {}
unsafe impl Sync for SystemCursors {}

fn load(id: PCWSTR) -> Option<HCURSOR> {
    unsafe { LoadCursorW(None, id).ok() }
}

fn system_cursors() -> &'static SystemCursors {
    static CURSORS: OnceLock<SystemCursors> = OnceLock::new();
    CURSORS.get_or_init(|| SystemCursors {
        ibeam: load(IDC_IBEAM),
        hand: load(IDC_HAND),
        wait: load(IDC_WAIT),
        appstarting: load(IDC_APPSTARTING),
        help: load(IDC_HELP),
        no: load(IDC_NO),
        sizeall: load(IDC_SIZEALL),
        cross: load(IDC_CROSS),
        sizens: load(IDC_SIZENS),
        sizewe: load(IDC_SIZEWE),
        sizenwse: load(IDC_SIZENWSE),
        sizenesw: load(IDC_SIZENESW),
        uparrow: load(IDC_UPARROW),
        arrow: load(IDC_ARROW),
    })
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
        let c = system_cursors();
        if Some(h) == c.ibeam {
            return "text";
        }
        if Some(h) == c.hand {
            return "click";
        }
        if Some(h) == c.wait {
            return "wait";
        }
        if Some(h) == c.appstarting {
            return "progress";
        }
        if Some(h) == c.help {
            return "help";
        }
        if Some(h) == c.no {
            return "forbidden";
        }
        if Some(h) == c.sizeall {
            return "move";
        }
        if Some(h) == c.cross {
            return "precise";
        }
        if Some(h) == c.sizens {
            return "resize_ns";
        }
        if Some(h) == c.sizewe {
            return "resize_ew";
        }
        if Some(h) == c.sizenwse {
            return "resize_nwse";
        }
        if Some(h) == c.sizenesw {
            return "resize_nesw";
        }
        if Some(h) == c.uparrow || Some(h) == c.arrow {
            return "arrow";
        }
        "arrow"
    }
}
