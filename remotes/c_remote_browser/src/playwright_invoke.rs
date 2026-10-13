//! Playwright engine RPC — registered into `c_remote_browser_core::playwright`.

use std::sync::Arc;

use base64::Engine as _;
use c_remote_browser_core::browser_screenshot;
use c_remote_browser_core::browser_state;
use c_remote_browser_core::extension_agent;
use c_remote_browser_core::mode;
use c_remote_browser_core::playwright;
use serde_json::{json, Value};

use crate::browser_download;
use crate::engine::ipc::EngineBridge;
use crate::engine::process;

pub fn register() {
    playwright::register_playwright_handlers(
        Arc::new(|method, params| Box::pin(async move { invoke_method(&method, params).await })),
        Arc::new(|body| Box::pin(async move { invoke_tab_ws(body).await })),
    );
    playwright::register_playwright_idle(
        Arc::new(|active| {
            Box::pin(async move {
                let st = browser_state::global();
                let st = match st {
                    Some(s) => s,
                    None => return,
                };
                let headless = mode::headless_from_config();
                let bridge = match process::ensure_engine(&st, headless, "default").await {
                    Ok(b) => b,
                    Err(_) => return,
                };
                let method = if active { "screencast.start" } else { "screencast.stop" };
                let _ = bridge.call(method, json!({})).await;
            })
        }),
        Arc::new(|payload| {
            Box::pin(async move {
                let st = browser_state::global();
                let st = match st {
                    Some(s) => s,
                    None => return,
                };
                let headless = mode::headless_from_config();
                let bridge = match process::ensure_engine(&st, headless, "default").await {
                    Ok(b) => b,
                    Err(_) => return,
                };
                let _ = bridge.call("input", payload).await;
            })
        }),
    );
    extension_agent::register_embedded_agent_runner(|| crate::run_agent_blocking());
}

async fn invoke_tab_ws(body: Value) -> anyhow::Result<Value> {
    let st = browser_state::global().ok_or_else(|| anyhow::anyhow!("browser state not init"))?;
    let headless = mode::headless_from_config();
    let slot_id = body
        .get("slot_id")
        .and_then(|v| v.as_str())
        .unwrap_or("default");
    let bridge = process::ensure_engine(&st, headless, slot_id).await?;
    tab_command(&bridge, &body).await
}

pub async fn tab_command(bridge: &EngineBridge, body: &Value) -> anyhow::Result<Value> {
    let op = body.get("op").and_then(|v| v.as_str()).unwrap_or("");
    match op {
        "list" => bridge.call("tab.list", json!({})).await,
        "activate" => {
            let tab_id = tab_id_field(body)?;
            bridge
                .call("tab.activate", json!({ "tabId": tab_id }))
                .await?;
            Ok(json!({ "ok": true, "tab_id": tab_id }))
        }
        "new" => {
            let url = body.get("url").and_then(|v| v.as_str());
            let mut params = json!({});
            if let Some(u) = url {
                params["url"] = json!(u);
            }
            bridge.call("tab.new", params).await
        }
        "close" => {
            let tab_id = tab_id_field(body)?;
            bridge
                .call("tab.close", json!({ "tabId": tab_id }))
                .await?;
            Ok(json!({ "ok": true, "tab_id": tab_id }))
        }
        _ => anyhow::bail!("unknown browser.tab op: {op}"),
    }
}

fn tab_id_field(body: &Value) -> anyhow::Result<&str> {
    body.get("tab_id")
        .or_else(|| body.get("tabId"))
        .and_then(|v| v.as_str())
        .ok_or_else(|| anyhow::anyhow!("tab_id required"))
}

async fn invoke_method(method: &str, params: Value) -> anyhow::Result<Value> {
    if method == "task.run" {
        let st =
            browser_state::global().ok_or_else(|| anyhow::anyhow!("browser state not init"))?;
        let headless = mode::headless_from_config();
        let slot_id = params
            .get("slot_id")
            .and_then(|v| v.as_str())
            .unwrap_or("default");
        let bridge = process::ensure_engine(&st, headless, slot_id).await?;
        return bridge.call("task.run", params).await;
    }

    let st = browser_state::global().ok_or_else(|| anyhow::anyhow!("browser state not init"))?;
    let headless = mode::headless_from_config();
    let slot_id = params
        .get("slot_id")
        .and_then(|v| v.as_str())
        .unwrap_or("default");
    let bridge = process::ensure_engine(&st, headless, slot_id).await?;

    match method {
        "tabs" => tab_command(&bridge, &params).await,
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
        "page.screenshot" => {
            let quality = params
                .get("quality")
                .and_then(|v| v.as_i64())
                .unwrap_or(80)
                .clamp(40, 95);
            let mut ipc = json!({ "quality": quality });
            if let Some(tab_id) = params.get("tab_id").and_then(|v| v.as_str()) {
                ipc["tab_id"] = json!(tab_id);
            }
            let mut screenshot = bridge.call("page.screenshot", ipc).await?;
            let coords = browser_screenshot::marker_coords(&params);
            browser_screenshot::apply_marker_to_screenshot_json(
                &mut screenshot,
                quality as u8,
                coords,
            );
            Ok(json!({ "ok": true, "screenshot": screenshot }))
        }
        "captcha.apply" => {
            let kind = params
                .get("kind")
                .and_then(|v| v.as_str())
                .ok_or_else(|| anyhow::anyhow!("kind required"))?;
            let token = params
                .get("token")
                .and_then(|v| v.as_str())
                .ok_or_else(|| anyhow::anyhow!("token required"))?;
            let mut ipc = json!({ "kind": kind, "token": token });
            if let Some(tab_id) = params.get("tab_id").and_then(|v| v.as_str()) {
                ipc["tab_id"] = json!(tab_id);
            }
            bridge.call("captcha.apply", ipc).await
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
            browser_download::ipc_file_upload(&bridge, tab_id, selector, file_name, &bytes).await?;
            Ok(json!({ "ok": true }))
        }
        other => anyhow::bail!("unknown browser method: {other}"),
    }
}
