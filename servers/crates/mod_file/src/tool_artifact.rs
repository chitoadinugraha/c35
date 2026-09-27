use chrono::{DateTime, Duration, Utc};
use c35_store::snowflake_id;
use serde_json::Value as JsonValue;
use sqlx::{PgPool, Row};

pub const TOOL_ARTIFACT_TTL_DAYS: i64 = 14;

pub async fn tool_artifact_insert(
    pool: &PgPool,
    owner_iid: i64,
    req_id: &str,
    tool_call_id: &str,
    tool_id: &str,
    device_iid: i64,
    hash_blake3: &str,
    width: i32,
    height: i32,
    meta_json: &JsonValue,
) -> Result<i64, sqlx::Error> {
    let id = snowflake_id();
    let expires_ts = Utc::now() + Duration::days(TOOL_ARTIFACT_TTL_DAYS);
    sqlx::query(
        r#"
        INSERT INTO ai.tool_artifact (
            id, owner_iid, req_id, tool_call_id, tool_id, device_iid,
            hash_blake3, width, height, meta_json, expires_ts
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        "#,
    )
    .bind(id)
    .bind(owner_iid)
    .bind(req_id)
    .bind(tool_call_id)
    .bind(tool_id)
    .bind(device_iid)
    .bind(hash_blake3)
    .bind(width)
    .bind(height)
    .bind(meta_json)
    .bind(expires_ts)
    .execute(pool)
    .await?;
    Ok(id)
}

#[derive(Debug, Clone)]
pub struct ToolArtifactRow {
    pub id: i64,
    pub owner_iid: i64,
    pub req_id: String,
    pub tool_call_id: String,
    pub tool_id: String,
    pub device_iid: i64,
    pub hash_blake3: String,
    pub width: i32,
    pub height: i32,
    pub meta_json: JsonValue,
    pub created_ts: DateTime<Utc>,
    pub expires_ts: DateTime<Utc>,
}

fn row_to_artifact(r: &sqlx::postgres::PgRow) -> Result<ToolArtifactRow, sqlx::Error> {
    Ok(ToolArtifactRow {
        id: r.try_get("id")?,
        owner_iid: r.try_get("owner_iid")?,
        req_id: r.try_get("req_id")?,
        tool_call_id: r.try_get("tool_call_id")?,
        tool_id: r.try_get("tool_id")?,
        device_iid: r.try_get("device_iid")?,
        hash_blake3: r.try_get("hash_blake3")?,
        width: r.try_get("width")?,
        height: r.try_get("height")?,
        meta_json: r.try_get("meta_json")?,
        created_ts: r.try_get("created_ts")?,
        expires_ts: r.try_get("expires_ts")?,
    })
}

pub async fn tool_artifact_list_by_req(
    pool: &PgPool,
    owner_iid: i64,
    req_id: &str,
    tool_id: Option<&str>,
) -> Result<Vec<ToolArtifactRow>, sqlx::Error> {
    let rows = if let Some(tid) = tool_id.filter(|s| !s.is_empty()) {
        sqlx::query(
            r#"
            SELECT id, owner_iid, req_id, tool_call_id, tool_id, device_iid,
                   hash_blake3, width, height, meta_json, created_ts, expires_ts
            FROM ai.tool_artifact
            WHERE owner_iid = $1 AND req_id = $2 AND tool_id = $3
              AND deleted_ts IS NULL AND expires_ts > NOW()
            ORDER BY created_ts ASC
            "#,
        )
        .bind(owner_iid)
        .bind(req_id)
        .bind(tid)
        .fetch_all(pool)
        .await?
    } else {
        sqlx::query(
            r#"
            SELECT id, owner_iid, req_id, tool_call_id, tool_id, device_iid,
                   hash_blake3, width, height, meta_json, created_ts, expires_ts
            FROM ai.tool_artifact
            WHERE owner_iid = $1 AND req_id = $2
              AND deleted_ts IS NULL AND expires_ts > NOW()
            ORDER BY created_ts ASC
            "#,
        )
        .bind(owner_iid)
        .bind(req_id)
        .fetch_all(pool)
        .await?
    };
    rows.iter().map(row_to_artifact).collect()
}

pub async fn tool_artifact_get(
    pool: &PgPool,
    owner_iid: i64,
    artifact_id: i64,
) -> Result<Option<ToolArtifactRow>, sqlx::Error> {
    let row = sqlx::query(
        r#"
        SELECT id, owner_iid, req_id, tool_call_id, tool_id, device_iid,
               hash_blake3, width, height, meta_json, created_ts, expires_ts
        FROM ai.tool_artifact
        WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL AND expires_ts > NOW()
        "#,
    )
    .bind(artifact_id)
    .bind(owner_iid)
    .fetch_optional(pool)
    .await?;
    row.as_ref().map(row_to_artifact).transpose()
}

pub async fn tool_artifact_evict_stale(pool: &PgPool) -> Result<u64, sqlx::Error> {
    let res = sqlx::query(
        r#"
        UPDATE ai.tool_artifact
        SET deleted_ts = NOW()
        WHERE deleted_ts IS NULL AND expires_ts < NOW()
        "#,
    )
    .execute(pool)
    .await?;
    Ok(res.rows_affected())
}
