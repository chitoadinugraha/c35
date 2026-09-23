//! Windows filesystem ops for `remote-fs` data channel (protobuf frames).

use std::io::{Read, Seek, SeekFrom, Write};
use std::path::{Component, Path, PathBuf};
use std::time::UNIX_EPOCH;

use c35_proto::{
    pb_encode, Message, RemoteFsEntry, RemoteFsListReq, RemoteFsListRes, RemoteFsReadReq,
    RemoteFsReadRes, RemoteFsWriteReq, RemoteFsWriteRes,
};

const READ_CHUNK_DEFAULT: i32 = 256 * 1024;
const READ_CHUNK_MAX: i32 = 4 * 1024 * 1024;

enum FsFrameKind {
    List,
    Read,
    Write,
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
    }
}

fn fs_frame_kind(data: &[u8]) -> FsFrameKind {
    let mut i = 0usize;
    while i < data.len() {
        let (tag, wire) = match read_tag(data, &mut i) {
            Some(v) => v,
            None => break,
        };
        let field = tag >> 3;
        if field == 3 {
            return if wire == 2 {
                FsFrameKind::Write
            } else {
                FsFrameKind::Read
            };
        }
        if !skip_field(data, &mut i, wire) {
            break;
        }
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

fn list_drives() -> Vec<RemoteFsEntry> {
    ('A'..='Z')
        .filter_map(|c| {
            let root = format!("{}:\\", c);
            if Path::new(&root).exists() {
                Some(RemoteFsEntry {
                    name: format!("{}:", c),
                    path: root,
                    is_dir: true,
                    size: 0,
                    modified_ms: 0,
                })
            } else {
                None
            }
        })
        .collect()
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
        "txt" | "md" | "log" => "text/plain".into(),
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
