use std::sync::Arc;

use tracing::debug;

use crate::sync_wake;

pub fn register_ws_drive_sync_handler() {
    c_remote_core::task_run::set_ws_text_command_handler(Arc::new(|cmd| {
        if let Some(rest) = cmd.trim().strip_prefix("c35.drive:") {
            if let Ok(v) = serde_json::from_str::<serde_json::Value>(rest) {
                let since_ms = v.get("since_ms").and_then(|x| x.as_i64()).unwrap_or(0);
                debug!(since_ms, "drive sync nudge from agent WS");
                sync_wake::wake_sync();
                return true;
            }
        }
        false
    }));
}
