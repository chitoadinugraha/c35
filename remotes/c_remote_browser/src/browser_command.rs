use std::sync::Arc;

use base64::Engine as _;
use c_remote_core::c35_proto::ResRemoteCommand;
use serde_json::{json, Value};
use tracing::warn;

use crate::engine::process;
use crate::mode;

const PREFIX: &str = "__c35_browser__:";

fn cmd_ok(stdout: Value) -> ResRemoteCommand {
    ResRemoteCommand {
        ok: true,
        error: String::new(),
        exit_code: 0,
        stdout: stdout.to_string(),
        stderr: String::new(),
    }
}

fn cmd_err(msg: impl Into<String>) -> ResRemoteCommand {
    let msg = msg.into();
    ResRemoteCommand {
        ok: false,
        error: msg.clone(),
        exit_code: 1,
        stdout: String::new(),
        stderr: msg,
    }
}

async fn invoke_method(method: &str, params: Value) -> anyhow::Result<Value> {
    let st = crate::browser_state::global().ok_or_else(|| anyhow::anyhow!("browser state not init"))?;
    let headless = mode::headless_from_config();
    let slot_id = params
        .get("slot_id")
        .and_then(|v| v.as_str())
        .unwrap_or("default");
    let bridge = process::ensure_engine(&st, headless, slot_id).await?;

    match method {
        "tabs" => crate::browser_tabs::tab_command(&bridge, &params).await,
        "navigate" => {
            let url = params
                .get("url")
                .and_then(|v| v.as_str())
                .ok_or_else(|| anyhow::anyhow!("url required"))?;
            bridge.call("navigate", json!({ "url": url })).await?;
            Ok(json!({ "ok": true }))
        }
        "reload" => {
            bridge.call("reload", json!({})).await?;
            Ok(json!({ "ok": true }))
        }
        "history.back" => {
            bridge.call("history.back", json!({})).await?;
            Ok(json!({ "ok": true }))
        }
        "history.forward" => {
            bridge.call("history.forward", json!({})).await?;
            Ok(json!({ "ok": true }))
        }
        "page.extract" => {
            let selector = params
                .get("selector")
                .and_then(|v| v.as_str())
                .ok_or_else(|| anyhow::anyhow!("selector required"))?;
            let mut step = json!({ "op": "extract", "selector": selector });
            if let Some(as_key) = params.get("as").and_then(|v| v.as_str()) {
                step["as"] = json!(as_key);
            }
            if let Some(tab_id) = params.get("tab_id").and_then(|v| v.as_str()) {
                step["tab_id"] = json!(tab_id);
            }
            let mut run = json!({ "slot_id": slot_id, "steps": [step] });
            if let Some(tab_id) = params.get("tab_id").and_then(|v| v.as_str()) {
                run["tab_id"] = json!(tab_id);
            }
            let result = bridge.call("task.run", run).await?;
            Ok(json!({ "ok": true, "result": result }))
        }
        "page.act" => {
            let action = params
                .get("action")
                .and_then(|v| v.as_str())
                .ok_or_else(|| anyhow::anyhow!("action required"))?;
            let step = match action {
                "click" => {
                    let selector = params
                        .get("selector")
                        .and_then(|v| v.as_str())
                        .ok_or_else(|| anyhow::anyhow!("selector required for click"))?;
                    json!({ "op": "click", "selector": selector })
                }
                "fill" => {
                    let selector = params
                        .get("selector")
                        .and_then(|v| v.as_str())
                        .ok_or_else(|| anyhow::anyhow!("selector required for fill"))?;
                    let text = params
                        .get("text")
                        .and_then(|v| v.as_str())
                        .ok_or_else(|| anyhow::anyhow!("text required for fill"))?;
                    json!({ "op": "fill", "selector": selector, "text": text })
                }
                "press" => {
                    let selector = params
                        .get("selector")
                        .and_then(|v| v.as_str())
                        .ok_or_else(|| anyhow::anyhow!("selector required for press"))?;
                    let text = params.get("text").and_then(|v| v.as_str()).unwrap_or("");
                    json!({ "op": "fill", "selector": selector, "text": text })
                }
                other => anyhow::bail!("unknown page.act action: {other}"),
            };
            let mut patched = step;
            if let Some(tab_id) = params.get("tab_id").and_then(|v| v.as_str()) {
                patched["tab_id"] = json!(tab_id);
            }
            let mut run = json!({ "slot_id": slot_id, "steps": [patched] });
            if let Some(tab_id) = params.get("tab_id").and_then(|v| v.as_str()) {
                run["tab_id"] = json!(tab_id);
            }
            let result = bridge.call("task.run", run).await?;
            Ok(json!({ "ok": true, "result": result }))
        }
        "page.observe" => {
            let max_chars = params
                .get("max_chars")
                .and_then(|v| v.as_i64())
                .unwrap_or(8000)
                .clamp(500, 50_000);
            let mut ipc = json!({ "max_chars": max_chars });
            if let Some(tab_id) = params.get("tab_id").and_then(|v| v.as_str()) {
                ipc["tab_id"] = json!(tab_id);
            }
            let observe = bridge.call("page.observe", ipc).await?;
            Ok(json!({ "ok": true, "observe": observe }))
        }
        "file.upload" => {
            let selector = params
                .get("selector")
                .and_then(|v| v.as_str())
                .ok_or_else(|| anyhow::anyhow!("selector required"))?;
            let file_name = params
                .get("file_name")
                .and_then(|v| v.as_str())
                .unwrap_or("upload.bin");
            let b64 = params
                .get("bytes_b64")
                .and_then(|v| v.as_str())
                .ok_or_else(|| anyhow::anyhow!("bytes_b64 required"))?;
            let bytes = base64::engine::general_purpose::STANDARD
                .decode(b64)
                .map_err(|e| anyhow::anyhow!("invalid bytes_b64: {e}"))?;
            let tab_id = params.get("tab_id").and_then(|v| v.as_str());
            crate::browser_download::ipc_file_upload(&bridge, tab_id, selector, file_name, &bytes)
                .await?;
            Ok(json!({ "ok": true }))
        }
        other => anyhow::bail!("unknown browser method: {other}"),
    }
}

pub fn register_command_handler() {
    c_remote_core::webrtc::set_command_handler(Arc::new(|raw, _timeout_sec| {
        Box::pin(async move {
            if !raw.starts_with(PREFIX) {
                return None;
            }
            let payload = raw[PREFIX.len()..].trim();
            let body: Value = match serde_json::from_str(payload) {
                Ok(v) => v,
                Err(e) => return Some(cmd_err(format!("invalid browser json: {e}"))),
            };
            let method = body
                .get("method")
                .and_then(|v| v.as_str())
                .unwrap_or("");
            let params = body.get("params").cloned().unwrap_or(Value::Null);
            match invoke_method(method, params).await {
                Ok(v) => Some(cmd_ok(v)),
                Err(e) => {
                    warn!("browser command {method}: {e}");
                    Some(cmd_err(e.to_string()))
                }
            }
        })
    }));
}
