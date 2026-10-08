//! Flutter app realtime lane: `c35.user.{owner_iid}.app.*`
//!
//! Spec: `_/docs/sync.md` (App realtime). WS subscribes `user_app_subscribe_subject` only.
//! Do not publish client UI state on `c35.user.{iid}.ev.*` or bare `c35.user.{iid}.balance`.

use c35_proto::{
    BillingPushBalance, BillingPushCommission, BillingPushQuota, WsRes, ws_res,
};
use prost::Message;

pub const APP_SEGMENT: &str = "app";

/// NATS subscribe filter for one owner app WS fanout (`server_ai` / `wire_ws`).
pub fn user_app_subscribe_subject(owner_iid: i64) -> String {
    format!("c35.user.{owner_iid}.{APP_SEGMENT}.>")
}

pub fn user_app_subject_balance(owner_iid: i64) -> String {
    format!("c35.user.{owner_iid}.{APP_SEGMENT}.balance")
}

pub fn user_app_subject_quota(owner_iid: i64) -> String {
    format!("c35.user.{owner_iid}.{APP_SEGMENT}.quota")
}

pub fn user_app_subject_commission(owner_iid: i64) -> String {
    format!("c35.user.{owner_iid}.{APP_SEGMENT}.commission")
}

pub fn user_app_subject_profile(owner_iid: i64) -> String {
    format!("c35.user.{owner_iid}.{APP_SEGMENT}.profile")
}

pub fn user_app_subject_settings(owner_iid: i64) -> String {
    format!("c35.user.{owner_iid}.{APP_SEGMENT}.settings")
}

pub fn user_app_subject_task_run(owner_iid: i64) -> String {
    format!("c35.user.{owner_iid}.{APP_SEGMENT}.task_run")
}

pub fn user_app_subject_device_presence(owner_iid: i64) -> String {
    format!("c35.user.{owner_iid}.{APP_SEGMENT}.device_presence")
}

/// Inbox sidebar: `WsRes` with `SyncPush` (`chat`, `chat_member`, `chat_msg`).
pub fn user_app_subject_inbox(owner_iid: i64) -> String {
    format!("c35.user.{owner_iid}.{APP_SEGMENT}.inbox")
}

/// Live prompt stream + per-chat `SyncPush` (`c35.user.{owner_iid}.app.chat.{chat_id}`).
pub fn user_app_subject_chat(owner_iid: i64, chat_id: i64) -> String {
    format!("c35.user.{owner_iid}.{APP_SEGMENT}.chat.{chat_id}")
}

/// Guest storefront order created/updated — `WsRes` with `SyncPush.tx`.
pub fn user_app_subject_site_order(owner_iid: i64) -> String {
    format!("c35.user.{owner_iid}.{APP_SEGMENT}.site_order")
}

/// Segment after `.app.` (e.g. `balance`, `chat.12345`, `inbox`).
pub fn user_app_tail(subject: &str) -> Option<&str> {
    let marker = format!(".{APP_SEGMENT}.");
    subject.find(&marker).map(|i| &subject[i + marker.len()..])
}

/// Decode NATS payload from the app lane into a WS outbound frame.
pub fn user_app_fanout_decode(subject: &str, payload: &[u8]) -> Option<WsRes> {
    let tail = user_app_tail(subject)?;
    if tail == "balance" {
        let body = BillingPushBalance::decode(payload)
            .ok()
            .map(ws_res::Body::BillingBalance)?;
        return Some(WsRes {
            req_id: String::new(),
            body: Some(body),
        });
    }
    if tail == "quota" {
        let body = BillingPushQuota::decode(payload)
            .ok()
            .map(ws_res::Body::BillingQuota)?;
        return Some(WsRes {
            req_id: String::new(),
            body: Some(body),
        });
    }
    if tail == "commission" {
        let body = BillingPushCommission::decode(payload)
            .ok()
            .map(ws_res::Body::BillingCommission)?;
        return Some(WsRes {
            req_id: String::new(),
            body: Some(body),
        });
    }
    if tail == "device_presence" {
        let ws = WsRes::decode(payload).ok()?;
        let body = ws.body?;
        return Some(WsRes {
            req_id: ws.req_id,
            body: Some(body),
        });
    }
    if tail == "site_order"
        || tail == "inbox"
        || tail == "profile"
        || tail == "settings"
        || tail == "task_run"
        || tail.starts_with("chat.")
    {
        let ws = WsRes::decode(payload).ok()?;
        let body = ws.body?;
        return Some(WsRes {
            req_id: ws.req_id,
            body: Some(body),
        });
    }
    None
}