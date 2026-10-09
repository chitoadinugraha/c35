use anyhow::Result;
use c35_mod_site::{site_granted_iids, site_query_run, tx_browse_from_query, TxBrowseReport};
use serde_json::json;

use crate::prompt::ChatRes;
use crate::site_scope::site_scope_pick;
use crate::tx_browse::tx_browse_parse;
use crate::tx_browse_render::tx_browse_blocks;
use crate::tools::TurnCtx;

pub async fn tx_browse_prefetch(ctx: &TurnCtx<'_>, user_text: &str) -> Result<Option<ChatRes>> {
    let Some(intent) = tx_browse_parse(user_text) else {
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
        _ => return Ok(Some(plain_res("No site to list transactions for."))),
    };
    let mut params = json!({
        "range": intent.range,
        "limit": intent.limit,
        "open_only": intent.open_only,
    });
    if let Some(state) = &intent.state {
        params["state"] = json!(state);
    }
    let res = site_query_run(
        ctx.pool,
        ctx.owner_iid,
        site_iids,
        intent.query_id,
        &params.to_string(),
    )
    .await?;
    let Some(report) = tx_browse_from_query(intent.query_id, &res.rows, &res.result_json) else {
        return Ok(None);
    };
    Ok(Some(build_res(&report)))
}

fn build_res(report: &TxBrowseReport) -> ChatRes {
    let blocks = tx_browse_blocks(report);
    let text = format!(
        "{}. {} transactions. Total revenue {}.",
        report.title, report.row_count, report.total_revenue
    );
    ChatRes {
        text,
        blocks_json: serde_json::to_string(&blocks).unwrap_or_else(|_| "[]".into()),
        model_used: "tx_browse".into(),
        ..ChatRes::default()
    }
}

fn plain_res(text: &str) -> ChatRes {
    ChatRes {
        text: text.to_string(),
        model_used: "tx_browse".into(),
        ..ChatRes::default()
    }
}