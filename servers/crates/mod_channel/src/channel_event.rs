use async_nats::Client;
use c35_mod_event::{event_emit, kinds, EventCtx};
use serde_json::json;
use sqlx::PgPool;

pub async fn channel_connected_emit(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    platform: &str,
    channel_id: &str,
    meta: serde_json::Value,
) {
    let mut ctx = EventCtx::for_owner(owner_iid, "c35-server");
    ctx.channel_platform = Some(platform.to_string());
    ctx.channel_id = Some(channel_id.to_string());
    let _ = event_emit(pool, nats, ctx, kinds::CHANNEL_CONNECTED, meta).await;
}

pub async fn channel_disconnected_emit(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    platform: &str,
    channel_id: &str,
    meta: serde_json::Value,
) {
    let mut ctx = EventCtx::for_owner(owner_iid, "c35-server");
    ctx.channel_platform = Some(platform.to_string());
    ctx.channel_id = Some(channel_id.to_string());
    let mut m = meta;
    if m.is_null() {
        m = json!({});
    }
    let _ = event_emit(pool, nats, ctx, kinds::CHANNEL_DISCONNECTED, m).await;
}
