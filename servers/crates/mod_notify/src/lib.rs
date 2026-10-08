//! User notification inbox, presence, and delivery.
//!
//! Spec: `_/docs/notify.md`. WebSocket handlers, the NATS fire consumer,
//! Flutter, and Home tools live in later tracks.

mod bus;
mod deliver;
mod fcm_adapt;
mod hydrate;
mod plan;
mod store;
mod validate;

pub use bus::NotifyNats;
pub use deliver::{notify_deliver, notify_release_waiting};
pub use fcm_adapt::NotifyFcm;
pub use hydrate::hydrate_notify_schedules;
pub use plan::{plan_delivery, AppConn, DeliveryPlan, FcmTok, PRESENCE_TTL};
pub use store::{
    app_presence_delete, app_presence_put, fcm_token_put, notify_cancel, notify_list,
    notify_mark_read, notify_put, NotifyItem, NotifyRow,
};
pub use validate::{validate_notify_put, NotifyPut, NotifyWhen, BODY_MAX, DELAY_MAX, TITLE_MAX};

pub use async_trait::async_trait;

use std::collections::HashMap;

/// FCM data-message sender. Tests pass a mock. Production lives in `c35_fcm` (later track).
#[async_trait]
pub trait FcmSend: Send + Sync {
    async fn send_data(&self, tokens: &[String], data: HashMap<String, String>);
}
