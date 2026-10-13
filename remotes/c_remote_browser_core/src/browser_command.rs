use std::sync::Arc;

use c_remote_core::c35_proto::ResRemoteCommand;
use serde_json::{json, Value};
use tracing::warn;

use crate::mode;
use crate::playwright;

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
    if method == "ensure" {
        return crate::browser_ensure::browser_ensure(&params).await;
    }
    if mode::is_extension_engine() {
        if method == "tabs" {
            return crate::extension_tabs::extension_tab_command(&params).await;
        }
        if method == "file.upload" {
            anyhow::bail!(
                "browser.file.upload is not supported in chrome extension mode (deferred v1; use Remote tab for manual file pick)"
            );
        }
        if method.starts_with("sheets.") {
            return crate::extension_sheets::extension_sheets_method(method, &params).await;
        }
        if method == "agent.restart" {
            crate::extension_agent::restart_extension_agent()?;
            return Ok(json!({ "ok": true, "restarting": true }));
        }
        if method == "captcha.apply" {
            anyhow::bail!(
                "browser.captcha.apply is not supported on Chrome extension devices (browser_engine=extension); use the Remote tab for manual captcha"
            );
        }
        if method.starts_with("extension.") {
            return crate::extension_page::extension_page_method(method, &params).await;
        }
        return crate::extension_page::extension_page_method(method, &params).await;
    }
    playwright::invoke_method(method, params).await
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
                    let msg = e.to_string();
                    if msg != crate::extension_ipc::EXTENSION_IPC_NOT_READY_MSG {
                        warn!("browser command {method}: {msg}");
                    }
                    Some(cmd_err(msg))
                }
            }
        })
    }));
}
