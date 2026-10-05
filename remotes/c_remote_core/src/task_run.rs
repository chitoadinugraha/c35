use std::future::Future;
use std::pin::Pin;
use std::sync::{Arc, RwLock};

use c35_proto::{pb_decode, ActDeviceTaskRun, RemoteInputEvent};
use serde_json::Value;
use tracing::{info, warn};

pub type ActDeviceTaskHandler = Arc<
    dyn Fn(
            ActDeviceTaskRun,
            &crate::skill_dispatch::DispatchCtx,
        ) -> Pin<Box<dyn Future<Output = anyhow::Result<()>> + Send>>
        + Send
        + Sync,
>;

static ACT_DEVICE_TASK_HANDLER: RwLock<Option<ActDeviceTaskHandler>> = RwLock::new(None);

pub type WsTextCommandHandler = Arc<dyn Fn(&str) -> bool + Send + Sync>;

static WS_TEXT_COMMAND_HANDLER: RwLock<Option<WsTextCommandHandler>> = RwLock::new(None);

/// Agent-specific WS text commands (e.g. remote browser tab control). Return true if handled.
pub fn set_ws_text_command_handler(handler: WsTextCommandHandler) {
    if let Ok(mut g) = WS_TEXT_COMMAND_HANDLER.write() {
        *g = Some(handler);
    }
}

/// When set (remote browser agent), handles `ActDeviceTaskRun` instead of desktop skill dispatch.
pub fn set_act_device_task_handler(handler: ActDeviceTaskHandler) {
    if let Ok(mut g) = ACT_DEVICE_TASK_HANDLER.write() {
        *g = Some(handler);
    }
}

pub type BrowserTabHandler = Arc<
    dyn Fn(
            Value,
        ) -> Pin<Box<dyn Future<Output = anyhow::Result<Value>> + Send>>
        + Send
        + Sync,
>;

static BROWSER_TAB_HANDLER: RwLock<Option<BrowserTabHandler>> = RwLock::new(None);

pub fn set_browser_tab_handler(handler: BrowserTabHandler) {
    if let Ok(mut g) = BROWSER_TAB_HANDLER.write() {
        *g = Some(handler);
    }
}

pub async fn task_run_handle(
    payload: &[u8],
    dispatch_ctx: &crate::skill_dispatch::DispatchCtx,
) -> anyhow::Result<()> {
    if let Ok(input) = pb_decode::<RemoteInputEvent>(payload) {
        if !input.event_type.is_empty() {
            crate::webrtc::dispatch_input(&input);
            return Ok(());
        }
    }

    if let Ok(act) = pb_decode::<ActDeviceTaskRun>(payload) {
        info!(run_id = act.run_id, prompt = %act.prompt, "ActDeviceTaskRun received");
        let custom = ACT_DEVICE_TASK_HANDLER
            .read()
            .ok()
            .and_then(|g| g.clone());
        if let Some(handler) = custom {
            if let Err(e) = handler(act, dispatch_ctx).await {
                warn!("custom task handler error: {e}");
            }
            return Ok(());
        }
        if let Err(e) = crate::skill_dispatch::dispatch(dispatch_ctx, act).await {
            warn!("skill dispatch error: {e}");
        }
        return Ok(());
    }

    // Release notification or legacy raw text command
    if let Ok(cmd_str) = std::str::from_utf8(payload) {
        let cmd = cmd_str.trim();
        if cmd.starts_with("c35.drive:") {
            if let Ok(handler) = WS_TEXT_COMMAND_HANDLER.read() {
                if let Some(h) = handler.as_ref() {
                    if h(cmd) {
                        return Ok(());
                    }
                }
            }
        }
        if cmd == "c35.unpair" {
            info!("Received c35.unpair over agent session; clearing local pairing");
            crate::conn_exit::request_unpair();
            let _ = crate::config::session_key_clear();
            return Ok(());
        }
        let cmd = cmd.to_string();
        if cmd.starts_with("c35.release:ffmpeg-windows")
            || cmd.contains("\"platform\":\"ffmpeg-windows\"")
        {
            info!("Received ffmpeg release notification; triggering ffmpeg OTA download");
            #[cfg(target_os = "windows")]
            crate::tools::ffmpeg::trigger_background_ffmpeg_update(dispatch_ctx.server_url.clone());
            return Ok(());
        }
        if cmd.contains("\"platform\":\"remote-browser\"") || cmd.starts_with("c35.release:remote-browser") {
            info!("Received remote-browser release notification; triggering background update");
            std::env::set_var("C35_RELEASE_PLATFORM", "remote-browser");
            crate::update::trigger_background_update(dispatch_ctx.server_url.clone());
            return Ok(());
        }
        if cmd.contains("\"platform\":\"chrome-extension\"") || cmd.starts_with("c35.release:chrome-extension") {
            info!("Received chrome-extension release notification; triggering background update");
            std::env::set_var("C35_RELEASE_PLATFORM", "chrome-extension");
            crate::update::trigger_background_update(dispatch_ctx.server_url.clone());
            return Ok(());
        }
        if (cmd.starts_with("c35.release:") && !cmd.contains("remote-browser") && !cmd.contains("chrome-extension"))
            || cmd.starts_with("{\"platform\":\"remote-windows\"")
        {
            info!("Received release notification over agent session; triggering immediate background update");
            crate::update::trigger_background_update(dispatch_ctx.server_url.clone());
            return Ok(());
        }
        if let Ok(handler) = WS_TEXT_COMMAND_HANDLER.read() {
            if let Some(h) = handler.as_ref() {
                if h(&cmd) {
                    return Ok(());
                }
            }
        }
        if let Some(mode) = cmd.strip_prefix("c35.browser.mode:") {
            let mode = mode.trim();
            if let Err(e) = crate::config::browser_mode_save(mode) {
                warn!("browser mode save failed: {e}");
            } else {
                info!(mode, "browser mode saved; restart agent to apply headless flag");
            }
            return Ok(());
        }
        if let Some(payload) = cmd.strip_prefix("c35.browser.tab:") {
            let body: Value = match serde_json::from_str(payload.trim()) {
                Ok(v) => v,
                Err(e) => {
                    warn!("c35.browser.tab invalid json: {e}");
                    return Ok(());
                }
            };
            let custom = BROWSER_TAB_HANDLER.read().ok().and_then(|g| g.clone());
            if let Some(handler) = custom {
                if let Err(e) = handler(body).await {
                    warn!("browser tab handler error: {e}");
                }
            } else {
                warn!("c35.browser.tab received but no handler registered");
            }
            return Ok(());
        }
        if !cmd.is_empty() {
            let _task_guard = crate::update::task_start();
            info!(command = %cmd, "executing legacy agent command");
            #[cfg(windows)]
            {
                let output = tokio::task::spawn_blocking(move || crate::win_powershell::command_output(&cmd))
                .await??;
                info!(status = ?output.status, "legacy command finished");
            }
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use c35_proto::{
        pb_decode, pb_encode, RemoteInputEvent, ReqRemoteScreenshot, WsReq, ws_req,
    };

    #[test]
    fn ws_req_screenshot_roundtrip() {
        let req = WsReq {
            req_id: "100419954668314624".into(),
            body: Some(ws_req::Body::ReqRemoteScreenshot(ReqRemoteScreenshot {
                device_iid: 100383566648971264,
                max_width: 800,
                quality: 70,
                marker_x: 0.5,
                marker_y: 0.25,
                som: false,
            })),
        };
        let bytes = pb_encode(&req);
        let decoded = pb_decode::<WsReq>(&bytes).expect("decode WsReq");
        assert!(matches!(
            decoded.body,
            Some(ws_req::Body::ReqRemoteScreenshot(_))
        ));
    }

    #[test]
    fn remote_input_is_not_empty_ws_req() {
        let input = RemoteInputEvent {
            event_type: "mouse_click".into(),
            x: 0.5,
            y: 0.5,
            ..Default::default()
        };
        let bytes = pb_encode(&input);
        let ws = pb_decode::<WsReq>(&bytes).expect("ws decode");
        assert!(ws.body.is_none() && ws.req_id.is_empty());
    }
}
