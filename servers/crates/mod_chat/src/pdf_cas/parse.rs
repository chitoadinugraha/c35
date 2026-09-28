use anyhow::{bail, Context, Result};
use lopdf::{Document, Object};
use std::collections::BTreeMap;

use super::types::{PdfSection, PdfStructure};

const PDF_PARSE_MAX_BYTES: usize = 32 * 1024 * 1024;
const PDF_STRUCTURE_SECTION_CAP: usize = 80;
const PDF_EXTRACT_ABSOLUTE_MAX_CHARS: usize = 32_000;

pub fn pdf_structure(bytes: &[u8]) -> Result<PdfStructure> {
    if bytes.is_empty() {
        bail!("empty PDF");
    }
    if bytes.len() > PDF_PARSE_MAX_BYTES {
        bail!("PDF too large");
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

pub fn pdf_extract_pages(bytes: &[u8], page_from: u32, page_to: u32, max_chars: usize) -> Result<String> {
    if bytes.is_empty() {
        bail!("empty PDF");
    }
    if bytes.len() > PDF_PARSE_MAX_BYTES {
        bail!("PDF too large");
    }
    let doc = Document::load_mem(bytes).context("parse PDF")?;
    let pages = doc.get_pages();
    let page_count = pages.len().max(1) as u32;
    let from = page_from.clamp(1, page_count);
    let to = page_to.clamp(from, page_count);
    let max_len = max_chars.clamp(500, PDF_EXTRACT_ABSOLUTE_MAX_CHARS);
    let mut out = String::new();
    for p in from..=to {
        let chunk = doc.extract_text(&[p]).with_context(|| format!("extract page {p}"))?;
        let chunk = chunk.lines().map(str::trim).filter(|l| !l.is_empty()).collect::<Vec<_>>().join("\n");
        if chunk.is_empty() {
            continue;
        }
        let block = format!("--- page {p} ---\n{chunk}\n");
        if out.chars().count() + block.chars().count() > max_len {
            break;
        }
        out.push_str(&block);
    }
    Ok(out.trim().to_string())
}

fn outline_sections(_doc: &Document, _pages: &BTreeMap<u32, (u32, u16)>) -> Vec<PdfSection> {
    Vec::new()
}

fn outline_page(doc: &Document, pages: &BTreeMap<u32, (u32, u16)>, obj_id: (u32, u16)) -> Option<u32> {
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

fn page_num_from_ref(doc: &Document, pages: &BTreeMap<u32, (u32, u16)>, obj: &Object) -> Option<u32> {
    let id = match obj {
        Object::Reference(r) => (r.0, r.1),
        _ => return None,
    };
    for (num, &(oid, gen)) in pages {
        if oid == id.0 && gen == id.1 {
            return Some(*num);
        }
    }
    None
}

fn heading_heuristic(doc: &Document, pages: &BTreeMap<u32, (u32, u16)>, max_pages: u32) -> Vec<PdfSection> {
    let mut out = Vec::new();
    let scan = pages.len().min(max_pages as usize) as u32;
    for p in 1..=scan {
        let Ok(text) = doc.extract_text(&[p]) else {
            continue;
        };
        for line in text.lines().map(str::trim).filter(|l| !l.is_empty()) {
            if line.len() >= 4 && line.chars().next().is_some_and(|c| c.is_ascii_digit()) {
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