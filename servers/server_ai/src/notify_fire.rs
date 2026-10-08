use std::sync::{Arc, Mutex, OnceLock};

use async_nats::Client;
use c35_mod_notify::{notify_deliver, NotifyFcm};
use c35_store::PgPool;
use futures_util::StreamExt;
use tokio::task::JoinHandle;

const SUBJECT: &str = "c35.notify.fire.>";
const QUEUE: &str = "c35-notify-fire";

static FIRE: OnceLock<Mutex<Option<JoinHandle<()>>>> = OnceLock::new();

/// Queue-group consumer for `c35.notify.fire.>`. Replaces any previous loop
/// so a reconnect does not stack subscribers.
pub fn notify_fire_spawn(pool: PgPool, client: Client) {
    let slot = FIRE.get_or_init(|| Mutex::new(None));
    let mut guard = match slot.lock() {
        Ok(g) => g,
        Err(poisoned) => poisoned.into_inner(),
    };
    if let Some(prev) = guard.take() {
        prev.abort();
    }
    let fcm = Arc::new(NotifyFcm::from_env());
    *guard = Some(tokio::spawn(async move {
        notify_fire_loop(pool, client, fcm).await;
    }));
}

async fn notify_fire_loop(pool: PgPool, client: Client, fcm: Arc<NotifyFcm>) {
    tracing::info!("[c35:notify] starting fire consumer on {SUBJECT} queue={QUEUE}");
    let mut sub = match client
        .queue_subscribe(SUBJECT.to_string(), QUEUE.to_string())
        .await
    {
        Ok(s) => s,
        Err(e) => {
            tracing::warn!(error = %e, "[c35:notify] fire subscribe failed");
            return;
        }
    };
    while let Some(msg) = sub.next().await {
        let payload: serde_json::Value = match serde_json::from_slice(&msg.payload) {
            Ok(v) => v,
            Err(e) => {
                tracing::warn!(
                    error = %e,
                    subject = %msg.subject,
                    "[c35:notify] invalid fire payload"
                );
                continue;
            }
        };
        let Some(id) = payload.get("notify_id").and_then(|v| v.as_i64()) else {
            tracing::warn!(
                subject = %msg.subject,
                "[c35:notify] fire payload missing notify_id"
            );
            continue;
        };
        if id <= 0 {
            continue;
        }
        if let Err(e) = notify_deliver(&pool, Some(&client), fcm.as_ref(), id).await {
            tracing::warn!(notify_id = id, error = %e, "[c35:notify] deliver failed");
        }
    }
}
