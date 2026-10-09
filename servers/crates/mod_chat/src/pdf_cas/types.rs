pub const PDF_EXTRACT_DEFAULT_MAX_CHARS: usize = 14_000;

pub fn pdf_mime_ok(mime: &str, name: &str) -> bool {
    name.to_ascii_lowercase().ends_with(".pdf") || mime.to_ascii_lowercase().contains("pdf")
}

pub fn attachment_pdf_items(attachments_json: &str) -> Vec<(String, String)> {
    let Ok(v) = serde_json::from_str::<Vec<serde_json::Value>>(attachments_json) else {
        return vec![];
    };
    v.into_iter()
        .filter_map(|a| {
            let hash = a.get("hash").and_then(|x| x.as_str()).unwrap_or("").trim();
            let name = a.get("name").and_then(|x| x.as_str()).unwrap_or("").trim();
            let mime = a.get("mime").and_then(|x| x.as_str()).unwrap_or("");
            if hash.is_empty() || !pdf_mime_ok(mime, name) {
                return None;
            }
            Some((hash.to_string(), name.to_string()))
        })
        .collect()
}
