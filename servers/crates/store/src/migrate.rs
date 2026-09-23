use anyhow::{Context, Result};
use sqlx::{Error as SqlxError, PgPool, Row};
use std::collections::BTreeSet;
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
ALTER TABLE ai.billing_account ADD COLUMN IF NOT EXISTS commission_pending_usd NUMERIC(12, 4) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_account ADD COLUMN IF NOT EXISTS commission_pending_idr NUMERIC(14, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_topup_request DROP CONSTRAINT IF EXISTS chk_billing_topup_status;
ALTER TABLE ai.billing_topup_request ADD CONSTRAINT chk_billing_topup_status CHECK (
    status IN ('pending', 'pending_review', 'settled', 'rejected', 'cancelled', 'expired', 'failed')
);
ALTER TABLE site.tx_item ADD COLUMN IF NOT EXISTS owner_iid BIGINT NOT NULL DEFAULT 0;
ALTER TABLE site.tx_item ADD COLUMN IF NOT EXISTS obj_id BIGINT NOT NULL DEFAULT 0;
ALTER TABLE site.product ADD COLUMN IF NOT EXISTS obj_id BIGINT NOT NULL DEFAULT 0;
CREATE INDEX IF NOT EXISTS idx_tx_owner_time_ok ON site.tx (owner_iid, time_ts DESC) WHERE deleted_ts IS NULL AND state = 'ok';
CREATE INDEX IF NOT EXISTS idx_tx_item_owner_obj ON site.tx_item (owner_iid, obj_id) WHERE deleted_ts IS NULL;
CREATE INDEX IF NOT EXISTS idx_tx_item_obj ON site.tx_item (obj_id) WHERE obj_id > 0 AND deleted_ts IS NULL;
ALTER TABLE ai.consumption_item ADD COLUMN IF NOT EXISTS obj_id BIGINT NOT NULL DEFAULT 0;
CREATE INDEX IF NOT EXISTS idx_consumption_item_obj ON ai.consumption_item (owner_iid, obj_id) WHERE obj_id > 0 AND deleted_ts IS NULL;
CREATE INDEX IF NOT EXISTS idx_log_owner_created_desc ON ai.log (owner_iid, created_ts DESC, id DESC) WHERE deleted_ts IS NULL;
CREATE INDEX IF NOT EXISTS idx_log_created_desc ON ai.log (created_ts DESC, id DESC) WHERE deleted_ts IS NULL;
CREATE INDEX IF NOT EXISTS idx_log_owner_req_created ON ai.log (owner_iid, req_id, created_ts DESC) WHERE deleted_ts IS NULL AND req_id <> '';
CREATE INDEX IF NOT EXISTS idx_chat_msg_owner_created_desc ON ai.chat_msg (owner_iid, created_ts DESC, id DESC) WHERE deleted_ts IS NULL;
CREATE INDEX IF NOT EXISTS idx_chat_msg_owner_req ON ai.chat_msg (owner_iid, req_id) WHERE deleted_ts IS NULL AND req_id <> '';
";

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

#[derive(Debug)]
pub struct MigrateAuditReport {
    pub expected: BTreeSet<String>,
    pub present: BTreeSet<String>,
    pub missing: Vec<String>,
    pub extra: Vec<String>,
}

impl MigrateAuditReport {
    pub fn print(&self) {
        println!("migrate audit: {} expected, {} present", self.expected.len(), self.present.len());
        if self.missing.is_empty() {
            println!("missing: none");
        } else {
            println!("missing ({}):", self.missing.len());
            for t in &self.missing {
                println!("  - {t}");
            }
        }
        if !self.extra.is_empty() {
            println!("extra (not in schema files, {}):", self.extra.len());
            for t in &self.extra {
                println!("  + {t}");
            }
        }
    }
}

pub fn schema_expected_tables() -> BTreeSet<String> {
    let mut out = BTreeSet::new();
    for (_, sql) in SCHEMA_APPLY_ORDER {
        for line in sql.lines() {
            let upper = line.to_uppercase();
            if !upper.contains("CREATE TABLE") {
                continue;
            }
            let Some(rest) = line.split("CREATE TABLE").nth(1) else {
                continue;
            };
            let name = rest
                .trim()
                .trim_start_matches("IF NOT EXISTS")
                .trim()
                .split_whitespace()
                .next()
                .unwrap_or("")
                .trim_end_matches('(')
                .trim();
            if name.contains('.') {
                out.insert(name.to_string());
            }
        }
    }
    out
}

pub async fn migrate_audit(pool: &PgPool) -> Result<MigrateAuditReport> {
    let expected = schema_expected_tables();
    let rows = sqlx::query(
        "SELECT table_schema, table_name FROM information_schema.tables WHERE table_schema IN ('ai', 'site') AND table_type = 'BASE TABLE' ORDER BY 1, 2",
    )
        .fetch_all(pool)
        .await?;
    let present = rows
        .iter()
        .map(|r| format!("{}.{}", r.get::<String, _>(0), r.get::<String, _>(1)))
        .collect::<BTreeSet<_>>();
    let missing = expected.difference(&present).cloned().collect::<Vec<_>>();
    let extra = present.difference(&expected).cloned().collect::<Vec<_>>();
    Ok(MigrateAuditReport {
        expected,
        present,
        missing,
        extra,
    })
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

pub fn sql_stmts(sql: &str) -> Vec<String> {
    let mut cur = String::new();
    let mut out = Vec::new();
    let mut in_dollar_block = false;
    for raw in sql.lines() {
        let line = raw.trim();
        if line.is_empty() || line.starts_with("--") {
            continue;
        }
        if !in_dollar_block && dollar_block_opens(line) {
            in_dollar_block = true;
        }
        cur.push_str(line);
        cur.push('\n');
        if in_dollar_block {
            if dollar_block_closes(line) {
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

fn dollar_block_opens(line: &str) -> bool {
    let upper = line.to_ascii_uppercase();
    upper.starts_with("DO $$") || line.contains(" AS $$")
}

fn dollar_block_closes(line: &str) -> bool {
    if !line.contains("$$") {
        return false;
    }
    if dollar_block_opens(line) {
        return false;
    }
    line.contains("$$ LANGUAGE") || line.ends_with("$$;") || line.to_ascii_uppercase().ends_with("END $$;")
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

pub(crate) fn dsn() -> Result<String> {
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
    fn schema_expected_tables_includes_prompt_run_and_hint() {
        let tables = super::schema_expected_tables();
        assert!(tables.contains("ai.prompt_run"));
        assert!(tables.contains("ai.hint"));
        assert!(tables.contains("ai.object_normalizer"));
        assert!(tables.contains("site.render"));
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

    #[test]
    fn sql_stmts_splits_create_function_dollar_block() {
        let sql = r"
        CREATE TABLE t (id INT);
        CREATE OR REPLACE FUNCTION ai.slug_norm(raw TEXT) RETURNS TEXT AS $$
        BEGIN
            RETURN raw;
        END;
        $$ LANGUAGE plpgsql IMMUTABLE;
        INSERT INTO t VALUES (1);
        ";
        let stmts = super::sql_stmts(sql);
        assert_eq!(stmts.len(), 3);
        assert!(stmts[1].starts_with("CREATE OR REPLACE FUNCTION"));
        assert!(stmts[1].contains("$$ LANGUAGE"));
    }
}
