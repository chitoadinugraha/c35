use anyhow::{anyhow, bail, Result};
use c35_mod_site::site_query_run;
use serde_json::{json, Value};

use crate::tool;
use crate::tools::ToolContext;

fn site_iids_resolve(ctx: &ToolContext, args: &Value) -> Result<Vec<i64>> {
    if let Some(arr) = args.get("site_iids").and_then(|v| v.as_array()) {
        let ids: Vec<i64> = arr
            .iter()
            .filter_map(|v| v.as_i64())
            .filter(|i| *i > 0)
            .collect();
        if !ids.is_empty() {
            return Ok(ids);
        }
    }
    let from_mention = ctx.mention.site_iids();
    if !from_mention.is_empty() {
        return Ok(from_mention);
    }
    bail!("site_iids required — mention @site or pass site_iids")
}

fn params_json_resolve(args: &Value) -> Result<String> {
    if let Some(raw) = args.get("params_json").and_then(|v| v.as_str()) {
        return Ok(raw.to_string());
    }
    if let Some(params) = args.get("params") {
        return Ok(serde_json::to_string(params)?);
    }
    Ok("{}".into())
}

pub async fn site_query_run_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let query_id = args
        .get("query_id")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .ok_or_else(|| anyhow!("query_id is required"))?;
    let site_iids = site_iids_resolve(ctx, args)?;
    let params_json = params_json_resolve(args)?;
    let res = site_query_run(
        &ctx.pool,
        ctx.owner_iid,
        site_iids,
        query_id,
        &params_json,
    )
    .await?;
    let rows: Vec<Value> = res
        .rows
        .into_iter()
        .map(|r| {
            json!({
                "site_iid": r.site_iid,
                "site_name": r.site_name,
                "cells": r.cells,
            })
        })
        .collect();
    Ok(json!({
        "ok": true,
        "query_id": query_id,
        "rows": rows,
        "result_json": res.result_json,
    }))
}

tool! {
    struct: SiteQueryRunTool,
    name: "site.query.run",
    aliases: ["site_query_run"],
    description: "Run a readonly site query from the catalog (product.list, tx summaries, …). Multi-site compare uses all @mentioned sites when site_iids is omitted.",
    topics: ["site.commerce", "web.builder", "general"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.query.run.calling",
    ui_done_key: "tool.site.query.run.done",
    readonly: true,
    parameters: {
        query_id: (string, "Query catalog id (e.g. product.list, tx.profit_summary)", required),
        site_iids: (array, "Site identity IDs; omit to use all @mentioned sites", optional),
        params: (object, "Query parameters object (validated per QueryDef)", optional),
        params_json: (string, "Query parameters as JSON string (alternative to params)", optional),
    },
    execute: |args, ctx| {
        site_query_run_exec(ctx, &args).await
    }
}
