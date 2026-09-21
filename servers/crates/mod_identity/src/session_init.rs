use chrono::Utc;

use c35_ctx::Ctx;
use c35_proto::{ReqSessionInit, ResSessionInit, ResSync};
use c35_wire::WireResult;

use crate::{identity_nav_counts::identity_nav_counts, identity_profile_get::identity_profile_get};

pub async fn session_init(ctx: &Ctx, req: ReqSessionInit) -> WireResult<ResSessionInit> {
    let profile = identity_profile_get(ctx).await?;
    let billing = c35_mod_billing::billing_account_get(ctx, profile.billing_iid).await?;
    let nav = identity_nav_counts(ctx).await?;
    let now_ms = Utc::now().timestamp_millis();

    Ok(ResSessionInit {
        server_time_ms: now_ms,
        since_ms: req.since_ms,
        session_id: format!("s{}", ctx.caller_iid),
        profile: Some(profile),
        billing: Some(billing),
        nav: Some(nav),
        settings_json: "{}".into(),
        inbox_chats: vec![],
        inbox_members: vec![],
        sync: if req.since_ms > 0 {
            Some(ResSync {
                since_ms: req.since_ms,
                server_time_ms: now_ms,
                ..Default::default()
            })
        } else {
            None
        },
        models: vec![],
    })
}
