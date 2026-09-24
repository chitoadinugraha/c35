//! Guest site_render HTTP — `/{alien_id}` on primary hosts; Host-based `/` on custom domains.

use axum::{
    extract::{Path, Query, State},
    http::{header, HeaderMap, StatusCode},
    response::{IntoResponse, Response},
    routing::get,
    Router,
};
use c35_ctx::AppState;
use serde::Deserialize;
use sqlx::Row;

use crate::render::render_offline_html;
use crate::site_domain::{domain_site_id_verified, normalize_hostname};
use crate::site_preview::{site_draft_html_render, site_preview_token_verify};
use crate::site_publish::{render_get, resolve_site_by_alien_id, site_published};

const RESERVED: &[&str] = &[
    "a",
    "fs",
    "static",
    "health",
    "privacy.html",
    "terms.html",
    "delete.html",
    "404.html",
    "index.html",
    "alien.svg",
    "favicon.ico",
    ".well-known",
    "v1",
    "api",
];

#[derive(Debug, Deserialize)]
struct GuestQuery {
    draft: Option<String>,
    ptoken: Option<String>,
}

fn is_draft_request(q: &GuestQuery) -> bool {
    q.draft.as_deref() == Some("1")
}

fn preview_forbidden_page() -> Response {
    (
        StatusCode::FORBIDDEN,
        [(header::CONTENT_TYPE, "text/html; charset=utf-8")],
        "<!DOCTYPE html><html><body><h1>Preview expired</h1></body></html>",
    )
        .into_response()
}

fn render_key_to_page_path(render_key: &str) -> &str {
    render_key
        .strip_prefix("html:")
        .map(|p| if p.is_empty() { "/" } else { p })
        .unwrap_or("/")
}

fn not_found_page() -> Response {
    (
        StatusCode::NOT_FOUND,
        [(header::CONTENT_TYPE, "text/html; charset=utf-8")],
        "<!DOCTYPE html><html><body><h1>Not found</h1></body></html>",
    )
        .into_response()
}

fn request_host(headers: &HeaderMap) -> String {
    headers
        .get(header::HOST)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("")
        .to_string()
}

fn host_is_api(host: &str) -> bool {
    normalize_hostname(host) == "api.alienai.id"
}

pub fn host_is_primary(host: &str) -> bool {
    let h = normalize_hostname(host);
    if h.is_empty() {
        return true;
    }
    if host_is_api(&h) {
        return false;
    }
    if matches!(h.as_str(), "localhost" | "127.0.0.1" | "::1" | "0.0.0.0") {
        return true;
    }
    let mut hosts = vec!["alienai.id".to_string(), "www.alienai.id".to_string()];
    if let Ok(raw) = std::env::var("C35_PRIMARY_HOSTS") {
        for part in raw.split(',') {
            let p = normalize_hostname(part);
            if !p.is_empty() && !hosts.iter().any(|x| x == &p) {
                hosts.push(p);
            }
        }
    }
    hosts.iter().any(|p| p == &h)
}

pub fn site_render_router() -> Router<AppState> {
    Router::new()
        .route("/{alien_id}", get(guest_site_root))
        .route("/{alien_id}/", get(guest_site_root))
        .route("/{alien_id}/{*path}", get(guest_site_path))
}

/// Platform `GET /` hook — custom verified Host → site; else `None`.
pub async fn try_custom_domain_root(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Option<Response> {
    let host = request_host(&headers);
    if host_is_primary(&host) || host_is_api(&host) {
        return None;
    }
    let site_id = match domain_site_id_verified(&state.pool, &host).await {
        Ok(Some(id)) => id,
        _ => return Some(not_found_page()),
    };
    Some(serve_render_site(&state.pool, site_id, "html:/", &headers, None).await)
}

async fn guest_site_root(
    State(state): State<AppState>,
    Path(alien_id): Path<String>,
    Query(query): Query<GuestQuery>,
    headers: HeaderMap,
) -> Response {
    let host = request_host(&headers);
    if !host_is_primary(&host) {
        return not_found_page();
    }
    serve_render_path(&state.pool, &alien_id, "html:/", &headers, Some(&query)).await
}

async fn guest_site_path(
    State(state): State<AppState>,
    Path((alien_id, path)): Path<(String, String)>,
    Query(query): Query<GuestQuery>,
    headers: HeaderMap,
) -> Response {
    let host = request_host(&headers);
    if !host_is_primary(&host) {
        return not_found_page();
    }
    let page_path = if path.starts_with('/') {
        path
    } else {
        format!("/{}", path)
    };
    let render_key = if page_path == "/" {
        "html:/".to_string()
    } else {
        format!("html:{}", page_path)
    };
    serve_render_path(&state.pool, &alien_id, &render_key, &headers, Some(&query)).await
}

async fn serve_render_path(
    pool: &sqlx::PgPool,
    alien_id: &str,
    render_key: &str,
    headers: &HeaderMap,
    query: Option<&GuestQuery>,
) -> Response {
    let key = alien_id.trim();
    if key.is_empty() || RESERVED.iter().any(|r| r.eq_ignore_ascii_case(key)) {
        return not_found_page();
    }
    match resolve_site_by_alien_id(pool, key).await {
        Ok(site_id) => serve_render_site(pool, site_id, render_key, headers, query).await,
        Err(_) => not_found_page(),
    }
}

async fn serve_render_site(
    pool: &sqlx::PgPool,
    site_id: i64,
    render_key: &str,
    headers: &HeaderMap,
    query: Option<&GuestQuery>,
) -> Response {
    if let Some(q) = query.filter(|q| is_draft_request(q)) {
        let token = q.ptoken.as_deref().unwrap_or("").trim();
        if token.is_empty() {
            return preview_forbidden_page();
        }
        return match site_preview_token_verify(site_id, token) {
            Ok(true) => {
                let page_path = render_key_to_page_path(render_key);
                match site_draft_html_render(pool, site_id, page_path).await {
                    Ok((body, etag)) => draft_response(body, etag),
                    Err(_) => StatusCode::INTERNAL_SERVER_ERROR.into_response(),
                }
            }
            Ok(false) | Err(_) => preview_forbidden_page(),
        };
    }
    if !site_published(pool, site_id).await.unwrap_or(false) {
        let name = sqlx::query(r#"SELECT name FROM ai.identity WHERE id = $1"#)
            .bind(site_id)
            .fetch_optional(pool)
            .await
            .ok()
            .flatten()
            .map(|r| r.get::<String, _>("name"))
            .unwrap_or_else(|| "Site".into());
        return (
            StatusCode::SERVICE_UNAVAILABLE,
            [(header::CONTENT_TYPE, "text/html; charset=utf-8")],
            render_offline_html(&name),
        )
            .into_response();
    }
    match render_get(pool, site_id, render_key).await {
        Ok(Some((body, etag, content_type))) => render_response(body, etag, content_type, headers),
        Ok(None) if render_key == "html:/" => {
            match render_get(pool, site_id, "html:/").await {
                Ok(Some((body, etag, content_type))) => {
                    render_response(body, etag, content_type, headers)
                }
                _ => not_found_page(),
            }
        }
        Ok(None) => not_found_page(),
        Err(_) => StatusCode::INTERNAL_SERVER_ERROR.into_response(),
    }
}

fn draft_response(body: Vec<u8>, etag: String) -> Response {
    let mut res = (
        StatusCode::OK,
        [
            (header::CONTENT_TYPE, "text/html; charset=utf-8"),
            (header::CACHE_CONTROL, "private, no-store".into()),
        ],
        body,
    )
        .into_response();
    let etag = etag.trim();
    if !etag.is_empty() {
        if let Ok(v) = format!("\"{etag}\"").parse() {
            res.headers_mut().insert(header::ETAG, v);
        }
    }
    res
}

fn render_response(body: Vec<u8>, etag: String, content_type: String, headers: &HeaderMap) -> Response {
    let etag = etag.trim();
    if !etag.is_empty() {
        if let Some(inm) = headers.get(header::IF_NONE_MATCH).and_then(|v| v.to_str().ok()) {
            let matched = inm
                .split(',')
                .map(|s| s.trim().trim_matches('"'))
                .any(|s| s == etag || s == "*");
            if matched {
                return StatusCode::NOT_MODIFIED.into_response();
            }
        }
    }
    let mut res = (
        StatusCode::OK,
        [
            (header::CONTENT_TYPE, content_type),
            (header::CACHE_CONTROL, "public, max-age=30".into()),
        ],
        body,
    )
        .into_response();
    if !etag.is_empty() {
        if let Ok(v) = format!("\"{etag}\"").parse() {
            res.headers_mut().insert(header::ETAG, v);
        }
    }
    res
}
