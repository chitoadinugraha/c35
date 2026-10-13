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
use crate::guest_renderer::site_guest_render_ensure_current;
use crate::site_preview::{site_draft_html_render, site_published_html_render};
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
    "alienai",
];

#[derive(Debug, Deserialize)]
struct GuestQuery {
    draft: Option<String>,
}

fn draft_query_truthy(v: &str) -> bool {
    matches!(
        v.trim().to_ascii_lowercase().as_str(),
        "1" | "true" | "yes"
    )
}

fn is_draft_request(q: &GuestQuery) -> bool {
    q.draft.as_deref().map(draft_query_truthy).unwrap_or(false)
}

/// Local dev: re-run `page_html_render` on each request so renderer/CSS/JS changes show without republish.
fn guest_dev_live_render_enabled() -> bool {
    matches!(
        std::env::var("C35_GUEST_DEV_LIVE_RENDER")
            .ok()
            .as_deref(),
        Some("1") | Some("true") | Some("yes")
    ) || matches!(
        std::env::var("C35_DEV").ok().as_deref(),
        Some("1") | Some("true") | Some("yes")
    )
}

fn is_local_dev_host(headers: &HeaderMap) -> bool {
    let h = normalize_hostname(&request_host(headers));
    matches!(h.as_str(), "localhost" | "127.0.0.1" | "::1" | "0.0.0.0")
}

async fn serve_draft_html_page(
    pool: &sqlx::PgPool,
    site_id: i64,
    render_key: &str,
) -> Response {
    let page_path = render_key_to_page_path(render_key);
    match site_draft_html_render(pool, site_id, page_path).await {
        Ok((body, etag)) => draft_response(body, etag),
        Err(e) => guest_render_error_response(&e),
    }
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

const GUEST_BUSY_MESSAGE: &str =
    "This page is loading. Wait a moment and refresh.";

fn service_unavailable_page(message: &str) -> Response {
    let body = format!(
        "<!DOCTYPE html><html><body><h1>Please try again</h1><p>{}</p></body></html>",
        html_escape(message)
    );
    (
        StatusCode::SERVICE_UNAVAILABLE,
        [
            (header::CONTENT_TYPE, "text/html; charset=utf-8"),
            (header::RETRY_AFTER, "3"),
        ],
        body,
    )
        .into_response()
}

fn guest_busy_page() -> Response {
    service_unavailable_page(GUEST_BUSY_MESSAGE)
}

fn html_escape(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
}

fn is_site_not_found_err(err: &anyhow::Error) -> bool {
    err.to_string() == "site not found"
}

fn guest_resolve_error_response(err: &anyhow::Error) -> Response {
    if is_site_not_found_err(err) {
        return not_found_page();
    }
    tracing::warn!("guest site resolve failed: {:#}", err);
    guest_busy_page()
}

fn guest_render_error_response(err: &anyhow::Error) -> Response {
    tracing::warn!("guest site render failed: {:#}", err);
    guest_busy_page()
}

fn request_host(headers: &HeaderMap) -> String {
    headers
        .get(header::HOST)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("")
        .to_string()
}

pub fn host_is_api(host: &str) -> bool {
    normalize_hostname(host) == "api.alienai.id"
}

/// Platform hosts: guest `/{alien_id}` routing, not customer custom domains.
/// Defaults include `alienai.id`, `www.alienai.id`, and `site.alienai.id` (platform site CNAME target).
/// Extra hosts merge from `C35_PRIMARY_HOSTS` (comma-separated); cluster sets this in deployment.
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
    let mut hosts = vec![
        "alienai.id".to_string(),
        "www.alienai.id".to_string(),
        "site.alienai.id".to_string(),
    ];
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
        Ok(None) => return Some(not_found_page()),
        Err(e) => {
            tracing::warn!("custom domain lookup failed host={}: {:#}", host, e);
            return Some(guest_busy_page());
        }
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
        return match domain_site_id_verified(&state.pool, &host).await {
            Ok(Some(site_id)) => {
                let render_key = format!("html:/{}", alien_id.trim());
                serve_render_site(&state.pool, site_id, &render_key, &headers, Some(&query)).await
            }
            Ok(None) => not_found_page(),
            Err(e) => {
                tracing::warn!("custom domain lookup failed host={}: {:#}", host, e);
                guest_busy_page()
            }
        };
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
        return match domain_site_id_verified(&state.pool, &host).await {
            Ok(Some(site_id)) => {
                let full_path = format!("/{}/{}", alien_id.trim(), path.trim_start_matches('/'));
                let render_key = format!("html:{}", full_path);
                serve_render_site(&state.pool, site_id, &render_key, &headers, Some(&query)).await
            }
            Ok(None) => not_found_page(),
            Err(e) => {
                tracing::warn!("custom domain lookup failed host={}: {:#}", host, e);
                guest_busy_page()
            }
        };
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
    let key = crate::site_publish::guest_alien_id_key(alien_id);
    if key.is_empty() || RESERVED.iter().any(|r| r.eq_ignore_ascii_case(&key)) {
        return not_found_page();
    }
    match resolve_site_by_alien_id(pool, &key).await {
        Ok(site_id) => serve_render_site(pool, site_id, render_key, headers, query).await,
        Err(e) => guest_resolve_error_response(&e),
    }
}

async fn serve_render_site(
    pool: &sqlx::PgPool,
    site_id: i64,
    render_key: &str,
    headers: &HeaderMap,
    query: Option<&GuestQuery>,
) -> Response {
    if query.filter(|q| is_draft_request(q)).is_some() {
        return serve_draft_html_page(pool, site_id, render_key).await;
    }
    match site_published(pool, site_id).await {
        Ok(true) => {}
        Ok(false) => {
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
        Err(e) => {
            tracing::warn!("guest site_published check failed site_iid={}: {:#}", site_id, e);
            return guest_busy_page();
        }
    }
    if !(guest_dev_live_render_enabled() && is_local_dev_host(headers)) {
        if let Err(e) = site_guest_render_ensure_current(pool, site_id).await {
            tracing::warn!(
                "guest render version refresh skipped site_iid={}: {:#}",
                site_id,
                e
            );
        }
    }
    if guest_dev_live_render_enabled() && is_local_dev_host(headers) {
        let page_path = render_key_to_page_path(render_key);
        match site_published_html_render(pool, site_id, page_path).await {
            Ok((body, etag)) => return draft_response(body, etag),
            Err(e) => {
                tracing::warn!(
                    "guest dev live published render failed site_iid={}: {:#}",
                    site_id,
                    e
                );
            }
        }
    }
    match render_get(pool, site_id, render_key).await {
        Ok(Some((body, etag, content_type))) => render_response(body, etag, content_type, headers),
        Ok(None) if render_key == "html:/" => {
            match render_get(pool, site_id, "html:/").await {
                Ok(Some((body, etag, content_type))) => {
                    render_response(body, etag, content_type, headers)
                }
                Ok(None) | Err(_) => guest_busy_page(),
            }
        }
        Ok(None) => guest_busy_page(),
        Err(e) => guest_render_error_response(&e),
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

#[cfg(test)]
mod guest_http_tests {
    use super::*;

    #[test]
    fn site_not_found_is_only_explicit_message() {
        assert!(is_site_not_found_err(&anyhow::anyhow!("site not found")));
        assert!(!is_site_not_found_err(&anyhow::anyhow!("pool timed out")));
    }
}
