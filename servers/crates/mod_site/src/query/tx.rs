use std::collections::HashMap;

use c35_proto::SiteQueryRow;
use serde_json::json;
use sqlx::Row;

use super::params::{query_param_i32, query_param_str, query_param_str_vec, query_time_range};
use super::{query_register, site_query_rows_with_names, QueryResult};

query_register! {
    struct: SalesSummaryQuery,
    id: "tx.sales_summary",
    label: "Sales revenue summary",
    run: |pool, _caller_iid, site_iids, params| {
        if site_iids.is_empty() {
            return Ok(QueryResult {
                rows: vec![],
                result_json: "{}".into(),
            });
        }
        let (time_from, time_to) = query_time_range(params)?;
        let rows = sqlx::query(
            r#"
            WITH sites AS (
                SELECT unnest($1::bigint[]) AS site_iid
            ),
            agg AS (
                SELECT
                    site_iid,
                    COUNT(*) FILTER (WHERE ty IN ('sale', 'return_sale')) AS tx_count,
                    COALESCE(SUM(
                        CASE
                            WHEN ty = 'sale' THEN total
                            WHEN ty = 'return_sale' THEN -total
                            ELSE 0
                        END
                    ), 0) AS revenue,
                    COALESCE(SUM(
                        CASE
                            WHEN ty = 'sale' THEN items_total
                            WHEN ty = 'return_sale' THEN -items_total
                            ELSE 0
                        END
                    ), 0) AS items_revenue,
                    COALESCE(SUM(
                        CASE
                            WHEN ty = 'sale' THEN total_paid
                            WHEN ty = 'return_sale' THEN -total_paid
                            ELSE 0
                        END
                    ), 0) AS paid_total
                FROM site.tx
                WHERE site_iid = ANY($1)
                  AND deleted_ts IS NULL
                  AND is_archived = false
                  AND state = 'ok'
                  AND ty IN ('sale', 'return_sale')
                  AND ($2::timestamptz IS NULL OR time_ts >= $2)
                  AND ($3::timestamptz IS NULL OR time_ts <= $3)
                GROUP BY site_iid
            )
            SELECT
                s.site_iid,
                COALESCE(a.tx_count, 0) AS tx_count,
                COALESCE(a.revenue, 0) AS revenue,
                COALESCE(a.items_revenue, 0) AS items_revenue,
                COALESCE(a.paid_total, 0) AS paid_total
            FROM sites s
            LEFT JOIN agg a ON a.site_iid = s.site_iid
            ORDER BY s.site_iid
            "#,
        )
        .bind(site_iids)
        .bind(time_from)
        .bind(time_to)
        .fetch_all(pool)
        .await?;
        let mut out: Vec<SiteQueryRow> = rows
            .into_iter()
            .map(|r| {
                let site_iid: i64 = r.get("site_iid");
                let tx_count: i64 = r.get("tx_count");
                let revenue: i64 = r.get("revenue");
                let items_revenue: i64 = r.get("items_revenue");
                let paid_total: i64 = r.get("paid_total");
                let mut cells = HashMap::new();
                cells.insert("tx_count".into(), tx_count.to_string());
                cells.insert("revenue".into(), revenue.to_string());
                cells.insert("items_revenue".into(), items_revenue.to_string());
                cells.insert("paid_total".into(), paid_total.to_string());
                SiteQueryRow {
                    site_iid,
                    site_name: String::new(),
                    cells,
                }
            })
            .collect();
        out = site_query_rows_with_names(pool, site_iids, out).await?;
        let site_count = out.len();
        Ok(QueryResult {
            rows: out,
            result_json: json!({
                "query_id": "tx.sales_summary",
                "site_count": site_count,
                "time_from_ms": time_from.map(|t| t.timestamp_millis()).unwrap_or(0),
                "time_to_ms": time_to.map(|t| t.timestamp_millis()).unwrap_or(0),
            })
            .to_string(),
        })
    }
}

query_register! {
    struct: ProfitSummaryQuery,
    id: "tx.profit_summary",
    label: "Profit summary compare",
    run: |pool, _caller_iid, site_iids, params| {
        if site_iids.is_empty() {
            return Ok(QueryResult {
                rows: vec![],
                result_json: "{}".into(),
            });
        }
        let (time_from, time_to) = query_time_range(params)?;
        let rows = sqlx::query(
            r#"
            WITH tx_filtered AS (
                SELECT site_iid, tx_id, ty, total, items_total
                FROM site.tx
                WHERE site_iid = ANY($1)
                  AND deleted_ts IS NULL
                  AND is_archived = false
                  AND state = 'ok'
                  AND ($2::timestamptz IS NULL OR time_ts >= $2)
                  AND ($3::timestamptz IS NULL OR time_ts <= $3)
            ),
            sales AS (
                SELECT
                    site_iid,
                    COALESCE(SUM(
                        CASE
                            WHEN ty = 'sale' THEN total
                            WHEN ty = 'return_sale' THEN -total
                            ELSE 0
                        END
                    ), 0) AS gross_sales,
                    COALESCE(SUM(
                        CASE
                            WHEN ty = 'sale' THEN items_total
                            WHEN ty = 'return_sale' THEN -items_total
                            ELSE 0
                        END
                    ), 0) AS items_sales
                FROM tx_filtered
                WHERE ty IN ('sale', 'return_sale')
                GROUP BY site_iid
            ),
            purchases AS (
                SELECT
                    site_iid,
                    COALESCE(SUM(
                        CASE
                            WHEN ty = 'purchase' THEN total
                            WHEN ty = 'return_purchase' THEN -total
                            ELSE 0
                        END
                    ), 0) AS cogs
                FROM tx_filtered
                WHERE ty IN ('purchase', 'return_purchase')
                GROUP BY site_iid
            ),
            acc_expense AS (
                SELECT
                    t.site_iid,
                    COALESCE(SUM(
                        CASE
                            WHEN c.acc_group = 'expense' AND a.side = 'debit' THEN a.amount
                            WHEN c.acc_group = 'expense' AND a.side = 'credit' THEN -a.amount
                            ELSE 0
                        END
                    ), 0) AS gl_expense
                FROM tx_filtered t
                INNER JOIN site.tx_acc a
                    ON a.site_iid = t.site_iid
                   AND a.tx_id = t.tx_id
                   AND a.deleted_ts IS NULL
                LEFT JOIN site.tx_coa_category c
                    ON c.account_code = a.acc_code
                   AND c.is_active = true
                GROUP BY t.site_iid
            ),
            sites AS (
                SELECT unnest($1::bigint[]) AS site_iid
            )
            SELECT
                s.site_iid,
                COALESCE(sa.gross_sales, 0) AS gross_sales,
                COALESCE(sa.items_sales, 0) AS items_sales,
                COALESCE(p.cogs, 0) AS cogs,
                COALESCE(e.gl_expense, 0) AS gl_expense,
                COALESCE(sa.gross_sales, 0) - COALESCE(p.cogs, 0) - COALESCE(e.gl_expense, 0) AS profit
            FROM sites s
            LEFT JOIN sales sa ON sa.site_iid = s.site_iid
            LEFT JOIN purchases p ON p.site_iid = s.site_iid
            LEFT JOIN acc_expense e ON e.site_iid = s.site_iid
            ORDER BY profit DESC, s.site_iid
            "#,
        )
        .bind(site_iids)
        .bind(time_from)
        .bind(time_to)
        .fetch_all(pool)
        .await?;
        let mut out: Vec<SiteQueryRow> = rows
            .into_iter()
            .map(|r| {
                let site_iid: i64 = r.get("site_iid");
                let gross_sales: i64 = r.get("gross_sales");
                let items_sales: i64 = r.get("items_sales");
                let cogs: i64 = r.get("cogs");
                let gl_expense: i64 = r.get("gl_expense");
                let profit: i64 = r.get("profit");
                let mut cells = HashMap::new();
                cells.insert("gross_sales".into(), gross_sales.to_string());
                cells.insert("items_sales".into(), items_sales.to_string());
                cells.insert("cogs".into(), cogs.to_string());
                cells.insert("gl_expense".into(), gl_expense.to_string());
                cells.insert("profit".into(), profit.to_string());
                SiteQueryRow {
                    site_iid,
                    site_name: String::new(),
                    cells,
                }
            })
            .collect();
        out = site_query_rows_with_names(pool, site_iids, out).await?;
        let site_count = out.len();
        Ok(QueryResult {
            rows: out,
            result_json: json!({
                "query_id": "tx.profit_summary",
                "site_count": site_count,
                "time_from_ms": time_from.map(|t| t.timestamp_millis()).unwrap_or(0),
                "time_to_ms": time_to.map(|t| t.timestamp_millis()).unwrap_or(0),
            })
            .to_string(),
        })
    }
}

query_register! {
    struct: TopProductsQuery,
    id: "tx.top_products",
    label: "Top selling products",
    run: |pool, _caller_iid, site_iids, params| {
        if site_iids.is_empty() {
            return Ok(QueryResult {
                rows: vec![],
                result_json: "{}".into(),
            });
        }
        let (time_from, time_to) = query_time_range(params)?;
        let limit = query_param_i32(params, "limit", 10).clamp(1, 100) as i64;
        let rows = sqlx::query(
            r#"
            SELECT
                ti.site_iid,
                ti.product_id,
                COALESCE(NULLIF(p.name, ''), ti.note, 'Product ' || ti.product_id) AS product_name,
                COALESCE(p.sku, '') AS sku,
                COALESCE(SUM(ti.qty), 0)::bigint AS sold_qty,
                COALESCE(SUM(ti.total_price), 0)::bigint AS total_revenue
            FROM site.tx_item ti
            INNER JOIN site.tx t
                ON t.site_iid = ti.site_iid
               AND t.tx_id = ti.tx_id
               AND t.deleted_ts IS NULL
               AND t.state = 'ok'
               AND t.ty IN ('sale', 'return_sale')
            LEFT JOIN site.product p
                ON p.site_iid = ti.site_iid
               AND p.product_id = ti.product_id
            WHERE ti.site_iid = ANY($1)
              AND ($2::timestamptz IS NULL OR t.time_ts >= $2)
              AND ($3::timestamptz IS NULL OR t.time_ts <= $3)
            GROUP BY ti.site_iid, ti.product_id, product_name, p.sku
            ORDER BY sold_qty DESC, total_revenue DESC
            LIMIT $4
            "#,
        )
        .bind(site_iids)
        .bind(time_from)
        .bind(time_to)
        .bind(limit)
        .fetch_all(pool)
        .await?;

        let mut out: Vec<SiteQueryRow> = rows
            .into_iter()
            .enumerate()
            .map(|(idx, r)| {
                let site_iid: i64 = r.get("site_iid");
                let product_id: i64 = r.get("product_id");
                let product_name: String = r.get("product_name");
                let sku: String = r.get("sku");
                let sold_qty: i64 = r.get("sold_qty");
                let total_revenue: i64 = r.get("total_revenue");
                let mut cells = HashMap::new();
                cells.insert("rank".into(), (idx + 1).to_string());
                cells.insert("product_id".into(), product_id.to_string());
                cells.insert("product_name".into(), product_name);
                cells.insert("sku".into(), sku);
                cells.insert("sold_qty".into(), sold_qty.to_string());
                cells.insert("total_revenue".into(), total_revenue.to_string());
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
            result_json: json!({
                "query_id": "tx.top_products",
                "count": count,
                "limit": limit,
                "time_from_ms": time_from.map(|t| t.timestamp_millis()).unwrap_or(0),
                "time_to_ms": time_to.map(|t| t.timestamp_millis()).unwrap_or(0),
            })
            .to_string(),
        })
    }
}

query_register! {
    struct: ProductCompareQuery,
    id: "tx.product_compare",
    label: "Product performance and profitability comparison",
    run: |pool, _caller_iid, site_iids, params| {
        if site_iids.is_empty() {
            return Ok(QueryResult {
                rows: vec![],
                result_json: "{}".into(),
            });
        }
        let (time_from, time_to) = query_time_range(params)?;
        let names = query_param_str_vec(params, "product_names");
        let q = query_param_str(params, "q", "");
        let rows = sqlx::query(
            r#"
            SELECT
                ti.site_iid,
                ti.product_id,
                COALESCE(NULLIF(p.name, ''), ti.note, 'Product ' || ti.product_id) AS product_name,
                COALESCE(p.sku, '') AS sku,
                COALESCE(p.price, 0) AS current_price,
                COALESCE(p.cost_price, 0) AS cost_price,
                COALESCE(SUM(ti.qty), 0)::bigint AS sold_qty,
                COALESCE(SUM(ti.total_price), 0)::bigint AS total_revenue
            FROM site.tx_item ti
            INNER JOIN site.tx t
                ON t.site_iid = ti.site_iid
               AND t.tx_id = ti.tx_id
               AND t.deleted_ts IS NULL
               AND t.state = 'ok'
               AND t.ty IN ('sale', 'return_sale')
            LEFT JOIN site.product p
                ON p.site_iid = ti.site_iid
               AND p.product_id = ti.product_id
            WHERE ti.site_iid = ANY($1)
              AND ($2::timestamptz IS NULL OR t.time_ts >= $2)
              AND ($3::timestamptz IS NULL OR t.time_ts <= $3)
              AND (
                cardinality($4::text[]) = 0
                OR p.name = ANY($4)
                OR ($5 <> '' AND (p.name ILIKE ('%' || $5 || '%') OR p.sku ILIKE ('%' || $5 || '%')))
              )
            GROUP BY ti.site_iid, ti.product_id, product_name, p.sku, p.price, p.cost_price
            ORDER BY total_revenue DESC
            LIMIT 50
            "#,
        )
        .bind(site_iids)
        .bind(time_from)
        .bind(time_to)
        .bind(&names)
        .bind(q)
        .fetch_all(pool)
        .await?;

        let mut out: Vec<SiteQueryRow> = rows
            .into_iter()
            .map(|r| {
                let site_iid: i64 = r.get("site_iid");
                let product_id: i64 = r.get("product_id");
                let product_name: String = r.get("product_name");
                let sku: String = r.get("sku");
                let current_price: i64 = r.get("current_price");
                let cost_price: i64 = r.get("cost_price");
                let sold_qty: i64 = r.get("sold_qty");
                let total_revenue: i64 = r.get("total_revenue");
                let total_cogs = cost_price * sold_qty;
                let gross_profit = total_revenue - total_cogs;
                let margin_pct = if total_revenue > 0 {
                    (gross_profit as f64 / total_revenue as f64) * 100.0
                } else {
                    0.0
                };
                let mut cells = HashMap::new();
                cells.insert("product_id".into(), product_id.to_string());
                cells.insert("product_name".into(), product_name);
                cells.insert("sku".into(), sku);
                cells.insert("current_price".into(), current_price.to_string());
                cells.insert("cost_price".into(), cost_price.to_string());
                cells.insert("sold_qty".into(), sold_qty.to_string());
                cells.insert("total_revenue".into(), total_revenue.to_string());
                cells.insert("gross_profit".into(), gross_profit.to_string());
                cells.insert("margin_pct".into(), format!("{:.1}%", margin_pct));
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
            result_json: json!({
                "query_id": "tx.product_compare",
                "count": count,
                "time_from_ms": time_from.map(|t| t.timestamp_millis()).unwrap_or(0),
                "time_to_ms": time_to.map(|t| t.timestamp_millis()).unwrap_or(0),
            })
            .to_string(),
        })
    }
}

