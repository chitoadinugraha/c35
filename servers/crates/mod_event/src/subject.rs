use crate::catalog::{EventDef, EventScope};

use super::EventCtx;

pub fn subject_fill(def: &EventDef, ctx: &EventCtx) -> String {
    match def.scope {
        EventScope::User => format!("c35.user.{}.ev.{}", ctx.owner_iid, def.slug),
        EventScope::Device => {
            let device_iid = ctx.device_iid.unwrap_or(0);
            format!("c35.ev.device.{}.{}", device_iid, def.slug)
        }
        EventScope::Channel => {
            let platform = ctx.channel_platform.as_deref().unwrap_or("unknown");
            let channel_id = ctx.channel_id.as_deref().unwrap_or("unknown");
            format!(
                "c35.ev.channel.{}.{}.{}.{}",
                ctx.owner_iid,
                platform,
                channel_id,
                def.slug
            )
        }
    }
}
