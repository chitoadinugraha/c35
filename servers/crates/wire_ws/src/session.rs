use axum::extract::ws::{Message, WebSocket};
use c35_ctx::{AppState, Ctx};
use c35_proto::{pb_encode, pb_decode, ReqSessionInit, WsReq, WsRes, ws_req, ws_res};
use c35_wire::WireErr;
use futures_util::StreamExt;

use crate::router::WsQuery;

pub async fn handle(mut socket: WebSocket, state: AppState, q: WsQuery) {
    let token = match q.jwt.as_deref() {
        Some(t) if !t.is_empty() => t,
        _ => {
            let _ = send_err(&mut socket, "", WireErr::Unauthorized).await;
            return;
        }
    };

    let caller_iid = match c35_mod_identity::auth_session_resolve(&state.pool, token).await {
        Ok(Some(i)) if i > 0 => i,
        _ => {
            let _ = send_err(&mut socket, "", WireErr::Unauthorized).await;
            return;
        }
    };

    let ctx = Ctx::from_state(&state, caller_iid);

    while let Some(msg) = socket.next().await {
        let Ok(msg) = msg else { break };
        let Message::Binary(data) = msg else { continue };

        let req: WsReq = match pb_decode(&data) {
            Ok(r) => r,
            Err(_) => {
                let _ = send_err(&mut socket, "", WireErr::client("bad_request", "Invalid message")).await;
                continue;
            }
        };

        let req_id = req.req_id.clone();
        let res = dispatch(&ctx, req, &q).await;
        if socket
            .send(Message::Binary(pb_encode(&res).into()))
            .await
            .is_err()
        {
            break;
        }
        if matches!(res.body, Some(ws_res::Body::Err(_))) && req_id.is_empty() {
            break;
        }
    }
}

async fn dispatch(ctx: &Ctx, req: WsReq, q: &WsQuery) -> WsRes {
    let req_id = req.req_id;
    match req.body {
        Some(ws_req::Body::SessionInit(init)) => match session_init(ctx, init, q).await {
            Ok(body) => WsRes {
                req_id,
                body: Some(ws_res::Body::SessionInit(body)),
            },
            Err(e) => err_res(req_id, e),
        },
        _ => err_res(
            req_id,
            WireErr::client("not_implemented", "Request not supported yet"),
        ),
    }
}

async fn session_init(
    ctx: &Ctx,
    mut req: ReqSessionInit,
    q: &WsQuery,
) -> Result<c35_proto::ResSessionInit, WireErr> {
    if req.since_ms == 0 {
        req.since_ms = q.since.unwrap_or(0);
    }
    if req.locale.is_empty() {
        req.locale = q.locale.clone().unwrap_or_default();
    }
    if req.tz.is_empty() {
        req.tz = q.tz.clone().unwrap_or_default();
    }
    c35_mod_identity::session_init(ctx, req).await
}

fn err_res(req_id: String, err: WireErr) -> WsRes {
    WsRes {
        req_id,
        body: Some(ws_res::Body::Err(err.into_proto())),
    }
}

async fn send_err(socket: &mut WebSocket, req_id: &str, err: WireErr) -> Result<(), ()> {
    let res = WsRes {
        req_id: req_id.into(),
        body: Some(ws_res::Body::Err(err.into_proto())),
    };
    socket
        .send(Message::Binary(pb_encode(&res).into()))
        .await
        .map_err(|_| ())
}
