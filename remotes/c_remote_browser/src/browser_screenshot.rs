use std::time::Duration;

use base64::Engine as _;
use image::codecs::jpeg::JpegEncoder;
use image::{ImageEncoder, RgbaImage};
use serde_json::{json, Value};

fn draw_red_marker_rgba(buf: &mut [u8], w: u32, h: u32, nx: f64, ny: f64) {
    let cx = (nx.clamp(0.0, 1.0) * (w.saturating_sub(1)) as f64).round() as i32;
    let cy = (ny.clamp(0.0, 1.0) * (h.saturating_sub(1)) as f64).round() as i32;
    let radius = 7i32;
    for dy in -radius..=radius {
        for dx in -radius..=radius {
            let px = cx + dx;
            let py = cy + dy;
            if px < 0 || px >= w as i32 || py < 0 || py >= h as i32 {
                continue;
            }
            let dist_sq = dx * dx + dy * dy;
            let idx = (py as usize * w as usize + px as usize) * 4;
            if dist_sq <= 16 {
                buf[idx] = 255;
                buf[idx + 1] = 0;
                buf[idx + 2] = 0;
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

fn jpeg_apply_marker(jpeg: &[u8], nx: f64, ny: f64, quality: u8) -> anyhow::Result<Vec<u8>> {
    let img = image::load_from_memory(jpeg)?;
    let mut rgba: RgbaImage = img.to_rgba8();
    let (w, h) = rgba.dimensions();
    draw_red_marker_rgba(rgba.as_mut(), w, h, nx, ny);
    let mut out = Vec::new();
    let q = quality.clamp(40, 95);
    JpegEncoder::new_with_quality(&mut out, q).write_image(
        rgba.as_raw(),
        w,
        h,
        image::ExtendedColorType::Rgba8,
    )?;
    Ok(out)
}

pub fn marker_coords(params: &Value) -> Option<(f64, f64)> {
    let marker_on = params.get("marker").and_then(|v| v.as_bool()).unwrap_or(true);
    if !marker_on {
        return None;
    }
    if let (Some(mx), Some(my)) = (
        params.get("marker_x").and_then(|v| v.as_f64()),
        params.get("marker_y").and_then(|v| v.as_f64()),
    ) {
        return Some((mx.clamp(0.0, 1.0), my.clamp(0.0, 1.0)));
    }
    crate::browser_state::global().and_then(|s| s.extension_hint_marker())
}

pub fn apply_marker_to_screenshot_json(shot: &mut Value, quality: u8, coords: Option<(f64, f64)>) {
    let Some((mx, my)) = coords else {
        return;
    };
    let b64 = shot
        .get("jpeg_b64")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    if b64.is_empty() {
        return;
    }
    if let Ok(jpeg) = base64::engine::general_purpose::STANDARD.decode(b64) {
        if let Ok(marked) = jpeg_apply_marker(&jpeg, mx, my, quality) {
            shot["jpeg_b64"] =
                json!(base64::engine::general_purpose::STANDARD.encode(&marked));
            shot["marker_applied"] = json!(true);
        }
    }
}

fn extension_capture_json(tab_id: Option<&str>, quality: u8) -> anyhow::Result<Value> {
    let bridge = crate::extension_ipc::extension_bridge_get()
        .ok_or_else(crate::extension_ipc::extension_ipc_not_ready_err)?;
    let mut ipc = json!({ "quality": quality });
    if let Some(tid) = tab_id.filter(|s| !s.is_empty()) {
        ipc["tab_id"] = json!(tid);
    }
    let op = "page.screenshot".to_string();
    bridge
        .call(&op, ipc, Duration::from_secs(90))
        .map_err(|e| anyhow::anyhow!("{e}"))
}

pub fn webrtc_capture(
    _max_w: u32,
    quality: u8,
    marker: Option<(f64, f64)>,
    som: bool,
) -> anyhow::Result<(u16, u16, Vec<u8>, String)> {
    if som {
        anyhow::bail!("Set-of-Mark (som) is not supported on remote browser agent");
    }
    if !crate::mode::is_extension_engine() {
        anyhow::bail!("screenshot on remote browser requires chrome extension engine");
    }
    let q = quality.clamp(40, 95);
    let tab_id = crate::browser_state::global()
        .map(|s| s.extension_hint_tab())
        .filter(|s| !s.is_empty());
    let mut shot = extension_capture_json(tab_id.as_deref(), q)?;
    let coords = marker.or_else(|| crate::browser_state::global().and_then(|s| s.extension_hint_marker()));
    apply_marker_to_screenshot_json(&mut shot, q, coords);
    let width = shot.get("width").and_then(|v| v.as_u64()).unwrap_or(0) as u16;
    let height = shot.get("height").and_then(|v| v.as_u64()).unwrap_or(0) as u16;
    let b64 = shot
        .get("jpeg_b64")
        .and_then(|v| v.as_str())
        .ok_or_else(|| anyhow::anyhow!("screenshot missing jpeg_b64"))?;
    let jpeg = base64::engine::general_purpose::STANDARD
        .decode(b64)
        .map_err(|e| anyhow::anyhow!("invalid jpeg_b64: {e}"))?;
    Ok((width, height, jpeg, String::new()))
}