//! WebRTC data channel and media handlers bridging c_remote_core with Android.

use std::sync::{Arc, OnceLock, RwLock};
use bytes::Bytes;
use tracing::info;
use webrtc::track::track_local::track_local_static_sample::TrackLocalStaticSample;
use webrtc::media::Sample;

use crate::som_overlay::{draw_red_marker_rgba, draw_som_overlay_rgba, Mark};

pub type InputCallback = Box<dyn Fn(String, f64, f64, String, i32, i32) + Send + Sync + 'static>;
static INPUT_CB: OnceLock<InputCallback> = OnceLock::new();

pub fn set_input_callback(cb: InputCallback) {
    let _ = INPUT_CB.set(cb);
}

#[derive(Clone, Default)]
pub struct FrameBuffer {
    pub width: u32,
    pub height: u32,
    pub rgba: Vec<u8>,
}

static LATEST_FRAME: RwLock<Option<FrameBuffer>> = RwLock::new(None);
static LATEST_MARKS: RwLock<Vec<Mark>> = RwLock::new(Vec::new());

pub fn update_frame_buffer(width: u32, height: u32, rgba: Vec<u8>) {
    if let Ok(mut lock) = LATEST_FRAME.write() {
        *lock = Some(FrameBuffer { width, height, rgba });
    }
}

pub fn update_som_marks(marks: Vec<Mark>) {
    if let Ok(mut lock) = LATEST_MARKS.write() {
        *lock = marks;
    }
}

static VIDEO_TRACK: OnceLock<Arc<TrackLocalStaticSample>> = OnceLock::new();

pub fn set_video_track(track: Arc<TrackLocalStaticSample>) {
    let _ = VIDEO_TRACK.set(track);
}

pub async fn push_h264_sample(nal_data: &[u8], duration_ms: u32) -> anyhow::Result<()> {
    if let Some(track) = VIDEO_TRACK.get() {
        track.write_sample(&Sample {
            data: Bytes::copy_from_slice(nal_data),
            duration: std::time::Duration::from_millis(duration_ms as u64),
            ..Default::default()
        }).await?;
    }
    Ok(())
}

/// Initialize the WebRTC handlers in c_remote_core.
pub fn init_webrtc_handlers() {
    // 1. Input Handler: receives RemoteInputEvent from WebRTC data channel "remote-input"
    c_remote_core::webrtc::set_input_handler(Arc::new(|evt| {
        if let Some(cb) = INPUT_CB.get() {
            let evt_type = evt.event_type.clone();
            let x = evt.x;
            let y = evt.y;
            let text = evt.text.clone();
            let button = evt.button;
            let key_code = evt.key_code;
            cb(evt_type, x, y, text, button, key_code);
        }
    }));

    // 2. Screenshot Handler: captures current screen as JPEG with optional red marker and SoM
    c_remote_core::webrtc::set_screenshot_handler(Arc::new(|max_w, quality, marker, som| {
        let frame_opt = LATEST_FRAME.read().ok().and_then(|f| f.clone());
        let frame = match frame_opt {
            Some(f) if !f.rgba.is_empty() => f,
            _ => anyhow::bail!("No screen frame available from MediaProjection"),
        };

        let mut buf = frame.rgba;
        let w = frame.width;
        let h = frame.height;

        // Apply Set-of-Marks overlay if requested
        if som {
            if let Ok(marks) = LATEST_MARKS.read() {
                draw_som_overlay_rgba(&mut buf, w, h, &marks);
            }
        }

        // Apply high-contrast red marker if target click coordinates given
        if let Some((mx, my)) = marker {
            draw_red_marker_rgba(&mut buf, w, h, mx, my);
        }

        // Downscale if requested
        let (dst_w, dst_h, final_buf) = if max_w > 0 && w > max_w {
            let scale = max_w as f64 / w as f64;
            let nh = (h as f64 * scale).round() as u32;
            (max_w, nh, downscale_rgba(&buf, w, h, max_w, nh))
        } else {
            (w, h, buf)
        };

        // Encode to JPEG
        let mut jpeg = Vec::new();
        let enc = jpeg_encoder::Encoder::new(&mut jpeg, quality.clamp(10, 95));
        enc.encode(&final_buf, dst_w as u16, dst_h as u16, jpeg_encoder::ColorType::Rgba)?;

        let hash = blake3::hash(&jpeg).to_hex().to_string();
        Ok((dst_w as u16, dst_h as u16, jpeg, hash))
    }));

    // 3. Screen streaming handler over SCTP data channel "remote-screen"
    c_remote_core::webrtc::set_screen_handler(Arc::new(|dc| {
        tokio::spawn(async move {
            let mut interval = tokio::time::interval(std::time::Duration::from_millis(66)); // ~15 FPS SCTP
            loop {
                interval.tick().await;
                if dc.ready_state() != webrtc::data_channel::data_channel_state::RTCDataChannelState::Open {
                    break;
                }

                let frame_opt = LATEST_FRAME.read().ok().and_then(|f| f.clone());
                if let Some(frame) = frame_opt {
                    if frame.rgba.is_empty() {
                        continue;
                    }
                    let mut jpeg = Vec::new();
                    let enc = jpeg_encoder::Encoder::new(&mut jpeg, 50);
                    if enc.encode(&frame.rgba, frame.width as u16, frame.height as u16, jpeg_encoder::ColorType::Rgba).is_ok() {
                        let _ = dc.send(&Bytes::from(jpeg)).await;
                    }
                }
            }
        });
    }));

    // 4. Track handler for RTP hardware video track
    c_remote_core::webrtc::set_track_handler(Arc::new(|v_track, _a_track| {
        set_video_track(v_track);
    }));

    info!("Android WebRTC handlers registered with c_remote_core");
}

fn downscale_rgba(src: &[u8], src_w: u32, src_h: u32, dst_w: u32, dst_h: u32) -> Vec<u8> {
    let mut dst = vec![0u8; (dst_w * dst_h * 4) as usize];
    for y in 0..dst_h {
        let src_y = (y as u64 * src_h as u64 / dst_h as u64) as u32;
        let dst_row_start = (y * dst_w * 4) as usize;
        let src_row_start = (src_y * src_w * 4) as usize;
        for x in 0..dst_w {
            let src_x = (x as u64 * src_w as u64 / dst_w as u64) as u32;
            let di = dst_row_start + (x * 4) as usize;
            let si = src_row_start + (src_x * 4) as usize;
            dst[di..di + 4].copy_from_slice(&src[si..si + 4]);
        }
    }
    dst
}
