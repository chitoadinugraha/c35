use std::sync::atomic::{AtomicBool, AtomicU32, AtomicU8, Ordering};
use std::sync::Arc;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyhow::{bail, Result};
use tracing::{debug, info, warn};
use webrtc::data_channel::RTCDataChannel;

static CAPTURE_ACTIVE: AtomicBool = AtomicBool::new(false);
static SCREEN_DIRTY: AtomicBool = AtomicBool::new(true);
static NEXT_FRAME_ID: AtomicU32 = AtomicU32::new(1);
static VIEWER_STREAM_QUALITY: AtomicU8 = AtomicU8::new(80);
static VIEWER_STREAM_QUALITY_GEN: AtomicU32 = AtomicU32::new(0);

pub fn set_viewer_stream_quality(q: u8) {
    VIEWER_STREAM_QUALITY.store(q.clamp(40, 95), Ordering::Relaxed);
    VIEWER_STREAM_QUALITY_GEN.fetch_add(1, Ordering::Relaxed);
}

fn viewer_stream_quality() -> u8 {
    VIEWER_STREAM_QUALITY.load(Ordering::Relaxed)
}

pub fn is_capture_active() -> bool {
    CAPTURE_ACTIVE.load(Ordering::SeqCst)
}

#[cfg(not(target_os = "linux"))]
pub fn start_screen_stream(_dc: Arc<RTCDataChannel>, _display: u32, _fps: u32) {
    warn!("screen stream not implemented on this build target (Linux agent only)");
}

#[cfg(not(target_os = "linux"))]
pub fn capture_screen_jpeg(
    _max_w: u32,
    _quality: u8,
    _marker: Option<(f64, f64)>,
    _som: bool,
) -> Result<(u16, u16, Vec<u8>, String)> {
    bail!("screen capture not implemented on this build target (Linux agent only)")
}

#[cfg(target_os = "linux")]
mod linux {
    use super::*;
    use blake3::Hasher;
    use jpeg_encoder::{ColorType, Encoder};

    pub fn draw_red_marker(buf: &mut [u8], w: u32, h: u32, nx: f64, ny: f64) {
        let cx = (nx.clamp(0.0, 1.0) * (w.saturating_sub(1)) as f64).round() as i32;
        let cy = (ny.clamp(0.0, 1.0) * (h.saturating_sub(1)) as f64).round() as i32;
        let radius = 7i32;
        for dy in -radius..=radius {
            for dx in -radius..=radius {
                let px = cx + dx;
                let py = cy + dy;
                if px >= 0 && px < w as i32 && py >= 0 && py < h as i32 {
                    let dist_sq = dx * dx + dy * dy;
                    let idx = (py as usize * w as usize + px as usize) * 4;
                    if dist_sq <= 16 {
                        buf[idx] = 0;
                        buf[idx + 1] = 0;
                        buf[idx + 2] = 255;
                        buf[idx + 3] = 255;
                    } else if dist_sq <= 49 {
                        buf[idx] = 255;
                        buf[idx + 1] = 255;
                        buf[idx + 2] = 255;
                        buf[idx + 3] = 255;
                    }
                }
            }
        }
    }

    fn downscale_bgra(src: &[u8], src_w: u32, src_h: u32, dst_w: u32, dst_h: u32) -> Vec<u8> {
        let mut dst = vec![0u8; (dst_w as usize) * (dst_h as usize) * 4];
        for y in 0..dst_h {
            let src_y = (y as u64 * src_h as u64 / dst_h as u64) as u32;
            for x in 0..dst_w {
                let src_x = (x as u64 * src_w as u64 / dst_w as u64) as u32;
                let di = ((y * dst_w + x) * 4) as usize;
                let si = ((src_y * src_w + src_x) * 4) as usize;
                dst[di..di + 4].copy_from_slice(&src[si..si + 4]);
            }
        }
        dst
    }

    fn capture_primary_bgra() -> Result<(u32, u32, Vec<u8>)> {
        crate::capture::capture_primary_bgra()
    }

    fn desktop_width_cap() -> u32 {
        crate::capture::desktop_width_cap()
    }

    fn encode_bgra_jpeg(
        src_w: u32,
        src_h: u32,
        mut bgra: Vec<u8>,
        max_w: u32,
        quality: u8,
        prev_hash: Option<[u8; 32]>,
        force: bool,
        marker: Option<(f64, f64)>,
    ) -> Result<(Option<(u16, u16, Vec<u8>)>, [u8; 32])> {
        let cap_w = if max_w > 0 {
            max_w.min(src_w)
        } else {
            src_w
        };
        let dst_w = cap_w.max(1);
        let dst_h = (src_h as u64 * dst_w as u64 / src_w as u64).max(1) as u32;
        if dst_w != src_w || dst_h != src_h {
            bgra = downscale_bgra(&bgra, src_w, src_h, dst_w, dst_h);
        }
        if let Some((nx, ny)) = marker {
            draw_red_marker(&mut bgra, dst_w, dst_h, nx, ny);
        }

        let mut hasher = Hasher::new();
        hasher.update(&bgra);
        let hash = *hasher.finalize().as_bytes();
        if !force && prev_hash == Some(hash) {
            return Ok((None, hash));
        }

        let mut jpeg_bytes = Vec::with_capacity(((dst_w as u64 * dst_h as u64) / 2) as usize);
        let encoder = Encoder::new(&mut jpeg_bytes, quality);
        encoder
            .encode(&bgra, dst_w as u16, dst_h as u16, ColorType::Bgra)
            .map_err(|e| anyhow::anyhow!("jpeg encode: {e}"))?;
        Ok((Some((dst_w as u16, dst_h as u16, jpeg_bytes)), hash))
    }

    pub fn capture_screen_diff(
        max_w: u32,
        quality: u8,
        prev_hash: Option<[u8; 32]>,
        force: bool,
        marker: Option<(f64, f64)>,
    ) -> Result<(Option<(u16, u16, Vec<u8>)>, [u8; 32])> {
        let (w, h, bgra) = capture_primary_bgra()?;
        encode_bgra_jpeg(w, h, bgra, max_w, quality, prev_hash, force, marker)
    }

    pub fn capture_screen_jpeg(
        max_w: u32,
        quality: u8,
        marker: Option<(f64, f64)>,
        _som: bool,
    ) -> Result<(u16, u16, Vec<u8>, String)> {
        let (opt, _) = capture_screen_diff(max_w, quality, None, true, marker)?;
        match opt {
            Some((w, h, jpeg)) => Ok((w, h, jpeg, String::new())),
            None => {
                let (w, h, bgra) = capture_primary_bgra()?;
                let (opt2, _) = encode_bgra_jpeg(w, h, bgra, max_w, quality, None, true, marker)?;
                match opt2 {
                    Some((w, h, jpeg)) => Ok((w, h, jpeg, String::new())),
                    None => bail!("screenshot encode produced empty frame"),
                }
            }
        }
    }

    pub const REMOTE_SCREEN_SCTP_MAX_BYTES: usize = 60_000;
    pub const REMOTE_SCREEN_CHUNK_PAYLOAD_BYTES: usize = 48_000;

    pub fn make_screen_packet(w: u16, h: u16, ts_ms: u64, jpeg: &[u8]) -> Vec<u8> {
        let mut packet = Vec::with_capacity(16 + jpeg.len());
        packet.extend_from_slice(b"CS35");
        packet.extend_from_slice(&w.to_be_bytes());
        packet.extend_from_slice(&h.to_be_bytes());
        packet.extend_from_slice(&ts_ms.to_be_bytes());
        packet.extend_from_slice(jpeg);
        packet
    }

    pub fn make_screen_chunks(
        frame_id: u32,
        w: u16,
        h: u16,
        ts_ms: u64,
        jpeg: &[u8],
    ) -> Vec<Vec<u8>> {
        let total_chunks =
            ((jpeg.len() + REMOTE_SCREEN_CHUNK_PAYLOAD_BYTES - 1) / REMOTE_SCREEN_CHUNK_PAYLOAD_BYTES)
                .max(1) as u16;
        let mut chunks = Vec::with_capacity(total_chunks as usize);
        for (idx, slice) in jpeg.chunks(REMOTE_SCREEN_CHUNK_PAYLOAD_BYTES).enumerate() {
            let mut packet = Vec::with_capacity(24 + slice.len());
            packet.extend_from_slice(b"CS36");
            packet.extend_from_slice(&frame_id.to_be_bytes());
            packet.extend_from_slice(&(idx as u16).to_be_bytes());
            packet.extend_from_slice(&total_chunks.to_be_bytes());
            packet.extend_from_slice(&w.to_be_bytes());
            packet.extend_from_slice(&h.to_be_bytes());
            packet.extend_from_slice(&ts_ms.to_be_bytes());
            packet.extend_from_slice(slice);
            chunks.push(packet);
        }
        chunks
    }

    pub fn start_screen_stream(dc: Arc<RTCDataChannel>, max_w: u32, target_fps: u32) {
        let fps = target_fps.clamp(5, 30);
        let frame_interval = Duration::from_millis(1000 / fps as u64);

        tokio::spawn(async move {
            CAPTURE_ACTIVE.store(true, Ordering::SeqCst);
            let ceiling = if max_w > 0 { max_w } else { desktop_width_cap() };
            info!(
                fps,
                max_w,
                ceiling,
                "Linux desktop screen streaming started (SCTP MJPEG; portal on Wayland, xcap fallback on X11)"
            );

            let mut interval = tokio::time::interval(frame_interval);
            interval.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Skip);

            let mut prev_hash: Option<[u8; 32]> = None;
            let mut last_sent_time = SystemTime::now();
            let mut stream_max_w = ceiling;
            let mut stream_quality: u8 = viewer_stream_quality();
            let mut stream_quality_gen = VIEWER_STREAM_QUALITY_GEN.load(Ordering::Relaxed);

            loop {
                interval.tick().await;

                let gen = VIEWER_STREAM_QUALITY_GEN.load(Ordering::Relaxed);
                if gen != stream_quality_gen {
                    stream_quality_gen = gen;
                    stream_quality = viewer_stream_quality();
                }

                if c_remote_core::webrtc::is_file_media_active() {
                    continue;
                }

                let buffered = dc.buffered_amount().await;
                if buffered > 256 * 1024 {
                    debug!(buffered, "remote-screen sctp queue congested, dropping frame");
                    continue;
                }

                let dirty = SCREEN_DIRTY.swap(false, Ordering::Relaxed);
                let elapsed = last_sent_time.elapsed().unwrap_or_default();
                let force = dirty || elapsed >= Duration::from_secs(2);

                let cur_prev_hash = prev_hash;
                let cap_w = stream_max_w;
                let cap_q = stream_quality;
                let capture_res = tokio::task::spawn_blocking(move || {
                    capture_screen_diff(cap_w, cap_q, cur_prev_hash, force, None)
                })
                .await;

                match capture_res {
                    Ok(Ok((Some((w, h, jpeg)), new_hash))) => {
                        let ts_ms = SystemTime::now()
                            .duration_since(UNIX_EPOCH)
                            .unwrap_or_default()
                            .as_millis() as u64;

                        let send_res: Result<(), String> =
                            if jpeg.len() + 16 <= REMOTE_SCREEN_SCTP_MAX_BYTES {
                                let packet = make_screen_packet(w, h, ts_ms, &jpeg);
                                dc.send(&bytes::Bytes::from(packet))
                                    .await
                                    .map(|_| ())
                                    .map_err(|e| e.to_string())
                            } else {
                                let frame_id = NEXT_FRAME_ID.fetch_add(1, Ordering::Relaxed);
                                let chunks = make_screen_chunks(frame_id, w, h, ts_ms, &jpeg);
                                let mut chunk_res = Ok(());
                                for chunk in chunks {
                                    if let Err(e) = dc.send(&bytes::Bytes::from(chunk)).await {
                                        chunk_res = Err(e.to_string());
                                        break;
                                    }
                                }
                                chunk_res
                            };

                        match send_res {
                            Ok(()) => {
                                prev_hash = Some(new_hash);
                                last_sent_time = SystemTime::now();
                            }
                            Err(err_str) => {
                                if dc.ready_state()
                                    == webrtc::data_channel::data_channel_state::RTCDataChannelState::Closed
                                {
                                    info!("remote-screen data channel closed, stopping stream");
                                    break;
                                }
                                if err_str.contains("larger than maximum message size") {
                                    stream_quality = stream_quality.saturating_sub(10).max(40);
                                    stream_max_w = (stream_max_w * 3 / 4).max(640);
                                } else {
                                    warn!(error = %err_str, "remote-screen send failed");
                                }
                            }
                        }
                    }
                    Ok(Ok((None, new_hash))) => {
                        prev_hash = Some(new_hash);
                    }
                    Ok(Err(e)) => warn!("screen capture failed: {e:#}"),
                    Err(e) => warn!("screen capture task failed: {e}"),
                }
            }

            CAPTURE_ACTIVE.store(false, Ordering::SeqCst);
            info!("desktop screen streaming stopped");
        });
    }
}

#[cfg(target_os = "linux")]
pub use linux::{capture_screen_jpeg, start_screen_stream};
