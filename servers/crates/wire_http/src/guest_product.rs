use axum::{
    body::Bytes,
    extract::State,
    http::{header, StatusCode},
    response::{IntoResponse, Response},
    routing::post,
    Router,
};
use c35_ctx::AppState;
use c35_proto::ReqSiteGuestProductList;
use prost::Message;

pub fn guest_product_router() -> Router<AppState> {
    Router::new().route(
        "/v1/site/guest-product/list",
        post(guest_product_list_handler),
    )
}

async fn guest_product_list_handler(State(st): State<AppState>, body: Bytes) -> Response {
    let req = if let Ok(r) = ReqSiteGuestProductList::decode(body.clone()) {
        r
    } else if let Ok(val) = serde_json::from_slice::<serde_json::Value>(&body) {
        ReqSiteGuestProductList {
            site_iid: val.get("site_iid").and_then(|x| x.as_i64()).unwrap_or(0),
            filter: val
                .get("filter")
                .and_then(|x| x.as_str())
                .unwrap_or("all")
                .to_string(),
            category: val
                .get("category")
                .and_then(|x| x.as_str())
                .unwrap_or("")
                .to_string(),
            cursor: val
                .get("cursor")
                .and_then(|x| x.as_str())
                .unwrap_or("")
                .to_string(),
            limit: val.get("limit").and_then(|x| x.as_i64()).unwrap_or(24) as i32,
        }
    } else {
        return text_response(StatusCode::BAD_REQUEST, "invalid protobuf or json payload".into());
    };

    match c35_mod_site::guest_product_list(
        &st.pool,
        req.site_iid,
        &req.filter,
        &req.category,
        &req.cursor,
        req.limit,
    )
    .await
    {
        Ok(res) => {
            let items: Vec<serde_json::Value> = res
                .items
                .iter()
                .map(c35_mod_site::product_row_json)
                .collect();
            let json_body = serde_json::json!({
                "items": items,
                "next_cursor": res.next_cursor,
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
