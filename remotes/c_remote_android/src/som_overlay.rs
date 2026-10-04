//! Set-of-Mark (SoM) overlay and red marker drawing for Android screenshots.

#[derive(Clone, Debug, Default, serde::Serialize, serde::Deserialize)]
pub struct Mark {
    pub id: String,
    pub control_type: String,
    pub name: String,
    pub auto_id: String,
    pub center_x: i32,
    pub center_y: i32,
    pub bbox: [i32; 4], // [left, top, width, height]
}

/// Formats the accessibility tree marks into a structured text prompt list for LLMs.
pub fn axtree_text(marks: &[Mark], screen_w: u32, screen_h: u32) -> String {
    if marks.is_empty() {
        return "(no accessibility interactive elements found)".into();
    }
    let mut lines = Vec::with_capacity(marks.len() + 1);
    lines.push("Interactive UI elements (use exact normalized x, y to click):".to_string());
    for m in marks {
        let nx = if screen_w > 0 { (m.center_x as f64 / screen_w as f64).clamp(0.0, 1.0) } else { 0.0 };
        let ny = if screen_h > 0 { (m.center_y as f64 / screen_h as f64).clamp(0.0, 1.0) } else { 0.0 };
        lines.push(format!(
            "{} {} '{}' -> center=({:.3}, {:.3}) pixel=({}, {})",
            m.id, m.control_type, m.name, nx, ny, m.center_x, m.center_y
        ));
    }
    lines.join("\n")
}

/// Draw a high-contrast red marker with a white ring at normalized coordinates (nx, ny)
/// so multimodal models do not have to guess where actions/clicks land.
/// RGBA buffer layout: [R, G, B, A]
pub fn draw_red_marker_rgba(buf: &mut [u8], w: u32, h: u32, nx: f64, ny: f64) {
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
                    // Solid bright red center: RGBA = [255, 0, 0, 255]
                    buf[idx] = 255;
                    buf[idx + 1] = 0;
                    buf[idx + 2] = 0;
                    buf[idx + 3] = 255;
                } else if dist_sq <= 49 {
                    // White outer ring: RGBA = [255, 255, 255, 255]
                    buf[idx] = 255;
                    buf[idx + 1] = 255;
                    buf[idx + 2] = 255;
                    buf[idx + 3] = 255;
                }
            }
        }
    }
}

/// Draw the Set-of-Mark (SoM) bounding boxes and label badges (@1, @2, ...) onto RGBA image.
pub fn draw_som_overlay_rgba(
    buf: &mut [u8],
    w: u32,
    h: u32,
    marks: &[Mark],
) {
    if marks.is_empty() || w == 0 || h == 0 {
        return;
    }

    for m in marks {
        let [orig_x, orig_y, orig_w, orig_h] = m.bbox;
        if orig_x < 0 || orig_y < 0 {
            continue;
        }

        let bx = orig_x;
        let by = orig_y;
        let bw = orig_w.max(8);
        let bh = orig_h.max(8);

        let right = (bx + bw).min(w as i32 - 1);
        let bottom = (by + bh).min(h as i32 - 1);

        // 1. Draw 2px hollow bounding box in Coral / Orange-Red: RGBA = [255, 69, 0, 255]
        for y in by..=bottom {
            for x in bx..=right {
                let is_border = (y - by).abs() < 2
                    || (y - bottom).abs() < 2
                    || (x - bx).abs() < 2
                    || (x - right).abs() < 2;

                if is_border && x >= 0 && x < w as i32 && y >= 0 && y < h as i32 {
                    let idx = (y as usize * w as usize + x as usize) * 4;
                    buf[idx] = 255;
                    buf[idx + 1] = 69;
                    buf[idx + 2] = 0;
                    buf[idx + 3] = 255;
                }
            }
        }

        // 2. Draw number badge above the top-left of the box
        let num_str = m.id.trim_start_matches('@');
        let num_digits = num_str.len();
        let badge_w = (14 + num_digits * 12) as i32;
        let badge_h = 18i32;
        let badge_y = (by - badge_h).max(0);
        let badge_x = bx.max(0);

        // Fill badge background in Crimson Red: RGBA = [220, 20, 60, 255]
        for y in badge_y..badge_y + badge_h {
            for x in badge_x..badge_x + badge_w {
                if x >= 0 && x < w as i32 && y >= 0 && y < h as i32 {
                    let idx = (y as usize * w as usize + x as usize) * 4;
                    buf[idx] = 220;
                    buf[idx + 1] = 20;
                    buf[idx + 2] = 60;
                    buf[idx + 3] = 255;
                }
            }
        }

        // 3. Render digits in white text inside badge
        let mut char_x = badge_x + 4;
        let char_y = badge_y + 2;
        for c in num_str.chars() {
            if let Some(digit) = c.to_digit(10) {
                draw_digit(buf, w, h, char_x, char_y, digit as usize);
                char_x += 12;
            }
        }
    }
}

/// Simple 5x7 bitmap font for rendering digits 0-9.
fn draw_digit(buf: &mut [u8], w: u32, h: u32, x: i32, y: i32, d: usize) {
    if d > 9 {
        return;
    }
    const FONT: [[u8; 7]; 10] = [
        [0b01110, 0b10001, 0b10011, 0b10101, 0b11001, 0b10001, 0b01110], // 0
        [0b00100, 0b01100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110], // 1
        [0b01110, 0b10001, 0b00001, 0b00010, 0b00100, 0b01000, 0b11111], // 2
        [0b11111, 0b00010, 0b00100, 0b00010, 0b00001, 0b10001, 0b01110], // 3
        [0b00010, 0b00110, 0b01010, 0b10010, 0b11111, 0b00010, 0b00010], // 4
        [0b11111, 0b10000, 0b11110, 0b00001, 0b00001, 0b10001, 0b01110], // 5
        [0b00110, 0b01000, 0b10000, 0b11110, 0b10001, 0b10001, 0b01110], // 6
        [0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b01000, 0b01000], // 7
        [0b01110, 0b10001, 0b10001, 0b01110, 0b10001, 0b10001, 0b01110], // 8
        [0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b00010, 0b01100], // 9
    ];

    let pattern = &FONT[d];
    for (row, bits) in pattern.iter().enumerate() {
        for col in 0..5 {
            if (bits & (1 << (4 - col))) != 0 {
                let px = x + col;
                let py = y + row as i32 * 2; // 2x vertical scale for 14px height
                for sub_y in 0..2 {
                    let rpy = py + sub_y;
                    if px >= 0 && px < w as i32 && rpy >= 0 && rpy < h as i32 {
                        let idx = (rpy as usize * w as usize + px as usize) * 4;
                        buf[idx] = 255;
                        buf[idx + 1] = 255;
                        buf[idx + 2] = 255;
                        buf[idx + 3] = 255;
                    }
                }
            }
        }
    }
}
