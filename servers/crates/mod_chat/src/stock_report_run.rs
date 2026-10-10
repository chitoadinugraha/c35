//! Run a closed stock report from SQL and attach files. No row set is returned to the model.

use anyhow::Result;
use c35_mod_data_source::{
    data_source_list_for_bot, google_sheet_config_from_row, google_sheet_replace_grid,
    SOURCE_KIND_GOOGLE_SHEET,
};
use c35_mod_file::{cas_dir_default, cas_put};
use c35_mod_site::StockReport;
use serde_json::{json, Value};

use crate::stock_report_format::StockReportFormat;
use crate::stock_report_render::{stock_report_blocks, stock_report_files};

pub fn stock_report_llm_payload(report: &StockReport, files: &[Value]) -> Value {
    json!({
        "ok": true,
        "query_id": report.kind,
        "kind": report.kind,
        "row_count": report.row_count,
        "truncated": report.truncated,
        "totals": { "qty_in": report.qty_in, "qty_out": report.qty_out },
        "files": files,
    })
}

pub struct StockReportBuilt {
    pub llm: Value,
}

pub async fn materialize(
    pool: &sqlx::PgPool,
    chat_id: i64,
    report: &StockReport,
    formats: &[StockReportFormat],
) -> Result<StockReportBuilt> {
    let mut formats = formats.to_vec();
    if !formats.contains(&StockReportFormat::Table) {
        formats.insert(0, StockReportFormat::Table);
    }
    if formats.contains(&StockReportFormat::Gsheet) {
        match replace_linked_sheet(pool, chat_id, report).await {
            Ok(true) => {}
            Ok(false) | Err(_) => {
                if !formats.contains(&StockReportFormat::Xlsx) {
                    formats.push(StockReportFormat::Xlsx);
                }
            }
        }
    }
    let files = stock_report_files(report, &formats);
    let secret = cas_secret();
    let dir = cas_dir_default();
    let mut uploaded: Vec<(String, String, String)> = Vec::new();
    let mut file_json = Vec::new();
    for file in files {
        let put = cas_put(pool, &dir, &secret, &file.bytes, &file.mime).await?;
        uploaded.push((put.hash.clone(), file.name.clone(), file.mime.clone()));
        file_json.push(json!({ "hash": put.hash, "name": file.name, "mime": file.mime }));
    }
    let slides = formats.contains(&StockReportFormat::Slides);
    let blocks = stock_report_blocks(report, &uploaded, slides);
    let llm = stock_report_llm_payload(report, &file_json);
    let mut llm_out = llm.clone();
    llm_out["blocks"] = json!(blocks);
    Ok(StockReportBuilt { llm: llm_out })
}

#[allow(dead_code)]
fn reply_text(report: &StockReport, gsheet_note: &str) -> String {
    let mut s = format!(
        "{}. {} rows. In {}, out {}.",
        report.title, report.row_count, report.qty_in, report.qty_out
    );
    if report.truncated {
        s.push_str(" Truncated at 20000 rows.");
    }
    if !gsheet_note.is_empty() {
        s.push(' ');
        s.push_str(gsheet_note);
    }
    s
}

fn cas_secret() -> String {
    ["CAS_HMAC_SECRET", "C35_JWT_SECRET", "AGENT_SECRET_KEY"]
        .into_iter()
        .find_map(|k| std::env::var(k).ok())
        .unwrap_or_default()
}

async fn replace_linked_sheet(pool: &sqlx::PgPool, chat_id: i64, report: &StockReport) -> Result<bool> {
    let bot_iid: Option<i64> =
        sqlx::query_scalar("SELECT bot_iid FROM ai.chat WHERE id = $1 AND deleted_ts IS NULL")
            .bind(chat_id)
            .fetch_optional(pool)
            .await?;
    let Some(bot_iid) = bot_iid.filter(|id| *id > 0) else {
        return Ok(false);
    };
    let rows = data_source_list_for_bot(pool, bot_iid).await?;
    let cfg = rows
        .iter()
        .filter(|r| r.source_kind == SOURCE_KIND_GOOGLE_SHEET)
        .map(google_sheet_config_from_row)
        .find_map(|r| r.ok())
        .filter(|c| c.write_allowed);
    let Some(cfg) = cfg else {
        return Ok(false);
    };
    google_sheet_replace_grid(&cfg, &report.headers, &report.rows).await?;
    Ok(true)
}

pub fn formats_from_params(params: &Value) -> Vec<StockReportFormat> {
    let mut out = vec![StockReportFormat::Table];
    let Some(arr) = params.get("formats").and_then(|v| v.as_array()) else {
        return out;
    };
    for v in arr {
        let Some(s) = v.as_str() else { continue };
        let fmt = match s {
            "pdf" => StockReportFormat::Pdf,
            "xlsx" | "excel" => StockReportFormat::Xlsx,
            "slides" => StockReportFormat::Slides,
            "gsheet" => StockReportFormat::Gsheet,
            _ => continue,
        };
        if !out.contains(&fmt) {
            out.push(fmt);
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use c35_mod_site::StockReport;

    fn sample() -> StockReport {
        StockReport {
            kind: "tx.stock_movement".into(),
            title: "Stock movement".into(),
            headers: vec!["name".into(), "qty_in".into(), "qty_out".into()],
            rows: (0..100).map(|i| vec![format!("p{i}"), "1".into(), "2".into()]).collect(),
            row_count: 100,
            truncated: false,
            qty_in: 100,
            qty_out: 200,
        }
    }

    #[test]
    fn llm_payload_has_no_rows() {
        let report = sample();
        let v = stock_report_llm_payload(&report, &[]);
        assert!(v.get("rows").is_none());
        assert_eq!(v["row_count"], 100);
        assert!(v.to_string().len() < 2000);
    }
}
