use anyhow::Result;
use c35_proto::{ActDeviceTaskRun, Skill};
use tracing::{info, warn};

pub struct DispatchCtx {
    pub server_url: String,
    pub session_key: String,
    pub device_iid: i64,
    pub skill_store: crate::skill_store::SkillStore,
}

pub async fn dispatch(ctx: &DispatchCtx, act: ActDeviceTaskRun) -> Result<()> {
    let _task_guard = crate::update::task_start();
    info!(run_id = act.run_id, prompt = %act.prompt, "skill dispatch start");

    // 1. Find local skill match
    let local_skill = if act.skill_id > 0 {
        // Explicit skill_id from task definition
        ctx.skill_store
            .read()
            .unwrap()
            .iter()
            .find(|s| s.id == act.skill_id)
            .cloned()
    } else {
        crate::skill_store::find_match(&ctx.skill_store, &act.prompt, "", "")
    };

    if let Some(skill) = local_skill {
        info!(skill_id = skill.id, title = %skill.title, "found local skill, playing tape");
        // 2a. Replay tape
        match crate::skill_tape::play(
            &ctx.server_url,
            &ctx.session_key,
            ctx.device_iid,
            &act,
            &skill,
        )
        .await
        {
            Ok(()) => {
                let updated = bump_consecutive_ok(&skill);
                let _ = crate::skill_api::skill_put(
                    &ctx.server_url,
                    &ctx.session_key,
                    updated.clone(),
                )
                .await;
                // Report to catalog if from catalog
                if skill.catalog_release_id > 0 {
                    let _ = crate::skill_api::skill_run_report(
                        &ctx.server_url,
                        &ctx.session_key,
                        skill.id,
                        true,
                        "",
                    )
                    .await;
                }
                // Evaluate auto-submit
                crate::skill_submit::maybe_submit(ctx, &updated).await;
                report_done(&ctx.server_url, &ctx.session_key, &act, true, "done").await;
            }
            Err(e) => {
                warn!(run_id = act.run_id, err = %e, "tape play failed, attempting self-heal");
                if skill.catalog_release_id > 0 {
                    let _ = crate::skill_api::skill_run_report(
                        &ctx.server_url,
                        &ctx.session_key,
                        skill.id,
                        false,
                        &e.to_string(),
                    )
                    .await;
                }
                crate::skill_heal::heal(ctx, &act, &skill, &e.to_string()).await?;
            }
        }
    } else {
        info!(run_id = act.run_id, "no local skill match, searching catalog");
        // 2b. Try catalog search
        let catalog_skill = crate::skill_api::catalog_search(
            &ctx.server_url,
            &ctx.session_key,
            &act.prompt,
        )
        .await
        .ok()
        .and_then(|r| r.catalogs.into_iter().next());


        if let Some(cat) = catalog_skill {
            info!(catalog_id = cat.id, title = %cat.title, "found catalog skill, installing");
            match crate::skill_api::catalog_install(
                &ctx.server_url,
                &ctx.session_key,
                cat.id,
                ctx.device_iid,
            )
            .await
            {
                Ok(installed_skill) => {
                    crate::skill_store::update_skill(&ctx.skill_store, installed_skill.clone());
                    match crate::skill_tape::play(
                        &ctx.server_url,
                        &ctx.session_key,
                        ctx.device_iid,
                        &act,
                        &installed_skill,
                    )
                    .await
                    {
                        Ok(()) => {
                            let updated = bump_consecutive_ok(&installed_skill);
                            let _ = crate::skill_api::skill_put(
                                &ctx.server_url,
                                &ctx.session_key,
                                updated,
                            )
                            .await;
                            report_done(
                                &ctx.server_url,
                                &ctx.session_key,
                                &act,
                                true,
                                "done",
                            )
                            .await;
                        }
                        Err(e) => {
                            warn!("catalog skill tape failed: {e}; falling back to first-time explore");
                            crate::skill_explore::explore(ctx, &act, None).await?;
                        }
                    }
                }
                Err(e) => {
                    warn!("catalog install failed: {e}; falling back to first-time explore");
                    crate::skill_explore::explore(ctx, &act, None).await?;
                }
            }
        } else {
            // 2c. First-time AI exploration
            info!(run_id = act.run_id, "no catalog match, first-time AI exploration");
            crate::skill_explore::explore(ctx, &act, None).await?;
        }
    }

    Ok(())
}

fn bump_consecutive_ok(skill: &Skill) -> Skill {
    let mut s = skill.clone();
    s.consecutive_ok += 1;
    s.patch_count = 0; // reset on success
    s
}

async fn report_done(
    server_url: &str,
    session_key: &str,
    act: &ActDeviceTaskRun,
    ok: bool,
    detail: &str,
) {
    let _ = crate::skill_api::task_done(
        server_url,
        session_key,
        act.run_id,
        act.device_iid,
        ok,
        detail,
    )
    .await;
}
