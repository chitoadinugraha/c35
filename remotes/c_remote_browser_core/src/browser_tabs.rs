use std::sync::Arc;

use serde_json::Value;
use tracing::info;

use crate::extension_tabs;
use crate::mode;
use crate::playwright;

async fn handle_tab_ws(body: Value) -> anyhow::Result<Value> {
    if mode::is_extension_engine() {
        return extension_tabs::extension_tab_command(&body).await;
    }
    playwright::invoke_tab_ws(body).await
}

pub fn register_tab_handler() {
    c_remote_core::task_run::set_browser_tab_handler(Arc::new(|body| {
        Box::pin(async move {
            let op = body.get("op").and_then(|v| v.as_str()).unwrap_or("").to_string();
            let result = handle_tab_ws(body).await;
            match &result {
                Ok(v) => info!(op = %op, result = %v, "c35.browser.tab ok"),
                Err(e) => tracing::warn!(op = %op, "c35.browser.tab failed: {e}"),
            }
            result
        })
    }));
}
