use std::sync::{Arc, OnceLock};

use anyhow::{Context, Result};
use c35_store::PoolConfig;
use tokio::sync::{OwnedSemaphorePermit, Semaphore};
use tracing::info;

use super::checkpoint::PROMPT_RUN_MAX_CONCURRENT_DEFAULT;

static PROMPT_RUN_SEM: OnceLock<Arc<Semaphore>> = OnceLock::new();

pub fn prompt_run_max_concurrent_env_set() -> bool {
    std::env::var("PROMPT_RUN_MAX_CONCURRENT")
        .ok()
        .is_some_and(|s| !s.trim().is_empty())
}

pub fn prompt_run_max_concurrent_requested() -> usize {
    std::env::var("PROMPT_RUN_MAX_CONCURRENT")
        .ok()
        .and_then(|s| s.parse().ok())
        .filter(|n| *n >= 1)
        .unwrap_or(PROMPT_RUN_MAX_CONCURRENT_DEFAULT)
}

pub fn prompt_run_max_concurrent() -> usize {
    let cap = PoolConfig::from_env().prompt_run_concurrency_cap();
    let requested = if prompt_run_max_concurrent_env_set() {
        prompt_run_max_concurrent_requested()
    } else {
        PROMPT_RUN_MAX_CONCURRENT_DEFAULT.min(cap)
    };
    requested.min(cap).max(1)
}

pub fn prompt_run_concurrency_init() {
    let max = prompt_run_max_concurrent();
    let pool_cfg = PoolConfig::from_env();
    let requested = prompt_run_max_concurrent_requested();
    if prompt_run_max_concurrent_env_set() && requested > max {
        tracing::warn!(
            requested,
            effective = max,
            pool_max = pool_cfg.max_connections,
            reserved = pool_cfg.prompt_run_reserved_connections(),
            "[c35:prompt_run] PROMPT_RUN_MAX_CONCURRENT capped for SQLx pool headroom"
        );
    }
    let _ = PROMPT_RUN_SEM.set(Arc::new(Semaphore::new(max)));
    info!(
        max_concurrent = max,
        pool_max = pool_cfg.max_connections,
        "[c35:prompt_run] shared concurrency limit configured"
    );
}

fn sem() -> Arc<Semaphore> {
    PROMPT_RUN_SEM
        .get_or_init(|| Arc::new(Semaphore::new(prompt_run_max_concurrent())))
        .clone()
}

pub async fn prompt_run_concurrency_acquire() -> Result<OwnedSemaphorePermit> {
    sem()
        .acquire_owned()
        .await
        .context("prompt_run concurrency semaphore closed")
}