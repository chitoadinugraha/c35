use anyhow::{Context, Result};
use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;
use std::path::{Path, PathBuf};

use crate::schema::SCHEMA_APPLY_ORDER;

pub async fn pool_connect() -> Result<PgPool> {
    env_load();
    let url = dsn()?;
    let max = std::env::var("PG_MAX_CONNECTIONS")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(24);
    PgPoolOptions::new()
        .max_connections(max)
        .acquire_timeout(std::time::Duration::from_secs(10))
        .connect(&url)
        .await
        .context("connect yugabyte")
}

pub async fn migrate_apply(pool: &PgPool) -> Result<()> {
    tracing::info!("applying c35 schemas");
    for (label, sql) in SCHEMA_APPLY_ORDER {
        schema_apply(pool, sql, label).await?;
    }
    Ok(())
}

async fn schema_apply(pool: &PgPool, sql: &str, label: &str) -> Result<()> {
    for stmt in sql_stmts(sql) {
        if let Err(e) = sqlx::query(&stmt).execute(pool).await {
            let msg = e.to_string();
            if msg.contains("already exists") || msg.contains("duplicate") {
                continue;
            }
            return Err(e).with_context(|| {
                format!(
                    "{label}: {}",
                    stmt.chars().take(100).collect::<String>()
                )
            });
        }
    }
    tracing::info!(schema = label, "applied");
    Ok(())
}

fn sql_stmts(sql: &str) -> Vec<String> {
    let mut cur = String::new();
    let mut out = Vec::new();
    for raw in sql.lines() {
        let line = raw.trim();
        if line.is_empty() || line.starts_with("--") {
            continue;
        }
        cur.push_str(line);
        cur.push('\n');
        if line.ends_with(';') {
            let s = cur.trim().trim_end_matches(';').trim().to_string();
            cur.clear();
            if !s.is_empty() {
                out.push(s);
            }
        }
    }
    if !cur.trim().is_empty() {
        out.push(cur.trim().trim_end_matches(';').trim().to_string());
    }
    out
}

fn env_load() {
    for p in env_files() {
        let _ = dotenvy::from_path(&p);
    }
    if std::env::var("YB_DATABASE").is_err() {
        std::env::set_var("YB_DATABASE", "c35");
    }
}

fn env_files() -> Vec<PathBuf> {
    let mut out = vec![
        PathBuf::from("server_ai/.env.local"),
        PathBuf::from("servers/server_ai/.env.local"),
        PathBuf::from(".env.local"),
    ];
    if let Ok(man) = std::env::var("CARGO_MANIFEST_DIR") {
        out.push(Path::new(&man).join(".env.local"));
        out.push(Path::new(&man).join("../../server_ai/.env.local"));
    }
    out
}

fn env_first(keys: &[&str]) -> Option<String> {
    keys.iter()
        .find_map(|k| std::env::var(k).ok())
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
}

fn dsn() -> Result<String> {
    if let Some(url) = env_first(&["POSTGRES_URL", "DATABASE_URL"]) {
        return Ok(url);
    }
    let host = env_first(&["YB_HOST", "PG_HOST"]).context("YB_HOST required")?;
    let port = env_first(&["YB_PORT", "PG_PORT"]).unwrap_or_else(|| "5433".into());
    let db = env_first(&["YB_DATABASE", "PG_DATABASE"]).unwrap_or_else(|| "c35".into());
    let user = env_first(&["YB_USER", "PG_USER"]).context("YB_USER required")?;
    let pass = env_first(&["YB_PASSWORD", "PG_PASSWORD"]).context("YB_PASSWORD required")?;
    let ssl = env_first(&["YB_SSLMODE", "PG_SSLMODE"]).unwrap_or_else(|| "disable".into());
    Ok(format!(
        "postgres://{}:{}@{}:{}/{}?sslmode={}",
        urlencoding::encode(&user),
        urlencoding::encode(&pass),
        host,
        port,
        db,
        ssl
    ))
}

#[cfg(test)]
mod tests {
    #[test]
    fn sql_stmts_splits() {
        let stmts = super::sql_stmts("CREATE TABLE a (id int);\nCREATE TABLE b (id int);");
        assert_eq!(stmts.len(), 2);
    }
}
