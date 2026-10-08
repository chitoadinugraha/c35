//! PPTX document index. One unit per `ppt/slides/slideN.xml`.

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

pub fn pptx_doc_index(bytes: &[u8]) -> Result<DocIndex> {
    let mut archive = open_capped_zip(bytes)?;
    let mut slides = Vec::new();
    for i in 0..archive.len() {
        let name = {
            let file = archive
                .by_index(i)
                .with_context(|| format!("zip entry {i}"))?;
            zip_name(file.name())
        };
        if let Some(n) = slide_number(&name) {
            slides.push((n, i));
        }
    }
    slides.sort_by_key(|(n, _)| *n);

    let mut total = 0usize;
    let mut units = Vec::with_capacity(slides.len());
    for (_n, idx) in slides {
        let xml = read_index(&mut archive, idx)?;
        let text = xml_local_text(&xml, b"t")?;
        units.push(take_slide_text(&text, &mut total));
    }
    Ok(index_from_units("pptx", units))
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

fn read_index(archive: &mut ZipArchive<Cursor<&[u8]>>, idx: usize) -> Result<Vec<u8>> {
    let mut file = archive
        .by_index(idx)
        .with_context(|| format!("zip entry {idx}"))?;
    let mut buf = Vec::new();
    file.read_to_end(&mut buf)
        .with_context(|| format!("read zip entry {idx}"))?;
    Ok(buf)
}

fn zip_name(name: &str) -> String {
    name.trim_start_matches('/').replace('\\', "/")
}

fn slide_number(name: &str) -> Option<u32> {
    let rest = name.strip_prefix("ppt/slides/slide")?;
    let num = rest.strip_suffix(".xml")?;
    if num.is_empty() || !num.bytes().all(|b| b.is_ascii_digit()) {
        return None;
    }
    num.parse().ok()
}

fn xml_local_text(xml: &[u8], text_local: &[u8]) -> Result<String> {
    let mut reader = Reader::from_reader(xml);
    let mut buf = Vec::new();
    let mut out = String::new();
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
                if local.as_ref() == b"p" && !out.is_empty() && !out.ends_with('\n') {
                    out.push('\n');
                }
            }
            Ok(Event::Text(t)) if capture => {
                let decoded = t.unescape().context("xml text")?;
                out.push_str(&decoded);
            }
            Ok(Event::CData(t)) if capture => {
                out.push_str(&String::from_utf8_lossy(t.as_ref()));
            }
            Ok(Event::Eof) => break,
            Err(e) => return Err(e).context("parse xml"),
            _ => {}
        }
        buf.clear();
    }
    Ok(out)
}

fn take_slide_text(text: &str, total: &mut usize) -> String {
    if *total >= TOTAL_MAX_CHARS {
        return String::new();
    }
    let room = (TOTAL_MAX_CHARS - *total).min(UNIT_MAX_CHARS);
    let out: String = text.trim().chars().take(room).collect();
    *total += out.chars().count();
    out
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

    fn slide_xml(text: &str) -> Vec<u8> {
        format!(
            r#"<?xml version="1.0" encoding="UTF-8"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
  <p:cSld><p:spTree><p:sp><p:txBody><a:p><a:r><a:t>{text}</a:t></a:r></a:p></p:txBody></p:sp></p:spTree></p:cSld>
</p:sld>"#
        )
        .into_bytes()
    }

    #[test]
    fn pptx_doc_index_alpha_beta() {
        let slide2 = slide_xml("Beta");
        let slide1 = slide_xml("Alpha");
        let notes = slide_xml("Notes");
        let master = slide_xml("Master");
        let bytes = stored_zip(&[
            ("ppt/slides/slide2.xml", slide2.as_slice()),
            ("ppt/notesSlides/notesSlide1.xml", notes.as_slice()),
            ("ppt/slides/slide1.xml", slide1.as_slice()),
            ("ppt/slideMasters/slideMaster1.xml", master.as_slice()),
        ]);
        let index = pptx_doc_index(&bytes).expect("index");
        assert_eq!(index.kind, "pptx");
        assert_eq!(index.name, "");
        assert_eq!(index.units, 2);
        assert_eq!(index.pages.len(), 2);
        assert!(index.pages[0].text.contains("Alpha"));
        assert!(index.pages[1].text.contains("Beta"));
        assert!(!index.pages[0].needs_ocr);
        assert!(!index.pages[1].needs_ocr);
        assert!(index.pages[0].image_jpeg.is_none());
        assert_eq!(index.outline[0].title, "Alpha");
        assert_eq!(index.outline[0].page, 1);
        assert_eq!(index.outline[0].level, 1);
        assert_eq!(index.outline[1].title, "Beta");
        assert_eq!(index.outline[1].page, 2);
    }

    #[test]
    fn pptx_doc_index_rejects_201_entries() {
        let mut files = Vec::new();
        let body = b"x";
        for i in 0..201 {
            files.push((format!("f{i}.txt"), body.as_slice()));
        }
        let refs: Vec<(&str, &[u8])> = files.iter().map(|(n, b)| (n.as_str(), *b)).collect();
        let bytes = stored_zip(&refs);
        assert!(pptx_doc_index(&bytes).is_err());
    }
}
