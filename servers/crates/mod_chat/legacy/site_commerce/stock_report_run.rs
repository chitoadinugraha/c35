//! Run a closed stock report from SQL and attach files. No row set is returned to the model.

use anyhow::Result;
use c35_mod_data_source::{
    data_source_list_for_bot, google_sheet_config_from_row, google_sheet_replace_grid,
    SOURCE_KIND_GOOGLE_SHEET,
};
use c35_mod_file::{cas_dir_default, cas_put};
use c35_mod_site::{site_granted_iids, site_query_run, stock_report_from_query, StockReport};
use serde_json::{json, Value};

use crate::prompt::ChatRes;
use crate::site_scope::site_scope_pick;
use crate::stock_report::{stock_report_parse, StockReportFormat};
use crate::stock_report_render::{stock_report_blocks, stock_report_files};
use crate::tools::TurnCtx;

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

pub async fn stock_report_prefetch(ctx: &TurnCtx<'_>, user_text: &str) -> Result<Option<ChatRes>> {
    let Some(intent) = stock_report_parse(user_text, chrono::Utc::now()) else {
        return Ok(None);
    };
    let mentioned = ctx.mention.site_iids();
    let granted = if mentioned.is_empty() {
        site_granted_iids(ctx.pool, ctx.owner_iid).await.unwrap_or_default()
    } else {
        Vec::new()
    };
    let site_iids = match site_scope_pick(&mentioned, &granted, &[]) {
        Ok(ids) if !ids.is_empty() => ids,
        _ => {
            return Ok(Some(plain_res("No site to report on.")));
        }
    };
    if intent.query_id == "tx.stock_card" && intent.q.trim().is_empty() {
        return Ok(Some(plain_res("Which product?")));
    }
    let params = json!({
        "q": intent.q,
        "time_from_ms": intent.time_from_ms,
        "time_to_ms": intent.time_to_ms,
    });
    let res = site_query_run(
        ctx.pool,
        ctx.owner_iid,
        site_iids,
        intent.query_id,
        &params.to_string(),
    )
    .await?;
    if result_error(&res.result_json) .as_deref() == Some("product_required") {
        return Ok(Some(plain_res("Which product?")));
    }
    let Some(report) = stock_report_from_query(intent.query_id, &res.rows, &res.result_json) else {
        return Ok(None);
    };
    let built = materialize(ctx.pool, ctx.chat_id, &report, &intent.formats).await?;
    Ok(Some(built.res))
}

pub struct StockReportBuilt {
    pub res: ChatRes,
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
    let mut gsheet_note = String::new();
    if formats.contains(&StockReportFormat::Gsheet) {
        match replace_linked_sheet(pool, chat_id, report).await {
            Ok(true) => {}
            Ok(false) | Err(_) => {
                gsheet_note = "Google Sheet is not linked. The Excel file is attached.".into();
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
    Ok(StockReportBuilt {
        res: ChatRes {
            text: reply_text(report, &gsheet_note),
            blocks_json: serde_json::to_string(&blocks).unwrap_or_else(|_| "[]".into()),
            model_used: "stock_report".into(),
            ..ChatRes::default()
        },
        llm: llm_out,
    })
}

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

fn plain_res(text: &str) -> ChatRes {
    ChatRes {
        text: text.to_string(),
        blocks_json: "[]".into(),
        model_used: "stock_report".into(),
        ..ChatRes::default()
    }
}

fn result_error(result_json: &str) -> Option<String> {
    let v: Value = serde_json::from_str(result_json).ok()?;
    let err = v.get("error")?.as_str()?.trim();
    if err.is_empty() {
        None
    } else {
        Some(err.to_string())
    }
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
