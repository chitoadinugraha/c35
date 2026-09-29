use std::time::Duration;

use serde_json::{json, Value};

use crate::extension_ipc::extension_bridge_get;

const TAB_RPC_TIMEOUT: Duration = Duration::from_secs(4);

pub async fn extension_tab_command(body: &Value) -> anyhow::Result<Value> {
    let bridge = extension_bridge_get().ok_or_else(crate::extension_ipc::extension_ipc_not_ready_err)?;
    let op = body.get("op").and_then(|v| v.as_str()).unwrap_or("");
    extension_tab_command_bridge(bridge, op, body).await
}

async fn extension_tab_command_bridge(
    bridge: std::sync::Arc<crate::extension_ipc::ExtensionBridge>,
    op: &str,
    body: &Value,
) -> anyhow::Result<Value> {
    let tab_id = body
        .get("tab_id")
        .or_else(|| body.get("tabId"))
        .and_then(|v| v.as_str());
    let url = body.get("url").and_then(|v| v.as_str());
    match op {
        "list" => {
            let state = crate::browser_state::global()
                .ok_or_else(|| anyhow::anyhow!("browser state not init"))?;
            tokio::task::spawn_blocking(move || bridge.tabs_list()).await??;
            let deadline = std::time::Instant::now() + TAB_RPC_TIMEOUT;
            while std::time::Instant::now() < deadline {
                if let Ok(g) = state.extension_tabs.lock() {
                    if let Some(v) = g.as_ref() {
                        return Ok(v.clone());
                    }
                }
                std::thread::sleep(std::time::Duration::from_millis(40));
            }
            anyhow::bail!("tabs list timeout (extension did not respond)")
        }
        "activate" => {
            let tab_id = tab_id.ok_or_else(|| anyhow::anyhow!("tab_id required"))?;
            let tab_id_s = tab_id.to_string();
            tokio::task::spawn_blocking(move || {
                bridge.call(
                    "tabs.activate",
                    json!({ "tab_id": tab_id_s }),
                    TAB_RPC_TIMEOUT,
                )
            })
            .await??;
            Ok(json!({ "ok": true, "tab_id": tab_id }))
        }
        "new" => {
            let params = match url {
                Some(u) => json!({ "url": u }),
                None => json!({}),
            };
            let result = tokio::task::spawn_blocking(move || bridge.call("tabs.new", params, TAB_RPC_TIMEOUT))
                .await??;
            Ok(result)
        }
        "close" => {
            let tab_id = tab_id.ok_or_else(|| anyhow::anyhow!("tab_id required"))?;
            let tab_id_s = tab_id.to_string();
            let result = tokio::task::spawn_blocking(move || {
                bridge.call(
                    "tabs.close",
                    json!({ "tab_id": tab_id_s }),
                    TAB_RPC_TIMEOUT,
                )
            })
            .await??;
            Ok(result)
        }
        _ => anyhow::bail!("unknown browser.tab op: {op}"),
    }
}

pub async fn handle_tab_ws(body: Value) -> anyhow::Result<Value> {
    if crate::mode::is_extension_engine() {
        return extension_tab_command(&body).await;
    }
    let st = crate::browser_state::global().ok_or_else(|| anyhow::anyhow!("browser state not init"))?;
    let headless = crate::mode::headless_from_config();
    let slot_id = body
        .get("slot_id")
        .and_then(|v| v.as_str())
        .unwrap_or("default");
    let bridge = crate::engine::process::ensure_engine(&st, headless, slot_id).await?;
    crate::browser_tabs::tab_command(&bridge, &body).await
}
