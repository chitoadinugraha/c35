//! Home tool `doc.extract` — page/slide text from the cached document index.

use anyhow::{anyhow, bail, Result};
use serde_json::{json, Value};

use crate::tool;

const MAX_CHARS_MIN: i64 = 500;
const MAX_CHARS_MAX: i64 = 32_000;
const DEFAULT_MAX_CHARS: i64 = 14_000;

tool! {
    struct: DocExtractTool,
    name: "doc.extract",
    aliases: ["doc_extract"],
    description: "Text of a page or slide range from an attached PDF, DOCX, or PPTX. file_hash is the attachment hash. Does not return the whole file.",
    topics: ["chat"],
    always: [],
    rag_phrases: [
        "read the pdf",
        "baca dokumen",
        "extract slides",
        "what does the attachment say",
        "baca lampiran",
    ],
    parameters: {
        file_hash: (string, "Attachment CAS hash", required),
        unit_from: (integer, "First page or slide (1-based, inclusive)", required),
        unit_to: (integer, "Last page or slide (1-based, inclusive)", required),
        max_chars: (integer, "Max characters of returned text", optional, default = 14000),
    },
    execute: |args, ctx| {
        let hash = args["file_hash"].as_str().unwrap_or_default().trim();
        if hash.is_empty() {
            bail!("file_hash required");
        }
        let unit_from = json_i64(&args["unit_from"], 1);
        let unit_to = json_i64(&args["unit_to"], unit_from);
        let max_chars = json_i64(&args["max_chars"], DEFAULT_MAX_CHARS);
        Ok(doc_extract_for_ctx(ctx, hash, unit_from, unit_to, max_chars).await?)
    }
}

async fn doc_extract_for_ctx(
    ctx: &crate::tools::ToolContext,
    file_hash: &str,
    unit_from: i64,
    unit_to: i64,
    max_chars: i64,
) -> Result<Value> {
    let hash = file_hash.trim();
    if hash.is_empty() {
        bail!("file_hash required");
    }
    let mut index = load_doc_index(&ctx.pool, hash).await?;
    let charged = fill_pdf_ocr(ctx, hash, &mut index, unit_from, unit_to).await;
    let mut out = doc_extract_from_index(hash, &index, unit_from, unit_to, max_chars);
    if charged.pages > 0 {
        if let Some(obj) = out.as_object_mut() {
            obj.insert("ocr_pages".into(), json!(charged.pages));
            obj.insert("ocr_cost_usd".into(), json!(charged.cost_usd));
            obj.insert("ocr_tokens_in".into(), json!(charged.tokens_in));
            obj.insert("ocr_tokens_out".into(), json!(charged.tokens_out));
        }
    }
    Ok(out)
}

struct OcrCallCharge {
    pages: i32,
    tokens_in: i32,
    tokens_out: i32,
    cost_usd: f64,
}

async fn fill_pdf_ocr(
    ctx: &crate::tools::ToolContext,
    hash: &str,
    index: &mut Value,
    unit_from: i64,
    unit_to: i64,
) -> OcrCallCharge {
    let mut charged = OcrCallCharge {
        pages: 0,
        tokens_in: 0,
        tokens_out: 0,
        cost_usd: 0.0,
    };
    let pages = ocr_candidate_pages(index, unit_from, unit_to);
    if pages.is_empty() {
        return charged;
    }
    let gate_ok = match ctx.billing.as_ref() {
        Some(bctx) => c35_mod_billing::billing_gate_scoped(&ctx.pool, bctx)
            .await
            .is_ok(),
        None => false,
    };
    if !crate::doc_ocr::ocr_charge_allowed(gate_ok) {
        return charged;
    }
    let pdf_bytes = match c35_mod_file::cas_bytes_get(
        &ctx.pool,
        &c35_mod_file::cas_dir_default(),
        hash,
    )
    .await
    {
        Ok((bytes, _)) => bytes,
        Err(err) => {
            tracing::warn!("[c35:doc_ocr] blob read failed hash={hash}: {err}");
            return charged;
        }
    };
    let mut changed = false;
    for page in pages {
        let jpeg = match page_jpeg(&pdf_bytes, page).await {
            Some(bytes) => bytes,
            None => continue,
        };
        let usage = match crate::doc_ocr::ocr_jpeg(&ctx.http_client, &jpeg).await {
            Ok(usage) => usage,
            Err(err) => {
                tracing::warn!("[c35:doc_ocr] page {page} failed hash={hash}: {err:#}");
                continue;
            }
        };
        write_page_text(index, page, &usage.text);
        changed = true;
        crate::doc_ocr::apply_ocr_charge(&ctx.doc_ocr, &usage);
        charged.pages += 1;
        charged.tokens_in += usage.tokens_in;
        charged.tokens_out += usage.tokens_out;
        charged.cost_usd += usage.cost_usd;
    }
    if changed {
        persist_index(&ctx.pool, hash, index).await;
    }
    charged
}

fn ocr_candidate_pages(index: &Value, unit_from: i64, unit_to: i64) -> Vec<u32> {
    if index.get("kind").and_then(|v| v.as_str()).unwrap_or("") != "pdf" {
        return Vec::new();
    }
    let pages = index.get("pages").and_then(|v| v.as_array());
    let units = index
        .get("units")
        .and_then(|v| v.as_u64())
        .unwrap_or_else(|| pages.map(|rows| rows.len() as u64).unwrap_or(0));
    if units == 0 {
        return Vec::new();
    }
    let units_i = units as i64;
    let from = unit_from.clamp(1, units_i);
    let to = unit_to.clamp(from, units_i);
    let mut nums = Vec::new();
    if let Some(rows) = pages {
        for row in rows {
            let n = row.get("n").and_then(|v| v.as_u64()).unwrap_or(0);
            if n < from as u64 || n > to as u64 {
                continue;
            }
            let needs = row
                .get("needs_ocr")
                .and_then(|v| v.as_bool())
                .unwrap_or(false);
            let text = row.get("text").and_then(|v| v.as_str()).unwrap_or("");
            if needs && text.trim().is_empty() {
                nums.push(n as u32);
            }
        }
    }
    nums.sort_unstable();
    nums.dedup();
    nums.truncate(crate::doc_ocr::DOC_OCR_MAX_PAGES);
    nums
}

async fn page_jpeg(pdf_bytes: &[u8], page: u32) -> Option<Vec<u8>> {
    let bytes = pdf_bytes.to_vec();
    let parsed =
        tokio::task::spawn_blocking(move || c35_mod_file::pdf_page_embedded_jpeg(&bytes, page))
            .await;
    match parsed {
        Ok(Ok(Some(jpeg))) if !jpeg.is_empty() => Some(jpeg),
        Ok(Err(err)) => {
            tracing::warn!("[c35:doc_ocr] page image parse failed page={page}: {err:#}");
            None
        }
        _ => None,
    }
}

fn write_page_text(index: &mut Value, page: u32, text: &str) {
    let Some(pages) = index.get_mut("pages").and_then(|p| p.as_array_mut()) else {
        return;
    };
    for row in pages {
        if row.get("n").and_then(|v| v.as_u64()) != Some(u64::from(page)) {
            continue;
        }
        let Some(obj) = row.as_object_mut() else {
            continue;
        };
        obj.insert("text".to_string(), json!(text));
        obj.insert("needs_ocr".to_string(), json!(false));
        obj.insert("chars".to_string(), json!(text.chars().count()));
    }
}

async fn persist_index(pool: &sqlx::PgPool, hash: &str, index: &Value) {
    let Ok(doc) = serde_json::from_value::<c35_mod_file::DocIndex>(index.clone()) else {
        tracing::warn!("[c35:doc_ocr] index decode failed hash={hash}");
        return;
    };
    if let Err(err) = c35_mod_file::doc_index_put(pool, hash, &doc).await {
        tracing::warn!("[c35:doc_ocr] index put failed hash={hash}: {err:#}");
    }
}

pub async fn doc_extract_for_hash(
    pool: &sqlx::PgPool,
    file_hash: &str,
    unit_from: i64,
    unit_to: i64,
    max_chars: i64,
) -> Result<Value> {
    let hash = file_hash.trim();
    if hash.is_empty() {
        bail!("file_hash required");
    }
    let index = load_doc_index(pool, hash).await?;
    Ok(doc_extract_from_index(
        hash, &index, unit_from, unit_to, max_chars,
    ))
}

/// Cached index when `variants.doc_index` exists. On a miss with empty mime, read blob mime and build once.
async fn load_doc_index(pool: &sqlx::PgPool, hash: &str) -> Result<Value> {
    match c35_mod_file::doc_index_load_or_build(pool, hash, "", "").await {
        Ok(index) => Ok(index),
        Err(err) if is_unknown_kind(&err) => {
            let mime = blob_mime(pool, hash).await?;
            if mime.is_empty() {
                return Err(err);
            }
            c35_mod_file::doc_index_load_or_build(pool, hash, &mime, "").await
        }
        Err(err) => Err(err),
    }
}

fn is_unknown_kind(err: &anyhow::Error) -> bool {
    err.chain()
        .any(|cause| cause.to_string().contains("unknown document kind"))
}

async fn blob_mime(pool: &sqlx::PgPool, hash: &str) -> Result<String> {
    let meta = c35_mod_file::cas_meta_get(pool, hash)
        .await
        .map_err(|err| anyhow!("file meta: {err}"))?;
    Ok(meta.map(|row| row.mime_type).unwrap_or_default())
}

/// Join a cached index into the `doc.extract` JSON. No database and no model calls.
pub fn doc_extract_from_index(
    file_hash: &str,
    index: &Value,
    unit_from: i64,
    unit_to: i64,
    max_chars: i64,
) -> Value {
    let kind = index.get("kind").and_then(|v| v.as_str()).unwrap_or("");
    let label = if kind == "pptx" { "slide" } else { "page" };
    let pages = index.get("pages").and_then(|v| v.as_array());
    let units = index
        .get("units")
        .and_then(|v| v.as_u64())
        .unwrap_or_else(|| pages.map(|rows| rows.len() as u64).unwrap_or(0));
    let max_len = clamp_max_chars(max_chars);

    if units == 0 {
        return json!({
            "ok": true,
            "file_hash": file_hash,
            "kind": kind,
            "unit_from": 0,
            "unit_to": 0,
            "units": 0,
            "char_count": 0,
            "text": "",
            "ocr_pages": 0,
            "ocr_cost_usd": 0.0,
            "needs_ocr": false,
        });
    }

    let units_i = units as i64;
    let from = unit_from.clamp(1, units_i);
    let to = unit_to.clamp(from, units_i);

    let mut selected: Vec<(u64, String, bool)> = Vec::new();
    if let Some(rows) = pages {
        for row in rows {
            let n = row.get("n").and_then(|v| v.as_u64()).unwrap_or(0);
            if n < from as u64 || n > to as u64 {
                continue;
            }
            let needs = row
                .get("needs_ocr")
                .and_then(|v| v.as_bool())
                .unwrap_or(false);
            let text = if needs {
                String::new()
            } else {
                row.get("text")
                    .and_then(|v| v.as_str())
                    .unwrap_or("")
                    .to_string()
            };
            selected.push((n, text, needs));
        }
    }
    selected.sort_by_key(|(n, _, _)| *n);

    let mut ocr_pages: u64 = 0;
    let mut blocks = Vec::with_capacity(selected.len());
    for (n, text, needs) in &selected {
        if *needs {
            ocr_pages += 1;
        }
        blocks.push(format!("--- {label} {n} ---\n{text}"));
    }
    let joined = blocks.join("\n");
    let text: String = joined.chars().take(max_len as usize).collect();
    let needs_ocr = ocr_pages > 0;

    json!({
        "ok": true,
        "file_hash": file_hash,
        "kind": kind,
        "unit_from": from,
        "unit_to": to,
        "units": units,
        "char_count": text.chars().count(),
        "text": text,
        "ocr_pages": ocr_pages,
        "ocr_cost_usd": 0.0,
        "needs_ocr": needs_ocr,
    })
}

/// `presentation.source.extract` response, with text taken from the cached index.
pub fn presentation_source_extract_json(extracted: &Value) -> Value {
    json!({
        "ok": extracted.get("ok").cloned().unwrap_or(json!(true)),
        "file_hash": extracted.get("file_hash").cloned().unwrap_or(json!("")),
        "page_from": extracted.get("unit_from").cloned().unwrap_or(json!(1)),
        "page_to": extracted.get("unit_to").cloned().unwrap_or(json!(1)),
        "page_count": extracted.get("units").cloned().unwrap_or(json!(0)),
        "char_count": extracted.get("char_count").cloned().unwrap_or(json!(0)),
        "text": extracted.get("text").cloned().unwrap_or(json!("")),
    })
}

fn clamp_max_chars(max_chars: i64) -> i64 {
    max_chars.clamp(MAX_CHARS_MIN, MAX_CHARS_MAX)
}

fn json_i64(value: &Value, default: i64) -> i64 {
    if let Some(n) = value.as_i64() {
        return n;
    }
    if let Some(n) = value.as_u64() {
        return i64::try_from(n).unwrap_or(i64::MAX);
    }
    default
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::tools::Tool;

    fn sample_index() -> Value {
        json!({
            "kind": "pdf",
            "name": "notes.pdf",
            "units": 3,
            "pages": [
                {"n": 2, "text": "Beta", "needs_ocr": false},
                {"n": 1, "text": "Alpha", "needs_ocr": false},
                {"n": 3, "text": "SECRET_OCR", "needs_ocr": true}
            ]
        })
    }

    #[test]
    fn doc_extract_joins_pages_1_to_2() {
        let out = doc_extract_from_index("hash-1", &sample_index(), 1, 2, 14_000);
        assert_eq!(out["ok"], true);
        assert_eq!(out["file_hash"], "hash-1");
        assert_eq!(out["kind"], "pdf");
        assert_eq!(out["unit_from"].as_i64(), Some(1));
        assert_eq!(out["unit_to"].as_i64(), Some(2));
        assert_eq!(out["units"].as_i64(), Some(3));
        assert_eq!(out["text"], "--- page 1 ---\nAlpha\n--- page 2 ---\nBeta");
        assert_eq!(
            out["char_count"].as_i64(),
            Some(out["text"].as_str().unwrap().chars().count() as i64)
        );
        assert_eq!(out["needs_ocr"], false);
        assert_eq!(out["ocr_pages"].as_i64(), Some(0));
        assert_eq!(out["ocr_cost_usd"].as_f64(), Some(0.0));
        assert!(!out["text"].as_str().unwrap().contains("SECRET_OCR"));
    }

    #[test]
    fn doc_extract_max_chars_clamp() {
        let long = "x".repeat(4_000);
        let index = json!({
            "kind": "pdf",
            "units": 1,
            "pages": [{"n": 1, "text": long, "needs_ocr": false}]
        });
        let low = doc_extract_from_index("h", &index, 1, 1, 10);
        assert_eq!(low["char_count"].as_i64(), Some(500));
        assert_eq!(low["text"].as_str().unwrap().chars().count(), 500);
        assert!(low["text"]
            .as_str()
            .unwrap()
            .starts_with("--- page 1 ---\n"));

        let huge = "y".repeat(40_000);
        let index_huge = json!({
            "kind": "pdf",
            "units": 1,
            "pages": [{"n": 1, "text": huge, "needs_ocr": false}]
        });
        let high = doc_extract_from_index("h", &index_huge, 1, 1, 1_000_000);
        assert_eq!(high["char_count"].as_i64(), Some(32_000));
        assert_eq!(high["text"].as_str().unwrap().chars().count(), 32_000);
    }

    #[test]
    fn doc_extract_needs_ocr_page_does_not_invent_text() {
        let out = doc_extract_from_index("hash-1", &sample_index(), 3, 3, 14_000);
        let text = out["text"].as_str().unwrap();
        assert_eq!(text, "--- page 3 ---\n");
        assert!(!text.contains("SECRET_OCR"));
        assert_eq!(out["needs_ocr"], true);
        assert_eq!(out["ocr_pages"].as_i64(), Some(1));
        assert_eq!(out["ocr_cost_usd"].as_f64(), Some(0.0));
        assert_eq!(out["unit_from"].as_i64(), Some(3));
        assert_eq!(out["unit_to"].as_i64(), Some(3));
    }

    #[test]
    fn doc_extract_pptx_uses_slide_label() {
        let index = json!({
            "kind": "pptx",
            "units": 2,
            "pages": [
                {"n": 1, "text": "Title", "needs_ocr": false},
                {"n": 2, "text": "Body", "needs_ocr": false}
            ]
        });
        let out = doc_extract_from_index("deck", &index, 0, 99, 14_000);
        assert_eq!(out["unit_from"].as_i64(), Some(1));
        assert_eq!(out["unit_to"].as_i64(), Some(2));
        assert_eq!(out["text"], "--- slide 1 ---\nTitle\n--- slide 2 ---\nBody");
    }

    #[test]
    fn doc_extract_tool_definition() {
        let def = DocExtractTool.definition();
        assert_eq!(def.name, "doc.extract");
        assert!(def.aliases.iter().any(|a| a == "doc_extract"));
        assert!(def.topics.iter().any(|t| t == "chat"));
        assert!(def.always.is_empty());
        assert!(def.rag_phrases.iter().any(|p| p == "baca dokumen"));
        assert_eq!(def.parameters["properties"]["file_hash"]["type"], "string");
        assert_eq!(
            def.parameters["properties"]["max_chars"]["default"].as_i64(),
            Some(14000)
        );
        let required = def.parameters["required"].as_array().unwrap();
        assert!(required.iter().any(|v| v == "file_hash"));
        assert!(required.iter().any(|v| v == "unit_from"));
        assert!(required.iter().any(|v| v == "unit_to"));
        assert!(!required.iter().any(|v| v == "max_chars"));
    }

    #[test]
    fn doc_extract_cached_text_does_not_bill() {
        let index = json!({
            "kind": "pdf",
            "units": 1,
            "pages": [{"n": 1, "text": "Already read", "needs_ocr": false}]
        });
        let out = doc_extract_from_index("hash", &index, 1, 1, 14_000);
        assert_eq!(out["ocr_pages"].as_i64(), Some(0));
        assert_eq!(out["ocr_cost_usd"].as_f64(), Some(0.0));
        assert_eq!(out["needs_ocr"], false);
        assert!(out["text"].as_str().unwrap().contains("Already read"));
    }
}
