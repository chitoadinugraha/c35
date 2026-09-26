use chrono::Utc;

use c35_ctx::Ctx;
use c35_proto::{ReqSessionInit, ResSessionInit, ResSync};
use c35_wire::WireResult;

use crate::{
    identity_client_put::identity_client_put,
    identity_geo::{identity_geo_ip_apply, GeoHint},
    identity_nav_counts::identity_nav_counts,
    identity_prefs_sync::identity_prefs_sync,
    identity_profile_get::identity_profile_get,
};

pub async fn session_init(ctx: &Ctx, req: ReqSessionInit, geo: Option<&GeoHint>) -> WireResult<ResSessionInit> {
    let client_set_location = !req.location_city.trim().is_empty()
        || !req.location_region.trim().is_empty()
        || !req.location_country.trim().is_empty();
    let _ = identity_prefs_sync(
        &ctx.pool,
        ctx.caller_iid,
        &req.locale,
        &req.tz,
        &req.location_city,
        &req.location_region,
        &req.location_country,
        &req.location_source,
    )
    .await;
    if !client_set_location {
        if let Some(g) = geo {
            let _ = identity_geo_ip_apply(&ctx.pool, ctx.caller_iid, g).await;
        }
    }
    let _ = identity_client_put(
        &ctx.pool,
        ctx.caller_iid,
        &req.dv,
        &req.client_id,
        req.platform,
        req.app_build,
        &req.app_version_name,
    )
    .await;
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
        mentions: None,
        hints: None,
    })
}
