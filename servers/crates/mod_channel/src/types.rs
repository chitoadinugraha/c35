use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChannelInboundAttachment {
    pub hash: String,
    pub name: String,
    pub mime: String,
    #[serde(default)]
    pub media_id: String,
    #[serde(default)]
    pub url: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChannelInboundMessage {
    pub platform: String,
    pub external_user_id: String,
    pub display_name: String,
    pub text: String,
    pub external_msg_id: Option<String>,
    #[serde(default)]
    pub attachments: Vec<ChannelInboundAttachment>,
    #[serde(default)]
    pub is_voice: bool,
    #[serde(default)]
    pub quoted_msg_id: String,
    #[serde(default)]
    pub quoted_text: String,
    #[serde(default)]
    pub avatar_hash: String,
    #[serde(default)]
    pub platform_user_id: String,
}
