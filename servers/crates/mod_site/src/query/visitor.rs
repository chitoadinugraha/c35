use std::collections::HashMap;

use anyhow::{anyhow, bail, Result};
use c35_proto::SiteQueryRow;
use chrono::{NaiveDate, Utc};
use c35_time_range::date_range_from_params_at;
use serde_json::{json, Value};
use sqlx::Row;

use super::params::{query_param_i32, query_param_str};
use super::{query_register, site_query_rows_with_names, QueryResult};

fn default_tz(params: &Value) -> &str {
    let tz = query_param_str(params, "tz", "");
    if tz.is_empty() {
        "Asia/Jakarta"
    } else {
        tz
    }
}

fn parse_day(s: &str) -> Result<NaiveDate> {
    NaiveDate::parse_from_str(s.trim(), "%Y-%m-%d")
        .map_err(|_| anyhow!("invalid date {s}"))
}

fn day_range_from_params(params: &Value) -> Result<Vec<NaiveDate>> {
    let from_s = query_param_str(params, "day_from", "");
    let to_s = query_param_str(params, "day_to", "");
    if !from_s.is_empty() && !to_s.is_empty() {
        let from = parse_day(from_s)?;
        let to = parse_day(to_s)?;
        if from > to {
            bail!("invalid day range");
        }
        let days = to.signed_duration_since(from).num_days();
        if days > 62 {
            bail!("day range too large");
        }
        let mut out = Vec::new();
        let mut cur = from;
        while cur <= to {
            out.push(cur);
            cur = cur.succ_opt().ok_or_else(|| anyhow!("day overflow"))?;
        }
        return Ok(out);
    }

    let resolved = date_range_from_params_at(params, Utc::now(), default_tz(params))?;
    let from = resolved
        .from
        .ok_or_else(|| anyhow!("range or day_from/day_to required"))?
        .date_naive();
    let to = resolved
        .to
        .ok_or_else(|| anyhow!("range or day_from/day_to required"))?
        .date_naive();
    if from > to {
        bail!("invalid day range");
    }
    let span = to.signed_duration_since(from).num_days();
    if span > 62 {
        bail!("day range too large");
    }
    let mut out = Vec::new();
    let mut cur = from;
    while cur <= to {
        out.push(cur);
        cur = cur.succ_opt().ok_or_else(|| anyhow!("day overflow"))?;
    }
    Ok(out)
}

query_register! {
    struct: VisitorSummaryQuery,
    id: "visitor.summary",
    label: "Visitor traffic summary by day",
    run: |pool, _caller_iid, site_iids, params| {
        if site_iids.is_empty() {
            return Ok(QueryResult {
                rows: vec![],
                result_json: "{}".into(),
            });
        }
        let days = day_range_from_params(params)?;
        let mut out: Vec<SiteQueryRow> = Vec::new();
        for &site_iid in site_iids {
            for day in &days {
                let row = sqlx::query(
                    r#"
                    SELECT page_views, unique_visitors, active_duration_ms, visitor_slots
                    FROM site.analytics_day
                    WHERE site_iid = $1 AND day_bucket = $2
                    "#,
                )
                .bind(site_iid)
                .bind(day)
                .fetch_optional(pool)
                .await?;
                let (page_views, unique_visitors, active_duration_ms, slots) = match row {
                    Some(r) => (
                        r.get::<i64, _>("page_views"),
                        r.get::<i32, _>("unique_visitors"),
                        r.get::<i64, _>("active_duration_ms"),
                        r.get::<serde_json::Value, _>("visitor_slots").to_string(),
                    ),
                    None => (0, 0, 0, "[]".to_string()),
                };
                let mut cells = HashMap::new();
                cells.insert("day".into(), day.to_string());
                cells.insert("page_views".into(), page_views.to_string());
                cells.insert("unique_visitors".into(), unique_visitors.to_string());
                cells.insert("active_duration_ms".into(), active_duration_ms.to_string());
                cells.insert("visitor_slots".into(), slots);
                out.push(SiteQueryRow {
                    site_iid,
                    site_name: String::new(),
                    cells,
                });
            }
        }
        out = site_query_rows_with_names(pool, site_iids, out).await?;
        let count = out.len();
        Ok(QueryResult {
            rows: out,
            result_json: json!({ "query_id": "visitor.summary", "count": count }).to_string(),
        })
    }
}

query_register! {
    struct: VisitorPathsQuery,
    id: "visitor.paths",
    label: "Top guest page paths",
    run: |pool, _caller_iid, site_iids, params| {
        if site_iids.is_empty() {
            return Ok(QueryResult {
                rows: vec![],
                result_json: "{}".into(),
            });
        }
        let days = day_range_from_params(params)?;
        let limit = query_param_i32(params, "limit", 20).clamp(1, 100);
        let day_from = days.first().copied().unwrap_or_else(|| Utc::now().date_naive());
        let day_to = days.last().copied().unwrap_or(day_from);

        let rows = sqlx::query(
            r#"
            SELECT site_iid, path, SUM(views)::bigint AS views
            FROM site.analytics_path_day
            WHERE site_iid = ANY($1)
              AND day_bucket >= $2
              AND day_bucket <= $3
            GROUP BY site_iid, path
            ORDER BY views DESC
            LIMIT $4
            "#,
        )
        .bind(site_iids)
        .bind(day_from)
        .bind(day_to)
        .bind(limit as i64)
        .fetch_all(pool)
        .await?;

        let mut out: Vec<SiteQueryRow> = rows
            .into_iter()
            .map(|r| {
                let site_iid: i64 = r.get("site_iid");
                let path: String = r.get("path");
                let views: i64 = r.get("views");
                let mut cells = HashMap::new();
                cells.insert("path".into(), path);
                cells.insert("views".into(), views.to_string());
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
            result_json: json!({ "query_id": "visitor.paths", "count": count }).to_string(),
        })
    }
}

query_register! {
    struct: LinkClicksQuery,
    id: "link.clicks",
    label: "Hub link click counts",
    run: |pool, _caller_iid, site_iids, params| {
        if site_iids.is_empty() {
            return Ok(QueryResult {
                rows: vec![],
                result_json: "{}".into(),
            });
        }
        let days = day_range_from_params(params)?;
        let limit = query_param_i32(params, "limit", 50).clamp(1, 200);
        let day_from = days.first().copied().unwrap_or_else(|| Utc::now().date_naive());
        let day_to = days.last().copied().unwrap_or(day_from);

        let rows = sqlx::query(
            r#"
            SELECT
                a.site_iid,
                a.day_bucket,
                a.link_id,
                a.clicks,
                COALESCE(l.label, '') AS label,
                COALESCE(l.url, '') AS url
            FROM site.analytics_link_day a
            LEFT JOIN site.link l
              ON l.site_iid = a.site_iid AND l.link_id = a.link_id AND l.deleted_ts IS NULL
            WHERE a.site_iid = ANY($1)
              AND a.day_bucket >= $2
              AND a.day_bucket <= $3
            ORDER BY a.clicks DESC, a.day_bucket DESC
            LIMIT $4
            "#,
        )
        .bind(site_iids)
        .bind(day_from)
        .bind(day_to)
        .bind(limit as i64)
        .fetch_all(pool)
        .await?;

        let mut out: Vec<SiteQueryRow> = rows
            .into_iter()
            .map(|r| {
                let site_iid: i64 = r.get("site_iid");
                let day: NaiveDate = r.get("day_bucket");
                let link_id: i64 = r.get("link_id");
                let clicks: i32 = r.get("clicks");
                let label: String = r.get("label");
                let url: String = r.get("url");
                let mut cells = HashMap::new();
                cells.insert("day".into(), day.to_string());
                cells.insert("link_id".into(), link_id.to_string());
                cells.insert("clicks".into(), clicks.to_string());
                cells.insert("label".into(), label);
                cells.insert("url".into(), url);
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
            result_json: json!({ "query_id": "link.clicks", "count": count }).to_string(),
        })
    }
}
