use std::path::Path;

use image::imageops::FilterType;
use image::{DynamicImage, ExtendedColorType, GenericImageView, ImageEncoder};
use sqlx::Row;

use crate::{cas_put, file_variant_set};

const THUMB_MAX_PX: u32 = 320;
const SMALL_MAX_PX: u32 = 1280;
const JPEG_QUALITY: u8 = 82;

pub fn spawn_image_optimize(
    pool: sqlx::PgPool,
    cas_dir: std::path::PathBuf,
    secret: String,
    canonical_hash: String,
    mime_type: String,
) {
    if !mime_type.starts_with("image/") {
        return;
    }
    tokio::spawn(async move {
        if let Err(e) = image_optimize_run(&pool, &cas_dir, &secret, &canonical_hash, &mime_type)
            .await
        {
            tracing::warn!("image optimize {canonical_hash}: {e}");
        }
    });
}

async fn image_optimize_run(
    pool: &sqlx::PgPool,
    cas_dir: &Path,
    secret: &str,
    canonical_hash: &str,
    _mime_type: &str,
) -> Result<(), String> {
    let row = sqlx::query(
        "SELECT variants FROM ai.file_blob_meta WHERE hash_blake3 = $1",
    )
    .bind(canonical_hash)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    let variants = row
        .map(|r| r.get::<serde_json::Value, _>("variants"))
        .unwrap_or(serde_json::json!({}));
    if variants.get("thumb").is_some() && variants.get("small").is_some() {
        return Ok(());
    }

    let (bytes, _) = crate::cas_bytes_get(pool, cas_dir, canonical_hash)
        .await
        .map_err(|e| e.to_string())?;
    let img = image::load_from_memory(&bytes).map_err(|e| e.to_string())?;

    if variants.get("thumb").is_none() {
        let thumb = resize_max(&img, THUMB_MAX_PX);
        let encoded = encode_webp(&thumb)?;
        let put = cas_put(pool, cas_dir, secret, &encoded, "image/webp")
            .await
            .map_err(|e| e.to_string())?;
        file_variant_set(pool, canonical_hash, "thumb", &put.hash)
            .await
            .map_err(|e| e.to_string())?;
    }

    if variants.get("small").is_none() {
        let small = resize_max(&img, SMALL_MAX_PX);
        let encoded = encode_jpeg(&small)?;
        let put = cas_put(pool, cas_dir, secret, &encoded, "image/jpeg")
            .await
            .map_err(|e| e.to_string())?;
        file_variant_set(pool, canonical_hash, "small", &put.hash)
            .await
            .map_err(|e| e.to_string())?;
    }

    Ok(())
}

fn resize_max(img: &DynamicImage, max_px: u32) -> DynamicImage {
    let (w, h) = img.dimensions();
    if w <= max_px && h <= max_px {
        return img.clone();
    }
    let scale = (max_px as f32 / w as f32).min(max_px as f32 / h as f32);
    let nw = ((w as f32) * scale).round().max(1.0) as u32;
    let nh = ((h as f32) * scale).round().max(1.0) as u32;
    img.resize(nw, nh, FilterType::Lanczos3)
}

fn encode_webp(img: &DynamicImage) -> Result<Vec<u8>, String> {
    let rgba = img.to_rgba8();
    let encoder = webp::Encoder::from_rgba(&rgba, rgba.width(), rgba.height());
    Ok(encoder.encode(80.0).to_vec())
}

fn encode_jpeg(img: &DynamicImage) -> Result<Vec<u8>, String> {
    let rgb = img.to_rgb8();
    let mut buf = Vec::new();
    let enc = image::codecs::jpeg::JpegEncoder::new_with_quality(&mut buf, JPEG_QUALITY);
    enc.write_image(
        rgb.as_raw(),
        rgb.width(),
        rgb.height(),
        ExtendedColorType::Rgb8,
    )
    .map_err(|e| e.to_string())?;
    Ok(buf)
}
