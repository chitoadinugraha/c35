//! Flutter web static assets at `GET /app/*` from S3 prefix `app/web/current/`.

use axum::{
    extract::Path,
    http::{header, StatusCode},
    response::{IntoResponse, Redirect, Response},
    routing::get,
    Router,
};
use c35_ctx::AppState;
use c35_mod_file::s3_get_object;

pub const WEB_S3_PREFIX: &str = "app/web/current";

pub fn app_web_router() -> Router<AppState> {
    Router::new()
        .route("/app", get(app_web_redirect))
        .route("/app/", get(app_web_index))
        .route("/app/{*path}", get(app_web_get))
}

async fn app_web_redirect() -> Response {
    Redirect::permanent("/app/").into_response()
}

async fn app_web_index() -> Response {
    app_web_serve("").await
}

async fn app_web_get(Path(path): Path<String>) -> Response {
    app_web_serve(&path).await
}

async fn app_web_serve(rel_path: &str) -> Response {
    let Some(rel) = normalize_web_path(rel_path) else {
        return (StatusCode::BAD_REQUEST, "invalid path").into_response();
    };

    let key = s3_object_key(&rel);
    match s3_get_object(&key).await {
        Ok((bytes, mime)) => object_response(&rel, bytes, &mime),
        Err(e) if s3_not_configured(&e) => {
            (StatusCode::SERVICE_UNAVAILABLE, "web app storage not configured").into_response()
        }
        Err(e) if s3_not_found(&e) && spa_fallback_eligible(&rel) => {
            let index_key = s3_object_key("index.html");
            match s3_get_object(&index_key).await {
                Ok((bytes, mime)) => object_response("index.html", bytes, &mime),
                Err(e) if s3_not_configured(&e) => {
                    (StatusCode::SERVICE_UNAVAILABLE, "web app storage not configured").into_response()
                }
                _ => (StatusCode::NOT_FOUND, "not found").into_response(),
            }
        }
        Err(_) => (StatusCode::NOT_FOUND, "not found").into_response(),
    }
}

fn object_response(rel_path: &str, bytes: Vec<u8>, mime: &str) -> Response {
    let content_type = mime_type_for_path(rel_path).unwrap_or(mime);
    let cache = cache_control_for_path(rel_path);
    (
        StatusCode::OK,
        [
            (header::CONTENT_TYPE, content_type),
            (header::CACHE_CONTROL, cache),
        ],
        bytes,
    )
        .into_response()
}

pub fn normalize_web_path(path: &str) -> Option<String> {
    let clean = path.trim().trim_start_matches('/');
    if clean.contains("..") {
        return None;
    }
    Some(clean.to_string())
}

pub fn s3_object_key(rel_path: &str) -> String {
    let rel = rel_path.trim();
    if rel.is_empty() {
        format!("{}/index.html", WEB_S3_PREFIX)
    } else {
        format!("{}/{}", WEB_S3_PREFIX, rel)
    }
}

pub fn spa_fallback_eligible(rel_path: &str) -> bool {
    let rel = rel_path.trim();
    !rel.is_empty() && !rel.contains('.')
}

pub fn mime_type_for_path(path: &str) -> Option<&'static str> {
    let name = path.rsplit('/').next().unwrap_or(path);
    let ext = name.rsplit('.').next().unwrap_or("");
    match ext.to_ascii_lowercase().as_str() {
        "html" => Some("text/html; charset=utf-8"),
        "js" => Some("text/javascript; charset=utf-8"),
        "css" => Some("text/css; charset=utf-8"),
        "json" => Some("application/json; charset=utf-8"),
        "wasm" => Some("application/wasm"),
        "png" => Some("image/png"),
        "jpg" | "jpeg" => Some("image/jpeg"),
        "webp" => Some("image/webp"),
        "svg" => Some("image/svg+xml"),
        "ico" => Some("image/x-icon"),
        "woff" => Some("font/woff"),
        "woff2" => Some("font/woff2"),
        "ttf" => Some("font/ttf"),
        "txt" => Some("text/plain; charset=utf-8"),
        "" => None,
        _ => Some("application/octet-stream"),
    }
}

pub fn cache_control_for_path(path: &str) -> &'static str {
    let name = path.rsplit('/').next().unwrap_or(path);
    if name == "index.html" || name == "flutter_service_worker.js" {
        "public, max-age=60"
    } else {
        "public, max-age=31536000, immutable"
    }
}

fn s3_not_configured(err: &str) -> bool {
    err.contains("S3 not configured")
}

fn s3_not_found(err: &str) -> bool {
    err.contains("not found")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn normalize_web_path_strips_and_rejects_traversal() {
        assert_eq!(normalize_web_path(""), Some("".into()));
        assert_eq!(normalize_web_path("/"), Some("".into()));
        assert_eq!(normalize_web_path("main.dart.js"), Some("main.dart.js".into()));
        assert_eq!(normalize_web_path("/assets/logo.png"), Some("assets/logo.png".into()));
        assert!(normalize_web_path("../secret").is_none());
        assert!(normalize_web_path("assets/../secret").is_none());
    }

    #[test]
    fn s3_object_key_uses_prefix() {
        assert_eq!(s3_object_key(""), "app/web/current/index.html");
        assert_eq!(s3_object_key("main.dart.js"), "app/web/current/main.dart.js");
        assert_eq!(
            s3_object_key("assets/FontManifest.json"),
            "app/web/current/assets/FontManifest.json"
        );
    }

    #[test]
    fn spa_fallback_only_for_extensionless_paths() {
        assert!(!spa_fallback_eligible(""));
        assert!(spa_fallback_eligible("settings"));
        assert!(spa_fallback_eligible("chat/room"));
        assert!(!spa_fallback_eligible("main.dart.js"));
        assert!(!spa_fallback_eligible("assets/logo.png"));
    }

    #[test]
    fn mime_type_lookup() {
        assert_eq!(
            mime_type_for_path("index.html"),
            Some("text/html; charset=utf-8")
        );
        assert_eq!(
            mime_type_for_path("main.dart.js"),
            Some("text/javascript; charset=utf-8")
        );
        assert_eq!(mime_type_for_path("app.css"), Some("text/css; charset=utf-8"));
        assert_eq!(mime_type_for_path("canvaskit.wasm"), Some("application/wasm"));
        assert_eq!(mime_type_for_path("version.json"), Some("application/json; charset=utf-8"));
        assert_eq!(mime_type_for_path("noext"), Some("application/octet-stream"));
    }

    #[test]
    fn cache_control_short_for_shell_and_service_worker() {
        assert_eq!(cache_control_for_path("index.html"), "public, max-age=60");
        assert_eq!(
            cache_control_for_path("flutter_service_worker.js"),
            "public, max-age=60"
        );
        assert_eq!(
            cache_control_for_path("main.dart.js"),
            "public, max-age=31536000, immutable"
        );
        assert_eq!(
            cache_control_for_path("assets/NOTICES"),
            "public, max-age=31536000, immutable"
        );
    }
}
