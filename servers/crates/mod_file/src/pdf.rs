//! PDF structure (outline / page count) and scoped text extract — no LLM.

use anyhow::{bail, Context, Result};
use lopdf::{Document, Object, Stream};
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

pub const PDF_PARSE_MAX_BYTES: usize = 32 * 1024 * 1024;
pub const PDF_STRUCTURE_SECTION_CAP: usize = 80;
pub const PDF_EXTRACT_DEFAULT_MAX_CHARS: usize = 14_000;
pub const PDF_EXTRACT_ABSOLUTE_MAX_CHARS: usize = 32_000;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PdfSection {
    pub title: String,
    /// 1-based page number (best effort from outline).
    /// Stored doc-index JSON renames this to `unit` via `doc_index_json`.
    #[serde(alias = "unit")]
    pub page: u32,
    pub level: u8,
}

#[derive(Debug, Clone, Serialize)]
pub struct PdfStructure {
    pub page_count: u32,
    pub sections: Vec<PdfSection>,
    pub outline_from_bookmarks: bool,
}

pub fn pdf_structure(bytes: &[u8]) -> Result<PdfStructure> {
    if bytes.is_empty() {
        bail!("empty PDF");
    }
    if bytes.len() > PDF_PARSE_MAX_BYTES {
        bail!(
            "PDF too large (max {} MB)",
            PDF_PARSE_MAX_BYTES / (1024 * 1024)
        );
    }
    let doc = Document::load_mem(bytes).context("parse PDF")?;
    let pages = doc.get_pages();
    let page_count = pages.len().max(1) as u32;
    let mut sections = outline_sections(&doc, &pages);
    let outline_from_bookmarks = !sections.is_empty();
    if sections.is_empty() {
        sections = heading_heuristic(&doc, &pages, 12);
    }
    if sections.len() > PDF_STRUCTURE_SECTION_CAP {
        sections.truncate(PDF_STRUCTURE_SECTION_CAP);
    }
    Ok(PdfStructure {
        page_count,
        sections,
        outline_from_bookmarks,
    })
}

pub fn pdf_extract_pages(
    bytes: &[u8],
    page_from: u32,
    page_to: u32,
    max_chars: usize,
) -> Result<String> {
    if bytes.is_empty() {
        bail!("empty PDF");
    }
    if bytes.len() > PDF_PARSE_MAX_BYTES {
        bail!(
            "PDF too large (max {} MB)",
            PDF_PARSE_MAX_BYTES / (1024 * 1024)
        );
    }
    let doc = Document::load_mem(bytes).context("parse PDF")?;
    let pages = doc.get_pages();
    let page_count = pages.len().max(1) as u32;
    let from = page_from.clamp(1, page_count);
    let to = page_to.clamp(from, page_count);
    let max_len = max_chars.clamp(500, PDF_EXTRACT_ABSOLUTE_MAX_CHARS);
    let mut out = String::new();
    for p in from..=to {
        let chunk = doc
            .extract_text(&[p])
            .with_context(|| format!("extract page {p}"))?;
        let chunk = chunk
            .lines()
            .map(str::trim)
            .filter(|l| !l.is_empty())
            .collect::<Vec<_>>()
            .join("\n");
        if chunk.is_empty() {
            continue;
        }
        let block = format!("--- page {p} ---\n{chunk}\n");
        if out.chars().count() + block.chars().count() > max_len {
            let remain = max_len.saturating_sub(out.chars().count());
            if remain > 20 {
                out.push_str(&block.chars().take(remain).collect::<String>());
                out.push('…');
            }
            break;
        }
        out.push_str(&block);
    }
    Ok(out.trim().to_string())
}

fn outline_sections(doc: &Document, pages: &BTreeMap<u32, (u32, u16)>) -> Vec<PdfSection> {
    let mut out = Vec::new();
    let Ok(catalog) = doc.catalog() else {
        return out;
    };
    let Ok(outlines) = catalog.get(b"Outlines") else {
        return out;
    };
    let Some(outlines) = deref_dict(doc, outlines) else {
        return out;
    };
    let Ok(first) = outlines.get(b"First") else {
        return out;
    };
    walk_outline(doc, pages, first, 1, &mut out);
    out
}

fn walk_outline(
    doc: &Document,
    pages: &BTreeMap<u32, (u32, u16)>,
    node_obj: &Object,
    level: u8,
    out: &mut Vec<PdfSection>,
) {
    if out.len() >= PDF_STRUCTURE_SECTION_CAP || level > 12 {
        return;
    }
    let Some(node_id) = node_obj.as_reference().ok() else {
        return;
    };
    let Ok(dict) = doc.get_dictionary(node_id) else {
        return;
    };
    if let Some(title) = outline_title(doc, dict) {
        let page = outline_page(doc, pages, node_id).unwrap_or(1);
        out.push(PdfSection {
            title,
            page,
            level: level.min(6),
        });
    }
    if let Ok(first) = dict.get(b"First") {
        walk_outline(doc, pages, first, level.saturating_add(1), out);
    }
    if out.len() >= PDF_STRUCTURE_SECTION_CAP {
        return;
    }
    if let Ok(next) = dict.get(b"Next") {
        walk_outline(doc, pages, next, level, out);
    }
}

fn outline_title(doc: &Document, dict: &lopdf::Dictionary) -> Option<String> {
    let obj = dict.get(b"Title").ok()?;
    let resolved = match obj.as_reference() {
        Ok(id) => doc.get_object(id).ok()?,
        Err(_) => obj,
    };
    let title = lopdf::decode_text_string(resolved).ok()?;
    let title = title.trim();
    if title.is_empty() {
        None
    } else {
        Some(title.to_string())
    }
}

fn outline_page(
    doc: &Document,
    pages: &BTreeMap<u32, (u32, u16)>,
    obj_id: (u32, u16),
) -> Option<u32> {
    if let Ok(obj) = doc.get_object(obj_id) {
        if let Object::Dictionary(dict) = obj {
            if let Ok(dest) = dict.get(b"Dest") {
                return dest_page(doc, pages, dest);
            }
            if let Ok(a) = dict.get(b"A") {
                return action_page(doc, pages, a);
            }
        }
    }
    None
}

fn action_page(doc: &Document, pages: &BTreeMap<u32, (u32, u16)>, action: &Object) -> Option<u32> {
    if let Object::Dictionary(d) = action {
        if let Ok(dest) = d.get(b"D") {
            return dest_page(doc, pages, dest);
        }
    }
    None
}

fn dest_page(doc: &Document, pages: &BTreeMap<u32, (u32, u16)>, dest: &Object) -> Option<u32> {
    let arr = match dest {
        Object::Array(a) => a,
        _ => return None,
    };
    if arr.is_empty() {
        return None;
    }
    page_num_from_ref(doc, pages, &arr[0])
}

fn page_num_from_ref(
    doc: &Document,
    pages: &BTreeMap<u32, (u32, u16)>,
    obj: &Object,
) -> Option<u32> {
    let id = match obj {
        Object::Reference(r) => (r.0, r.1),
        _ => return None,
    };
    for (num, &(oid, gen)) in pages {
        if oid == id.0 && gen == id.1 {
            return Some(*num);
        }
    }
    if let Ok(target) = doc.get_object((id.0, id.1)) {
        if let Object::Dictionary(d) = target {
            if let Ok(Object::Reference(p)) = d.get(b"Parent") {
                return page_num_from_ref(doc, pages, &Object::Reference(*p));
            }
        }
    }
    None
}

/// First lines that look like numbered / titled headings (fallback when no PDF bookmarks).
fn heading_heuristic(
    doc: &Document,
    pages: &BTreeMap<u32, (u32, u16)>,
    max_pages: u32,
) -> Vec<PdfSection> {
    let mut out = Vec::new();
    let scan = pages.len().min(max_pages as usize) as u32;
    for p in 1..=scan {
        let Ok(text) = doc.extract_text(&[p]) else {
            continue;
        };
        for line in text.lines().map(str::trim).filter(|l| !l.is_empty()) {
            if line.chars().count() > 120 {
                continue;
            }
            let looks = line.len() >= 4
                && (line.chars().next().is_some_and(|c| c.is_ascii_digit())
                    || line.chars().filter(|c| c.is_uppercase()).count() >= line.len() / 2);
            if looks {
                out.push(PdfSection {
                    title: line.to_string(),
                    page: p,
                    level: 1,
                });
            }
            if out.len() >= PDF_STRUCTURE_SECTION_CAP {
                return out;
            }
        }
    }
    out
}

const PDF_INDEX_PAGE_MAX_CHARS: usize = 8_000;
const PDF_INDEX_TOTAL_MAX_CHARS: usize = 200_000;
const PDF_INDEX_IMAGE_MIN_BYTES: usize = 8_192;

pub fn pdf_doc_index(bytes: &[u8]) -> Result<crate::doc_index::DocIndex> {
    if bytes.is_empty() {
        bail!("empty PDF");
    }
    if bytes.len() > PDF_PARSE_MAX_BYTES {
        bail!(
            "PDF too large (max {} MB)",
            PDF_PARSE_MAX_BYTES / (1024 * 1024)
        );
    }
    let structure = pdf_structure(bytes)?;
    let doc = Document::load_mem(bytes).context("parse PDF")?;
    let page_map = doc.get_pages();
    let mut page_nums: Vec<u32> = page_map.keys().copied().collect();
    if page_nums.is_empty() {
        page_nums.push(1);
    }
    let mut total_chars = 0usize;
    let mut pages = Vec::with_capacity(page_nums.len());
    for n in page_nums {
        let raw = doc
            .extract_text(&[n])
            .with_context(|| format!("extract page {n}"))?;
        let trimmed = trim_page_text(&raw);
        let text = take_index_text(&trimmed, &mut total_chars);
        let image_jpeg = if trimmed.is_empty() {
            page_map
                .get(&n)
                .and_then(|id| largest_page_image(&doc, *id))
        } else {
            None
        };
        let needs_ocr = image_jpeg.is_some();
        pages.push(crate::doc_index::DocPage {
            n,
            text,
            needs_ocr,
            image_jpeg,
        });
    }
    Ok(crate::doc_index::DocIndex {
        kind: "pdf".to_string(),
        name: String::new(),
        units: structure.page_count.max(pages.len() as u32),
        outline: structure.sections,
        pages,
    })
}

fn trim_page_text(raw: &str) -> String {
    raw.lines()
        .map(str::trim)
        .filter(|l| !l.is_empty())
        .collect::<Vec<_>>()
        .join("\n")
}

fn take_index_text(trimmed: &str, total_chars: &mut usize) -> String {
    if *total_chars >= PDF_INDEX_TOTAL_MAX_CHARS {
        return String::new();
    }
    let mut text: String = trimmed.chars().take(PDF_INDEX_PAGE_MAX_CHARS).collect();
    let room = PDF_INDEX_TOTAL_MAX_CHARS - *total_chars;
    if text.chars().count() > room {
        text = text.chars().take(room).collect();
    }
    *total_chars += text.chars().count();
    text
}

/// Largest embedded image XObject on this page, if its stream is bigger than 8 KiB.
///
/// Only `/Resources` `/XObject` entries with `/Subtype /Image` are considered, including
/// resources inherited through `/Parent`. Inline images (`BI`/`ID`/`EI`) and images nested
/// inside Form XObjects are not walked — there is no raster renderer, so a scanned page
/// drawn that way stays `needs_ocr = false`.
fn largest_page_image(doc: &Document, page_id: (u32, u16)) -> Option<Vec<u8>> {
    let resources = page_resources(doc, page_id)?;
    let xobj = deref_dict(doc, resources.get(b"XObject").ok()?)?;
    let mut best: Option<Vec<u8>> = None;
    for (_, obj) in xobj.iter() {
        let Some(stream) = deref_stream(doc, obj) else {
            continue;
        };
        let Some(bytes) = image_stream_bytes(stream) else {
            continue;
        };
        if bytes.len() <= PDF_INDEX_IMAGE_MIN_BYTES {
            continue;
        }
        let replace = best.as_ref().map(|b| bytes.len() > b.len()).unwrap_or(true);
        if replace {
            best = Some(bytes);
        }
    }
    best
}

fn page_resources<'a>(doc: &'a Document, mut page_id: (u32, u16)) -> Option<&'a lopdf::Dictionary> {
    for _ in 0..8 {
        let dict = doc.get_dictionary(page_id).ok()?;
        if let Ok(res) = dict.get(b"Resources") {
            if let Some(resolved) = deref_dict(doc, res) {
                return Some(resolved);
            }
        }
        let parent = match dict.get(b"Parent").ok()? {
            Object::Reference(id) => *id,
            _ => return None,
        };
        page_id = parent;
    }
    None
}

fn deref_dict<'a>(doc: &'a Document, obj: &'a Object) -> Option<&'a lopdf::Dictionary> {
    match obj {
        Object::Dictionary(d) => Some(d),
        Object::Reference(id) => doc.get_object(*id).ok().and_then(|o| match o {
            Object::Dictionary(d) => Some(d),
            _ => None,
        }),
        _ => None,
    }
}

fn deref_stream<'a>(doc: &'a Document, obj: &'a Object) -> Option<&'a Stream> {
    match obj {
        Object::Stream(s) => Some(s),
        Object::Reference(id) => match doc.get_object(*id).ok()? {
            Object::Stream(s) => Some(s),
            _ => None,
        },
        _ => None,
    }
}

fn image_stream_bytes(stream: &Stream) -> Option<Vec<u8>> {
    let subtype = stream.dict.get(b"Subtype").ok()?;
    let is_image = match subtype {
        Object::Name(n) => n.as_slice() == b"Image",
        _ => false,
    };
    if !is_image {
        return None;
    }
    if stream.content.len() > PDF_INDEX_IMAGE_MIN_BYTES {
        return Some(stream.content.clone());
    }
    if let Ok(decoded) = stream.decompressed_content() {
        if decoded.len() > PDF_INDEX_IMAGE_MIN_BYTES {
            return Some(decoded);
        }
    }
    None
}

/// Largest embedded image on a 1-based page when that stream is bigger than 8 KiB.
///
/// Same XObject walk as indexing. No pdfium and no raster.
pub fn pdf_page_embedded_jpeg(bytes: &[u8], page: u32) -> Result<Option<Vec<u8>>> {
    if bytes.is_empty() {
        bail!("empty PDF");
    }
    if bytes.len() > PDF_PARSE_MAX_BYTES {
        bail!(
            "PDF too large (max {} MB)",
            PDF_PARSE_MAX_BYTES / (1024 * 1024)
        );
    }
    let doc = Document::load_mem(bytes).context("parse PDF")?;
    let Some(page_id) = doc.get_pages().get(&page).copied() else {
        return Ok(None);
    };
    Ok(largest_page_image(&doc, page_id))
}

pub fn pdf_mime_ok(mime: &str, name: &str) -> bool {
    let m = mime.to_ascii_lowercase();
    if m == "application/pdf" || m.contains("pdf") {
        return true;
    }
    name.to_ascii_lowercase().ends_with(".pdf")
}

#[cfg(test)]
mod pdf_doc_index_tests {
    use super::*;
    use lopdf::{dictionary, Document, Object, Stream};

    fn hello_pdf() -> Vec<u8> {
        let mut doc = Document::with_version("1.5");
        let pages_id = doc.new_object_id();
        let font_id = doc.add_object(dictionary! {
            "Type" => "Font",
            "Subtype" => "Type1",
            "BaseFont" => "Helvetica",
        });
        let resources_id = doc.add_object(dictionary! {
            "Font" => dictionary! {
                "F1" => font_id,
            },
        });
        let content = Stream::new(
            dictionary! {},
            b"BT /F1 24 Tf 100 700 Td (Hello) Tj ET".to_vec(),
        );
        let content_id = doc.add_object(content);
        let page_id = doc.add_object(dictionary! {
            "Type" => "Page",
            "Parent" => pages_id,
            "Contents" => content_id,
            "Resources" => resources_id,
            "MediaBox" => vec![0.into(), 0.into(), 612.into(), 792.into()],
        });
        doc.objects.insert(
            pages_id,
            Object::Dictionary(dictionary! {
                "Type" => "Pages",
                "Kids" => vec![page_id.into()],
                "Count" => 1,
            }),
        );
        let catalog_id = doc.add_object(dictionary! {
            "Type" => "Catalog",
            "Pages" => pages_id,
        });
        doc.trailer.set("Root", catalog_id);
        let mut bytes = Vec::new();
        doc.save_to(&mut bytes).expect("save pdf");
        bytes
    }

    #[test]
    fn pdf_doc_index_hello_omits_image_jpeg() {
        let mut index = pdf_doc_index(&hello_pdf()).expect("index");
        assert_eq!(index.kind, "pdf");
        assert!(index.units >= 1);
        assert!(!index.pages.is_empty());
        assert!(!index.pages[0].needs_ocr);
        assert!(index.pages[0].text.contains("Hello"));
        assert!(index.pages[0].image_jpeg.is_none());

        index.pages[0].image_jpeg = Some(vec![0xFF, 0xD8, 1, 2, 3, 0xFF, 0xD9]);
        let json = crate::doc_index::doc_index_json(&index);
        assert!(json["pages"][0].get("image_jpeg").is_none());
        assert_eq!(
            json["pages"][0]["chars"],
            index.pages[0].text.chars().count()
        );
        assert_eq!(json["kind"], "pdf");
        assert!(json.get("outline").is_some());
        let rendered = json.to_string();
        assert!(!rendered.contains("image_jpeg"));
    }

    fn page_with_image(image_len: usize) -> Vec<u8> {
        let mut doc = Document::with_version("1.5");
        let pages_id = doc.new_object_id();
        let image = Stream::new(
            dictionary! {
                "Type" => "XObject",
                "Subtype" => "Image",
                "Width" => 8,
                "Height" => 8,
                "ColorSpace" => "DeviceGray",
                "BitsPerComponent" => 8,
            },
            vec![0xAB; image_len],
        );
        let image_id = doc.add_object(image);
        let resources_id = doc.add_object(dictionary! {
            "XObject" => dictionary! {
                "Im0" => image_id,
            },
        });
        let content = Stream::new(dictionary! {}, b"q Q".to_vec());
        let content_id = doc.add_object(content);
        let page_id = doc.add_object(dictionary! {
            "Type" => "Page",
            "Parent" => pages_id,
            "Contents" => content_id,
            "Resources" => resources_id,
            "MediaBox" => vec![0.into(), 0.into(), 612.into(), 792.into()],
        });
        doc.objects.insert(
            pages_id,
            Object::Dictionary(dictionary! {
                "Type" => "Pages",
                "Kids" => vec![page_id.into()],
                "Count" => 1,
            }),
        );
        let catalog_id = doc.add_object(dictionary! {
            "Type" => "Catalog",
            "Pages" => pages_id,
        });
        doc.trailer.set("Root", catalog_id);
        let mut bytes = Vec::new();
        doc.save_to(&mut bytes).expect("save pdf");
        bytes
    }

    #[test]
    fn pdf_page_embedded_jpeg_keeps_largest_over_8kib() {
        let small = pdf_page_embedded_jpeg(&page_with_image(8_192), 1).expect("parse");
        assert!(small.is_none());
        let large = pdf_page_embedded_jpeg(&page_with_image(8_193), 1).expect("parse");
        let bytes = large.expect("image");
        assert!(bytes.len() > 8_192);
        assert!(pdf_page_embedded_jpeg(&hello_pdf(), 1)
            .expect("hello")
            .is_none());
        assert!(pdf_page_embedded_jpeg(&page_with_image(9_000), 4)
            .expect("missing")
            .is_none());
    }
}
