use std::sync::atomic::{AtomicBool, AtomicU32, AtomicU8, Ordering};
use std::sync::Arc;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyhow::{bail, Context, Result};
use tracing::{debug, error, info, warn};
use webrtc::data_channel::RTCDataChannel;
use windows::Win32::Foundation::HWND;
use windows::Win32::Graphics::Gdi::{
    BitBlt, CreateCompatibleBitmap, CreateCompatibleDC, DeleteDC, DeleteObject, GetDC, GetDIBits,
    ReleaseDC, SelectObject, SetStretchBltMode, StretchBlt, BITMAPINFO, BITMAPINFOHEADER, BI_RGB,
    DIB_RGB_COLORS, HBITMAP, HDC, HALFTONE, SRCCOPY,
};
use windows::Win32::UI::WindowsAndMessaging::{
    GetSystemMetrics, SM_CXSCREEN, SM_CYSCREEN,
    SM_XVIRTUALSCREEN, SM_YVIRTUALSCREEN, SM_CXVIRTUALSCREEN, SM_CYVIRTUALSCREEN,
};

static CAPTURE_ACTIVE: AtomicBool = AtomicBool::new(false);
static CAPTURE_FAIL_COUNT: AtomicU32 = AtomicU32::new(0);
static CAPTURE_FAIL_WARNED: AtomicBool = AtomicBool::new(false);
static SCREEN_DIRTY: AtomicBool = AtomicBool::new(true);
static NEXT_FRAME_ID: AtomicU32 = AtomicU32::new(1);
static VIEWER_STREAM_QUALITY: AtomicU8 = AtomicU8::new(80);
static VIEWER_STREAM_QUALITY_GEN: AtomicU32 = AtomicU32::new(0);

pub fn set_viewer_stream_quality(q: u8) {
    VIEWER_STREAM_QUALITY.store(q.clamp(40, 95), Ordering::Relaxed);
    VIEWER_STREAM_QUALITY_GEN.fetch_add(1, Ordering::Relaxed);
}

pub fn viewer_stream_quality() -> u8 {
    VIEWER_STREAM_QUALITY.load(Ordering::Relaxed)
}

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

/// True when nearly all pixels are near-black (lock screen, session 0, headless VM capture).
fn frame_mostly_black(bgra: &[u8]) -> bool {
    if bgra.len() < 4 {
        return true;
    }
    let mut dark = 0u64;
    let mut total = 0u64;
    for px in bgra.chunks_exact(4) {
        total += 1;
        if px[0] < 12 && px[1] < 12 && px[2] < 12 {
            dark += 1;
        }
    }
    total > 0 && dark * 100 / total >= 94
}

/// Copy the virtual desktop into a BGRA buffer (handles negative virtual-screen origins).
unsafe fn gdi_read_bgra(hdc_screen: HDC, src_w: i32, src_h: i32, dst_w: u32, dst_h: u32) -> Result<Vec<u8>> {
    let hdc_full = CreateCompatibleDC(hdc_screen);
    if hdc_full.is_invalid() {
        bail!("failed to create compatible DC for virtual screen");
    }

    let hbm_full = CreateCompatibleBitmap(hdc_screen, src_w, src_h);
    if hbm_full.is_invalid() {
        let _ = DeleteDC(hdc_full);
        bail!("failed to create virtual-screen bitmap");
    }

    let old_full = SelectObject(hdc_full, hbm_full);
    let vx = GetSystemMetrics(SM_XVIRTUALSCREEN);
    let vy = GetSystemMetrics(SM_YVIRTUALSCREEN);
    if BitBlt(hdc_full, 0, 0, src_w, src_h, hdc_screen, vx, vy, SRCCOPY).is_err() {
        let _ = SelectObject(hdc_full, old_full);
        let _ = DeleteObject(hbm_full);
        let _ = DeleteDC(hdc_full);
        bail!("BitBlt virtual screen failed");
    }

    let (read_dc, read_bm, read_w, read_h, scaled): (HDC, HBITMAP, u32, u32, bool) =
        if dst_w as i32 == src_w && dst_h as i32 == src_h {
            (hdc_full, hbm_full, dst_w, dst_h, false)
        } else {
            let hdc_scaled = CreateCompatibleDC(hdc_screen);
            if hdc_scaled.is_invalid() {
                let _ = SelectObject(hdc_full, old_full);
                let _ = DeleteObject(hbm_full);
                let _ = DeleteDC(hdc_full);
                bail!("failed to create scale DC");
            }
            let hbm_scaled = CreateCompatibleBitmap(hdc_screen, dst_w as i32, dst_h as i32);
            if hbm_scaled.is_invalid() {
                let _ = DeleteDC(hdc_scaled);
                let _ = SelectObject(hdc_full, old_full);
                let _ = DeleteObject(hbm_full);
                let _ = DeleteDC(hdc_full);
                bail!("failed to create scaled bitmap");
            }
            let old_scaled = SelectObject(hdc_scaled, hbm_scaled);
            let _ = SetStretchBltMode(hdc_scaled, HALFTONE);
            let stretch_ok = StretchBlt(
                hdc_scaled,
                0,
                0,
                dst_w as i32,
                dst_h as i32,
                hdc_full,
                0,
                0,
                src_w,
                src_h,
                SRCCOPY,
            );
            let _ = SelectObject(hdc_scaled, old_scaled);
            if !stretch_ok.as_bool() {
                let _ = DeleteObject(hbm_scaled);
                let _ = DeleteDC(hdc_scaled);
                let _ = SelectObject(hdc_full, old_full);
                let _ = DeleteObject(hbm_full);
                let _ = DeleteDC(hdc_full);
                bail!("StretchBlt scaled desktop failed");
            }
            (hdc_scaled, hbm_scaled, dst_w, dst_h, true)
        };

    let mut bgra_buf = vec![0u8; (read_w * read_h * 4) as usize];
    let mut bmi = BITMAPINFO {
        bmiHeader: BITMAPINFOHEADER {
            biSize: std::mem::size_of::<BITMAPINFOHEADER>() as u32,
            biWidth: read_w as i32,
            biHeight: -(read_h as i32),
            biPlanes: 1,
            biBitCount: 32,
            biCompression: BI_RGB.0,
            ..Default::default()
        },
        ..Default::default()
    };

    let dib_res = GetDIBits(
        read_dc,
        read_bm,
        0,
        read_h,
        Some(bgra_buf.as_mut_ptr() as *mut _),
        &mut bmi,
        DIB_RGB_COLORS,
    );

    if scaled {
        let _ = DeleteObject(read_bm);
        let _ = DeleteDC(read_dc);
    }
    let _ = SelectObject(hdc_full, old_full);
    let _ = DeleteObject(hbm_full);
    let _ = DeleteDC(hdc_full);

    if dib_res == 0 {
        bail!("failed to capture screen DIB");
    }

    Ok(bgra_buf)
}

/// Capture screen using GDI returning raw BGRA pixel bytes without compression.
pub fn capture_screen_gdi_raw(max_w: u32) -> Result<(u32, u32, Vec<u8>)> {
    unsafe {
        let vx = GetSystemMetrics(SM_XVIRTUALSCREEN);
        let vy = GetSystemMetrics(SM_YVIRTUALSCREEN);
        let vw = GetSystemMetrics(SM_CXVIRTUALSCREEN);
        let vh = GetSystemMetrics(SM_CYVIRTUALSCREEN);
        let (src_w, src_h) = if vw > 0 && vh > 0 {
            (vw, vh)
        } else {
            (GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN))
        };
        if src_w <= 0 || src_h <= 0 {
            bail!("invalid screen metrics: {src_w}x{src_h}");
        }
        let _ = (vx, vy);

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

        let capture_res = gdi_read_bgra(hdc_screen, src_w, src_h, dst_w, dst_h);
        let _ = ReleaseDC(HWND::default(), hdc_screen);
        let bgra_buf = capture_res?;

        Ok((dst_w, dst_h, bgra_buf))
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
        let vw = GetSystemMetrics(SM_CXVIRTUALSCREEN);
        let vh = GetSystemMetrics(SM_CYVIRTUALSCREEN);
        let (src_w, src_h) = if vw > 0 && vh > 0 {
            (vw, vh)
        } else {
            (GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN))
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

        let mut bgra_buf = gdi_read_bgra(hdc_screen, src_w, src_h, dst_w, dst_h)?;
        let _ = ReleaseDC(HWND::default(), hdc_screen);

        let mut axtree = String::new();
        if som {
            let marks = crate::uia::uia_walk();
            axtree = crate::uia::axtree_text(&marks, src_w as u32, src_h as u32);
            crate::uia::draw_som_overlay(&mut bgra_buf, dst_w, dst_h, src_w as u32, src_h as u32, &marks);
        }

        if let Some((mx, my)) = marker {
            draw_red_marker(&mut bgra_buf, dst_w, dst_h, mx, my);
        }

        if frame_mostly_black(&bgra_buf) {
            if crate::video_stream::is_video_stream_active() {
                if let Some((w, h, b)) = crate::dxgi_capture::shared_last_bgra_clone() {
                    if !frame_mostly_black(&b) {
                        debug!("GDI capture black; using last DXGI frame from active WebRTC stream");
                        return encode_bgra_screenshot(w, h, b, max_w, quality, prev_hash, force, marker, som, false);
                    }
                }
            }
            bail!("desktop capture is blank (unlock PC, sign in to interactive session — lock screen / non-interactive VM session often yields black frames)");
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
fn encode_bgra_screenshot(
    src_w: u32,
    src_h: u32,
    raw_bgra: Vec<u8>,
    max_w: u32,
    quality: u8,
    prev_hash: Option<[u8; 32]>,
    force: bool,
    marker: Option<(f64, f64)>,
    som: bool,
    check_black: bool,
) -> Result<(Option<(u16, u16, Vec<u8>, String)>, [u8; 32])> {
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

    if check_black && frame_mostly_black(&bgra_buf) {
        bail!("desktop capture is blank (unlock PC, sign in to interactive session — lock screen / non-interactive VM session often yields black frames)");
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

fn try_reuse_last_dxgi_frame(
    max_w: u32,
    quality: u8,
    prev_hash: Option<[u8; 32]>,
    force: bool,
    marker: Option<(f64, f64)>,
    som: bool,
) -> Option<Result<(Option<(u16, u16, Vec<u8>, String)>, [u8; 32])>> {
    if !crate::video_stream::is_video_stream_active() {
        return None;
    }
    let (w, h, bgra) = crate::dxgi_capture::shared_last_bgra_clone()?;
    debug!(w, h, "screenshot reusing last DXGI desktop frame from WebRTC stream");
    Some(encode_bgra_screenshot(w, h, bgra, max_w, quality, prev_hash, force, marker, som, false))
}

/// Chat / `device.screenshot` path when WebRTC video is off — fresh agent capture only.
fn capture_tool_screenshot_agent_opt(
    max_w: u32,
    quality: u8,
    prev_hash: Option<[u8; 32]>,
    marker: Option<(f64, f64)>,
    som: bool,
) -> Result<(Option<(u16, u16, Vec<u8>, String)>, [u8; 32])> {
    if !crate::dxgi_capture::shared_dxgi_disabled() {
        match crate::dxgi_capture::shared_capture_for_tool_screenshot() {
            Ok((src_w, src_h, raw_bgra)) => {
                if let Ok(out) = encode_bgra_screenshot(
                    src_w,
                    src_h,
                    raw_bgra,
                    max_w,
                    quality,
                    prev_hash,
                    true,
                    marker,
                    som,
                    true,
                ) {
                    return Ok(out);
                }
                warn!("tool screenshot DXGI frame blank; falling back to GDI");
            }
            Err(e) => warn!("tool screenshot DXGI capture failed: {e}; falling back to GDI"),
        }
    }
    capture_screen_gdi(max_w, quality, prev_hash, true, marker, som)
}

fn screenshot_recover_after_blank(
    max_w: u32,
    quality: u8,
    prev_hash: Option<[u8; 32]>,
    force: bool,
    marker: Option<(f64, f64)>,
    som: bool,
) -> Option<Result<(Option<(u16, u16, Vec<u8>, String)>, [u8; 32])>> {
    if !force {
        return None;
    }
    if let Some(res) = try_reuse_last_dxgi_frame(max_w, quality, prev_hash, force, marker, som) {
        if res.is_ok() {
            return Some(res);
        }
    }
    for ms in [50u32, 200, 500] {
        if let Ok(Some((w, h, bgra))) = crate::dxgi_capture::shared_capture_frame(ms) {
            if frame_mostly_black(&bgra) {
                continue;
            }
            if let Ok(out) = encode_bgra_screenshot(w, h, bgra, max_w, quality, prev_hash, force, marker, som, true) {
                return Some(Ok(out));
            }
        }
    }
    if let Some(res) = try_reuse_last_dxgi_frame(max_w, quality, prev_hash, force, marker, som) {
        return Some(res);
    }
    None
}

pub fn capture_screen_diff_opt(
    max_w: u32,
    quality: u8,
    prev_hash: Option<[u8; 32]>,
    force: bool,
    marker: Option<(f64, f64)>,
    som: bool,
) -> Result<(Option<(u16, u16, Vec<u8>, String)>, [u8; 32])> {
    if force && !crate::video_stream::is_video_stream_active() {
        return capture_tool_screenshot_agent_opt(max_w, quality, prev_hash, marker, som);
    }
    if !crate::dxgi_capture::shared_dxgi_disabled() {
        match crate::dxgi_capture::shared_capture_frame(16) {
            Ok(Some((src_w, src_h, raw_bgra))) => {
                if let Ok(out) = encode_bgra_screenshot(
                    src_w,
                    src_h,
                    raw_bgra,
                    max_w,
                    quality,
                    prev_hash,
                    force,
                    marker,
                    som,
                    true,
                ) {
                    return Ok(out);
                }
                warn!("DXGI frame blank; trying cached frame, DXGI retry, then GDI");
                if let Some(res) = screenshot_recover_after_blank(max_w, quality, prev_hash, force, marker, som) {
                    return res;
                }
            }
            Ok(None) => {
                if !force && prev_hash.is_some() {
                    return Ok((None, prev_hash.unwrap()));
                }
                if force {
                    if let Some(res) = try_reuse_last_dxgi_frame(max_w, quality, prev_hash, force, marker, som) {
                        return res;
                    }
                    if let Ok(Some((src_w, src_h, raw_bgra))) = crate::dxgi_capture::shared_capture_frame(500) {
                        if let Ok(out) = encode_bgra_screenshot(
                            src_w,
                            src_h,
                            raw_bgra,
                            max_w,
                            quality,
                            prev_hash,
                            force,
                            marker,
                            som,
                            true,
                        ) {
                            return Ok(out);
                        }
                        if let Some(res) = screenshot_recover_after_blank(max_w, quality, prev_hash, force, marker, som) {
                            return res;
                        }
                    }
                    if let Some(res) = try_reuse_last_dxgi_frame(max_w, quality, prev_hash, force, marker, som) {
                        return res;
                    }
                    warn!("DXGI idle for tool screenshot; GDI fallback often black on Hyper-V — prefer Remote tab stream");
                }
            }
            Err(e) => {
                warn!("DXGI capture frame error: {e}; trying last DXGI frame before GDI");
                if force {
                    if let Some(res) = try_reuse_last_dxgi_frame(max_w, quality, prev_hash, force, marker, som) {
                        return res;
                    }
                }
            }
        }
    }

    match capture_screen_gdi(max_w, quality, prev_hash, force, marker, som) {
        Ok(v) => Ok(v),
        Err(e) => {
            if force {
                if let Some(res) = try_reuse_last_dxgi_frame(max_w, quality, prev_hash, force, marker, som) {
                    return res;
                }
            }
            Err(e)
        }
    }
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

pub fn desktop_width_cap() -> u32 {
    unsafe {
        GetSystemMetrics(SM_CXVIRTUALSCREEN).max(1) as u32
    }
}

/// Encode frame into 16-byte header + JPEG body:
/// [0..4]: b"CS35"
/// [4..6]: width (u16 be)
/// [6..8]: height (u16 be)
/// [8..16]: timestamp_ms (u64 be)
/// [16..]: jpeg payload
/// WebRTC SCTP data channels enforce standard 64KB MTU; keep packets strictly under 60KB.
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

/// Encode large frame into chunked CS36 packets:
/// [0..4]: b"CS36"
/// [4..8]: frame_id (u32 be)
/// [8..10]: chunk_idx (u16 be)
/// [10..12]: total_chunks (u16 be)
/// [12..14]: width (u16 be)
/// [14..16]: height (u16 be)
/// [16..24]: timestamp_ms (u64 be)
/// [24..]: chunk payload
pub fn make_screen_chunks(
    frame_id: u32,
    w: u16,
    h: u16,
    ts_ms: u64,
    jpeg: &[u8],
) -> Vec<Vec<u8>> {
    let total_chunks = ((jpeg.len() + REMOTE_SCREEN_CHUNK_PAYLOAD_BYTES - 1) / REMOTE_SCREEN_CHUNK_PAYLOAD_BYTES).max(1) as u16;
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

/// `max_w == 0` → capture up to native desktop width; SCTP backpressure + chunking preserves crisp detail.
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
            "desktop screen streaming started (SCTP MJPEG; ensure an interactive desktop session — lock screen / headless VM may yield black frames)"
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

            if crate::video_stream::is_video_stream_active() {
                continue;
            }

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

            let mut sent = false;
            let mut stop_stream = false;
            for attempt in 0..5u8 {
                let cur_prev_hash = prev_hash;
                let cap_w = stream_max_w;
                let cap_q = stream_quality;
                let capture_res = tokio::task::spawn_blocking(move || {
                    capture_screen_diff(cap_w, cap_q, cur_prev_hash, force)
                })
                .await;

                match capture_res {
                    Ok(Ok((Some((w, h, jpeg)), new_hash))) => {
                        let ts_ms = SystemTime::now()
                            .duration_since(UNIX_EPOCH)
                            .unwrap_or_default()
                            .as_millis() as u64;

                        let send_res: Result<(), String> = if jpeg.len() + 16 <= REMOTE_SCREEN_SCTP_MAX_BYTES {
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
                                sent = true;
                                break;
                            }
                            Err(err_str) => {
                                if dc.ready_state() == webrtc::data_channel::data_channel_state::RTCDataChannelState::Closed {
                                    info!("remote-screen data channel closed, stopping stream");
                                    stop_stream = true;
                                    break;
                                }
                                if err_str.contains("larger than maximum message size") {
                                    stream_quality = stream_quality.saturating_sub(10).max(40);
                                    stream_max_w = (stream_max_w * 3 / 4).max(640);
                                    debug!(
                                        attempt,
                                        stream_max_w,
                                        stream_quality,
                                        "remote-screen frame rejected by SCTP MTU; retrying smaller"
                                    );
                                    continue;
                                }
                                debug!("remote-screen send transient error: {err_str}, will retry next tick");
                                break;
                            }
                        }
                    }
                    Ok(Ok((None, new_hash))) => {
                        prev_hash = Some(new_hash);
                        sent = true;
                        break;
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
                        sent = true;
                        break;
                    }
                    Err(e) => {
                        error!("spawn_blocking capture error: {e}");
                        sent = true;
                        break;
                    }
                }
            }
            if !sent && !stop_stream {
                warn!(
                    stream_max_w,
                    stream_quality,
                    "remote-screen could not fit frame under SCTP max after retries"
                );
            }
            if stop_stream {
                break;
            }
        }

        CAPTURE_ACTIVE.store(false, Ordering::SeqCst);
        info!("desktop screen streaming stopped");
    });
}
