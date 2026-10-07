use base64::{engine::general_purpose::STANDARD as B64, Engine as _};
use serde_json::Value;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct MediaAttachment {
    pub name: String,
    pub mime_type: String,
    pub data: String,
}

pub fn parse_media_attach(text: &str) -> Option<MediaAttachment> {
    let v: Value = serde_json::from_str(text).ok()?;
    let msg_type = v.get("type").and_then(|t| t.as_str())?;
    if msg_type != "media_attach" {
        return None;
    }
    let data = v.get("data").and_then(|d| d.as_str())?.trim().to_string();
    if data.is_empty() {
        return None;
    }
    let name = v.get("name").and_then(|n| n.as_str()).unwrap_or("").to_string();
    let mime_type = v
        .get("mime_type")
        .or_else(|| v.get("mimeType"))
        .and_then(|m| m.as_str())
        .unwrap_or("application/octet-stream")
        .to_string();
    Some(MediaAttachment {
        name,
        mime_type,
        data,
    })
}

pub fn extract_attachment_text(name: &str, data: &str) -> String {
    let decoded = if let Ok(bytes) = B64.decode(data.trim()) {
        match String::from_utf8(bytes.clone()) {
            Ok(s) => s,
            Err(_) => {
                let lossy = String::from_utf8_lossy(&bytes);
                let cleaned: String = lossy
                    .chars()
                    .filter(|c| !c.is_control() || *c == '\n' || *c == '\t')
                    .collect();
                if cleaned.trim().len() > 10 {
                    cleaned
                } else {
                    format!("[Attached document: {name}]")
                }
            }
        }
    } else {
        data.trim().to_string()
    };
    if !name.trim().is_empty() {
        format!("[Attached file: {}]\n{}", name.trim(), decoded)
    } else {
        decoded
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_media_attach_image() {
        let json = r#"{"type":"media_attach","name":"photo.jpg","mime_type":"image/jpeg","data":"aGVsbG8="}"#;
        let attach = parse_media_attach(json).expect("should parse");
        assert_eq!(attach.name, "photo.jpg");
        assert_eq!(attach.mime_type, "image/jpeg");
        assert_eq!(attach.data, "aGVsbG8=");
    }

    #[test]
    fn test_parse_media_attach_text() {
        let json = r#"{"type":"media_attach","name":"notes.txt","mime_type":"text/plain","data":"SGVsbG8gd29ybGQ="}"#;
        let attach = parse_media_attach(json).expect("should parse");
        assert_eq!(attach.name, "notes.txt");
        assert_eq!(attach.mime_type, "text/plain");
        let text = extract_attachment_text(&attach.name, &attach.data);
        assert!(text.contains("Hello world"));
    }
}
