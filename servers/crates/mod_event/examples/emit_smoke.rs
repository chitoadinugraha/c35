use c35_mod_event::{event_emit, kinds, EventCtx};
use c35_nats::connect as nats_connect;
use c35_store::pool_connect;
use serde_json::json;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenvy::dotenv().ok();
    dotenvy::from_filename("servers/server_ai/.env.local").ok();
    dotenvy::from_filename(".env.local").ok();
    let pool = pool_connect().await?;
    let nats = nats_connect().await.ok_or_else(|| anyhow::anyhow!("NATS unavailable"))?;
    let owner: i64 = std::env::var("C35_EVENT_SMOKE_OWNER")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(33_000);
    let mut ctx = EventCtx::for_owner(owner, "c35-smoke");
    ctx.name = "Event smoke".into();
    let id = event_emit(
        &pool,
        Some(&nats),
        ctx,
        kinds::USER_CONNECTED,
        json!({ "source": "emit_smoke", "smoke": true }),
    )
    .await?;
    println!(
        "event_emit ok id={} owner={} subject=c35.user.{}.ev.connected",
        id,
        owner,
        owner
    );
    Ok(())
}