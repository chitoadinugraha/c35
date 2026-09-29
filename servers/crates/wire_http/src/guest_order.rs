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

async fn guest_order_put_handler(
    State(st): State<AppState>,
    headers: axum::http::HeaderMap,
    body: Bytes,
) -> Response {
    let is_json_req = headers
        .get(header::CONTENT_TYPE)
        .and_then(|h| h.to_str().ok())
        .map(|ct| ct.contains("application/json"))
        .unwrap_or(false);

    let (req, from_json) = if let Ok(r) = ReqSiteGuestOrderPut::decode(body.clone()) {
        (r, false)
    } else if let Ok(val) = serde_json::from_slice::<serde_json::Value>(&body) {
        let site_iid = val.get("site_iid").and_then(|x| x.as_i64()).unwrap_or(0);
        let customer_name = val.get("customer_name").and_then(|x| x.as_str()).unwrap_or("").to_string();
        let customer_phone = val.get("customer_phone").and_then(|x| x.as_str()).unwrap_or("").to_string();
        let note = val.get("note").and_then(|x| x.as_str()).unwrap_or("").to_string();
        let tx_val = val.get("tx").unwrap_or(&val);
        match c35_mod_tx::tx_json_parse(tx_val) {
            Ok(mut tx) => {
                if !customer_name.is_empty() {
                    tx.subject_name = customer_name;
                }
                if !customer_phone.is_empty() {
                    tx.subject_phone = customer_phone;
                }
                if !note.is_empty() && tx.desc.is_empty() {
                    tx.desc = note;
                }
                (
                    ReqSiteGuestOrderPut {
                        site_iid,
                        tx: Some(tx),
                    },
                    true,
                )
            }
            Err(e) => return text_response(StatusCode::BAD_REQUEST, format!("json tx parse error: {e}")),
        }
    } else {
        return text_response(StatusCode::BAD_REQUEST, "protobuf or json decode error".into());
    };

    match c35_mod_tx::guest_order_put(&st.pool, req).await {
        Ok(res) => {
            if is_json_req || from_json {
                let tx_json = res.tx.as_ref().map(c35_mod_tx::tx_to_json).unwrap_or_default();
                let json_body = serde_json::json!({
                    "tx": tx_json,
                });
                (
                    StatusCode::OK,
                    [(header::CONTENT_TYPE, header::HeaderValue::from_static("application/json"))],
                    json_body.to_string(),
                ).into_response()
            } else {
                protobuf_response(StatusCode::OK, &res)
            }
        }
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
