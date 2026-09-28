//! Parse Google Docs / Slides URLs for data_source config.

use anyhow::{bail, Context, Result};
use serde_json::{json, Value};

pub const SOURCE_KIND_GOOGLE_DOC: &str = "google_doc";
pub const SOURCE_KIND_GOOGLE_SLIDE: &str = "google_slide";

pub fn parse_google_doc_url(url: &str) -> Result<String> {
    parse_google_drive_id(url, "/document/d/")
}

pub fn parse_google_slide_url(url: &str) -> Result<String> {
    parse_google_drive_id(url, "/presentation/d/")
}

fn parse_google_drive_id(url: &str, marker: &str) -> Result<String> {
    let url = url.trim();
    if url.is_empty() {
        bail!("empty url");
    }
    let id = extract_between(url, marker, "/")
        .or_else(|| extract_between(url, marker, "?"))
        .or_else(|| extract_between(url, marker, "#"))
        .filter(|s| !s.is_empty())
        .context("parse document id from url")?;
    Ok(id)
}

fn extract_between(s: &str, start: &str, end: &str) -> Option<String> {
    let pos = s.find(start)?;
    let rest = &s[pos + start.len()..];
    let end_pos = rest.find(end).unwrap_or(rest.len());
    let id = rest[..end_pos].trim();
    if id.is_empty() {
        None
    } else {
        Some(id.to_string())
    }
}

pub fn config_merge_doc_url(config: &mut Value, view_url: &str) -> Result<()> {
    let document_id = parse_google_doc_url(view_url)?;
    if let Some(obj) = config.as_object_mut() {
        obj.insert("document_id".into(), json!(document_id));
        obj.insert("view_url".into(), json!(view_url.trim()));
        if !obj.contains_key("sync_scope") {
            obj.insert("sync_scope".into(), json!("all"));
        }
    }
    Ok(())
}

pub fn config_merge_slide_url(config: &mut Value, view_url: &str) -> Result<()> {
    let presentation_id = parse_google_slide_url(view_url)?;
    if let Some(obj) = config.as_object_mut() {
        obj.insert("presentation_id".into(), json!(presentation_id));
        obj.insert("view_url".into(), json!(view_url.trim()));
        if !obj.contains_key("sync_scope") {
            obj.insert("sync_scope".into(), json!("all"));
        }
    }
    Ok(())
}

pub fn html_title_from_document(html: &str) -> Option<String> {
    let lower = html.to_ascii_lowercase();
    let start = lower.find("<title>")?;
    let rest = &html[start + 7..];
    let end = rest.find("</title>")?;
    let raw = rest[..end].trim();
    if raw.is_empty() {
        return None;
    }
    let title = raw
        .trim_end_matches(" - Google Sheets")
        .trim_end_matches(" - Google Docs")
        .trim_end_matches(" - Google Slides")
        .trim_end_matches(" - Google Drive")
        .trim();
    if title.is_empty() {
        None
    } else {
        Some(title.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_doc_url() {
        let u = "https://docs.google.com/document/d/abc123/edit";
        assert_eq!(parse_google_doc_url(u).unwrap(), "abc123");
    }

    #[test]
    fn parse_slide_url() {
        let u = "https://docs.google.com/presentation/d/xyz99/edit";
        assert_eq!(parse_google_slide_url(u).unwrap(), "xyz99");
    }
}