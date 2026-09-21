use std::path::{Path, PathBuf};
use std::time::Duration;

use axum::{
    extract::{Path as AxumPath, Query, State},
    http::{header, HeaderMap, StatusCode},
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use c35_ctx::AppState;
use c35_mod_identity::auth_session_caller_iid;
use serde::Deserialize;
use sqlx::Row;

pub const CAS_INLINE_MAX_BYTES: i64 = 524_288;
pub const CAS_URL_TTL: Duration = Duration::from_secs(7 * 24 * 60 * 60);

#[derive(Debug, Clone)]
pub struct CasPutResult {
    pub hash: String,
    pub size_bytes: i64,
    pub mime_type: String,
    pub is_inline: bool,
    pub url: String,
}

#[derive(serde::Serialize)]
pub struct UploadResponse {
    pub hash: String,
    pub size_bytes: i64,
    pub mime_type: String,
    pub is_inline: bool,
    pub url: String,
}

pub fn cas_dir_default() -> PathBuf {
    std::env::var("CAS_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from(".cache/cas"))
}

pub fn cas_hash(body: &[u8]) -> String {
    blake3::hash(body).to_hex().to_string()
}

fn cas_mac(secret: &str, hash: &str, exp_ms: i64) -> String {
    let key = *blake3::hash(secret.as_bytes()).as_bytes();
    let mut hasher = blake3::Hasher::new_keyed(&key);
    hasher.update(hash.as_bytes());
    hasher.update(b"|");
    hasher.update(&exp_ms.to_be_bytes());
    hasher.finalize().to_hex().to_string()
}

pub fn cas_sign(secret: &str, hash: &str, ttl: Duration) -> String {
    let exp = now_ms() + ttl.as_millis() as i64;
    let sig = cas_mac(secret, hash, exp);
    format!("/fs/{hash}?exp={exp}&sig={sig}")
}

pub fn cas_verify(secret: &str, hash: &str, exp: i64, sig: &str) -> bool {
    if hash.is_empty() || sig.is_empty() || exp <= now_ms() {
        return false;
    }
    cas_mac(secret, hash, exp).eq_ignore_ascii_case(sig.trim())
}

async fn cas_is_public(pool: &sqlx::PgPool, hash: &str) -> bool {
    let hash = hash.trim();
    if hash.is_empty() {
        return false;
    }
    sqlx::query_scalar::<_, bool>(
        r#"
        SELECT EXISTS(
            SELECT 1 FROM ai.identity
            WHERE is_active = true AND pic LIKE '%' || $1 || '%'
        )
        AND EXISTS(
            SELECT 1 FROM ai.file_blob_meta
            WHERE hash_blake3 = $1 AND is_inline = true
        )
        "#,
    )
    .bind(hash)
    .fetch_one(pool)
    .await
    .unwrap_or(false)
}

pub async fn cas_put(
    pool: &sqlx::PgPool,
    cas_dir: &Path,
    secret: &str,
    body: &[u8],
    mime_type: &str,
) -> Result<CasPutResult, sqlx::Error> {
    let hash = cas_hash(body);
    let size = body.len() as i64;
    let is_inline = size < CAS_INLINE_MAX_BYTES;
    let url = cas_sign(secret, &hash, CAS_URL_TTL);

    if sqlx::query_scalar::<_, bool>("SELECT EXISTS(SELECT 1 FROM ai.file_blob_meta WHERE hash_blake3 = $1)")
        .bind(&hash)
        .fetch_one(pool)
        .await?
    {
        return Ok(CasPutResult {
            hash,
            size_bytes: size,
            mime_type: mime_type.to_string(),
            is_inline,
            url,
        });
    }

    if is_inline {
        let mut tx = pool.begin().await?;
        sqlx::query(
            "INSERT INTO ai.file_blob_meta (hash_blake3, size_bytes, mime_type, is_inline) VALUES ($1, $2, $3, true) ON CONFLICT DO NOTHING",
        )
        .bind(&hash)
        .bind(size)
        .bind(mime_type)
        .execute(&mut *tx)
        .await?;
        sqlx::query(
            "INSERT INTO ai.file_blob_inline (hash_blake3, bytes) VALUES ($1, $2) ON CONFLICT DO NOTHING",
        )
        .bind(&hash)
        .bind(body)
        .execute(&mut *tx)
        .await?;
        tx.commit().await?;
    } else {
        let prefix = &hash[0..2.min(hash.len())];
        tokio::fs::create_dir_all(cas_dir.join(prefix)).await.ok();
        tokio::fs::write(cas_dir.join(prefix).join(&hash), body)
            .await
            .map_err(|e| sqlx::Error::Protocol(e.to_string()))?;
        sqlx::query(
            "INSERT INTO ai.file_blob_meta (hash_blake3, size_bytes, mime_type, is_inline) VALUES ($1, $2, $3, false) ON CONFLICT DO NOTHING",
        )
        .bind(&hash)
        .bind(size)
        .bind(mime_type)
        .execute(pool)
        .await?;
    }

    Ok(CasPutResult {
        hash,
        size_bytes: size,
        mime_type: mime_type.to_string(),
        is_inline,
        url,
    })
}

pub async fn cas_bytes_get(
    pool: &sqlx::PgPool,
    cas_dir: &Path,
    hash: &str,
) -> Result<(Vec<u8>, String), sqlx::Error> {
    let inline_row = sqlx::query(
        r#"
        SELECT m.mime_type, i.bytes
        FROM ai.file_blob_meta m
        JOIN ai.file_blob_inline i ON i.hash_blake3 = m.hash_blake3
        WHERE m.hash_blake3 = $1
        "#,
    )
    .bind(hash)
    .fetch_optional(pool)
    .await?;
    if let Some(row) = inline_row {
        let mime: String = row.get("mime_type");
        let bytes: Vec<u8> = row.get("bytes");
        return Ok((bytes, mime));
    }
    if hash.len() >= 2 {
        let disk_path = cas_dir.join(&hash[0..2]).join(hash);
        if disk_path.exists() {
            let bytes = tokio::fs::read(&disk_path)
                .await
                .map_err(|e| sqlx::Error::Protocol(e.to_string()))?;
            let mime: String = sqlx::query_scalar(
                "SELECT mime_type FROM ai.file_blob_meta WHERE hash_blake3 = $1",
            )
            .bind(hash)
            .fetch_optional(pool)
            .await?
            .unwrap_or_else(|| "application/octet-stream".to_string());
            return Ok((bytes, mime));
        }
    }
    Err(sqlx::Error::RowNotFound)
}

pub fn file_router() -> Router<AppState> {
    Router::new()
        .route("/fs/{hash}", get(get_file_handler))
        .route("/v1/file/upload", post(upload_file_handler))
}

#[derive(Deserialize, Default)]
struct CasGetQuery {
    #[serde(default)]
    exp: i64,
    #[serde(default)]
    sig: String,
}

async fn get_file_handler(
    State(st): State<AppState>,
    AxumPath(hash): AxumPath<String>,
    Query(q): Query<CasGetQuery>,
    headers: HeaderMap,
) -> impl IntoResponse {
    let signed = cas_verify(&st.cas_secret, &hash, q.exp, &q.sig);
    let public = if signed {
        false
    } else {
        cas_is_public(&st.pool, &hash).await
    };
    let session = if signed || public {
        false
    } else {
        auth_session_caller_iid(&st.pool, &headers, None)
            .await
            .is_some_and(|id| id > 0)
    };
    if !signed && !public && !session {
        return (StatusCode::UNAUTHORIZED, "unauthorized").into_response();
    }
    match cas_bytes_get(&st.pool, &st.cas_dir, &hash).await {
        Ok((bytes, mime)) => (
            StatusCode::OK,
            [
                (header::CONTENT_TYPE, mime),
                (
                    header::CACHE_CONTROL,
                    "public, max-age=31536000, immutable".to_string(),
                ),
            ],
            bytes,
        )
            .into_response(),
        Err(_) => (StatusCode::NOT_FOUND, "not found").into_response(),
    }
}

async fn upload_file_handler(
    State(st): State<AppState>,
    headers: HeaderMap,
    body: axum::body::Bytes,
) -> impl IntoResponse {
    if body.is_empty() {
        return (StatusCode::BAD_REQUEST, "empty body").into_response();
    }
    let _iid = match auth_session_caller_iid(&st.pool, &headers, None).await {
        Some(id) if id > 0 => id,
        _ => return (StatusCode::UNAUTHORIZED, "unauthorized").into_response(),
    };
    let mime_type = headers
        .get(header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("application/octet-stream")
        .to_string();
    let put = match cas_put(&st.pool, &st.cas_dir, &st.cas_secret, &body, &mime_type).await {
        Ok(p) => p,
        Err(e) => return (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response(),
    };
    let origin = st.public_origin.trim_end_matches('/');
    let url = if put.url.starts_with('/') {
        format!("{origin}{}", put.url)
    } else {
        put.url.clone()
    };
    Json(UploadResponse {
        hash: put.hash,
        size_bytes: put.size_bytes,
        mime_type: put.mime_type,
        is_inline: put.is_inline,
        url,
    })
    .into_response()
}

fn now_ms() -> i64 {
    chrono::Utc::now().timestamp_millis()
}
