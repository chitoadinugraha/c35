use crate::{require_root, AdminError};
use c35_proto::{
    ReqAdminLogReport, ResAdminLogReport, UiMetricsCard, UiReportTable, UiReportTableRow, UiWidget,
};
use sqlx::{PgPool, QueryBuilder, Row};

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
    Ok(ResAdminLogReport { widgets })
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
