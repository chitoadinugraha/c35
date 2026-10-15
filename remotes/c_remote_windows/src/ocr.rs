//! WinRT OCR Engine integration for Canvas Set-of-Mark (SoM) perception.
//!
//! Utilizes `Windows.Media.Ocr.OcrEngine` to recognize text on canvas / custom controls
//! (Google Sheets, Figma, Flutter Web, SVG diagrams) without external binary dependencies.

use std::sync::OnceLock;
use anyhow::Result;
use tracing::{debug, warn};
use windows::Graphics::Imaging::{BitmapAlphaMode, BitmapPixelFormat, SoftwareBitmap};
use windows::Media::Ocr::OcrEngine;
use windows::Storage::Streams::DataWriter;

#[derive(Clone, Debug, Default, serde::Serialize, serde::Deserialize, PartialEq)]
pub struct OcrMark {
    pub text: String,
    pub center_x: i32,
    pub center_y: i32,
    pub bbox: [i32; 4], // [left, top, width, height]
}

/// Retrieve or lazily initialize the singleton WinRT OCR engine.
fn get_ocr_engine() -> Option<&'static OcrEngine> {
    static OCR_ENGINE: OnceLock<Option<OcrEngine>> = OnceLock::new();
    OCR_ENGINE
        .get_or_init(|| {
            // 1. Try from user profile languages (system default)
            match OcrEngine::TryCreateFromUserProfileLanguages() {
                Ok(engine) => {
                    debug!("Initialized WinRT OcrEngine from user profile languages");
                    Some(engine)
                }
                Err(e) => {
                    debug!("OcrEngine::TryCreateFromUserProfileLanguages failed: {e}; trying available languages");
                    // 2. Fallback to first available language if any
                    if let Ok(langs) = OcrEngine::AvailableRecognizerLanguages() {
                        if let Ok(first) = langs.GetAt(0) {
                            if let Ok(engine) = OcrEngine::TryCreateFromLanguage(&first) {
                                debug!("Initialized WinRT OcrEngine from first available language");
                                return Some(engine);
                            }
                        }
                    }
                    warn!("No supported WinRT OCR language pack found on system");
                    None
                }
            }
        })
        .as_ref()
}

/// Crop the sub-region specified by `roi: [left, top, width, height]` from a BGRA buffer.
/// Returns (cropped_buffer, crop_x, crop_y, crop_w, crop_h).
pub fn crop_bgra(
    data: &[u8],
    width: u32,
    height: u32,
    roi: Option<[i32; 4]>,
) -> Option<(Vec<u8>, u32, u32, u32, u32)> {
    let [rx, ry, rw, rh] = match roi {
        Some(r) => r,
        None => return None,
    };

    if rw <= 0 || rh <= 0 || width == 0 || height == 0 {
        return None;
    }

    let x0 = rx.clamp(0, width as i32) as u32;
    let y0 = ry.clamp(0, height as i32) as u32;
    let x1 = (rx + rw).clamp(0, width as i32) as u32;
    let y1 = (ry + rh).clamp(0, height as i32) as u32;

    if x1 <= x0 || y1 <= y0 {
        return None;
    }

    let crop_w = x1 - x0;
    let crop_h = y1 - y0;

    // If ROI covers the entire image, skip allocation
    if crop_w == width && crop_h == height && x0 == 0 && y0 == 0 {
        return None;
    }

    let mut cropped = vec![0u8; crop_w as usize * crop_h as usize * 4];
    let row_bytes = (crop_w * 4) as usize;

    for row in 0..crop_h {
        let src_off = (((y0 + row) * width + x0) * 4) as usize;
        let dst_off = (row * crop_w * 4) as usize;
        if src_off + row_bytes <= data.len() && dst_off + row_bytes <= cropped.len() {
            cropped[dst_off..dst_off + row_bytes]
                .copy_from_slice(&data[src_off..src_off + row_bytes]);
        }
    }

    Some((cropped, x0, y0, crop_w, crop_h))
}

/// Execute native WinRT OCR on a BGRA image buffer within optional ROI bounds.
///
/// Returns words and compact phrases with bounding boxes and centers.
/// Gracefully recovers from language or WinRT errors by returning an empty Vec.
pub fn run_ocr_bgra(
    data: &[u8],
    width: u32,
    height: u32,
    roi: Option<[i32; 4]>,
) -> Result<Vec<OcrMark>> {
    if data.is_empty() || width == 0 || height == 0 {
        return Ok(Vec::new());
    }

    let engine = match get_ocr_engine() {
        Some(e) => e,
        None => return Ok(Vec::new()),
    };

    let (crop_res, (buf_slice, eff_w, eff_h, off_x, off_y)) =
        match crop_bgra(data, width, height, roi) {
            Some((cropped, cx, cy, cw, ch)) => {
                (Some(cropped), (None, cw, ch, cx as i32, cy as i32))
            }
            None => (None, (Some(data), width, height, 0i32, 0i32)),
        };

    let bytes = match &crop_res {
        Some(c) => c.as_slice(),
        None => buf_slice.unwrap_or(data),
    };

    let expected_len = (eff_w as usize) * (eff_h as usize) * 4;
    if bytes.len() < expected_len {
        return Ok(Vec::new());
    }

    // Windows OCR requires dimensions to not exceed MaxImageDimension
    let max_dim = OcrEngine::MaxImageDimension().unwrap_or(4096);
    if eff_w > max_dim || eff_h > max_dim {
        debug!(
            eff_w,
            eff_h, max_dim, "Image dimensions exceed WinRT OCR MaxImageDimension"
        );
        return Ok(Vec::new());
    }

    let result = (|| -> windows::core::Result<Vec<OcrMark>> {
        let writer = DataWriter::new()?;
        writer.WriteBytes(bytes)?;
        let buffer = writer.DetachBuffer()?;

        let bitmap = SoftwareBitmap::CreateCopyWithAlphaFromBuffer(
            &buffer,
            BitmapPixelFormat::Bgra8,
            eff_w as i32,
            eff_h as i32,
            BitmapAlphaMode::Premultiplied,
        )?;

        let async_op = engine.RecognizeAsync(&bitmap)?;
        let ocr_result = async_op.get()?;
        let lines = ocr_result.Lines()?;

        let mut marks = Vec::new();

        for line in lines {
            let words = match line.Words() {
                Ok(w) => w,
                Err(_) => continue,
            };

            // Group adjacent words on the same line if gap is small (normal word spacing <= 20px)
            let mut cur_text = String::new();
            let mut cur_x = 0i32;
            let mut cur_y = 0i32;
            let mut cur_w = 0i32;
            let mut cur_h = 0i32;
            let mut has_group = false;

            for word in words {
                let w_text = match word.Text() {
                    Ok(t) => t.to_string(),
                    Err(_) => continue,
                };
                let w_text = w_text.trim();
                if w_text.is_empty() {
                    continue;
                }

                let rect = match word.BoundingRect() {
                    Ok(r) => r,
                    Err(_) => continue,
                };

                let wx = off_x + rect.X.round() as i32;
                let wy = off_y + rect.Y.round() as i32;
                let ww = rect.Width.round() as i32;
                let wh = rect.Height.round() as i32;

                if ww <= 2 || wh <= 2 {
                    continue;
                }

                if !has_group {
                    cur_text = w_text.to_string();
                    cur_x = wx;
                    cur_y = wy;
                    cur_w = ww;
                    cur_h = wh;
                    has_group = true;
                } else {
                    let gap = wx - (cur_x + cur_w);
                    let v_diff = (wy - cur_y).abs();
                    // If word is on same horizontal line with small gap (<= 20px), combine into phrase
                    if gap >= 0 && gap <= 20 && v_diff <= cur_h.max(wh) / 2 {
                        cur_text.push(' ');
                        cur_text.push_str(w_text);
                        let right = (wx + ww).max(cur_x + cur_w);
                        let bottom = (wy + wh).max(cur_y + cur_h);
                        cur_x = cur_x.min(wx);
                        cur_y = cur_y.min(wy);
                        cur_w = right - cur_x;
                        cur_h = bottom - cur_y;
                    } else {
                        // Flush current group
                        if !cur_text.is_empty() && cur_w > 0 && cur_h > 0 {
                            marks.push(OcrMark {
                                text: cur_text.clone(),
                                center_x: cur_x + cur_w / 2,
                                center_y: cur_y + cur_h / 2,
                                bbox: [cur_x, cur_y, cur_w, cur_h],
                            });
                        }
                        cur_text = w_text.to_string();
                        cur_x = wx;
                        cur_y = wy;
                        cur_w = ww;
                        cur_h = wh;
                    }
                }
            }

            if has_group && !cur_text.is_empty() && cur_w > 0 && cur_h > 0 {
                marks.push(OcrMark {
                    text: cur_text,
                    center_x: cur_x + cur_w / 2,
                    center_y: cur_y + cur_h / 2,
                    bbox: [cur_x, cur_y, cur_w, cur_h],
                });
            }
        }

        Ok(marks)
    })();

    match result {
        Ok(marks) => Ok(marks),
        Err(e) => {
            debug!("WinRT OCR error during recognition: {e}");
            Ok(Vec::new())
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_crop_bgra_none_roi() {
        let data = vec![255u8; 16]; // 2x2 BGRA
        assert!(crop_bgra(&data, 2, 2, None).is_none());
    }

    #[test]
    fn test_crop_bgra_full_image_roi_returns_none() {
        let data = vec![255u8; 16];
        assert!(crop_bgra(&data, 2, 2, Some([0, 0, 2, 2])).is_none());
    }

    #[test]
    fn test_crop_bgra_subregion() {
        // 4x4 image
        let mut data = vec![0u8; 4 * 4 * 4];
        // Set pixel at (1, 1) to red [0, 0, 255, 255]
        let idx = (1 * 4 + 1) * 4;
        data[idx] = 0;
        data[idx + 1] = 0;
        data[idx + 2] = 255;
        data[idx + 3] = 255;

        // Crop 2x2 region from (1, 1)
        let cropped = crop_bgra(&data, 4, 4, Some([1, 1, 2, 2]));
        assert!(cropped.is_some());
        let (buf, cx, cy, cw, ch) = cropped.unwrap();
        assert_eq!(cx, 1);
        assert_eq!(cy, 1);
        assert_eq!(cw, 2);
        assert_eq!(ch, 2);
        assert_eq!(buf.len(), 2 * 2 * 4);
        // The first pixel of cropped buffer is (1, 1) which was red
        assert_eq!(&buf[0..4], &[0, 0, 255, 255]);
    }

    #[test]
    fn test_crop_bgra_out_of_bounds_clamps() {
        let data = vec![0u8; 4 * 4 * 4];
        let cropped = crop_bgra(&data, 4, 4, Some([3, 3, 10, 10]));
        assert!(cropped.is_some());
        let (_, cx, cy, cw, ch) = cropped.unwrap();
        assert_eq!(cx, 3);
        assert_eq!(cy, 3);
        assert_eq!(cw, 1);
        assert_eq!(ch, 1);
    }

    #[test]
    fn test_run_ocr_bgra_empty() {
        let marks = run_ocr_bgra(&[], 0, 0, None).unwrap();
        assert!(marks.is_empty());
    }

    #[test]
    fn test_ocr_mark_serde() {
        let mark = OcrMark {
            text: "Hello World".to_string(),
            center_x: 100,
            center_y: 200,
            bbox: [50, 180, 100, 40],
        };
        let json = serde_json::to_string(&mark).unwrap();
        let parsed: OcrMark = serde_json::from_str(&json).unwrap();
        assert_eq!(mark, parsed);
    }
}
