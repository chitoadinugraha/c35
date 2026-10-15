use blake3::hash;
use sqlx::PgPool;
use tracing::warn;

const AVATAR_INLINE_MAX_BYTES: usize = 524_288;

/// True when `pic` is already served from our CAS (`/fs/{hash}`).
pub fn identity_pic_is_cas(pic: &str) -> bool {
    let p = pic.trim();
    if p.is_empty() {
        return false;
    }
    let path = p
        .strip_prefix("https://")
        .or_else(|| p.strip_prefix("http://"))
        .and_then(|rest| rest.find('/').map(|i| &rest[i..]))
        .unwrap_or(p);
    let path = path.trim_start_matches('/');
    path.starts_with("fs/")
        && path.len() >= "fs/".len() + 64
        && path[3..3 + 64]
            .chars()
            .all(|c| c.is_ascii_hexdigit())
}

/// Fetch remote avatar bytes (e.g. Google profile photo) into CAS; return `/fs/{hash}` or the original on failure.
pub async fn identity_pic_ingest_from_url(pool: &PgPool, raw: &str) -> String {
    let trimmed = raw.trim();
    if trimmed.is_empty() || identity_pic_is_cas(trimmed) {
        return trimmed.to_string();
    }
    if !trimmed.starts_with("http://") && !trimmed.starts_with("https://") {
        return trimmed.to_string();
    }
    match identity_pic_fetch_to_cas(pool, trimmed).await {
        Ok(path) => path,
        Err(e) => {
            warn!("identity pic ingest failed url={}: {}", trimmed, e);
            trimmed.to_string()
        }
    }
}

fn identity_pic_hash_hex(body: &[u8]) -> String {
    hash(body).to_hex().to_string()
}

async fn identity_pic_cas_put_inline(
    pool: &PgPool,
    body: &[u8],
    mime_type: &str,
) -> Result<String, String> {
    if body.len() > AVATAR_INLINE_MAX_BYTES {
        return Err("avatar too large for inline CAS".into());
    }
    let hash_blake3 = identity_pic_hash_hex(body);
    let exists: bool = sqlx::query_scalar(
        "SELECT EXISTS(SELECT 1 FROM ai.file_blob_meta WHERE hash_blake3 = $1)",
    )
    .bind(&hash_blake3)
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())?;
    if exists {
        return Ok(hash_blake3);
    }
    let size = body.len() as i64;
    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;
    let inserted = sqlx::query(
        r#"
        INSERT INTO ai.file_blob_meta (hash_blake3, size_bytes, mime_type, is_inline, store, loc)
        VALUES ($1, $2, $3, true, 'inline', '{}'::jsonb)
        ON CONFLICT (hash_blake3) DO NOTHING
        "#,
    )
    .bind(&hash_blake3)
    .bind(size)
    .bind(mime_type)
    .execute(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;
    if inserted.rows_affected() == 0 {
        tx.rollback().await.map_err(|e| e.to_string())?;
        return Ok(hash_blake3);
    }
    sqlx::query("INSERT INTO ai.file_blob_inline (hash_blake3, bytes) VALUES ($1, $2)")
        .bind(&hash_blake3)
        .bind(body)
        .execute(&mut *tx)
        .await
        .map_err(|e| e.to_string())?;
    tx.commit().await.map_err(|e| e.to_string())?;
    Ok(hash_blake3)
}

async fn identity_pic_fetch_to_cas(pool: &PgPool, url: &str) -> Result<String, String> {
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(20))
        .build()
        .map_err(|e| e.to_string())?;
    let res = client
        .get(url)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    if !res.status().is_success() {
        return Err(format!("http {}", res.status()));
    }
    let mime = res
        .headers()
        .get(reqwest::header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .map(|s| s.split(';').next().unwrap_or(s).trim())
        .filter(|s| s.starts_with("image/"))
        .unwrap_or("image/jpeg")
        .to_string();
    let bytes = res.bytes().await.map_err(|e| e.to_string())?;
    if bytes.is_empty() {
        return Err("empty body".into());
    }
    let hash_blake3 = identity_pic_cas_put_inline(pool, &bytes, &mime).await?;
    Ok(format!("/fs/{}", hash_blake3))
}

#[cfg(test)]
mod tests {
    use super::identity_pic_is_cas;

    #[test]
    fn cas_pic_paths() {
        assert!(identity_pic_is_cas("/fs/abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"));
        assert!(identity_pic_is_cas(
            "https://api.alienai.id/fs/abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789",
        ));
        assert!(!identity_pic_is_cas("https://lh3.googleusercontent.com/a/abc"));
        assert!(!identity_pic_is_cas(""));
    }
}