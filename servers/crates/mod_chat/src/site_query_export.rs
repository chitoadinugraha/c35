use anyhow::Result;
use c35_mod_file::cas_put;
use c35_mod_site::TxBrowseReport;
use serde_json::{json, Value};

use crate::stock_report_render::StockReportFile;
use crate::tools::ToolContext;
use crate::tx_browse_render::{tx_browse_export_headers, tx_browse_export_rows};

pub async fn tx_browse_export_files(
    ctx: &ToolContext,
    report: &TxBrowseReport,
    want_pdf: bool,
    want_xlsx: bool,
) -> Result<Vec<Value>> {
    if report.rows.is_empty() {
        return Ok(vec![]);
    }
    let locale = ctx.locale.as_str();
    let headers = tx_browse_export_headers(locale);
    let rows = tx_browse_export_rows(report, locale);
    let ym = chrono::Utc::now().format("%Y%m");
    let secret = cas_secret();
    let dir = c35_mod_file::cas_dir_default();
    let mut file_json = Vec::new();
    if want_pdf {
        let file = StockReportFile {
            name: format!("tx-sales-{ym}.pdf"),
            mime: "application/pdf".to_string(),
            bytes: c35_mod_file::report_pdf(&report.title, &headers, &rows, report.truncated),
        };
        let put = cas_put(&ctx.pool, &dir, &secret, &file.bytes, &file.mime).await?;
        file_json.push(json!({ "hash": put.hash, "name": file.name, "mime": file.mime }));
    }
    if want_xlsx {
        let file = StockReportFile {
            name: format!("tx-sales-{ym}.xlsx"),
            mime: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".to_string(),
            bytes: c35_mod_file::report_xlsx(&headers, &rows),
        };
        let put = cas_put(&ctx.pool, &dir, &secret, &file.bytes, &file.mime).await?;
        file_json.push(json!({ "hash": put.hash, "name": file.name, "mime": file.mime }));
    }
    Ok(file_json)
}

fn cas_secret() -> String {
    ["CAS_HMAC_SECRET", "C35_JWT_SECRET", "AGENT_SECRET_KEY"]
        .into_iter()
        .find_map(|k| std::env::var(k).ok())
        .unwrap_or_default()
}

pub fn export_formats_from_params(params: &Value) -> (bool, bool) {
    let lower = params.to_string().to_ascii_lowercase();
    let pdf = lower.contains("pdf");
    let xlsx = lower.contains("xlsx") || lower.contains("excel") || lower.contains("spreadsheet");
    (pdf, xlsx)
}
