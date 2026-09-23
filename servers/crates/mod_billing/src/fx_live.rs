use std::sync::atomic::{AtomicI64, Ordering};

use anyhow::Result;
use async_nats::Client;
use c35_proto::FetchFxPush;
use futures_util::StreamExt;
use prost::Message;
use sqlx::{PgPool, Row};
use tracing::{info, warn};

use crate::fetch_fx::{FX_DEFAULT_MICRO, FX_SUBJECT};

static FX_MICRO: AtomicI64 = AtomicI64::new(FX_DEFAULT_MICRO);
static FX_RATE_ID: AtomicI64 = AtomicI64::new(1);

pub fn fx_live_micro_per_usd() -> i64 {
    let v = FX_MICRO.load(Ordering::Relaxed);
    if v > 0 { v } else { FX_DEFAULT_MICRO }
}

pub fn fx_live_rate_id() -> i64 {
    FX_RATE_ID.load(Ordering::Relaxed)
}

pub fn fx_live_idr_per_usd() -> f64 {
    fx_live_micro_per_usd() as f64 / 1_000_000.0
}

pub fn fx_live_apply_push(push: &FetchFxPush) {
    if push.micro_per_usd > 0 {
        FX_MICRO.store(push.micro_per_usd, Ordering::Relaxed);
    }
    if push.fx_rate_id > 0 {
        FX_RATE_ID.store(push.fx_rate_id, Ordering::Relaxed);
    }
}

pub async fn fx_live_init(pool: &PgPool) -> Result<()> {
    let row = sqlx::query(
        "SELECT id, micro_per_usd FROM ai.billing_fx_rate WHERE currency = 'IDR' ORDER BY effective_from DESC LIMIT 1",
    )
    .fetch_optional(pool)
    .await?;
    if let Some(r) = row {
        let id: i64 = r.get("id");
        let micro: i64 = r.get("micro_per_usd");
        FX_MICRO.store(micro, Ordering::Relaxed);
        FX_RATE_ID.store(id, Ordering::Relaxed);
        info!(fx_rate_id = id, micro_per_usd = micro, "fx_live loaded from db");
    }
    Ok(())
}

pub fn fx_live_subscribe(pool: PgPool, nats: Client) {
    tokio::spawn(async move {
        let mut sub = match nats.subscribe(FX_SUBJECT).await {
            Ok(s) => s,
            Err(e) => {
                warn!(error = %e, "fx_live nats subscribe failed");
                return;
            }
        };
        while let Some(msg) = sub.next().await {
            if let Ok(push) = FetchFxPush::decode(msg.payload.as_ref()) {
                fx_live_apply_push(&push);
                info!(
                    fx_rate_id = push.fx_rate_id,
                    micro_per_usd = push.micro_per_usd,
                    published_idr = push.published_idr_per_usd,
                    "fx_live updated"
                );
            }
            let _ = pool;
        }
    });
}
