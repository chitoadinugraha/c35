use axum::{
    body::Bytes,
    extract::State,
    http::{HeaderMap, StatusCode},
    response::{IntoResponse, Response},
    routing::post,
};
use c35_ctx::AppState;
use c35_mod_identity::auth_session_caller_iid;
use c35_mod_referral::{
    referral_code_delete, referral_code_list, referral_code_put, referral_share_set,
    referral_tree_get, referral_user_stats,
};
use c35_proto::{invoke_req, invoke_res, InvokeReq, InvokeRes, ResReferralShareSet, ResReferralTreeGet};
use prost::Message;

pub fn invoke_router() -> axum::Router<AppState> {
    axum::Router::new().route("/v1/invoke", post(http_invoke_handler))
}

async fn http_invoke_handler(
    State(st): State<AppState>,
    headers: HeaderMap,
    body: Bytes,
) -> Response {
    let mut req = match InvokeReq::decode(body) {
        Ok(r) => r,
        Err(e) => return text_response(StatusCode::BAD_REQUEST, format!("Protobuf decode error: {e}")),
    };
    let iid = match auth_session_caller_iid(&st.pool, &headers, None).await {
        Some(id) if id > 0 => id,
        _ => return invoke_unauthorized(&req.req_id),
    };
    req.caller_iid = iid;
    protobuf_response(dispatch_invoke(&st.pool, req).await)
}

pub async fn dispatch_invoke(pool: &sqlx::PgPool, req: InvokeReq) -> InvokeRes {
    let req_id = req.req_id.clone();
    let iid = req.caller_iid;
    match req.body {
        Some(invoke_req::Body::ReferralTreeGet(r)) => InvokeRes {
            req_id,
            status_code: 200,
            error_message: String::new(),
            body: Some(invoke_res::Body::ReferralTreeGet(ResReferralTreeGet {
                slice: Some(referral_tree_get(pool, iid, r.root_id, r.depth).await),
            })),
        },
        Some(invoke_req::Body::ReferralShareSet(r)) => {
            referral_share_set(pool, iid, r.parent_uid, r.child_uid, r.share_percent).await;
            InvokeRes {
                req_id,
                status_code: 200,
                error_message: String::new(),
                body: Some(invoke_res::Body::ReferralShareSet(ResReferralShareSet {
                    success: true,
                })),
            }
        }
        Some(invoke_req::Body::ReferralCodeList(_)) => InvokeRes {
            req_id,
            status_code: 200,
            error_message: String::new(),
            body: Some(invoke_res::Body::ReferralCodeList(
                c35_proto::ResReferralCodeList {
                    items: referral_code_list(pool, iid).await,
                },
            )),
        },
        Some(invoke_req::Body::ReferralCodePut(r)) => {
            let doc = r.code.unwrap_or_default();
            match referral_code_put(pool, iid, doc).await {
                Ok(saved) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::ReferralCodePut(saved)),
                },
                Err(msg) => invoke_error(&req_id, 400, msg),
            }
        }
        Some(invoke_req::Body::ReferralCodeDelete(r)) => {
            match referral_code_delete(pool, iid, &r.code).await {
                Ok(()) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: None,
                },
                Err(msg) => invoke_error(&req_id, 400, msg),
            }
        }
        Some(invoke_req::Body::ReferralUserStats(r)) => {
            match referral_user_stats(pool, iid, r).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::ReferralUserStats(res)),
                },
                Err(msg) => invoke_error(
                    &req_id,
                    if msg == "forbidden" { 403 } else { 400 },
                    msg,
                ),
            }
        }
        _ => invoke_error(&req_id, 404, "not implemented".into()),
    }
}

fn invoke_unauthorized(req_id: &str) -> Response {
    protobuf_response(InvokeRes {
        req_id: req_id.into(),
        status_code: 401,
        error_message: "unauthorized".into(),
        body: None,
    })
}

fn invoke_error(req_id: &str, status: i32, msg: String) -> InvokeRes {
    InvokeRes {
        req_id: req_id.into(),
        status_code: status,
        error_message: msg,
        body: None,
    }
}

fn protobuf_response(res: InvokeRes) -> Response {
    let status = StatusCode::from_u16(res.status_code as u16).unwrap_or(StatusCode::OK);
    let mut buf = Vec::new();
    let _ = res.encode(&mut buf);
    use axum::http::HeaderValue;
    (
        status,
        [(
            axum::http::header::CONTENT_TYPE,
            HeaderValue::from_static("application/x-protobuf"),
        )],
        buf,
    )
        .into_response()
}

fn text_response(status: StatusCode, msg: String) -> Response {
    (status, msg).into_response()
}
