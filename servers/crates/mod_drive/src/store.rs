use std::path::Path;

use c35_mod_file::cas_put;
use c35_store::snowflake_id;
use sqlx::{PgPool, Row};

use crate::quota::{drive_storage_limit_bytes, DriveQuotaExceeded};

#[derive(Debug, Clone, serde::Serialize)]
pub struct DriveStorageSnapshot {
    pub storage_used_bytes: i64,
    pub storage_limit_bytes: i64,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct DriveFileEntry {
    pub path: String,
    pub hash: String,
    pub size: i64,
    pub name: String,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct DriveUploadResponse {
    pub hash: String,
    pub size_bytes: i64,
    pub mime_type: String,
    pub is_inline: bool,
    pub asset_id: Option<i64>,
    pub url: String,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct DriveFileOpResponse {
    pub ok: bool,
    pub path: String,
}

pub async fn drive_storage_used_bytes(pool: &PgPool, owner_iid: i64) -> Result<i64, sqlx::Error> {
    sqlx::query_scalar(
        r#"
        SELECT COALESCE(SUM(size_bytes), 0)::bigint
        FROM ai.drive_file
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .fetch_one(pool)
    .await
}

pub async fn drive_storage_snapshot(
    pool: &PgPool,
    owner_iid: i64,
) -> Result<DriveStorageSnapshot, sqlx::Error> {
    let used = drive_storage_used_bytes(pool, owner_iid).await?;
    let limit = drive_storage_limit_bytes(pool, owner_iid).await?;
    Ok(DriveStorageSnapshot {
        storage_used_bytes: used,
        storage_limit_bytes: limit,
    })
}

pub async fn drive_tree_list(pool: &PgPool, owner_iid: i64) -> Result<Vec<DriveFileEntry>, sqlx::Error> {
    let rows = sqlx::query(
        r#"
        SELECT path, hash_blake3, size_bytes
        FROM ai.drive_file
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        ORDER BY path
        "#,
    )
    .bind(owner_iid)
    .fetch_all(pool)
    .await?;
    Ok(rows
        .into_iter()
        .map(|r| {
            let path: String = r.get("path");
            DriveFileEntry {
                path: path.clone(),
                hash: r.get("hash_blake3"),
                size: r.get("size_bytes"),
                name: drive_path_name(&path),
            }
        })
        .filter(|e| !e.path.is_empty() && !e.hash.is_empty())
        .collect())
}

pub async fn drive_file_put(
    pool: &PgPool,
    cas_dir: &Path,
    cas_secret: &str,
    public_origin: &str,
    owner_iid: i64,
    path: &str,
    body: &[u8],
    mime_type: &str,
) -> Result<DriveUploadResponse, DrivePutError> {
    let path = drive_normalize_path(path);
    if path.is_empty() {
        return Err(DrivePutError::InvalidPath);
    }
    if body.is_empty() {
        return Err(DrivePutError::EmptyBody);
    }

    let new_size = body.len() as i64;
    let old_size: i64 = sqlx::query_scalar(
        r#"
        SELECT COALESCE(size_bytes, 0)::bigint
        FROM ai.drive_file
        WHERE owner_iid = $1 AND path = $2 AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(owner_iid)
    .bind(&path)
    .fetch_optional(pool)
    .await?
    .unwrap_or(0);

    let used = drive_storage_used_bytes(pool, owner_iid).await?;
    let limit = drive_storage_limit_bytes(pool, owner_iid).await?;
    let projected = used - old_size + new_size;
    if projected > limit {
        return Err(DrivePutError::Quota(DriveQuotaExceeded {
            used_bytes: used,
            delta_bytes: new_size - old_size,
            limit_bytes: limit,
        }));
    }

    let put = cas_put(pool, cas_dir, cas_secret, body, mime_type)
        .await
        .map_err(DrivePutError::Cas)?;

    let origin = public_origin.trim_end_matches('/');
    let url = if put.url.starts_with('/') {
        format!("{origin}{}", put.url)
    } else {
        put.url.clone()
    };

    let existing_id: Option<i64> = sqlx::query_scalar(
        r#"
        SELECT id FROM ai.drive_file
        WHERE owner_iid = $1 AND path = $2 AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(owner_iid)
    .bind(&path)
    .fetch_optional(pool)
    .await?;

    if let Some(id) = existing_id {
        sqlx::query(
            r#"
            UPDATE ai.drive_file
            SET hash_blake3 = $3, size_bytes = $4, mime_type = $5, updated_ts = NOW()
            WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL
            "#,
        )
        .bind(id)
        .bind(owner_iid)
        .bind(&put.hash)
        .bind(put.size_bytes)
        .bind(mime_type)
        .execute(pool)
        .await?;
    } else {
        let id = snowflake_id();
        sqlx::query(
            r#"
            INSERT INTO ai.drive_file (id, owner_iid, path, hash_blake3, size_bytes, mime_type)
            VALUES ($1, $2, $3, $4, $5, $6)
            "#,
        )
        .bind(id)
        .bind(owner_iid)
        .bind(&path)
        .bind(&put.hash)
        .bind(put.size_bytes)
        .bind(mime_type)
        .execute(pool)
        .await?;
    }

    Ok(DriveUploadResponse {
        hash: put.hash,
        size_bytes: put.size_bytes,
        mime_type: put.mime_type,
        is_inline: put.is_inline,
        asset_id: None,
        url,
    })
}

pub async fn drive_file_delete(pool: &PgPool, owner_iid: i64, path: &str) -> Result<bool, sqlx::Error> {
    let path = drive_normalize_path(path);
    if path.is_empty() {
        return Ok(false);
    }
    let res = sqlx::query(
        r#"
        UPDATE ai.drive_file
        SET deleted_ts = NOW(), updated_ts = NOW()
        WHERE owner_iid = $1 AND path = $2 AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .bind(&path)
    .execute(pool)
    .await?;
    Ok(res.rows_affected() > 0)
}

#[derive(Debug, thiserror::Error)]
pub enum DrivePutError {
    #[error("path required")]
    InvalidPath,
    #[error("empty body")]
    EmptyBody,
    #[error("{0}")]
    Quota(DriveQuotaExceeded),
    #[error("cas: {0}")]
    Cas(sqlx::Error),
    #[error("{0}")]
    Db(sqlx::Error),
}

impl From<sqlx::Error> for DrivePutError {
    fn from(e: sqlx::Error) -> Self {
        DrivePutError::Db(e)
    }
}

pub fn drive_normalize_path(path: &str) -> String {
    let trimmed = path.trim();
    if trimmed.is_empty() {
        return String::new();
    }
    if trimmed.starts_with('/') {
        trimmed.to_string()
    } else {
        format!("/{trimmed}")
    }
}

fn drive_path_name(path: &str) -> String {
    path.rsplit('/').next().filter(|s| !s.is_empty()).unwrap_or(path).to_string()
}
