use axum::{
    body::Bytes,
    extract::State,
    http::{header, StatusCode},
    response::{IntoResponse, Response},
    routing::post,
    Router,
};
use c35_ctx::AppState;
use c35_proto::{ReqSiteGuestOrderGet, ReqSiteGuestOrderPut};
use prost::Message;

pub fn guest_order_router() -> Router<AppState> {
    Router::new()
        .route("/v1/site/guest-order/put", post(guest_order_put_handler))
        .route("/v1/site/guest-order/get", post(guest_order_get_handler))
}

async fn guest_order_put_handler(State(st): State<AppState>, body: Bytes) -> Response {
    let req = match ReqSiteGuestOrderPut::decode(body) {
        Ok(r) => r,
        Err(e) => return text_response(StatusCode::BAD_REQUEST, format!("protobuf decode error: {e}")),
    };
    match c35_mod_tx::guest_order_put(&st.pool, req).await {
        Ok(res) => protobuf_response(StatusCode::OK, &res),
        Err(e) => text_response(StatusCode::BAD_REQUEST, e.to_string()),
    }
}

async fn guest_order_get_handler(State(st): State<AppState>, body: Bytes) -> Response {
    let req = match ReqSiteGuestOrderGet::decode(body) {
        Ok(r) => r,
        Err(e) => return text_response(StatusCode::BAD_REQUEST, format!("protobuf decode error: {e}")),
    };
    match c35_mod_tx::guest_order_get(&st.pool, req).await {
        Ok(res) => {
            if res.tx.is_none() {
                return text_response(StatusCode::NOT_FOUND, "order not found".into());
            }
            protobuf_response(StatusCode::OK, &res)
        }
        Err(e) => text_response(StatusCode::BAD_REQUEST, e.to_string()),
    }
}

fn protobuf_response<T: Message>(status: StatusCode, res: &T) -> Response {
    let mut buf = Vec::new();
    let _ = res.encode(&mut buf);
    (
        status,
        [(
            axum::http::header::CONTENT_TYPE,
            header::HeaderValue::from_static("application/x-protobuf"),
        )],
        buf,
    )
        .into_response()
}

fn text_response(status: StatusCode, msg: String) -> Response {
    (status, msg).into_response()
}
