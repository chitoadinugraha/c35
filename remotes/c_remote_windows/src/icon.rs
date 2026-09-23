#[cfg(target_os = "windows")]
pub fn load_app_icon(width: i32, height: i32) -> windows::Win32::UI::WindowsAndMessaging::HICON {
    use windows::core::PCWSTR;
    use windows::Win32::UI::WindowsAndMessaging::{
        GetSystemMetrics, LoadIconW, LoadImageW, HICON, IDI_APPLICATION, IMAGE_ICON, LR_LOADFROMFILE,
        SM_CXSMICON, SM_CYSMICON,
    };

    let w = if width <= 0 {
        unsafe { GetSystemMetrics(SM_CXSMICON) }
    } else {
        width
    };
    let h = if height <= 0 {
        unsafe { GetSystemMetrics(SM_CYSMICON) }
    } else {
        height
    };

    let icon_path = ensure_icon_file();
    let wide: Vec<u16> = icon_path
        .to_string_lossy()
        .encode_utf16()
        .chain(std::iter::once(0))
        .collect();
    unsafe {
        match LoadImageW(
            None,
            PCWSTR(wide.as_ptr()),
            IMAGE_ICON,
            w,
            h,
            LR_LOADFROMFILE,
        ) {
            Ok(handle) if !handle.is_invalid() => HICON(handle.0),
            _ => LoadIconW(None, IDI_APPLICATION).unwrap_or_default(),
        }
    }
}

#[cfg(target_os = "windows")]
pub fn ensure_icon_file() -> std::path::PathBuf {
    const ICO_BYTES: &[u8] = include_bytes!("../resources/alien_rounded.ico");
    let mut p = std::env::var("LOCALAPPDATA")
        .map(std::path::PathBuf::from)
        .unwrap_or_else(|_| std::env::temp_dir());
    p.push("AlienAI");
    let _ = std::fs::create_dir_all(&p);
    p.push("alien_rounded.ico");
    if !p.exists() || std::fs::metadata(&p).map(|m| m.len() == 0).unwrap_or(true) {
        let _ = std::fs::write(&p, ICO_BYTES);
    }
    p
}
