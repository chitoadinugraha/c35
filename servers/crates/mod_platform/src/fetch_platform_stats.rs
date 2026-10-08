use std::time::Duration;

use anyhow::{Context, Result};
use async_trait::async_trait;
use c35_mod_fetch::{encode_push, FetchCtx, FetchOutcome, FetchTask};
use c35_nats::{stats_kv_ensure, stats_kv_key_platform_user_count, stats_kv_put_bytes};
use c35_proto::FetchPlatformStatsPush;
use chrono::Utc;

pub const PLATFORM_STATS_SUBJECT: &str = "c35.fetch.platform.stats";

pub struct PlatformUserCountFetchTask;

async fn count_active_users(pool: &sqlx::PgPool) -> Result<i64> {
    sqlx::query_scalar(
        "SELECT COUNT(*)::bigint FROM ai.identity WHERE kind = 'user' AND deleted_ts IS NULL",
    )
    .fetch_one(pool)
    .await
    .context("platform user count")
}

fn env_u64(key: &str, default: u64) -> u64 {
    std::env::var(key)
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(default)
}

#[async_trait]
impl FetchTask for PlatformUserCountFetchTask {
    fn name(&self) -> &'static str {
        "platform_user_count"
    }

    fn interval(&self) -> Duration {
        Duration::from_secs(env_u64("PLATFORM_USER_COUNT_INTERVAL_SECS", 60))
    }

    async fn run(&self, ctx: &FetchCtx) -> Result<FetchOutcome> {
        let count = count_active_users(&ctx.pool).await?;
        let push = FetchPlatformStatsPush {
            platform_user_count: count,
            ts_ms: Utc::now().timestamp_millis(),
        };
        let payload = encode_push(&push);
        if let Ok(store) = stats_kv_ensure(&ctx.nats).await {
            let key = stats_kv_key_platform_user_count();
            if let Err(e) = stats_kv_put_bytes(&store, key, &payload).await {
                tracing::warn!(error = %e, key, "platform_user_count KV put failed");
            }
        }
        Ok(FetchOutcome {
            changed: true,
            nats_subject: Some(PLATFORM_STATS_SUBJECT),
            nats_payload: Some(payload),
        })
    }
}
