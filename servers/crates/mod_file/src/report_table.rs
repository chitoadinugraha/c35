//! Tabular stock-report export: one-page-per-28-rows PDF and a minimal xlsx.

use std::io::{Cursor, Write};

use lopdf::{dictionary, Document, Object, Stream};
use zip::write::SimpleFileOptions;
use zip::{CompressionMethod, ZipWriter};

const PDF_BODY_ROWS: usize = 28;
const PDF_PAGE_W: i32 = 612;
const PDF_MARGIN_X: i32 = 36;

/// Helvetica PDF. One page per 28 body rows. Footer is `row i-j of N`, plus `truncated` when set.
pub fn report_pdf(
    title: &str,
    headers: &[String],
    rows: &[Vec<String>],
    truncated: bool,
) -> Vec<u8> {
    let mut doc = Document::with_version("1.4");
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

    let total = rows.len();
    let page_count = if total == 0 {
        1
    } else {
        total.div_ceil(PDF_BODY_ROWS)
    };
    let mut kids: Vec<Object> = Vec::with_capacity(page_count);
    for page_idx in 0..page_count {
        let start = page_idx * PDF_BODY_ROWS;
        let end = (start + PDF_BODY_ROWS).min(total);
        let slice = if start < end { &rows[start..end] } else { &[] };
        let content = Stream::new(
            dictionary! {},
            page_stream(
                title,
                headers,
                slice,
                page_idx == 0,
                start,
                total,
                truncated,
            ),
        );
        let content_id = doc.add_object(content);
        let page_id = doc.add_object(dictionary! {
            "Type" => "Page",
            "Parent" => pages_id,
            "Contents" => content_id,
            "Resources" => resources_id,
            "MediaBox" => vec![0.into(), 0.into(), PDF_PAGE_W.into(), 792.into()],
        });
        kids.push(page_id.into());
    }

    let page_count_obj = page_count as i64;
    doc.objects.insert(
        pages_id,
        Object::Dictionary(dictionary! {
            "Type" => "Pages",
            "Kids" => kids,
            "Count" => page_count_obj,
        }),
    );
    let catalog_id = doc.add_object(dictionary! {
        "Type" => "Catalog",
        "Pages" => pages_id,
    });
    doc.trailer.set("Root", catalog_id);
    let mut bytes = Vec::new();
    doc.save_to(&mut bytes).expect("save report pdf");
    bytes
}

/// Minimal OOXML workbook. Sheet name `Report`. Every cell is a shared string.
pub fn report_xlsx(headers: &[String], rows: &[Vec<String>]) -> Vec<u8> {
    let width = headers
        .len()
        .max(rows.iter().map(|r| r.len()).max().unwrap_or(0));
    let mut strings: Vec<String> = Vec::new();
    let mut sheet_rows: Vec<String> = Vec::new();
    let mut row_num = 1u32;
    if width == 0 {
        sheet_rows.push(format!(r#"<row r="{row_num}"/>"#));
    } else {
        push_sheet_row(&mut sheet_rows, &mut strings, row_num, headers, width);
        row_num += 1;
        for row in rows {
            push_sheet_row(&mut sheet_rows, &mut strings, row_num, row, width);
            row_num += 1;
        }
    }

    let sst_count = strings.len();
    let mut sst = String::new();
    sst.push_str(r#"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>"#);
    sst.push_str(&format!(
        r#"<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="{sst_count}" uniqueCount="{sst_count}">"#
    ));
    for s in &strings {
        sst.push_str("<si><t xml:space=\"preserve\">");
        sst.push_str(&xml_escape(s));
        sst.push_str("</t></si>");
    }
    sst.push_str("</sst>");

    let sheet = format!(
        r#"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>
{}
  </sheetData>
</worksheet>"#,
        sheet_rows.join("\n")
    );

    let workbook = r#"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Report" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>"#;

    let workbook_rels = r#"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
</Relationships>"#;

    let root_rels = r#"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>"#;

    let content_types = r#"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
</Types>"#;

    let cursor = Cursor::new(Vec::new());
    let mut zip = ZipWriter::new(cursor);
    let opts = SimpleFileOptions::default().compression_method(CompressionMethod::Deflated);
    let files: &[(&str, &str)] = &[
        ("[Content_Types].xml", content_types),
        ("_rels/.rels", root_rels),
        ("xl/workbook.xml", workbook),
        ("xl/_rels/workbook.xml.rels", workbook_rels),
        ("xl/worksheets/sheet1.xml", sheet.as_str()),
        ("xl/sharedStrings.xml", sst.as_str()),
    ];
    for (name, body) in files {
        zip.start_file(*name, opts).expect("xlsx part");
        zip.write_all(body.as_bytes()).expect("xlsx bytes");
    }
    zip.finish().expect("xlsx finish").into_inner()
}

fn push_sheet_row(
    sheet_rows: &mut Vec<String>,
    strings: &mut Vec<String>,
    row_num: u32,
    cells: &[String],
    width: usize,
) {
    let mut xml = format!(r#"<row r="{row_num}">"#);
    for col in 0..width {
        let value = cells.get(col).map(|s| s.as_str()).unwrap_or("");
        let idx = strings.len();
        strings.push(value.to_string());
        let cell = format!("{}{row_num}", col_name(col));
        xml.push_str(&format!(r#"<c r="{cell}" t="s"><v>{idx}</v></c>"#));
    }
    xml.push_str("</row>");
    sheet_rows.push(xml);
}

fn page_stream(
    title: &str,
    headers: &[String],
    rows: &[Vec<String>],
    show_title: bool,
    start: usize,
    total: usize,
    truncated: bool,
) -> Vec<u8> {
    let col_count = headers
        .len()
        .max(rows.iter().map(|r| r.len()).max().unwrap_or(0));
    let usable = PDF_PAGE_W - PDF_MARGIN_X * 2;
    let col_w = if col_count == 0 {
        usable
    } else {
        (usable / col_count as i32).max(24)
    };
    let max_chars = (col_w / 5).max(1) as usize;
    let mut s = String::from("BT\n");
    let mut y = 760;
    if show_title {
        draw_text(&mut s, PDF_MARGIN_X, y, 14, &pdf_escape_clip(title, 140));
        y -= 22;
    }
    if col_count > 0 && !headers.is_empty() {
        draw_cells(&mut s, y, headers, col_count, col_w, 9, max_chars);
        y -= 16;
    }
    for row in rows {
        draw_cells(&mut s, y, row, col_count, col_w, 8, max_chars);
        y -= 14;
        if y < 48 {
            break;
        }
    }
    let (i, j) = if rows.is_empty() {
        (0, 0)
    } else {
        (start + 1, start + rows.len())
    };
    let mut footer = format!("row {i}-{j} of {total}");
    if truncated {
        footer.push_str(" truncated");
    }
    draw_text(&mut s, PDF_MARGIN_X, 28, 9, &pdf_escape(&footer));
    s.push_str("ET\n");
    s.into_bytes()
}

fn draw_cells(
    s: &mut String,
    y: i32,
    cells: &[String],
    col_count: usize,
    col_w: i32,
    size: u8,
    max_chars: usize,
) {
    for i in 0..col_count {
        let raw = cells.get(i).map(|c| c.as_str()).unwrap_or("");
        if raw.is_empty() {
            continue;
        }
        let x = PDF_MARGIN_X + i as i32 * col_w;
        draw_text(s, x, y, size, &pdf_escape_clip(raw, max_chars));
    }
}

fn draw_text(s: &mut String, x: i32, y: i32, size: u8, escaped: &str) {
    if escaped.is_empty() {
        return;
    }
    s.push_str(&format!(
        "/F1 {size} Tf\n1 0 0 1 {x} {y} Tm\n({escaped}) Tj\n"
    ));
}

fn pdf_escape_clip(s: &str, max_chars: usize) -> String {
    let clipped: String = s.chars().take(max_chars.max(1)).collect();
    pdf_escape(&clipped)
}

fn pdf_escape(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for c in s.chars() {
        match c {
            '\\' => out.push_str("\\\\"),
            '(' => out.push_str("\\("),
            ')' => out.push_str("\\)"),
            '\n' | '\r' | '\t' => out.push(' '),
            c if (' '..='~').contains(&c) => out.push(c),
            _ => out.push('?'),
        }
    }
    out
}

fn col_name(index: usize) -> String {
    let mut n = index as u32 + 1;
    let mut s = String::new();
    while n > 0 {
        n -= 1;
        s.insert(0, (b'A' + (n % 26) as u8) as char);
        n /= 26;
    }
    s
}

fn xml_escape(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for c in s.chars() {
        match c {
            '&' => out.push_str("&amp;"),
            '<' => out.push_str("&lt;"),
            '>' => out.push_str("&gt;"),
            '"' => out.push_str("&quot;"),
            '\'' => out.push_str("&apos;"),
            c if c.is_control() && c != '\t' && c != '\n' && c != '\r' => {}
            c => out.push(c),
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn report_xlsx_is_a_zip() {
        let bytes = report_xlsx(
            &["Name".into(), "In".into()],
            &[vec!["Mil".into(), "2".into()]],
        );
        assert_eq!(&bytes[..2], b"PK");
    }

    #[test]
    fn report_pdf_starts_with_header() {
        let bytes = report_pdf(
            "January (in)",
            &["Name".into()],
            &[vec!["Mil".into()]],
            true,
        );
        assert!(bytes.starts_with(b"%PDF"));
        let doc = Document::load_mem(&bytes).expect("pdf");
        assert!(doc.get_pages().contains_key(&1));
        let text = doc.extract_text(&[1]).expect("text");
        assert!(text.contains("January"));
        assert!(text.contains("truncated"));
        assert!(text.contains("row 1-1 of 1"));
    }

    #[test]
    fn report_pdf_one_page_per_28_rows() {
        let rows: Vec<Vec<String>> = (0..29).map(|i| vec![format!("r{i}")]).collect();
        let bytes = report_pdf("T", &["C".into()], &rows, false);
        let doc = Document::load_mem(&bytes).expect("pdf");
        assert_eq!(doc.get_pages().len(), 2);
        let page2 = doc.extract_text(&[2]).expect("page 2");
        assert!(page2.contains("row 29-29 of 29"));
    }
}
