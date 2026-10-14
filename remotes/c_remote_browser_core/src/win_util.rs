//! Windows helpers: spawn without console flash, shell open, registry.

#[cfg(windows)]
pub fn spawn_no_console(program: &str, args: &[&str]) -> std::io::Result<std::process::Child> {
    use std::os::windows::process::CommandExt;
    const CREATE_NO_WINDOW: u32 = 0x0800_0000;
    std::process::Command::new(program)
        .args(args)
        .creation_flags(CREATE_NO_WINDOW)
        .spawn()
}

#[cfg(windows)]
pub fn shell_open(path_or_url: &str) -> anyhow::Result<()> {
    use std::ffi::OsStr;
    use std::os::windows::ffi::OsStrExt;
    use windows_sys::Win32::UI::Shell::ShellExecuteW;
    use windows_sys::Win32::UI::WindowsAndMessaging::SW_SHOWNORMAL;

    let op: Vec<u16> = OsStr::new("open")
        .encode_wide()
        .chain(Some(0))
        .collect();
    let target: Vec<u16> = OsStr::new(path_or_url)
        .encode_wide()
        .chain(Some(0))
        .collect();
    let ret = unsafe {
        ShellExecuteW(
            std::ptr::null_mut(),
            op.as_ptr(),
            target.as_ptr(),
            std::ptr::null(),
            std::ptr::null(),
            SW_SHOWNORMAL as i32,
        )
    };
    if (ret as isize) <= 32 {
        anyhow::bail!("ShellExecuteW failed for {}", path_or_url);
    }
    Ok(())
}

#[cfg(windows)]
pub fn reg_set_native_host_manifest(subkey: &str, manifest_path: &str) -> anyhow::Result<()> {
    use std::ffi::OsStr;
    use std::os::windows::ffi::OsStrExt;
    use windows_sys::Win32::System::Registry::{
        RegCloseKey, RegCreateKeyW, RegSetValueExW, HKEY, HKEY_CURRENT_USER, KEY_WRITE, REG_SZ,
    };

    fn wide(s: &str) -> Vec<u16> {
        OsStr::new(s).encode_wide().chain(Some(0)).collect()
    }

    let subkey_w = wide(subkey);
    let mut hkey: HKEY = std::ptr::null_mut();
    let st = unsafe {
        RegCreateKeyW(
            HKEY_CURRENT_USER,
            subkey_w.as_ptr(),
            &mut hkey,
        )
    };
    if st != 0 {
        anyhow::bail!("RegCreateKeyW failed ({st})");
    }
    let name: Vec<u16> = wide("");
    let val = wide(manifest_path);
    let byte_len = (val.len() - 1) * 2;
    let bytes =
        unsafe { std::slice::from_raw_parts(val.as_ptr() as *const u8, byte_len) };
    let st = unsafe {
        RegSetValueExW(
            hkey,
            name.as_ptr(),
            0,
            REG_SZ,
            bytes.as_ptr(),
            byte_len as u32,
        )
    };
    let _ = unsafe { RegCloseKey(hkey) };
    if st != 0 {
        anyhow::bail!("RegSetValueExW failed ({st})");
    }
    Ok(())
}

#[cfg(windows)]
pub fn reg_query_default_value(subkey: &str) -> Option<String> {
    use std::ffi::OsStr;
    use std::os::windows::ffi::OsStrExt;
    use windows_sys::Win32::System::Registry::{
        RegCloseKey, RegOpenKeyExW, RegQueryValueExW, HKEY, HKEY_CURRENT_USER, KEY_READ,
    };

    fn wide(s: &str) -> Vec<u16> {
        OsStr::new(s).encode_wide().chain(Some(0)).collect()
    }

    let subkey_w = wide(subkey);
    let mut hkey: HKEY = std::ptr::null_mut();
    if unsafe {
        RegOpenKeyExW(HKEY_CURRENT_USER, subkey_w.as_ptr(), 0, KEY_READ, &mut hkey)
    } != 0
    {
        return None;
    }
    let name: Vec<u16> = wide("");
    let mut ty = 0u32;
    let mut len = 0u32;
    if unsafe {
        RegQueryValueExW(
            hkey,
            name.as_ptr(),
            std::ptr::null_mut(),
            &mut ty,
            std::ptr::null_mut(),
            &mut len,
        )
    } != 0
        || len < 2
    {
        let _ = unsafe { RegCloseKey(hkey) };
        return None;
    }
    let mut buf = vec![0u8; len as usize];
    if unsafe {
        RegQueryValueExW(
            hkey,
            name.as_ptr(),
            std::ptr::null_mut(),
            &mut ty,
            buf.as_mut_ptr(),
            &mut len,
        )
    } != 0
    {
        let _ = unsafe { RegCloseKey(hkey) };
        return None;
    }
    let _ = unsafe { RegCloseKey(hkey) };
    let wide_len = (len as usize / 2).saturating_sub(1);
    let u16s: &[u16] =
        unsafe { std::slice::from_raw_parts(buf.as_ptr() as *const u16, wide_len) };
    String::from_utf16(u16s).ok()
}

#[cfg(not(windows))]
pub fn spawn_no_console(program: &str, args: &[&str]) -> std::io::Result<std::process::Child> {
    std::process::Command::new(program).args(args).spawn()
}

#[cfg(not(windows))]
pub fn shell_open(path_or_url: &str) -> anyhow::Result<()> {
    std::process::Command::new("xdg-open").arg(path_or_url).spawn()?;
    Ok(())
}

#[cfg(not(windows))]
pub fn reg_set_native_host_manifest(_subkey: &str, _manifest_path: &str) -> anyhow::Result<()> {
    Ok(())
}

#[cfg(not(windows))]
pub fn reg_query_default_value(_subkey: &str) -> Option<String> {
    None
}
