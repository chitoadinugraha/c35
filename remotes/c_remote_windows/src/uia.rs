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
use windows::Win32::UI::WindowsAndMessaging::{GetForegroundWindow, GetWindowTextW};

const WALK_CAP: usize = 200;
const WALK_DEPTH: i32 = 20;

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

pub const MAX_AXTREE_ITEMS: usize = 50;

/// Formats the accessibility tree marks into a structured text prompt list for LLMs.
pub fn axtree_text(marks: &[Mark], screen_w: u32, screen_h: u32) -> String {
    let mut filtered: Vec<&Mark> = marks
        .iter()
        .filter(|m| {
            // Filter out elements whose bounding box/center is completely off-screen
            let is_off_screen = m.center_x < 0
                || m.center_y < 0
                || (screen_w > 0 && m.center_x > screen_w as i32)
                || (screen_h > 0 && m.center_y > screen_h as i32);
            if is_off_screen {
                return false;
            }

            // Filter out elements with empty names UNLESS control_type is Edit, ComboBox, or Document
            let is_unlabeled_actionable = matches!(
                m.control_type.as_str(),
                "Edit" | "ComboBox" | "Document"
            );
            if m.name.trim().is_empty() && !is_unlabeled_actionable {
                return false;
            }

            true
        })
        .collect();

    if filtered.is_empty() {
        return "(no UIA interactive elements found in foreground window)".into();
    }

    // Prioritize most interactive controls (Edit, Button, ComboBox, CheckBox, TabItem, Hyperlink)
    filtered.sort_by_key(|m| {
        match m.control_type.as_str() {
            "Edit" | "Button" | "ComboBox" | "CheckBox" | "TabItem" | "Hyperlink" => 0,
            _ => 1,
        }
    });

    let max_items = filtered.len().min(MAX_AXTREE_ITEMS);
    let mut lines = Vec::with_capacity(max_items + 1);
    lines.push("Interactive UI elements (use exact normalized x, y to click):".to_string());
    for m in filtered.into_iter().take(MAX_AXTREE_ITEMS) {
        let nx = if screen_w > 0 { (m.center_x as f64 / screen_w as f64).clamp(0.0, 1.0) } else { 0.0 };
        let ny = if screen_h > 0 { (m.center_y as f64 / screen_h as f64).clamp(0.0, 1.0) } else { 0.0 };
        lines.push(format!(
            "{} {} '{}' -> center=({:.3}, {:.3}) pixel=({}, {}) size=({}x{})",
            m.id, m.control_type, m.name, nx, ny, m.center_x, m.center_y, m.bbox[2], m.bbox[3]
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
                    if q.len() > 1000 {
                        break;
                    }
                }
            }
        }
    }

    out
}

pub fn uia_foreground_title() -> String {
    unsafe {
        let hwnd = GetForegroundWindow();
        if hwnd.is_invalid() {
            return String::new();
        }
        let mut buf = [0u16; 256];
        let n = GetWindowTextW(hwnd, &mut buf);
        if n <= 0 {
            return String::new();
        }
        String::from_utf16_lossy(&buf[..n as usize])
    }
}

/// UIA name at pixel + foreground window title (for teach step labels).
pub fn resolve_element_at(x: i32, y: i32) -> (String, String) {
    let window = uia_foreground_title();
    if let Ok(auto) = UIAutomation::new() {
        if let Ok(el) = auto.element_from_point(uiautomation::types::Point::new(x, y)) {
            let name = el.get_name().unwrap_or_default();
            if !name.trim().is_empty() {
                return (name, window);
            }
        }
    }
    let marks = uia_walk();
    let mut best: Option<(i64, String)> = None;
    for m in marks {
        let dx = (m.center_x - x) as i64;
        let dy = (m.center_y - y) as i64;
        let d = dx * dx + dy * dy;
        if best.as_ref().map(|(bd, _)| d < *bd).unwrap_or(true) {
            best = Some((d, m.name));
        }
    }
    match best {
        Some((_, name)) if !name.trim().is_empty() => (name, window),
        _ => (String::new(), window),
    }
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
    if w < 6 || h < 6 || w > 3840 || h > 2160 {
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_axtree_text_formatting_with_size() {
        let marks = vec![
            Mark {
                id: "@1".to_string(),
                control_type: "Button".to_string(),
                name: "Submit".to_string(),
                auto_id: "btn_submit".to_string(),
                center_x: 864,
                center_y: 345,
                bbox: [804, 327, 120, 36],
            },
            Mark {
                id: "@2".to_string(),
                control_type: "Edit".to_string(),
                name: "Username".to_string(),
                auto_id: "txt_user".to_string(),
                center_x: 500,
                center_y: 200,
                bbox: [400, 185, 200, 30],
            },
        ];

        let text = axtree_text(&marks, 1920, 1080);
        let lines: Vec<&str> = text.lines().collect();
        assert_eq!(lines.len(), 3);
        assert_eq!(lines[0], "Interactive UI elements (use exact normalized x, y to click):");
        assert_eq!(
            lines[1],
            "@1 Button 'Submit' -> center=(0.450, 0.319) pixel=(864, 345) size=(120x36)"
        );
        assert_eq!(
            lines[2],
            "@2 Edit 'Username' -> center=(0.260, 0.185) pixel=(500, 200) size=(200x30)"
        );
    }

    #[test]
    fn test_axtree_text_empty() {
        assert_eq!(
            axtree_text(&[], 1920, 1080),
            "(no UIA interactive elements found in foreground window)"
        );
    }

    #[test]
    fn test_actionable_controls() {
        assert!(actionable(ControlType::Button));
        assert!(actionable(ControlType::Edit));
        assert!(actionable(ControlType::ComboBox));
        assert!(actionable(ControlType::MenuItem));
        assert!(actionable(ControlType::TabItem));
        assert!(actionable(ControlType::Hyperlink));
        assert!(actionable(ControlType::CheckBox));
        assert!(actionable(ControlType::ListItem));
        assert!(actionable(ControlType::TreeItem));
        assert!(actionable(ControlType::Document));
        assert!(actionable(ControlType::SplitButton));
        assert!(actionable(ControlType::RadioButton));

        assert!(!actionable(ControlType::Text));
        assert!(!actionable(ControlType::Pane));
        assert!(!actionable(ControlType::Window));
    }

    #[test]
    fn test_axtree_text_filters_offscreen() {
        let marks = vec![
            Mark {
                id: "@1".to_string(),
                control_type: "Button".to_string(),
                name: "OffScreen Left".to_string(),
                auto_id: "".to_string(),
                center_x: -10,
                center_y: 200,
                bbox: [-50, 180, 80, 40],
            },
            Mark {
                id: "@2".to_string(),
                control_type: "Button".to_string(),
                name: "OffScreen Right".to_string(),
                auto_id: "".to_string(),
                center_x: 2000,
                center_y: 200,
                bbox: [1950, 180, 100, 40],
            },
            Mark {
                id: "@3".to_string(),
                control_type: "Button".to_string(),
                name: "OffScreen Top".to_string(),
                auto_id: "".to_string(),
                center_x: 500,
                center_y: -5,
                bbox: [450, -30, 100, 50],
            },
            Mark {
                id: "@4".to_string(),
                control_type: "Button".to_string(),
                name: "OffScreen Bottom".to_string(),
                auto_id: "".to_string(),
                center_x: 500,
                center_y: 1200,
                bbox: [450, 1180, 100, 40],
            },
            Mark {
                id: "@5".to_string(),
                control_type: "Button".to_string(),
                name: "Visible Button".to_string(),
                auto_id: "".to_string(),
                center_x: 500,
                center_y: 500,
                bbox: [450, 480, 100, 40],
            },
        ];

        let text = axtree_text(&marks, 1920, 1080);
        let lines: Vec<&str> = text.lines().collect();
        assert_eq!(lines.len(), 2);
        assert_eq!(lines[0], "Interactive UI elements (use exact normalized x, y to click):");
        assert!(lines[1].contains("Visible Button"));
    }

    #[test]
    fn test_axtree_text_filters_empty_name_unless_actionable_input() {
        let marks = vec![
            Mark {
                id: "@1".to_string(),
                control_type: "Button".to_string(),
                name: "".to_string(),
                auto_id: "".to_string(),
                center_x: 100,
                center_y: 100,
                bbox: [80, 80, 40, 40],
            },
            Mark {
                id: "@2".to_string(),
                control_type: "Button".to_string(),
                name: "   ".to_string(),
                auto_id: "".to_string(),
                center_x: 200,
                center_y: 100,
                bbox: [180, 80, 40, 40],
            },
            Mark {
                id: "@3".to_string(),
                control_type: "Edit".to_string(),
                name: "".to_string(),
                auto_id: "txt_search".to_string(),
                center_x: 300,
                center_y: 100,
                bbox: [250, 80, 100, 40],
            },
            Mark {
                id: "@4".to_string(),
                control_type: "ComboBox".to_string(),
                name: "  ".to_string(),
                auto_id: "cmb_select".to_string(),
                center_x: 450,
                center_y: 100,
                bbox: [400, 80, 100, 40],
            },
            Mark {
                id: "@5".to_string(),
                control_type: "Document".to_string(),
                name: "".to_string(),
                auto_id: "doc_editor".to_string(),
                center_x: 600,
                center_y: 100,
                bbox: [550, 80, 100, 40],
            },
            Mark {
                id: "@6".to_string(),
                control_type: "ListItem".to_string(),
                name: "".to_string(),
                auto_id: "".to_string(),
                center_x: 750,
                center_y: 100,
                bbox: [700, 80, 100, 40],
            },
        ];

        let text = axtree_text(&marks, 1920, 1080);
        let lines: Vec<&str> = text.lines().collect();
        // Header + 3 actionable empty-named text inputs (Edit, ComboBox, Document)
        assert_eq!(lines.len(), 4);
        assert!(lines[1].contains("Edit"));
        assert!(lines[2].contains("ComboBox"));
        assert!(lines[3].contains("Document"));
    }

    #[test]
    fn test_axtree_text_prioritizes_interactive_controls() {
        let marks = vec![
            Mark {
                id: "@1".to_string(),
                control_type: "ListItem".to_string(),
                name: "Row 1".to_string(),
                auto_id: "".to_string(),
                center_x: 100,
                center_y: 100,
                bbox: [80, 80, 100, 30],
            },
            Mark {
                id: "@2".to_string(),
                control_type: "Button".to_string(),
                name: "Save".to_string(),
                auto_id: "".to_string(),
                center_x: 200,
                center_y: 100,
                bbox: [180, 80, 80, 30],
            },
            Mark {
                id: "@3".to_string(),
                control_type: "TreeItem".to_string(),
                name: "Node 1".to_string(),
                auto_id: "".to_string(),
                center_x: 300,
                center_y: 100,
                bbox: [280, 80, 100, 30],
            },
            Mark {
                id: "@4".to_string(),
                control_type: "Hyperlink".to_string(),
                name: "Help".to_string(),
                auto_id: "".to_string(),
                center_x: 400,
                center_y: 100,
                bbox: [380, 80, 60, 30],
            },
        ];

        let text = axtree_text(&marks, 1920, 1080);
        let lines: Vec<&str> = text.lines().collect();
        assert_eq!(lines.len(), 5);
        // Priority 0: Button and Hyperlink (preserved order between them: Button, then Hyperlink)
        assert!(lines[1].contains("@2 Button 'Save'"));
        assert!(lines[2].contains("@4 Hyperlink 'Help'"));
        // Priority 1: ListItem and TreeItem (preserved order: Row 1, Node 1)
        assert!(lines[3].contains("@1 ListItem 'Row 1'"));
        assert!(lines[4].contains("@3 TreeItem 'Node 1'"));
    }

    #[test]
    fn test_axtree_text_capped_at_50() {
        let mut marks = Vec::new();
        for i in 1..=80 {
            marks.push(Mark {
                id: format!("@{i}"),
                control_type: "Button".to_string(),
                name: format!("Button {i}"),
                auto_id: "".to_string(),
                center_x: 100,
                center_y: 100,
                bbox: [80, 80, 50, 30],
            });
        }

        let text = axtree_text(&marks, 1920, 1080);
        let lines: Vec<&str> = text.lines().collect();
        // 1 header line + 50 items = 51 lines
        assert_eq!(lines.len(), 51);
        assert_eq!(lines[0], "Interactive UI elements (use exact normalized x, y to click):");
        assert!(lines[1].contains("@1 Button 'Button 1'"));
        assert!(lines[50].contains("@50 Button 'Button 50'"));
    }
}
