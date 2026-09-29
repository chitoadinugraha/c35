//! Detect Chrome-launched native messaging (Windows may omit manifest `args`).

#[cfg(windows)]
pub fn launched_by_chrome_browser() -> bool {
    chrome_ancestor_process_basename(6).is_some()
}

#[cfg(not(windows))]
pub fn launched_by_chrome_browser() -> bool {
    false
}

#[cfg(windows)]
fn chrome_ancestor_process_basename(max_depth: u32) -> Option<String> {
    use windows_sys::Win32::Foundation::{HANDLE, INVALID_HANDLE_VALUE};
    use windows_sys::Win32::System::Diagnostics::ToolHelp::{
        CreateToolhelp32Snapshot, Process32FirstW, Process32NextW, PROCESSENTRY32W,
        TH32CS_SNAPPROCESS,
    };

    unsafe {
        let snap: HANDLE = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
        if snap == INVALID_HANDLE_VALUE {
            return None;
        }
        let mut pid = std::process::id();
        for _ in 0..max_depth {
            let parent = process_parent_pid(snap, pid)?;
            if parent == 0 {
                break;
            }
            if let Some(name) = process_basename(snap, parent) {
                let lower = name.to_ascii_lowercase();
                if lower == "chrome.exe"
                    || lower == "msedge.exe"
                    || lower == "brave.exe"
                    || lower.starts_with("chrome")
                {
                    return Some(lower);
                }
            }
            pid = parent;
        }
        None
    }
}

#[cfg(windows)]
fn process_parent_pid(snap: windows_sys::Win32::Foundation::HANDLE, pid: u32) -> Option<u32> {
    use windows_sys::Win32::System::Diagnostics::ToolHelp::{
        Process32FirstW, Process32NextW, PROCESSENTRY32W,
    };

    unsafe {
        let mut entry = PROCESSENTRY32W {
            dwSize: std::mem::size_of::<PROCESSENTRY32W>() as u32,
            ..std::mem::zeroed()
        };
        if Process32FirstW(snap, &mut entry) == 0 {
            return None;
        }
        loop {
            if entry.th32ProcessID == pid {
                return Some(entry.th32ParentProcessID);
            }
            if Process32NextW(snap, &mut entry) == 0 {
                return None;
            }
        }
    }
}

#[cfg(windows)]
fn process_basename(
    snap: windows_sys::Win32::Foundation::HANDLE,
    pid: u32,
) -> Option<String> {
    use windows_sys::Win32::System::Diagnostics::ToolHelp::{
        Process32FirstW, Process32NextW, PROCESSENTRY32W,
    };

    unsafe {
        let mut entry = PROCESSENTRY32W {
            dwSize: std::mem::size_of::<PROCESSENTRY32W>() as u32,
            ..std::mem::zeroed()
        };
        if Process32FirstW(snap, &mut entry) == 0 {
            return None;
        }
        loop {
            if entry.th32ProcessID == pid {
                let len = entry
                    .szExeFile
                    .iter()
                    .position(|&c| c == 0)
                    .unwrap_or(entry.szExeFile.len());
                return Some(String::from_utf16_lossy(&entry.szExeFile[..len]));
            }
            if Process32NextW(snap, &mut entry) == 0 {
                return None;
            }
        }
    }
}