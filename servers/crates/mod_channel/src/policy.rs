use crate::types::ChannelInboundAttachment;

pub const BOT_OOS_MARKER: &str = "[bot-oos]";
pub const AUTO_BLOCK_OOS_THRESHOLD: u32 = 10;
pub const CHANNEL_INBOUND_IMAGE_MAX_BYTES: usize = 5_242_880;
pub const CHANNEL_DOC_MAX_BYTES: usize = 8 * 1024 * 1024;
pub const CHANNEL_UNSUPPORTED_REPLY: &str =
    "This bot accepts text, images, PDF, Word, and PowerPoint. / Bot ini menerima teks, gambar, PDF, Word, dan PowerPoint.";

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

pub fn inbound_attachment_allowed(mime: &str, name: &str, size: usize) -> bool {
    let mime = mime_base(mime);
    if mime.starts_with("image/") {
        return inbound_bytes_allowed(size);
    }
    if doc_allowed(&mime, name) {
        return size <= CHANNEL_DOC_MAX_BYTES;
    }
    false
}

pub fn inbound_attachments_filter(items: &mut Vec<ChannelInboundAttachment>) {
    items.retain(|a| inbound_attachment_allowed(&a.mime, &a.name, 0));
}

pub fn inbound_bytes_allowed(size: usize) -> bool {
    size <= CHANNEL_INBOUND_IMAGE_MAX_BYTES
}

pub fn inbound_had_blocked_media(inbound: &crate::types::ChannelInboundMessage) -> bool {
    if inbound.is_voice {
        return true;
    }
    inbound
        .attachments
        .iter()
        .any(|a| !inbound_attachment_allowed(&a.mime, &a.name, 0))
}

fn mime_base(mime: &str) -> String {
    mime.split(';')
        .next()
        .unwrap_or("")
        .trim()
        .to_lowercase()
}

fn doc_allowed(mime: &str, name: &str) -> bool {
    const DOC_MIMES: [&str; 3] = [
        "application/pdf",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    ];
    if DOC_MIMES.contains(&mime) {
        return true;
    }
    let name = name.trim().to_lowercase();
    name.ends_with(".pdf") || name.ends_with(".docx") || name.ends_with(".pptx")
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
        assert!(inbound_attachment_allowed("image/jpeg", "photo.jpg", 1024));
        assert!(inbound_attachment_allowed(
            "image/png",
            "photo.png",
            CHANNEL_INBOUND_IMAGE_MAX_BYTES
        ));
        assert!(!inbound_attachment_allowed(
            "image/jpeg",
            "photo.jpg",
            CHANNEL_INBOUND_IMAGE_MAX_BYTES + 1
        ));
        assert!(!inbound_attachment_allowed("audio/ogg", "note.ogg", 1024));
        assert!(!inbound_attachment_allowed("application/zip", "files.zip", 1024));
        assert!(!inbound_attachment_allowed(
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "sheet.xlsx",
            1024
        ));
    }

    #[test]
    fn pdf_under_8_mib_allowed() {
        assert!(inbound_attachment_allowed(
            "application/pdf",
            "notes.pdf",
            CHANNEL_DOC_MAX_BYTES
        ));
        assert!(inbound_attachment_allowed(
            "application/octet-stream",
            "notes.PDF",
            1024
        ));
    }

    #[test]
    fn pdf_over_8_mib_rejected() {
        assert!(!inbound_attachment_allowed(
            "application/pdf",
            "notes.pdf",
            CHANNEL_DOC_MAX_BYTES + 1
        ));
    }

    #[test]
    fn exe_rejected() {
        assert!(!inbound_attachment_allowed(
            "application/x-msdownload",
            "setup.exe",
            1024
        ));
        assert!(!inbound_attachment_allowed(
            "application/octet-stream",
            "setup.exe",
            1024
        ));
    }

    #[test]
    fn docx_mime_allowed() {
        assert!(inbound_attachment_allowed(
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "brief.docx",
            1024
        ));
        assert!(inbound_attachment_allowed(
            "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            "deck.pptx",
            CHANNEL_DOC_MAX_BYTES
        ));
    }

    #[test]
    fn legacy_doc_rejected() {
        assert!(!inbound_attachment_allowed("application/msword", "old.doc", 1024));
        assert!(!inbound_attachment_allowed(
            "application/octet-stream",
            "old.doc",
            1024
        ));
        assert!(!inbound_attachment_allowed(
            "application/vnd.ms-powerpoint",
            "old.ppt",
            1024
        ));
        assert!(!inbound_attachment_allowed(
            "application/octet-stream",
            "old.ppt",
            1024
        ));
    }
}
