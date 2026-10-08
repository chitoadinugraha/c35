use axum::{
    body::Bytes,
    extract::State,
    http::{header, StatusCode},
    response::{IntoResponse, Response},
    routing::post,
    Router,
};
use c35_ctx::AppState;

pub fn guest_reservation_router() -> Router<AppState> {
    Router::new().route(
        "/v1/site/guest-reservation/availability",
        post(guest_reservation_availability_handler),
    )
}

async fn guest_reservation_availability_handler(State(st): State<AppState>, body: Bytes) -> Response {
    let val = match serde_json::from_slice::<serde_json::Value>(&body) {
        Ok(v) => v,
        Err(e) => return text_response(StatusCode::BAD_REQUEST, format!("invalid json: {e}")),
    };
    let site_iid = val.get("site_iid").and_then(|x| x.as_i64()).unwrap_or(0);
    let product_id = val.get("product_id").and_then(|x| x.as_i64()).unwrap_or(0);
    let start_ts_ms = val.get("start_ts_ms").and_then(|x| x.as_i64()).unwrap_or(0);
    let end_ts_ms = val.get("end_ts_ms").and_then(|x| x.as_i64()).unwrap_or(0);
    let units = val.get("units").and_then(|x| x.as_i64()).unwrap_or(0);

    match c35_mod_site::guest_reservation_availability(
        &st.pool,
        site_iid,
        product_id,
        start_ts_ms,
        end_ts_ms,
        units,
    )
    .await
    {
        Ok(avail) => json_ok(avail.to_json()),
        Err(e) => text_response(StatusCode::BAD_REQUEST, e.to_string()),
    }
}

fn json_ok(body: serde_json::Value) -> Response {
    (
        StatusCode::OK,
        [(
            header::CONTENT_TYPE,
            header::HeaderValue::from_static("application/json"),
        )],
        body.to_string(),
    )
        .into_response()
}

fn text_response(status: StatusCode, msg: String) -> Response {
    (status, msg).into_response()
}
