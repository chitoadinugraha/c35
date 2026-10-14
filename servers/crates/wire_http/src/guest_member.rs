//! Guest member portal HTTP.

use axum::{
    body::Bytes,
    extract::State,
    http::{header, HeaderMap, StatusCode},
    response::{IntoResponse, Response},
    routing::post,
    Json, Router,
};
use c35_ctx::AppState;
use c35_mod_identity::auth_session_caller_iid;
use c35_mod_site::{site_capabilities_get, site_customer_profile, site_member_portal_enabled};
use c35_proto::{ReqSiteGuestMemberMe, ReqSiteGuestMemberMerge, ReqSiteGuestOrderList};
use prost::Message;
use serde::Deserialize;
use serde_json::json;

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
        if let Ok(v) = header::HeaderValue::from_str(origin) {
            resp.headers_mut()
                .insert(header::ACCESS_CONTROL_ALLOW_ORIGIN, v);
        }
        resp.headers_mut().insert(
            header::ACCESS_CONTROL_ALLOW_METHODS,
            header::HeaderValue::from_static("POST, OPTIONS"),
        );
        resp.headers_mut().insert(
            header::ACCESS_CONTROL_ALLOW_HEADERS,
            header::HeaderValue::from_static("content-type, x-visitor-id, authorization"),
        );
        resp.headers_mut()
            .insert(header::VARY, header::HeaderValue::from_static("Origin"));
    }
    resp
}

fn origin_from_headers(headers: &HeaderMap) -> String {
    headers
        .get(header::ORIGIN)
        .and_then(|h| h.to_str().ok())
        .unwrap_or("")
        .to_string()
}

async fn require_user(st: &AppState, headers: &HeaderMap, site_iid: i64) -> Result<i64, Response> {
    if site_iid <= 0 {
        return Err(json_err(StatusCode::BAD_REQUEST, "site_iid required"));
    }
    let caps = site_capabilities_get(&st.pool, site_iid).await; if !site_member_portal_enabled(&caps) {
        return Err(json_err(StatusCode::FORBIDDEN, "member portal disabled"));
    }
    match auth_session_caller_iid(&st.pool, headers, None).await {
        Some(uid) if uid > 0 => Ok(uid),
        _ => Err(json_err(StatusCode::UNAUTHORIZED, "sign in required")),
    }
}

fn json_err(status: StatusCode, msg: &str) -> Response {
    (status, Json(json!({ "ok": false, "error": msg }))).into_response()
}

pub fn guest_member_router() -> Router<AppState> {
    Router::new()
        .route("/v1/site/guest-member/me", post(guest_member_me))
        .route("/v1/site/guest-member/merge", post(guest_member_merge_handler))
        .route("/v1/site/guest-order/list", post(guest_order_list_handler))
}

#[derive(Deserialize)]
struct GuestMemberMeBody {
    site_iid: i64,
}

async fn guest_member_me(State(st): State<AppState>, headers: HeaderMap, body: Bytes) -> Response {
    let origin = origin_from_headers(&headers);
    let site_iid = parse_site_iid(&body);
    let user_iid = match require_user(&st, &headers, site_iid).await {
        Ok(u) => u,
        Err(r) => return with_cors(r, &origin),
    };
    match site_customer_profile(&st.pool, site_iid, user_iid).await {
        Ok(p) => with_cors(
            (
                StatusCode::OK,
                Json(json!({
                    "ok": true,
                    "user_iid": p.user_iid,
                    "display_name": p.display_name,
                    "pic": p.pic,
                    "email": p.email,
                    "contact_id": p.contact_id,
                })),
            )
                .into_response(),
            &origin,
        ),
        Err(e) => with_cors(json_err(StatusCode::BAD_REQUEST, &e.to_string()), &origin),
    }
}

async fn guest_member_merge_handler(
    State(st): State<AppState>,
    headers: HeaderMap,
    body: Bytes,
) -> Response {
    let origin = origin_from_headers(&headers);
    let req = decode_merge(&body);
    let site_iid = req.site_iid;
    let user_iid = match require_user(&st, &headers, site_iid).await {
        Ok(u) => u,
        Err(r) => return with_cors(r, &origin),
    };
    match c35_mod_tx::guest_member_merge(&st.pool, req, user_iid).await {
        Ok(res) => with_cors(
            (
                StatusCode::OK,
                Json(json!({
                    "ok": true,
                    "merged_count": res.merged_count,
                })),
            )
                .into_response(),
            &origin,
        ),
        Err(e) => with_cors(json_err(StatusCode::BAD_REQUEST, &e.to_string()), &origin),
    }
}

async fn guest_order_list_handler(
    State(st): State<AppState>,
    headers: HeaderMap,
    body: Bytes,
) -> Response {
    let origin = origin_from_headers(&headers);
    let req = decode_order_list(&body);
    let site_iid = req.site_iid;
    let user_iid = match require_user(&st, &headers, site_iid).await {
        Ok(u) => u,
        Err(r) => return with_cors(r, &origin),
    };
    match c35_mod_tx::guest_order_list(&st.pool, req, user_iid).await {
        Ok(res) => {
            let orders = res
                .orders
                .iter()
                .map(|o| {
                    json!({
                        "tx_id": o.tx_id,
                        "state": o.state,
                        "total": o.total,
                        "time_ts_ms": o.time_ts_ms,
                        "progress_label": o.progress_label,
                    })
                })
                .collect::<Vec<_>>();
            with_cors(
                (StatusCode::OK, Json(json!({ "ok": true, "orders": orders }))).into_response(),
                &origin,
            )
        }
        Err(e) => with_cors(json_err(StatusCode::BAD_REQUEST, &e.to_string()), &origin),
    }
}

fn parse_site_iid(body: &Bytes) -> i64 {
    if let Ok(r) = ReqSiteGuestMemberMe::decode(body.clone()) {
        return r.site_iid;
    }
    if let Ok(v) = serde_json::from_slice::<serde_json::Value>(body) {
        return v.get("site_iid").and_then(|x| x.as_i64()).unwrap_or(0);
    }
    0
}

fn decode_merge(body: &Bytes) -> ReqSiteGuestMemberMerge {
    if let Ok(r) = ReqSiteGuestMemberMerge::decode(body.clone()) {
        return r;
    }
    if let Ok(v) = serde_json::from_slice::<serde_json::Value>(body) {
        let order_ids = v
            .get("order_ids")
            .and_then(|a| a.as_array())
            .map(|a| a.iter().filter_map(|x| x.as_i64()).collect())
            .unwrap_or_default();
        return ReqSiteGuestMemberMerge {
            site_iid: v.get("site_iid").and_then(|x| x.as_i64()).unwrap_or(0),
            visitor_id: v
                .get("visitor_id")
                .and_then(|x| x.as_str())
                .unwrap_or("")
                .to_string(),
            order_ids,
        };
    }
    ReqSiteGuestMemberMerge::default()
}

fn decode_order_list(body: &Bytes) -> ReqSiteGuestOrderList {
    if let Ok(r) = ReqSiteGuestOrderList::decode(body.clone()) {
        return r;
    }
    if let Ok(v) = serde_json::from_slice::<serde_json::Value>(body) {
        return ReqSiteGuestOrderList {
            site_iid: v.get("site_iid").and_then(|x| x.as_i64()).unwrap_or(0),
        };
    }
    ReqSiteGuestOrderList::default()
}