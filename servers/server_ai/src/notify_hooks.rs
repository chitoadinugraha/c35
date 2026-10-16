use std::sync::Arc;

use async_nats::Client;
use c35_mod_notify::{notify_emit, NotifyEmit, NotifyFcm};
use c35_store::PgPool;
use serde_json::{json, Value};

pub fn notify_hooks_init(pool: PgPool, nats: Option<Client>) {
    let fcm = Arc::new(NotifyFcm::from_env());
    c35_mod_mail::mail_user_notify_fn_set(Arc::new(move |uid, payload| {
        if uid <= 0 {
            return;
        }
        let pool = pool.clone();
        let nats = nats.clone();
        let fcm = fcm.clone();
        tokio::spawn(async move {
            if let Err(e) = mail_received_notify(&pool, nats.as_ref(), fcm.as_ref(), uid, payload).await {
                tracing::warn!(owner_iid = uid, error = %e, "[c35:notify] mail hook");
            }
        });
    }));
}

async fn mail_received_notify(
    pool: &PgPool,
    nats: Option<&Client>,
    fcm: &NotifyFcm,
    owner_iid: i64,
    payload: Value,
) -> anyhow::Result<()> {
    let event = payload.get("event").and_then(|v| v.as_str());
    if event != Some("mail.message.received") {
        return Ok(());
    }
    let mailbox_id = payload.get("mailbox_id").and_then(|v| v.as_i64()).unwrap_or(0);
    let message_id = payload.get("message_id").and_then(|v| v.as_i64()).unwrap_or(0);
    let unread = payload
        .get("inbox_count")
        .and_then(|v| v.as_i64())
        .unwrap_or(0);
    let body = if unread > 0 {
        format!("{unread} unread in inbox")
    } else {
        "New message received".to_string()
    };
    notify_emit(
        pool,
        nats,
        fcm,
        NotifyEmit {
            owner_iid,
            title: "New mail".to_string(),
            body,
            category: "mail",
            route_json: json!({
                "path": "/mail",
                "mailbox_id": mailbox_id,
                "message_id": message_id,
            }),
            req_id: String::new(),
        },
    )
    .await?;
    Ok(())
}
