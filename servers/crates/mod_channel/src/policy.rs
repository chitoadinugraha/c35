use crate::types::ChannelInboundAttachment;

pub const BOT_OOS_MARKER: &str = "[bot-oos]";
pub const AUTO_BLOCK_OOS_THRESHOLD: u32 = 10;
pub const CHANNEL_INBOUND_IMAGE_MAX_BYTES: usize = 5_242_880;
pub const CHANNEL_UNSUPPORTED_REPLY: &str =
    "This bot accepts text and images only (no voice notes or other files). / Bot ini hanya menerima teks dan gambar.";

pub fn reply_oos_strip(reply: &str) -> (String, bool) {
    let trimmed = reply.trim_start();
    if !trimmed.starts_with(BOT_OOS_MARKER) {
        return (reply.to_string(), false);
    }
    let rest = trimmed.strip_prefix(BOT_OOS_MARKER).unwrap_or(trimmed);
    let body = rest.trim_start_matches('\n').trim_start();
    if body.is_empty() {
        return (String::new(), true);
    }
    (body.to_string(), true)
}

pub fn inbound_attachment_allowed(mime: &str) -> bool {
    mime.trim().to_lowercase().starts_with("image/")
}

pub fn inbound_attachments_filter(items: &mut Vec<ChannelInboundAttachment>) {
    items.retain(|a| inbound_attachment_allowed(&a.mime));
}

pub fn inbound_bytes_allowed(size: usize) -> bool {
    size <= CHANNEL_INBOUND_IMAGE_MAX_BYTES
}

pub fn inbound_had_blocked_media(inbound: &crate::types::ChannelInboundMessage) -> bool {
    if inbound.is_voice {
        return true;
    }
    inbound.attachments.iter().any(|a| !inbound_attachment_allowed(&a.mime))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn oos_strip_removes_marker_line() {
        let (clean, oos) = reply_oos_strip("[bot-oos]\n\nSorry, we only help with menu orders.");
        assert!(oos);
        assert_eq!(clean, "Sorry, we only help with menu orders.");
    }

    #[test]
    fn oos_strip_in_scope_unchanged() {
        let raw = "Our hours are 9am-9pm.";
        let (clean, oos) = reply_oos_strip(raw);
        assert!(!oos);
        assert_eq!(clean, raw);
    }

    #[test]
    fn image_mime_only() {
        assert!(inbound_attachment_allowed("image/jpeg"));
        assert!(!inbound_attachment_allowed("application/pdf"));
    }
}
