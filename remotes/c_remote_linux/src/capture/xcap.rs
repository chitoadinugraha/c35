use anyhow::{Context, Result};
use tracing::warn;
use xcap::Monitor;

pub fn capture_primary_bgra() -> Result<(u32, u32, Vec<u8>)> {
    let monitors = Monitor::all().context("monitor list")?;
    let monitor = monitors.first().context("no monitors found")?;
    let img = monitor.capture_image().context("xcap capture")?;
    let w = img.width();
    let h = img.height();
    let rgba = img.as_raw();
    let bgra = rgba_to_bgra(rgba, w, h);
    if frame_mostly_black(&bgra) {
        warn!(
            "xcap frame is mostly black (Wayland without portal, locked session, or no DISPLAY?)"
        );
    }
    Ok((w, h, bgra))
}

fn rgba_to_bgra(rgba: &[u8], w: u32, h: u32) -> Vec<u8> {
    let len = (w as usize) * (h as usize) * 4;
    let mut bgra = vec![0u8; len];
    for (i, px) in rgba.chunks_exact(4).enumerate() {
        let o = i * 4;
        bgra[o] = px[2];
        bgra[o + 1] = px[1];
        bgra[o + 2] = px[0];
        bgra[o + 3] = px[3];
    }
    bgra
}

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

pub fn desktop_width_cap() -> u32 {
    Monitor::all()
        .ok()
        .and_then(|m| m.first().map(|mon| mon.width()))
        .filter(|w| *w > 0)
        .unwrap_or(1920)
}
