use std::path::PathBuf;

use c35_mod_file::{cas_bytes_get, cas_hash_normalize, cas_meta_get, cas_put};
use c35_proto::MailAttachment;
use serde::{Deserialize, Serialize};
use sqlx::PgPool;

pub const MAX_ATTACHMENTS: usize = 10;
pub const MAX_ATTACHMENT_BYTES: usize = 5 * 1024 * 1024;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MailAttachmentMeta {
    pub path: String,
    #[serde(default)]
    pub name: String,
    #[serde(default)]
    pub mime: String,
    #[serde(default)]
    pub size: i64,
}

pub struct MailCas {
    pub pool: PgPool,
    pub cas_dir: PathBuf,
    pub cas_secret: String,
}

pub fn attachments_to_json(atts: &[MailAttachmentMeta]) -> String {
    serde_json::to_string(atts).unwrap_or_else(|_| "[]".into())
}

pub fn path_to_hash(path: &str) -> Option<String> {
    cas_hash_normalize(path.trim().strip_prefix("/fs/")?)
}

pub async fn validate_and_normalize(
    cas: &MailCas,
    atts: &[MailAttachment],
) -> Result<Vec<MailAttachmentMeta>, String> {
    if atts.len() > MAX_ATTACHMENTS {
        return Err(format!("too many attachments (max {MAX_ATTACHMENTS})"));
    }
    let mut out = Vec::with_capacity(atts.len());
    for a in atts {
        let path = a.path.trim();
        let hash = path_to_hash(path).ok_or_else(|| format!("invalid attachment path: {path}"))?;
        let meta = cas_meta_get(&cas.pool, &hash)
            .await
            .map_err(|e| e.to_string())?
            .ok_or_else(|| format!("attachment not found: {path}"))?;
        let size = if a.size > 0 { a.size } else { meta.size_bytes };
        if size as usize > MAX_ATTACHMENT_BYTES {
            return Err(format!("attachment too large (max {} bytes)", MAX_ATTACHMENT_BYTES));
        }
        let mime = if a.mime.trim().is_empty() { meta.mime_type } else { a.mime.trim().to_string() };
        let name = if a.name.trim().is_empty() {
            format!("attachment-{hash:.8}")
        } else {
            sanitize_filename(a.name.trim())
        };
        out.push(MailAttachmentMeta {
            path: format!("/fs/{hash}"),
            name,
            mime,
            size,
        });
    }
    Ok(out)
}

pub async fn store_bytes(cas: &MailCas, mime: &str, name: &str, body: &[u8]) -> Result<MailAttachmentMeta, String> {
    if body.len() > MAX_ATTACHMENT_BYTES {
        return Err(format!("attachment too large (max {} bytes)", MAX_ATTACHMENT_BYTES));
    }
    let mime = if mime.trim().is_empty() { "application/octet-stream" } else { mime.trim() };
    let put = cas_put(&cas.pool, &cas.cas_dir, &cas.cas_secret, body, mime)
        .await
        .map_err(|e| e.to_string())?;
    Ok(MailAttachmentMeta {
        path: format!("/fs/{}", put.hash),
        name: sanitize_filename(name),
        mime: put.mime_type,
        size: put.size_bytes,
    })
}

pub async fn load_bytes(cas: &MailCas, meta: &MailAttachmentMeta) -> Result<(String, Vec<u8>), String> {
    let hash = path_to_hash(&meta.path).ok_or_else(|| "invalid path".to_string())?;
    let (bytes, _) = cas_bytes_get(&cas.pool, &cas.cas_dir, &hash).await.map_err(|e| e.to_string())?;
    let file_meta = cas_meta_get(&cas.pool, &hash).await.map_err(|e| e.to_string())?;
    let mime = if meta.mime.trim().is_empty() {
        file_meta.map(|m| m.mime_type).unwrap_or_else(|| "application/octet-stream".into())
    } else {
        meta.mime.clone()
    };
    Ok((mime, bytes.to_vec()))
}

pub async fn inbound_from_base64(
    cas: Option<&MailCas>,
    raw: &[crate::inbound::MailInboundAttachment],
) -> Result<Vec<MailAttachmentMeta>, String> {
    let Some(cas) = cas else {
        return if raw.is_empty() { Ok(Vec::new()) } else { Err("file store not configured".into()) };
    };
    let mut out = Vec::new();
    for a in raw {
        let data_b64 = a.data.as_deref().unwrap_or("").trim();
        if data_b64.is_empty() {
            continue;
        }
        let bytes = base64::Engine::decode(&base64::engine::general_purpose::STANDARD, data_b64)
            .or_else(|_| base64::Engine::decode(&base64::engine::general_purpose::STANDARD_NO_PAD, data_b64))
            .map_err(|e| format!("invalid attachment base64: {e}"))?;
        if bytes.len() > MAX_ATTACHMENT_BYTES {
            continue;
        }
        let name = a.name.as_deref().map(str::trim).filter(|s| !s.is_empty()).unwrap_or("attachment");
        let mime = a.mime.as_deref().map(str::trim).filter(|s| !s.is_empty()).unwrap_or("application/octet-stream");
        out.push(store_bytes(cas, mime, name, &bytes).await?);
    }
    Ok(out)
}

fn sanitize_filename(name: &str) -> String {
    let cleaned: String = name.chars().map(|c| if c.is_control() || "/\\<>|".contains(c) { '_' } else { c }).take(180).collect();
    let cleaned = cleaned.trim().trim_matches('.');
    if cleaned.is_empty() { "attachment".into() } else { cleaned.to_string() }
}
