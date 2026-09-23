use c35_proto::{pb_decode, ActDeviceTaskRun, RemoteInputEvent};
use tracing::{info, warn};

pub async fn task_run_handle(
    payload: &[u8],
    dispatch_ctx: &crate::skill_dispatch::DispatchCtx,
) -> anyhow::Result<()> {
    if let Ok(input) = pb_decode::<RemoteInputEvent>(payload) {
        crate::webrtc::dispatch_input(&input);
        return Ok(());
    }

    if let Ok(act) = pb_decode::<ActDeviceTaskRun>(payload) {
        info!(run_id = act.run_id, prompt = %act.prompt, "ActDeviceTaskRun received");
        if let Err(e) = crate::skill_dispatch::dispatch(dispatch_ctx, act).await {
            warn!("skill dispatch error: {e}");
        }
        return Ok(());
    }

    // Release notification or legacy raw text command
    if let Ok(cmd_str) = std::str::from_utf8(payload) {
        let cmd = cmd_str.trim().to_string();
        if cmd.starts_with("c35.release:") || cmd.starts_with("{\"platform\":\"remote-windows\"") {
            info!("Received release notification over agent session; triggering immediate background update");
            crate::update::trigger_background_update(dispatch_ctx.server_url.clone());
            return Ok(());
        }
        if !cmd.is_empty() {
            let _task_guard = crate::update::task_start();
            info!(command = %cmd, "executing legacy agent command");
            #[cfg(windows)]
            {
                let output = tokio::task::spawn_blocking(move || {
                    std::process::Command::new("powershell")
                        .args(["-NoProfile", "-NonInteractive", "-Command", &cmd])
                        .output()
                })
                .await??;
                info!(status = ?output.status, "legacy command finished");
            }
        }
    }

    Ok(())
}
