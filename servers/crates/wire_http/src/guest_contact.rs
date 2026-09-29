use axum::{
    body::Bytes,
    extract::State,
    http::{header, StatusCode},
    response::{IntoResponse, Response},
    routing::post,
    Router,
};
use c35_ctx::AppState;
use c35_proto::ReqSiteGuestContactPut;
use prost::Message;

pub fn guest_contact_router() -> Router<AppState> {
    Router::new()
        .route("/v1/site/guest-contact/put", post(guest_contact_put_handler))
}

async fn guest_contact_put_handler(State(st): State<AppState>, body: Bytes) -> Response {
    let req = if let Ok(r) = ReqSiteGuestContactPut::decode(body.clone()) {
        r
    } else if let Ok(val) = serde_json::from_slice::<serde_json::Value>(&body) {
        ReqSiteGuestContactPut {
            site_iid: val.get("site_iid").and_then(|x| x.as_i64()).unwrap_or(0),
            name: val.get("name").and_then(|x| x.as_str()).unwrap_or("").to_string(),
            contact_val: val.get("contact_val").or_else(|| val.get("contact")).or_else(|| val.get("phone")).or_else(|| val.get("email")).and_then(|x| x.as_str()).unwrap_or("").to_string(),
            message: val.get("message").or_else(|| val.get("msg")).and_then(|x| x.as_str()).unwrap_or("").to_string(),
            meta_json: val.get("meta_json").and_then(|x| x.as_str()).unwrap_or("{}").to_string(),
        }
    } else {
        return text_response(StatusCode::BAD_REQUEST, "invalid protobuf or json payload".into());
    };

    match c35_mod_site::guest_contact_put(&st.pool, req).await {
        Ok(res) => {
            let json_body = serde_json::json!({
                "ok": res.ok,
                "contact_id": res.contact_id,
                "error": res.error,
            });
            (
                StatusCode::OK,
                [(
                    header::CONTENT_TYPE,
                    header::HeaderValue::from_static("application/json"),
                )],
                json_body.to_string(),
            )
                .into_response()
        }
        Err(e) => text_response(StatusCode::BAD_REQUEST, e.to_string()),
    }
}

fn text_response(status: StatusCode, msg: String) -> Response {
    (
        status,
        [(
            header::CONTENT_TYPE,
            header::HeaderValue::from_static("text/plain; charset=utf-8"),
        )],
        msg,
    )
        .into_response()
}
