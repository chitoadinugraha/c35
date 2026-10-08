use std::sync::Arc;
use std::time::{Duration, Instant};

use reqwest::Client;
use sqlx::PgPool;
use tokio::sync::Semaphore;
use tracing::{info, warn};

use crate::config::{
    data_source_bg_batch, data_source_bg_enabled, data_source_bg_max_concurrent,
    data_source_bg_tick_sec, data_source_sync_ttl_sec,
};
use crate::store_due::sync_due_claim_batch;
use crate::sync::data_source_sync_run;

pub fn data_source_bg_spawn(pool: PgPool, http: Client) {
    if !data_source_bg_enabled() {
        info!("[c35:data_source] background sync disabled (DATA_SOURCE_BG_ENABLED)");
        return;
    }
    tokio::spawn(async move {
        let sem = Arc::new(Semaphore::new(data_source_bg_max_concurrent()));
        let http = http;
        let tick = Duration::from_secs(data_source_bg_tick_sec());
        let mut interval = tokio::time::interval(tick);
        interval.tick().await;
        loop {
            interval.tick().await;
            let ttl = data_source_sync_ttl_sec();
            let batch = data_source_bg_batch();
            let ids = match sync_due_claim_batch(&pool, ttl, batch).await {
                Ok(v) => v,
                Err(e) => {
                    warn!("[c35:data_source] bg due scan failed: {e:#}");
                    continue;
                }
            };
            if ids.is_empty() {
                continue;
            }
            info!("[c35:data_source] bg tick claimed={} reason=bg", ids.len());
            for id in ids {
                let pool = pool.clone();
                let http = http.clone();
                let sem = sem.clone();
                tokio::spawn(async move {
                    let _permit = match sem.acquire().await {
                        Ok(p) => p,
                        Err(_) => return,
                    };
                    let t0 = Instant::now();
                    match data_source_sync_run(&http, &pool, id).await {
                        Ok(()) => info!(
                            "[c35:data_source] bg done id={} duration_ms={} reason=bg",
                            id,
                            t0.elapsed().as_millis()
                        ),
                        Err(e) => warn!(
                            "[c35:data_source] bg failed id={} duration_ms={} err={e:#}",
                            id,
                            t0.elapsed().as_millis()
                        ),
                    }
                });
            }
        }
    });
}
