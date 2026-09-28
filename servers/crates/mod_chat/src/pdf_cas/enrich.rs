use anyhow::{Context, Result};
use c35_mod_file::{cas_bytes_get, cas_dir_default};
use serde_json::json;
use sqlx::PgPool;

use super::parse::{pdf_extract_pages, pdf_structure};
use super::types::attachment_pdf_items;

pub async fn pdf_bytes_load(pool: &PgPool, hash: &str) -> Result<Vec<u8>> {
    let (bytes, _) = cas_bytes_get(pool, &cas_dir_default(), hash)
        .await
        .context("load PDF from CAS")?;
    Ok(bytes)
}

pub async fn pdf_structure_for_hash(pool: &PgPool, hash: &str, name: &str) -> Result<serde_json::Value> {
    let bytes = pdf_bytes_load(pool, hash).await?;
    let structure = pdf_structure(&bytes)?;
    let sections = serde_json::to_value(&structure.sections).unwrap_or(json!([]));
    Ok(json!({
        "ok": true,
        "file_hash": hash,
        "file_name": name,
        "page_count": structure.page_count,
        "outline_from_bookmarks": structure.outline_from_bookmarks,
        "sections": sections,
    }))
}

pub async fn pdf_extract_for_hash(
    pool: &PgPool,
    hash: &str,
    page_from: u32,
    page_to: u32,
    max_chars: usize,
) -> Result<serde_json::Value> {
    let bytes = pdf_bytes_load(pool, hash).await?;
    let structure = pdf_structure(&bytes)?;
    let text = pdf_extract_pages(&bytes, page_from, page_to, max_chars)?;
    Ok(json!({
        "ok": true,
        "file_hash": hash,
        "page_from": page_from,
        "page_to": page_to,
        "page_count": structure.page_count,
        "char_count": text.chars().count(),
        "text": text,
    }))
}

pub async fn presentation_pdf_enrich(pool: &PgPool, attachments_json: &str) -> Option<String> {
    let items = attachment_pdf_items(attachments_json);
    if items.is_empty() {
        return None;
    }
    let mut blocks = Vec::new();
    for (hash, name) in items.iter().take(2) {
        match pdf_structure_for_hash(pool, hash, name).await {
            Ok(v) => blocks.push(v.to_string()),
            Err(e) => blocks.push(json!({ "ok": false, "file_hash": hash, "error": e.to_string() }).to_string()),
        }
    }
    Some(blocks.join("\n"))
}