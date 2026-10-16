use anyhow::Result;
use serde_json::{json, Value};
use sqlx::PgPool;

use crate::store::{notify_put, NotifyRow};
use crate::validate::{NotifyPut, NotifyWhen};
use crate::FcmSend;

/// Product notification (mail, order, task, staff send). Inserts `ai.notify` and delivers immediately.
#[derive(Clone, Debug)]
pub struct NotifyEmit {
    pub owner_iid: i64,
    pub title: String,
    pub body: String,
    pub category: &'static str,
    pub route_json: Value,
    pub req_id: String,
}

impl NotifyEmit {
    pub fn route_with_category(mut self) -> Self {
        if let Some(obj) = self.route_json.as_object_mut() {
            obj.entry("category".to_string())
                .or_insert_with(|| json!(self.category));
        } else {
            self.route_json = json!({ "category": self.category });
        }
        self
    }
}

pub async fn notify_emit(
    pool: &PgPool,
    nats: Option<&c35_nats::Client>,
    fcm: &dyn FcmSend,
    emit: NotifyEmit,
) -> Result<NotifyRow> {
    if emit.owner_iid <= 0 {
        anyhow::bail!("owner_iid required");
    }
    let emit = emit.route_with_category();
    let put = NotifyPut {
        owner_iid: emit.owner_iid,
        title: emit.title,
        body: emit.body,
        delay_sec: 0,
        fire_at: None,
        when: NotifyWhen::Delay,
        req_id: emit.req_id,
        route_json: emit.route_json,
    };
    notify_put(pool, nats, fcm, put).await
}
