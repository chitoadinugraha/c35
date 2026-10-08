//! DOCX document index. Text comes from `word/document.xml` only.

use std::io::{Cursor, Read};

use anyhow::{bail, Context, Result};
use quick_xml::events::Event;
use quick_xml::Reader;
use zip::ZipArchive;

use crate::doc_index::{DocIndex, DocPage};
use crate::pdf::PdfSection;

const ZIP_MAX_ENTRIES: usize = 200;
const ZIP_MAX_UNCOMPRESSED: u64 = 32 * 1024 * 1024;
const UNIT_MAX_CHARS: usize = 8_000;
const TOTAL_MAX_CHARS: usize = 200_000;
const OUTLINE_TITLE_MAX: usize = 80;

pub fn docx_doc_index(bytes: &[u8]) -> Result<DocIndex> {
    let mut archive = open_capped_zip(bytes)?;
    let xml = read_named(&mut archive, "word/document.xml")?;
    let text = xml_local_text(&xml, b"t")?;
    let units = chunk_units(&text);
    Ok(index_from_units("docx", units))
}

fn open_capped_zip(bytes: &[u8]) -> Result<ZipArchive<Cursor<&[u8]>>> {
    let mut archive = ZipArchive::new(Cursor::new(bytes)).context("open zip")?;
    if archive.len() > ZIP_MAX_ENTRIES {
        bail!(
            "zip has {} entries (max {ZIP_MAX_ENTRIES})",
            archive.len()
        );
    }
    let mut total = 0u64;
    for i in 0..archive.len() {
        let file = archive
            .by_index(i)
            .with_context(|| format!("zip entry {i}"))?;
        total = total.saturating_add(file.size());
        if total > ZIP_MAX_UNCOMPRESSED {
            bail!("zip uncompressed size exceeds 32 MiB");
        }
    }
    Ok(archive)
}

fn read_named(archive: &mut ZipArchive<Cursor<&[u8]>>, want: &str) -> Result<Vec<u8>> {
    for i in 0..archive.len() {
        let name = {
            let file = archive
                .by_index(i)
                .with_context(|| format!("zip entry {i}"))?;
            zip_name(file.name())
        };
        if name != want {
            continue;
        }
        let mut file = archive
            .by_index(i)
            .with_context(|| format!("zip entry {i}"))?;
        let mut buf = Vec::new();
        file.read_to_end(&mut buf)
            .with_context(|| format!("read {want}"))?;
        return Ok(buf);
    }
    bail!("missing {want}")
}

fn zip_name(name: &str) -> String {
    name.trim_start_matches('/').replace('\\', "/")
}

fn xml_local_text(xml: &[u8], text_local: &[u8]) -> Result<String> {
    let mut reader = Reader::from_reader(xml);
    let mut buf = Vec::new();
    let mut out = String::new();
    let mut chars = 0usize;
    let mut capture = false;
    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(e)) => {
                capture = e.local_name().as_ref() == text_local;
            }
            Ok(Event::End(e)) => {
                let local = e.local_name();
                if local.as_ref() == text_local {
                    capture = false;
                }
                if local.as_ref() == b"p" {
                    push_paragraph_break(&mut out, &mut chars);
                }
            }
            Ok(Event::Empty(e)) => {
                if e.local_name().as_ref() == b"br" || e.local_name().as_ref() == b"cr" {
                    push_paragraph_break(&mut out, &mut chars);
                }
            }
            Ok(Event::Text(t)) if capture => {
                let decoded = t.unescape().context("xml text")?;
                push_capped(&mut out, &mut chars, &decoded);
            }
            Ok(Event::CData(t)) if capture => {
                let decoded = String::from_utf8_lossy(t.as_ref());
                push_capped(&mut out, &mut chars, &decoded);
            }
            Ok(Event::Eof) => break,
            Err(e) => return Err(e).context("parse xml"),
            _ => {}
        }
        buf.clear();
    }
    Ok(out)
}

fn push_paragraph_break(out: &mut String, chars: &mut usize) {
    if out.is_empty() || out.ends_with('\n') || *chars >= TOTAL_MAX_CHARS {
        return;
    }
    out.push('\n');
    *chars += 1;
}

fn push_capped(out: &mut String, chars: &mut usize, extra: &str) {
    if *chars >= TOTAL_MAX_CHARS {
        return;
    }
    let room = TOTAL_MAX_CHARS - *chars;
    for ch in extra.chars().take(room) {
        out.push(ch);
        *chars += 1;
    }
}

fn chunk_units(text: &str) -> Vec<String> {
    let mut units = Vec::new();
    let mut rest = text.trim();
    let mut total = 0usize;
    while !rest.is_empty() && total < TOTAL_MAX_CHARS {
        let room = (TOTAL_MAX_CHARS - total).min(UNIT_MAX_CHARS);
        let (chunk, next) = take_chars(rest, room);
        if chunk.is_empty() {
            break;
        }
        total += chunk.chars().count();
        rest = next.trim_start_matches('\n');
        units.push(chunk);
    }
    units
}

fn take_chars(text: &str, max_chars: usize) -> (String, &str) {
    let mut end = 0usize;
    let mut count = 0usize;
    for (i, ch) in text.char_indices() {
        if count == max_chars {
            break;
        }
        count += 1;
        end = i + ch.len_utf8();
    }
    (text[..end].to_string(), &text[end..])
}

fn index_from_units(kind: &str, units: Vec<String>) -> DocIndex {
    let outline = units
        .iter()
        .enumerate()
        .filter_map(|(i, text)| {
            first_line_title(text).map(|title| PdfSection {
                title,
                page: (i as u32) + 1,
                level: 1,
            })
        })
        .collect();
    let pages = units
        .into_iter()
        .enumerate()
        .map(|(i, text)| DocPage {
            n: (i as u32) + 1,
            text,
            needs_ocr: false,
            image_jpeg: None,
        })
        .collect::<Vec<_>>();
    DocIndex {
        kind: kind.to_string(),
        name: String::new(),
        units: pages.len() as u32,
        outline,
        pages,
    }
}

fn first_line_title(text: &str) -> Option<String> {
    let line = text.lines().map(str::trim).find(|l| !l.is_empty())?;
    let title: String = line.chars().take(OUTLINE_TITLE_MAX).collect();
    if title.is_empty() {
        None
    } else {
        Some(title)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;
    use zip::write::SimpleFileOptions;
    use zip::{CompressionMethod, ZipWriter};

    fn stored_zip(files: &[(&str, &[u8])]) -> Vec<u8> {
        let cursor = Cursor::new(Vec::new());
        let mut zip = ZipWriter::new(cursor);
        let opts = SimpleFileOptions::default().compression_method(CompressionMethod::Stored);
        for (name, body) in files {
            zip.start_file(*name, opts).unwrap();
            zip.write_all(body).unwrap();
        }
        zip.finish().unwrap().into_inner()
    }

    #[test]
    fn docx_doc_index_hello() {
        let xml = br#"<?xml version="1.0" encoding="UTF-8"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body><w:p><w:r><w:t>HelloDoc</w:t></w:r></w:p></w:body>
</w:document>"#;
        let bytes = stored_zip(&[("word/document.xml", xml)]);
        let index = docx_doc_index(&bytes).expect("index");
        assert_eq!(index.kind, "docx");
        assert_eq!(index.name, "");
        assert_eq!(index.units, 1);
        assert!(index.pages[0].text.contains("HelloDoc"));
        assert!(!index.pages[0].needs_ocr);
        assert!(index.pages[0].image_jpeg.is_none());
        assert_eq!(index.outline.len(), 1);
        assert_eq!(index.outline[0].title, "HelloDoc");
        assert_eq!(index.outline[0].page, 1);
        assert_eq!(index.outline[0].level, 1);
    }

    #[test]
    fn docx_doc_index_rejects_201_entries() {
        let mut files = Vec::new();
        let body = b"x";
        for i in 0..201 {
            files.push((format!("f{i}.txt"), body.as_slice()));
        }
        let refs: Vec<(&str, &[u8])> = files.iter().map(|(n, b)| (n.as_str(), *b)).collect();
        let bytes = stored_zip(&refs);
        assert!(docx_doc_index(&bytes).is_err());
    }
}
