//! S3 roundtrip — requires S3_* env and YB_* database.

use c35_mod_file::{cas_bytes_get, cas_dir_default, cas_hash, cas_put, CAS_INLINE_MAX_BYTES};

#[tokio::test]
#[ignore = "requires S3_* env and YB_* database"]
async fn s3_put_get_roundtrip() {
    let _ = dotenvy::from_filename(".env.local");
    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL");
    let pool = sqlx::PgPool::connect(&database_url).await.expect("connect");
    let cas_dir = cas_dir_default();
    let secret = std::env::var("CAS_HMAC_SECRET").unwrap_or_else(|_| "test".into());

    let body: Vec<u8> = (0..CAS_INLINE_MAX_BYTES as usize).map(|i| (i % 251) as u8).collect();
    let hash = cas_hash(&body);

    let _ = cas_put(&pool, &cas_dir, &secret, &body, "application/octet-stream")
        .await
        .expect("put");

    let (got, _) = cas_bytes_get(&pool, &cas_dir, &hash)
        .await
        .expect("get");
    assert_eq!(got, body);

    let store: String = sqlx::query_scalar(
        "SELECT store FROM ai.file_blob_meta WHERE hash_blake3 = $1",
    )
    .bind(&hash)
    .fetch_one(&pool)
    .await
    .expect("meta");
    assert_eq!(store, "s3");
}
