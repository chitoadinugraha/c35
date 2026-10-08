use c35_mod_notify::NotifyItem as NotifyRow;
use c35_proto::{
    ws_res, ReqAppPresence, ReqNotifyList, ReqNotifyRead, ReqNotifyTokenPut, ResAppPresence,
    ResNotifyList, ResNotifyRead, ResNotifyTokenPut, WsRes,
};
use c35_wire::WireErr;
use sqlx::PgPool;

fn err_res(req_id: String, err: WireErr) -> WsRes {
    WsRes {
        req_id,
        body: Some(ws_res::Body::Err(err.into_proto())),
    }
}

fn ok_res(req_id: String, body: ws_res::Body) -> WsRes {
    WsRes {
        req_id,
        body: Some(body),
    }
}

fn map_item(row: NotifyRow) -> c35_proto::NotifyItem {
    c35_proto::NotifyItem {
        id: row.id,
        title: row.title,
        body: row.body,
        status: row.status,
        channels: row.channels,
        fire_at_ms: row.fire_at.timestamp_millis(),
        sent_ts_ms: row.sent_ts.map(|t| t.timestamp_millis()).unwrap_or(0),
        read_ts_ms: row.read_ts.map(|t| t.timestamp_millis()).unwrap_or(0),
        created_ts_ms: row.created_ts.timestamp_millis(),
        route_json: row.route_json.to_string(),
    }
}

pub async fn notify_list_res(pool: &PgPool, caller_iid: i64, req_id: String, r: ReqNotifyList) -> WsRes {
    match c35_mod_notify::notify_list(pool, caller_iid, r.limit, r.unread_only).await {
        Ok(rows) => ok_res(
            req_id,
            ws_res::Body::NotifyList(ResNotifyList {
                items: rows.into_iter().map(map_item).collect(),
            }),
        ),
        Err(e) => err_res(req_id, WireErr::client("notify_list_failed", e.to_string())),
    }
}

pub async fn notify_read_res(pool: &PgPool, caller_iid: i64, req_id: String, r: ReqNotifyRead) -> WsRes {
    match c35_mod_notify::notify_mark_read(pool, caller_iid, &r.ids).await {
        Ok(updated) => ok_res(req_id, ws_res::Body::NotifyRead(ResNotifyRead { updated })),
        Err(e) => err_res(req_id, WireErr::client("notify_read_failed", e.to_string())),
    }
}

pub async fn notify_token_put_res(
    pool: &PgPool,
    caller_iid: i64,
    req_id: String,
    r: ReqNotifyTokenPut,
) -> WsRes {
    if r.client_id.is_empty() {
        return err_res(req_id, WireErr::client("client", "empty client_id"));
    }
    match c35_mod_notify::fcm_token_put(pool, caller_iid, &r.client_id, &r.token, &r.platform).await {
        Ok(()) => ok_res(req_id, ws_res::Body::NotifyTokenPut(ResNotifyTokenPut {})),
        Err(e) => err_res(req_id, WireErr::client("notify_token_put_failed", e.to_string())),
    }
}

pub async fn app_presence_res(pool: &PgPool, caller_iid: i64, req_id: String, r: ReqAppPresence) -> WsRes {
    if r.client_id.is_empty() {
        return err_res(req_id, WireErr::client("client", "empty client_id"));
    }
    match c35_mod_notify::app_presence_put(pool, caller_iid, &r.client_id, r.resumed).await {
        Ok(()) => ok_res(req_id, ws_res::Body::AppPresence(ResAppPresence {})),
        Err(e) => err_res(req_id, WireErr::client("app_presence_failed", e.to_string())),
    }
}

pub async fn note_presence(pool: &PgPool, caller_iid: i64, stored: &mut String, client_id: &str, res: &WsRes) {
    if client_id.is_empty() || matches!(res.body, Some(ws_res::Body::Err(_))) {
        return;
    }
    if stored == client_id {
        return;
    }
    if !stored.is_empty() {
        let _ = c35_mod_notify::app_presence_delete(pool, caller_iid, stored).await;
    }
    *stored = client_id.to_string();
}

pub async fn forget_presence(pool: &PgPool, caller_iid: i64, stored: &str) {
    if stored.is_empty() {
        return;
    }
    let _ = c35_mod_notify::app_presence_delete(pool, caller_iid, stored).await;
}
