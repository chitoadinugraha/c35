#[cfg(target_os = "windows")]
mod win_impl {
    use std::ffi::c_void;
    use std::os::windows::ffi::OsStrExt;
    use std::path::PathBuf;
    use std::sync::mpsc;
    use std::time::Duration;

    use tracing::{info, warn};
    use windows::Win32::Foundation::HANDLE;
    use windows::Win32::Storage::FileSystem::{
        CreateFileW, FILE_FLAG_BACKUP_SEMANTICS, FILE_LIST_DIRECTORY, FILE_NOTIFY_CHANGE,
        FILE_SHARE_DELETE, FILE_SHARE_READ, FILE_SHARE_WRITE, OPEN_EXISTING, ReadDirectoryChangesW,
    };
    use windows::core::PCWSTR;

    use crate::sync_wake;
    use crate::vfs::VfsDriveManager;

    const NOTIFY_FILTER: FILE_NOTIFY_CHANGE = FILE_NOTIFY_CHANGE(0x0000000F);

    pub fn start_drive_watcher(backing_dir: PathBuf) {
        std::thread::Builder::new()
            .name("alienai-drive-watch".into())
            .spawn(move || watch_supervisor(backing_dir))
            .ok();
    }

    fn watch_supervisor(root: PathBuf) {
        let (signal_tx, signal_rx) = mpsc::channel::<()>();
        let root_watch = root.clone();
        std::thread::Builder::new()
            .name("alienai-drive-watch-io".into())
            .spawn(move || {
                if let Err(e) = watch_loop(&root_watch, move || {
                    let _ = signal_tx.send(());
                }) {
                    warn!("Drive FS watcher exited: {e:#}");
                }
            })
            .ok();
        info!("Drive FS watcher started on {:?}", root);
        while signal_rx.recv().is_ok() {
            while signal_rx.recv_timeout(Duration::from_millis(400)).is_ok() {}
            sync_wake::wake_sync();
        }
    }

    fn watch_loop(root: &PathBuf, mut on_change: impl FnMut() + Send + 'static) -> anyhow::Result<()> {
        let wide: Vec<u16> = root.as_os_str().encode_wide().chain(std::iter::once(0)).collect();
        unsafe {
            let handle = CreateFileW(
                PCWSTR(wide.as_ptr()),
                FILE_LIST_DIRECTORY.0,
                FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                None,
                OPEN_EXISTING,
                FILE_FLAG_BACKUP_SEMANTICS,
                HANDLE::default(),
            )?;
            if handle.is_invalid() {
                anyhow::bail!("CreateFileW on drive root failed");
            }
            let mut buffer = vec![0u8; 64 * 1024];
            loop {
                let mut bytes_returned = 0u32;
                let ok = ReadDirectoryChangesW(
                    handle,
                    buffer.as_mut_ptr() as *mut c_void,
                    buffer.len() as u32,
                    true,
                    NOTIFY_FILTER,
                    Some(&mut bytes_returned),
                    None,
                    None,
                );
                if ok.is_err() {
                    std::thread::sleep(Duration::from_secs(2));
                    continue;
                }
                if bytes_returned > 0 {
                    parse_notify_buffer(root, &buffer[..bytes_returned as usize], &mut on_change);
                }
            }
        }
    }

    fn parse_notify_buffer(_root: &PathBuf, buf: &[u8], on_change: &mut impl FnMut()) {
        let mut offset = 0usize;
        while offset < buf.len() {
            if offset + 12 > buf.len() {
                break;
            }
            let next = u32::from_le_bytes(buf[offset..offset + 4].try_into().unwrap()) as usize;
            let _action = u32::from_le_bytes(buf[offset + 4..offset + 8].try_into().unwrap());
            let name_len = u32::from_le_bytes(buf[offset + 8..offset + 12].try_into().unwrap()) as usize;
            let name_start = offset + 12;
            let name_end = name_start + name_len;
            if name_end > buf.len() {
                break;
            }
            let wide: Vec<u16> = buf[name_start..name_end]
                .chunks_exact(2)
                .map(|c| u16::from_le_bytes([c[0], c[1]]))
                .take_while(|&c| c != 0)
                .collect();
            let name = String::from_utf16_lossy(&wide);
            let rel = PathBuf::from(name);
            if !VfsDriveManager::is_internal_path(&rel) {
                let rel_s = rel.to_string_lossy().replace('\\', "/");
                sync_wake::pending_push(&rel_s);
                on_change();
            }
            if next == 0 {
                break;
            }
            offset += next;
        }
    }
}

#[cfg(target_os = "windows")]
pub use win_impl::*;

#[cfg(not(target_os = "windows"))]
pub fn start_drive_watcher(_backing_dir: std::path::PathBuf) {}
