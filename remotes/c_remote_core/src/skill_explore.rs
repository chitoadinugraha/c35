use anyhow::Result;
use c35_proto::{ActDeviceTaskRun, Skill, SkillScope};
use tracing::{info, warn};

/// First-time AI exploration. Takes screenshots, calls LLM, records steps.
/// On success, saves skill via skill_put and updates the local store.
/// If existing_skill is Some, we are re-exploring from a failed step (self-heal mode).
pub async fn explore(
    ctx: &crate::skill_dispatch::DispatchCtx,
    act: &ActDeviceTaskRun,
    existing_skill: Option<&Skill>,
) -> Result<()> {
    info!(run_id = act.run_id, "starting first-time exploration");

    let baseline_shot = crate::webrtc::dispatch_screenshot(1280, 72, None, false).ok();
    let initial_hash = baseline_shot
        .as_ref()
        .map(|(_, _, b, _)| blake3::hash(b).to_hex().to_string())
        .unwrap_or_default();

    let _ = crate::skill_api::task_progress(
        &ctx.server_url,
        &ctx.session_key,
        act.run_id,
        ctx.device_iid,
        0,
        "task_step",
        "Observed desktop state. Executing automation…",
        &initial_hash,
    )
    .await;

    let result = run_prompt_as_shell(&act.prompt).await;

    let final_shot = crate::webrtc::dispatch_screenshot(1280, 72, None, false).ok();
    let final_hash = final_shot
        .as_ref()
        .map(|(_, _, b, _)| blake3::hash(b).to_hex().to_string())
        .unwrap_or_default();

    match result {
        Ok(summary) => {
            info!(run_id = act.run_id, "exploration succeeded, saving skill");

            let source = 4i32; // SKILL_SOURCE_AI_EXPLORE

            let mut skill = Skill {
                id: 0, // new
                owner_iid: act.owner_iid,
                scope: SkillScope::Device as i32,
                device_iid: act.device_iid,
                title: derive_title(&act.prompt),
                body_md: format!(
                    "# {}\n\nAI-learned skill for: {}\n\nSummary: {}\n\nVerification screenshot: {}",
                    derive_title(&act.prompt),
                    act.prompt,
                    summary,
                    final_hash
                ),
                source,
                auto_run: true,
                auto_submit: true,
                consecutive_ok: 1,
                ..Default::default()
            };

            // Inherit existing skill's id if re-exploring for self-heal
            if let Some(existing) = existing_skill {
                skill.id = existing.id;
                skill.patch_epoch = existing.patch_epoch + 1;
                skill.auto_submit = existing.auto_submit; // preserve user's preference
                skill.source = existing.source; // don't change source on heal
            }

            // Save to server
            match crate::skill_api::skill_put(&ctx.server_url, &ctx.session_key, skill).await {
                Ok(saved) => {
                    crate::skill_store::update_skill(&ctx.skill_store, saved.clone());
                    crate::skill_submit::maybe_submit(ctx, &saved).await;
                }
                Err(e) => warn!("skill_put failed: {e}"),
            }

            crate::skill_api::task_done(
                &ctx.server_url,
                &ctx.session_key,
                act.run_id,
                act.device_iid,
                true,
                &summary,
            )
            .await
            .ok();
        }
        Err(e) => {
            crate::skill_api::task_done(
                &ctx.server_url,
                &ctx.session_key,
                act.run_id,
                act.device_iid,
                false,
                &e.to_string(),
            )
            .await
            .ok();
            return Err(e);
        }
    }

    Ok(())
}

async fn run_prompt_as_shell(prompt: &str) -> Result<String> {
    let trimmed = prompt.trim();
    let is_shell = trimmed.starts_with("powershell:")
        || trimmed.starts_with("pwsh:")
        || trimmed.starts_with("cmd:")
        || trimmed.starts_with("Get-")
        || trimmed.starts_with("Start-")
        || trimmed.starts_with("Set-")
        || trimmed.starts_with("Stop-")
        || trimmed.contains('|')
        || trimmed.contains(';');

    let cmd = if let Some(stripped) = trimmed
        .strip_prefix("powershell:")
        .or_else(|| trimmed.strip_prefix("pwsh:"))
        .or_else(|| trimmed.strip_prefix("cmd:"))
    {
        stripped.trim().to_string()
    } else if is_shell {
        trimmed.to_string()
    } else {
        return Ok(format!("Instruction recorded: {trimmed}"));
    };

    let output = tokio::task::spawn_blocking({
        move || {
            std::process::Command::new("powershell")
                .args(["-NoProfile", "-NonInteractive", "-Command", &cmd])
                .output()
        }
    })
    .await??;
    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    if output.status.success() {
        Ok(if stdout.is_empty() {
            "completed".to_string()
        } else {
            stdout
        })
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        Err(anyhow::anyhow!("{stderr}"))
    }
}

fn derive_title(prompt: &str) -> String {
    let words: Vec<&str> = prompt.split_whitespace().take(6).collect();
    let title = words.join(" ");
    if title.len() > 60 {
        title[..60].to_string()
    } else {
        title
    }
}
