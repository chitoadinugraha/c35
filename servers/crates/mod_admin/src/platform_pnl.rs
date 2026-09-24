use crate::{require_root, AdminError};
use c35_mod_platform::{platform_pnl_query, PlatformPnl};
use c35_proto::{
    ReqAdminPlatformPnl, ResAdminPlatformPnl, UiMetricsCard, UiReportTable, UiReportTableRow,
    UiWidget,
};
use sqlx::PgPool;

pub async fn admin_platform_pnl(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqAdminPlatformPnl,
) -> Result<ResAdminPlatformPnl, AdminError> {
    require_root(pool, viewer_iid).await?;
    let (pnl, vendors) = platform_pnl_query(pool, req.since_ms, req.until_ms)
        .await
        .map_err(|e| AdminError::bad(e.to_string()))?;
    Ok(build_res(pnl, vendors))
}

fn build_res(pnl: PlatformPnl, vendors: Vec<c35_mod_platform::VendorCostBreakdown>) -> ResAdminPlatformPnl {
    let drift_subtitle = if pnl.ai_cogs_drift_pct > 5.0 {
        format!("Drift {:.1}% — review AI API vendor lines", pnl.ai_cogs_drift_pct)
    } else {
        format!("AI vendor vs wholesale drift {:.1}%", pnl.ai_cogs_drift_pct)
    };
    let widgets = vec![
        metric_card("Revenue", pnl.revenue_usd, "Top-ups + purchases + metered"),
        metric_card("AI COGS", pnl.ai_cogs_usd, "Wholesale usage cost"),
        metric_card("Infra COGS", pnl.infra_cogs_usd, "Vendor costs excl. AI API"),
        metric_card("Gross profit", pnl.gross_profit_usd, "Revenue − AI − infra"),
        metric_card("AI API vendor", pnl.ai_api_vendor_usd, drift_subtitle),
    ];
    let widgets = if vendors.is_empty() {
        widgets
    } else {
        let rows = vendors
            .into_iter()
            .map(|v| UiReportTableRow {
                cells: vec![v.vendor, format_usd(v.amount_usd)],
            })
            .collect();
        widgets
            .into_iter()
            .chain([UiWidget {
                element: Some(c35_proto::ui_widget::Element::Table(UiReportTable {
                    headers: vec!["Vendor".into(), "Amount (USD)".into()],
                    rows,
                })),
            }])
            .collect()
    };
    ResAdminPlatformPnl {
        widgets,
        revenue_usd: pnl.revenue_usd,
        ai_cogs_usd: pnl.ai_cogs_usd,
        infra_cogs_usd: pnl.infra_cogs_usd,
        gross_profit_usd: pnl.gross_profit_usd,
        ai_api_vendor_usd: pnl.ai_api_vendor_usd,
        ai_cogs_drift_pct: pnl.ai_cogs_drift_pct,
    }
}

fn metric_card(title: &str, usd: f64, subtitle: impl Into<String>) -> UiWidget {
    UiWidget {
        element: Some(c35_proto::ui_widget::Element::MetricsCard(UiMetricsCard {
            title: title.into(),
            value: format_usd(usd),
            subtitle: subtitle.into(),
        })),
    }
}

fn format_usd(usd: f64) -> String {
    format!("${:.2}", usd)
}
