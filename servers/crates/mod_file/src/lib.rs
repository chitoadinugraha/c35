use std::path::{Path, PathBuf};
use std::sync::OnceLock;
use std::time::Duration;

use axum::{
    extract::{Path as AxumPath, Query, State},
    http::{header, HeaderMap, HeaderValue, StatusCode},
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use c35_ctx::AppState;
use c35_mod_identity::auth_session_caller_iid;
use serde::Deserialize;
use sqlx::{Postgres, Row, Transaction};
use serde_json::Value as JsonValue;

mod optimize;
mod s3;

use s3::{BlobS3, S3BlobError};

pub const CAS_INLINE_MAX_BYTES: i64 = 524_288;
pub const CAS_URL_TTL: Duration = Duration::from_secs(7 * 24 * 60 * 60);

static S3_CLIENT: OnceLock<Option<BlobS3>> = OnceLock::new();

fn s3_client() -> Option<&'static BlobS3> {
    S3_CLIENT
        .get_or_init(|| match s3::BlobS3::from_env() {
            Some(Ok(c)) => Some(c),
            Some(Err(e)) => {
                tracing::warn!("S3 init failed: {e}");
                None
            }
            None => None,
        })
        .as_ref()
}

pub async fn s3_get_object(key: &str) -> Result<(Vec<u8>, String), String> {
    let s3 = s3_client().ok_or_else(|| "S3 not configured".to_string())?;
    s3.get_key(key).await.map_err(|e| e.to_string())
}

fn cas_store_disk() -> bool {
    std::env::var("CAS_STORE")
        .map(|v| v.eq_ignore_ascii_case("disk"))
        .unwrap_or(false)
}

#[derive(Debug, Clone)]
pub struct CasPutResult {
    pub hash: String,
    pub size_bytes: i64,
    pub mime_type: String,
    pub is_inline: bool,
    pub url: String,
}

#[derive(Debug, Clone)]
pub struct CasMeta {
    pub hash: String,
    pub mime_type: String,
    pub size_bytes: i64,
    pub store: String,
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

pub fn cas_hash_normalize(hash: &str) -> Option<String> {
    let h = hash.trim().to_lowercase();
    if h.len() != 64 || !h.chars().all(|c| c.is_ascii_hexdigit()) {
        return None;
    }
    Some(h)
}

pub fn cas_hash_verify(hash: &str, body: &[u8]) -> Result<(), String> {
    let Some(h) = cas_hash_normalize(hash) else {
        return Err("invalid blake3 hash".into());
    };
    let got = cas_hash(body);
    if got != h {
        return Err(format!("hash mismatch: expected {h}, got {got}"));
    }
    Ok(())
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
            WHERE hash_blake3 = $1
        )
        "#,
    )
    .bind(hash)
    .fetch_one(pool)
    .await
    .unwrap_or(false)
}

pub async fn cas_meta_get(
    pool: &sqlx::PgPool,
    hash: &str,
) -> Result<Option<CasMeta>, sqlx::Error> {
    let Some(hash) = cas_hash_normalize(hash) else {
        return Ok(None);
    };
    let row = sqlx::query(
        "SELECT hash_blake3, mime_type, size_bytes, store FROM ai.file_blob_meta WHERE hash_blake3 = $1",
    )
    .bind(&hash)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(|r| CasMeta {
        hash: r.get("hash_blake3"),
        mime_type: r.get("mime_type"),
        size_bytes: r.get("size_bytes"),
        store: r.get("store"),
    }))
}

pub async fn file_variant_set(
    pool: &sqlx::PgPool,
    canonical_hash: &str,
    key: &str,
    variant_hash: &str,
) -> Result<(), sqlx::Error> {
    let canonical_hash = cas_hash_normalize(canonical_hash)
        .ok_or_else(|| sqlx::Error::Protocol("invalid canonical hash".into()))?;
    let variant_hash = cas_hash_normalize(variant_hash)
        .ok_or_else(|| sqlx::Error::Protocol("invalid variant hash".into()))?;
    if key.is_empty() || !key.chars().all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-') {
        return Err(sqlx::Error::Protocol("invalid variant key".into()));
    }
    let patch = serde_json::json!({ key: variant_hash });
    let mut tx = pool.begin().await?;
    let updated = sqlx::query(
        r#"
        UPDATE ai.file_blob_meta
        SET variants = variants || $2::jsonb
        WHERE hash_blake3 = $1
        "#,
    )
    .bind(&canonical_hash)
    .bind(patch)
    .execute(&mut *tx)
    .await?;
    if updated.rows_affected() == 0 {
        tx.rollback().await?;
        return Err(sqlx::Error::RowNotFound);
    }
    tx.commit().await?;
    Ok(())
}

pub async fn file_variant_get(
    pool: &sqlx::PgPool,
    canonical_hash: &str,
    key: &str,
) -> Result<Option<String>, sqlx::Error> {
    let Some(canonical_hash) = cas_hash_normalize(canonical_hash) else {
        return Ok(None);
    };
    let row = sqlx::query(
        "SELECT variants FROM ai.file_blob_meta WHERE hash_blake3 = $1",
    )
    .bind(&canonical_hash)
    .fetch_optional(pool)
    .await?;
    Ok(row.and_then(|r| {
        r.get::<JsonValue, _>("variants")
            .get(key)
            .and_then(|v| v.as_str())
            .map(str::to_string)
    }))
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

    if sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(SELECT 1 FROM ai.file_blob_meta WHERE hash_blake3 = $1)",
    )
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
        let inserted = meta_insert_tx(
            &mut tx,
            &hash,
            size,
            mime_type,
            true,
            "inline",
            &serde_json::json!({}),
        )
        .await?;
        if !inserted {
            tx.rollback().await?;
            return Ok(CasPutResult {
                hash,
                size_bytes: size,
                mime_type: mime_type.to_string(),
                is_inline,
                url,
            });
        }
        sqlx::query(
            "INSERT INTO ai.file_blob_inline (hash_blake3, bytes) VALUES ($1, $2)",
        )
        .bind(&hash)
        .bind(body)
        .execute(&mut *tx)
        .await?;
        tx.commit().await?;
    } else if cas_store_disk() {
        let prefix = &hash[0..2.min(hash.len())];
        let disk_path = cas_dir.join(prefix).join(&hash);
        tokio::fs::create_dir_all(cas_dir.join(prefix))
            .await
            .map_err(|e| sqlx::Error::Protocol(e.to_string()))?;
        tokio::fs::write(&disk_path, body)
            .await
            .map_err(|e| sqlx::Error::Protocol(e.to_string()))?;
        let loc = serde_json::json!({
            "path": disk_path.to_string_lossy()
        });
        let mut tx = pool.begin().await?;
        let inserted = meta_insert_tx(
            &mut tx,
            &hash,
            size,
            mime_type,
            false,
            "disk",
            &loc,
        )
        .await?;
        if !inserted {
            tx.rollback().await?;
            tokio::fs::remove_file(&disk_path).await.ok();
        } else {
            tx.commit().await?;
        }
    } else {
        let s3 = s3_client().ok_or_else(|| {
            sqlx::Error::Protocol(format!(
                "blob {size}B >= {CAS_INLINE_MAX_BYTES}; S3 not configured (set S3_* or CAS_STORE=disk)"
            ))
        })?;
        s3.put(&hash, body, mime_type)
            .await
            .map_err(s3_err_to_sqlx)?;
        let loc = BlobS3::loc_json(&hash);
        let mut tx = pool.begin().await?;
        let inserted = meta_insert_tx(&mut tx, &hash, size, mime_type, false, "s3", &loc).await?;
        if !inserted {
            tx.rollback().await?;
        } else {
            tx.commit().await?;
        }
    }

    if mime_type.starts_with("image/") {
        optimize::spawn_image_optimize(
            pool.clone(),
            cas_dir.to_path_buf(),
            secret.to_string(),
            hash.clone(),
            mime_type.to_string(),
        );
    }

    Ok(CasPutResult {
        hash,
        size_bytes: size,
        mime_type: mime_type.to_string(),
        is_inline,
        url,
    })
}

async fn meta_insert_tx(
    tx: &mut Transaction<'_, Postgres>,
    hash: &str,
    size: i64,
    mime_type: &str,
    is_inline: bool,
    store: &str,
    loc: &JsonValue,
) -> Result<bool, sqlx::Error> {
    let r = sqlx::query(
        r#"
        INSERT INTO ai.file_blob_meta
            (hash_blake3, size_bytes, mime_type, is_inline, store, loc, variants)
        VALUES ($1, $2, $3, $4, $5, $6, '{}')
        ON CONFLICT (hash_blake3) DO NOTHING
        "#,
    )
    .bind(hash)
    .bind(size)
    .bind(mime_type)
    .bind(is_inline)
    .bind(store)
    .bind(loc)
    .execute(&mut **tx)
    .await?;
    Ok(r.rows_affected() > 0)
}

fn s3_err_to_sqlx(e: S3BlobError) -> sqlx::Error {
    sqlx::Error::Protocol(e.to_string())
}

pub async fn cas_bytes_get(
    pool: &sqlx::PgPool,
    cas_dir: &Path,
    hash: &str,
) -> Result<(Vec<u8>, String), sqlx::Error> {
    let Some(hash) = cas_hash_normalize(hash) else {
        return Err(sqlx::Error::RowNotFound);
    };
    let row = sqlx::query(
        r#"
        SELECT m.mime_type, m.store, m.loc, i.bytes AS inline_bytes
        FROM ai.file_blob_meta m
        LEFT JOIN ai.file_blob_inline i ON i.hash_blake3 = m.hash_blake3
        WHERE m.hash_blake3 = $1
        "#,
    )
    .bind(&hash)
    .fetch_optional(pool)
    .await?;

    let Some(row) = row else {
        return Err(sqlx::Error::RowNotFound);
    };

    let mime: String = row.get("mime_type");
    let store: String = row.get("store");

    match store.as_str() {
        "inline" => {
            let bytes: Option<Vec<u8>> = row.get("inline_bytes");
            bytes
                .map(|b| (b, mime))
                .ok_or(sqlx::Error::RowNotFound)
        }
        "s3" => {
            let s3 = s3_client().ok_or_else(|| {
                sqlx::Error::Protocol("S3 not configured".into())
            })?;
            let loc: JsonValue = row.get("loc");
            let key = loc
                .get("key")
                .and_then(|v| v.as_str())
                .map(str::to_string)
                .unwrap_or_else(|| BlobS3::object_key(&hash));
            let (bytes, _) = s3.get_key(&key).await.map_err(s3_err_to_sqlx)?;
            Ok((bytes, mime))
        }
        "disk" => {
            let loc: JsonValue = row.get("loc");
            let disk_path = loc
                .get("path")
                .and_then(|v| v.as_str())
                .map(PathBuf::from)
                .or_else(|| {
                    if hash.len() >= 2 {
                        Some(cas_dir.join(&hash[0..2]).join(&hash))
                    } else {
                        None
                    }
                });
            let path = disk_path.ok_or(sqlx::Error::RowNotFound)?;
            let bytes = tokio::fs::read(&path)
                .await
                .map_err(|e| sqlx::Error::Protocol(e.to_string()))?;
            Ok((bytes, mime))
        }
        other => Err(sqlx::Error::Protocol(format!("unknown store={other}"))),
    }
}

pub fn file_router() -> Router<AppState> {
    Router::new()
        .route("/fs/{hash}", get(get_file_handler).head(head_file_handler).put(put_file_handler))
        .route("/v1/file/upload", post(upload_file_handler))
}

#[derive(Deserialize, Default)]
struct CasGetQuery {
    #[serde(default)]
    exp: i64,
    #[serde(default)]
    sig: String,
    #[serde(default)]
    v: Option<String>,
}

fn cache_headers(hash: &str, size: i64) -> HeaderMap {
    let mut h = HeaderMap::new();
    if let Ok(v) = HeaderValue::from_str(&format!("\"{hash}\"")) {
        h.insert(header::ETAG, v);
    }
    h.insert(
        header::CACHE_CONTROL,
        HeaderValue::from_static("public, max-age=31536000, immutable"),
    );
    if size > 0 {
        if let Ok(v) = HeaderValue::from_str(&size.to_string()) {
            h.insert(header::CONTENT_LENGTH, v);
        }
    }
    h
}

async fn resolve_fetch_hash(
    pool: &sqlx::PgPool,
    hash: &str,
    variant: Option<&str>,
) -> Result<String, sqlx::Error> {
    let Some(hash) = cas_hash_normalize(hash) else {
        return Err(sqlx::Error::Protocol("invalid hash".into()));
    };
    if let Some(key) = variant.filter(|k| !k.is_empty()) {
        if let Some(vh) = file_variant_get(pool, &hash, key).await? {
            return Ok(vh);
        }
    }
    Ok(hash)
}

async fn file_access_ok(
    st: &AppState,
    hash: &str,
    q: &CasGetQuery,
    headers: &HeaderMap,
) -> bool {
    let signed = cas_verify(&st.cas_secret, hash, q.exp, &q.sig);
    if signed {
        return true;
    }
    if cas_is_public(&st.pool, hash).await {
        return true;
    }
    auth_session_caller_iid(&st.pool, headers, None)
        .await
        .is_some_and(|id| id > 0)
}

async fn get_file_handler(
    State(st): State<AppState>,
    AxumPath(hash): AxumPath<String>,
    Query(q): Query<CasGetQuery>,
    headers: HeaderMap,
) -> impl IntoResponse {
    let canonical = hash.trim().to_lowercase();
    if cas_hash_normalize(&canonical).is_none() {
        return (StatusCode::BAD_REQUEST, "invalid hash").into_response();
    }
    if !file_access_ok(&st, &canonical, &q, &headers).await {
        return (StatusCode::UNAUTHORIZED, "unauthorized").into_response();
    }

    let fetch_hash = match resolve_fetch_hash(&st.pool, &canonical, q.v.as_deref()).await {
        Ok(h) => h,
        Err(_) => return (StatusCode::NOT_FOUND, "not found").into_response(),
    };

    let etag = format!("\"{fetch_hash}\"");
    if let Some(if_none_match) = headers.get(header::IF_NONE_MATCH).and_then(|v| v.to_str().ok()) {
        if if_none_match == etag {
            return (
                StatusCode::NOT_MODIFIED,
                [(header::ETAG, etag)],
                Vec::<u8>::new(),
            )
                .into_response();
        }
    }

    match cas_bytes_get(&st.pool, &st.cas_dir, &fetch_hash).await {
        Ok((bytes, mime)) => {
            let meta = cas_meta_get(&st.pool, &fetch_hash)
                .await
                .ok()
                .flatten();
            let size = meta.map(|m| m.size_bytes).unwrap_or(bytes.len() as i64);
            let mut res_headers = cache_headers(&fetch_hash, size);
            if let Ok(v) = HeaderValue::from_str(&mime) {
                res_headers.insert(header::CONTENT_TYPE, v);
            }
            (StatusCode::OK, res_headers, bytes).into_response()
        }
        Err(_) => (StatusCode::NOT_FOUND, "not found").into_response(),
    }
}

async fn head_file_handler(
    State(st): State<AppState>,
    AxumPath(hash): AxumPath<String>,
    Query(q): Query<CasGetQuery>,
    headers: HeaderMap,
) -> impl IntoResponse {
    let canonical = hash.trim().to_lowercase();
    if cas_hash_normalize(&canonical).is_none() {
        return (StatusCode::BAD_REQUEST, "invalid hash").into_response();
    }
    if !file_access_ok(&st, &canonical, &q, &headers).await {
        return (StatusCode::UNAUTHORIZED, "unauthorized").into_response();
    }

    let fetch_hash = match resolve_fetch_hash(&st.pool, &canonical, q.v.as_deref()).await {
        Ok(h) => h,
        Err(_) => return (StatusCode::NOT_FOUND, "not found").into_response(),
    };

    match cas_meta_get(&st.pool, &fetch_hash).await {
        Ok(Some(meta)) => {
            let mut res_headers = cache_headers(&fetch_hash, meta.size_bytes);
            if let Ok(v) = HeaderValue::from_str(&meta.mime_type) {
                res_headers.insert(header::CONTENT_TYPE, v);
            }
            (StatusCode::OK, res_headers).into_response()
        }
        Ok(None) => (StatusCode::NOT_FOUND, "not found").into_response(),
        Err(_) => (StatusCode::INTERNAL_SERVER_ERROR, "error").into_response(),
    }
}

async fn put_file_handler(
    State(st): State<AppState>,
    AxumPath(hash): AxumPath<String>,
    headers: HeaderMap,
    body: axum::body::Bytes,
) -> impl IntoResponse {
    let hash = hash.trim().to_lowercase();
    if cas_hash_normalize(&hash).is_none() {
        return (StatusCode::BAD_REQUEST, "invalid hash").into_response();
    }
    if cas_meta_get(&st.pool, &hash).await.ok().flatten().is_some() {
        return StatusCode::NO_CONTENT.into_response();
    }
    if let Err(msg) = cas_hash_verify(&hash, &body) {
        return (StatusCode::BAD_REQUEST, msg).into_response();
    }
    let mime_type = headers
        .get(header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("application/octet-stream");
    match cas_put(&st.pool, &st.cas_dir, &st.cas_secret, &body, mime_type).await {
        Ok(_) => StatusCode::CREATED.into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response(),
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

#[cfg(test)]
mod unit_tests {
    use super::*;

    #[test]
    fn hash_normalize_accepts_64_hex() {
        let body = b"c35 file cas";
        let hash = cas_hash(body);
        assert_eq!(cas_hash_normalize(&hash), Some(hash.clone()));
        assert_eq!(cas_hash_normalize(&hash.to_uppercase()), Some(hash));
    }

    #[test]
    fn hash_normalize_rejects_invalid() {
        assert!(cas_hash_normalize("").is_none());
        assert!(cas_hash_normalize("abc").is_none());
        assert!(cas_hash_normalize(&"x".repeat(64)).is_none());
    }

    #[test]
    fn hash_verify_ok_and_mismatch() {
        let body = b"verify me";
        let hash = cas_hash(body);
        assert!(cas_hash_verify(&hash, body).is_ok());
        assert!(cas_hash_verify(&hash, b"other").is_err());
        assert!(cas_hash_verify("bad", body).is_err());
    }

    #[test]
    fn variant_key_validation() {
        assert!("".is_empty());
        let valid = "thumb_small-1";
        assert!(valid
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-'));
        let invalid = "thumb/x";
        assert!(!invalid
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-'));
    }
}
