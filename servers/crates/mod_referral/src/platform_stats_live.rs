use std::sync::atomic::{AtomicI64, Ordering};

use anyhow::Result;
use async_nats::Client;
use c35_nats::{
    stats_kv_ensure, stats_kv_get_bytes, stats_kv_key_platform_user_count,
};
use c35_proto::FetchPlatformStatsPush;
use futures_util::StreamExt;
use prost::Message;
use sqlx::PgPool;
use tracing::{info, warn};

pub const PLATFORM_STATS_SUBJECT: &str = "c35.fetch.platform.stats";

static PLATFORM_USER_COUNT: AtomicI64 = AtomicI64::new(0);

pub fn platform_stats_live_user_count() -> i64 {
    PLATFORM_USER_COUNT.load(Ordering::Relaxed)
}

pub fn platform_stats_live_apply(push: &FetchPlatformStatsPush) {
    if push.platform_user_count >= 0 {
        PLATFORM_USER_COUNT.store(push.platform_user_count, Ordering::Relaxed);
    }
}

async fn platform_user_count_sql(pool: &PgPool) -> Result<i64> {
    sqlx::query_scalar(
        "SELECT COUNT(*)::bigint FROM ai.identity WHERE kind = 'user' AND deleted_ts IS NULL",
    )
    .fetch_one(pool)
    .await
    .map_err(|e| anyhow::anyhow!(e))
}

pub async fn platform_stats_live_init(pool: &PgPool, nats: Option<&Client>) -> Result<()> {
    if let Some(client) = nats {
        if let Ok(store) = stats_kv_ensure(client).await {
            let key = stats_kv_key_platform_user_count();
            if let Some(bytes) = stats_kv_get_bytes(&store, key).await {
                if let Ok(push) = FetchPlatformStatsPush::decode(bytes.as_ref()) {
                    platform_stats_live_apply(&push);
                    info!(
                        platform_user_count = push.platform_user_count,
                        ts_ms = push.ts_ms,
                        "platform_stats_live loaded from KV"
                    );
                    return Ok(());
                }
            }
        }
    }
    let count = platform_user_count_sql(pool).await?;
    PLATFORM_USER_COUNT.store(count, Ordering::Relaxed);
    info!(platform_user_count = count, "platform_stats_live loaded from SQL");
    Ok(())
}

pub fn platform_stats_live_subscribe(nats: Client) {
    tokio::spawn(async move {
        let mut sub = match nats.subscribe(PLATFORM_STATS_SUBJECT).await {
            Ok(s) => s,
            Err(e) => {
                warn!(error = %e, "platform_stats_live nats subscribe failed");
                return;
            }
        };
        while let Some(msg) = sub.next().await {
            if let Ok(push) = FetchPlatformStatsPush::decode(msg.payload.as_ref()) {
                platform_stats_live_apply(&push);
                info!(
                    platform_user_count = push.platform_user_count,
                    ts_ms = push.ts_ms,
                    "platform_stats_live updated"
                );
            }
        }
    });
}
