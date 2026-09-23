use std::collections::HashMap;

use c35_proto::SiteQueryRow;
use serde_json::json;
use sqlx::Row;

use super::params::query_param_bool;
use super::params::query_param_i32;
use super::{query_register, site_query_rows_with_names, QueryResult};

query_register! {
    struct: ProductListQuery,
    id: "product.list",
    label: "Product catalog list",
    run: |pool, _caller_iid, site_iids, _params| {
        if site_iids.is_empty() {
            return Ok(QueryResult {
                rows: vec![],
                result_json: "{}".into(),
            });
        }
        let rows = sqlx::query(
            r#"
            SELECT site_iid, product_id, name, price, stock_qty
            FROM site.product
            WHERE site_iid = ANY($1) AND deleted_ts IS NULL AND is_archived = false
            ORDER BY site_iid, sort_order, product_id
            "#,
        )
        .bind(site_iids)
        .fetch_all(pool)
        .await?;
        let mut out: Vec<SiteQueryRow> = rows
            .into_iter()
            .map(|r| {
                let site_iid: i64 = r.get("site_iid");
                let product_id: i64 = r.get("product_id");
                let name: String = r.get("name");
                let price: i64 = r.get("price");
                let stock_qty: i32 = r.get("stock_qty");
                let mut cells = HashMap::new();
                cells.insert("product_id".into(), product_id.to_string());
                cells.insert("name".into(), name);
                cells.insert("price".into(), price.to_string());
                cells.insert("stock_qty".into(), stock_qty.to_string());
                SiteQueryRow {
                    site_iid,
                    site_name: String::new(),
                    cells,
                }
            })
            .collect();
        out = site_query_rows_with_names(pool, site_iids, out).await?;
        let count = out.len();
        Ok(QueryResult {
            rows: out,
            result_json: json!({ "query_id": "product.list", "count": count }).to_string(),
        })
    }
}

query_register! {
    struct: ProductStockStatusQuery,
    id: "product.stock_status",
    label: "Low stock snapshot",
    run: |pool, _caller_iid, site_iids, params| {
        if site_iids.is_empty() {
            return Ok(QueryResult {
                rows: vec![],
                result_json: "{}".into(),
            });
        }
        let low_qty_max = query_param_i32(params, "low_qty_max", 5).max(0);
        let all_tracked = query_param_bool(params, "all_tracked", false);
        let rows = sqlx::query(
            r#"
            SELECT site_iid, product_id, name, sku, stock_qty, track_stock
            FROM site.product
            WHERE site_iid = ANY($1)
              AND deleted_ts IS NULL
              AND is_archived = false
              AND track_stock = true
              AND (
                $2 = true
                OR stock_qty <= $3
              )
            ORDER BY site_iid, stock_qty ASC, sort_order, product_id
            "#,
        )
        .bind(site_iids)
        .bind(all_tracked)
        .bind(low_qty_max)
        .fetch_all(pool)
        .await?;
        let mut out: Vec<SiteQueryRow> = rows
            .into_iter()
            .map(|r| {
                let site_iid: i64 = r.get("site_iid");
                let product_id: i64 = r.get("product_id");
                let name: String = r.get("name");
                let sku: String = r.get("sku");
                let stock_qty: i32 = r.get("stock_qty");
                let status = if stock_qty <= 0 {
                    "out_of_stock"
                } else if stock_qty <= low_qty_max {
                    "low"
                } else {
                    "ok"
                };
                let mut cells = HashMap::new();
                cells.insert("product_id".into(), product_id.to_string());
                cells.insert("name".into(), name);
                cells.insert("sku".into(), sku);
                cells.insert("stock_qty".into(), stock_qty.to_string());
                cells.insert("low_qty_max".into(), low_qty_max.to_string());
                cells.insert("status".into(), status.into());
                SiteQueryRow {
                    site_iid,
                    site_name: String::new(),
                    cells,
                }
            })
            .collect();
        out = site_query_rows_with_names(pool, site_iids, out).await?;
        let count = out.len();
        let low_count = out
            .iter()
            .filter(|r| {
                matches!(
                    r.cells.get("status").map(String::as_str),
                    Some("low") | Some("out_of_stock")
                )
            })
            .count();
        Ok(QueryResult {
            rows: out,
            result_json: json!({
                "query_id": "product.stock_status",
                "count": count,
                "low_count": low_count,
                "low_qty_max": low_qty_max,
                "all_tracked": all_tracked,
            })
            .to_string(),
        })
    }
}
