use anyhow::Result;
use c35_proto::{ActDeviceTaskRun, Skill};
use tracing::{info, warn};

const MAX_PATCHES_PER_DAY: i32 = 3;

pub async fn heal(
    ctx: &crate::skill_dispatch::DispatchCtx,
    act: &ActDeviceTaskRun,
    skill: &Skill,
    failure_reason: &str,
) -> Result<()> {
    info!(skill_id = skill.id, failure = failure_reason, "skill_heal: evaluating self-repair");

    let now_ms = unix_now_ms();
    let since_last_patch_secs = if skill.last_patched_ts_ms > 0 {
        (now_ms - skill.last_patched_ts_ms) / 1000
    } else {
        86401 // more than 24h ago → treat as first patch
    };

    // Reset patch_count if last patch was > 24h ago
    let effective_patch_count = if since_last_patch_secs > 86400 {
        0
    } else {
        skill.patch_count
    };

    if effective_patch_count >= MAX_PATCHES_PER_DAY {
        warn!(skill_id = skill.id, "circuit breaker tripped: max patches/day reached");
        // Pause auto-run and save
        let mut updated = skill.clone();
        updated.auto_run = false;
        let _ =
            crate::skill_api::skill_put(&ctx.server_url, &ctx.session_key, updated.clone()).await;
        crate::skill_store::update_skill(&ctx.skill_store, updated);

        crate::skill_api::task_done(
            &ctx.server_url,
            &ctx.session_key,
            act.run_id,
            ctx.device_iid,
            false,
            &format!(
                "Skill auto-repair paused: too many patches in 24h. Reason: {}. \
                 Please review the skill in the app.",
                failure_reason
            ),
        )
        .await
        .ok();

        return Ok(());
    }

    info!(
        skill_id = skill.id,
        patch_count = effective_patch_count,
        "attempting self-repair via re-exploration"
    );

    let _ = crate::skill_api::task_progress(
        &ctx.server_url,
        &ctx.session_key,
        act.run_id,
        ctx.device_iid,
        0,
        "task_log",
        &format!(
            "UI may have changed. Re-learning the workflow… (attempt {}/{})",
            effective_patch_count + 1,
            MAX_PATCHES_PER_DAY
        ),
        "",
    )
    .await;

    let mut patched_skill = skill.clone();
    patched_skill.patch_count = effective_patch_count + 1;
    patched_skill.patch_epoch += 1;
    patched_skill.last_patched_ts_ms = now_ms;
    patched_skill.consecutive_ok = 0;

    crate::skill_explore::explore(ctx, act, Some(&patched_skill)).await
}

fn unix_now_ms() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_millis() as i64)
        .unwrap_or(0)
}
