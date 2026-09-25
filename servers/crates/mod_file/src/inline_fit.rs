use image::{DynamicImage, ExtendedColorType, GenericImageView, ImageEncoder};

use crate::CAS_INLINE_MAX_BYTES;

pub fn cas_image_bytes_fit_inline(body: Vec<u8>, mime: &str) -> Result<(Vec<u8>, String), String> {
    let limit = CAS_INLINE_MAX_BYTES as usize;
    if body.len() < limit {
        return Ok((body, mime.to_string()));
    }
    let img = image::load_from_memory(&body).map_err(|e| e.to_string())?;
    for max_px in [2048u32, 1536, 1280, 1024, 768, 512] {
        for quality in [88u8, 82, 75, 68, 60, 52] {
            let resized = resize_max(&img, max_px);
            let encoded = encode_jpeg(&resized, quality)?;
            if encoded.len() < limit {
                return Ok((encoded, "image/jpeg".into()));
            }
        }
    }
    Err(format!(
        "generated image too large to store inline ({} bytes after compression attempts)",
        body.len()
    ))
}

fn resize_max(img: &DynamicImage, max_px: u32) -> DynamicImage {
    let (w, h) = img.dimensions();
    if w <= max_px && h <= max_px {
        return img.clone();
    }
    let scale = (max_px as f32 / w as f32).min(max_px as f32 / h as f32);
    let nw = ((w as f32) * scale).round().max(1.0) as u32;
    let nh = ((h as f32) * scale).round().max(1.0) as u32;
    img.resize(nw, nh, image::imageops::FilterType::Lanczos3)
}

fn encode_jpeg(img: &DynamicImage, quality: u8) -> Result<Vec<u8>, String> {
    let rgb = img.to_rgb8();
    let mut buf = Vec::new();
    let enc = image::codecs::jpeg::JpegEncoder::new_with_quality(&mut buf, quality);
    enc.write_image(
        rgb.as_raw(),
        rgb.width(),
        rgb.height(),
        ExtendedColorType::Rgb8,
    )
    .map_err(|e| e.to_string())?;
    Ok(buf)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fit_skips_small_body() {
        let body = vec![1u8, 2, 3];
        let (out, mime) = cas_image_bytes_fit_inline(body.clone(), "image/png").unwrap();
        assert_eq!(out, body);
        assert_eq!(mime, "image/png");
    }
}
