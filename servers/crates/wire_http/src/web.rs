use std::path::{Path as StdPath, PathBuf};
use axum::{
    extract::{Path, State},
    http::{header, HeaderMap, StatusCode},
    response::{IntoResponse, Redirect, Response},
    routing::get,
    Router,
};
use c35_ctx::AppState;

use crate::version::{DownloadKind, version_download_resolve};

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

async fn download_redirect(st: AppState, platform: &'static str, kind: DownloadKind) -> Response {
    match version_download_resolve(&st.pool, &st.cas_secret, &st.public_origin, platform, kind).await {
        Ok(Some(url)) => Redirect::temporary(&url).into_response(),
        Ok(None) => (StatusCode::NOT_FOUND, "download not found").into_response(),
        Err(e) => {
            tracing::warn!(error = %e, platform, "download redirect lookup failed");
            (StatusCode::INTERNAL_SERVER_ERROR, "download lookup failed").into_response()
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
    download_redirect(st, "android", DownloadKind::Apk).await
}

async fn download_app_exe(State(st): State<AppState>) -> Response {
    download_redirect(st, "windows", DownloadKind::WindowsZip).await
}

async fn download_app_msi(State(st): State<AppState>) -> Response {
    download_msix_redirect(st, "windows").await
}

async fn download_agent_exe(State(st): State<AppState>) -> Response {
    download_redirect(st, "remote-windows", DownloadKind::WindowsZip).await
}

async fn download_agent_msi(State(st): State<AppState>) -> Response {
    download_msix_redirect(st, "remote-windows").await
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
        .route("/alien.svg", get(|| page_get("alien.svg")))
        .route("/locales/{file}", get(locale_get))
        .route("/static/{*path}", get(static_get))
        .route("/download/web", get(|| async {
            Redirect::temporary("https://alienai.id/app/")
        }))
        .route("/download/app.apk", get(download_app_apk))
        .route("/download/app.exe", get(download_app_exe))
        .route("/download/app.msi", get(download_app_msi))
        .route("/download/agent.exe", get(download_agent_exe))
        .route("/download/agent.msi", get(download_agent_msi))
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
        assert!(dir.join("alien.svg").is_file(), "alien.svg must exist");
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
    }
}

