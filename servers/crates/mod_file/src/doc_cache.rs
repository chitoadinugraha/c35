//! CAS cache for document indexes. Image bytes stay in the parser result, never in the blob.

use std::time::Duration;

use anyhow::{anyhow, Context, Result};
use serde_json::Value;

use crate::doc_index::{doc_index_json, DocIndex};
use crate::{
    cas_bytes_get, cas_dir_default, cas_hmac_secret, cas_put, docx_doc_index, file_variant_get,
    file_variant_set, pdf_doc_index, pptx_doc_index,
};

const DOC_INDEX_VARIANT: &str = "doc_index";
const DOC_INDEX_PARSE_TIMEOUT: Duration = Duration::from_secs(5);

pub fn doc_kind_from_mime_name(mime: &str, name: &str) -> Option<&'static str> {
    let mime_l = mime.to_ascii_lowercase();
    let name_l = name.to_ascii_lowercase();
    if mime_l.contains("pdf") || name_l.ends_with(".pdf") {
        Some("pdf")
    } else if mime_l.contains("wordprocessingml.document") || name_l.ends_with(".docx") {
        Some("docx")
    } else if mime_l.contains("presentationml.presentation") || name_l.ends_with(".pptx") {
        Some("pptx")
    } else {
        None
    }
}

pub async fn doc_index_get(pool: &sqlx::PgPool, hash: &str) -> Result<Option<Value>> {
    let Some(variant_hash) = file_variant_get(pool, hash, DOC_INDEX_VARIANT).await? else {
        return Ok(None);
    };
    let (bytes, _) = cas_bytes_get(pool, &cas_dir_default(), &variant_hash).await?;
    let value = serde_json::from_slice(&bytes).context("parse doc_index json")?;
    Ok(Some(value))
}

pub async fn doc_index_put(pool: &sqlx::PgPool, hash: &str, index: &DocIndex) -> Result<String> {
    let body = serde_json::to_vec(&doc_index_json(index)).context("serialize doc index")?;
    let secret = cas_hmac_secret();
    let put = cas_put(pool, &cas_dir_default(), &secret, &body, "application/json").await?;
    file_variant_set(pool, hash, DOC_INDEX_VARIANT, &put.hash).await?;
    Ok(put.hash)
}

pub async fn doc_index_load_or_build(
    pool: &sqlx::PgPool,
    hash: &str,
    mime: &str,
    name: &str,
) -> Result<Value> {
    if hash.trim().is_empty() {
        return Err(anyhow!("empty hash"));
    }
    if let Some(cached) = doc_index_get(pool, hash).await? {
        return Ok(cached);
    }
    let kind =
        doc_kind_from_mime_name(mime, name).ok_or_else(|| anyhow!("unknown document kind"))?;
    let (bytes, _) = cas_bytes_get(pool, &cas_dir_default(), hash).await?;
    let name = name.to_string();
    let kind = kind.to_string();
    let index = tokio::time::timeout(
        DOC_INDEX_PARSE_TIMEOUT,
        tokio::task::spawn_blocking(move || parse_doc_index(&kind, &bytes, &name)),
    )
    .await
    .map_err(|_| anyhow!("document index parse timed out"))?
    .map_err(|e| anyhow!("document index parse task failed: {e}"))??;
    let json = doc_index_json(&index);
    doc_index_put(pool, hash, &index).await?;
    Ok(json)
}

fn parse_doc_index(kind: &str, bytes: &[u8], name: &str) -> Result<DocIndex> {
    let mut index = match kind {
        "pdf" => pdf_doc_index(bytes)?,
        "docx" => docx_doc_index(bytes)?,
        "pptx" => pptx_doc_index(bytes)?,
        _ => return Err(anyhow!("unknown document kind")),
    };
    if index.name.is_empty() {
        index.name = name.to_string();
    }
    Ok(index)
}

#[cfg(test)]
mod tests {
    use super::doc_kind_from_mime_name;

    #[test]
    fn doc_kind_from_mime_name_cases() {
        assert_eq!(
            doc_kind_from_mime_name("application/pdf", "notes.bin"),
            Some("pdf")
        );
        assert_eq!(
            doc_kind_from_mime_name("application/octet-stream", "Report.PDF"),
            Some("pdf")
        );
        assert_eq!(
            doc_kind_from_mime_name(
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                "x.bin"
            ),
            Some("docx")
        );
        assert_eq!(
            doc_kind_from_mime_name("application/octet-stream", "memo.DOCX"),
            Some("docx")
        );
        assert_eq!(
            doc_kind_from_mime_name(
                "application/vnd.openxmlformats-officedocument.presentationml.presentation",
                "x.bin"
            ),
            Some("pptx")
        );
        assert_eq!(
            doc_kind_from_mime_name("application/octet-stream", "deck.PPTX"),
            Some("pptx")
        );
        assert_eq!(
            doc_kind_from_mime_name("application/octet-stream", "setup.exe"),
            None
        );
    }
}
