use serde_json::{json, Value};

use crate::extension_ipc::ExtensionBridge;
use crate::mode;

pub async fn extension_tab_command(body: &Value) -> anyhow::Result<Value> {
    let st = crate::browser_state::global().ok_or_else(|| anyhow::anyhow!("browser state not init"))?;
    let bridge = st
        .extension_bridge
        .lock()
        .ok()
        .and_then(|g| g.clone());

    let op = body.get("op").and_then(|v| v.as_str()).unwrap_or("");
    match bridge {
        None => Ok(json!({ "tabs": [] })),
        Some(b) => extension_tab_command_bridge(&b, op, body).await,
    }
}

async fn extension_tab_command_bridge(
    bridge: &ExtensionBridge,
    op: &str,
    body: &Value,
) -> anyhow::Result<Value> {
    match op {
        "list" => {
            bridge.tabs_list()?;
            Ok(json!({ "tabs": [] }))
        }
        "activate" => {
            let tab_id = body
                .get("tab_id")
                .or_else(|| body.get("tabId"))
                .and_then(|v| v.as_str())
                .ok_or_else(|| anyhow::anyhow!("tab_id required"))?;
            bridge.tabs_activate(tab_id)?;
            Ok(json!({ "ok": true, "tab_id": tab_id }))
        }
        "new" | "close" => anyhow::bail!("extension engine tab op not supported: {op}"),
        _ => anyhow::bail!("unknown browser.tab op: {op}"),
    }
}

pub async fn handle_tab_ws(body: Value) -> anyhow::Result<Value> {
    if mode::is_extension_engine() {
        return extension_tab_command(&body).await;
    }
    let st = crate::browser_state::global().ok_or_else(|| anyhow::anyhow!("browser state not init"))?;
    let headless = mode::headless_from_config();
    let slot_id = body
        .get("slot_id")
        .and_then(|v| v.as_str())
        .unwrap_or("default");
    let bridge = crate::engine::process::ensure_engine(&st, headless, slot_id).await?;
    crate::browser_tabs::tab_command(&bridge, &body).await
}