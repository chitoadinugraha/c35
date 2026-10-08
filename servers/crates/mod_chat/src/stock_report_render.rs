//! Render a `StockReport` into chat blocks, PDF/xlsx bytes, and a short slide deck.

use c35_mod_site::StockReport;
use serde_json::{json, Value};

use crate::stock_report::StockReportFormat;

const PREVIEW_ROWS: usize = 40;
const SLIDE_CAP: usize = 6;
const SLIDE_CHARS: usize = 2000;
const TOP_ROWS: usize = 8;

pub struct StockReportFile {
    pub name: String,
    pub mime: String,
    pub bytes: Vec<u8>,
}

pub fn stock_report_files(
    report: &StockReport,
    formats: &[StockReportFormat],
) -> Vec<StockReportFile> {
    let ym = chrono::Utc::now().format("%Y%m");
    let mut out = Vec::new();
    for fmt in formats {
        match fmt {
            StockReportFormat::Pdf => out.push(StockReportFile {
                name: format!("{}-{ym}.pdf", report.kind),
                mime: "application/pdf".to_string(),
                bytes: c35_mod_file::report_pdf(
                    &report.title,
                    &report.headers,
                    &report.rows,
                    report.truncated,
                ),
            }),
            StockReportFormat::Xlsx => out.push(StockReportFile {
                name: format!("{}-{ym}.xlsx", report.kind),
                mime: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                    .to_string(),
                bytes: c35_mod_file::report_xlsx(&report.headers, &report.rows),
            }),
            StockReportFormat::Table | StockReportFormat::Slides | StockReportFormat::Gsheet => {}
        }
    }
    out
}

/// Summary deck only. Theme is applied on the presentation block, not inside the slide text.
pub fn stock_report_slides(report: &StockReport) -> Vec<String> {
    let mut slides = Vec::new();
    push_slide(
        &mut slides,
        format!("# {}\n\n{} rows", report.title, report.row_count),
    );
    let net = report.qty_in.saturating_sub(report.qty_out);
    push_slide(
        &mut slides,
        format!(
            "# Totals\n\nQty in: {}\nQty out: {}\nNet: {net}",
            report.qty_in, report.qty_out
        ),
    );
    push_slide(&mut slides, top_rows_slide(report));
    slides
}

/// `files` are already-uploaded `(hash, name, mime)` triples.
pub fn stock_report_blocks(
    report: &StockReport,
    files: &[(String, String, String)],
    slides: bool,
) -> Vec<Value> {
    let preview: Vec<&Vec<String>> = report.rows.iter().take(PREVIEW_ROWS).collect();
    let mut blocks = vec![json!({
        "kind": "site.stock_report",
        "body": {
            "headers": report.headers,
            "rows": preview,
            "row_count": report.row_count,
            "truncated": report.truncated,
            "qty_in": report.qty_in,
            "qty_out": report.qty_out,
            "title": report.title,
            "kind": report.kind,
        }
    })];
    for (hash, name, mime) in files {
        blocks.push(json!({
            "kind": "file",
            "body": {
                "hash": hash,
                "name": name,
                "mime": mime,
            }
        }));
    }
    if slides {
        blocks.push(json!({
            "kind": "presentation.deck",
            "body": {
                "title": report.title,
                "slides": stock_report_slides(report),
                "theme": "emerald",
                "created_at_ms": chrono::Utc::now().timestamp_millis(),
            }
        }));
    }
    blocks
}

fn top_rows_slide(report: &StockReport) -> String {
    let kind = report.kind.as_str();
    if kind == "tx.stock_list"
        || header_idx(&report.headers, "stock_qty").is_some()
            && kind != "tx.stock_card"
            && kind != "tx.stock_movement"
    {
        return ranked_slide(
            report,
            "Lowest stock",
            header_idx(&report.headers, "stock_qty"),
            false,
            true,
        );
    }
    if kind == "tx.stock_card"
        || header_idx(&report.headers, "qty_signed").is_some() && kind != "tx.stock_movement"
    {
        return ranked_slide(
            report,
            "Largest outbound",
            header_idx(&report.headers, "qty_signed"),
            true,
            false,
        );
    }
    ranked_slide(
        report,
        "Largest outbound",
        header_idx(&report.headers, "qty_out"),
        false,
        false,
    )
}

fn ranked_slide(
    report: &StockReport,
    heading: &str,
    qty_col: Option<usize>,
    negative_magnitude: bool,
    lowest: bool,
) -> String {
    let Some(qty_col) = qty_col else {
        return format!("# {heading}\n\nNo quantity column");
    };
    let mut ranked: Vec<(usize, i64)> = report
        .rows
        .iter()
        .enumerate()
        .filter_map(|(i, row)| {
            let q = parse_i64(row.get(qty_col).map(|s| s.as_str()).unwrap_or(""));
            let score = if negative_magnitude {
                if q < 0 {
                    q.saturating_neg()
                } else {
                    return None;
                }
            } else {
                q
            };
            Some((i, score))
        })
        .collect();
    if lowest {
        ranked.sort_by(|a, b| a.1.cmp(&b.1).then(a.0.cmp(&b.0)));
    } else {
        ranked.sort_by(|a, b| b.1.cmp(&a.1).then(a.0.cmp(&b.0)));
    }
    ranked.truncate(TOP_ROWS);
    let mut text = format!("# {heading}\n");
    if ranked.is_empty() {
        text.push_str("\nNo rows");
        return text;
    }
    for (i, score) in ranked {
        let row = &report.rows[i];
        let label = row_label(row, &report.headers);
        text.push_str(&format!("\n- {label} {score}"));
    }
    text
}

fn row_label(row: &[String], headers: &[String]) -> String {
    let name = cell_at(row, header_idx(headers, "name"));
    let sku = cell_at(row, header_idx(headers, "sku"));
    if name.is_empty() {
        sku.to_string()
    } else if sku.is_empty() {
        name.to_string()
    } else {
        format!("{name} ({sku})")
    }
}

fn cell_at<'a>(row: &'a [String], idx: Option<usize>) -> &'a str {
    idx.and_then(|i| row.get(i))
        .map(|s| s.as_str())
        .unwrap_or("")
}

fn header_idx(headers: &[String], name: &str) -> Option<usize> {
    headers.iter().position(|h| h == name)
}

fn parse_i64(s: &str) -> i64 {
    s.trim().parse().unwrap_or(0)
}

fn push_slide(slides: &mut Vec<String>, text: String) {
    if slides.len() >= SLIDE_CAP {
        return;
    }
    slides.push(cap_slide(text));
}

fn cap_slide(s: String) -> String {
    if s.len() < SLIDE_CHARS {
        return s;
    }
    let mut end = SLIDE_CHARS - 1;
    while end > 0 && !s.is_char_boundary(end) {
        end -= 1;
    }
    s[..end].to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_movement_report(n: usize) -> StockReport {
        let headers = vec![
            "site".into(),
            "name".into(),
            "sku".into(),
            "qty_in".into(),
            "qty_out".into(),
        ];
        let mut qty_in = 0i64;
        let mut qty_out = 0i64;
        let rows: Vec<Vec<String>> = (0..n)
            .map(|i| {
                let inn = i as i64;
                let out = (n - i) as i64;
                qty_in += inn;
                qty_out += out;
                vec![
                    "s".into(),
                    format!("item {i}"),
                    format!("sku{i}"),
                    inn.to_string(),
                    out.to_string(),
                ]
            })
            .collect();
        StockReport {
            kind: "tx.stock_movement".into(),
            title: "Stock movement".into(),
            headers,
            rows,
            row_count: n as i64,
            truncated: false,
            qty_in,
            qty_out,
        }
    }

    #[test]
    fn slides_are_summary_only() {
        let report = sample_movement_report(100);
        let slides = stock_report_slides(&report);
        assert!(slides.len() <= 6);
        assert!(slides.iter().all(|s| s.len() < 2000));
        assert!(slides.len() >= 3);
        let joined = slides.join("\n");
        assert!(!joined.contains("item 50"));
        assert!(slides[1].contains("Qty in:"));
        assert!(slides[1].contains("Qty out:"));
        assert!(slides[1].contains("Net:"));
        assert!(slides[2].contains("item 0"));
    }
}
