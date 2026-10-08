use anyhow::Result;
use chrono::{DateTime, Utc};
use sqlx::PgPool;

use crate::bus::NotifyNats;
use crate::deliver::notify_deliver;
use crate::FcmSend;

/// Republish live `scheduled` rows after boot.
/// Overdue rows (`fire_at <= now`) are delivered immediately.
/// Future rows go through `NotifyNats::publish_schedule` (NATS `@at` headers).
pub async fn hydrate_notify_schedules(
    pool: &PgPool,
    nats: &c35_nats::Client,
    fcm: &dyn FcmSend,
) -> Result<u32> {
    let rows = match sqlx::query_as::<_, (i64, DateTime<Utc>)>(
        r#"
        SELECT id, fire_at
        FROM ai.notify
        WHERE status = 'scheduled'
          AND deleted_ts IS NULL
          AND fire_at > NOW() - INTERVAL '2 minutes'
        "#,
    )
    .fetch_all(pool)
    .await
    {
        Ok(rows) => rows,
        Err(e) if e.to_string().contains("does not exist") => return Ok(0),
        Err(e) => return Err(e.into()),
    };

    let now = Utc::now();
    let mut count = 0u32;
    for (id, fire_at) in rows {
        if fire_at <= now {
            if let Err(e) = notify_deliver(pool, Some(nats), fcm, id).await {
                tracing::warn!(notify_id = id, error = %e, "[c35:notify] overdue deliver failed");
                continue;
            }
        } else if let Err(e) = nats.publish_schedule(id, fire_at).await {
            tracing::warn!(notify_id = id, error = %e, "[c35:notify] schedule publish failed");
            continue;
        }
        count += 1;
    }
    Ok(count)
}
