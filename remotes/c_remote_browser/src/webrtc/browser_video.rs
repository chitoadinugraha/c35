//! JPEG screencast frames -> NV12 -> H.264 WebRTC RTP (Windows Media Foundation).

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::{Duration, SystemTime};

use anyhow::{Context, Result};
use bytes::Bytes;
use tracing::{debug, info, warn};
use webrtc::media::Sample;
use webrtc::track::track_local::track_local_static_sample::TrackLocalStaticSample;

static BROWSER_VIDEO_ACTIVE: AtomicBool = AtomicBool::new(false);
const DEFAULT_BITRATE_BPS: u32 = 12_000_000;

fn jpeg_max_fps() -> u32 {
    std::env::var("C35_BROWSER_JPEG_MAX_FPS")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(15)
        .clamp(1, 60)
}

fn jpeg_to_bgra(jpeg: &[u8]) -> Result<(u32, u32, Vec<u8>)> {
    let img = image::load_from_memory(jpeg).context("jpeg decode")?;
    let rgb = img.to_rgb8();
    let (w, h) = (rgb.width(), rgb.height());
    let mut bgra = Vec::with_capacity((w as usize) * (h as usize) * 4);
    for px in rgb.pixels() {
        bgra.push(px[2]);
        bgra.push(px[1]);
        bgra.push(px[0]);
        bgra.push(255);
    }
    Ok((w, h, bgra))
}

pub fn start_browser_video_stream(video_track: Arc<TrackLocalStaticSample>) {
    #[cfg(windows)]
    start_browser_video_stream_impl(video_track);
    #[cfg(not(windows))]
    {
        let _ = video_track;
        warn!("browser H.264 WebRTC video requires Windows (Media Foundation); SCTP fallback only");
    }
}

#[cfg(windows)]
fn start_browser_video_stream_impl(video_track: Arc<TrackLocalStaticSample>) {
    use c_remote_windows::video_stream::{bgra_to_nv12_scaled, H264Encoder};

    tokio::spawn(async move {
        BROWSER_VIDEO_ACTIVE.store(true, Ordering::SeqCst);
        let target_fps = jpeg_max_fps();
        let frame_interval = Duration::from_millis(1000 / target_fps as u64);
        let mut ticker = tokio::time::interval(frame_interval);
        ticker.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Skip);

        info!(target_fps, "browser WebRTC H.264 video loop started");

        let mut encoder_opt: Option<H264Encoder> = None;
        let mut consecutive_failures = 0u32;

        while BROWSER_VIDEO_ACTIVE.load(Ordering::SeqCst) {
            ticker.tick().await;

            if c_remote_core::webrtc::is_file_media_active() {
                continue;
            }

            let st = match crate::browser_state::global() {
                Some(s) => s,
                None => continue,
            };
            let frame = match st.latest_frame() {
                Some(f) => f,
                None => continue,
            };

            let (src_w, src_h, bgra_buf) = match jpeg_to_bgra(&frame.jpeg) {
                Ok(v) => v,
                Err(e) => {
                    debug!("browser jpeg decode: {e:#}");
                    continue;
                }
            };

            let aspect = src_w as f64 / src_h.max(1) as f64;
            let target_w = ((src_w / 2) * 2).max(640);
            let target_h = (((target_w as f64 / aspect).round() as u32 / 2) * 2).max(360);
            let bitrate = DEFAULT_BITRATE_BPS;

            let encoder_needs_reinit = encoder_opt.as_ref().map_or(true, |e| {
                e.width != target_w || e.height != target_h || e.bitrate != bitrate
            });

            if encoder_needs_reinit {
                match H264Encoder::new(target_w, target_h, target_fps, bitrate) {
                    Ok(enc) => {
                        info!(
                            encoder = if enc.is_hardware() { "hw" } else { "sw" },
                            width = target_w,
                            height = target_h,
                            fps = target_fps,
                            bitrate,
                            "browser H.264 encoder ready"
                        );
                        encoder_opt = Some(enc);
                        consecutive_failures = 0;
                    }
                    Err(e) => {
                        consecutive_failures += 1;
                        if consecutive_failures < 3 {
                            warn!("browser H.264 encoder init: {e:#}");
                        }
                        if consecutive_failures >= 5 {
                            warn!("browser H.264 encoder failed repeatedly; stopping RTP loop");
                            break;
                        }
                        tokio::time::sleep(Duration::from_millis(100)).await;
                        continue;
                    }
                }
            }

            let encoder = match encoder_opt.as_mut() {
                Some(e) => e,
                None => continue,
            };

            let nv12 = bgra_to_nv12_scaled(
                &bgra_buf,
                src_w as usize,
                src_h as usize,
                target_w as usize,
                target_h as usize,
            );

            match encoder.encode_frame(&nv12) {
                Ok(nalus) if !nalus.is_empty() => {
                    let sample = Sample {
                        data: Bytes::from(nalus),
                        duration: frame_interval,
                        timestamp: SystemTime::now(),
                        ..Default::default()
                    };
                    if let Err(e) = video_track.write_sample(&sample).await {
                        debug!("browser video_track write_sample: {e}");
                    }
                }
                Ok(_) => {}
                Err(e) => debug!("browser H.264 encode: {e:#}"),
            }
        }

        BROWSER_VIDEO_ACTIVE.store(false, Ordering::SeqCst);
        info!("browser WebRTC H.264 loop ended");
    });
}