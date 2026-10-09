use anyhow::Result;
use serde_json::json;
use sqlx::PgPool;

use super::types::attachment_pdf_items;

pub async fn pdf_structure_for_hash(
    pool: &PgPool,
    hash: &str,
    name: &str,
) -> Result<serde_json::Value> {
    let index = c35_mod_file::doc_index_load_or_build(pool, hash, "application/pdf", name).await?;
    let page_count = index.get("units").and_then(|v| v.as_u64()).unwrap_or(0);
    let sections: Vec<serde_json::Value> = index
        .get("outline")
        .and_then(|v| v.as_array())
        .map(|items| {
            items
                .iter()
                .map(|item| {
                    let page = item
                        .get("unit")
                        .and_then(|v| v.as_u64())
                        .or_else(|| item.get("page").and_then(|v| v.as_u64()))
                        .unwrap_or(1);
                    json!({
                        "title": item.get("title").and_then(|v| v.as_str()).unwrap_or(""),
                        "page": page,
                        "level": item.get("level").and_then(|v| v.as_u64()).unwrap_or(1),
                    })
                })
                .collect()
        })
        .unwrap_or_default();
    Ok(json!({
        "ok": true,
        "file_hash": hash,
        "file_name": name,
        "page_count": page_count,
        "outline_from_bookmarks": !sections.is_empty(),
        "sections": sections,
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
            Err(e) => blocks.push(
                json!({ "ok": false, "file_hash": hash, "error": e.to_string() }).to_string(),
            ),
        }
    }
    Some(blocks.join("\n"))
}
