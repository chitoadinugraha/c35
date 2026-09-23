use anyhow::{anyhow, Result};
use c35_proto::{ActDeviceTaskRun, Skill, SkillStep};
use tracing::{info, warn};

/// Replay skill steps in order. On any step failure, returns Err.
pub async fn play(
    server_url: &str,
    session_key: &str,
    device_iid: i64,
    act: &ActDeviceTaskRun,
    skill: &Skill,
) -> Result<()> {
    let steps = &skill.steps;
    if steps.is_empty() {
        // No steps = body_md only skill (prompt-style); consider it OK
        info!(skill_id = skill.id, "no tape steps, prompt-only skill");
        return Ok(());
    }

    for (i, step) in steps.iter().enumerate() {
        if step.deleted_ts_ms > 0 {
            continue;
        }
        info!(step = i, kind = %step.kind, label = %step.label, "executing tape step");

        let _ = crate::skill_api::task_progress(
            server_url,
            session_key,
            act.run_id,
            device_iid,
            i as i32,
            "task_step",
            &format!("Step {}: {}", i + 1, step.label),
            "",
        )
        .await;

        execute_step(step).await.map_err(|e| {
            warn!(step = i, kind = %step.kind, err = %e, "tape step failed");
            anyhow!("step_{i}_failed: {e}")
        })?;

        // Small delay between steps
        tokio::time::sleep(std::time::Duration::from_millis(300)).await;
    }

    Ok(())
}

async fn execute_step(step: &SkillStep) -> Result<()> {
    match step.kind.as_str() {
        "click" | "double_click" | "right_click" => {
            execute_win32_action(&step.kind, &step.ax_target_json, "").await
        }
        "type" => {
            let text = extract_type_text(&step.tape_local_only_json, &step.label);
            execute_win32_action("type", "", &text).await
        }
        "shortcut" => {
            execute_win32_action("shortcut", "", &step.label).await
        }
        "wait" => {
            let ms: u64 = serde_json::from_str::<serde_json::Value>(&step.ax_target_json)
                .ok()
                .and_then(|v| v["ms"].as_u64())
                .unwrap_or(1000);
            tokio::time::sleep(std::time::Duration::from_millis(ms)).await;
            Ok(())
        }
        "screenshot" => Ok(()), // informational step
        "shell" => {
            let cmd = step.label.trim();
            if cmd.is_empty() {
                return Ok(());
            }
            let output = tokio::task::spawn_blocking({
                let cmd = cmd.to_string();
                move || {
                    std::process::Command::new("powershell")
                        .args(["-NoProfile", "-NonInteractive", "-Command", &cmd])
                        .output()
                }
            })
            .await??;
            if !output.status.success() {
                let stderr = String::from_utf8_lossy(&output.stderr);
                return Err(anyhow!("shell step failed: {stderr}"));
            }
            Ok(())
        }
        other => {
            warn!(kind = other, "unknown step kind, skipping");
            Ok(())
        }
    }
}

async fn execute_win32_action(kind: &str, ax_target: &str, text: &str) -> Result<()> {
    info!(kind, ax_target, text, "[win32] executing skill tape action");

    let (x, y) = if !ax_target.is_empty() {
        if let Ok(val) = serde_json::from_str::<serde_json::Value>(ax_target) {
            let x = val.get("x").or_else(|| val.get("center_x")).and_then(|v| v.as_f64()).unwrap_or(0.0);
            let y = val.get("y").or_else(|| val.get("center_y")).and_then(|v| v.as_f64()).unwrap_or(0.0);
            (x, y)
        } else {
            (0.0, 0.0)
        }
    } else {
        (0.0, 0.0)
    };

    let evt = match kind {
        "click" => c35_proto::RemoteInputEvent {
            event_type: "mouse_click".to_string(),
            x,
            y,
            button: 0,
            ..Default::default()
        },
        "double_click" => c35_proto::RemoteInputEvent {
            event_type: "double_click".to_string(),
            x,
            y,
            button: 0,
            ..Default::default()
        },
        "right_click" => c35_proto::RemoteInputEvent {
            event_type: "right_click".to_string(),
            x,
            y,
            button: 2,
            ..Default::default()
        },
        "type" => c35_proto::RemoteInputEvent {
            event_type: "type_text".to_string(),
            text: text.to_string(),
            ..Default::default()
        },
        "shortcut" => c35_proto::RemoteInputEvent {
            event_type: "shortcut".to_string(),
            text: text.to_string(),
            ..Default::default()
        },
        _ => return Ok(()),
    };

    crate::webrtc::dispatch_input(&evt);
    Ok(())
}

fn extract_type_text(tape_json: &str, label: &str) -> String {
    serde_json::from_str::<serde_json::Value>(tape_json)
        .ok()
        .and_then(|v| v["text"].as_str().map(|s| s.to_string()))
        .unwrap_or_else(|| label.to_string())
}
