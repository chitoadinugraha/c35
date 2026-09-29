//! Skill teach recorder over `remote-teach` data channel (protobuf frames).

use c35_proto::{
    pb_encode, Message, RemoteTeachStartReq, RemoteTeachStartRes, RemoteTeachStatusReq,
    RemoteTeachStatusRes, RemoteTeachStep, RemoteTeachStopReq, RemoteTeachStopRes,
};

use crate::skill_teach::{self, TeachStepRecord};

enum TeachFrameKind {
    Start,
    Stop,
    Status,
}

pub fn teach_dispatch(data: &[u8]) -> Vec<u8> {
    match teach_frame_kind(data) {
        TeachFrameKind::Start => {
            let req = match RemoteTeachStartReq::decode(data) {
                Ok(r) => r,
                Err(_) => {
                    return pb_encode(&RemoteTeachStartRes {
                        ok: false,
                        error: "invalid RemoteTeachStartReq".into(),
                    });
                }
            };
            pb_encode(&teach_start(req))
        }
        TeachFrameKind::Stop => {
            if RemoteTeachStopReq::decode(data).is_err() {
                return pb_encode(&RemoteTeachStopRes {
                    steps: vec![],
                    error: "invalid RemoteTeachStopReq".into(),
                });
            }
            pb_encode(&teach_stop())
        }
        TeachFrameKind::Status => {
            if RemoteTeachStatusReq::decode(data).is_err() {
                return pb_encode(&RemoteTeachStatusRes {
                    recording: false,
                    steps: vec![],
                    duration_sec: 0,
                    last_label: String::new(),
                    error: "invalid RemoteTeachStatusReq".into(),
                });
            }
            pb_encode(&teach_status())
        }
    }
}

fn teach_start(req: RemoteTeachStartReq) -> RemoteTeachStartRes {
    match skill_teach::teach_start(req.title.trim()) {
        Ok(()) => RemoteTeachStartRes {
            ok: true,
            error: String::new(),
        },
        Err(e) => RemoteTeachStartRes {
            ok: false,
            error: e.to_string(),
        },
    }
}

fn teach_stop() -> RemoteTeachStopRes {
    match skill_teach::teach_stop() {
        Ok(steps) => RemoteTeachStopRes {
            steps: steps_to_wire(&steps),
            error: String::new(),
        },
        Err(e) => RemoteTeachStopRes {
            steps: vec![],
            error: e.to_string(),
        },
    }
}

fn teach_status() -> RemoteTeachStatusRes {
    let st = skill_teach::teach_status();
    RemoteTeachStatusRes {
        recording: st.recording,
        steps: steps_to_wire(&st.steps),
        duration_sec: st.duration_sec,
        last_label: st.last_label,
        error: String::new(),
    }
}

fn steps_to_wire(steps: &[TeachStepRecord]) -> Vec<RemoteTeachStep> {
    steps
        .iter()
        .map(|s| RemoteTeachStep {
            ord: s.ord,
            kind: s.kind.clone(),
            label: s.label.clone(),
            ax_target_json: s.ax_target_json.clone(),
        })
        .collect()
}

fn teach_frame_kind(data: &[u8]) -> TeachFrameKind {
    let mut has_f1 = false;
    let mut f1_wire = 0u8;
    let mut has_f2 = false;
    let mut has_f31 = false;
    let mut has_f32 = false;
    let mut i = 0usize;
    while i < data.len() {
        let (field, wire) = match read_tag(data, &mut i) {
            Some(v) => v,
            None => break,
        };
        match field {
            1 => {
                has_f1 = true;
                f1_wire = wire;
            }
            2 if wire == 0 => has_f2 = true,
            31 if wire == 0 => has_f31 = true,
            32 if wire == 0 => has_f32 = true,
            _ => {}
        }
        if !skip_field(data, &mut i, wire) {
            break;
        }
    }
    if has_f31 {
        return TeachFrameKind::Stop;
    }
    if has_f32 {
        return TeachFrameKind::Status;
    }
    if has_f1 || has_f2 || (has_f1 && f1_wire == 2) {
        return TeachFrameKind::Start;
    }
    TeachFrameKind::Status
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
    while *i < data.len() && shift <= 63 {
        let b = data[*i];
        *i += 1;
        out |= ((b & 0x7f) as u64) << shift;
        if b & 0x80 == 0 {
            return (out, true);
        }
        shift += 7;
    }
    (0, false)
}
