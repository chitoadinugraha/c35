use std::time::Duration;

use anyhow::Result;
use async_trait::async_trait;
use c35_mod_fetch::{encode_push, FetchCtx, FetchOutcome, FetchTask};
use c35_proto::FetchLlmCatalogPush;
use chrono::Utc;
use futures_util::StreamExt;
use prost::Message;
use sqlx::PgPool;
use tracing::{info, warn};

use crate::catalog_sync::llm_catalog_sync_force;
use crate::llm_catalog::llm_catalog_reload;

pub const LLM_CATALOG_SUBJECT: &str = "c35.fetch.llm_catalog";

pub struct LlmCatalogFetchTask;

#[async_trait]
impl FetchTask for LlmCatalogFetchTask {
    fn name(&self) -> &'static str {
        "llm_catalog"
    }

    fn interval(&self) -> Duration {
        Duration::from_secs(crate::llm_catalog::SYNC_INTERVAL_SECS)
    }

    async fn run(&self, ctx: &FetchCtx) -> Result<FetchOutcome> {
        let count = llm_catalog_sync_force(&ctx.pool).await?;
        let push = FetchLlmCatalogPush {
            sync_ts_ms: Utc::now().timestamp_millis(),
            model_count: count as i32,
        };
        Ok(FetchOutcome {
            changed: true,
            nats_subject: Some(LLM_CATALOG_SUBJECT),
            nats_payload: Some(encode_push(&push)),
        })
    }
}

pub fn llm_catalog_nats_subscribe(pool: PgPool, nats: async_nats::Client) {
    tokio::spawn(async move {
        let mut sub = match nats.subscribe(LLM_CATALOG_SUBJECT).await {
            Ok(s) => s,
            Err(e) => {
                warn!(error = %e, "llm_catalog nats subscribe failed");
                return;
            }
        };
        while let Some(msg) = sub.next().await {
            if FetchLlmCatalogPush::decode(msg.payload.as_ref()).is_ok() {
                if let Err(e) = llm_catalog_reload(&pool).await {
                    warn!(error = %e, "llm_catalog_reload from nats failed");
                } else {
                    info!("llm_catalog reloaded from nats");
                }
            }
        }
    });
}

pub fn external_fetcher_enabled() -> bool {
    std::env::var("EXTERNAL_FETCHER")
        .map(|v| matches!(v.to_lowercase().as_str(), "1" | "true" | "yes"))
        .unwrap_or(false)
}
