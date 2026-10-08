use chrono::{DateTime, Duration, Utc};

/// A connection counts as live when `updated_ts` is newer than this.
pub const PRESENCE_TTL: Duration = Duration::seconds(45);

#[derive(Clone, Debug)]
pub struct AppConn {
    pub client_id: String,
    pub resumed: bool,
    pub updated_ts: DateTime<Utc>,
}

#[derive(Clone, Debug)]
pub struct FcmTok {
    pub client_id: String,
    pub token: String,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct DeliveryPlan {
    pub nats: bool,
    pub fcm_tokens: Vec<String>,
    pub channels: String,
}

pub fn plan_delivery(conns: &[AppConn], tokens: &[FcmTok], now: DateTime<Utc>) -> DeliveryPlan {
    let cutoff = now - PRESENCE_TTL;
    let live: Vec<&AppConn> = conns.iter().filter(|c| c.updated_ts > cutoff).collect();
    let nats = !live.is_empty();
    let fcm_tokens: Vec<String> = tokens
        .iter()
        .filter(|t| {
            !live.iter().any(|c| c.client_id == t.client_id)
        })
        .map(|t| t.token.clone())
        .collect();

    let mut parts: Vec<&str> = Vec::new();
    if live.iter().any(|c| c.resumed) {
        parts.push("app");
    }
    if live.iter().any(|c| !c.resumed) {
        parts.push("local");
    }
    if !fcm_tokens.is_empty() {
        parts.push("fcm");
    }

    DeliveryPlan {
        nats,
        fcm_tokens,
        channels: parts.join(","),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn now() -> DateTime<Utc> {
        DateTime::parse_from_rfc3339("2026-10-08T10:00:00Z")
            .unwrap()
            .with_timezone(&Utc)
    }

    fn conn(id: &str, resumed: bool, ago_secs: i64, now: DateTime<Utc>) -> AppConn {
        AppConn {
            client_id: id.to_string(),
            resumed,
            updated_ts: now - Duration::seconds(ago_secs),
        }
    }

    fn tok(id: &str, token: &str) -> FcmTok {
        FcmTok {
            client_id: id.to_string(),
            token: token.to_string(),
        }
    }

    #[test]
    fn resumed_conn_only_is_app() {
        let now = now();
        let plan = plan_delivery(&[conn("a", true, 0, now)], &[], now);
        assert_eq!(plan.channels, "app");
        assert!(plan.nats);
        assert!(plan.fcm_tokens.is_empty());
    }

    #[test]
    fn background_conn_only_is_local() {
        let now = now();
        let plan = plan_delivery(&[conn("a", false, 0, now)], &[], now);
        assert_eq!(plan.channels, "local");
        assert!(plan.nats);
        assert!(plan.fcm_tokens.is_empty());
    }

    #[test]
    fn token_only_is_fcm() {
        let now = now();
        let plan = plan_delivery(&[], &[tok("a", "tok-a")], now);
        assert_eq!(plan.channels, "fcm");
        assert!(!plan.nats);
        assert_eq!(plan.fcm_tokens, vec!["tok-a".to_string()]);
    }

    #[test]
    fn resumed_client_a_plus_token_for_b() {
        let now = now();
        let plan = plan_delivery(
            &[conn("A", true, 0, now)],
            &[tok("A", "tok-a"), tok("B", "tok-b")],
            now,
        );
        assert_eq!(plan.channels, "app,fcm");
        assert!(plan.nats);
        assert_eq!(plan.fcm_tokens, vec!["tok-b".to_string()]);
    }

    #[test]
    fn stale_conn_falls_through_to_fcm() {
        let now = now();
        let plan = plan_delivery(
            &[conn("A", true, 46, now)],
            &[tok("A", "tok-a")],
            now,
        );
        assert_eq!(plan.channels, "fcm");
        assert!(!plan.nats);
        assert_eq!(plan.fcm_tokens, vec!["tok-a".to_string()]);
    }

    #[test]
    fn resumed_and_background_are_app_local() {
        let now = now();
        let plan = plan_delivery(
            &[conn("A", true, 1, now), conn("B", false, 1, now)],
            &[],
            now,
        );
        assert_eq!(plan.channels, "app,local");
        assert!(plan.nats);
        assert!(plan.fcm_tokens.is_empty());
    }
}
