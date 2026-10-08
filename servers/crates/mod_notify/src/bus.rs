use anyhow::Result;
use async_nats::header::HeaderMap;
use async_nats::jetstream;
use chrono::{DateTime, Duration, Utc};
use c35_proto::{ws_res, Message, NotifyPush, WsRes};

use crate::async_trait;

/// Broker seam so unit tests never open a NATS connection.
/// `None` skips publish; the inbox row is still stored.
#[async_trait]
pub trait NotifyNats: Send + Sync {
    async fn publish_schedule(&self, id: i64, fire_at: DateTime<Utc>) -> Result<()>;
    async fn publish_user_notify(&self, owner_iid: i64, payload: Vec<u8>) -> Result<()>;
}

#[async_trait]
impl NotifyNats for c35_nats::Client {
    async fn publish_schedule(&self, id: i64, fire_at: DateTime<Utc>) -> Result<()> {
        let js = jetstream::new(self.clone());
        let subject = schedule_subject(id);
        let target = schedule_target(id);
        let at = schedule_at_header(fire_at);
        let ttl = schedule_ttl(fire_at, Utc::now());
        let mut headers = HeaderMap::new();
        headers.insert("Nats-Schedule", at.as_str());
        headers.insert("Nats-Schedule-Target", target.as_str());
        headers.insert("Nats-Schedule-TTL", ttl);
        let payload = serde_json::to_vec(&serde_json::json!({ "notify_id": id }))?;
        js.publish_with_headers(subject, headers, payload.into())
            .await?
            .await?;
        Ok(())
    }

    async fn publish_user_notify(&self, owner_iid: i64, payload: Vec<u8>) -> Result<()> {
        let subject = c35_nats::user_app_subject_notify(owner_iid);
        self.publish(subject, payload.into()).await?;
        Ok(())
    }
}

pub fn schedule_subject(id: i64) -> String {
    format!("c35.schedule.notify.{id}")
}

pub fn schedule_target(id: i64) -> String {
    format!("c35.notify.fire.{id}")
}

pub fn schedule_at_header(fire_at: DateTime<Utc>) -> String {
    format!("@at {}", fire_at.to_rfc3339())
}

/// `24h` when `fire_at` is within 24 hours of `now`, otherwise `168h`.
pub fn schedule_ttl(fire_at: DateTime<Utc>, now: DateTime<Utc>) -> &'static str {
    if fire_at <= now + Duration::hours(24) {
        "24h"
    } else {
        "168h"
    }
}

pub fn encode_notify_push(
    req_id: &str,
    id: i64,
    title: &str,
    body: &str,
    route_json: &str,
) -> Vec<u8> {
    let ws = WsRes {
        req_id: req_id.to_string(),
        body: Some(ws_res::Body::NotifyPush(NotifyPush {
            id,
            title: title.to_string(),
            body: body.to_string(),
            route_json: route_json.to_string(),
        })),
    };
    ws.encode_to_vec()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ttl_is_24h_inside_the_window_and_168h_past_it() {
        let now = DateTime::parse_from_rfc3339("2026-10-08T10:00:00Z")
            .unwrap()
            .with_timezone(&Utc);
        assert_eq!(schedule_ttl(now, now), "24h");
        assert_eq!(schedule_ttl(now + Duration::hours(24), now), "24h");
        assert_eq!(
            schedule_ttl(now + Duration::hours(24) + Duration::seconds(1), now),
            "168h"
        );
        let at = now + Duration::seconds(30);
        assert_eq!(schedule_at_header(at), format!("@at {}", at.to_rfc3339()));
        assert_eq!(schedule_subject(7), "c35.schedule.notify.7");
        assert_eq!(schedule_target(7), "c35.notify.fire.7");
    }
}
