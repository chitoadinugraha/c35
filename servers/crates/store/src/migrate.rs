use anyhow::{Context, Result};
use sqlx::postgres::PgPoolOptions;
use sqlx::{Error as SqlxError, PgPool};
use std::future::Future;
use std::path::{Path, PathBuf};
use std::time::Duration;
use tokio::sync::OnceCell;

use crate::schema::SCHEMA_APPLY_ORDER;

const MIGRATE_LOCK_KEY: i64 = 9035;

static SCHEMA_READY: OnceCell<()> = OnceCell::const_new();

const BOOT_PATCH_SQL: &str = r"
ALTER TABLE ai.chat_msg ADD COLUMN IF NOT EXISTS cost_usd NUMERIC(12, 6) NOT NULL DEFAULT 0;
ALTER TABLE ai.chat_msg ADD COLUMN IF NOT EXISTS error_text TEXT NOT NULL DEFAULT '';
";

pub async fn pool_connect() -> Result<PgPool> {
    env_load();
    let url = dsn()?;
    let max = std::env::var("PG_MAX_CONNECTIONS")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(8);
    let acquire_secs = std::env::var("PG_ACQUIRE_TIMEOUT_SECS")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(30);
    let pool = PgPoolOptions::new()
        .max_connections(max)
        .acquire_timeout(Duration::from_secs(acquire_secs))
        .connect_lazy(&url)
        .context("connect yugabyte")?;
    sqlx::query("SELECT 1")
        .execute(&pool)
        .await
        .context("connect yugabyte")?;
    Ok(pool)
}

pub fn missing_table(err: &SqlxError) -> bool {
    match err {
        SqlxError::Database(db) => {
            db.code().as_deref() == Some("42P01")
                || db.message().contains("does not exist")
        }
        _ => false,
    }
}

pub fn missing_schema(err: &SqlxError) -> bool {
    match err {
        SqlxError::Database(db) => {
            matches!(db.code().as_deref(), Some("42P01") | Some("42703"))
                || db.message().contains("does not exist")
        }
        _ => false,
    }
}

pub async fn db_retry<T, F, Fut>(pool: &PgPool, mut f: F) -> Result<T, SqlxError>
where
    F: FnMut() -> Fut,
    Fut: Future<Output = Result<T, SqlxError>>,
{
    if SCHEMA_READY.get().is_some() {
        return f().await;
    }
    match f().await {
        ok @ Ok(_) => {
            let _ = SCHEMA_READY.set(());
            ok
        }
        Err(e) if missing_schema(&e) => {
            migrate_once(pool).await.map_err(|e| {
                SqlxError::Configuration(format!("schema migrate: {e}").into())
            })?;
            let _ = SCHEMA_READY.set(());
            f().await
        }
        Err(e) => Err(e),
    }
}

async fn migrate_once(pool: &PgPool) -> Result<()> {
    SCHEMA_READY
        .get_or_try_init(|| async { migrate_apply(pool).await })
        .await
        .map(|_| ())
}

/// Safe idempotent column patches — runs on every boot under advisory lock.
pub async fn migrate_boot(pool: &PgPool) -> Result<()> {
    migrate_locked(pool, "boot", BOOT_PATCH_SQL).await
}

pub async fn migrate_apply(pool: &PgPool) -> Result<()> {
    tracing::info!("applying c35 schemas");
    for (label, sql) in SCHEMA_APPLY_ORDER {
        migrate_locked(pool, label, sql).await?;
    }
    Ok(())
}

async fn migrate_locked(pool: &PgPool, label: &str, sql: &str) -> Result<()> {
    let mut conn = pool.acquire().await?;
    sqlx::query("SELECT pg_advisory_lock($1)")
        .bind(MIGRATE_LOCK_KEY)
        .execute(&mut *conn)
        .await?;
    let out = schema_apply(&mut conn, sql, label).await;
    let _ = sqlx::query("SELECT pg_advisory_unlock($1)")
        .bind(MIGRATE_LOCK_KEY)
        .execute(&mut *conn)
        .await;
    out
}

async fn schema_apply(conn: &mut sqlx::pool::PoolConnection<sqlx::Postgres>, sql: &str, label: &str) -> Result<()> {
    for stmt in sql_stmts(sql) {
        exec_retry(conn, &stmt, label).await?;
    }
    tracing::info!(schema = label, "applied");
    Ok(())
}

async fn exec_retry(conn: &mut sqlx::pool::PoolConnection<sqlx::Postgres>, stmt: &str, label: &str) -> Result<()> {
    let mut delay = Duration::from_millis(100);
    for attempt in 0..8 {
        match sqlx::query(stmt).execute(&mut **conn).await {
            Ok(_) => return Ok(()),
            Err(e) if schema_stmt_skip(&e) => return Ok(()),
            Err(e) if schema_stmt_retry(&e) && attempt < 7 => {
                tracing::warn!(
                    schema = label,
                    attempt = attempt + 1,
                    err = %e,
                    "schema stmt retry"
                );
                tokio::time::sleep(delay).await;
                delay = delay.saturating_mul(2);
            }
            Err(e) => {
                return Err(e).with_context(|| {
                    format!(
                        "{label}: {}",
                        stmt.chars().take(100).collect::<String>()
                    )
                });
            }
        }
    }
    Ok(())
}

fn schema_stmt_skip(err: &SqlxError) -> bool {
    match err {
        SqlxError::Database(db) => {
            let msg = db.message().to_lowercase();
            msg.contains("already exists")
                || msg.contains("duplicate")
                || (msg.contains("does not exist") && msg.contains("drop"))
        }
        _ => false,
    }
}

fn schema_stmt_retry(err: &SqlxError) -> bool {
    match err {
        SqlxError::Database(db) => {
            db.code().as_deref() == Some("40001")
                || db.message().to_lowercase().contains("serialize")
                || db.message().to_lowercase().contains("concurrent update")
        }
        _ => false,
    }
}

fn sql_stmts(sql: &str) -> Vec<String> {
    let mut cur = String::new();
    let mut out = Vec::new();
    let mut in_dollar_block = false;
    for raw in sql.lines() {
        let line = raw.trim();
        if line.is_empty() || line.starts_with("--") {
            continue;
        }
        if !in_dollar_block && line.to_ascii_uppercase().starts_with("DO $$") {
            in_dollar_block = true;
        }
        cur.push_str(line);
        cur.push('\n');
        if in_dollar_block {
            if line.ends_with("$$;") || line.to_ascii_uppercase().ends_with("END $$;") {
                in_dollar_block = false;
                push_stmt(&mut out, &mut cur);
            }
        } else if line.ends_with(';') {
            push_stmt(&mut out, &mut cur);
        }
    }
    if !cur.trim().is_empty() {
        push_stmt(&mut out, &mut cur);
    }
    out
}

fn push_stmt(out: &mut Vec<String>, cur: &mut String) {
    let s = cur.trim().trim_end_matches(';').trim().to_string();
    cur.clear();
    if !s.is_empty() {
        out.push(s);
    }
}

pub fn env_load() {
    for p in env_files() {
        let _ = dotenvy::from_path(&p);
    }
    std::env::set_var("YB_DATABASE", "c35");
}

fn env_files() -> Vec<PathBuf> {
    let mut out = vec![PathBuf::from(r"D:\alienai_proto\cluster\.env.local")];
    if let Some(root) = repo_root() {
        out.push(root.join("servers/server_ai/.env.local"));
        out.push(root.join(".env.local"));
    }
    out.extend([
        PathBuf::from("servers/server_ai/.env.local"),
        PathBuf::from("server_ai/.env.local"),
        PathBuf::from(".env.local"),
    ]);
    if let Ok(man) = std::env::var("CARGO_MANIFEST_DIR") {
        out.push(Path::new(&man).join(".env.local"));
        out.push(Path::new(&man).join("../../server_ai/.env.local"));
    }
    out
}

fn repo_root() -> Option<PathBuf> {
    if let Ok(exe) = std::env::current_exe() {
        let mut dir = exe.parent()?.to_path_buf();
        for _ in 0..8 {
            if dir.join("servers").join("Cargo.toml").exists() {
                return Some(dir);
            }
            dir = dir.parent()?.to_path_buf();
        }
    }
    std::env::current_dir()
        .ok()
        .filter(|d| d.join("servers").join("Cargo.toml").exists())
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

    #[test]
    fn sql_stmts_splits_do_dollar_block_as_one_statement() {
        let sql = r"
        CREATE TABLE t (id INT);
        DO $$
        BEGIN
            IF TRUE THEN
                NULL;
            END IF;
        END $$;
        INSERT INTO t VALUES (1);
        ";
        let stmts = super::sql_stmts(sql);
        assert_eq!(stmts.len(), 3);
        assert!(stmts[0].starts_with("CREATE TABLE"));
        assert!(stmts[1].starts_with("DO $$"));
        assert!(stmts[1].contains("END $$"));
        assert!(stmts[2].starts_with("INSERT"));
    }
}
