use c35_proto::{ReqSkillCatalogSubmit, Skill};
use tracing::{info, warn};

const CONSECUTIVE_OK_GATE: i32 = 5;

pub async fn maybe_submit(ctx: &crate::skill_dispatch::DispatchCtx, skill: &Skill) {
    if !skill.auto_submit {
        return;
    }
    if skill.consecutive_ok < CONSECUTIVE_OK_GATE {
        info!(
            skill_id = skill.id,
            consecutive_ok = skill.consecutive_ok,
            gate = CONSECUTIVE_OK_GATE,
            "auto-submit gate not reached"
        );
        return;
    }
    // Already in catalog — skip
    if skill.catalog_id > 0 {
        return;
    }

    info!(
        skill_id = skill.id,
        "auto-submit gate reached, submitting to Alien AI Public Skill Library"
    );

    let req = ReqSkillCatalogSubmit {
        skill_id: skill.id,
        submit_action: "new".to_string(),
        existing_catalog_id: 0,
    };

    match crate::skill_api::catalog_submit(&ctx.server_url, &ctx.session_key, req).await {
        Ok(res) => {
            info!(
                skill_id = skill.id,
                status = %res.status,
                "auto-submit result: {}",
                res.message
            );
        }
        Err(e) => {
            warn!(skill_id = skill.id, err = %e, "auto-submit failed");
        }
    }
}
