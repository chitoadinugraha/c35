//! Public guest analytics ingest (`POST /v1/site/guest-analytics/*`).

use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};
use std::time::{Duration, Instant};

use axum::{
    extract::State,
    http::{header, HeaderMap, StatusCode},
    response::{IntoResponse, Response},
    routing::post,
    Json, Router,
};
use c35_ctx::AppState;
use c35_mod_site::{site_analytics_link_click, site_analytics_ping, SiteAnalyticsPing};
use serde::Deserialize;

const RATE_LIMIT_WINDOW: Duration = Duration::from_secs(60);
const RATE_LIMIT_MAX: u32 = 120;

fn rate_buckets() -> &'static Mutex<HashMap<String, (u32, Instant)>> {
    static BUCKETS: OnceLock<Mutex<HashMap<String, (u32, Instant)>>> = OnceLock::new();
    BUCKETS.get_or_init(|| Mutex::new(HashMap::new()))
}

fn rate_limit_key(site_key: &str, ip: &str) -> String {
    format!("{}:{}", site_key.trim(), ip)
}

fn rate_limit_check(key: &str) -> bool {
    let now = Instant::now();
    let mut guard = rate_buckets().lock().unwrap_or_else(|e| e.into_inner());
    let entry = guard.entry(key.to_string()).or_insert((0, now));
    if now.duration_since(entry.1) > RATE_LIMIT_WINDOW {
        *entry = (0, now);
    }
    if entry.0 >= RATE_LIMIT_MAX {
        return false;
    }
    entry.0 += 1;
    true
}

fn client_ip(headers: &HeaderMap) -> String {
    if let Some(v) = headers.get("x-forwarded-for").and_then(|h| h.to_str().ok()) {
        let ip = v.split(',').next().unwrap_or("").trim();
        if !ip.is_empty() {
            return ip.to_string();
        }
    }
    headers
        .get("x-real-ip")
        .and_then(|h| h.to_str().ok())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .unwrap_or("unknown")
        .to_string()
}

pub fn guest_analytics_router() -> Router<AppState> {
    Router::new()
        .route("/v1/site/guest-analytics/ping", post(guest_analytics_ping_handler))
        .route(
            "/v1/site/guest-analytics/link-click",
            post(guest_analytics_link_click_handler),
        )
}

async fn guest_analytics_ping_handler(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(body): Json<SiteAnalyticsPing>,
) -> Response {
    let ip = client_ip(&headers);
    let rl_key = rate_limit_key(&body.alien_id, &ip);
    if !rate_limit_check(&rl_key) {
        return (
            StatusCode::TOO_MANY_REQUESTS,
            Json(serde_json::json!({ "ok": false, "error": "rate limit" })),
        )
            .into_response();
    }
    match site_analytics_ping(&st.pool, body, &ip).await {
        Ok(()) => (
            StatusCode::NO_CONTENT,
            [(header::CACHE_CONTROL, "no-store")],
        )
            .into_response(),
        Err(e) => {
            let msg = e.to_string();
            let status = if msg.contains("not found") || msg.contains("not published") {
                StatusCode::NOT_FOUND
            } else {
                StatusCode::BAD_REQUEST
            };
            (
                status,
                Json(serde_json::json!({ "ok": false, "error": msg })),
            )
                .into_response()
        }
    }
}

#[derive(Deserialize)]
struct LinkClickBody {
    alien_id: String,
    link_id: i64,
    visitor_id: String,
}

async fn guest_analytics_link_click_handler(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(body): Json<LinkClickBody>,
) -> Response {
    let ip = client_ip(&headers);
    let rl_key = rate_limit_key(&body.alien_id, &ip);
    if !rate_limit_check(&rl_key) {
        return (
            StatusCode::TOO_MANY_REQUESTS,
            Json(serde_json::json!({ "ok": false, "error": "rate limit" })),
        )
            .into_response();
    }
    match site_analytics_link_click(
        &st.pool,
        &body.alien_id,
        body.link_id,
        &body.visitor_id,
    )
    .await
    {
        Ok(()) => (
            StatusCode::NO_CONTENT,
            [(header::CACHE_CONTROL, "no-store")],
        )
            .into_response(),
        Err(e) => {
            let msg = e.to_string();
            let status = if msg.contains("not found") || msg.contains("not published") {
                StatusCode::NOT_FOUND
            } else {
                StatusCode::BAD_REQUEST
            };
            (
                status,
                Json(serde_json::json!({ "ok": false, "error": msg })),
            )
                .into_response()
        }
    }
}
