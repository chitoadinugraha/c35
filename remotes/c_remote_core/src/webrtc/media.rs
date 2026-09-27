//! File media playback over existing WebRTC H.264 video track (`remote-fs` channel).

use c35_proto::{
    pb_encode, RemoteMediaCloseRes, RemoteMediaEncoder, RemoteMediaOpenRes, RemoteMediaState,
    RemoteMediaStatusRes,
};

pub enum MediaFrameKind {
    Open,
    Close,
    Status,
}

pub fn media_frame_kind(data: &[u8]) -> Option<MediaFrameKind> {
    let mut has_f21 = false;
    let mut f21_wire = 0u8;
    let mut has_f22 = false;
    let mut has_f23 = false;
    let mut i = 0usize;
    while i < data.len() {
        let (field, wire) = match read_tag(data, &mut i) {
            Some(v) => v,
            None => break,
        };
        match field {
            21 => {
                has_f21 = true;
                f21_wire = wire;
            }
            22 if wire == 0 => has_f22 = true,
            23 if wire == 0 => has_f23 = true,
            _ => {}
        }
        if !skip_field(data, &mut i, wire) {
            break;
        }
    }
    if has_f21 && f21_wire == 2 {
        return Some(MediaFrameKind::Open);
    }
    if has_f22 {
        return Some(MediaFrameKind::Close);
    }
    if has_f23 {
        return Some(MediaFrameKind::Status);
    }
    None
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
        0 | 1 => {
            while *i < data.len() {
                if data[*i] & 0x80 == 0 {
                    *i += 1;
                    break;
                }
                *i += 1;
            }
            true
        }
        2 => {
            let (len, ok) = read_varint(data, i);
            if !ok {
                return false;
            }
            *i = i.saturating_add(len as usize);
            *i <= data.len()
        }
        5 => {
            *i += 4;
            *i <= data.len()
        }
        _ => false,
    }
}

fn read_varint(data: &[u8], i: &mut usize) -> (u64, bool) {
    let mut out = 0u64;
    let mut shift = 0u32;
    while *i < data.len() {
        let b = data[*i];
        *i += 1;
        out |= ((b & 0x7f) as u64) << shift;
        if b & 0x80 == 0 {
            return (out, true);
        }
        shift += 7;
        if shift > 63 {
            return (0, false);
        }
    }
    (0, false)
}

pub type MediaHandler = std::sync::Arc<
    dyn Fn(MediaFrameKind, &[u8]) -> Vec<u8> + Send + Sync,
>;

static MEDIA_HANDLER: std::sync::OnceLock<MediaHandler> = std::sync::OnceLock::new();

pub fn set_media_handler(handler: MediaHandler) {
    let _ = MEDIA_HANDLER.set(handler);
}

fn stub_open(_data: &[u8]) -> RemoteMediaOpenRes {
    RemoteMediaOpenRes {
        ok: false,
        error: "file media playback not supported on this agent platform".into(),
        state: RemoteMediaState::Error as i32,
        encoder: RemoteMediaEncoder::Unspecified as i32,
    }
}

fn stub_close() -> RemoteMediaCloseRes {
    RemoteMediaCloseRes {
        ok: true,
        error: String::new(),
        state: RemoteMediaState::Idle as i32,
    }
}

fn stub_status() -> RemoteMediaStatusRes {
    RemoteMediaStatusRes {
        state: RemoteMediaState::Idle as i32,
        path: String::new(),
        error: String::new(),
        encoder: RemoteMediaEncoder::Unspecified as i32,
    }
}

pub fn media_dispatch(kind: MediaFrameKind, data: &[u8]) -> Vec<u8> {
    if let Some(h) = MEDIA_HANDLER.get() {
        return h(kind, data);
    }
    match kind {
        MediaFrameKind::Open => pb_encode(&stub_open(data)),
        MediaFrameKind::Close => pb_encode(&stub_close()),
        MediaFrameKind::Status => pb_encode(&stub_status()),
    }
}
