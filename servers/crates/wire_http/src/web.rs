use std::path::{Path as StdPath, PathBuf};
use axum::{
    extract::{Path, State},
    http::{header, HeaderMap, HeaderValue, StatusCode},
    response::{IntoResponse, Redirect, Response},
    routing::get,
    Router,
};
use c35_ctx::AppState;
use c35_mod_file::cas_bytes_get;

use crate::version::{DownloadKind, version_download_blob_resolve, version_download_resolve};

const MSIX_NOT_PUBLISHED: &str = "MSIX not published; use auto-update ZIP";

pub fn web_root_dir() -> PathBuf {
    if let Ok(dir) = std::env::var("WEB_ROOT_DIR") {
        return PathBuf::from(dir);
    }
    for candidate in &[
        "clients/web",
        "../clients/web",
        "../../clients/web",
        "../../../clients/web",
    ] {
        let p = PathBuf::from(candidate);
        if p.is_dir() {
            return p;
        }
    }
    PathBuf::from("clients/web")
}

fn mime_type(path: &StdPath) -> &'static str {
    match path.extension().and_then(|s| s.to_str()).unwrap_or("") {
        "html" => "text/html; charset=utf-8",
        "css" => "text/css; charset=utf-8",
        "js" => "text/javascript; charset=utf-8",
        "svg" => "image/svg+xml",
        "png" => "image/png",
        "jpg" | "jpeg" => "image/jpeg",
        "json" => "application/json; charset=utf-8",
        "ico" => "image/x-icon",
        "woff2" => "font/woff2",
        "txt" => "text/plain; charset=utf-8",
        "xml" => "application/xml; charset=utf-8",
        _ => "application/octet-stream",
    }
}

pub async fn root_get(State(state): State<AppState>, headers: HeaderMap) -> Response {
    if let Some(res) = c35_mod_site::try_custom_domain_root(State(state), headers).await {
        return res;
    }
    let web_dir = web_root_dir();
    let index_file = web_dir.join("index.html");
    if let Ok(bytes) = tokio::fs::read(&index_file).await {
        return (
            StatusCode::OK,
            [
                (header::CONTENT_TYPE, "text/html; charset=utf-8"),
                (header::CACHE_CONTROL, "public, max-age=60"),
            ],
            bytes,
        )
            .into_response();
    }
    (
        StatusCode::OK,
        [(header::CONTENT_TYPE, "text/html; charset=utf-8")],
        "<!DOCTYPE html><html><body><p>alienai.id</p></body></html>",
    )
        .into_response()
}

async fn page_get(file_name: &'static str) -> Response {
    let target = web_root_dir().join(file_name);
    if let Ok(bytes) = tokio::fs::read(&target).await {
        let content_type = mime_type(StdPath::new(file_name));
        return (
            StatusCode::OK,
            [
                (header::CONTENT_TYPE, content_type),
                (header::CACHE_CONTROL, "public, max-age=300"),
            ],
            bytes,
        )
            .into_response();
    }
    (StatusCode::NOT_FOUND, "page not found").into_response()
}

pub async fn locale_get(Path(file): Path<String>) -> Response {
    let clean = file.trim();
    if !clean.ends_with(".json")
        || !clean
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-' || c == '.')
    {
        return (StatusCode::BAD_REQUEST, "invalid locale file").into_response();
    }
    let target = web_root_dir().join("locales").join(clean);
    if let Ok(bytes) = tokio::fs::read(&target).await {
        return (
            StatusCode::OK,
            [
                (header::CONTENT_TYPE, "application/json; charset=utf-8"),
                (header::CACHE_CONTROL, "public, max-age=3600"),
            ],
            bytes,
        )
            .into_response();
    }
    (StatusCode::NOT_FOUND, "locale not found").into_response()
}

pub async fn static_get(Path(path): Path<String>) -> Response {
    let clean = path.trim_start_matches('/');
    if clean.contains("..") {
        return (StatusCode::BAD_REQUEST, "invalid path").into_response();
    }
    let target = web_root_dir().join("static").join(clean);
    if let Ok(bytes) = tokio::fs::read(&target).await {
        let content_type = mime_type(&target);
        return (
            StatusCode::OK,
            [
                (header::CONTENT_TYPE, content_type),
                (header::CACHE_CONTROL, "public, max-age=86400"),
            ],
            bytes,
        )
            .into_response();
    }
    (StatusCode::NOT_FOUND, "static asset not found").into_response()
}

fn download_content_disposition(filename: &str) -> HeaderValue {
    HeaderValue::from_str(&format!("attachment; filename=\"{filename}\""))
        .unwrap_or_else(|_| HeaderValue::from_static("attachment"))
}

async fn download_serve(
    st: AppState,
    platform: &'static str,
    kind: DownloadKind,
    filename: &'static str,
) -> Response {
    let hash = match version_download_blob_resolve(&st.pool, platform, kind).await {
        Ok(Some(h)) => h,
        Ok(None) => return (StatusCode::NOT_FOUND, "download not found").into_response(),
        Err(e) => {
            tracing::warn!(error = %e, platform, "download blob lookup failed");
            return (StatusCode::INTERNAL_SERVER_ERROR, "download lookup failed").into_response();
        }
    };
    match cas_bytes_get(&st.pool, &st.cas_dir, &hash).await {
        Ok((bytes, mime)) => {
            let mut headers = HeaderMap::new();
            if let Ok(v) = HeaderValue::from_str(&mime) {
                headers.insert(header::CONTENT_TYPE, v);
            }
            headers.insert(header::CONTENT_DISPOSITION, download_content_disposition(filename));
            headers.insert(
                header::CACHE_CONTROL,
                HeaderValue::from_static("public, max-age=300"),
            );
            (StatusCode::OK, headers, bytes).into_response()
        }
        Err(e) => {
            tracing::warn!(error = %e, platform, hash, "download blob read failed");
            (StatusCode::NOT_FOUND, "download not found").into_response()
        }
    }
}

async fn download_msix_redirect(st: AppState, platform: &'static str) -> Response {
    match version_download_resolve(
        &st.pool,
        &st.cas_secret,
        &st.public_origin,
        platform,
        DownloadKind::WindowsMsix,
    )
    .await
    {
        Ok(Some(url)) => Redirect::temporary(&url).into_response(),
        Ok(None) => (StatusCode::NOT_FOUND, MSIX_NOT_PUBLISHED).into_response(),
        Err(e) => {
            tracing::warn!(error = %e, platform, "download msix redirect lookup failed");
            (StatusCode::INTERNAL_SERVER_ERROR, "download lookup failed").into_response()
        }
    }
}

async fn download_app_apk(State(st): State<AppState>) -> Response {
    download_serve(st, "android", DownloadKind::Apk, "alienai.apk").await
}

async fn download_app_zip(State(st): State<AppState>) -> Response {
    download_serve(st, "windows", DownloadKind::WindowsZip, "alienai-app.zip").await
}

async fn download_app_msi(State(st): State<AppState>) -> Response {
    download_msix_redirect(st, "windows").await
}

async fn download_agent_install(State(st): State<AppState>) -> Response {
    let has_setup = matches!(
        version_download_blob_resolve(&st.pool, "remote-windows", DownloadKind::WindowsSetup).await,
        Ok(Some(_))
    );
    if has_setup {
        return download_serve(
            st,
            "remote-windows",
            DownloadKind::WindowsSetup,
            "AlienAI_Remote_Windows_Setup.exe",
        )
        .await;
    }
    download_serve(st, "remote-windows", DownloadKind::WindowsZip, "alienai.zip").await
}

async fn download_agent_zip(State(st): State<AppState>) -> Response {
    download_serve(st, "remote-windows", DownloadKind::WindowsZip, "alienai.zip").await
}

async fn download_agent_msi(State(st): State<AppState>) -> Response {
    download_msix_redirect(st, "remote-windows").await
}

async fn download_agent_update_ps1() -> Response {
    const SCRIPT: &str = include_str!("../scripts/agent_ota_rescue.ps1");
    (
        StatusCode::OK,
        [
            (header::CONTENT_TYPE, HeaderValue::from_static("text/plain; charset=utf-8")),
            (
                header::CONTENT_DISPOSITION,
                HeaderValue::from_static("attachment; filename=\"agent-update.ps1\""),
            ),
        ],
        SCRIPT,
    )
        .into_response()
}

pub fn web_router() -> Router<AppState> {
    Router::new()
        .route("/terms", get(|| page_get("terms.html")))
        .route("/terms.html", get(|| page_get("terms.html")))
        .route("/privacy", get(|| page_get("privacy.html")))
        .route("/privacy.html", get(|| page_get("privacy.html")))
        .route("/delete", get(|| page_get("delete.html")))
        .route("/delete.html", get(|| page_get("delete.html")))
        .route("/tts", get(|| page_get("tts.html")))
        .route("/tts.html", get(|| page_get("tts.html")))
        .route("/status", get(|| page_get("status.html")))
        .route("/status.html", get(|| page_get("status.html")))
        .route("/alien.svg", get(|| page_get("alien.svg")))
        .route("/favicon.ico", get(|| page_get("favicon.ico")))
        .route("/favicon-32x32.png", get(|| page_get("favicon-32x32.png")))
        .route("/favicon-48x48.png", get(|| page_get("favicon-48x48.png")))
        .route("/apple-touch-icon.png", get(|| page_get("apple-touch-icon.png")))
        .route("/robots.txt", get(|| page_get("robots.txt")))
        .route("/sitemap.xml", get(|| page_get("sitemap.xml")))
        .route("/locales/{file}", get(locale_get))
        .route("/static/{*path}", get(static_get))
        .route("/download/web", get(|| async {
            Redirect::temporary("https://alienai.id/app/")
        }))
        .route("/download/app.apk", get(download_app_apk))
        .route("/download/alienai.apk", get(download_app_apk))
        .route("/download/app.exe", get(download_app_zip))
        .route("/download/alienai-app.zip", get(download_app_zip))
        .route("/download/app.msi", get(download_app_msi))
        .route("/download/agent.exe", get(download_agent_install))
        .route("/download/alienai.zip", get(download_agent_zip))
        .route("/download/agent.zip", get(download_agent_zip))
        .route("/download/agent.msi", get(download_agent_msi))
        .route("/download/agent-update.ps1", get(download_agent_update_ps1))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_web_root_dir_and_files_exist() {
        let dir = web_root_dir();
        assert!(dir.is_dir(), "web_root_dir {:?} should be a directory", dir);
        assert!(dir.join("index.html").is_file(), "index.html must exist");
        assert!(dir.join("terms.html").is_file(), "terms.html must exist");
        assert!(dir.join("privacy.html").is_file(), "privacy.html must exist");
        assert!(dir.join("delete.html").is_file(), "delete.html must exist");
        assert!(dir.join("tts.html").is_file(), "tts.html must exist");
        assert!(dir.join("status.html").is_file(), "status.html must exist");
        assert!(dir.join("alien.svg").is_file(), "alien.svg must exist");
        assert!(dir.join("favicon.ico").is_file(), "favicon.ico must exist");
        assert!(dir.join("favicon-32x32.png").is_file(), "favicon-32x32.png must exist");
        assert!(dir.join("favicon-48x48.png").is_file(), "favicon-48x48.png must exist");
        assert!(dir.join("apple-touch-icon.png").is_file(), "apple-touch-icon.png must exist");
        assert!(dir.join("robots.txt").is_file(), "robots.txt must exist");
        assert!(dir.join("sitemap.xml").is_file(), "sitemap.xml must exist");
        assert!(dir.join("locales").join("en.json").is_file(), "locales/en.json must exist");
        assert!(dir.join("locales").join("id.json").is_file(), "locales/id.json must exist");
        assert!(dir.join("static").join("starry-night.js").is_file(), "static/starry-night.js must exist");
    }

    #[test]
    fn test_mime_type_lookup() {
        assert_eq!(mime_type(StdPath::new("index.html")), "text/html; charset=utf-8");
        assert_eq!(mime_type(StdPath::new("style.css")), "text/css; charset=utf-8");
        assert_eq!(mime_type(StdPath::new("starry-night.js")), "text/javascript; charset=utf-8");
        assert_eq!(mime_type(StdPath::new("alien.svg")), "image/svg+xml");
        assert_eq!(mime_type(StdPath::new("en.json")), "application/json; charset=utf-8");
        assert_eq!(mime_type(StdPath::new("sitemap.xml")), "application/xml; charset=utf-8");
        assert_eq!(mime_type(StdPath::new("robots.txt")), "text/plain; charset=utf-8");
    }
}

