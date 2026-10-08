use std::collections::HashMap;

use c35_proto::SiteQueryRow;
use chrono::{DateTime, Utc};
use serde_json::{json, Value};
use sqlx::Row;

use super::params::{query_param_i64, query_param_str, query_time_range};
use super::{query_register, site_query_rows_with_names, QueryResult};

pub const STOCK_PREVIEW_ROWS: usize = 40;
pub const STOCK_EXPORT_CAP: i64 = 20_000;

const STOCK_FETCH_LIMIT: i64 = STOCK_EXPORT_CAP + 1;

const LIST_HEADERS: &[&str] = &["site", "name", "sku", "stock_qty"];
const CARD_HEADERS: &[&str] = &[
    "site",
    "time_ts",
    "ty",
    "tx_id",
    "name",
    "sku",
    "direction",
    "qty_signed",
    "note",
];
const MOVE_HEADERS: &[&str] = &["site", "name", "sku", "qty_in", "qty_out"];

pub struct StockReport {
    pub kind: String,
    pub title: String,
    pub headers: Vec<String>,
    pub rows: Vec<Vec<String>>,
    pub row_count: i64,
    pub truncated: bool,
    pub qty_in: i64,
    pub qty_out: i64,
}

pub fn stock_report_query_id(id: &str) -> bool {
    matches!(id, "tx.stock_list" | "tx.stock_card" | "tx.stock_movement")
}

pub fn stock_report_preview(rows: &[Vec<String>], cap: usize) -> &[Vec<String>] {
    let n = cap.min(rows.len());
    &rows[..n]
}

pub fn stock_report_from_query(
    query_id: &str,
    rows: &[SiteQueryRow],
    result_json: &str,
) -> Option<StockReport> {
    if !stock_report_query_id(query_id) {
        return None;
    }
    let meta: Value = serde_json::from_str(result_json).unwrap_or(Value::Null);
    let headers = match query_id {
        "tx.stock_list" => LIST_HEADERS,
        "tx.stock_card" => CARD_HEADERS,
        "tx.stock_movement" => MOVE_HEADERS,
        _ => return None,
    };
    let grid = rows
        .iter()
        .map(|row| {
            headers
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
    Some(StockReport {
        kind: query_id.to_string(),
        title: stock_title(query_id).to_string(),
        headers: headers.iter().map(|s| (*s).to_string()).collect(),
        rows: grid,
        row_count: json_i64(&meta, "row_count", rows.len() as i64),
        truncated: meta
            .get("truncated")
            .and_then(|v| v.as_bool())
            .unwrap_or(false),
        qty_in: json_i64(&meta, "qty_in", 0),
        qty_out: json_i64(&meta, "qty_out", 0),
    })
}

fn stock_title(query_id: &str) -> &'static str {
    match query_id {
        "tx.stock_list" => "Stock list",
        "tx.stock_card" => "Stock card",
        "tx.stock_movement" => "Stock movement",
        _ => "Stock report",
    }
}

fn json_i64(meta: &Value, key: &str, default: i64) -> i64 {
    meta.get(key).and_then(|v| v.as_i64()).unwrap_or(default)
}

fn stock_meta(
    query_id: &str,
    row_count: i64,
    truncated: bool,
    qty_in: i64,
    qty_out: i64,
) -> String {
    json!({
        "query_id": query_id,
        "row_count": row_count,
        "truncated": truncated,
        "qty_in": qty_in,
        "qty_out": qty_out,
    })
    .to_string()
}

fn trim_export<T>(mut rows: Vec<T>) -> (Vec<T>, bool) {
    let truncated = rows.len() as i64 > STOCK_EXPORT_CAP;
    if truncated {
        rows.truncate(STOCK_EXPORT_CAP as usize);
    }
    (rows, truncated)
}

fn empty_sites() -> QueryResult {
    QueryResult {
        rows: vec![],
        result_json: "{}".into(),
    }
}

fn signed_totals(qty_signed: i32, qty_in: &mut i64, qty_out: &mut i64) {
    let q = i64::from(qty_signed);
    if q > 0 {
        *qty_in += q;
    } else if q < 0 {
        *qty_out += -q;
    }
}

query_register! {
    struct: StockListQuery,
    id: "tx.stock_list",
    label: "Stock list",
    run: |pool, _caller_iid, site_iids, params| {
        if site_iids.is_empty() {
            return Ok(empty_sites());
        }
        let q = query_param_str(params, "q", "");
        let sql = format!(
            r#"
            SELECT site_iid, name, sku, stock_qty
            FROM site.product
            WHERE site_iid = ANY($1)
              AND deleted_ts IS NULL
              AND is_archived = false
              AND track_stock = true
              AND (
                $2 = ''
                OR name ILIKE ('%' || $2 || '%')
                OR sku ILIKE ('%' || $2 || '%')
              )
            ORDER BY site_iid, name
            LIMIT {STOCK_FETCH_LIMIT}
            "#
        );
        let rows = sqlx::query(&sql)
            .bind(site_iids)
            .bind(q)
            .fetch_all(pool)
            .await?;
        let (rows, truncated) = trim_export(rows);
        let mut out: Vec<SiteQueryRow> = rows
            .into_iter()
            .map(|r| {
                let site_iid: i64 = r.get("site_iid");
                let name: String = r.get("name");
                let sku: String = r.get("sku");
                let stock_qty: i32 = r.get("stock_qty");
                let mut cells = HashMap::new();
                cells.insert("name".into(), name);
                cells.insert("sku".into(), sku);
                cells.insert("stock_qty".into(), stock_qty.to_string());
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
            result_json: stock_meta("tx.stock_list", row_count, truncated, 0, 0),
        })
    }
}

query_register! {
    struct: StockCardQuery,
    id: "tx.stock_card",
    label: "Stock card",
    run: |pool, _caller_iid, site_iids, params| {
        if site_iids.is_empty() {
            return Ok(empty_sites());
        }
        let q = query_param_str(params, "q", "");
        let product_id = query_param_i64(params, "product_id", 0);
        if product_id <= 0 && q.is_empty() {
            return Ok(QueryResult {
                rows: vec![],
                result_json: json!({ "error": "product_required" }).to_string(),
            });
        }
        let (time_from, time_to) = query_time_range(params)?;
        let sql = format!(
            r#"
            SELECT s.site_iid, t.time_ts, t.ty, t.tx_id, p.name, p.sku,
                   s.direction, s.qty_signed, s.note
            FROM site.tx_stock s
            JOIN site.tx t
              ON t.site_iid = s.site_iid AND t.tx_id = s.tx_id
            JOIN site.product p
              ON p.site_iid = s.site_iid AND p.product_id = s.product_id
            WHERE s.site_iid = ANY($1)
              AND s.deleted_ts IS NULL
              AND t.deleted_ts IS NULL
              AND t.is_archived = false
              AND t.state = 'ok'
              AND ($2::bigint > 0 AND s.product_id = $2
                   OR $2::bigint = 0 AND (p.name ILIKE ('%' || $3 || '%') OR p.sku ILIKE ('%' || $3 || '%')))
              AND ($4::timestamptz IS NULL OR t.time_ts >= $4)
              AND ($5::timestamptz IS NULL OR t.time_ts <= $5)
            ORDER BY t.time_ts, t.tx_id, s.stock_id
            LIMIT {STOCK_FETCH_LIMIT}
            "#
        );
        let rows = sqlx::query(&sql)
            .bind(site_iids)
            .bind(product_id)
            .bind(q)
            .bind(time_from)
            .bind(time_to)
            .fetch_all(pool)
            .await?;
        let (rows, truncated) = trim_export(rows);
        let mut qty_in: i64 = 0;
        let mut qty_out: i64 = 0;
        let mut out: Vec<SiteQueryRow> = Vec::with_capacity(rows.len());
        for r in rows {
            let site_iid: i64 = r.get("site_iid");
            let time_ts: DateTime<Utc> = r.get("time_ts");
            let ty: String = r.get("ty");
            let tx_id: i64 = r.get("tx_id");
            let name: String = r.get("name");
            let sku: String = r.get("sku");
            let direction: String = r.get("direction");
            let qty_signed: i32 = r.get("qty_signed");
            let note: String = r.get("note");
            signed_totals(qty_signed, &mut qty_in, &mut qty_out);
            let mut cells = HashMap::new();
            cells.insert("time_ts".into(), time_ts.format("%Y-%m-%d %H:%M:%S").to_string());
            cells.insert("ty".into(), ty);
            cells.insert("tx_id".into(), tx_id.to_string());
            cells.insert("name".into(), name);
            cells.insert("sku".into(), sku);
            cells.insert("direction".into(), direction);
            cells.insert("qty_signed".into(), qty_signed.to_string());
            cells.insert("note".into(), note);
            out.push(SiteQueryRow {
                site_iid,
                site_name: String::new(),
                cells,
            });
        }
        out = site_query_rows_with_names(pool, site_iids, out).await?;
        let row_count = out.len() as i64;
        Ok(QueryResult {
            rows: out,
            result_json: stock_meta("tx.stock_card", row_count, truncated, qty_in, qty_out),
        })
    }
}

query_register! {
    struct: StockMovementQuery,
    id: "tx.stock_movement",
    label: "Stock movement",
    run: |pool, _caller_iid, site_iids, params| {
        if site_iids.is_empty() {
            return Ok(empty_sites());
        }
        let q = query_param_str(params, "q", "");
        let (time_from, time_to) = query_time_range(params)?;
        let sql = format!(
            r#"
            SELECT p.site_iid, p.product_id, p.name, p.sku,
                   COALESCE(SUM(CASE WHEN s.qty_signed > 0 THEN s.qty_signed ELSE 0 END), 0) AS qty_in,
                   COALESCE(SUM(CASE WHEN s.qty_signed < 0 THEN -s.qty_signed ELSE 0 END), 0) AS qty_out
            FROM site.tx_stock s
            JOIN site.tx t ON t.site_iid = s.site_iid AND t.tx_id = s.tx_id
            JOIN site.product p ON p.site_iid = s.site_iid AND p.product_id = s.product_id
            WHERE s.site_iid = ANY($1)
              AND s.deleted_ts IS NULL
              AND t.deleted_ts IS NULL
              AND t.is_archived = false
              AND t.state = 'ok'
              AND ($2::timestamptz IS NULL OR t.time_ts >= $2)
              AND ($3::timestamptz IS NULL OR t.time_ts <= $3)
              AND ($4 = '' OR p.name ILIKE ('%' || $4 || '%') OR p.sku ILIKE ('%' || $4 || '%'))
            GROUP BY p.site_iid, p.product_id, p.name, p.sku
            ORDER BY p.name
            LIMIT {STOCK_FETCH_LIMIT}
            "#
        );
        let rows = sqlx::query(&sql)
            .bind(site_iids)
            .bind(time_from)
            .bind(time_to)
            .bind(q)
            .fetch_all(pool)
            .await?;
        let (rows, truncated) = trim_export(rows);
        let mut qty_in: i64 = 0;
        let mut qty_out: i64 = 0;
        let mut out: Vec<SiteQueryRow> = Vec::with_capacity(rows.len());
        for r in rows {
            let site_iid: i64 = r.get("site_iid");
            let name: String = r.get("name");
            let sku: String = r.get("sku");
            let row_in: i64 = r.get("qty_in");
            let row_out: i64 = r.get("qty_out");
            qty_in += row_in;
            qty_out += row_out;
            let mut cells = HashMap::new();
            cells.insert("name".into(), name);
            cells.insert("sku".into(), sku);
            cells.insert("qty_in".into(), row_in.to_string());
            cells.insert("qty_out".into(), row_out.to_string());
            out.push(SiteQueryRow {
                site_iid,
                site_name: String::new(),
                cells,
            });
        }
        out = site_query_rows_with_names(pool, site_iids, out).await?;
        let row_count = out.len() as i64;
        Ok(QueryResult {
            rows: out,
            result_json: stock_meta("tx.stock_movement", row_count, truncated, qty_in, qty_out),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::{stock_report_preview, stock_report_query_id};

    #[test]
    fn stock_report_kinds_are_closed() {
        assert!(stock_report_query_id("tx.stock_list"));
        assert!(stock_report_query_id("tx.stock_card"));
        assert!(stock_report_query_id("tx.stock_movement"));
        assert!(!stock_report_query_id("tx.sales_summary"));
        assert!(!stock_report_query_id("product.stock"));
    }

    #[test]
    fn stock_report_preview_is_capped() {
        let rows = (0..50).map(|i| vec![format!("p{i}")]).collect::<Vec<_>>();
        let view = stock_report_preview(&rows, 40);
        assert_eq!(view.len(), 40);
    }
}
