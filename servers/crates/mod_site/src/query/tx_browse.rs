use std::collections::HashMap;

use c35_proto::SiteQueryRow;
use chrono::{DateTime, Utc};
use serde_json::{json, Value};
use sqlx::Row;

use super::params::{query_param_bool, query_param_i32, query_param_str, query_time_range};
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

pub struct TxBrowseReport {
    pub kind: String,
    pub title: String,
    pub headers: Vec<String>,
    pub rows: Vec<Vec<String>>,
    pub row_count: i64,
    pub truncated: bool,
    pub total_revenue: i64,
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
) -> Option<TxBrowseReport> {
    if query_id != "tx.sales_list" {
        return None;
    }
    let meta: Value = serde_json::from_str(result_json).unwrap_or(Value::Null);
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
        title: "Sales transactions".to_string(),
        headers: LIST_HEADERS.iter().map(|s| (*s).to_string()).collect(),
        rows: grid,
        row_count: json_i64(&meta, "row_count", rows.len() as i64),
        truncated: meta
            .get("truncated")
            .and_then(|v| v.as_bool())
            .unwrap_or(false),
        total_revenue: json_i64(&meta, "total_revenue", 0),
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
        let limit = query_param_i32(params, "limit", 50).clamp(1, 200) as i64;
        let fetch = (limit + 1).min(TX_FETCH_LIMIT);
        let open_only = query_param_bool(params, "open_only", false);
        let state_filter = query_param_str(params, "state", "");
        let q = query_param_str(params, "q", "");
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
