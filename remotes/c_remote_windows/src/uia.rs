//! Windows UI Automation (UIA) Set-of-Mark (SoM) Engine.
//!
//! Scans the OS accessibility tree of the active foreground window,
//! discovers actionable interactive controls (buttons, inputs, links, tabs),
//! and overlays numbered bounding boxes (@1, @2, ...) directly onto screenshots.

use std::collections::VecDeque;
use tracing::debug;
use uiautomation::controls::ControlType;
use uiautomation::types::Handle;
use uiautomation::{UIAutomation, UIElement};
use windows::Win32::UI::WindowsAndMessaging::GetForegroundWindow;

const WALK_CAP: usize = 40;
const WALK_DEPTH: i32 = 12;

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
        return "(no UIA interactive elements found in foreground window)".into();
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

/// Walk the UI Automation tree of the active foreground window.
pub fn uia_walk() -> Vec<Mark> {
    let auto = match UIAutomation::new() {
        Ok(a) => a,
        Err(e) => {
            debug!("UIAutomation init error: {e}");
            return Vec::new();
        }
    };

    let root = match uia_root(&auto) {
        Ok(r) => r,
        Err(e) => {
            debug!("UIAutomation root error: {e}");
            return Vec::new();
        }
    };

    let walker = match auto.get_control_view_walker() {
        Ok(w) => w,
        Err(e) => {
            debug!("UIAutomation walker error: {e}");
            return Vec::new();
        }
    };

    let mut out = Vec::new();
    let mut q: VecDeque<(UIElement, i32)> = VecDeque::new();
    q.push_back((root, 0));
    let mut n = 1u32;

    while let Some((el, depth)) = q.pop_front() {
        if out.len() >= WALK_CAP {
            break;
        }
        if depth <= WALK_DEPTH {
            if let Some(mark) = mark_from(&el, n) {
                out.push(mark);
                n += 1;
            }
            if let Ok(child) = walker.get_first_child(&el) {
                let mut cur = child;
                loop {
                    q.push_back((cur.clone(), depth + 1));
                    match walker.get_next_sibling(&cur) {
                        Ok(next) => cur = next,
                        Err(_) => break,
                    }
                    if q.len() > 200 {
                        break;
                    }
                }
            }
        }
    }

    out
}

fn uia_root(auto: &UIAutomation) -> anyhow::Result<UIElement> {
    unsafe {
        let hwnd = GetForegroundWindow();
        if !hwnd.is_invalid() {
            if let Ok(el) = auto.element_from_handle(Handle::from(hwnd.0 as isize)) {
                return Ok(el);
            }
        }
    }
    Ok(auto
        .get_root_element()
        .or_else(|_| auto.get_focused_element())?)
}

fn mark_from(el: &UIElement, n: u32) -> Option<Mark> {
    let ct = el.get_control_type().ok()?;
    if !actionable(ct) {
        return None;
    }
    let rect = el.get_bounding_rectangle().ok()?;
    let left = rect.get_left();
    let top = rect.get_top();
    let w = rect.get_right() - left;
    let h = rect.get_bottom() - top;
    if w < 8 || h < 8 || w > 3000 || h > 1800 {
        return None;
    }
    let name: String = el.get_name().unwrap_or_default().chars().take(80).collect();
    Some(Mark {
        id: format!("@{n}"),
        control_type: format!("{ct:?}").replace("ControlType::", ""),
        name,
        auto_id: el.get_automation_id().unwrap_or_default(),
        center_x: left + w / 2,
        center_y: top + h / 2,
        bbox: [left, top, w, h],
    })
}

fn actionable(ct: ControlType) -> bool {
    matches!(
        ct,
        ControlType::Button
            | ControlType::Edit
            | ControlType::ComboBox
            | ControlType::MenuItem
            | ControlType::TabItem
            | ControlType::Hyperlink
            | ControlType::CheckBox
            | ControlType::ListItem
            | ControlType::TreeItem
            | ControlType::Document
            | ControlType::SplitButton
            | ControlType::RadioButton
    )
}

// ---------------------------------------------------------------------------
// Set-of-Mark Overlay Rendering (5x7 Embedded Digit Font, 0 External Deps)
// ---------------------------------------------------------------------------

const DIGITS_5X7: [&[u8; 7]; 10] = [
    &[0b01110, 0b10001, 0b10011, 0b10101, 0b11001, 0b10001, 0b01110], // 0
    &[0b00100, 0b01100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110], // 1
    &[0b01110, 0b10001, 0b00001, 0b00010, 0b00100, 0b01000, 0b11111], // 2
    &[0b11111, 0b00010, 0b00100, 0b00010, 0b00001, 0b10001, 0b01110], // 3
    &[0b00010, 0b00110, 0b01010, 0b10010, 0b11111, 0b00010, 0b00010], // 4
    &[0b11111, 0b10000, 0b11110, 0b00001, 0b00001, 0b10001, 0b01110], // 5
    &[0b00110, 0b01000, 0b10000, 0b11110, 0b10001, 0b10001, 0b01110], // 6
    &[0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b01000, 0b01000], // 7
    &[0b01110, 0b10001, 0b10001, 0b01110, 0b10001, 0b10001, 0b01110], // 8
    &[0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b00010, 0b01100], // 9
];

/// Draw a single digit using the 5x7 bitmask with scale factor 2x.
fn draw_digit(buf: &mut [u8], w: u32, h: u32, start_x: i32, start_y: i32, digit: usize) {
    if digit > 9 {
        return;
    }
    let glyph = DIGITS_5X7[digit];
    for (row, &bits) in glyph.iter().enumerate() {
        for col in 0..5 {
            if (bits & (1 << (4 - col))) != 0 {
                // 2x scaling: plot 2x2 pixels
                for dy in 0..2 {
                    for dx in 0..2 {
                        let px = start_x + col * 2 + dx;
                        let py = start_y + (row as i32) * 2 + dy;
                        if px >= 0 && px < w as i32 && py >= 0 && py < h as i32 {
                            let idx = (py as usize * w as usize + px as usize) * 4;
                            // White text: BGRA = [255, 255, 255, 255]
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
}

/// Draw the Set-of-Mark (SoM) bounding boxes and label badges (@1, @2, ...) onto the BGRA image.
pub fn draw_som_overlay(
    buf: &mut [u8],
    dst_w: u32,
    dst_h: u32,
    src_w: u32,
    src_h: u32,
    marks: &[Mark],
) {
    if marks.is_empty() || dst_w == 0 || dst_h == 0 || src_w == 0 || src_h == 0 {
        return;
    }

    let scale_x = dst_w as f64 / src_w as f64;
    let scale_y = dst_h as f64 / src_h as f64;

    for m in marks {
        let [orig_x, orig_y, orig_w, orig_h] = m.bbox;
        if orig_x < 0 || orig_y < 0 {
            continue;
        }

        let bx = (orig_x as f64 * scale_x).round() as i32;
        let by = (orig_y as f64 * scale_y).round() as i32;
        let bw = (orig_w as f64 * scale_x).round().max(8.0) as i32;
        let bh = (orig_h as f64 * scale_y).round().max(8.0) as i32;

        let right = (bx + bw).min(dst_w as i32 - 1);
        let bottom = (by + bh).min(dst_h as i32 - 1);

        // 1. Draw 2px hollow bounding box in Coral / Orange-Red: BGRA = [0, 69, 255, 255]
        for y in by..=bottom {
            for x in bx..=right {
                let is_border = (y - by).abs() < 2
                    || (y - bottom).abs() < 2
                    || (x - bx).abs() < 2
                    || (x - right).abs() < 2;

                if is_border && x >= 0 && x < dst_w as i32 && y >= 0 && y < dst_h as i32 {
                    let idx = (y as usize * dst_w as usize + x as usize) * 4;
                    buf[idx] = 0;
                    buf[idx + 1] = 69;
                    buf[idx + 2] = 255;
                    buf[idx + 3] = 255;
                }
            }
        }

        // 2. Draw number badge above the top-left of the box
        // Extract number from "@1" -> 1
        let num_str = m.id.trim_start_matches('@');
        let num_digits = num_str.len();
        let badge_w = (14 + num_digits * 12) as i32;
        let badge_h = 18i32;
        let badge_y = (by - badge_h).max(0);
        let badge_x = bx.max(0);

        // Fill badge background in Crimson Red: BGRA = [60, 20, 220, 255]
        for y in badge_y..badge_y + badge_h {
            for x in badge_x..badge_x + badge_w {
                if x >= 0 && x < dst_w as i32 && y >= 0 && y < dst_h as i32 {
                    let idx = (y as usize * dst_w as usize + x as usize) * 4;
                    buf[idx] = 60;
                    buf[idx + 1] = 20;
                    buf[idx + 2] = 220;
                    buf[idx + 3] = 255;
                }
            }
        }

        // 3. Render digits in white text inside badge
        let mut char_x = badge_x + 4;
        let char_y = badge_y + 2;
        for c in num_str.chars() {
            if let Some(digit) = c.to_digit(10) {
                draw_digit(buf, dst_w, dst_h, char_x, char_y, digit as usize);
                char_x += 12;
            }
        }
    }
}
