use tracing::{info, warn};
use webrtc::ice_transport::ice_credential_type::RTCIceCredentialType;
use webrtc::ice_transport::ice_server::RTCIceServer;

/// Local `dev_server` (127.0.0.1): STUN-only avoids TURN on dead Hyper-V/VBox/Tailscale NICs (Win error 10051).
pub fn ice_servers_local_dev(server_url: &str) -> Option<Vec<RTCIceServer>> {
    let u = server_url.to_ascii_lowercase();
    if !(u.contains("127.0.0.1") || u.contains("localhost")) {
        return None;
    }
    info!("local dev server_url: STUN-only ICE (set C35_ICE_SERVERS to override)");
    Some(vec![RTCIceServer {
        urls: vec!["stun:stun.l.google.com:19302".to_string()],
        username: String::new(),
        credential: String::new(),
        credential_type: RTCIceCredentialType::Unspecified,
    }])
}

#[derive(serde::Deserialize)]
struct IceConfigRes {
    ice_servers: Vec<IceServerEntry>,
}

#[derive(serde::Deserialize)]
struct IceServerEntry {
    urls: Vec<String>,
    #[serde(default)]
    username: String,
    #[serde(default)]
    credential: String,
}

pub async fn ice_servers_fetch(server_url: &str, session_key: &str) -> Option<Vec<RTCIceServer>> {
    let url = format!("{}/v1/agent/ice", server_url.trim_end_matches('/'));
    let res = reqwest::Client::new()
        .get(&url)
        .header("X-Device-Session", session_key)
        .send()
        .await;
    match res {
        Ok(r) if r.status().is_success() => match r.json::<IceConfigRes>().await {
            Ok(body) if !body.ice_servers.is_empty() => Some(
                body.ice_servers
                    .into_iter()
                    .map(|e| {
                        let is_turn = e.urls.iter().any(|u| u.starts_with("turn:") || u.starts_with("turns:"));
                        RTCIceServer {
                            urls: e.urls,
                            username: e.username,
                            credential: e.credential,
                            credential_type: if is_turn {
                                RTCIceCredentialType::Password
                            } else {
                                RTCIceCredentialType::Unspecified
                            },
                        }
                    })
                    .collect(),
            ),
            Ok(_) => {
                warn!("agent ice config empty; using STUN fallback");
                None
            }
            Err(e) => {
                warn!("agent ice config JSON parse failed: {e}");
                None
            }
        },
        Ok(r) => {
            warn!("agent ice config HTTP {}", r.status());
            None
        }
        Err(e) => {
            warn!("agent ice config fetch failed: {e}");
            None
        }
    }
}
