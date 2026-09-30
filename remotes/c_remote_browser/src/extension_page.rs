use std::time::Duration;

use serde_json::{json, Value};

use crate::extension_ipc::extension_bridge_get;

const PAGE_RPC_TIMEOUT: Duration = Duration::from_secs(90);
const TASK_RPC_TIMEOUT: Duration = Duration::from_secs(120);

fn bridge() -> anyhow::Result<std::sync::Arc<crate::extension_ipc::ExtensionBridge>> {
    extension_bridge_get().ok_or_else(crate::extension_ipc::extension_ipc_not_ready_err)
}

async fn rpc_call(op: &str, params: Value) -> anyhow::Result<Value> {
    let bridge = bridge()?;
    let op_s = op.to_string();
    tokio::task::spawn_blocking(move || bridge.call(&op_s, params, PAGE_RPC_TIMEOUT))
        .await?
}

fn tab_id_in(params: &Value, ipc: &mut Value) {
    if let Some(tab_id) = params.get("tab_id").and_then(|v| v.as_str()) {
        ipc["tab_id"] = json!(tab_id);
    }
}

pub async fn extension_page_method(method: &str, params: &Value) -> anyhow::Result<Value> {
    match method {
        "navigate" => {
            let url = params
                .get("url")
                .and_then(|v| v.as_str())
                .ok_or_else(|| anyhow::anyhow!("url required"))?;
            let mut ipc = json!({ "url": url });
            tab_id_in(params, &mut ipc);
            rpc_call("navigate", ipc).await?;
            Ok(json!({ "ok": true }))
        }
        "reload" => {
            let mut ipc = json!({});
            tab_id_in(params, &mut ipc);
            rpc_call("reload", ipc).await?;
            Ok(json!({ "ok": true }))
        }
        "history.back" => {
            let mut ipc = json!({});
            tab_id_in(params, &mut ipc);
            rpc_call("history.back", ipc).await?;
            Ok(json!({ "ok": true }))
        }
        "history.forward" => {
            let mut ipc = json!({});
            tab_id_in(params, &mut ipc);
            rpc_call("history.forward", ipc).await?;
            Ok(json!({ "ok": true }))
        }
        "page.observe" => {
            let max_chars = params
                .get("max_chars")
                .and_then(|v| v.as_i64())
                .unwrap_or(8000)
                .clamp(500, 50_000);
            let mut ipc = json!({ "max_chars": max_chars });
            tab_id_in(params, &mut ipc);
            let observe = rpc_call("page.observe", ipc).await?;
            Ok(json!({ "ok": true, "observe": observe }))
        }
        "page.screenshot" => {
            let quality = params
                .get("quality")
                .and_then(|v| v.as_i64())
                .unwrap_or(80)
                .clamp(40, 95);
            let mut ipc = json!({ "quality": quality });
            tab_id_in(params, &mut ipc);
            let mut screenshot = rpc_call("page.screenshot", ipc).await?;
            let coords = crate::browser_screenshot::marker_coords(params);
            crate::browser_screenshot::apply_marker_to_screenshot_json(
                &mut screenshot,
                quality as u8,
                coords,
            );
            Ok(json!({ "ok": true, "screenshot": screenshot }))
        }
        "page.extract" => {
            let selector = params
                .get("selector")
                .and_then(|v| v.as_str())
                .ok_or_else(|| anyhow::anyhow!("selector required"))?;
            let mut ipc = json!({ "selector": selector });
            if let Some(as_key) = params.get("as").and_then(|v| v.as_str()) {
                ipc["as"] = json!(as_key);
            }
            tab_id_in(params, &mut ipc);
            let result = rpc_call("page.extract", ipc).await?;
            Ok(json!({ "ok": true, "result": result }))
        }
        "page.act" => {
            let action = params
                .get("action")
                .and_then(|v| v.as_str())
                .ok_or_else(|| anyhow::anyhow!("action required"))?;
            let selector = params
                .get("selector")
                .and_then(|v| v.as_str())
                .ok_or_else(|| anyhow::anyhow!("selector required"))?;
            let mut ipc = json!({ "action": action, "selector": selector });
            if let Some(text) = params.get("text").and_then(|v| v.as_str()) {
                ipc["text"] = json!(text);
            }
            tab_id_in(params, &mut ipc);
            let result = rpc_call("page.act", ipc).await?;
            Ok(json!({ "ok": true, "result": result }))
        }
        "extension.version" | "extension.reload" => rpc_call(method, json!({})).await,
        other => anyhow::bail!("unknown browser method: {other}"),
    }
}

pub async fn extension_task_run(params: Value) -> anyhow::Result<Value> {
    let bridge = bridge()?;
    tokio::task::spawn_blocking(move || bridge.call("task.run", params, TASK_RPC_TIMEOUT))
        .await?
}
