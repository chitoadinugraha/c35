use std::sync::Arc;

use c_remote_core::c35_proto::ActDeviceTaskRun;
use c_remote_core::skill_api;
use serde_json::{json, Value};
use tracing::warn;

use crate::engine::process;
use crate::mode;

pub async fn handle_act(
    server_url: &str,
    session_key: &str,
    act: ActDeviceTaskRun,
) -> anyhow::Result<()> {
    let _guard = c_remote_core::update::task_start();

    let body: Value = match serde_json::from_str(&act.prompt) {
        Ok(v) => v,
        Err(_) => serde_json::json!({
            "slot_id": "default",
            "steps": [{ "op": "navigate", "url": act.prompt.trim() }]
        }),
    };

    let slot_id = body
        .get("slot_id")
        .and_then(|v| v.as_str())
        .unwrap_or("default");
    let steps = body.get("steps").cloned().unwrap_or(Value::Array(vec![]));
    let mut params = json!({ "slot_id": slot_id, "steps": steps });
    if let Some(tab_id) = body.get("tab_id").and_then(|v| v.as_str()) {
        params["tab_id"] = json!(tab_id);
    }

    let result = if mode::is_extension_engine() {
        crate::extension_page::extension_task_run(params).await?
    } else {
        let st =
            crate::browser_state::global().ok_or_else(|| anyhow::anyhow!("browser state not init"))?;
        let headless = mode::headless_from_config();
        let bridge = process::ensure_engine(&st, headless, slot_id).await?;
        bridge.call("task.run", params).await?
    };

    let detail = result.to_string();
    skill_api::task_done(
        server_url,
        session_key,
        act.run_id,
        act.device_iid,
        true,
        &detail,
    )
    .await?;
    Ok(())
}

pub fn register_task_handler() {
    super::browser_tabs::register_tab_handler();
    c_remote_core::task_run::set_act_device_task_handler(Arc::new(|act, ctx| {
        let server_url = ctx.server_url.clone();
        let session_key = ctx.session_key.clone();
        Box::pin(async move {
            let run_id = act.run_id;
            let device_iid = act.device_iid;
            if let Err(e) = handle_act(&server_url, &session_key, act).await {
                warn!("browser task failed: {e}");
                let _ = skill_api::task_done(
                    &server_url,
                    &session_key,
                    run_id,
                    device_iid,
                    false,
                    &e.to_string(),
                )
                .await;
            }
            Ok(())
        })
    }));
}
