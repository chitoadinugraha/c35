use serde::Serialize;

pub const PDF_EXTRACT_DEFAULT_MAX_CHARS: usize = 14_000;

#[derive(Debug, Clone, Serialize)]
pub struct PdfSection {
    pub title: String,
    pub page: u32,
    pub level: u8,
}

#[derive(Debug, Clone, Serialize)]
pub struct PdfStructure {
    pub page_count: u32,
    pub sections: Vec<PdfSection>,
    pub outline_from_bookmarks: bool,
}

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
