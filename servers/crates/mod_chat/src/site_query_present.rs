use c35_proto::SiteQueryRow;
use c35_time_range::range_key_normalize;
use serde_json::{json, Value};

fn summary_range_label(range_key: &str, locale: &str) -> String {
    let id = locale.to_lowercase().starts_with("id");
    match range_key {
        "today" if id => "Hari ini".into(),
        "today" => "Today".into(),
        "yesterday" if id => "Kemarin".into(),
        "yesterday" => "Yesterday".into(),
        "this_week" if id => "Minggu ini".into(),
        "this_week" => "This week".into(),
        "this_month" if id => "Bulan ini".into(),
        "this_month" => "This month".into(),
        other => other.replace('_', " "),
    }
}

fn cell_i64(cells: &std::collections::HashMap<String, String>, key: &str) -> i64 {
    cells
        .get(key)
        .and_then(|s| s.trim().parse().ok())
        .unwrap_or(0)
}

pub fn site_query_summary_blocks(
    query_id: &str,
    rows: &[SiteQueryRow],
    params: &Value,
    locale: &str,
) -> Vec<Value> {
    if rows.is_empty() {
        return vec![];
    }
    let range_raw = params
        .get("range")
        .and_then(|v| v.as_str())
        .unwrap_or("today");
    let range_key = range_key_normalize(range_raw);
    let range_label = summary_range_label(&range_key, locale);
    let id = locale.to_lowercase().starts_with("id");
    let title = if query_id == "tx.profit_summary" {
        if id {
            "Ringkasan untung"
        } else {
            "Profit summary"
        }
    } else if id {
        "Ringkasan penjualan"
    } else {
        "Sales summary"
    };
    let sites: Vec<Value> = rows
        .iter()
        .map(|r| {
            let revenue = cell_i64(&r.cells, "revenue");
            let tx_count = cell_i64(&r.cells, "tx_count");
            let profit = cell_i64(&r.cells, "profit");
            let mut metrics = vec![
                json!({ "key": "revenue", "label": if id { "Omzet" } else { "Revenue" }, "value": revenue }),
                json!({ "key": "tx_count", "label": if id { "Transaksi" } else { "Transactions" }, "value": tx_count }),
            ];
            if query_id == "tx.profit_summary" {
                metrics.push(json!({
                    "key": "profit",
                    "label": if id { "Untung" } else { "Profit" },
                    "value": profit,
                }));
            }
            json!({
                "site_iid": r.site_iid,
                "site_name": r.site_name,
                "metrics": metrics,
            })
        })
        .collect();
    vec![json!({
        "kind": "site.report_summary",
        "body": {
            "title": title,
            "query_id": query_id,
            "range_key": range_key,
            "range_label": range_label,
            "sites": sites,
            "single_site": rows.len() == 1,
        }
    })]
}

pub fn site_query_llm_compact(query_id: &str, rows: &[SiteQueryRow], result_json: &str) -> Value {
    let sites: Vec<Value> = rows
        .iter()
        .map(|r| {
            json!({
                "site_iid": r.site_iid,
                "site_name": r.site_name,
                "cells": r.cells,
            })
        })
        .collect();
    let meta = serde_json::from_str::<Value>(result_json).unwrap_or(json!({}));
    json!({
        "query_id": query_id,
        "sites": sites,
        "meta": meta,
    })
}
