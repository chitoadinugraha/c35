//! File media playback (Windows): ffmpeg H.264 to WebRTC video track.

use std::path::{Path, PathBuf};
use std::process::Stdio;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
use std::time::{Duration, SystemTime};

use anyhow::{anyhow, Context, Result};
use bytes::Bytes;
use c35_proto::{
    pb_encode, Message, RemoteMediaCloseRes, RemoteMediaEncoder, RemoteMediaOpenReq,
    RemoteMediaOpenRes, RemoteMediaState, RemoteMediaStatusRes,
};
use tokio::io::{AsyncReadExt, BufReader};
use tokio::process::Command;
use tokio::sync::watch;
use tracing::{info, warn};
use webrtc::media::Sample;
use webrtc::track::track_local::track_local_static_sample::TrackLocalStaticSample;

use super::media::{set_media_handler, MediaFrameKind};
use crate::tools::ffmpeg::ffmpeg_exe_path;

static FILE_MEDIA_ACTIVE: AtomicBool = AtomicBool::new(false);

struct PlaybackState {
    path: String,
    encoder: RemoteMediaEncoder,
    error: String,
    stop_tx: Option<watch::Sender<bool>>,
}

static PLAYBACK: Mutex<Option<PlaybackState>> = Mutex::new(None);
static VIDEO_TRACK: Mutex<Option<Arc<TrackLocalStaticSample>>> = Mutex::new(None);

pub fn is_file_media_active() -> bool {
    FILE_MEDIA_ACTIVE.load(Ordering::SeqCst)
}

pub fn set_video_track(track: Arc<TrackLocalStaticSample>) {
    if let Ok(mut g) = VIDEO_TRACK.lock() {
        *g = Some(track);
    }
}

pub fn register_media_handler() {
    set_media_handler(Arc::new(|kind, data| match kind {
        MediaFrameKind::Open => pb_encode(&media_open(data)),
        MediaFrameKind::Close => pb_encode(&media_close()),
        MediaFrameKind::Status => pb_encode(&media_status()),
    }));
}

fn idle_status() -> RemoteMediaStatusRes {
    RemoteMediaStatusRes {
        state: RemoteMediaState::Idle as i32,
        path: String::new(),
        error: String::new(),
        encoder: RemoteMediaEncoder::Unspecified as i32,
    }
}

fn media_status() -> RemoteMediaStatusRes {
    let g = PLAYBACK.lock().ok();
    let Some(st) = g.as_ref().and_then(|m| m.as_ref()) else {
        return idle_status();
    };
    let state = if FILE_MEDIA_ACTIVE.load(Ordering::SeqCst) {
        RemoteMediaState::Playing
    } else if !st.error.is_empty() {
        RemoteMediaState::Error
    } else {
        RemoteMediaState::Opening
    };
    RemoteMediaStatusRes {
        state: state as i32,
        path: st.path.clone(),
        error: st.error.clone(),
        encoder: st.encoder as i32,
    }
}

fn media_close() -> RemoteMediaCloseRes {
    stop_playback();
    RemoteMediaCloseRes {
        ok: true,
        error: String::new(),
        state: RemoteMediaState::Idle as i32,
    }
}

fn media_open(data: &[u8]) -> RemoteMediaOpenRes {
    let req = match RemoteMediaOpenReq::decode(data) {
        Ok(r) => r,
        Err(_) => {
            return RemoteMediaOpenRes {
                ok: false,
                error: "invalid RemoteMediaOpenReq".into(),
                state: RemoteMediaState::Error as i32,
                encoder: RemoteMediaEncoder::Unspecified as i32,
            };
        }
    };
    let path = req.path.trim();
    if path.is_empty() {
        return RemoteMediaOpenRes {
            ok: false,
            error: "empty path".into(),
            state: RemoteMediaState::Error as i32,
            encoder: RemoteMediaEncoder::Unspecified as i32,
        };
    }
    let pb = match path_resolve(path) {
        Ok(p) => p,
        Err(e) => {
            return RemoteMediaOpenRes {
                ok: false,
                error: e.to_string(),
                state: RemoteMediaState::Error as i32,
                encoder: RemoteMediaEncoder::Unspecified as i32,
            };
        }
    };
    if !pb.is_file() {
        return RemoteMediaOpenRes {
            ok: false,
            error: "path is not a file".into(),
            state: RemoteMediaState::Error as i32,
            encoder: RemoteMediaEncoder::Unspecified as i32,
        };
    }

    stop_playback();

    if let Err(hw_err) = try_hw_file_transcode(&pb) {
        info!("file media HW path skipped: {hw_err}");
    }

    let ffmpeg = ffmpeg_exe_path();
    if !ffmpeg.is_file() {
        return RemoteMediaOpenRes {
            ok: false,
            error: format!(
                "ffmpeg not installed at {} - wait for agent ffmpeg OTA or publish app.release.c35.ffmpeg-windows",
                ffmpeg.display()
            ),
            state: RemoteMediaState::Error as i32,
            encoder: RemoteMediaEncoder::Unspecified as i32,
        };
    }

    let track = match VIDEO_TRACK.lock().ok().and_then(|g| g.clone()) {
        Some(t) => t,
        None => {
            return RemoteMediaOpenRes {
                ok: false,
                error: "WebRTC video track not ready - connect Remote session first".into(),
                state: RemoteMediaState::Error as i32,
                encoder: RemoteMediaEncoder::Unspecified as i32,
            };
        }
    };

    let (stop_tx, stop_rx) = watch::channel(false);
    {
        let mut g = PLAYBACK.lock().expect("playback lock");
        *g = Some(PlaybackState {
            path: path.to_string(),
            encoder: RemoteMediaEncoder::Ffmpeg,
            error: String::new(),
            stop_tx: Some(stop_tx),
        });
    }
    FILE_MEDIA_ACTIVE.store(true, Ordering::SeqCst);

    let path_string = pb.to_string_lossy().into_owned();
    tokio::spawn(async move {
        if let Err(e) = ffmpeg_pipe_to_track(&path_string, &ffmpeg, track, stop_rx).await {
            warn!("file media playback ended: {e}");
            if let Ok(mut g) = PLAYBACK.lock() {
                if let Some(st) = g.as_mut() {
                    st.error = e.to_string();
                }
            }
        }
        FILE_MEDIA_ACTIVE.store(false, Ordering::SeqCst);
        if let Ok(mut g) = PLAYBACK.lock() {
            g.take();
        }
        info!("file media playback stopped; screen capture resumes");
    });

    RemoteMediaOpenRes {
        ok: true,
        error: String::new(),
        state: RemoteMediaState::Playing as i32,
        encoder: RemoteMediaEncoder::Ffmpeg as i32,
    }
}

fn stop_playback() {
    if let Ok(mut g) = PLAYBACK.lock() {
        if let Some(st) = g.take() {
            if let Some(tx) = st.stop_tx {
                let _ = tx.send(true);
            }
        }
    }
    FILE_MEDIA_ACTIVE.store(false, Ordering::SeqCst);
}

fn try_hw_file_transcode(_path: &Path) -> Result<()> {
    Err(anyhow!(
        "Media Foundation file demux/H.264 MFT pipeline not implemented (MVP); using ffmpeg fallback"
    ))
}

fn path_resolve(raw: &str) -> Result<PathBuf> {
    let p = PathBuf::from(raw);
    if p.components().any(|c| matches!(c, std::path::Component::ParentDir)) {
        return Err(anyhow!("path traversal rejected"));
    }
    Ok(p)
}

async fn ffmpeg_pipe_to_track(
    path: &str,
    ffmpeg: &Path,
    track: Arc<TrackLocalStaticSample>,
    mut stop_rx: watch::Receiver<bool>,
) -> Result<()> {
    info!(path, "starting ffmpeg file to H.264 WebRTC video track");

    let mut child = Command::new(ffmpeg)
        .args([
            "-hide_banner",
            "-loglevel",
            "error",
            "-re",
            "-i",
            path,
            "-an",
            "-c:v",
            "libx264",
            "-preset",
            "ultrafast",
            "-tune",
            "zerolatency",
            "-profile:v",
            "baseline",
            "-x264-params",
            "repeat-headers=1",
            "-f",
            "h264",
            "pipe:1",
        ])
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .kill_on_drop(true)
        .spawn()
        .context("spawn ffmpeg")?;

    let mut stdout = BufReader::new(
        child
            .stdout
            .take()
            .ok_or_else(|| anyhow!("ffmpeg stdout missing"))?,
    );
    let frame_duration = Duration::from_millis(33);
    let mut carry = Vec::new();
    let mut buf = vec![0u8; 64 * 1024];

    loop {
        if *stop_rx.borrow() {
            let _ = child.start_kill();
            return Ok(());
        }
        let n = tokio::select! {
            r = stdout.read(&mut buf) => r?,
            _ = stop_rx.changed() => {
                if *stop_rx.borrow() {
                    let _ = child.start_kill();
                    return Ok(());
                }
                continue;
            }
        };
        if n == 0 {
            if !carry.is_empty() {
                let tail = std::mem::take(&mut carry);
                let sample = Sample {
                    data: Bytes::from(tail),
                    duration: frame_duration,
                    timestamp: SystemTime::now(),
                    ..Default::default()
                };
                let _ = track.write_sample(&sample).await;
            }
            break;
        }
        carry.extend_from_slice(&buf[..n]);
        while let Some(nal) = take_annex_b_nal(&mut carry) {
            if nal.is_empty() {
                continue;
            }
            let sample = Sample {
                data: Bytes::from(nal),
                duration: frame_duration,
                timestamp: SystemTime::now(),
                ..Default::default()
            };
            if track.write_sample(&sample).await.is_err() {
                let _ = child.start_kill();
                return Err(anyhow!("video track write failed"));
            }
        }
    }

    let status = child.wait().await.context("ffmpeg wait")?;
    if !status.success() {
        return Err(anyhow!("ffmpeg exited with {:?}", status.code()));
    }
    Ok(())
}

fn take_annex_b_nal(carry: &mut Vec<u8>) -> Option<Vec<u8>> {
    let start = find_start_code(carry, 0)?;
    let next = find_start_code(carry, start + 3);
    let end = next.unwrap_or(carry.len());
    if next.is_none() && end.saturating_sub(start) < 5 {
        return None;
    }
    let nal = carry[start..end].to_vec();
    carry.drain(..end);
    Some(nal)
}

fn find_start_code(data: &[u8], from: usize) -> Option<usize> {
    let mut i = from;
    while i + 3 <= data.len() {
        if data[i] == 0 && data[i + 1] == 0 && data[i + 2] == 1 {
            return Some(i);
        }
        if i + 4 <= data.len()
            && data[i] == 0
            && data[i + 1] == 0
            && data[i + 2] == 0
            && data[i + 3] == 1
        {
            return Some(i);
        }
        i += 1;
    }
    None
}
