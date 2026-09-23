use std::collections::HashMap;

use c35_proto::SiteQueryRow;
use serde_json::json;
use sqlx::Row;

use super::params::query_time_range;
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
