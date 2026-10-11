use anyhow::{anyhow, Result};
use c35_mod_site::{
    site_granted_iids, site_query_run, stock_report_from_query, stock_report_query_id,
    tx_browse_from_query, tx_browse_query_id,
};
use c35_time_range::timezone_default_from_locale;
use crate::site_query_export::{export_formats_from_params, tx_browse_export_files};
use crate::site_query_present::site_query_llm_compact;
use crate::tx_browse_render::tx_browse_llm_payload;
use serde_json::{json, Value};

use crate::stock_report_run::{formats_from_params, materialize};

use crate::site_scope::site_scope_pick;
use crate::tool;
use crate::tools::ToolContext;

fn json_value_i64(v: &Value) -> Option<i64> {
    v.as_i64()
        .or_else(|| v.as_u64().and_then(|n| i64::try_from(n).ok()))
        .or_else(|| v.as_str().and_then(|s| s.trim().parse().ok()))
}

fn site_iid_from_entry(v: &Value) -> Option<i64> {
    json_value_i64(v).or_else(|| v.get("iid").and_then(json_value_i64))
}

fn args_site_iids(args: &Value) -> Vec<i64> {
    args.get("site_iids")
        .and_then(|v| v.as_array())
        .map(|arr| {
            arr.iter()
                .filter_map(site_iid_from_entry)
                .filter(|i| *i > 0)
                .collect()
        })
        .unwrap_or_default()
}

fn merge_nested_query_params(params: &mut Value) {
    let inner = params.get("params").cloned();
    if let Some(inner) = inner {
        if let Some(obj) = params.as_object_mut() {
            obj.remove("params");
            if let Some(inner_obj) = inner.as_object() {
                for (k, v) in inner_obj {
                    if !obj.contains_key(k) {
                        obj.insert(k.clone(), v.clone());
                    }
                }
            }
        }
    }
}

/// Coerce common LLM wire mistakes (query_id under params, nested params, site_iids objects).
pub fn site_query_args_normalize(args: &Value) -> Value {
    let mut out = args.clone();
    let has_top_qid = out
        .get("query_id")
        .and_then(|v| v.as_str())
        .is_some_and(|s| !s.trim().is_empty());
    if !has_top_qid {
        let lifted = out
            .get("params")
            .and_then(|p| p.get("query_id"))
            .or_else(|| {
                out.get("params")
                    .and_then(|p| p.get("params"))
                    .and_then(|pp| pp.get("query_id"))
            })
            .and_then(|v| v.as_str())
            .map(str::trim)
            .filter(|s| !s.is_empty());
        if let Some(qid) = lifted {
            out["query_id"] = json!(qid);
            if let Some(params) = out.get_mut("params").and_then(|p| p.as_object_mut()) {
                params.remove("query_id");
                if let Some(inner) = params.get_mut("params").and_then(|p| p.as_object_mut()) {
                    inner.remove("query_id");
                }
            }
        }
    }
    if let Some(params) = out.get_mut("params") {
        merge_nested_query_params(params);
    }
    if let Some(arr) = out.get("site_iids").and_then(|v| v.as_array()) {
        let flat: Vec<Value> = arr
            .iter()
            .filter_map(site_iid_from_entry)
            .filter(|i| *i > 0)
            .map(|i| json!(i))
            .collect();
        if !flat.is_empty() {
            out["site_iids"] = json!(flat);
        }
    }
    out
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

fn params_has_time_bounds(params: &Value) -> bool {
    if params
        .get("range")
        .and_then(|v| v.as_str())
        .is_some_and(|s| !s.trim().is_empty())
    {
        return true;
    }
    if params.get("time_from_ms").is_some() || params.get("time_to_ms").is_some() {
        return true;
    }
    if params
        .get("date_from")
        .and_then(|v| v.as_str())
        .is_some_and(|s| !s.trim().is_empty())
    {
        return true;
    }
    if params
        .get("date_to")
        .and_then(|v| v.as_str())
        .is_some_and(|s| !s.trim().is_empty())
    {
        return true;
    }
    false
}

fn params_json_resolve(args: &Value, locale: &str, query_id: &str) -> Result<String> {
    let mut params: Value = if let Some(raw) = args.get("params_json").and_then(|v| v.as_str()) {
        serde_json::from_str(raw)?
    } else if let Some(params) = args.get("params") {
        params.clone()
    } else {
        json!({})
    };
    if params.get("tz").and_then(|v| v.as_str()).unwrap_or("").trim().is_empty() {
        params["tz"] = json!(timezone_default_from_locale(locale));
    }
    if query_id.starts_with("tx.") && !params_has_time_bounds(&params) {
        params["range"] = json!("today");
    }
    Ok(serde_json::to_string(&params)?)
}

fn stock_tool_response(query_id: &str, built_llm: Value) -> Value {
    let blocks = built_llm.get("blocks").cloned().unwrap_or(json!([]));
    let block = blocks
        .as_array()
        .and_then(|a| a.first())
        .cloned()
        .unwrap_or(json!({}));
    let mut llm = built_llm;
    if let Some(obj) = llm.as_object_mut() {
        obj.remove("blocks");
    }
    json!({
        "ok": true,
        "query_id": query_id,
        "llm": llm,
        "block": block,
        "blocks": blocks,
    })
}

pub async fn site_query_run_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let args = site_query_args_normalize(args);
    let query_id = args
        .get("query_id")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .ok_or_else(|| anyhow!("query_id is required"))?;
    let site_iids = site_iids_resolve(ctx, &args).await?;
    let params_json = params_json_resolve(&args, ctx.locale.as_str(), query_id)?;
    let params: Value = serde_json::from_str(&params_json).unwrap_or(json!({}));
    let res = site_query_run(&ctx.pool, ctx.owner_iid, site_iids, query_id, &params_json).await?;
    if stock_report_query_id(query_id) {
        let Some(report) = stock_report_from_query(query_id, &res.rows, &res.result_json) else {
            return Ok(json!({ "ok": false, "query_id": query_id, "error": "stock report failed" }));
        };
        let built = materialize(&ctx.pool, ctx.chat_id, &report, &formats_from_params(&params)).await?;
        return Ok(stock_tool_response(query_id, built.llm));
    }
    if tx_browse_query_id(query_id) {
        let Some(report) =
            tx_browse_from_query(query_id, &res.rows, &res.result_json, ctx.locale.as_str())
        else {
            return Ok(json!({ "ok": false, "query_id": query_id, "error": "tx browse failed" }));
        };
        let (want_pdf, want_xlsx) = export_formats_from_params(&params);
        let file_json = if want_pdf || want_xlsx {
            tx_browse_export_files(ctx, &report, want_pdf, want_xlsx).await?
        } else {
            vec![]
        };
        let llm = tx_browse_llm_payload(&report, &file_json);
        let blocks = crate::tx_browse_render::tx_browse_blocks(&report);
        return Ok(json!({
            "ok": true,
            "query_id": query_id,
            "llm": llm,
            "block": blocks.first().cloned().unwrap_or(json!({})),
        }));
    }
    let llm = site_query_llm_compact(query_id, &res.rows, &res.result_json);
    Ok(json!({
        "ok": true,
        "query_id": query_id,
        "llm": llm,
        "rows": llm.get("sites").cloned().unwrap_or(json!([])),
        "result_json": res.result_json,
    }))
}

tool! {
    struct: SiteQueryRunTool,
    name: "site.query.run",
    aliases: ["site_query_run"],
    description: "Readonly site query catalog. params use DATE RANGE wire: range (today/yesterday/this_week/last_week/this_month/last_month/mtd/ytd), date_from/date_to (YYYY-MM-DD), or time_from_ms/time_to_ms. tx.sales_list filters: limit, open_only, state, q, min_total, max_total. Examples: tx.sales_summary, tx.profit_summary, tx.sales_list, tx.top_products, product.stock.",
    topics: ["site.commerce", "web.builder"],
    rag_phrases: [
        "omzet", "untung", "laba", "transaksi", "daftar transaksi", "penjualan", "terlaris",
        "paling laku", "profit", "sales today", "berapa transaksi", "total transaksi",
        "berapa total transaksi", "jumlah transaksi", "kartu stok", "stok", "dibanding kemarin",
        "max_total", "min_total", "transaksi di bawah",
    ],
    ui_calling_key: "tool.site.query.run.calling",
    ui_done_key: "tool.site.query.run.done",
    readonly: true,
    parameters: {
        query_id: (string, "Query catalog id (e.g. product.list, tx.profit_summary, tx.sales_list)", required),
        site_iids: (array, "Site identity IDs; omit to use all @mentioned sites", optional),
        params: (object, "Query parameters (DATE RANGE + query-specific filters)", optional),
        params_json: (string, "Query parameters as JSON string (alternative to params)", optional),
    },
    execute: |args, ctx| {
        site_query_run_exec(ctx, &args).await
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn normalize_lifts_query_id_from_params() {
        let raw = json!({
            "params": { "query_id": "product.list" },
            "site_iids": [{ "iid": 101 }]
        });
        let n = site_query_args_normalize(&raw);
        assert_eq!(n["query_id"], "product.list");
        assert_eq!(n["site_iids"], json!([101]));
        assert!(n["params"].get("query_id").is_none());
    }

    #[test]
    fn normalize_lifts_nested_params_query_id() {
        let raw = json!({
            "params": {
                "query_id": "tx.top_products",
                "params": { "range": "today" }
            }
        });
        let n = site_query_args_normalize(&raw);
        assert_eq!(n["query_id"], "tx.top_products");
        assert_eq!(n["params"]["range"], "today");
        assert!(n["params"].get("params").is_none());
    }
}
