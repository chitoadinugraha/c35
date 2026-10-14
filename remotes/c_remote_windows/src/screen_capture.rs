use std::sync::atomic::{AtomicBool, AtomicU32, AtomicU64, AtomicU8, Ordering};
use std::sync::Arc;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyhow::{bail, Context, Result};
use tracing::{debug, error, info, warn};
use webrtc::data_channel::RTCDataChannel;
use windows::Win32::Graphics::Gdi::{
    BitBlt, CreateCompatibleBitmap, CreateCompatibleDC, DeleteDC, DeleteObject, GetDC, GetDIBits,
    ReleaseDC, SelectObject, SetStretchBltMode, StretchBlt, BITMAPINFO, BITMAPINFOHEADER, BI_RGB,
    DIB_RGB_COLORS, HBITMAP, HDC, HALFTONE, SRCCOPY,
};
use windows::Win32::UI::WindowsAndMessaging::{
    GetDesktopWindow, GetSystemMetrics, SM_CXSCREEN, SM_CYSCREEN,
    SM_XVIRTUALSCREEN, SM_YVIRTUALSCREEN, SM_CXVIRTUALSCREEN, SM_CYVIRTUALSCREEN,
};

/// SRCCOPY with CAPTUREBLT — needed for layered windows on some VMs.
const SRCCOPY_CAPTURE: u32 = SRCCOPY.0 | 0x4000_0000;

static CAPTURE_ACTIVE: AtomicBool = AtomicBool::new(false);
static CAPTURE_FAIL_COUNT: AtomicU32 = AtomicU32::new(0);
static CAPTURE_FAIL_WARNED: AtomicBool = AtomicBool::new(false);
static SCREEN_DIRTY: AtomicBool = AtomicBool::new(true);
static NEXT_FRAME_ID: AtomicU32 = AtomicU32::new(1);
static VIEWER_STREAM_QUALITY: AtomicU8 = AtomicU8::new(80);
static VIEWER_STREAM_QUALITY_GEN: AtomicU32 = AtomicU32::new(0);
static LAST_GDI_CAPTURE_MS: AtomicU64 = AtomicU64::new(0);

const GDI_STREAM_MIN_INTERVAL_MS: u64 = 750;

#[inline]
fn remote_view_capture_active() -> bool {
    is_capture_active() || crate::video_stream::is_video_stream_active()
}

pub fn gdi_stream_capture_allowed() -> bool {
    if !remote_view_capture_active() {
        return true;
    }
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as u64;
    let last = LAST_GDI_CAPTURE_MS.load(Ordering::Relaxed);
    if now.saturating_sub(last) < GDI_STREAM_MIN_INTERVAL_MS {
        return false;
    }
    LAST_GDI_CAPTURE_MS.store(now, Ordering::Relaxed);
    true
}

#[inline]
fn prev_hash_or_zero(prev_hash: Option<[u8; 32]>) -> [u8; 32] {
    prev_hash.unwrap_or([0u8; 32])
}

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

#[inline]
fn bgra_buf_len(w: u32, h: u32) -> usize {
    ((w as u64) * (h as u64) * 4) as usize
}

#[inline]
fn bgra_row_byte_offset(y: u32, w: u32) -> usize {
    ((y as u64) * (w as u64) * 4) as usize
}

/// Downscale BGRA image using fast area/box-averaging downsampling.
/// Preserves thin text strokes, UI control borders, and red target markers when resizing from 1080p/1440p down to 1280.
pub fn downscale_bgra(src: &[u8], src_w: u32, src_h: u32, dst_w: u32, dst_h: u32) -> Vec<u8> {
    if dst_w == 0 || dst_h == 0 {
        return Vec::new();
    }
    if src_w == 0 || src_h == 0 || src.is_empty() {
        return vec![0u8; bgra_buf_len(dst_w, dst_h)];
    }

    let mut dst = vec![0u8; bgra_buf_len(dst_w, dst_h)];

    // Precompute x-coordinate bounds to eliminate repeated 64-bit divisions in the inner loop
    let mut x_bounds = Vec::with_capacity(dst_w as usize);
    for x in 0..dst_w {
        let x0 = (x as u64 * src_w as u64 / dst_w as u64) as u32;
        let x1 = (((x + 1) as u64 * src_w as u64 + dst_w as u64 - 1) / dst_w as u64).min(src_w as u64) as u32;
        x_bounds.push((x0, x1));
    }

    for y in 0..dst_h {
        let y0 = (y as u64 * src_h as u64 / dst_h as u64) as u32;
        let y1 = (((y + 1) as u64 * src_h as u64 + dst_h as u64 - 1) / dst_h as u64).min(src_h as u64) as u32;
        let dst_row_start = bgra_row_byte_offset(y, dst_w);

        for x in 0..dst_w {
            let (x0, x1) = x_bounds[x as usize];
            let di = dst_row_start + (x * 4) as usize;

            if x1 <= x0 || y1 <= y0 {
                let sx = x0.min(src_w.saturating_sub(1));
                let sy = y0.min(src_h.saturating_sub(1));
                let si = bgra_row_byte_offset(sy, src_w) + (sx * 4) as usize;
                if si + 4 <= src.len() && di + 4 <= dst.len() {
                    dst[di..di + 4].copy_from_slice(&src[si..si + 4]);
                }
                continue;
            }

            if x1 == x0 + 1 && y1 == y0 + 1 {
                let si = bgra_row_byte_offset(y0, src_w) + (x0 * 4) as usize;
                if si + 4 <= src.len() && di + 4 <= dst.len() {
                    dst[di..di + 4].copy_from_slice(&src[si..si + 4]);
                }
                continue;
            }

            let count = (x1 - x0) * (y1 - y0);
            let mut sum_b = 0u32;
            let mut sum_g = 0u32;
            let mut sum_r = 0u32;
            let mut sum_a = 0u32;

            for sy in y0..y1 {
                let row_start = (sy as usize) * (src_w as usize) * 4;
                let start_idx = row_start + (x0 as usize) * 4;
                let end_idx = row_start + (x1 as usize) * 4;
                if end_idx <= src.len() {
                    for px in src[start_idx..end_idx].chunks_exact(4) {
                        sum_b += px[0] as u32;
                        sum_g += px[1] as u32;
                        sum_r += px[2] as u32;
                        sum_a += px[3] as u32;
                    }
                }
            }

            if count > 0 && di + 4 <= dst.len() {
                dst[di] = (sum_b / count) as u8;
                dst[di + 1] = (sum_g / count) as u8;
                dst[di + 2] = (sum_r / count) as u8;
                dst[di + 3] = (sum_a / count) as u8;
            }
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
    let blt_ok = BitBlt(hdc_full, 0, 0, src_w, src_h, hdc_screen, vx, vy, SRCCOPY).is_ok()
        || BitBlt(
            hdc_full,
            0,
            0,
            src_w,
            src_h,
            hdc_screen,
            vx,
            vy,
            windows::Win32::Graphics::Gdi::ROP_CODE(SRCCOPY_CAPTURE),
        )
        .is_ok();
    if !blt_ok {
        let pw = GetSystemMetrics(SM_CXSCREEN);
        let ph = GetSystemMetrics(SM_CYSCREEN);
        if pw > 0 && ph > 0 && (pw != src_w || ph != src_h || vx != 0 || vy != 0) {
            let _ = SelectObject(hdc_full, old_full);
            let _ = DeleteObject(hbm_full);
            let _ = DeleteDC(hdc_full);
            return gdi_read_bgra(hdc_screen, pw, ph, dst_w, dst_h);
        }
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

    let mut bgra_buf = vec![0u8; bgra_buf_len(read_w, read_h)];
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

        let hwnd = GetDesktopWindow();
        let hdc_screen: HDC = GetDC(hwnd);
        if hdc_screen.is_invalid() {
            bail!("failed to get screen HDC");
        }

        let capture_res = gdi_read_bgra(hdc_screen, src_w, src_h, dst_w, dst_h);
        let _ = ReleaseDC(hwnd, hdc_screen);
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

        let hwnd = GetDesktopWindow();
        let hdc_screen: HDC = GetDC(hwnd);
        if hdc_screen.is_invalid() {
            bail!("failed to get screen HDC");
        }

        let mut bgra_buf = gdi_read_bgra(hdc_screen, src_w, src_h, dst_w, dst_h)?;
        let _ = ReleaseDC(hwnd, hdc_screen);

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

        let mut jpeg_bytes =
            Vec::with_capacity(((dst_w as u64 * dst_h as u64) / 2) as usize);
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

    let mut jpeg_bytes = Vec::with_capacity(((dst_w as u64 * dst_h as u64) / 2) as usize);
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

fn try_reuse_shared_last_bgra(
    max_w: u32,
    quality: u8,
    prev_hash: Option<[u8; 32]>,
    force: bool,
    marker: Option<(f64, f64)>,
    som: bool,
    check_black: bool,
) -> Option<Result<(Option<(u16, u16, Vec<u8>, String)>, [u8; 32])>> {
    let (w, h, bgra) = crate::dxgi_capture::shared_last_bgra_clone()?;
    debug!(w, h, "reusing last DXGI desktop frame (avoid GDI flicker)");
    Some(encode_bgra_screenshot(
        w, h, bgra, max_w, quality, prev_hash, force, marker, som, check_black,
    ))
}

fn try_reuse_last_dxgi_frame(
    max_w: u32,
    quality: u8,
    prev_hash: Option<[u8; 32]>,
    force: bool,
    marker: Option<(f64, f64)>,
    som: bool,
) -> Option<Result<(Option<(u16, u16, Vec<u8>, String)>, [u8; 32])>> {
    if !remote_view_capture_active() {
        return None;
    }
    try_reuse_shared_last_bgra(max_w, quality, prev_hash, force, marker, som, false)
}

fn skip_gdi_use_cached_frame(
    max_w: u32,
    quality: u8,
    prev_hash: Option<[u8; 32]>,
    force: bool,
    marker: Option<(f64, f64)>,
    som: bool,
) -> Result<(Option<(u16, u16, Vec<u8>, String)>, [u8; 32])> {
    if let Some(res) = try_reuse_shared_last_bgra(max_w, quality, prev_hash, force, marker, som, false) {
        return res;
    }
    if force {
        for ms in [32u32, 120, 400] {
            if let Ok(Some((w, h, bgra))) = crate::dxgi_capture::shared_capture_frame(ms) {
                if let Ok(out) = encode_bgra_screenshot(
                    w, h, bgra, max_w, quality, prev_hash, force, marker, som, true,
                ) {
                    return Ok(out);
                }
            }
        }
        if let Some(res) = try_reuse_shared_last_bgra(max_w, quality, prev_hash, force, marker, som, false) {
            return res;
        }
    }
    Ok((None, prev_hash_or_zero(prev_hash)))
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
    if !gdi_stream_capture_allowed() {
        return skip_gdi_use_cached_frame(max_w, quality, prev_hash, true, marker, som);
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
    let quality = if quality == 0 { 72 } else { quality.clamp(40, 95) };
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

    if remote_view_capture_active() && !crate::dxgi_capture::shared_dxgi_disabled() {
        debug!("skipping GDI while DXGI session is active (remote view)");
        return skip_gdi_use_cached_frame(max_w, quality, prev_hash, force, marker, som);
    }

    if !gdi_stream_capture_allowed() {
        return skip_gdi_use_cached_frame(max_w, quality, prev_hash, force, marker, som);
    }

    match capture_screen_gdi(max_w, quality, prev_hash, force, marker, som) {
        Ok(v) => Ok(v),
        Err(e) => {
            if force {
                if let Some(res) = try_reuse_last_dxgi_frame(max_w, quality, prev_hash, force, marker, som) {
                    return res;
                }
                if let Some((w, h, bgra)) = crate::dxgi_capture::shared_last_bgra_clone() {
                    if let Ok(out) = encode_bgra_screenshot(
                        w,
                        h,
                        bgra,
                        max_w,
                        quality,
                        prev_hash,
                        force,
                        marker,
                        som,
                        true,
                    ) {
                        warn!("GDI capture failed ({e:#}); using last DXGI frame");
                        return Ok(out);
                    }
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
    capture_screen_jpeg_with_params(max_w, quality, marker, som)
}

/// Capture full desktop into a JPEG byte buffer with dimensions and optional SoM axtree text.
/// Quality defaults to 72 if 0, clamped to 40..95 to preserve image clarity for vision models.
pub fn capture_screen_jpeg_with_params(
    max_w: u32,
    quality: u8,
    marker: Option<(f64, f64)>,
    som: bool,
) -> Result<(u16, u16, Vec<u8>, String)> {
    let q = if quality == 0 { 72 } else { quality.clamp(40, 95) };
    let (frame, _) = capture_screen_diff_opt(max_w, q, None, true, marker, som)?;
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_downscale_bgra_box_average() {
        // 2x2 image downscaled to 1x1
        // Pixel (0,0): [100, 100, 100, 255]
        // Pixel (1,0): [200, 200, 200, 255]
        // Pixel (0,1): [0, 0, 0, 255]
        // Pixel (1,1): [100, 100, 100, 255]
        // Expected average: (100 + 200 + 0 + 100) / 4 = 100
        #[rustfmt::skip]
        let src = vec![
            100, 100, 100, 255,  200, 200, 200, 255,
            0,   0,   0,   255,  100, 100, 100, 255,
        ];
        let dst = downscale_bgra(&src, 2, 2, 1, 1);
        assert_eq!(dst.len(), 4);
        assert_eq!(dst, vec![100, 100, 100, 255]);
    }

    #[test]
    fn test_downscale_bgra_preserves_thin_lines() {
        // 4x4 image with a thin 1-pixel red vertical line at x=1
        // BGRA format: [B, G, R, A] = [0, 0, 255, 255] for red, [0, 0, 0, 255] for black
        let mut src = vec![0u8; 4 * 4 * 4];
        for y in 0..4 {
            for x in 0..4 {
                let idx = (y * 4 + x) * 4;
                src[idx + 3] = 255; // Alpha
                if x == 1 {
                    src[idx + 2] = 255; // Red line
                }
            }
        }

        let dst = downscale_bgra(&src, 4, 4, 2, 2);
        assert_eq!(dst.len(), 2 * 2 * 4);

        // Destination pixel (0, 0) covers source x in 0..2, y in 0..2.
        // It samples (0,0)[black], (1,0)[red], (0,1)[black], (1,1)[red].
        // Red channel average = (0 + 255 + 0 + 255) / 4 = 127.
        let dst_r_00 = dst[2];
        assert_eq!(dst_r_00, 127, "red line stroke must be preserved in downscale");

        // Destination pixel (1, 0) covers source x in 2..4, y in 0..2 (all black).
        let dst_r_10 = dst[4 + 2];
        assert_eq!(dst_r_10, 0, "black area remains black");
    }

    #[test]
    fn test_downscale_bgra_identity() {
        let src = vec![
            10, 20, 30, 255, 40, 50, 60, 255,
            70, 80, 90, 255, 11, 22, 33, 255,
        ];
        let dst = downscale_bgra(&src, 2, 2, 2, 2);
        assert_eq!(dst, src);
    }

    #[test]
    fn test_downscale_bgra_zero_and_empty() {
        assert!(downscale_bgra(&[], 0, 0, 0, 0).is_empty());
        assert!(downscale_bgra(&[1, 2, 3, 4], 1, 1, 0, 0).is_empty());
        let empty_dst = downscale_bgra(&[], 0, 0, 10, 10);
        assert_eq!(empty_dst.len(), 10 * 10 * 4);
    }

    #[test]
    fn test_downscale_bgra_performance_1080p_to_720p() {
        let src_w = 1920u32;
        let src_h = 1080u32;
        let dst_w = 1280u32;
        let dst_h = 720u32;
        let src = vec![128u8; (src_w * src_h * 4) as usize];

        let start = std::time::Instant::now();
        let dst = downscale_bgra(&src, src_w, src_h, dst_w, dst_h);
        let elapsed = start.elapsed();

        assert_eq!(dst.len(), (dst_w * dst_h * 4) as usize);
        // Even unoptimized in debug mode it should be reasonable; log duration
        println!("1080p to 720p box-averaging elapsed: {:?}", elapsed);
    }

    #[test]
    fn test_quality_clamping_logic() {
        let clamp_q = |q: u8| if q == 0 { 72 } else { q.clamp(40, 95) };
        assert_eq!(clamp_q(0), 72);
        assert_eq!(clamp_q(20), 40);
        assert_eq!(clamp_q(40), 40);
        assert_eq!(clamp_q(72), 72);
        assert_eq!(clamp_q(80), 80);
        assert_eq!(clamp_q(95), 95);
        assert_eq!(clamp_q(100), 95);
    }
}
