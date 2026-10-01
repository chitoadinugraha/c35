use anyhow::{Context, Result};
use chrono::{DateTime, Utc};
use serde_json::Value;
use sqlx::{PgPool, Row};
use c35_store::snowflake_id;

#[derive(Clone, Debug)]
pub struct DataSourceRow {
    pub id: i64,
    pub owner_iid: i64,
    pub bot_iid: Option<i64>,
    pub source_kind: String,
    pub name: String,
    pub config: Value,
}

#[derive(Clone, Debug)]
pub struct DataSourceSyncRow {
    pub data_source_id: i64,
    pub source_kind: String,
    pub snapshot_hash: String,
    pub row_count: i32,
    pub status: String,
    pub error_msg: Option<String>,
    pub synced_ts: DateTime<Utc>,
}

pub async fn data_source_list_for_bot(pool: &PgPool, bot_iid: i64) -> Result<Vec<DataSourceRow>> {
    let rows = sqlx::query(
        r#"
        SELECT id, owner_iid, bot_iid, source_kind, name, config
        FROM ai.data_source
        WHERE bot_iid = $1 AND deleted_ts IS NULL
        ORDER BY updated_ts DESC
        "#,
    )
    .bind(bot_iid)
    .fetch_all(pool)
    .await
    .context("data_source_list_for_bot")?;
    Ok(rows.into_iter().filter_map(row_to_data_source).collect())
}

pub async fn data_source_get(pool: &PgPool, id: i64) -> Result<Option<DataSourceRow>> {
    let row = sqlx::query(
        r#"
        SELECT id, owner_iid, bot_iid, source_kind, name, config
        FROM ai.data_source
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(id)
    .fetch_optional(pool)
    .await
    .context("data_source_get")?;
    Ok(row.and_then(row_to_data_source))
}

pub async fn data_source_put(
    pool: &PgPool,
    owner_iid: i64,
    id: i64,
    bot_iid: Option<i64>,
    source_kind: &str,
    name: &str,
    config: &Value,
) -> Result<i64> {
    let id = if id > 0 { id } else { snowflake_id() };
    sqlx::query(
        r#"
        INSERT INTO ai.data_source (id, owner_iid, bot_iid, source_kind, name, config, created_ts, updated_ts)
        VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
        ON CONFLICT (id) DO UPDATE SET
            bot_iid = EXCLUDED.bot_iid,
            source_kind = EXCLUDED.source_kind,
            name = EXCLUDED.name,
            config = EXCLUDED.config,
            updated_ts = NOW(),
            deleted_ts = NULL
        "#,
    )
    .bind(id)
    .bind(owner_iid)
    .bind(bot_iid)
    .bind(source_kind)
    .bind(name)
    .bind(config)
    .execute(pool)
    .await
    .context("data_source_put")?;
    Ok(id)
}

pub async fn data_source_soft_delete(pool: &PgPool, id: i64) -> Result<()> {
    sqlx::query("UPDATE ai.data_source SET deleted_ts = NOW(), updated_ts = NOW() WHERE id = $1")
        .bind(id)
        .execute(pool)
        .await
        .context("data_source_soft_delete")?;
    Ok(())
}

pub async fn sync_row_get(pool: &PgPool, data_source_id: i64) -> Result<Option<(String, i32)>> {
    let row = sqlx::query(
        "SELECT snapshot_hash, row_count FROM ai.data_source_sync WHERE data_source_id = $1",
    )
    .bind(data_source_id)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(|r| {
        (
            r.try_get("snapshot_hash").unwrap_or_default(),
            r.try_get::<i32, _>("row_count").unwrap_or(0),
        )
    }))
}

pub async fn sync_row_count(pool: &PgPool, data_source_id: i64) -> usize {
    sqlx::query_scalar::<_, i32>("SELECT row_count FROM ai.data_source_sync WHERE data_source_id = $1")
        .bind(data_source_id)
        .fetch_optional(pool)
        .await
        .ok()
        .flatten()
        .unwrap_or(0) as usize
}

pub async fn sync_touch(pool: &PgPool, data_source_id: i64) -> Result<()> {
    sqlx::query(
        "UPDATE ai.data_source_sync SET synced_ts = NOW(), updated_ts = NOW(), status = 'ok' WHERE data_source_id = $1",
    )
    .bind(data_source_id)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn sync_invalidate_row(pool: &PgPool, data_source_id: i64) -> Result<()> {
    sqlx::query(
        r#"
        UPDATE ai.data_source_sync
        SET snapshot_hash = '', status = 'stale', updated_ts = NOW()
        WHERE data_source_id = $1
        "#,
    )
    .bind(data_source_id)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn sync_upsert_ok(
    pool: &PgPool,
    data_source_id: i64,
    source_kind: &str,
    snapshot_hash: &str,
    row_count: i32,
) -> Result<()> {
    sqlx::query(
        r#"
        INSERT INTO ai.data_source_sync (data_source_id, source_kind, snapshot_hash, row_count, status, error_msg, synced_ts, updated_ts)
        VALUES ($1, $2, $3, $4, 'ok', NULL, NOW(), NOW())
        ON CONFLICT (data_source_id) DO UPDATE SET
            source_kind = EXCLUDED.source_kind,
            snapshot_hash = EXCLUDED.snapshot_hash,
            row_count = EXCLUDED.row_count,
            status = 'ok',
            error_msg = NULL,
            synced_ts = NOW(),
            updated_ts = NOW()
        "#,
    )
    .bind(data_source_id)
    .bind(source_kind)
    .bind(snapshot_hash)
    .bind(row_count)
    .execute(pool)
    .await
    .context("sync_upsert_ok")?;
    Ok(())
}

pub async fn sync_upsert_error(pool: &PgPool, data_source_id: i64, source_kind: &str, msg: &str) -> Result<()> {
    sqlx::query(
        r#"
        INSERT INTO ai.data_source_sync (data_source_id, source_kind, snapshot_hash, row_count, status, error_msg, synced_ts, updated_ts)
        VALUES ($1, $2, '', 0, 'error', $3, NOW(), NOW())
        ON CONFLICT (data_source_id) DO UPDATE SET
            status = 'error',
            error_msg = EXCLUDED.error_msg,
            updated_ts = NOW()
        "#,
    )
    .bind(data_source_id)
    .bind(source_kind)
    .bind(msg)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn chunks_delete_for_source(pool: &PgPool, data_source_id: i64) -> Result<()> {
    sqlx::query("DELETE FROM ai.data_source_chunk WHERE data_source_id = $1")
        .bind(data_source_id)
        .execute(pool)
        .await?;
    Ok(())
}

pub async fn chunk_insert(
    pool: &PgPool,
    data_source_id: i64,
    chunk_key: &str,
    source_kind: &str,
    content: &str,
    content_hash: &str,
    meta: &Value,
) -> Result<()> {
    let id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.data_source_chunk (id, data_source_id, chunk_key, source_kind, content, content_hash, meta)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        "#,
    )
    .bind(id)
    .bind(data_source_id)
    .bind(chunk_key)
    .bind(source_kind)
    .bind(content)
    .bind(content_hash)
    .bind(meta)
    .execute(pool)
    .await
    .context("chunk_insert")?;
    Ok(())
}

pub async fn chunks_full_text(pool: &PgPool, data_source_id: i64) -> Result<String> {
    let rows = sqlx::query(
        r#"
        SELECT content FROM ai.data_source_chunk
        WHERE data_source_id = $1
        ORDER BY COALESCE((meta->>'row')::int, 0), chunk_key
        "#,
    )
    .bind(data_source_id)
    .fetch_all(pool)
    .await?;
    let lines: Vec<String> = rows.iter().map(|r| r.get::<String, _>("content")).collect();
    Ok(lines.join("\n"))
}

pub struct ChunkCand {
    pub data_source_id: i64,
    pub chunk_key: String,
    pub content: String,
    pub content_hash: String,
}

pub async fn chunk_candidates_fts(
    pool: &PgPool,
    data_source_ids: &[i64],
    query_text: &str,
    limit: i64,
) -> Result<Vec<ChunkCand>> {
    let q = query_text.trim();
    if q.is_empty() || data_source_ids.is_empty() {
        return Ok(Vec::new());
    }
    let rows = sqlx::query(
        r#"
        SELECT data_source_id, chunk_key, content, content_hash
        FROM ai.data_source_chunk
        WHERE data_source_id = ANY($1) AND tsv @@ plainto_tsquery('english', $2)
        ORDER BY data_source_id, chunk_key
        LIMIT $3
        "#,
    )
    .bind(data_source_ids)
    .bind(q)
    .bind(limit)
    .fetch_all(pool)
    .await?;
    Ok(rows.into_iter().map(chunk_row_to_cand).collect())
}

pub async fn chunk_candidates_recent(pool: &PgPool, data_source_ids: &[i64], limit: i64) -> Result<Vec<ChunkCand>> {
    if data_source_ids.is_empty() {
        return Ok(Vec::new());
    }
    let rows = sqlx::query(
        r#"
        SELECT data_source_id, chunk_key, content, content_hash
        FROM ai.data_source_chunk
        WHERE data_source_id = ANY($1)
        ORDER BY COALESCE((meta->>'row')::int, 0), chunk_key
        LIMIT $2
        "#,
    )
    .bind(data_source_ids)
    .bind(limit)
    .fetch_all(pool)
    .await?;
    Ok(rows.into_iter().map(chunk_row_to_cand).collect())
}

fn row_to_data_source(row: sqlx::postgres::PgRow) -> Option<DataSourceRow> {
    Some(DataSourceRow {
        id: row.try_get("id").unwrap_or(0),
        owner_iid: row.try_get("owner_iid").unwrap_or(0),
        bot_iid: row.try_get("bot_iid").ok(),
        source_kind: row.try_get("source_kind").unwrap_or_default(),
        name: row.try_get("name").unwrap_or_default(),
        config: row.try_get("config").unwrap_or_else(|_| serde_json::json!({})),
    })
}

fn chunk_row_to_cand(row: sqlx::postgres::PgRow) -> ChunkCand {
    ChunkCand {
        data_source_id: row.get("data_source_id"),
        chunk_key: row.get("chunk_key"),
        content: row.get("content"),
        content_hash: row.get("content_hash"),
    }
}
