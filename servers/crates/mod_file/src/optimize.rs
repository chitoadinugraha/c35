use std::collections::HashSet;
use std::path::Path;
use std::sync::{Arc, OnceLock};
use std::time::Duration;

use image::imageops::FilterType;
use image::{DynamicImage, ExtendedColorType, GenericImageView, ImageEncoder};
use sqlx::Row;
use tokio::sync::{Mutex, Semaphore};

use crate::{cas_put_opts, file_variant_set, CasPutOptions};

const THUMB_MAX_PX: u32 = 320;
const SMALL_MAX_PX: u32 = 1280;
const JPEG_QUALITY: u8 = 82;

pub const IMAGE_OPTIMIZE_MAX_CONCURRENT_DEFAULT: usize = 3;

static IMAGE_OPTIMIZE_SEM: OnceLock<Arc<Semaphore>> = OnceLock::new();
static IMAGE_OPTIMIZE_INFLIGHT: OnceLock<Mutex<HashSet<String>>> = OnceLock::new();

pub fn image_optimize_max_concurrent() -> usize {
    std::env::var("IMAGE_OPTIMIZE_MAX_CONCURRENT")
        .ok()
        .and_then(|s| s.trim().parse().ok())
        .unwrap_or(IMAGE_OPTIMIZE_MAX_CONCURRENT_DEFAULT)
        .clamp(1, 8)
}

fn image_optimize_sem() -> Arc<Semaphore> {
    IMAGE_OPTIMIZE_SEM
        .get_or_init(|| Arc::new(Semaphore::new(image_optimize_max_concurrent())))
        .clone()
}

fn image_optimize_inflight() -> &'static Mutex<HashSet<String>> {
    IMAGE_OPTIMIZE_INFLIGHT.get_or_init(|| Mutex::new(HashSet::new()))
}

fn variant_key_triggers_optimize(key: &str) -> bool {
    matches!(key, "thumb" | "small")
}

/// Build thumb/small on first `GET /fs/{canonical}?v=thumb|small` (sync, bounded wait if in flight).
pub async fn ensure_image_variants_on_read(
    pool: &sqlx::PgPool,
    cas_dir: &Path,
    secret: &str,
    canonical_hash: &str,
    variant_key: &str,
) {
    if !variant_key_triggers_optimize(variant_key) {
        return;
    }
    if crate::file_variant_get(pool, canonical_hash, variant_key)
        .await
        .ok()
        .flatten()
        .is_some()
    {
        return;
    }
    let mime = match crate::cas_meta_get(pool, canonical_hash).await {
        Ok(Some(meta)) if meta.mime_type.starts_with("image/") => meta.mime_type,
        _ => return,
    };

    let started = {
        let mut set = image_optimize_inflight().lock().await;
        set.insert(canonical_hash.to_string())
    };
    if !started {
        for _ in 0..300 {
            if crate::file_variant_get(pool, canonical_hash, variant_key)
                .await
                .ok()
                .flatten()
                .is_some()
            {
                return;
            }
            if !image_optimize_inflight()
                .lock()
                .await
                .contains(canonical_hash)
            {
                return;
            }
            tokio::time::sleep(Duration::from_millis(100)).await;
        }
        return;
    }

    let sem = image_optimize_sem();
    let run = async {
        let _permit = sem.acquire().await.map_err(|e| e.to_string())?;
        image_optimize_run(pool, cas_dir, secret, canonical_hash, &mime).await
    };
    if let Err(e) = run.await {
        tracing::warn!("image optimize on read {canonical_hash}: {e}");
    }
    image_optimize_inflight()
        .lock()
        .await
        .remove(canonical_hash);
}

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
        {
            let mut set = image_optimize_inflight().lock().await;
            if !set.insert(canonical_hash.clone()) {
                return;
            }
        }
        let sem = image_optimize_sem();
        let Ok(_permit) = sem.acquire().await else {
            image_optimize_inflight()
                .lock()
                .await
                .remove(&canonical_hash);
            return;
        };
        let run = image_optimize_run(&pool, &cas_dir, &secret, &canonical_hash, &mime_type).await;
        image_optimize_inflight()
            .lock()
            .await
            .remove(&canonical_hash);
        if let Err(e) = run {
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
    let row = sqlx::query("SELECT variants FROM ai.file_blob_meta WHERE hash_blake3 = $1")
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

    let need_thumb = variants.get("thumb").is_none();
    let need_small = variants.get("small").is_none();
    let encoded =
        tokio::task::spawn_blocking(move || image_optimize_encode(&bytes, need_thumb, need_small))
            .await
            .map_err(|e| e.to_string())??;

    if let Some(body) = encoded.thumb {
        let put = cas_put_opts(
            pool,
            cas_dir,
            secret,
            &body,
            "image/webp",
            CasPutOptions::derivative(),
        )
        .await
        .map_err(|e| e.to_string())?;
        if put.hash != canonical_hash {
            file_variant_set(pool, canonical_hash, "thumb", &put.hash)
                .await
                .map_err(|e| e.to_string())?;
        }
    }
    if let Some(body) = encoded.small {
        let put = cas_put_opts(
            pool,
            cas_dir,
            secret,
            &body,
            "image/jpeg",
            CasPutOptions::derivative(),
        )
        .await
        .map_err(|e| e.to_string())?;
        if put.hash != canonical_hash {
            file_variant_set(pool, canonical_hash, "small", &put.hash)
                .await
                .map_err(|e| e.to_string())?;
        }
    }

    Ok(())
}

struct ImageOptimizeEncoded {
    thumb: Option<Vec<u8>>,
    small: Option<Vec<u8>>,
}

fn image_optimize_encode(
    bytes: &[u8],
    need_thumb: bool,
    need_small: bool,
) -> Result<ImageOptimizeEncoded, String> {
    if !need_thumb && !need_small {
        return Ok(ImageOptimizeEncoded {
            thumb: None,
            small: None,
        });
    }
    let img = image::load_from_memory(bytes).map_err(|e| e.to_string())?;
    let thumb = if need_thumb {
        Some(encode_webp(&resize_max(&img, THUMB_MAX_PX))?)
    } else {
        None
    };
    let small = if need_small {
        Some(encode_jpeg(&resize_max(&img, SMALL_MAX_PX))?)
    } else {
        None
    };
    Ok(ImageOptimizeEncoded { thumb, small })
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn max_concurrent_clamps() {
        std::env::set_var("IMAGE_OPTIMIZE_MAX_CONCURRENT", "99");
        assert_eq!(image_optimize_max_concurrent(), 8);
        std::env::set_var("IMAGE_OPTIMIZE_MAX_CONCURRENT", "0");
        assert_eq!(image_optimize_max_concurrent(), 1);
        std::env::remove_var("IMAGE_OPTIMIZE_MAX_CONCURRENT");
    }
}
