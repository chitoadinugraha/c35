//! Windows filesystem ops for `remote-fs` data channel (protobuf frames).

use std::io::{Read, Seek, SeekFrom, Write};
use std::path::{Component, Path, PathBuf};
use std::time::UNIX_EPOCH;

use c35_proto::{
    pb_encode, Message, RemoteFsDeleteReq, RemoteFsDeleteRes, RemoteFsDriveKind, RemoteFsEntry,
    RemoteFsListReq, RemoteFsListRes, RemoteFsMkdirReq, RemoteFsMkdirRes, RemoteFsReadReq,
    RemoteFsReadRes, RemoteFsRenameReq, RemoteFsRenameRes, RemoteFsWriteReq, RemoteFsWriteRes,
};

const READ_CHUNK_DEFAULT: i32 = 256 * 1024;
const READ_CHUNK_MAX: i32 = 4 * 1024 * 1024;

enum FsFrameKind {
    List,
    Read,
    Write,
    Mkdir,
    Delete,
    Rename,
}

pub fn fs_dispatch(data: &[u8]) -> Vec<u8> {
    match fs_frame_kind(data) {
        FsFrameKind::List => {
            let req = match Message::decode(data) {
                Ok(r) => r,
                Err(_) => {
                    return pb_encode(&RemoteFsListRes {
                        entries: vec![],
                        error: "invalid RemoteFsListReq".into(),
                    });
                }
            };
            pb_encode(&fs_list(req))
        }
        FsFrameKind::Read => {
            let req = match Message::decode(data) {
                Ok(r) => r,
                Err(_) => {
                    return pb_encode(&RemoteFsReadRes {
                        data: vec![],
                        eof: true,
                        mime: String::new(),
                        error: "invalid RemoteFsReadReq".into(),
                    });
                }
            };
            pb_encode(&fs_read(req))
        }
        FsFrameKind::Write => {
            let req = match Message::decode(data) {
                Ok(r) => r,
                Err(_) => {
                    return pb_encode(&RemoteFsWriteRes {
                        bytes_written: 0,
                        error: "invalid RemoteFsWriteReq".into(),
                    });
                }
            };
            pb_encode(&fs_write(req))
        }
        FsFrameKind::Mkdir => {
            let req = match Message::decode(data) {
                Ok(r) => r,
                Err(_) => {
                    return pb_encode(&RemoteFsMkdirRes {
                        error: "invalid RemoteFsMkdirReq".into(),
                    });
                }
            };
            pb_encode(&fs_mkdir(req))
        }
        FsFrameKind::Delete => {
            let req = match Message::decode(data) {
                Ok(r) => r,
                Err(_) => {
                    return pb_encode(&RemoteFsDeleteRes {
                        error: "invalid RemoteFsDeleteReq".into(),
                    });
                }
            };
            pb_encode(&fs_delete(req))
        }
        FsFrameKind::Rename => {
            let req = match Message::decode(data) {
                Ok(r) => r,
                Err(_) => {
                    return pb_encode(&RemoteFsRenameRes {
                        error: "invalid RemoteFsRenameReq".into(),
                    });
                }
            };
            pb_encode(&fs_rename(req))
        }
    }
}

fn fs_frame_kind(data: &[u8]) -> FsFrameKind {
    let mut has_f1 = false;
    let mut has_f2 = false;
    let mut f2_wire = 0u8;
    let mut has_f3 = false;
    let mut f3_wire = 0u8;
    let mut has_f4 = false;
    let mut has_f5 = false;
    let mut i = 0usize;
    while i < data.len() {
        let (field, wire) = match read_tag(data, &mut i) {
            Some(v) => v,
            None => break,
        };
        match field {
            1 => has_f1 = true,
            2 => {
                has_f2 = true;
                f2_wire = wire;
            }
            3 => {
                has_f3 = true;
                f3_wire = wire;
            }
            4 => has_f4 = true,
            5 if wire == 2 => has_f5 = true,
            _ => {}
        }
        if !skip_field(data, &mut i, wire) {
            break;
        }
    }
    if has_f4 || (has_f3 && f3_wire == 2 && has_f1) {
        return FsFrameKind::Write;
    }
    if has_f3 && f3_wire == 0 {
        return FsFrameKind::Read;
    }
    if has_f1 && has_f2 && f2_wire == 2 {
        return FsFrameKind::Rename;
    }
    if has_f5 {
        return FsFrameKind::Delete;
    }
    if has_f2 && f2_wire == 2 && !has_f1 {
        return FsFrameKind::Mkdir;
    }
    FsFrameKind::List
}

fn read_tag(data: &[u8], i: &mut usize) -> Option<(u32, u8)> {
    if *i >= data.len() {
        return None;
    }
    let tag = data[*i];
    *i += 1;
    Some(((tag >> 3) as u32, tag & 0x07))
}

fn skip_field(data: &[u8], i: &mut usize, wire: u8) -> bool {
    match wire {
        0 => skip_varint(data, i),
        1 => {
            *i += 8;
            *i <= data.len()
        }
        2 => match read_varint(data, i) {
            Some(len) => {
                *i += len as usize;
                *i <= data.len()
            }
            None => false,
        }
        5 => {
            *i += 4;
            *i <= data.len()
        }
        _ => false,
    }
}

fn skip_varint(data: &[u8], i: &mut usize) -> bool {
    while *i < data.len() {
        *i += 1;
        if data[*i - 1] & 0x80 == 0 {
            return true;
        }
    }
    false
}

fn read_varint(data: &[u8], i: &mut usize) -> Option<u64> {
    let mut out = 0u64;
    let mut shift = 0u32;
    while *i < data.len() {
        let b = data[*i];
        *i += 1;
        out |= ((b & 0x7f) as u64) << shift;
        if b & 0x80 == 0 {
            return Some(out);
        }
        shift += 7;
        if shift > 63 {
            return None;
        }
    }
    None
}

pub fn fs_list(req: RemoteFsListReq) -> RemoteFsListRes {
    let path = req.path.trim();
    if path.is_empty() {
        return RemoteFsListRes {
            entries: list_drives(),
            error: String::new(),
        };
    }
    match path_resolve(path) {
        Ok(p) => match std::fs::read_dir(&p) {
            Ok(rd) => {
                let mut entries = Vec::new();
                for ent in rd.flatten() {
                    let meta = ent.metadata().ok();
                    let is_dir = meta.as_ref().map(|m| m.is_dir()).unwrap_or(false);
                    let size = meta.as_ref().map(|m| m.len() as i64).unwrap_or(0);
                    let modified_ms = meta
                        .as_ref()
                        .and_then(|m| m.modified().ok())
                        .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
                        .map(|d| d.as_millis() as i64)
                        .unwrap_or(0);
                    let name = ent.file_name().to_string_lossy().into_owned();
                    let child = ent.path();
                    entries.push(RemoteFsEntry {
                        name,
                        path: path_display(&child),
                        is_dir,
                        size,
                        modified_ms,
                        drive_kind: RemoteFsDriveKind::Unspecified.into(),
                    });
                }
                entries.sort_by(|a, b| {
                    b.is_dir
                        .cmp(&a.is_dir)
                        .then_with(|| a.name.to_lowercase().cmp(&b.name.to_lowercase()))
                });
                RemoteFsListRes {
                    entries,
                    error: String::new(),
                }
            }
            Err(e) => RemoteFsListRes {
                entries: vec![],
                error: e.to_string(),
            },
        },
        Err(e) => RemoteFsListRes {
            entries: vec![],
            error: e,
        },
    }
}

pub fn fs_read(req: RemoteFsReadReq) -> RemoteFsReadRes {
    let path = req.path.trim();
    if path.is_empty() {
        return RemoteFsReadRes {
            data: vec![],
            eof: true,
            mime: String::new(),
            error: "path required".into(),
        };
    }
    let length = if req.length <= 0 {
        READ_CHUNK_DEFAULT
    } else {
        req.length.min(READ_CHUNK_MAX)
    };
    match path_resolve(path) {
        Ok(p) => match std::fs::File::open(&p) {
            Ok(mut f) => {
                if let Err(e) = f.seek(SeekFrom::Start(req.offset as u64)) {
                    return RemoteFsReadRes {
                        data: vec![],
                        eof: true,
                        mime: String::new(),
                        error: e.to_string(),
                    };
                }
                let mut buf = vec![0u8; length as usize];
                match f.read(&mut buf) {
                    Ok(n) => {
                        buf.truncate(n);
                        let meta = f.metadata().ok();
                        let total = meta.map(|m| m.len()).unwrap_or(0);
                        let eof = req.offset as u64 + n as u64 >= total;
                        RemoteFsReadRes {
                            data: buf,
                            eof,
                            mime: mime_guess(&p),
                            error: String::new(),
                        }
                    }
                    Err(e) => RemoteFsReadRes {
                        data: vec![],
                        eof: true,
                        mime: String::new(),
                        error: e.to_string(),
                    },
                }
            }
            Err(e) => RemoteFsReadRes {
                data: vec![],
                eof: true,
                mime: String::new(),
                error: e.to_string(),
            },
        },
        Err(e) => RemoteFsReadRes {
            data: vec![],
            eof: true,
            mime: String::new(),
            error: e,
        },
    }
}

pub fn fs_write(req: RemoteFsWriteReq) -> RemoteFsWriteRes {
    let path = req.path.trim();
    if path.is_empty() {
        return RemoteFsWriteRes {
            bytes_written: 0,
            error: "path required".into(),
        };
    }
    match path_resolve(path) {
        Ok(p) => {
            if let Some(parent) = p.parent() {
                if let Err(e) = std::fs::create_dir_all(parent) {
                    return RemoteFsWriteRes {
                        bytes_written: 0,
                        error: e.to_string(),
                    };
                }
            }
            let mut open_opts = std::fs::OpenOptions::new();
            open_opts.write(true).create(true);
            if req.offset > 0 {
                open_opts.read(true);
            }
            match open_opts.open(&p) {
                Ok(mut f) => {
                    if req.offset > 0 {
                        if let Err(e) = f.seek(SeekFrom::Start(req.offset as u64)) {
                            return RemoteFsWriteRes {
                                bytes_written: 0,
                                error: e.to_string(),
                            };
                        }
                    }
                    match f.write(&req.data) {
                        Ok(n) => {
                            if req.finalize {
                                let _ = f.flush();
                            }
                            RemoteFsWriteRes {
                                bytes_written: n as i64,
                                error: String::new(),
                            }
                        }
                        Err(e) => RemoteFsWriteRes {
                            bytes_written: 0,
                            error: e.to_string(),
                        },
                    }
                }
                Err(e) => RemoteFsWriteRes {
                    bytes_written: 0,
                    error: e.to_string(),
                },
            }
        }
        Err(e) => RemoteFsWriteRes {
            bytes_written: 0,
            error: e,
        },
    }
}

pub fn fs_mkdir(req: RemoteFsMkdirReq) -> RemoteFsMkdirRes {
    let path = req.path.trim();
    if path.is_empty() {
        return RemoteFsMkdirRes {
            error: "path required".into(),
        };
    }
    match path_resolve(path) {
        Ok(p) => RemoteFsMkdirRes {
            error: std::fs::create_dir_all(&p)
                .err()
                .map(|e| e.to_string())
                .unwrap_or_default(),
        },
        Err(e) => RemoteFsMkdirRes { error: e },
    }
}

pub fn fs_delete(req: RemoteFsDeleteReq) -> RemoteFsDeleteRes {
    let path = req.path.trim();
    if path.is_empty() {
        return RemoteFsDeleteRes {
            error: "path required".into(),
        };
    }
    match path_resolve(path) {
        Ok(p) => match std::fs::symlink_metadata(&p) {
            Ok(meta) => {
                let err = if meta.is_dir() {
                    std::fs::remove_dir_all(&p).err()
                } else {
                    std::fs::remove_file(&p).err()
                };
                RemoteFsDeleteRes {
                    error: err.map(|e| e.to_string()).unwrap_or_default(),
                }
            }
            Err(e) => RemoteFsDeleteRes {
                error: e.to_string(),
            },
        },
        Err(e) => RemoteFsDeleteRes { error: e },
    }
}

pub fn fs_rename(req: RemoteFsRenameReq) -> RemoteFsRenameRes {
    let from = req.from_path.trim();
    let to = req.to_path.trim();
    if from.is_empty() || to.is_empty() {
        return RemoteFsRenameRes {
            error: "from_path and to_path required".into(),
        };
    }
    match (path_resolve(from), path_resolve(to)) {
        (Ok(from_p), Ok(to_p)) => RemoteFsRenameRes {
            error: std::fs::rename(&from_p, &to_p)
                .err()
                .map(|e| e.to_string())
                .unwrap_or_default(),
        },
        (Err(e), _) | (_, Err(e)) => RemoteFsRenameRes { error: e },
    }
}

fn list_drives() -> Vec<RemoteFsEntry> {
    ('A'..='Z')
        .filter_map(|c| {
            let root = format!("{}:\\", c);
            if !Path::new(&root).exists() {
                return None;
            }
            let kind = drive_kind_for_root(&root);
            Some(RemoteFsEntry {
                name: drive_display_name(c, &root, kind),
                path: root,
                is_dir: true,
                size: 0,
                modified_ms: 0,
                drive_kind: kind.into(),
            })
        })
        .collect()
}

fn drive_kind_for_root(root: &str) -> RemoteFsDriveKind {
    #[cfg(windows)]
    {
        return drive_kind_windows(root);
    }
    #[cfg(not(windows))]
    {
        RemoteFsDriveKind::Fixed
    }
}

#[cfg(windows)]
fn drive_kind_windows(root: &str) -> RemoteFsDriveKind {
    use std::ffi::OsStr;
    use std::os::windows::ffi::OsStrExt;
    use windows::core::PCWSTR;
    use windows::Win32::Storage::FileSystem::GetDriveTypeW;

    let wide: Vec<u16> = OsStr::new(root).encode_wide().chain(Some(0)).collect();
    match unsafe { GetDriveTypeW(PCWSTR(wide.as_ptr())) } {
        2 => RemoteFsDriveKind::Removable,
        3 => RemoteFsDriveKind::Fixed,
        4 => RemoteFsDriveKind::Remote,
        5 => RemoteFsDriveKind::Cdrom,
        6 => RemoteFsDriveKind::Ram,
        _ => RemoteFsDriveKind::Fixed,
    }
}

fn drive_display_name(letter: char, root: &str, kind: RemoteFsDriveKind) -> String {
    #[cfg(windows)]
    {
        if let Some(label) = drive_volume_label_windows(root) {
            if !label.is_empty() {
                return format!("{} ({}:)", label, letter);
            }
        }
    }
    match kind {
        RemoteFsDriveKind::Remote => format!("Network ({letter}:)"),
        RemoteFsDriveKind::Removable => format!("USB Drive ({letter}:)"),
        RemoteFsDriveKind::Cdrom => format!("DVD ({letter}:)"),
        RemoteFsDriveKind::Ram => format!("RAM Disk ({letter}:)"),
        _ => format!("Local Disk ({letter}:)"),
    }
}

#[cfg(windows)]
fn drive_volume_label_windows(root: &str) -> Option<String> {
    use std::ffi::OsStr;
    use std::os::windows::ffi::OsStrExt;
    use windows::core::PCWSTR;
    use windows::Win32::Storage::FileSystem::GetVolumeInformationW;

    let wide: Vec<u16> = OsStr::new(root).encode_wide().chain(Some(0)).collect();
    let mut label = [0u16; 261];
    let ok = unsafe {
        GetVolumeInformationW(
            PCWSTR(wide.as_ptr()),
            Some(&mut label),
            None,
            None,
            None,
            None,
        )
    };
    if ok.is_err() {
        return None;
    }
    let end = label.iter().position(|&c| c == 0).unwrap_or(label.len());
    let s = String::from_utf16_lossy(&label[..end]).trim().to_string();
    if s.is_empty() { None } else { Some(s) }
}

#[cfg(not(windows))]
fn drive_volume_label_windows(_root: &str) -> Option<String> {
    None
}

pub fn path_resolve(raw: &str) -> Result<PathBuf, String> {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return Ok(PathBuf::new());
    }
    if trimmed.contains("..") {
        return Err("path traversal denied".into());
    }
    let path = PathBuf::from(trimmed);
    for comp in path.components() {
        if comp == Component::ParentDir {
            return Err("path traversal denied".into());
        }
    }
    if let Some(stem) = path.to_str() {
        if stem.contains("..") {
            return Err("path traversal denied".into());
        }
    }
    Ok(path)
}

fn path_display(path: &Path) -> String {
    path.to_string_lossy().replace('/', "\\")
}

fn mime_guess(path: &Path) -> String {
    let ext = path
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("")
        .to_ascii_lowercase();
    match ext.as_str() {
        "txt" | "md" | "log" | "ini" => "text/plain".into(),
        "json" => "application/json".into(),
        "html" | "htm" => "text/html".into(),
        "png" => "image/png".into(),
        "jpg" | "jpeg" => "image/jpeg".into(),
        "gif" => "image/gif".into(),
        "webp" => "image/webp".into(),
        "pdf" => "application/pdf".into(),
        "mp4" => "video/mp4".into(),
        "mp3" => "audio/mpeg".into(),
        _ => "application/octet-stream".into(),
    }
}
