use std::time::{Duration, Instant};

use serde_json::Value;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PairPoll {
    Pending,
    Claimed { session_key: String, device_iid: i64 },
    Expired,
}

#[derive(Debug, Clone)]
pub struct PairPending {
    pub display_code: String,
    pub secret: String,
    pub expires_in_sec: i64,
}

impl PairPending {
    pub fn deadline(&self) -> Instant {
        Instant::now() + Duration::from_secs(self.expires_in_sec.max(1) as u64)
    }
}

pub fn pair_poll_from_json(v: &Value) -> anyhow::Result<PairPoll> {
    let status = v.get("status").and_then(|s| s.as_str()).unwrap_or("");
    match status {
        "claimed" => {
            let session_key = v
                .get("session_key")
                .and_then(|s| s.as_str())
                .unwrap_or("")
                .trim();
            if session_key.is_empty() {
                anyhow::bail!("claimed without session_key");
            }
            let device_iid = v.get("device_iid").and_then(|d| d.as_i64()).unwrap_or(0);
            Ok(PairPoll::Claimed {
                session_key: session_key.to_string(),
                device_iid,
            })
        }
        "expired" => Ok(PairPoll::Expired),
        "pending" => Ok(PairPoll::Pending),
        _ => {
            if let Some(err) = v.get("error").and_then(|e| e.as_str()) {
                anyhow::bail!("{}", err.to_string());
            }
            Ok(PairPoll::Pending)
        }
    }
}

pub fn pair_should_reroll(poll: &PairPoll, deadline: Instant, now: Instant) -> bool {
    matches!(poll, PairPoll::Expired) || now >= deadline
}

pub async fn pair_register(
    base_url: &str,
    device_name: &str,
    device_type: &str,
) -> anyhow::Result<PairPending> {
    let client = reqwest::Client::new();
    let url = format!("{}/v1/device/pair/register", base_url.trim_end_matches('/'));
    let res = client
        .post(&url)
        .json(&serde_json::json!({
            "device_name": device_name,
            "device_type": device_type,
        }))
        .send()
        .await?
        .error_for_status()?
        .json::<Value>()
        .await?;
    pair_pending_from_json(&res)
}

pub async fn pair_poll(base_url: &str, secret: &str) -> anyhow::Result<PairPoll> {
    let client = reqwest::Client::new();
    let url = format!("{}/v1/device/pair/poll", base_url.trim_end_matches('/'));
    let res = client
        .get(&url)
        .query(&[("secret", secret)])
        .send()
        .await?
        .error_for_status()?
        .json::<Value>()
        .await?;
    pair_poll_from_json(&res)
}

fn pair_pending_from_json(v: &Value) -> anyhow::Result<PairPending> {
    let display_code = v.get("code").and_then(|c| c.as_str()).unwrap_or("").trim().to_string();
    let secret = v.get("device_secret").and_then(|c| c.as_str()).unwrap_or("").trim().to_string();
    if display_code.is_empty() || secret.is_empty() {
        anyhow::bail!("pairing server did not return a code");
    }
    let expires_in_sec = v.get("expires_in_sec").and_then(|e| e.as_i64()).unwrap_or(300);
    Ok(PairPending {
        display_code,
        secret,
        expires_in_sec,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn poll_json_claimed_expired_pending() {
        assert_eq!(
            pair_poll_from_json(&json!({
                "status": "claimed",
                "session_key": "tok_abc",
                "device_iid": 42
            }))
            .unwrap(),
            PairPoll::Claimed {
                session_key: "tok_abc".into(),
                device_iid: 42,
            }
        );
        assert_eq!(
            pair_poll_from_json(&json!({"status": "expired"})).unwrap(),
            PairPoll::Expired
        );
        assert_eq!(
            pair_poll_from_json(&json!({"status": "pending"})).unwrap(),
            PairPoll::Pending
        );
        assert!(pair_poll_from_json(&json!({"status": "claimed", "session_key": ""})).is_err());
        assert_eq!(
            pair_poll_from_json(&json!({"status": "unknown"})).unwrap(),
            PairPoll::Pending
        );
        assert!(pair_poll_from_json(&json!({"status": "bad", "error": "nope"})).is_err());
    }

    #[test]
    fn reroll_only_when_expired_or_deadline() {
        let now = Instant::now();
        let later = now + Duration::from_secs(60);
        assert!(!pair_should_reroll(&PairPoll::Pending, later, now));
        assert!(pair_should_reroll(&PairPoll::Expired, later, now));
        assert!(pair_should_reroll(&PairPoll::Pending, now, later));
    }
}
