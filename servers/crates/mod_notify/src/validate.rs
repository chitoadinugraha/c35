use anyhow::{bail, Result};
use chrono::{DateTime, Utc};
use serde_json::Value;

pub const TITLE_MAX: usize = 120;
pub const BODY_MAX: usize = 500;
pub const DELAY_MAX: u32 = 604_800;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum NotifyWhen {
    Delay,
    Turn,
}

#[derive(Clone, Debug)]
pub struct NotifyPut {
    pub owner_iid: i64,
    pub title: String,
    pub body: String,
    pub delay_sec: u32,
    pub fire_at: Option<DateTime<Utc>>,
    pub when: NotifyWhen,
    pub req_id: String,
    pub route_json: Value,
}

pub fn validate_notify_put(put: &NotifyPut) -> Result<()> {
    if put.title.trim().is_empty() {
        bail!("empty title");
    }
    if put.title.chars().count() > TITLE_MAX {
        bail!("title exceeds {TITLE_MAX} characters");
    }
    if put.body.chars().count() > BODY_MAX {
        bail!("body exceeds {BODY_MAX} characters");
    }
    if put.delay_sec > DELAY_MAX {
        bail!("delay_sec exceeds {DELAY_MAX}");
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn sample() -> NotifyPut {
        NotifyPut {
            owner_iid: 1,
            title: "hello".into(),
            body: "body".into(),
            delay_sec: 0,
            fire_at: None,
            when: NotifyWhen::Delay,
            req_id: String::new(),
            route_json: json!({}),
        }
    }

    #[test]
    fn rejects_empty_title_long_delay_and_long_title() {
        let mut put = sample();
        put.title.clear();
        assert!(validate_notify_put(&put).is_err());

        put = sample();
        put.delay_sec = 604_801;
        assert!(validate_notify_put(&put).is_err());

        put = sample();
        put.title = "a".repeat(121);
        assert!(validate_notify_put(&put).is_err());

        put = sample();
        put.title = "a".repeat(120);
        put.delay_sec = 604_800;
        put.body = "b".repeat(500);
        assert!(validate_notify_put(&put).is_ok());
    }
}
