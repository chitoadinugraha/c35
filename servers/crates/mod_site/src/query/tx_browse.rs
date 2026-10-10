use std::collections::HashMap;

use c35_proto::SiteQueryRow;
use chrono::{DateTime, Datelike, Utc};
use serde_json::{json, Value};
use sqlx::Row;

use super::params::{
    query_param_bool, query_param_i32, query_param_i64, query_param_str, query_time_range,
};
use super::{query_register, site_query_rows_with_names, QueryResult};

pub const TX_PREVIEW_ROWS: usize = 40;
pub const TX_EXPORT_CAP: i64 = 20_000;
const TX_FETCH_LIMIT: i64 = TX_EXPORT_CAP + 1;

const LIST_HEADERS: &[&str] = &[
    "site",
    "tx_id",
    "time_ts",
    "total",
    "total_paid",
    "state",
    "ty",
    "desc",
    "cashier_name",
    "subject_name",
];

#[derive(Debug, Clone)]
pub struct TxBrowseDisplayRow {
    pub tx_id: String,
    pub time: String,
    pub total: i64,
    pub label: String,
    pub status: Option<String>,
    pub site_name: Option<String>,
    pub unpaid: Option<i64>,
}

#[derive(Debug, Clone, Default)]
pub struct TxBrowseStats {
    pub avg_ticket: i64,
    pub max_total: i64,
    pub min_total: i64,
}

pub struct TxBrowseReport {
    pub kind: String,
    pub title: String,
    pub headers: Vec<String>,
    pub rows: Vec<Vec<String>>,
    pub row_count: i64,
    pub truncated: bool,
    pub total_revenue: i64,
    pub range_key: String,
    pub range_label: String,
    pub single_site: bool,
    pub primary_site_name: String,
    pub show_site_column: bool,
    pub open_only: bool,
    pub display: Vec<TxBrowseDisplayRow>,
    pub stats: TxBrowseStats,
}

fn locale_id(locale: &str) -> bool {
    locale.trim().to_ascii_lowercase().starts_with("id")
}

fn offset_hours(locale: &str) -> i32 {
    if locale_id(locale) {
        7
    } else {
        0
    }
}

fn format_tx_time(time_ts: &str, locale: &str, include_date: bool) -> String {
    let utc = DateTime::parse_from_rfc3339(time_ts)
        .map(|dt| dt.with_timezone(&Utc))
        .ok()
        .or_else(|| time_ts.parse::<DateTime<Utc>>().ok());
    let Some(utc) = utc else {
        return time_ts.chars().take(16).collect();
    };
    let local = utc + chrono::Duration::hours(offset_hours(locale) as i64);
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

fn range_label(range_key: &str, locale: &str) -> String {
    let id = locale_id(locale);
    match range_key {
        "yesterday" => {
            if id {
                "Kemarin".into()
            } else {
                "Yesterday".into()
            }
        }
        "this_week" => {
            if id {
                "Minggu ini".into()
            } else {
                "This week".into()
            }
        }
        "this_month" => {
            if id {
                "Bulan ini".into()
            } else {
                "This month".into()
            }
        }
        _ => {
            if id {
                "Hari ini".into()
            } else {
                "Today".into()
            }
        }
    }
}

fn state_label(state: &str, locale: &str) -> Option<String> {
    if state == "ok" {
        return None;
    }
    let id = locale_id(locale);
    Some(match state {
        "cancelled" => {
            if id {
                "Batal"
            } else {
                "Cancelled"
            }
        }
        "pending" | "waiting_payment" => {
            if id {
                "Belum lunas"
            } else {
                "Unpaid"
            }
        }
        "draft" => {
            if id {
                "Draft"
            } else {
                "Draft"
            }
        }
        other => other,
    }
    .to_string())
}

fn row_label(desc: &str, subject: &str, locale: &str) -> String {
    if !desc.trim().is_empty() {
        return desc.trim().to_string();
    }
    if !subject.trim().is_empty() {
        return subject.trim().to_string();
    }
    if locale_id(locale) {
        "Penjualan".into()
    } else {
        "Sale".into()
    }
}

fn time_includes_date(range_key: &str) -> bool {
    !matches!(range_key, "today" | "yesterday")
}

pub fn tx_browse_title(site_name: &str, range_label: &str, locale: &str) -> String {
    if locale_id(locale) {
        if site_name.trim().is_empty() {
            format!("Transaksi · {range_label}")
        } else {
            format!("Transaksi · {} · {}", site_name.trim(), range_label)
        }
    } else if site_name.trim().is_empty() {
        format!("Transactions · {range_label}")
    } else {
        format!(
            "Transactions · {} · {}",
            site_name.trim(),
            range_label
        )
    }
}

pub fn tx_browse_query_id(id: &str) -> bool {
    id == "tx.sales_list"
}

pub fn tx_browse_preview(rows: &[Vec<String>], cap: usize) -> &[Vec<String>] {
    let n = cap.min(rows.len());
    &rows[..n]
}

pub fn tx_browse_from_query(
    query_id: &str,
    rows: &[SiteQueryRow],
    result_json: &str,
    locale: &str,
) -> Option<TxBrowseReport> {
    if query_id != "tx.sales_list" {
        return None;
    }
    let meta: Value = serde_json::from_str(result_json).unwrap_or(Value::Null);
    let range_key = meta
        .get("range")
        .and_then(|v| v.as_str())
        .unwrap_or("today")
        .to_string();
    let open_only = meta
        .get("open_only")
        .and_then(|v| v.as_bool())
        .unwrap_or(false);
    let range_label = range_label(&range_key, locale);
    let include_date = time_includes_date(&range_key);
    let site_names: Vec<String> = rows
        .iter()
        .map(|r| r.site_name.clone())
        .filter(|s| !s.trim().is_empty())
        .collect();
    let unique_sites: std::collections::HashSet<_> = site_names.iter().cloned().collect();
    let single_site = unique_sites.len() <= 1;
    let primary_site_name = site_names.first().cloned().unwrap_or_default();
    let show_site_column = !single_site;

    let mut totals: Vec<i64> = Vec::new();
    let mut display = Vec::new();
    for row in rows {
        let time_ts = row.cells.get("time_ts").cloned().unwrap_or_default();
        let total = row
            .cells
            .get("total")
            .and_then(|s| s.parse::<i64>().ok())
            .unwrap_or(0);
        let total_paid = row
            .cells
            .get("total_paid")
            .and_then(|s| s.parse::<i64>().ok())
            .unwrap_or(0);
        let state = row.cells.get("state").cloned().unwrap_or_default();
        let desc = row.cells.get("desc").cloned().unwrap_or_default();
        let subject = row.cells.get("subject_name").cloned().unwrap_or_default();
        totals.push(total);
        let unpaid = if open_only || total_paid < total {
            Some(total - total_paid)
        } else {
            None
        };
        display.push(TxBrowseDisplayRow {
            tx_id: row.cells.get("tx_id").cloned().unwrap_or_default(),
            time: format_tx_time(&time_ts, locale, include_date),
            total,
            label: row_label(&desc, &subject, locale),
            status: state_label(&state, locale),
            site_name: if show_site_column {
                Some(row.site_name.clone())
            } else {
                None
            },
            unpaid,
        });
    }
    let stats = if totals.is_empty() {
        TxBrowseStats::default()
    } else {
        let sum = totals.iter().sum::<i64>();
        let n = totals.len() as i64;
        TxBrowseStats {
            avg_ticket: sum / n.max(1),
            max_total: *totals.iter().max().unwrap_or(&0),
            min_total: *totals.iter().min().unwrap_or(&0),
        }
    };

    let grid = rows
        .iter()
        .map(|row| {
            LIST_HEADERS
                .iter()
                .map(|key| {
                    if *key == "site" {
                        row.site_name.clone()
                    } else {
                        row.cells.get(*key).cloned().unwrap_or_default()
                    }
                })
                .collect()
        })
        .collect();
    Some(TxBrowseReport {
        kind: query_id.to_string(),
        title: tx_browse_title(&primary_site_name, &range_label, locale),
        headers: LIST_HEADERS.iter().map(|s| (*s).to_string()).collect(),
        rows: grid,
        row_count: json_i64(&meta, "row_count", rows.len() as i64),
        truncated: meta
            .get("truncated")
            .and_then(|v| v.as_bool())
            .unwrap_or(false),
        total_revenue: json_i64(&meta, "total_revenue", 0),
        range_key,
        range_label,
        single_site,
        primary_site_name,
        show_site_column,
        open_only,
        display,
        stats,
    })
}

fn json_i64(v: &Value, key: &str, default: i64) -> i64 {
    v.get(key)
        .and_then(|x| x.as_i64().or_else(|| x.as_str()?.parse().ok()))
        .unwrap_or(default)
}

query_register! {
    struct: SalesListQuery,
    id: "tx.sales_list",
    label: "Sales transaction list",
    run: |pool, _caller_iid, site_iids, params| {
        if site_iids.is_empty() {
            return Ok(QueryResult {
                rows: vec![],
                result_json: "{}".into(),
            });
        }
        let (time_from, time_to) = query_time_range(params)?;
        let range = query_param_str(params, "range", "today");
        let limit = query_param_i32(params, "limit", 50).clamp(1, 200) as i64;
        let fetch = (limit + 1).min(TX_FETCH_LIMIT);
        let open_only = query_param_bool(params, "open_only", false);
        let state_filter = query_param_str(params, "state", "");
        let q = query_param_str(params, "q", "");
        let min_total = query_param_i64(params, "min_total", 0);
        let max_total = query_param_i64(params, "max_total", 0);
        let mut sql = String::from(
            r#"
            SELECT site_iid, tx_id, time_ts, total, total_paid, state, ty,
                   COALESCE("desc", '') AS desc,
                   COALESCE(cashier_name, '') AS cashier_name,
                   COALESCE(subject_name, '') AS subject_name
            FROM site.tx
            WHERE site_iid = ANY($1)
              AND deleted_ts IS NULL
              AND is_archived = false
            "#,
        );
        let mut bind = 2i32;
        if open_only {
            sql.push_str(
                " AND ty = 'sale' AND state IN ('ok', 'pending', 'waiting_payment') AND total_unpaid > 0",
            );
        } else if !state_filter.is_empty() {
            sql.push_str(&format!(" AND state = ${}", bind));
            bind += 1;
        } else {
            sql.push_str(" AND state = 'ok' AND ty IN ('sale', 'return_sale')");
        }
        if time_from.is_some() {
            sql.push_str(&format!(" AND time_ts >= ${}", bind));
            bind += 1;
        }
        if time_to.is_some() {
            sql.push_str(&format!(" AND time_ts <= ${}", bind));
            bind += 1;
        }
        if !q.is_empty() {
            sql.push_str(&format!(" AND \"desc\" ILIKE ${}", bind));
            bind += 1;
        }
        if min_total > 0 {
            sql.push_str(&format!(" AND total >= ${}", bind));
            bind += 1;
        }
        if max_total > 0 {
            sql.push_str(&format!(" AND total <= ${}", bind));
            bind += 1;
        }
        sql.push_str(&format!(" ORDER BY time_ts DESC LIMIT ${}", bind));

        let mut query = sqlx::query(&sql).bind(site_iids);
        if !state_filter.is_empty() {
            query = query.bind(state_filter);
        }
        if let Some(t) = time_from {
            query = query.bind(t);
        }
        if let Some(t) = time_to {
            query = query.bind(t);
        }
        if !q.is_empty() {
            query = query.bind(format!("%{}%", q));
        }
        if min_total > 0 {
            query = query.bind(min_total);
        }
        if max_total > 0 {
            query = query.bind(max_total);
        }
        query = query.bind(fetch);

        let fetched = query.fetch_all(pool).await?;
        let truncated = fetched.len() as i64 > limit;
        let slice = if truncated {
            &fetched[..limit as usize]
        } else {
            &fetched[..]
        };
        let mut total_revenue: i64 = 0;
        let mut out: Vec<SiteQueryRow> = slice
            .iter()
            .map(|r| {
                let site_iid: i64 = r.get("site_iid");
                let tx_id: i64 = r.get("tx_id");
                let time_ts: DateTime<Utc> = r.get("time_ts");
                let total: i64 = r.get("total");
                let total_paid: i64 = r.get("total_paid");
                let state: String = r.get("state");
                let ty: String = r.get("ty");
                let desc: String = r.get("desc");
                let cashier_name: String = r.get("cashier_name");
                let subject_name: String = r.get("subject_name");
                if ty == "sale" {
                    total_revenue += total;
                } else if ty == "return_sale" {
                    total_revenue -= total;
                }
                let mut cells = HashMap::new();
                cells.insert("tx_id".into(), tx_id.to_string());
                cells.insert("time_ts".into(), time_ts.to_rfc3339());
                cells.insert("total".into(), total.to_string());
                cells.insert("total_paid".into(), total_paid.to_string());
                cells.insert("state".into(), state);
                cells.insert("ty".into(), ty);
                cells.insert("desc".into(), desc);
                cells.insert("cashier_name".into(), cashier_name);
                cells.insert("subject_name".into(), subject_name);
                SiteQueryRow {
                    site_iid,
                    site_name: String::new(),
                    cells,
                }
            })
            .collect();
        out = site_query_rows_with_names(pool, site_iids, out).await?;
        let row_count = out.len() as i64;
        Ok(QueryResult {
            rows: out,
            result_json: json!({
                "query_id": "tx.sales_list",
                "row_count": row_count,
                "truncated": truncated,
                "total_revenue": total_revenue,
                "range": range,
                "open_only": open_only,
                "time_from_ms": time_from.map(|t| t.timestamp_millis()).unwrap_or(0),
                "time_to_ms": time_to.map(|t| t.timestamp_millis()).unwrap_or(0),
            })
            .to_string(),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tx_browse_query_id_closed() {
        assert!(tx_browse_query_id("tx.sales_list"));
        assert!(!tx_browse_query_id("tx.sales_summary"));
    }

    #[test]
    fn tx_browse_preview_capped() {
        let rows = (0..50).map(|i| vec![i.to_string()]).collect::<Vec<_>>();
        assert_eq!(tx_browse_preview(&rows, 40).len(), 40);
    }
}
