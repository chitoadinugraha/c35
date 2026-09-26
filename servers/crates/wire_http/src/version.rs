use std::collections::HashMap;
use std::time::Duration;

use axum::extract::{Path, State};
use axum::http::{header, HeaderMap, StatusCode};
use axum::response::IntoResponse;
use axum::routing::get;
use axum::{Json, Router};
use c35_ctx::AppState;
use c35_mod_file::{cas_sign, CAS_URL_TTL};
use c35_store::db_retry;
use chrono::{DateTime, Utc};
use serde::Serialize;
use serde_json::Value;

const CONFIG_KEY_PREFIX: &str = "app.release.c35.";

#[derive(Debug, Clone, Serialize, PartialEq)]
pub struct VersionRes {
    pub version: i64,
    #[serde(rename = "versionName")]
    pub version_name: String,
    pub min: i64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hash: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub size: Option<i64>,
    pub url: String,
    #[serde(rename = "apkHash", skip_serializing_if = "Option::is_none")]
    pub apk_hash: Option<String>,
    #[serde(rename = "apkSize", skip_serializing_if = "Option::is_none")]
    pub apk_size: Option<i64>,
    #[serde(rename = "apkUrl", skip_serializing_if = "Option::is_none")]
    pub apk_url: Option<String>,
    #[serde(rename = "setupHash", skip_serializing_if = "Option::is_none")]
    pub setup_hash: Option<String>,
    #[serde(rename = "setupSize", skip_serializing_if = "Option::is_none")]
    pub setup_size: Option<i64>,
    #[serde(rename = "setupUrl", skip_serializing_if = "Option::is_none")]
    pub setup_url: Option<String>,
}

#[derive(Debug, Serialize)]
struct VersionAllRes {
    platforms: HashMap<String, VersionAllPlatform>,
    history: Vec<VersionHistoryItem>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct VersionAllPlatform {
    version: i64,
    version_name: String,
    min: i64,
    url: String,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct VersionHistoryItem {
    platform: String,
    version: i64,
    version_name: String,
    url: String,
    updated_at: DateTime<Utc>,
}

pub fn version_router() -> Router<AppState> {
    Router::new()
        .route("/version", get(version_all))
        .route("/version/{platform}", get(version_get))
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DownloadKind {
    Apk,
    WindowsZip,
    WindowsSetup,
    WindowsMsix,
}

pub fn version_download_url(release: &VersionRes, stored: &Value, kind: DownloadKind) -> Option<String> {
    match kind {
        DownloadKind::Apk => release.apk_url.clone(),
        DownloadKind::WindowsZip => release.hash.as_deref().map(|_| release.url.clone()),
        DownloadKind::WindowsSetup => release.setup_url.clone(),
        DownloadKind::WindowsMsix => version_store_msix_url(stored),
    }
}

fn version_store_msix_url(stored: &Value) -> Option<String> {
    for key in ["storeUrl", "store_url"] {
        if let Some(url) = stored
            .get(key)
            .and_then(|v| v.as_str())
            .filter(|s| s.contains(".msix"))
        {
            return Some(url.to_string());
        }
    }
    stored
        .get("url")
        .and_then(|v| v.as_str())
        .filter(|s| s.contains(".msix"))
        .map(str::to_string)
}

pub async fn version_download_resolve(
    pool: &sqlx::PgPool,
    cas_secret: &str,
    public_origin: &str,
    platform: &str,
    kind: DownloadKind,
) -> Result<Option<String>, sqlx::Error> {
    let Some(stored) = version_config_get(pool, platform).await? else {
        return Ok(None);
    };
    let Some(release) = version_release_build(&stored, cas_secret, public_origin, CAS_URL_TTL) else {
        return Ok(None);
    };
    Ok(version_download_url(&release, &stored, kind))
}

pub fn version_download_blob_hash(release: &VersionRes, kind: DownloadKind) -> Option<String> {
    match kind {
        DownloadKind::Apk => release.apk_hash.clone(),
        DownloadKind::WindowsZip => release.hash.clone(),
        DownloadKind::WindowsSetup => release.setup_hash.clone(),
        DownloadKind::WindowsMsix => None,
    }
}

pub async fn version_download_blob_resolve(
    pool: &sqlx::PgPool,
    platform: &str,
    kind: DownloadKind,
) -> Result<Option<String>, sqlx::Error> {
    let Some(stored) = version_config_get(pool, platform).await? else {
        return Ok(None);
    };
    let Some(release) = version_release_build(&stored, "unused", "https://unused", Duration::from_secs(1))
    else {
        return Ok(None);
    };
    Ok(version_download_blob_hash(&release, kind))
}

pub fn version_release_build(stored: &Value, secret: &str, origin: &str, ttl: Duration) -> Option<VersionRes> {
    let version = stored.get("version").and_then(json_i64)?;
    if version <= 0 {
        return None;
    }
    let version_name = stored
        .get("versionName")
        .and_then(|v| v.as_str())
        .filter(|s| !s.is_empty())
        .map(str::to_string)
        .unwrap_or_else(|| version.to_string());
    let min = stored.get("min").and_then(json_i64).unwrap_or(0);
    let hash = stored
        .get("hash")
        .and_then(|v| v.as_str())
        .filter(|s| !s.is_empty())
        .map(str::to_string);
    let size = stored.get("size").and_then(json_i64);
    let apk_hash = stored
        .get("apkHash")
        .and_then(|v| v.as_str())
        .filter(|s| !s.is_empty())
        .map(str::to_string);
    let apk_size = stored.get("apkSize").and_then(json_i64);
    let base = origin.trim_end_matches('/');
    let url = match hash.as_deref() {
        Some(h) => format!("{base}{}", cas_sign(secret, h, ttl)),
        None => stored
            .get("url")
            .and_then(|v| v.as_str())
            .filter(|s| !s.is_empty())
            .map(str::to_string)?,
    };
    let apk_url = apk_hash
        .as_deref()
        .map(|h| format!("{base}{}", cas_sign(secret, h, ttl)));
    let setup_hash = stored
        .get("setupHash")
        .and_then(|v| v.as_str())
        .filter(|s| !s.is_empty())
        .map(str::to_string);
    let setup_size = stored.get("setupSize").and_then(json_i64);
    let setup_url = setup_hash
        .as_deref()
        .map(|h| format!("{base}{}", cas_sign(secret, h, ttl)));
    Some(VersionRes {
        version,
        version_name,
        min,
        hash,
        size,
        url,
        apk_hash,
        apk_size,
        apk_url,
        setup_hash,
        setup_size,
        setup_url,
    })
}

async fn version_config_get(pool: &sqlx::PgPool, platform: &str) -> Result<Option<Value>, sqlx::Error> {
    let key = format!("{CONFIG_KEY_PREFIX}{platform}");
    db_retry(pool, || async {
        let row: Option<(Value,)> = sqlx::query_as("SELECT value FROM ai.config WHERE key = $1")
            .bind(&key)
            .fetch_optional(pool)
            .await?;
        Ok(row.map(|(v,)| v))
    })
    .await
}

async fn version_all(State(st): State<AppState>) -> impl IntoResponse {
    let rows = db_retry(&st.pool, || async {
        sqlx::query_as::<_, (String, Value, DateTime<Utc>)>(
            "SELECT key, value, updated_at FROM ai.config WHERE key LIKE $1 ORDER BY updated_at DESC",
        )
        .bind(format!("{CONFIG_KEY_PREFIX}%"))
        .fetch_all(&st.pool)
        .await
    })
    .await;
    let rows = match rows {
        Ok(r) => r,
        Err(e) => {
            tracing::warn!(error = %e, "version all: config list failed");
            return (StatusCode::INTERNAL_SERVER_ERROR, "version lookup failed").into_response();
        }
    };
    let mut platforms: HashMap<String, VersionAllPlatform> = HashMap::new();
    let mut history = Vec::new();
    for (key, value, updated_at) in rows {
        let platform = key.strip_prefix(CONFIG_KEY_PREFIX).unwrap_or(&key).to_string();
        let Some(body) = version_all_platform(&value, &st.cas_secret, &st.public_origin, CAS_URL_TTL) else {
            continue;
        };
        history.push(VersionHistoryItem {
            platform: platform.clone(),
            version: body.version,
            version_name: body.version_name.clone(),
            url: body.url.clone(),
            updated_at,
        });
        let replace = match platforms.get(&platform) {
            Some(existing) => body.version > existing.version,
            None => true,
        };
        if replace {
            platforms.insert(platform, body);
        }
    }
    let mut headers = HeaderMap::new();
    headers.insert(header::CACHE_CONTROL, "public, max-age=60".parse().unwrap());
    (StatusCode::OK, headers, Json(VersionAllRes { platforms, history })).into_response()
}

fn version_all_platform(stored: &Value, secret: &str, origin: &str, ttl: Duration) -> Option<VersionAllPlatform> {
    let built = version_release_build(stored, secret, origin, ttl)?;
    Some(VersionAllPlatform {
        version: built.version,
        version_name: built.version_name,
        min: built.min,
        url: built.url,
    })
}

async fn version_get(State(st): State<AppState>, Path(platform): Path<String>) -> impl IntoResponse {
    let platform = platform.trim().to_lowercase();
    if platform.is_empty() || !platform.chars().all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-') {
        return (StatusCode::BAD_REQUEST, "invalid platform").into_response();
    }
    let stored = match version_config_get(&st.pool, &platform).await {
        Ok(v) => v,
        Err(e) => {
            tracing::warn!(error = %e, platform = %platform, "version config read");
            return (StatusCode::INTERNAL_SERVER_ERROR, "version lookup failed").into_response();
        }
    };
    let stored = match stored {
        Some(v) => v,
        None => return (StatusCode::NOT_FOUND, "version not found").into_response(),
    };
    match version_release_build(&stored, &st.cas_secret, &st.public_origin, CAS_URL_TTL) {
        Some(body) => {
            let mut headers = HeaderMap::new();
            headers.insert(header::CACHE_CONTROL, "public, max-age=300".parse().unwrap());
            (StatusCode::OK, headers, Json(body)).into_response()
        }
        None => (StatusCode::NOT_FOUND, "version not found").into_response(),
    }
}

fn json_i64(v: &Value) -> Option<i64> {
    v.as_i64()
        .or_else(|| v.as_u64().map(|n| n as i64))
        .or_else(|| v.as_str().and_then(|s| s.parse().ok()))
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn version_release_build_windows_from_hash() {
        let stored = json!({
            "version": 235,
            "versionName": "20.235.0",
            "min": 200,
            "hash": "abc123",
            "size": 1024
        });
        let out = version_release_build(&stored, "dev-cas-hmac", "https://alienai.id", Duration::from_secs(3600)).unwrap();
        assert_eq!(out.version, 235);
        assert!(out.url.contains("/fs/abc123?"));
    }

    #[test]
    fn version_release_build_android_with_apk() {
        let stored = json!({
            "version": 234,
            "versionName": "20.234.0",
            "min": 0,
            "url": "https://play.google.com/store/apps/details?id=id.alienai.agent",
            "apkHash": "abc123",
            "apkSize": 4096
        });
        let out = version_release_build(&stored, "dev-cas-hmac", "https://alienai.id", Duration::from_secs(3600)).unwrap();
        assert_eq!(out.apk_hash.as_deref(), Some("abc123"));
        assert!(out.apk_url.as_ref().unwrap().contains("/fs/abc123?"));
    }

    #[test]
    fn version_download_blob_hash_from_release() {
        let release = version_release_build(
            &json!({ "version": 2, "hash": "winhash", "apkHash": "apkhash", "size": 1 }),
            "secret",
            "https://alienai.id",
            Duration::from_secs(60),
        )
        .unwrap();
        assert_eq!(
            version_download_blob_hash(&release, DownloadKind::WindowsZip).as_deref(),
            Some("winhash")
        );
        assert_eq!(
            version_download_blob_hash(&release, DownloadKind::Apk).as_deref(),
            Some("apkhash")
        );
        assert!(version_download_blob_hash(&release, DownloadKind::WindowsMsix).is_none());
        assert!(version_download_blob_hash(&release, DownloadKind::WindowsSetup).is_none());
    }

    #[test]
    fn version_release_build_with_setup_hash() {
        let stored = json!({
            "version": 5,
            "versionName": "1.5.0",
            "min": 2,
            "hash": "otahash",
            "size": 1000,
            "setupHash": "setuphash",
            "setupSize": 2000
        });
        let out = version_release_build(&stored, "dev-cas-hmac", "https://alienai.id", Duration::from_secs(3600)).unwrap();
        assert_eq!(out.setup_hash.as_deref(), Some("setuphash"));
        assert!(out.setup_url.as_ref().unwrap().contains("/fs/setuphash?"));
        assert_eq!(
            version_download_blob_hash(&out, DownloadKind::WindowsSetup).as_deref(),
            Some("setuphash")
        );
    }

    #[test]
    fn version_download_url_apk_windows_and_msix() {
        let android = json!({
            "version": 234,
            "url": "https://play.google.com/store/apps/details?id=id.alienai.agent",
            "apkHash": "apkhash",
            "apkSize": 4096
        });
        let android_release = version_release_build(&android, "dev-cas-hmac", "https://alienai.id", Duration::from_secs(3600)).unwrap();
        assert!(version_download_url(&android_release, &android, DownloadKind::Apk)
            .unwrap()
            .contains("/fs/apkhash?"));

        let windows = json!({
            "version": 235,
            "hash": "winhash",
            "size": 1024
        });
        let windows_release = version_release_build(&windows, "dev-cas-hmac", "https://alienai.id", Duration::from_secs(3600)).unwrap();
        assert!(version_download_url(&windows_release, &windows, DownloadKind::WindowsZip)
            .unwrap()
            .contains("/fs/winhash?"));
        assert!(version_download_url(&windows_release, &windows, DownloadKind::WindowsMsix).is_none());

        let msix = json!({
            "version": 236,
            "hash": "winhash",
            "size": 1024,
            "storeUrl": "https://apps.microsoft.com/store/detail/alienai/9NABCDEF.msix"
        });
        let msix_release = version_release_build(&msix, "dev-cas-hmac", "https://alienai.id", Duration::from_secs(3600)).unwrap();
        assert_eq!(
            version_download_url(&msix_release, &msix, DownloadKind::WindowsMsix).as_deref(),
            Some("https://apps.microsoft.com/store/detail/alienai/9NABCDEF.msix")
        );
    }
}
