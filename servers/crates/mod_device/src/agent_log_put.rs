use async_nats::Client;
use c35_mod_event::{event_emit, kinds, EventCtx};
use serde_json::json;
use sqlx::PgPool;

pub async fn agent_log_put(
    pool: &PgPool,
    nats: Option<&Client>,
    device_iid: i64,
    owner_iid: i64,
    _kind: &str,
    topic: &str,
    text: &str,
    meta: Option<serde_json::Value>,
) -> Result<i64, String> {
    let event_kind = match (topic, text) {
        ("agent.ws", "connected") | ("connected", _) => kinds::DEVICE_AGENT_CONNECTED,
        ("agent.ws", "disconnected") | ("disconnected", _) => kinds::DEVICE_AGENT_DISCONNECTED,
        ("agent.unpair", "unpaired") | (_, "unpaired") => kinds::DEVICE_UNPAIRED,
        _ => kinds::DEVICE_AGENT_CONNECTED,
    };
    let mut ctx = EventCtx::for_owner(owner_iid, "c35-server");
    ctx.device_iid = Some(device_iid);
    let meta = meta.unwrap_or_else(|| json!({ "topic": topic, "detail": text }));
    event_emit(pool, nats, ctx, event_kind, meta)
        .await
        .map_err(|e| e.to_string())
}
