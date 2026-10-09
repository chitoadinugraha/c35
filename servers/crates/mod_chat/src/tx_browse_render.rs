use c35_mod_site::{tx_browse_preview, TxBrowseReport, TX_PREVIEW_ROWS};
use serde_json::{json, Value};

pub fn tx_browse_blocks(report: &TxBrowseReport) -> Vec<Value> {
    let preview: Vec<&Vec<String>> = tx_browse_preview(&report.rows, TX_PREVIEW_ROWS)
        .iter()
        .collect();
    vec![json!({
        "kind": "site.tx_list",
        "body": {
            "headers": report.headers,
            "rows": preview,
            "row_count": report.row_count,
            "truncated": report.truncated,
            "total_revenue": report.total_revenue,
            "title": report.title,
            "kind": report.kind,
        }
    })]
}

pub fn tx_browse_llm_payload(report: &TxBrowseReport) -> Value {
    let preview_rows: Vec<Vec<String>> = report.rows.iter().take(5).cloned().collect();
    json!({
        "ok": true,
        "query_id": report.kind,
        "row_count": report.row_count,
        "truncated": report.truncated,
        "total_revenue": report.total_revenue,
        "preview": preview_rows,
    })
}