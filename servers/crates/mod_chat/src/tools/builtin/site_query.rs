use anyhow::{anyhow, Result};
use c35_mod_site::{site_granted_iids, site_query_run, stock_report_from_query, stock_report_query_id};
use serde_json::{json, Value};

use crate::stock_report_run::{formats_from_params, materialize};

use crate::site_scope::site_scope_pick;
use crate::tool;
use crate::tools::ToolContext;

fn args_site_iids(args: &Value) -> Vec<i64> {
    args.get("site_iids")
        .and_then(|v| v.as_array())
        .map(|arr| {
            arr.iter()
                .filter_map(|v| v.as_i64())
                .filter(|i| *i > 0)
                .collect()
        })
        .unwrap_or_default()
}

async fn site_iids_resolve(ctx: &ToolContext, args: &Value) -> Result<Vec<i64>> {
    let arg_iids = args_site_iids(args);
    let mentioned = ctx.mention.site_iids();
    let granted = if mentioned.is_empty() && arg_iids.is_empty() {
        site_granted_iids(&ctx.pool, ctx.owner_iid).await?
    } else {
        Vec::new()
    };
    let ids = site_scope_pick(&mentioned, &granted, &arg_iids).map_err(|e| anyhow!(e))?;
    Ok(ids)
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
    let site_iids = site_iids_resolve(ctx, args).await?;
    let params_json = params_json_resolve(args)?;
    let res = site_query_run(&ctx.pool, ctx.owner_iid, site_iids, query_id, &params_json).await?;
    if stock_report_query_id(query_id) {
        let params: Value = serde_json::from_str(&params_json).unwrap_or(json!({}));
        let Some(report) = stock_report_from_query(query_id, &res.rows, &res.result_json) else {
            return Ok(json!({ "ok": false, "query_id": query_id, "error": "stock report failed" }));
        };
        let built = materialize(&ctx.pool, ctx.chat_id, &report, &formats_from_params(&params)).await?;
        return Ok(built.llm);
    }
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
    description: "Readonly site query. Omit site_iids to use @mentioned sites, or every site the caller can access when nothing is mentioned. product.stock params.q matches name, sku, or category.",
    topics: ["site.commerce", "web.builder"],
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
