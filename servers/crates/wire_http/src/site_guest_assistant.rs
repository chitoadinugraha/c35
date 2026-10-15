//! Public guest storefront AI chat (`POST /v1/site/guest-assistant/chat`).

use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};
use std::time::{Duration, Instant};

use axum::{
    body::Bytes,
    extract::State,
    http::{header, HeaderMap, HeaderValue, StatusCode},
    response::{IntoResponse, Response},
    routing::post,
    Json, Router,
};
use c35_ctx::AppState;
use c35_mod_chat::{
    guest_cart_patch, guest_site_data_mode_from_boot_mode, site_guest_context_prepare,
    site_guest_live_system_prompt_build, site_guest_turn_with_hooks, GuestSiteDataMode,
};
use c35_proto::Message;
use c35_store::snowflake_id;
use serde::Deserialize;
use serde_json::json;

const RATE_LIMIT_WINDOW: Duration = Duration::from_secs(60);
const RATE_LIMIT_MAX: u32 = 40;

const LIVE_RATE_LIMIT_WINDOW: Duration = Duration::from_secs(3600);
const LIVE_RATE_LIMIT_MAX: u32 = 6;

fn live_rate_buckets() -> &'static Mutex<HashMap<String, (u32, Instant)>> {
    static LIVE_BUCKETS: OnceLock<Mutex<HashMap<String, (u32, Instant)>>> = OnceLock::new();
    LIVE_BUCKETS.get_or_init(|| Mutex::new(HashMap::new()))
}

fn live_rate_limit_check(key: &str) -> Result<(), u64> {
    let now = Instant::now();
    let mut guard = live_rate_buckets().lock().unwrap_or_else(|e| e.into_inner());
    let entry = guard.entry(key.to_string()).or_insert((0, now));
    let elapsed = now.duration_since(entry.1);
    if elapsed > LIVE_RATE_LIMIT_WINDOW {
        *entry = (0, now);
    }
    if entry.0 >= LIVE_RATE_LIMIT_MAX {
        let retry_after = LIVE_RATE_LIMIT_WINDOW.saturating_sub(elapsed).as_secs().max(1);
        return Err(retry_after);
    }
    entry.0 += 1;
    Ok(())
}

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
            HeaderValue::from_static("content-type, x-visitor-id, authorization"),
        );
        resp.headers_mut()
            .insert(header::VARY, HeaderValue::from_static("Origin"));
    }
    resp
}

pub fn site_guest_assistant_router() -> Router<AppState> {
    Router::new()
        .route(
            "/v1/site/guest-assistant/chat",
            post(guest_assistant_chat_post).options(guest_assistant_chat_options),
        )
        .route(
            "/v1/site/guest-assistant/live/setup",
            post(guest_assistant_live_setup_post).options(guest_assistant_live_setup_options),
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
    /// `draft` uses `site.draft` meta (preview / `?draft=1`); default requires published snapshot.
    boot_mode: Option<String>,
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
    let data_mode = guest_site_data_mode_from_boot_mode(body.boot_mode.as_deref());
    match site_guest_turn_with_hooks(
        &st.pool,
        st.nats.as_ref(),
        body.site_iid,
        &visitor_id,
        &body.message,
        &req_id,
        data_mode,
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

async fn guest_assistant_live_setup_options(headers: HeaderMap) -> Response {
    let origin = headers
        .get(header::ORIGIN)
        .and_then(|h| h.to_str().ok())
        .unwrap_or("");
    with_cors(StatusCode::NO_CONTENT.into_response(), origin)
}

#[derive(Deserialize, Debug, Default)]
struct GuestLiveSetupInput {
    #[serde(default)]
    site_iid: i64,
    visitor_id: Option<String>,
    boot_mode: Option<String>,
    locale: Option<String>,
    req_id: Option<String>,
}

fn parse_live_setup_body(bytes: &[u8], headers: &HeaderMap) -> GuestLiveSetupInput {
    let content_type = headers
        .get(header::CONTENT_TYPE)
        .and_then(|h| h.to_str().ok())
        .unwrap_or("");

    if (content_type.contains("application/x-protobuf") || content_type.contains("application/protobuf"))
        && !bytes.is_empty()
    {
        if let Ok(pb) = c35_proto::ReqSiteGuestAssistantLiveSetup::decode(bytes) {
            return GuestLiveSetupInput {
                site_iid: pb.site_iid,
                visitor_id: if pb.visitor_id.is_empty() { None } else { Some(pb.visitor_id) },
                boot_mode: if pb.boot_mode.is_empty() { None } else { Some(pb.boot_mode) },
                locale: if pb.locale.is_empty() { None } else { Some(pb.locale) },
                req_id: if pb.req_id.is_empty() { None } else { Some(pb.req_id) },
            };
        }
    }

    if let Ok(parsed) = serde_json::from_slice::<GuestLiveSetupInput>(bytes) {
        if parsed.site_iid > 0 || parsed.visitor_id.is_some() {
            return parsed;
        }
    }

    if let Ok(s) = std::str::from_utf8(bytes) {
        let mut b = GuestLiveSetupInput::default();
        for pair in s.split('&') {
            if let Some((k, v)) = pair.split_once('=') {
                let dec = urlencoding::decode(v).unwrap_or_default();
                match k.trim() {
                    "site_iid" => b.site_iid = dec.parse().unwrap_or(0),
                    "visitor_id" => b.visitor_id = Some(dec.to_string()),
                    "boot_mode" => b.boot_mode = Some(dec.to_string()),
                    "locale" => b.locale = Some(dec.to_string()),
                    "req_id" => b.req_id = Some(dec.to_string()),
                    _ => {}
                }
            }
        }
        if b.site_iid > 0 || b.visitor_id.is_some() {
            return b;
        }
    }

    GuestLiveSetupInput::default()
}

fn live_setup_respond(
    headers: &HeaderMap,
    origin: &str,
    status: StatusCode,
    ok: bool,
    error: &str,
    req_id: &str,
    live_session_id: &str,
    ws_path: &str,
    max_duration_sec: i32,
) -> Response {
    let accept = headers
        .get(header::ACCEPT)
        .and_then(|h| h.to_str().ok())
        .unwrap_or("");
    if accept.contains("application/x-protobuf") || accept.contains("application/protobuf") {
        let pb = c35_proto::ResSiteGuestAssistantLiveSetup {
            ok,
            error: error.to_string(),
            req_id: req_id.to_string(),
            live_session_id: live_session_id.to_string(),
            ws_path: ws_path.to_string(),
            max_duration_sec,
        };
        let mut resp = (status, pb.encode_to_vec()).into_response();
        resp.headers_mut().insert(
            header::CONTENT_TYPE,
            HeaderValue::from_static("application/x-protobuf"),
        );
        with_cors(resp, origin)
    } else {
        with_cors(
            (
                status,
                Json(json!({
                    "ok": ok,
                    "error": error,
                    "req_id": req_id,
                    "live_session_id": live_session_id,
                    "ws_path": ws_path,
                    "max_duration_sec": max_duration_sec,
                })),
            )
                .into_response(),
            origin,
        )
    }
}

async fn guest_assistant_live_setup_post(
    State(st): State<AppState>,
    headers: HeaderMap,
    body: Bytes,
) -> Response {
    let origin = headers
        .get(header::ORIGIN)
        .and_then(|h| h.to_str().ok())
        .unwrap_or("");

    let parsed = parse_live_setup_body(&body, &headers);
    let req_id = parsed
        .req_id
        .filter(|s| !s.trim().is_empty())
        .unwrap_or_else(|| snowflake_id().to_string());

    let visitor_id = parsed
        .visitor_id
        .as_deref()
        .or_else(|| headers.get("x-visitor-id").and_then(|h| h.to_str().ok()))
        .unwrap_or("")
        .trim()
        .to_string();

    if parsed.site_iid <= 0 {
        return live_setup_respond(
            &headers,
            origin,
            StatusCode::BAD_REQUEST,
            false,
            "site_iid required",
            &req_id,
            "",
            "",
            0,
        );
    }

    if visitor_id.is_empty() {
        return live_setup_respond(
            &headers,
            origin,
            StatusCode::BAD_REQUEST,
            false,
            "visitor_id required",
            &req_id,
            "",
            "",
            0,
        );
    }

    // Rate limiting: (site_iid, visitor_id, ip)
    let ip = client_ip(&headers);
    let rl_key = rate_limit_key(parsed.site_iid, &visitor_id, &ip);
    if let Err(retry_after) = live_rate_limit_check(&rl_key) {
        let mut resp = live_setup_respond(
            &headers,
            origin,
            StatusCode::TOO_MANY_REQUESTS,
            false,
            "rate limit exceeded for live calls. please try again later.",
            &req_id,
            "",
            "",
            0,
        );
        if let Ok(v) = HeaderValue::from_str(&retry_after.to_string()) {
            resp.headers_mut().insert(header::RETRY_AFTER, v);
        }
        return resp;
    }

    // Context loading via site_guest_context_prepare
    let data_mode = guest_site_data_mode_from_boot_mode(parsed.boot_mode.as_deref());
    let ctx = match site_guest_context_prepare(&st.pool, parsed.site_iid, data_mode).await {
        Ok(c) => c,
        Err(e) => {
            return live_setup_respond(
                &headers,
                origin,
                StatusCode::BAD_REQUEST,
                false,
                &e.to_string(),
                &req_id,
                "",
                "",
                0,
            );
        }
    };

    // Verify call_enabled gate
    if let Err(e) = ctx.ensure_call_enabled() {
        return live_setup_respond(
            &headers,
            origin,
            StatusCode::BAD_REQUEST,
            false,
            &e.to_string(),
            &req_id,
            "",
            "",
            0,
        );
    }

    // Verify C35_LIVE_ENABLED gate (same check as live_start_rpc)
    if !c35_mod_live::live_enabled() {
        return live_setup_respond(
            &headers,
            origin,
            StatusCode::OK,
            false,
            "Live call is not available yet",
            &req_id,
            "",
            "",
            0,
        );
    }

    // Resolve guest live offer
    let guest_offer_id = std::env::var("C35_GUEST_LIVE_OFFER_ID")
        .unwrap_or_else(|_| "live.alienai".to_string());
    let Some(offer) = c35_mod_live::live_offer_resolve(&st.pool, &guest_offer_id).await else {
        return live_setup_respond(
            &headers,
            origin,
            StatusCode::BAD_REQUEST,
            false,
            "Guest live offer unavailable",
            &req_id,
            "",
            "",
            0,
        );
    };
    if !offer.enabled {
        return live_setup_respond(
            &headers,
            origin,
            StatusCode::BAD_REQUEST,
            false,
            "This live call option is not available yet",
            &req_id,
            "",
            "",
            0,
        );
    }

    // Billing hold on ctx.owner_iid
    let sid = snowflake_id().to_string();
    let billing_req_id = c35_mod_live::live_req_id(&req_id, &sid);
    let billing_row = match c35_mod_live::live_billing_gate_nats(
        &st.pool,
        st.nats.as_ref(),
        ctx.owner_iid,
        &billing_req_id,
        &offer,
    )
    .await
    {
        Ok(r) => r,
        Err(e) => {
            return live_setup_respond(
                &headers,
                origin,
                StatusCode::PAYMENT_REQUIRED,
                false,
                &format!("Storefront live call billing error: {e}"),
                &req_id,
                "",
                "",
                0,
            );
        }
    };

    // System prompt snapshot
    let guest_system_prompt =
        site_guest_live_system_prompt_build(&st.pool, &ctx, &offer.provider_model).await;

    // Register guest live session ticket
    let data_mode_str = match data_mode {
        GuestSiteDataMode::Draft => "draft",
        GuestSiteDataMode::Published => "published",
    };
    let (_token, ws_path) = c35_mod_live::guest_live_session_register(
        &sid,
        ctx.owner_iid,
        offer,
        billing_req_id,
        billing_row,
        parsed.site_iid,
        visitor_id,
        data_mode_str.to_string(),
        guest_system_prompt,
    );

    let max_duration_sec = std::env::var("C35_GUEST_LIVE_MAX_SEC")
        .ok()
        .and_then(|v| v.parse::<i32>().ok())
        .unwrap_or(900);

    live_setup_respond(
        &headers,
        origin,
        StatusCode::OK,
        true,
        "",
        &req_id,
        &sid,
        &ws_path,
        max_duration_sec,
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_live_setup_body_json() {
        let headers = HeaderMap::new();
        let json_bytes = br#"{"site_iid": 9901, "visitor_id": "v-123", "boot_mode": "draft", "locale": "en", "req_id": "r-1"}"#;
        let parsed = parse_live_setup_body(json_bytes, &headers);
        assert_eq!(parsed.site_iid, 9901);
        assert_eq!(parsed.visitor_id.as_deref(), Some("v-123"));
        assert_eq!(parsed.boot_mode.as_deref(), Some("draft"));
        assert_eq!(parsed.locale.as_deref(), Some("en"));
        assert_eq!(parsed.req_id.as_deref(), Some("r-1"));
    }

    #[test]
    fn test_parse_live_setup_body_form() {
        let headers = HeaderMap::new();
        let form_bytes = b"site_iid=8802&visitor_id=v-form-456&boot_mode=published&locale=id&req_id=r-form";
        let parsed = parse_live_setup_body(form_bytes, &headers);
        assert_eq!(parsed.site_iid, 8802);
        assert_eq!(parsed.visitor_id.as_deref(), Some("v-form-456"));
        assert_eq!(parsed.boot_mode.as_deref(), Some("published"));
        assert_eq!(parsed.locale.as_deref(), Some("id"));
        assert_eq!(parsed.req_id.as_deref(), Some("r-form"));
    }

    #[test]
    fn test_parse_live_setup_body_protobuf() {
        let mut headers = HeaderMap::new();
        headers.insert(header::CONTENT_TYPE, HeaderValue::from_static("application/x-protobuf"));
        let pb = c35_proto::ReqSiteGuestAssistantLiveSetup {
            site_iid: 7703,
            visitor_id: "v-pb-789".to_string(),
            boot_mode: "draft".to_string(),
            locale: "ja".to_string(),
            req_id: "r-pb".to_string(),
        };
        let bytes = pb.encode_to_vec();
        let parsed = parse_live_setup_body(&bytes, &headers);
        assert_eq!(parsed.site_iid, 7703);
        assert_eq!(parsed.visitor_id.as_deref(), Some("v-pb-789"));
        assert_eq!(parsed.boot_mode.as_deref(), Some("draft"));
        assert_eq!(parsed.locale.as_deref(), Some("ja"));
        assert_eq!(parsed.req_id.as_deref(), Some("r-pb"));
    }

    #[test]
    fn test_live_rate_limit_stricter_cap() {
        let key = format!("test-rl-{}", snowflake_id());
        for _ in 0..LIVE_RATE_LIMIT_MAX {
            assert!(live_rate_limit_check(&key).is_ok());
        }
        let err = live_rate_limit_check(&key).expect_err("should exceed limit on 7th call");
        assert!(err > 0 && err <= LIVE_RATE_LIMIT_WINDOW.as_secs());
    }

    #[test]
    fn test_cors_origin_allowed_rules() {
        assert!(cors_origin_allowed("http://localhost:3000"));
        assert!(cors_origin_allowed("https://127.0.0.1:8080"));
        assert!(cors_origin_allowed("https://store.alienai.id"));
        assert!(cors_origin_allowed("https://alienai.id"));
        assert!(!cors_origin_allowed("https://malicious.example.com"));
        assert!(!cors_origin_allowed(""));
    }

    #[test]
    fn guest_live_setup_rejects_call_disabled() {
        use c35_mod_chat::{GuestContextError, GuestSiteContext};

        let ctx = GuestSiteContext {
            site: c35_mod_chat::SiteContext {
                site_iid: 1234,
                alien_id: "test-site".into(),
                name: "Test Site".into(),
            },
            owner_iid: 99000,
            meta: serde_json::json!({
                "ai_assistant": { "call_enabled": false }
            }),
            data_mode: GuestSiteDataMode::Draft,
            caps: c35_mod_chat::SiteCapabilityView::empty(),
            commerce: false,
            chat_enabled: true,
            call_enabled: false,
            site_context_block: String::new(),
            knowledge_block: String::new(),
            products_block: String::new(),
            chat_intro: None,
            call_intro: None,
        };
        let err = ctx.ensure_call_enabled().expect_err("should reject call when call_enabled is false");
        assert!(matches!(err, GuestContextError::CallDisabled));
        assert_eq!(err.to_string(), "guest call disabled");

        let headers = HeaderMap::new();
        let resp = live_setup_respond(
            &headers,
            "",
            StatusCode::BAD_REQUEST,
            false,
            &err.to_string(),
            "req-1",
            "",
            "",
            0,
        );
        assert_eq!(resp.status(), StatusCode::BAD_REQUEST);
    }
}
