use c35_mod_site::{TxBrowseDisplayRow, TxBrowseReport, TX_PREVIEW_ROWS};
use serde_json::{json, Value};

const LLM_PREVIEW_ROWS: usize = 5;

pub fn tx_browse_blocks(report: &TxBrowseReport) -> Vec<Value> {
    let preview: Vec<&TxBrowseDisplayRow> = report
        .display
        .iter()
        .take(TX_PREVIEW_ROWS)
        .collect();
    let transactions: Vec<Value> = preview
        .iter()
        .map(|row| {
            let mut o = json!({
                "tx_id": row.tx_id,
                "time": row.time,
                "total": row.total,
                "label": row.label,
            });
            if let Some(s) = &row.status {
                o["status"] = json!(s);
            }
            if let Some(u) = row.unpaid {
                o["unpaid"] = json!(u);
            }
            if let Some(site) = &row.site_name {
                o["site_name"] = json!(site);
            }
            o
        })
        .collect();
    vec![json!({
        "kind": "site.tx_list",
        "body": {
            "title": report.title,
            "range_key": report.range_key,
            "range_label": report.range_label,
            "site_name": report.primary_site_name,
            "single_site": report.single_site,
            "show_site_column": report.show_site_column,
            "open_only": report.open_only,
            "glance": {
                "tx_count": report.row_count,
                "total_revenue": report.total_revenue,
            },
            "row_count": report.row_count,
            "total_revenue": report.total_revenue,
            "truncated": report.truncated,
            "transactions": transactions,
        }
    })]
}

pub fn tx_browse_llm_payload(report: &TxBrowseReport, files: &[Value]) -> Value {
    let preview_rows: Vec<Value> = report
        .display
        .iter()
        .take(LLM_PREVIEW_ROWS)
        .map(|row| {
            json!({
                "time": row.time,
                "total": row.total,
                "label": row.label,
                "status": row.status,
            })
        })
        .collect();
    json!({
        "ok": true,
        "query_id": report.kind,
        "title": report.title,
        "range_key": report.range_key,
        "range_label": report.range_label,
        "site_name": report.primary_site_name,
        "row_count": report.row_count,
        "truncated": report.truncated,
        "total_revenue": report.total_revenue,
        "stats": {
            "avg_ticket": report.stats.avg_ticket,
            "max_total": report.stats.max_total,
            "min_total": report.stats.min_total,
        },
        "preview": preview_rows,
        "files": files,
    })
}

/// Export grid headers (human-oriented) for pdf/xlsx.
pub fn tx_browse_export_headers(locale: &str) -> Vec<String> {
    let id = locale.trim().to_ascii_lowercase().starts_with("id");
    if id {
        vec![
            "Toko".into(),
            "Waktu".into(),
            "Total".into(),
            "Dibayar".into(),
            "Status".into(),
            "Catatan".into(),
            "Kasir".into(),
            "Pelanggan".into(),
        ]
    } else {
        vec![
            "Site".into(),
            "Time".into(),
            "Total".into(),
            "Paid".into(),
            "Status".into(),
            "Note".into(),
            "Cashier".into(),
            "Customer".into(),
        ]
    }
}

pub fn tx_browse_export_rows(report: &TxBrowseReport, locale: &str) -> Vec<Vec<String>> {
    let include_date = !matches!(report.range_key.as_str(), "today" | "yesterday");
    report.rows.iter().map(|grid| {
        let time_raw = grid.get(2).cloned().unwrap_or_default();
        let time = format_tx_time_cell(&time_raw, locale, include_date);
        vec![
            grid.first().cloned().unwrap_or_default(),
            time,
            grid.get(3).cloned().unwrap_or_default(),
            grid.get(4).cloned().unwrap_or_default(),
            grid.get(5).cloned().unwrap_or_default(),
            grid.get(7).cloned().unwrap_or_default(),
            grid.get(8).cloned().unwrap_or_default(),
            grid.get(9).cloned().unwrap_or_default(),
        ]
    }).collect()
}

fn format_tx_time_cell(time_ts: &str, locale: &str, include_date: bool) -> String {
    use chrono::{DateTime, Datelike, Utc};
    let off = if locale.trim().to_ascii_lowercase().starts_with("id") {
        7
    } else {
        0
    };
    let utc = DateTime::parse_from_rfc3339(time_ts)
        .map(|dt| dt.with_timezone(&Utc))
        .ok()
        .or_else(|| time_ts.parse::<DateTime<Utc>>().ok());
    let Some(utc) = utc else {
        return time_ts.chars().take(16).collect();
    };
    let local = utc + chrono::Duration::hours(off as i64);
    if include_date {
        format!(
            "{:02}/{:02} {}",
            local.day(),
            local.month(),
            local.format("%H:%M")
        )
    } else {
        local.format("%H:%M").to_string()
    }
}
