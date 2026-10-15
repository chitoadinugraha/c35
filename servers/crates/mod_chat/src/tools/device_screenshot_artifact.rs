use anyhow::{Context, Result};
use base64::Engine;
use c35_mod_file::{cas_dir_default, cas_put, tool_artifact_insert};
use serde_json::{json, Value};
use sqlx::PgPool;

use super::context::ToolContext;

pub(crate) fn cas_secret_from_env() -> String {
    ["CAS_HMAC_SECRET", "C35_JWT_SECRET", "AGENT_SECRET_KEY"]
        .into_iter()
        .find_map(|k| std::env::var(k).ok())
        .unwrap_or_default()
}

pub async fn device_screenshot_artifact_put(
    pool: &PgPool,
    owner_iid: i64,
    req_id: &str,
    tool_call_id: &str,
    tool_id: &str,
    device_iid: i64,
    jpeg: &[u8],
    width: u32,
    height: u32,
    som: bool,
    marker: bool,
    axtree_chars: usize,
) -> Result<(String, String)> {
    let secret = cas_secret_from_env();
    let put = cas_put(pool, &cas_dir_default(), &secret, jpeg, "image/jpeg")
        .await
        .context("cas_put device screenshot")?;
    let meta_json = json!({
        "som": som,
        "marker": marker,
        "axtree_chars": axtree_chars,
    });
    tool_artifact_insert(
        pool,
        owner_iid,
        req_id,
        tool_call_id,
        tool_id,
        device_iid,
        &put.hash,
        width as i32,
        height as i32,
        &meta_json,
    )
    .await
    .context("insert ai.tool_artifact")?;
    Ok((put.hash, put.url))
}

pub async fn device_screenshot_attach_artifact(
    ctx: &ToolContext,
    tool_id: &str,
    device_iid: i64,
    jpeg: &[u8],
    width: u32,
    height: u32,
    som: bool,
    marker: bool,
    axtree_chars: usize,
    out: &mut Value,
) {
    if ctx.req_id.trim().is_empty() || jpeg.is_empty() {
        return;
    }
    match device_screenshot_artifact_put(
        &ctx.pool,
        ctx.owner_iid,
        &ctx.req_id,
        &ctx.tool_call_id,
        tool_id,
        device_iid,
        jpeg,
        width,
        height,
        som,
        marker,
        axtree_chars,
    )
    .await
    {
        Ok((hash, url)) => {
            out["image_hash"] = json!(hash);
            out["image_url"] = json!(url);
            out["som"] = json!(som);
            out["marker"] = json!(marker);
        }
        Err(e) => tracing::warn!(error = %e, tool_id, "device screenshot artifact persist failed"),
    }
}

pub fn tool_result_preview_trim(result: &Value) -> Value {
    let mut v = result.clone();
    strip_image_base64(&mut v);
    v
}

fn strip_image_base64(v: &mut Value) {
    if let Some(obj) = v.as_object_mut() {
        obj.remove("image_base64");
        if let Some(sc) = obj.get_mut("screenshot").and_then(|x| x.as_object_mut()) {
            sc.remove("jpeg_b64");
        }
        if let Some(llm) = obj.get_mut("llm").and_then(|x| x.as_object_mut()) {
            llm.remove("image_base64");
        }
    }
}

fn screenshot_dims(result: &Value) -> (i64, i64) {
    let w = result
        .get("width")
        .and_then(|v| v.as_i64())
        .or_else(|| result.pointer("/screenshot/width").and_then(|v| v.as_i64()))
        .unwrap_or(0);
    let h = result
        .get("height")
        .and_then(|v| v.as_i64())
        .or_else(|| {
            result
                .pointer("/screenshot/height")
                .and_then(|v| v.as_i64())
        })
        .unwrap_or(0);
    (w, h)
}

pub fn screenshot_meta_value(
    hash: &str,
    url: &str,
    width: u32,
    height: u32,
    som: bool,
    marker: bool,
) -> Value {
    json!({
        "hash": hash,
        "url": url,
        "width": width,
        "height": height,
        "som": som,
        "marker": marker,
    })
}

/// Persist JPEG bytes fed to the LLM (CAS file, not base64 in logs).
pub async fn llm_vision_jpeg_persist(
    pool: &PgPool,
    owner_iid: i64,
    req_id: &str,
    tool_call_id: &str,
    device_iid: i64,
    jpeg: &[u8],
    width: u32,
    height: u32,
    som: bool,
    marker: bool,
) -> Result<Value> {
    let (hash, url) = device_screenshot_artifact_put(
        pool,
        owner_iid,
        req_id,
        tool_call_id,
        "llm.vision",
        device_iid,
        jpeg,
        width,
        height,
        som,
        marker,
        0,
    )
    .await?;
    Ok(screenshot_meta_value(&hash, &url, width, height, som, marker))
}

/// Ensure a vision frame sent to the model has a CAS file for trace/debug.
pub async fn llm_vision_ensure_stored(
    pool: &PgPool,
    owner_iid: i64,
    req_id: &str,
    tool_call_id: &str,
    tool_result: &Value,
    jpeg_b64: &str,
) -> Option<Value> {
    if let Some(meta) = tool_screenshot_meta_from_result(tool_result) {
        return Some(meta);
    }
    let b64 = jpeg_b64.trim();
    if b64.is_empty() || req_id.trim().is_empty() {
        return None;
    }
    let bytes = match base64::engine::general_purpose::STANDARD.decode(b64) {
        Ok(b) => b,
        Err(e) => {
            tracing::warn!(error = %e, "llm_vision_ensure_stored base64 decode failed");
            return None;
        }
    };
    if bytes.is_empty() {
        return None;
    }
    let (width, height) = screenshot_dims(tool_result);
    let w = width.max(0) as u32;
    let h = height.max(0) as u32;
    let som = tool_result.get("som").and_then(|v| v.as_bool()).unwrap_or(false);
    let marker = tool_result
        .get("marker")
        .and_then(|v| v.as_bool())
        .unwrap_or(false);
    let device_iid = tool_result
        .get("device_iid")
        .and_then(|v| v.as_i64())
        .unwrap_or(0);
    match llm_vision_jpeg_persist(
        pool,
        owner_iid,
        req_id,
        tool_call_id,
        device_iid,
        &bytes,
        w,
        h,
        som,
        marker,
    )
    .await
    {
        Ok(meta) => Some(meta),
        Err(e) => {
            tracing::warn!(error = %e, "llm_vision_ensure_stored persist failed");
            None
        }
    }
}

pub fn tool_screenshot_meta_from_result(result: &Value) -> Option<Value> {
    let hash = result
        .get("image_hash")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    if hash.is_empty() {
        return None;
    }
    let url = result
        .get("image_url")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let (width, height) = screenshot_dims(result);
    let som = result.get("som").and_then(|v| v.as_bool()).unwrap_or(false);
    let marker = result
        .get("marker")
        .and_then(|v| v.as_bool())
        .unwrap_or(false);
    Some(screenshot_meta_value(
        hash,
        url,
        width.max(0) as u32,
        height.max(0) as u32,
        som,
        marker,
    ))
}

pub fn tool_screenshot_log_text(tool_id: &str, result: &Value) -> String {
    let (width, height) = screenshot_dims(result);
    let hash = result
        .get("image_hash")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let hash_short = if hash.len() > 12 {
        format!("{}…", &hash[..12])
    } else {
        hash.to_string()
    };
    if hash_short.is_empty() {
        format!("{tool_id} {width}x{height}")
    } else {
        format!("{tool_id} {width}x{height} hash={hash_short}")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn preview_trim_strips_base64() {
        let v = json!({
            "ok": true,
            "image_base64": "aGVsbG8=",
            "image_hash": "abc",
            "width": 10,
            "height": 20,
        });
        let slim = tool_result_preview_trim(&v);
        assert!(slim.get("image_base64").is_none());
        assert_eq!(slim["image_hash"], "abc");
    }

    #[test]
    fn llm_vision_ensure_stored_uses_existing_hash_without_decode() {
        let v = json!({
            "image_hash": "deadbeef",
            "image_url": "https://example/cas",
            "width": 1024,
            "height": 708,
            "som": true,
            "marker": false,
        });
        // sync helper: meta path only
        let m = tool_screenshot_meta_from_result(&v).expect("meta");
        assert_eq!(m["som"], true);
        assert_eq!(m["width"], 1024);
    }

    #[test]
    fn screenshot_meta_from_result_fields() {
        let v = json!({
            "image_hash": "deadbeef",
            "image_url": "https://example/cas",
            "width": 1280,
            "height": 720,
            "som": true,
            "marker": false,
        });
        let m = tool_screenshot_meta_from_result(&v).expect("meta");
        assert_eq!(m["hash"], "deadbeef");
        assert_eq!(m["width"], 1280);
        assert_eq!(m["som"], true);
    }

    #[test]
    fn log_text_includes_hash_prefix() {
        let v = json!({
            "image_hash": "0123456789abcdef",
            "width": 100,
            "height": 50,
        });
        let t = tool_screenshot_log_text("device.screenshot", &v);
        assert!(t.contains("100x50"));
        assert!(t.contains("hash=0123456789ab"));
    }
}
