use sqlx::PgPool;

use crate::thought::thought_strip;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum OutboundMediaKind {
    Image,
    Document,
    Audio,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OutboundMedia {
    pub kind: OutboundMediaKind,
    pub hash: String,
    pub mime: String,
    pub name: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OutboundPayload {
    pub text: String,
    pub media: Vec<OutboundMedia>,
}

pub fn outbound_payload_parse(raw: &str) -> OutboundPayload {
    let visible = thought_strip(raw);
    let mut media = Vec::new();
    let mut text = visible.clone();

    while let Some(start) = text.find("![") {
        let rest = &text[start + 2..];
        let title_end = rest.find(']');
        let url_start = rest.find("](");
        if title_end.is_none() || url_start.is_none() {
            break;
        }
        let url_start = start + 2 + url_start.unwrap() + 2;
        let url_end = text[url_start..].find(')').map(|i| url_start + i);
        if url_end.is_none() {
            break;
        }
        let url_end = url_end.unwrap();
        let url = text[url_start..url_end].trim();
        if let Some(item) = media_from_url(url) {
            push_media(&mut media, item);
        }
        text.replace_range(start..=url_end, "");
    }

    for token in visible.split_whitespace() {
        let clean = token.trim_matches(|c: char| c == ')' || c == '(' || c == ',' || c == '.');
        if let Some(hash) = fs_hash_from_token(clean) {
            push_media(&mut media, media_from_hash(&hash, clean));
            text = text.replace(clean, "");
        }
    }

    OutboundPayload {
        text: text.split_whitespace().collect::<Vec<_>>().join(" ").trim().to_string(),
        media,
    }
}

fn push_media(media: &mut Vec<OutboundMedia>, item: OutboundMedia) {
    if item.hash.is_empty() || media.iter().any(|m| m.hash == item.hash) {
        return;
    }
    media.push(item);
}

fn fs_hash_from_token(token: &str) -> Option<String> {
    if let Some(idx) = token.to_lowercase().find("/fs/") {
        let hash = token[idx + 4..].split('/').next().unwrap_or_default();
        if hash.len() >= 32 && hash.chars().all(|c| c.is_ascii_hexdigit()) {
            return Some(hash.to_string());
        }
    }
    None
}

fn media_from_url(url: &str) -> Option<OutboundMedia> {
    if let Some(hash) = fs_hash_from_token(url) {
        return Some(media_from_hash(&hash, url));
    }
    None
}

pub fn media_from_hash(hash: &str, hint_url: &str) -> OutboundMedia {
    let mime = mime_from_url(hint_url);
    let kind = if mime.starts_with("image/") {
        OutboundMediaKind::Image
    } else if mime.starts_with("audio/") {
        OutboundMediaKind::Audio
    } else {
        OutboundMediaKind::Document
    };
    OutboundMedia {
        kind,
        hash: hash.to_string(),
        mime,
        name: if hint_url.is_empty() {
            "file".into()
        } else {
            file_name_from_url(hint_url)
        },
    }
}

pub fn mime_from_url(url: &str) -> String {
    let lower = url.to_lowercase();
    if lower.ends_with(".png") {
        "image/png".into()
    } else if lower.ends_with(".webp") {
        "image/webp".into()
    } else if lower.ends_with(".gif") {
        "image/gif".into()
    } else if lower.ends_with(".jpg") || lower.ends_with(".jpeg") {
        "image/jpeg".into()
    } else if lower.ends_with(".mp3") {
        "audio/mpeg".into()
    } else if lower.ends_with(".ogg") {
        "audio/ogg".into()
    } else if lower.ends_with(".pdf") {
        "application/pdf".into()
    } else {
        "application/octet-stream".into()
    }
}

fn file_name_from_url(url: &str) -> String {
    url.rsplit('/').next().unwrap_or("file").split('?').next().unwrap_or("file").to_string()
}

pub fn fs_public_url(hash: &str) -> String {
    let base = std::env::var("C35_PUBLIC_ORIGIN")
        .or_else(|_| std::env::var("CS_PUBLIC_ORIGIN"))
        .ok()
        .map(|s| s.trim().trim_end_matches('/').to_string())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| "https://alienai.id".to_string());
    format!("{base}/fs/{hash}")
}

pub async fn media_mime_resolve(pool: &PgPool, hash: &str, fallback: &str) -> String {
    if hash.is_empty() {
        return fallback.to_string();
    }
    let mime = sqlx::query_scalar::<_, String>("SELECT mime_type FROM ai.file_blob_meta WHERE hash_blake3 = $1")
        .bind(hash)
        .fetch_optional(pool)
        .await
        .ok()
        .flatten();
    mime.filter(|m| !m.is_empty()).unwrap_or_else(|| fallback.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_markdown_image_and_strips_from_text() {
        let raw = "Here ![logo](https://alienai.id/fs/abc123def4567890abcdef1234567890ab) done";
        let p = outbound_payload_parse(raw);
        assert_eq!(p.media.len(), 1);
        assert_eq!(p.media[0].hash, "abc123def4567890abcdef1234567890ab");
        assert!(!p.text.contains("/fs/"));
    }

    #[test]
    fn parses_fs_hash_token() {
        let raw = "See https://alienai.id/fs/abc123def4567890abcdef1234567890ab please";
        let p = outbound_payload_parse(raw);
        assert_eq!(p.media.len(), 1);
        assert_eq!(p.media[0].kind, OutboundMediaKind::Document);
    }
}
