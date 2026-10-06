use base64::{engine::general_purpose::STANDARD as B64, Engine};
use c35_proto::{IceServer, ReqRemoteIceConfig, ResRemoteIceConfig};
use hmac::{Hmac, Mac};
use sha1::Sha1;
use std::time::{SystemTime, UNIX_EPOCH};

const TTL_SEC: u32 = 86400;

fn env_or(key: &str, default: &str) -> String {
    std::env::var(key).unwrap_or_else(|_| default.into())
}

fn env_urls(key: &str, defaults: &[&str]) -> Vec<String> {
    match std::env::var(key) {
        Ok(raw) if !raw.trim().is_empty() => raw
            .split(',')
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .map(str::to_string)
            .collect(),
        _ => defaults.iter().map(|s| (*s).into()).collect(),
    }
}

fn default_stun_urls() -> Vec<String> {
    env_urls(
        "C35_STUN_URLS",
        &[
            "stun:stun.alienai.id:3479",
            "stun:turn.alienai.id:3479",
        ],
    )
}

fn default_turn_urls() -> Vec<String> {
    env_urls(
        "C35_TURN_URLS",
        &[
            "turn:turn.alienai.id:3479?transport=tcp",
            "turn:turn.alienai.id:3479?transport=udp",
        ],
    )
}

fn turn_credential(secret: &str, username: &str) -> String {
    type HmacSha1 = Hmac<Sha1>;
    let mut mac = HmacSha1::new_from_slice(secret.as_bytes()).expect("hmac key");
    mac.update(username.as_bytes());
    B64.encode(mac.finalize().into_bytes())
}

fn unix_now() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

/// Local dev_server (127.0.0.1 / C35_ICE_LOCAL_DEV): same STUN as prod; TURN TCP-only (Win UDP 10051 on Hyper-V/VBox).
fn ice_local_dev_mode() -> bool {
    if std::env::var("C35_ICE_LOCAL_DEV").as_deref() == Ok("1") {
        return true;
    }
    let u = std::env::var("C35_SERVER_URL")
        .or_else(|_| std::env::var("C35_PUBLIC_URL"))
        .unwrap_or_default()
        .to_ascii_lowercase();
    u.contains("127.0.0.1") || u.contains("localhost")
}

fn turn_urls_tcp_only() -> Vec<String> {
    default_turn_urls()
        .into_iter()
        .filter(|u| u.contains("transport=tcp") || u.starts_with("turns:"))
        .collect()
}

fn push_turn_server(ice_servers: &mut Vec<IceServer>, caller_iid: i64, turn_urls: Vec<String>) {
    let secret = std::env::var("C35_TURN_SECRET").unwrap_or_default();
    if secret.trim().is_empty() || turn_urls.is_empty() {
        return;
    }
    let expiry = unix_now() + u64::from(TTL_SEC);
    let username = format!("{}:{}", expiry, caller_iid);
    let credential = turn_credential(secret.trim(), &username);
    ice_servers.push(IceServer {
        urls: turn_urls,
        username,
        credential,
    });
}

/// Mint ephemeral ICE servers for WebRTC (STUN always; TURN when `C35_TURN_SECRET` is set).
pub fn remote_ice_config(caller_iid: i64, _req: ReqRemoteIceConfig) -> ResRemoteIceConfig {
    let _ = env_or("C35_TURN_REALM", "alienai.id");
    let mut ice_servers = vec![IceServer {
        urls: default_stun_urls(),
        username: String::new(),
        credential: String::new(),
    }];
    let turn_urls = if ice_local_dev_mode() {
        turn_urls_tcp_only()
    } else {
        default_turn_urls()
    };
    push_turn_server(&mut ice_servers, caller_iid, turn_urls);

    ResRemoteIceConfig {
        ice_servers,
        ttl_sec: TTL_SEC,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn local_dev_stun_is_alienai_not_google() {
        std::env::set_var("C35_ICE_LOCAL_DEV", "1");
        let cfg = remote_ice_config(99000, ReqRemoteIceConfig::default());
        std::env::remove_var("C35_ICE_LOCAL_DEV");
        let stun = &cfg.ice_servers[0].urls;
        assert!(stun.iter().any(|u| u.contains("alienai.id")));
        assert!(!stun.iter().any(|u| u.contains("google.com")));
    }
}
