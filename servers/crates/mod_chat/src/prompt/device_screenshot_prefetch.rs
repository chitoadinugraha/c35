//! Prefetch a desktop JPEG when a single device is in prompt scope so hop 1 has vision
//! without a model `device.screenshot` tool round.

use base64::Engine;
use c35_mod_device::{agent_cluster_online, remote_device_screenshot_capture};
use serde_json::{json, Value};
use sqlx::PgPool;

use crate::mention_context::{device_iid_resolve, MentionContext};
use crate::tools::ToolDef;

#[derive(Debug, Clone)]
pub struct DeviceScreenshotPrefetch {
    pub device_iid: i64,
    pub image_base64: String,
    pub width: u32,
    pub height: u32,
    pub jpeg_bytes: Vec<u8>,
    pub axtree_text: String,
}

pub fn prefetch_device_iid(
    mention: &MentionContext,
    mention_ids: &[String],
    bound_device_iid: i64,
) -> Option<i64> {
    match device_iid_resolve(mention, mention_ids, bound_device_iid) {
        Ok(iid) if iid > 0 => Some(iid),
        _ => None,
    }
}

pub fn device_screenshot_prefetch_wanted(
    _run_kind: &str,
    tools: &[ToolDef],
    tool_exclude: &[String],
) -> bool {
    if tool_exclude.iter().any(|x| x == "device.screenshot") {
        return false;
    }
    tools.iter().any(|t| t.name == "device.screenshot")
}

pub async fn device_screenshot_prefetch_capture(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    owner_iid: i64,
    device_iid: i64,
) -> Option<DeviceScreenshotPrefetch> {
    const MAX_WIDTH: u32 = 1280;
    const QUALITY: u32 = 72;
    const ONLINE_TIMEOUT: std::time::Duration = std::time::Duration::from_millis(1500);
    const PREFETCH_TIMEOUT: std::time::Duration = std::time::Duration::from_millis(4000);

    // Presence guard: verify device is online in the cluster cache before issuing NATS screenshot request
    match tokio::time::timeout(ONLINE_TIMEOUT, agent_cluster_online(pool, nats, device_iid)).await {
        Ok(Ok(true)) => {}
        Ok(Ok(false)) => {
            tracing::info!(
                "[c35:device_prefetch] skipping prefetch: device_iid={device_iid} is offline"
            );
            return None;
        }
        Ok(Err(e)) => {
            tracing::warn!(
                "[c35:device_prefetch] skipping prefetch: device_iid={device_iid} presence check failed: {e}"
            );
            return None;
        }
        Err(_) => {
            tracing::warn!(
                "[c35:device_prefetch] presence check timed out after {}ms for device_iid={device_iid}",
                ONLINE_TIMEOUT.as_millis()
            );
            return None;
        }
    }

    let capture_fut = remote_device_screenshot_capture(
        pool,
        nats,
        owner_iid,
        device_iid,
        MAX_WIDTH,
        QUALITY,
        None,
        true, // som = true so the prefetch captures visual Set-of-Mark tags and populates axtree_text
    );

    let res = match tokio::time::timeout(PREFETCH_TIMEOUT, capture_fut).await {
        Ok(Ok(r)) if r.ok && !r.jpeg_bytes.is_empty() => r,
        Ok(Ok(r)) => {
            tracing::warn!(
                "[c35:device_prefetch] capture not ok device_iid={device_iid}: {}",
                r.error
            );
            return None;
        }
        Ok(Err(e)) => {
            tracing::warn!(
                "[c35:device_prefetch] capture failed device_iid={device_iid}: {e}"
            );
            return None;
        }
        Err(_) => {
            tracing::warn!(
                "[c35:device_prefetch] capture timed out after {}ms for device_iid={device_iid}",
                PREFETCH_TIMEOUT.as_millis()
            );
            return None;
        }
    };
    let b64 = base64::engine::general_purpose::STANDARD.encode(&res.jpeg_bytes);
    Some(DeviceScreenshotPrefetch {
        device_iid,
        image_base64: b64,
        width: res.width,
        height: res.height,
        jpeg_bytes: res.jpeg_bytes,
        axtree_text: res.axtree_text,
    })
}

/// Attach prefetched JPEG to the current user turn (same message as the prompt text).
/// No steering to call `device.screenshot` — vision only.
/// If `prefetch.axtree_text` is non-empty, appends it as structured interactive control/screen text.
pub fn device_screenshot_prefetch_attach_user_turn(
    contents: &mut Vec<Value>,
    prefetch: &DeviceScreenshotPrefetch,
) {
    let last = contents.last_mut().filter(|m| {
        m.get("role").and_then(|r| r.as_str()) == Some("user")
    });
    let Some(last) = last else {
        return;
    };
    let parts = last
        .get_mut("parts")
        .and_then(|p| p.as_array_mut());
    let Some(parts) = parts else {
        return;
    };
    parts.push(json!({
        "inlineData": {
            "mimeType": "image/jpeg",
            "data": prefetch.image_base64
        }
    }));
    if !prefetch.axtree_text.trim().is_empty() {
        parts.push(json!({
            "text": format!("[CURRENT SCREEN OBSERVATION]\n{}", prefetch.axtree_text.trim())
        }));
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::mention_context::MentionContext;

    #[test]
    fn wanted_allows_computer_use_and_main() {
        let tools = vec![ToolDef::new(
            "device.screenshot".into(),
            String::new(),
            json!({}),
        )];
        assert!(device_screenshot_prefetch_wanted("computer_use", &tools, &[]));
        assert!(device_screenshot_prefetch_wanted("main", &tools, &[]));
        assert!(!device_screenshot_prefetch_wanted(
            "computer_use",
            &tools,
            &["device.screenshot".into()]
        ));
    }

    #[test]
    fn resolve_single_device_from_mention_ctx() {
        let mention = MentionContext {
            devices: vec![42],
            ..MentionContext::default()
        };
        assert_eq!(prefetch_device_iid(&mention, &[], 0), Some(42));
    }

    #[test]
    fn attach_extends_last_user_message() {
        let mut contents = vec![json!({ "role": "user", "parts": [{ "text": "hi" }] })];
        let prefetch = DeviceScreenshotPrefetch {
            device_iid: 1,
            image_base64: "abc".into(),
            width: 100,
            height: 50,
            jpeg_bytes: vec![1, 2],
            axtree_text: String::new(),
        };
        device_screenshot_prefetch_attach_user_turn(&mut contents, &prefetch);
        assert_eq!(contents.len(), 1);
        let parts = contents[0]["parts"].as_array().unwrap();
        assert_eq!(parts.len(), 2);
        assert_eq!(parts[1]["inlineData"]["data"], "abc");
    }

    #[test]
    fn attach_appends_axtree_text_when_non_empty() {
        let mut contents = vec![json!({ "role": "user", "parts": [{ "text": "open app" }] })];
        let prefetch = DeviceScreenshotPrefetch {
            device_iid: 1,
            image_base64: "xyz".into(),
            width: 1920,
            height: 1080,
            jpeg_bytes: vec![1, 2],
            axtree_text: "Interactive UI elements:\n@1 Button 'OK'".into(),
        };
        device_screenshot_prefetch_attach_user_turn(&mut contents, &prefetch);
        assert_eq!(contents.len(), 1);
        let parts = contents[0]["parts"].as_array().unwrap();
        assert_eq!(parts.len(), 3);
        assert_eq!(parts[1]["inlineData"]["data"], "xyz");
        assert_eq!(
            parts[2]["text"],
            "[CURRENT SCREEN OBSERVATION]\nInteractive UI elements:\n@1 Button 'OK'"
        );
    }
}