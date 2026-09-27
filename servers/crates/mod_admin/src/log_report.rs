use crate::{require_root, AdminError};
use c35_proto::{
    ReqAdminLogReport, ResAdminLogReport, UiMetricsCard, UiReportTable, UiReportTableRow, UiWidget,
};
use sqlx::{PgPool, QueryBuilder, Row};

const TOOL_TRACE_WHERE: &str = " AND kind = 'tool' AND class = 'trace' AND COALESCE(meta->>'tool', '') <> ''";

pub async fn admin_log_report(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqAdminLogReport,
) -> Result<ResAdminLogReport, AdminError> {
    require_root(pool, viewer_iid).await?;
    let kind_limit = if req.limit <= 0 { 10 } else { req.limit.min(50) };

    let mut agg_qb = QueryBuilder::new(
        "SELECT COUNT(*)::bigint AS total, COUNT(DISTINCT owner_iid)::bigint AS owners FROM ai.log WHERE deleted_ts IS NULL",
    );
    push_log_filters(&mut agg_qb, &req);
    let agg = agg_qb
        .build()
        .fetch_one(pool)
        .await
        .map_err(|e| AdminError::bad(e.to_string()))?;
    let total: i64 = agg.get("total");
    let owners: i64 = agg.get("owners");

    let mut kind_qb = QueryBuilder::new("SELECT kind, COUNT(*)::bigint AS cnt FROM ai.log WHERE deleted_ts IS NULL");
    push_log_filters(&mut kind_qb, &req);
    kind_qb.push(" GROUP BY kind ORDER BY cnt DESC LIMIT ");
    kind_qb.push_bind(kind_limit);
    let kind_rows = kind_qb
        .build()
        .fetch_all(pool)
        .await
        .map_err(|e| AdminError::bad(e.to_string()))?;

    let mut widgets = vec![
        UiWidget {
            element: Some(c35_proto::ui_widget::Element::MetricsCard(UiMetricsCard {
                title: "Total logs".into(),
                value: format!("{total}"),
                subtitle: "In selected range".into(),
            })),
        },
        UiWidget {
            element: Some(c35_proto::ui_widget::Element::MetricsCard(UiMetricsCard {
                title: "Distinct owners".into(),
                value: format!("{owners}"),
                subtitle: "Users with log rows".into(),
            })),
        },
    ];
    if !kind_rows.is_empty() {
        let rows = kind_rows
            .into_iter()
            .map(|r| UiReportTableRow {
                cells: vec![r.get::<String, _>("kind"), format!("{}", r.get::<i64, _>("cnt"))],
            })
            .collect();
        widgets.push(UiWidget {
            element: Some(c35_proto::ui_widget::Element::Table(UiReportTable {
                headers: vec!["Kind".into(), "Count".into()],
                rows,
            })),
        });
    }

    if req.group_tools {
        widgets.extend(tool_usage_widgets(pool, &req, kind_limit).await?);
    }

    Ok(ResAdminLogReport { widgets })
}

async fn tool_usage_widgets(
    pool: &PgPool,
    req: &ReqAdminLogReport,
    tool_limit: i32,
) -> Result<Vec<UiWidget>, AdminError> {
    let mut total_qb = QueryBuilder::new(
        "SELECT COUNT(*)::bigint AS total FROM ai.log WHERE deleted_ts IS NULL",
    );
    total_qb.push(TOOL_TRACE_WHERE);
    push_log_filters(&mut total_qb, req);
    let tool_total: i64 = total_qb
        .build()
        .fetch_one(pool)
        .await
        .map_err(|e| AdminError::bad(e.to_string()))?
        .get("total");

    let mut tool_qb = QueryBuilder::new(
        r#"SELECT meta->>'tool' AS tool_id,
           COUNT(*)::bigint AS calls,
           COUNT(*) FILTER (WHERE topic <> 'tool_error' AND COALESCE(meta->>'ok', 'true') <> 'false')::bigint AS ok_cnt,
           COUNT(*) FILTER (WHERE topic = 'tool_error' OR meta->>'ok' = 'false')::bigint AS fail_cnt,
           COALESCE(AVG(NULLIF(duration_ms, 0)), 0)::double precision AS avg_ms
           FROM ai.log WHERE deleted_ts IS NULL"#,
    );
    tool_qb.push(TOOL_TRACE_WHERE);
    push_log_filters(&mut tool_qb, req);
    tool_qb.push(" GROUP BY meta->>'tool' ORDER BY calls DESC LIMIT ");
    tool_qb.push_bind(tool_limit);
    let tool_rows = tool_qb
        .build()
        .fetch_all(pool)
        .await
        .map_err(|e| AdminError::bad(e.to_string()))?;

    let mut week_qb = QueryBuilder::new(
        r#"SELECT to_char(date_trunc('week', created_ts AT TIME ZONE 'UTC'), 'YYYY-MM-DD') AS week_start,
           COUNT(*)::bigint AS calls
           FROM ai.log WHERE deleted_ts IS NULL"#,
    );
    week_qb.push(TOOL_TRACE_WHERE);
    push_log_filters(&mut week_qb, req);
    week_qb.push(
        " GROUP BY date_trunc('week', created_ts AT TIME ZONE 'UTC') ORDER BY week_start DESC LIMIT 12",
    );
    let week_rows = week_qb
        .build()
        .fetch_all(pool)
        .await
        .map_err(|e| AdminError::bad(e.to_string()))?;

    let mut out = vec![UiWidget {
        element: Some(c35_proto::ui_widget::Element::MetricsCard(UiMetricsCard {
            title: "Tool executions".into(),
            value: format!("{tool_total}"),
            subtitle: "kind=tool trace rows with meta.tool".into(),
        })),
    }];

    if !tool_rows.is_empty() {
        let rows = tool_rows
            .into_iter()
            .map(|r| {
                let avg_ms: f64 = r.get("avg_ms");
                UiReportTableRow {
                    cells: vec![
                        r.get::<String, _>("tool_id"),
                        format!("{}", r.get::<i64, _>("calls")),
                        format!("{}", r.get::<i64, _>("ok_cnt")),
                        format!("{}", r.get::<i64, _>("fail_cnt")),
                        format!("{avg_ms:.0}"),
                    ],
                }
            })
            .collect();
        out.push(UiWidget {
            element: Some(c35_proto::ui_widget::Element::Table(UiReportTable {
                headers: vec![
                    "tool_id".into(),
                    "calls".into(),
                    "ok".into(),
                    "fail".into(),
                    "avg_ms".into(),
                ],
                rows,
            })),
        });
    }

    if !week_rows.is_empty() {
        let rows = week_rows
            .into_iter()
            .map(|r| {
                UiReportTableRow {
                    cells: vec![
                        r.get::<String, _>("week_start"),
                        format!("{}", r.get::<i64, _>("calls")),
                    ],
                }
            })
            .collect();
        out.push(UiWidget {
            element: Some(c35_proto::ui_widget::Element::Table(UiReportTable {
                headers: vec!["week_start (UTC)".into(), "calls".into()],
                rows,
            })),
        });
    }

    Ok(out)
}

fn push_log_filters(qb: &mut QueryBuilder<'_, sqlx::Postgres>, req: &ReqAdminLogReport) {
    if let Some(owner_iid) = req.owner_iid {
        qb.push(" AND owner_iid = ");
        qb.push_bind(owner_iid);
    }
    if req.since_ms > 0 {
        qb.push(" AND created_ts >= ");
        qb.push_bind(ms_to_ts(req.since_ms));
    }
    if req.until_ms > 0 {
        qb.push(" AND created_ts <= ");
        qb.push_bind(ms_to_ts(req.until_ms));
    }
}

fn ms_to_ts(ms: i64) -> chrono::DateTime<chrono::Utc> {
    chrono::DateTime::from_timestamp_millis(ms).unwrap_or_else(chrono::Utc::now)
}
