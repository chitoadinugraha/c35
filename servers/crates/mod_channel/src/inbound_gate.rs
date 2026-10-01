//! Drop channel events that are not 1:1 user messages (status, groups, reactions, ...).

use crate::types::ChannelInboundMessage;

pub const IGNORED_PREFIX: &str = "channel_inbound_ignored:";

pub fn is_ignored_err(err: &anyhow::Error) -> bool {
    err.to_string().starts_with(IGNORED_PREFIX)
}

/// Server-side gate after payload is mapped to `ChannelInboundMessage`.
pub fn channel_inbound_accept(inbound: &ChannelInboundMessage) -> bool {
    match inbound.platform.as_str() {
        "whatsapp" => whatsapp_peer_id_accept(&inbound.external_user_id),
        "telegram" => true,
        "app" => true,
        _ => true,
    }
}

/// Linked-device and Cloud peer JID / phone id strings (`628...@s.whatsapp.net`, LID, etc.).
pub fn whatsapp_peer_id_accept(peer: &str) -> bool {
    let p = peer.trim();
    if p.is_empty() {
        return false;
    }
    let lower = p.to_ascii_lowercase();
    if lower == "status@broadcast" || lower.contains("status@broadcast") {
        return false;
    }
    if lower.ends_with("@broadcast") {
        return false;
    }
    if lower.ends_with("@g.us") {
        return false;
    }
    if lower.ends_with("@newsletter") {
        return false;
    }
    true
}

pub fn meta_cloud_message_ignored(msg: &serde_json::Value) -> Option<&'static str> {
    match msg.get("type").and_then(|v| v.as_str()) {
        Some("reaction") => Some("reaction"),
        Some("unsupported") => Some("unsupported"),
        Some("system") => Some("system"),
        Some("unknown") => Some("unknown"),
        _ => None,
    }
}

pub fn telegram_chat_type_private(chat: &serde_json::Value) -> bool {
    chat.get("type").and_then(|v| v.as_str()) == Some("private")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn whatsapp_accepts_dm_jids() {
        assert!(whatsapp_peer_id_accept("628123456789@s.whatsapp.net"));
        assert!(whatsapp_peer_id_accept("15551234567@s.whatsapp.net"));
    }

    #[test]
    fn whatsapp_rejects_status_and_groups() {
        assert!(!whatsapp_peer_id_accept("status@broadcast"));
        assert!(!whatsapp_peer_id_accept("120363123@g.us"));
        assert!(!whatsapp_peer_id_accept("123@newsletter"));
        assert!(!whatsapp_peer_id_accept("list@broadcast"));
    }

    #[test]
    fn meta_ignores_reactions() {
        let msg = serde_json::json!({ "type": "reaction", "from": "1" });
        assert_eq!(meta_cloud_message_ignored(&msg), Some("reaction"));
    }
}