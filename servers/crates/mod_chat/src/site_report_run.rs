use anyhow::Result;
use c35_mod_site::{site_granted_iids, site_query_run};
use serde_json::json;

use crate::prompt::ChatRes;
use crate::site_report::site_report_parse;
use crate::site_scope::site_scope_pick;
use crate::tools::TurnCtx;

pub async fn site_report_prefetch(ctx: &TurnCtx<'_>, user_text: &str) -> Result<Option<ChatRes>> {
    let Some(intent) = site_report_parse(user_text) else {
        return Ok(None);
    };
    let mentioned = ctx.mention.site_iids();
    let granted = if mentioned.is_empty() {
        site_granted_iids(ctx.pool, ctx.owner_iid).await.unwrap_or_default()
    } else {
        Vec::new()
    };
    let site_iids = match site_scope_pick(&mentioned, &granted, &[]) {
        Ok(ids) if !ids.is_empty() => ids,
        _ => return Ok(Some(plain_res("No site to report on."))),
    };
    let params = json!({ "range": intent.range });
    let res = site_query_run(
        ctx.pool,
        ctx.owner_iid,
        site_iids,
        intent.query_id,
        &params.to_string(),
    )
    .await?;
    Ok(Some(build_res(intent.query_id, &res.rows)))
}

fn build_res(query_id: &str, rows: &[c35_proto::SiteQueryRow]) -> ChatRes {
    if rows.is_empty() {
        return plain_res("No data for that period.");
    }
    let mut lines: Vec<String> = Vec::new();
    for row in rows {
        let name = if row.site_name.is_empty() {
            format!("Site {}", row.site_iid)
        } else {
            row.site_name.clone()
        };
        if query_id == "tx.profit_summary" {
            let profit = row.cells.get("profit").cloned().unwrap_or_default();
            let gross = row.cells.get("gross_sales").cloned().unwrap_or_default();
            lines.push(format!("{name}: untung {profit} (omzet {gross})"));
        } else {
            let revenue = row.cells.get("revenue").cloned().unwrap_or_default();
            let tx_count = row.cells.get("tx_count").cloned().unwrap_or_default();
            lines.push(format!("{name}: omzet {revenue} ({tx_count} transaksi)"));
        }
    }
    ChatRes {
        text: lines.join("\n"),
        model_used: "site_report".into(),
        ..ChatRes::default()
    }
}

fn plain_res(text: &str) -> ChatRes {
    ChatRes {
        text: text.to_string(),
        model_used: "site_report".into(),
        ..ChatRes::default()
    }
}
