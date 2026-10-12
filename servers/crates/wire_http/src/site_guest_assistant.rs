//! Public guest storefront AI chat (`POST /v1/site/guest-assistant/chat`).

use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};
use std::time::{Duration, Instant};

use axum::{
    extract::State,
    http::{header, HeaderMap, HeaderValue, StatusCode},
    response::{IntoResponse, Response},
    routing::{options, post},
    Json, Router,
};
use c35_ctx::AppState;
use c35_mod_chat::{guest_cart_patch, site_guest_turn_with_hooks};
use c35_store::snowflake_id;
use serde::Deserialize;
use serde_json::json;

const RATE_LIMIT_WINDOW: Duration = Duration::from_secs(60);
const RATE_LIMIT_MAX: u32 = 40;

fn rate_buckets() -> &'static Mutex<HashMap<String, (u32, Instant)>> {
    static BUCKETS: OnceLock<Mutex<HashMap<String, (u32, Instant)>>> = OnceLock::new();
    BUCKETS.get_or_init(|| Mutex::new(HashMap::new()))
}

fn rate_limit_key(site_iid: i64, visitor_id: &str, ip: &str) -> String {
    format!("{}:{}:{}", site_iid, visitor_id.trim(), ip)
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

fn cors_origin_allowed(origin: &str) -> bool {
    let o = origin.trim().to_lowercase();
    if o.is_empty() {
        return false;
    }
    if o.contains("localhost") || o.contains("127.0.0.1") {
        return true;
    }
    o.ends_with("alienai.id") || o.contains(".alienai.id")
}

fn with_cors(mut resp: Response, origin: &str) -> Response {
    if cors_origin_allowed(origin) {
        if let Ok(v) = HeaderValue::from_str(origin) {
            resp.headers_mut()
                .insert(header::ACCESS_CONTROL_ALLOW_ORIGIN, v);
        }
        resp.headers_mut().insert(
            header::ACCESS_CONTROL_ALLOW_METHODS,
            HeaderValue::from_static("POST, OPTIONS"),
        );
        resp.headers_mut().insert(
            header::ACCESS_CONTROL_ALLOW_HEADERS,
            HeaderValue::from_static("content-type, x-visitor-id"),
        );
        resp.headers_mut()
            .insert(header::VARY, HeaderValue::from_static("Origin"));
    }
    resp
}

pub fn site_guest_assistant_router() -> Router<AppState> {
    Router::new().route(
        "/v1/site/guest-assistant/chat",
        post(guest_assistant_chat_post).options(guest_assistant_chat_options),
    )
}

async fn guest_assistant_chat_options(headers: HeaderMap) -> Response {
    let origin = headers
        .get(header::ORIGIN)
        .and_then(|h| h.to_str().ok())
        .unwrap_or("");
    with_cors(StatusCode::NO_CONTENT.into_response(), origin)
}

#[derive(Deserialize)]
struct GuestChatBody {
    site_iid: i64,
    visitor_id: Option<String>,
    message: String,
    #[serde(default)]
    stream: bool,
    cart: Option<serde_json::Value>,
}

async fn guest_assistant_chat_post(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(body): Json<GuestChatBody>,
) -> Response {
    let origin = headers
        .get(header::ORIGIN)
        .and_then(|h| h.to_str().ok())
        .unwrap_or("");
    let visitor_id = body
        .visitor_id
        .as_deref()
        .or_else(|| headers.get("x-visitor-id").and_then(|h| h.to_str().ok()))
        .unwrap_or("")
        .trim()
        .to_string();
    if visitor_id.is_empty() {
        return with_cors(
            (
                StatusCode::BAD_REQUEST,
                Json(json!({ "ok": false, "error": "visitor_id required" })),
            )
                .into_response(),
            origin,
        );
    }
    let ip = client_ip(&headers);
    let rl_key = rate_limit_key(body.site_iid, &visitor_id, &ip);
    if !rate_limit_check(&rl_key) {
        return with_cors(
            (
                StatusCode::TOO_MANY_REQUESTS,
                Json(json!({ "ok": false, "error": "rate limit" })),
            )
                .into_response(),
            origin,
        );
    }
    if let Some(cart) = body.cart.as_ref() {
        guest_cart_patch(body.site_iid, &visitor_id, cart);
    }
    let req_id = snowflake_id().to_string();
    if body.stream {
        return with_cors(
            (
                StatusCode::NOT_IMPLEMENTED,
                Json(json!({
                    "ok": false,
                    "error": "stream not implemented; omit stream or set false",
                    "req_id": req_id
                })),
            )
                .into_response(),
            origin,
        );
    }
    match site_guest_turn_with_hooks(
        &st.pool,
        st.nats.as_ref(),
        body.site_iid,
        &visitor_id,
        &body.message,
        &req_id,
        None,
        None,
    )
    .await
    {
        Ok(res) => with_cors(
            (
                StatusCode::OK,
                Json(json!({
                    "ok": true,
                    "req_id": req_id,
                    "text": res.text,
                    "blocks_json": res.blocks_json,
                    "model": res.model,
                    "tokens_in": res.tokens_in,
                    "tokens_out": res.tokens_out,
                    "cost_usd": res.cost_usd,
                    "duration_ms": res.duration_ms,
                    "inst_ids": res.inst_ids,
                })),
            )
                .into_response(),
            origin,
        ),
        Err(e) => with_cors(
            (
                StatusCode::BAD_REQUEST,
                Json(json!({ "ok": false, "error": e.to_string(), "req_id": req_id })),
            )
                .into_response(),
            origin,
        ),
    }
}
