use axum::{
    body::Bytes,
    extract::State,
    http::{header, StatusCode},
    response::{IntoResponse, Response},
    routing::post,
    Router,
};
use c35_ctx::AppState;

pub fn guest_queue_router() -> Router<AppState> {
    Router::new()
        .route("/v1/site/guest-queue/take", post(guest_queue_take_handler))
        .route("/v1/site/guest-queue/get", post(guest_queue_get_handler))
}

async fn guest_queue_take_handler(State(st): State<AppState>, body: Bytes) -> Response {
    let val = match serde_json::from_slice::<serde_json::Value>(&body) {
        Ok(v) => v,
        Err(e) => return json_error(StatusCode::BAD_REQUEST, format!("invalid json: {e}")),
    };
    let site_iid = val.get("site_iid").and_then(|x| x.as_i64()).unwrap_or(0);
    let queue_id = val.get("queue_id").and_then(|x| x.as_i64()).unwrap_or(0);
    let guest_name = val.get("guest_name").and_then(|x| x.as_str()).unwrap_or("");
    let guest_phone = val
        .get("guest_phone")
        .or_else(|| val.get("phone"))
        .and_then(|x| x.as_str())
        .unwrap_or("");
    match c35_mod_site::guest_queue_take(&st.pool, site_iid, queue_id, guest_name, guest_phone)
        .await
    {
        Ok(res) => json_ok(c35_mod_site::guest_queue_take_json(&res)),
        Err(e) => json_error(StatusCode::BAD_REQUEST, e.to_string()),
    }
}

async fn guest_queue_get_handler(State(st): State<AppState>, body: Bytes) -> Response {
    let val = match serde_json::from_slice::<serde_json::Value>(&body) {
        Ok(v) => v,
        Err(e) => return json_error(StatusCode::BAD_REQUEST, format!("invalid json: {e}")),
    };
    let site_iid = val.get("site_iid").and_then(|x| x.as_i64()).unwrap_or(0);
    let queue_id = val.get("queue_id").and_then(|x| x.as_i64()).unwrap_or(0);
    let ticket_id = val.get("ticket_id").and_then(|x| x.as_i64()).unwrap_or(0);
    match c35_mod_site::guest_queue_get(&st.pool, site_iid, queue_id, ticket_id).await {
        Ok(res) => {
            let status = if res.ok {
                StatusCode::OK
            } else if res.error.contains("not found") {
                StatusCode::NOT_FOUND
            } else {
                StatusCode::BAD_REQUEST
            };
            json_ok_status(status, c35_mod_site::guest_queue_get_json(&res))
        }
        Err(e) => json_error(StatusCode::BAD_REQUEST, e.to_string()),
    }
}

fn json_ok(body: serde_json::Value) -> Response {
    json_ok_status(StatusCode::OK, body)
}

fn json_ok_status(status: StatusCode, body: serde_json::Value) -> Response {
    (
        status,
        [(
            header::CONTENT_TYPE,
            header::HeaderValue::from_static("application/json"),
        )],
        body.to_string(),
    )
        .into_response()
}

fn json_error(status: StatusCode, msg: String) -> Response {
    (
        status,
        [(
            header::CONTENT_TYPE,
            header::HeaderValue::from_static("application/json"),
        )],
        serde_json::json!({ "ok": false, "error": msg }).to_string(),
    )
        .into_response()
}
