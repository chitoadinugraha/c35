//! Flutter app realtime lane: `c35.user.{owner_iid}.app.*`
//!
//! Spec: `_/specs/sync.md` (App realtime). WS subscribes `user_app_subscribe_subject` only.
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

/// User notification push: `WsRes` with `NotifyPush`.
pub fn user_app_subject_notify(owner_iid: i64) -> String {
    format!("c35.user.{owner_iid}.{APP_SEGMENT}.notify")
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
        || tail == "notify"
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

#[cfg(test)]
mod tests {
    use super::*;
    use c35_proto::NotifyPush;
    use prost::Message;

    #[test]
    fn user_app_subject_notify_round_trip() {
        assert_eq!(
            super::user_app_subject_notify(99000),
            "c35.user.99000.app.notify"
        );
        let ws = WsRes {
            req_id: "req-1".to_string(),
            body: Some(ws_res::Body::NotifyPush(NotifyPush {
                id: 42,
                title: "title".to_string(),
                body: "body".to_string(),
                route_json: r#"{"chat_id":1}"#.to_string(),
            })),
        };
        let decoded = user_app_fanout_decode(
            &super::user_app_subject_notify(99000),
            &ws.encode_to_vec(),
        )
        .expect("notify fanout");
        assert_eq!(decoded.req_id, ws.req_id);
        match (decoded.body, ws.body) {
            (
                Some(ws_res::Body::NotifyPush(got)),
                Some(ws_res::Body::NotifyPush(want)),
            ) => {
                assert_eq!(got.id, want.id);
                assert_eq!(got.title, want.title);
                assert_eq!(got.body, want.body);
                assert_eq!(got.route_json, want.route_json);
            }
            other => panic!("expected NotifyPush round-trip, got {other:?}"),
        }
    }
}