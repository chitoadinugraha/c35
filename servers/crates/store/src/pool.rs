use anyhow::{Context, Result};
use sqlx::postgres::{PgConnectOptions, PgPoolOptions};
use sqlx::{ConnectOptions, PgPool};
use std::str::FromStr;
use std::time::Duration;
use tracing::log::LevelFilter;

use crate::migrate::{dsn, env_load};

#[derive(Debug, Clone)]
pub struct PoolConfig {
    pub max_connections: u32,
    pub min_connections: u32,
    pub acquire_timeout: Duration,
    pub acquire_slow_threshold: Duration,
    pub idle_timeout: Duration,
    pub max_lifetime: Duration,
    pub slow_statement: Duration,
    pub test_before_acquire: bool,
}

impl PoolConfig {
    pub fn from_env() -> Self {
        let max = env_u32("PG_MAX_CONNECTIONS", 24);
        let min = env_u32("PG_MIN_CONNECTIONS", 4).min(max);
        Self {
            max_connections: max,
            min_connections: min,
            acquire_timeout: Duration::from_secs(env_u64("PG_ACQUIRE_TIMEOUT_SECS", 30)),
            acquire_slow_threshold: Duration::from_millis(env_u64("PG_SLOW_ACQUIRE_MS", 3_000)),
            idle_timeout: Duration::from_secs(env_u64("PG_IDLE_TIMEOUT_SECS", 600)),
            max_lifetime: Duration::from_secs(env_u64("PG_MAX_LIFETIME_SECS", 1_800)),
            slow_statement: Duration::from_millis(env_u64("PG_SLOW_STATEMENT_MS", 1_000)),
            test_before_acquire: env_bool("PG_TEST_BEFORE_ACQUIRE", true),
        }
    }
}

pub async fn pool_connect() -> Result<PgPool> {
    env_load();
    pool_connect_url(&dsn()?).await
}

pub async fn pool_connect_url(url: &str) -> Result<PgPool> {
    let cfg = PoolConfig::from_env();
    let connect_options = PgConnectOptions::from_str(url)
        .context("parse postgres url")?
        .log_slow_statements(LevelFilter::Warn, cfg.slow_statement);
    let pool = PgPoolOptions::new()
        .max_connections(cfg.max_connections)
        .min_connections(cfg.min_connections)
        .acquire_timeout(cfg.acquire_timeout)
        .acquire_slow_threshold(cfg.acquire_slow_threshold)
        .acquire_slow_level(LevelFilter::Warn)
        .idle_timeout(Some(cfg.idle_timeout))
        .max_lifetime(Some(cfg.max_lifetime))
        .test_before_acquire(cfg.test_before_acquire)
        .connect_with(connect_options)
        .await
        .context("connect yugabyte")?;
    tracing::info!(
        max_connections = cfg.max_connections,
        min_connections = cfg.min_connections,
        acquire_timeout_secs = cfg.acquire_timeout.as_secs(),
        slow_acquire_ms = cfg.acquire_slow_threshold.as_millis(),
        slow_statement_ms = cfg.slow_statement.as_millis(),
        idle_timeout_secs = cfg.idle_timeout.as_secs(),
        max_lifetime_secs = cfg.max_lifetime.as_secs(),
        test_before_acquire = cfg.test_before_acquire,
        "db pool configured"
    );
    Ok(pool)
}

/// Warn when every pooled connection is checked out (helps diagnose slow acquires).
pub fn pool_monitor_spawn(pool: PgPool) {
    tokio::spawn(async move {
        let mut interval = tokio::time::interval(Duration::from_secs(15));
        loop {
            interval.tick().await;
            let size = pool.size();
            let idle = pool.num_idle();
            if size > 0 && idle == 0 {
                tracing::warn!(
                    pool_size = size,
                    pool_idle = idle,
                    "db pool saturated — all connections in use; check sqlx::query slow statement logs"
                );
            }
        }
    });
}

fn env_u32(key: &str, default: u32) -> u32 {
    std::env::var(key)
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(default)
}

fn env_u64(key: &str, default: u64) -> u64 {
    std::env::var(key)
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(default)
}

fn env_bool(key: &str, default: bool) -> bool {
    std::env::var(key)
        .ok()
        .map(|s| matches!(s.to_ascii_lowercase().as_str(), "1" | "true" | "yes" | "on"))
        .unwrap_or(default)
}
