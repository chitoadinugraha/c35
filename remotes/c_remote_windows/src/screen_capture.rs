use std::sync::atomic::{AtomicBool, AtomicU32, Ordering};
use std::sync::Arc;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyhow::{bail, Context, Result};
use tracing::{debug, error, info, warn};
use webrtc::data_channel::RTCDataChannel;
use windows::Win32::Foundation::HWND;
use windows::Win32::Graphics::Gdi::{
    CreateCompatibleBitmap, CreateCompatibleDC, DeleteDC, DeleteObject, GetDC, GetDIBits,
    ReleaseDC, SelectObject, SetStretchBltMode, StretchBlt, BITMAPINFO, BITMAPINFOHEADER, BI_RGB,
    COLORONCOLOR, DIB_RGB_COLORS, HBITMAP, HDC, SRCCOPY,
};
use windows::Win32::UI::WindowsAndMessaging::{
    GetSystemMetrics, SM_CXSCREEN, SM_CYSCREEN,
    SM_XVIRTUALSCREEN, SM_YVIRTUALSCREEN, SM_CXVIRTUALSCREEN, SM_CYVIRTUALSCREEN,
};

static CAPTURE_ACTIVE: AtomicBool = AtomicBool::new(false);
static CAPTURE_FAIL_COUNT: AtomicU32 = AtomicU32::new(0);
static CAPTURE_FAIL_WARNED: AtomicBool = AtomicBool::new(false);
static SCREEN_DIRTY: AtomicBool = AtomicBool::new(true);
static DXGI_DISABLED: AtomicBool = AtomicBool::new(false);
static DXGI_CAPTURER: std::sync::Mutex<Option<crate::dxgi_capture::DxgiCapturer>> =
    std::sync::Mutex::new(None);

pub fn is_capture_active() -> bool {
    CAPTURE_ACTIVE.load(Ordering::SeqCst)
}

pub fn mark_screen_dirty() {
    SCREEN_DIRTY.store(true, Ordering::Relaxed);
}

/// Downscale BGRA image using fast nearest-neighbor sampling.
fn downscale_bgra(src: &[u8], src_w: u32, src_h: u32, dst_w: u32, dst_h: u32) -> Vec<u8> {
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

/// Draw a high-contrast red marker with a white ring at normalized coordinates (nx, ny)
/// so multimodal models do not have to guess where actions/clicks land.
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
                    // Solid bright red center: BGRA = [0, 0, 255, 255]
                    buf[idx] = 0;
                    buf[idx + 1] = 0;
                    buf[idx + 2] = 255;
                    buf[idx + 3] = 255;
                } else if dist_sq <= 49 {
                    // White outer ring: BGRA = [255, 255, 255, 255]
                    buf[idx] = 255;
                    buf[idx + 1] = 255;
                    buf[idx + 2] = 255;
                    buf[idx + 3] = 255;
                }
            }
        }
    }
}

/// Capture screen using GDI fallback (Win32 compatible DC / StretchBlt).
pub fn capture_screen_gdi(
    max_w: u32,
    quality: u8,
    prev_hash: Option<[u8; 32]>,
    force: bool,
    marker: Option<(f64, f64)>,
    som: bool,
) -> Result<(Option<(u16, u16, Vec<u8>, String)>, [u8; 32])> {
    unsafe {
        let vx = GetSystemMetrics(SM_XVIRTUALSCREEN);
        let vy = GetSystemMetrics(SM_YVIRTUALSCREEN);
        let vw = GetSystemMetrics(SM_CXVIRTUALSCREEN);
        let vh = GetSystemMetrics(SM_CYVIRTUALSCREEN);
        let (src_x, src_y, src_w, src_h) = if vw > 0 && vh > 0 {
            (vx, vy, vw, vh)
        } else {
            (0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN))
        };
        if src_w <= 0 || src_h <= 0 {
            bail!("invalid screen metrics: {src_w}x{src_h}");
        }

        let (dst_w, dst_h) = if max_w > 0 && (src_w as u32) > max_w {
            let h = ((src_h as u64 * max_w as u64) / src_w as u64).max(1) as u32;
            (max_w, h)
        } else {
            (src_w as u32, src_h as u32)
        };

        let hdc_screen: HDC = GetDC(HWND::default());
        if hdc_screen.is_invalid() {
            bail!("failed to get screen HDC");
        }

        let hdc_mem: HDC = CreateCompatibleDC(hdc_screen);
        if hdc_mem.is_invalid() {
            let _ = ReleaseDC(HWND::default(), hdc_screen);
            bail!("failed to create compatible DC");
        }

        let hbm: HBITMAP = CreateCompatibleBitmap(hdc_screen, dst_w as i32, dst_h as i32);
        if hbm.is_invalid() {
            let _ = DeleteDC(hdc_mem);
            let _ = ReleaseDC(HWND::default(), hdc_screen);
            bail!("failed to create compatible bitmap");
        }

        let old_bm = SelectObject(hdc_mem, hbm);
        let _ = SetStretchBltMode(hdc_mem, COLORONCOLOR);

        let blt_res = StretchBlt(
            hdc_mem,
            0,
            0,
            dst_w as i32,
            dst_h as i32,
            hdc_screen,
            src_x,
            src_y,
            src_w,
            src_h,
            SRCCOPY,
        );

        let mut bgra_buf = vec![0u8; (dst_w * dst_h * 4) as usize];

        let mut bmi = BITMAPINFO {
            bmiHeader: BITMAPINFOHEADER {
                biSize: std::mem::size_of::<BITMAPINFOHEADER>() as u32,
                biWidth: dst_w as i32,
                biHeight: -(dst_h as i32), // negative for top-down DIB
                biPlanes: 1,
                biBitCount: 32,
                biCompression: BI_RGB.0,
                ..Default::default()
            },
            ..Default::default()
        };

        let dib_res = GetDIBits(
            hdc_mem,
            hbm,
            0,
            dst_h,
            Some(bgra_buf.as_mut_ptr() as *mut _),
            &mut bmi,
            DIB_RGB_COLORS,
        );

        // Cleanup GDI objects immediately
        let _ = SelectObject(hdc_mem, old_bm);
        let _ = DeleteObject(hbm);
        let _ = DeleteDC(hdc_mem);
        let _ = ReleaseDC(HWND::default(), hdc_screen);

        if !blt_res.as_bool() || dib_res == 0 {
            bail!("failed to capture screen DIB");
        }

        let mut axtree = String::new();
        if som {
            let marks = crate::uia::uia_walk();
            axtree = crate::uia::axtree_text(&marks, src_w as u32, src_h as u32);
            crate::uia::draw_som_overlay(&mut bgra_buf, dst_w, dst_h, src_w as u32, src_h as u32, &marks);
        }

        if let Some((mx, my)) = marker {
            draw_red_marker(&mut bgra_buf, dst_w, dst_h, mx, my);
        }

        let hash = *blake3::hash(&bgra_buf).as_bytes();

        if !force && prev_hash == Some(hash) {
            return Ok((None, hash));
        }

        let mut jpeg_bytes = Vec::with_capacity((dst_w * dst_h / 2) as usize);
        let encoder = jpeg_encoder::Encoder::new(&mut jpeg_bytes, quality);
        encoder
            .encode(
                &bgra_buf,
                dst_w as u16,
                dst_h as u16,
                jpeg_encoder::ColorType::Bgra,
            )
            .context("failed to encode desktop JPEG")?;

        Ok((Some((dst_w as u16, dst_h as u16, jpeg_bytes, axtree)), hash))
    }
}

/// Capture full desktop and compare with previous frame hash.
/// Tries fast GPU capture via DXGI Desktop Duplication (<1ms) first.
/// If DXGI is unavailable (headless, RDP, lock screen), falls back seamlessly to GDI capture.
pub fn capture_screen_diff_opt(
    max_w: u32,
    quality: u8,
    prev_hash: Option<[u8; 32]>,
    force: bool,
    marker: Option<(f64, f64)>,
    som: bool,
) -> Result<(Option<(u16, u16, Vec<u8>, String)>, [u8; 32])> {
    if !DXGI_DISABLED.load(Ordering::Relaxed) {
        let mut guard = DXGI_CAPTURER.lock().unwrap();
        if guard.is_none() {
            match crate::dxgi_capture::DxgiCapturer::new() {
                Ok(cap) => {
                    info!("DXGI GPU desktop capture activated");
                    *guard = Some(cap);
                }
                Err(e) => {
                    warn!("DXGI capture init failed: {e}; falling back to GDI");
                    DXGI_DISABLED.store(true, Ordering::Relaxed);
                }
            }
        }

        if let Some(capturer) = guard.as_mut() {
            match capturer.capture_frame(16) {
                Ok(Some((src_w, src_h, raw_bgra))) => {
                    let (dst_w, dst_h, mut bgra_buf) = if max_w > 0 && src_w > max_w {
                        let h = ((src_h as u64 * max_w as u64) / src_w as u64).max(1) as u32;
                        let scaled = downscale_bgra(&raw_bgra, src_w, src_h, max_w, h);
                        (max_w, h, scaled)
                    } else {
                        (src_w, src_h, raw_bgra)
                    };

                    let mut axtree = String::new();
                    if som {
                        let marks = crate::uia::uia_walk();
                        axtree = crate::uia::axtree_text(&marks, src_w, src_h);
                        crate::uia::draw_som_overlay(&mut bgra_buf, dst_w, dst_h, src_w, src_h, &marks);
                    }

                    if let Some((mx, my)) = marker {
                        draw_red_marker(&mut bgra_buf, dst_w, dst_h, mx, my);
                    }

                    let hash = *blake3::hash(&bgra_buf).as_bytes();
                    if !force && prev_hash == Some(hash) {
                        return Ok((None, hash));
                    }

                    let mut jpeg_bytes = Vec::with_capacity((dst_w * dst_h / 2) as usize);
                    let encoder = jpeg_encoder::Encoder::new(&mut jpeg_bytes, quality);
                    encoder
                        .encode(
                            &bgra_buf,
                            dst_w as u16,
                            dst_h as u16,
                            jpeg_encoder::ColorType::Bgra,
                        )
                        .context("failed to encode desktop JPEG from DXGI frame")?;

                    return Ok((Some((dst_w as u16, dst_h as u16, jpeg_bytes, axtree)), hash));
                }
                Ok(None) => {
                    // No new frame from DXGI within timeout (screen is static)
                    if !force && prev_hash.is_some() {
                        return Ok((None, prev_hash.unwrap()));
                    }
                    // If forced (e.g. initial connection), fall through to GDI to get initial frame
                }
                Err(e) => {
                    warn!("DXGI capture frame error: {e}; falling back to GDI");
                }
            }
        }
    }

    capture_screen_gdi(max_w, quality, prev_hash, force, marker, som)
}

pub fn capture_screen_diff(
    max_w: u32,
    quality: u8,
    prev_hash: Option<[u8; 32]>,
    force: bool,
) -> Result<(Option<(u16, u16, Vec<u8>)>, [u8; 32])> {
    let (opt, hash) = capture_screen_diff_opt(max_w, quality, prev_hash, force, None, false)?;
    let mapped = opt.map(|(w, h, jpeg, _)| (w, h, jpeg));
    Ok((mapped, hash))
}

/// Capture full desktop into a JPEG byte buffer with dimensions and optional SoM axtree text.
pub fn capture_screen_jpeg(
    max_w: u32,
    quality: u8,
    marker: Option<(f64, f64)>,
    som: bool,
) -> Result<(u16, u16, Vec<u8>, String)> {
    let (frame, _) = capture_screen_diff_opt(max_w, quality, None, true, marker, som)?;
    frame.context("failed to capture frame")
}

/// Encode frame into 16-byte header + JPEG body:
/// [0..4]: b"CS35"
/// [4..6]: width (u16 be)
/// [6..8]: height (u16 be)
/// [8..16]: timestamp_ms (u64 be)
/// [16..]: jpeg payload
pub fn make_screen_packet(w: u16, h: u16, ts_ms: u64, jpeg: &[u8]) -> Vec<u8> {
    let mut packet = Vec::with_capacity(16 + jpeg.len());
    packet.extend_from_slice(b"CS35");
    packet.extend_from_slice(&w.to_be_bytes());
    packet.extend_from_slice(&h.to_be_bytes());
    packet.extend_from_slice(&ts_ms.to_be_bytes());
    packet.extend_from_slice(jpeg);
    packet
}

/// Spawn screen capture streamer on a WebRTC data channel with dirty-frame detection and SCTP backpressure.
pub fn start_screen_stream(dc: Arc<RTCDataChannel>, max_w: u32, target_fps: u32) {
    let fps = target_fps.clamp(5, 30);
    let frame_interval = Duration::from_millis(1000 / fps as u64);

    tokio::spawn(async move {
        CAPTURE_ACTIVE.store(true, Ordering::SeqCst);
        info!(
            fps,
            max_w,
            "desktop screen streaming started (SCTP MJPEG; ensure an interactive desktop session — lock screen / headless VM may yield black frames)"
        );

        let mut interval = tokio::time::interval(frame_interval);
        interval.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Skip);

        let mut prev_hash: Option<[u8; 32]> = None;
        let mut last_sent_time = SystemTime::now();

        loop {
            interval.tick().await;

            // SCTP backpressure: skip frame if data channel send buffer > 256KB
            let buffered = dc.buffered_amount().await;
            if buffered > 256 * 1024 {
                debug!(buffered, "remote-screen sctp queue congested, dropping frame");
                continue;
            }

            let dirty = SCREEN_DIRTY.swap(false, Ordering::Relaxed);
            let elapsed = last_sent_time.elapsed().unwrap_or_default();
            // Force frame if dirty or 2s heartbeat elapsed
            let force = dirty || elapsed >= Duration::from_secs(2);

            let cur_prev_hash = prev_hash;
            let capture_res = tokio::task::spawn_blocking(move || {
                capture_screen_diff(max_w, 72, cur_prev_hash, force)
            })
            .await;

            match capture_res {
                Ok(Ok((Some((w, h, jpeg)), new_hash))) => {
                    prev_hash = Some(new_hash);
                    last_sent_time = SystemTime::now();
                    let ts_ms = SystemTime::now()
                        .duration_since(UNIX_EPOCH)
                        .unwrap_or_default()
                        .as_millis() as u64;
                    let packet = make_screen_packet(w, h, ts_ms, &jpeg);
                    if let Err(e) = dc.send(&bytes::Bytes::from(packet)).await {
                        debug!("remote-screen send failed: {e}, stopping stream");
                        break;
                    }
                }
                Ok(Ok((None, new_hash))) => {
                    prev_hash = Some(new_hash);
                }
                Ok(Err(e)) => {
                    let n = CAPTURE_FAIL_COUNT.fetch_add(1, Ordering::Relaxed) + 1;
                    if n >= 5 && !CAPTURE_FAIL_WARNED.swap(true, Ordering::Relaxed) {
                        warn!(
                            failures = n,
                            "screen capture failing repeatedly: {e} — check VM is logged in, desktop visible, and not on lock screen"
                        );
                    } else {
                        debug!("screen capture error: {e}");
                    }
                }
                Err(e) => {
                    error!("spawn_blocking capture error: {e}");
                    break;
                }
            }
        }

        CAPTURE_ACTIVE.store(false, Ordering::SeqCst);
        info!("desktop screen streaming stopped");
    });
}
