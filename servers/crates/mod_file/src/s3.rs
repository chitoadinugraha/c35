//! S3-compatible blob backend (`rust-s3`) — keys `fs/{hash}`.

use s3::creds::Credentials;
use s3::Bucket;
use thiserror::Error;

#[derive(Debug, Clone)]
pub struct S3Config {
    pub endpoint: String,
    pub bucket: String,
    pub access_key: String,
    pub secret_key: String,
    pub secure: bool,
    pub region: String,
}

impl S3Config {
    pub fn from_env() -> Option<Self> {
        let endpoint = std::env::var("S3_ENDPOINT").unwrap_or_default();
        let bucket = std::env::var("S3_BUCKET").unwrap_or_default();
        if endpoint.is_empty() || bucket.is_empty() {
            return None;
        }
        Some(Self {
            endpoint,
            bucket,
            access_key: std::env::var("S3_ACCESS_KEY").unwrap_or_default(),
            secret_key: std::env::var("S3_SECRET_KEY").unwrap_or_default(),
            secure: std::env::var("S3_SECURE")
                .map(|v| v.parse().unwrap_or(true))
                .unwrap_or(true),
            region: std::env::var("S3_REGION").unwrap_or_else(|_| "us-east-1".into()),
        })
    }
}

#[derive(Debug, Error)]
pub enum S3BlobError {
    #[error("s3: {0}")]
    Msg(String),
}

pub type S3Result<T> = Result<T, S3BlobError>;

#[derive(Clone)]
pub struct BlobS3 {
    bucket: Box<Bucket>,
}

impl BlobS3 {
    pub fn from_config(cfg: &S3Config) -> S3Result<Self> {
        let endpoint = normalize_endpoint(&cfg.endpoint, cfg.secure);
        let region = s3::Region::Custom {
            region: cfg.region.clone(),
            endpoint,
        };
        let credentials = Credentials::new(
            Some(&cfg.access_key),
            Some(&cfg.secret_key),
            None,
            None,
            None,
        )
        .map_err(|e| S3BlobError::Msg(e.to_string()))?;

        let mut bucket = Bucket::new(&cfg.bucket, region, credentials)
            .map_err(|e| S3BlobError::Msg(e.to_string()))?;
        bucket.set_path_style();
        Ok(Self { bucket })
    }

    pub fn from_env() -> Option<S3Result<Self>> {
        S3Config::from_env().map(|cfg| Self::from_config(&cfg))
    }

    pub fn object_key(hash: &str) -> String {
        format!("fs/{hash}")
    }

    pub fn loc_json(hash: &str) -> serde_json::Value {
        serde_json::json!({ "key": Self::object_key(hash) })
    }

    pub async fn put(&self, hash: &str, body: &[u8], mime: &str) -> S3Result<()> {
        let key = Self::object_key(hash);
        let response = self
            .bucket
            .put_object_with_content_type(&key, body, mime)
            .await
            .map_err(|e| S3BlobError::Msg(e.to_string()))?;
        let status = response.status_code();
        if status != 200 {
            return Err(S3BlobError::Msg(format!("put_object {key}: HTTP {status}")));
        }
        Ok(())
    }

    pub async fn get_key(&self, key: &str) -> S3Result<(Vec<u8>, String)> {
        let response = self
            .bucket
            .get_object(key)
            .await
            .map_err(|e| S3BlobError::Msg(e.to_string()))?;
        let status = response.status_code();
        if status == 404 {
            return Err(S3BlobError::Msg(format!("get_object {key}: not found")));
        }
        if status != 200 {
            return Err(S3BlobError::Msg(format!("get_object {key}: HTTP {status}")));
        }
        let body = response.bytes().to_vec();
        if is_s3_error_xml(&body) {
            return Err(S3BlobError::Msg(format!("get_object {key}: not found")));
        }
        let mime = response
            .headers()
            .get("Content-Type")
            .cloned()
            .unwrap_or_else(|| mime_from_key(key));
        Ok((body, mime))
    }
}

fn is_s3_error_xml(body: &[u8]) -> bool {
    body.starts_with(b"<?xml") && body.windows(8).any(|w| w == b"NoSuchKey")
}

fn mime_from_key(key: &str) -> String {
    let name = key.rsplit('/').next().unwrap_or(key);
    let ext = name.rsplit('.').next().unwrap_or("");
    match ext.to_ascii_lowercase().as_str() {
        "html" => "text/html; charset=utf-8",
        "js" => "text/javascript; charset=utf-8",
        "css" => "text/css; charset=utf-8",
        "json" => "application/json; charset=utf-8",
        "wasm" => "application/wasm",
        "png" => "image/png",
        "jpg" | "jpeg" => "image/jpeg",
        "webp" => "image/webp",
        "svg" => "image/svg+xml",
        "ico" => "image/x-icon",
        "woff" => "font/woff",
        "woff2" => "font/woff2",
        "ttf" => "font/ttf",
        "txt" => "text/plain; charset=utf-8",
        _ => "application/octet-stream",
    }
    .into()
}

fn normalize_endpoint(endpoint: &str, secure: bool) -> String {
    if endpoint.starts_with("http://") || endpoint.starts_with("https://") {
        return endpoint.to_string();
    }
    if secure {
        format!("https://{endpoint}")
    } else {
        format!("http://{endpoint}")
    }
}
