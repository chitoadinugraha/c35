use anyhow::{anyhow, Result};
use c35_mod_tx::enum_map::{tx_state_from_str, tx_type_from_str};
use c35_mod_tx::{
    tx_debt_pay, tx_debt_payment_json_parse, tx_json_parse, tx_list, tx_preview, tx_put,
    tx_result_json, tx_to_json,
};
use c35_proto::{
    ReqTxDebtPay, ReqTxList, ReqTxPreview, ReqTxPut, TxInputSource, TxState, TxType,
};
use serde_json::{json, Value};

use crate::mention_context::site_iid_resolve as mention_site_iid_resolve;
use crate::tool;
use crate::tools::ToolContext;

fn site_iid_resolve(ctx: &ToolContext, args: &Value) -> Result<i64> {
    mention_site_iid_resolve(
        &ctx.mention,
        ctx.site_iid,
        args.get("site_iid").and_then(|v| v.as_i64()),
    )
}

fn tx_type_resolve(args: &Value) -> i32 {
    match args.get("type").and_then(|v| v.as_str()) {
        Some(s) => i32::from(tx_type_from_str(s)),
        _ => i32::from(TxType::Sale),
    }
}

fn tx_state_resolve(args: &Value) -> i32 {
    match args.get("state").and_then(|v| v.as_str()) {
        Some(s) => i32::from(tx_state_from_str(s)),
        _ => i32::from(TxState::Ok),
    }
}

pub async fn site_tx_put_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let mut tx = tx_json_parse(args)?;
    tx.site_iid = site_iid;
    if tx.input_source == 0 {
        tx.input_source = i32::from(TxInputSource::Ai);
    }
    let res = tx_put(
        &ctx.pool,
        ctx.owner_iid,
        ReqTxPut { tx: Some(tx) },
        None,
    )
    .await?;
    let tx = res.tx.ok_or_else(|| anyhow!("tx not returned"))?;
    Ok(tx_result_json(&tx))
}

pub async fn site_tx_preview_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let mut tx = tx_json_parse(args)?;
    tx.site_iid = site_iid;
    let res = tx_preview(
        &ctx.pool,
        ctx.owner_iid,
        ReqTxPreview { tx: Some(tx) },
    )
    .await?;
    let tx = res.tx.ok_or_else(|| anyhow!("tx not returned"))?;
    Ok(json!({
        "ok": true,
        "site_iid": tx.site_iid,
        "tx_id": tx.tx_id,
        "total": tx.total,
        "coa_name": res.coa_name,
        "tx": tx_to_json(&tx),
    }))
}

pub async fn site_tx_debt_pay_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let tx_id = args
        .get("tx_id")
        .and_then(|v| v.as_i64())
        .filter(|i| *i > 0)
        .ok_or_else(|| anyhow!("tx_id is required"))?;
    let payment = tx_debt_payment_json_parse(args)?;
    let res = tx_debt_pay(
        &ctx.pool,
        ctx.owner_iid,
        ReqTxDebtPay {
            site_iid,
            tx_id,
            payment: Some(payment),
        },
        None,
    )
    .await?;
    let tx = res.tx.ok_or_else(|| anyhow!("tx not returned"))?;
    Ok(tx_result_json(&tx))
}

pub async fn site_tx_list_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let res = tx_list(
        &ctx.pool,
        ctx.owner_iid,
        ReqTxList {
            site_iid,
            q: args.get("q").and_then(|v| v.as_str()).unwrap_or("").into(),
            after_tx_id: args.get("after_tx_id").and_then(|v| v.as_i64()).unwrap_or(0),
            limit: args.get("limit").and_then(|v| v.as_i64()).unwrap_or(50) as i32,
            include_archived: args.get("include_archived").and_then(|v| v.as_bool()).unwrap_or(false),
            r#type: tx_type_resolve(args),
            state: tx_state_resolve(args),
            subject_contact_id: args
                .get("subject_contact_id")
                .and_then(|v| v.as_i64())
                .unwrap_or(0),
            time_from_ms: args.get("time_from_ms").and_then(|v| v.as_i64()).unwrap_or(0),
            time_to_ms: args.get("time_to_ms").and_then(|v| v.as_i64()).unwrap_or(0),
            open_only: args.get("open_only").and_then(|v| v.as_bool()).unwrap_or(false),
        },
    )
    .await?;
    let txs = res.txs.iter().map(tx_to_json).collect::<Vec<_>>();
    Ok(json!({
        "ok": true,
        "site_iid": site_iid,
        "txs": txs,
        "count": txs.len(),
    }))
}

tool! {
    struct: SiteTxPutTool,
    name: "site.tx.put",
    aliases: ["site_tx_put"],
    description: "Create or update a POS transaction (sale, purchase, …) for one site. Pass full tx object with items and payments.",
    topics: ["site.commerce"],
    requires_kinds: ["site"],
    requires_capability: "commerce",
    ui_calling_key: "tool.site.tx.put.calling",
    ui_done_key: "tool.site.tx.put.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @site when exactly one mentioned)", optional),
        tx_json: (string, "Full Tx JSON string", optional),
        tx: (object, "Full Tx object (alternative to tx_json)", optional),
    },
    execute: |args, ctx| {
        site_tx_put_exec(ctx, &args).await
    }
}

tool! {
    struct: SiteTxPreviewTool,
    name: "site.tx.preview",
    aliases: ["site_tx_preview"],
    description: "Dry-run transaction totals, stock, and COA names without saving.",
    topics: ["site.commerce"],
    requires_kinds: ["site"],
    requires_capability: "commerce",
    ui_calling_key: "tool.site.tx.preview.calling",
    ui_done_key: "tool.site.tx.preview.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @site when exactly one mentioned)", optional),
        tx_json: (string, "Full Tx JSON string", optional),
        tx: (object, "Full Tx object (alternative to tx_json)", optional),
    },
    execute: |args, ctx| {
        site_tx_preview_exec(ctx, &args).await
    }
}

tool! {
    struct: SiteTxDebtPayTool,
    name: "site.tx.debt_pay",
    aliases: ["site_tx_debt_pay"],
    description: "Apply a debt installment payment to an existing transaction.",
    topics: ["site.commerce"],
    requires_kinds: ["site"],
    requires_capability: "commerce",
    ui_calling_key: "tool.site.tx.debt_pay.calling",
    ui_done_key: "tool.site.tx.debt_pay.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @site when exactly one mentioned)", optional),
        tx_id: (integer, "Transaction ID", required),
        payment: (object, "Debt payment {method, amount, note, ts_ms}", optional),
        payment_json: (string, "Debt payment JSON string (alternative to payment)", optional),
    },
    execute: |args, ctx| {
        site_tx_debt_pay_exec(ctx, &args).await
    }
}

tool! {
    struct: SiteTxListTool,
    name: "site.tx.list",
    aliases: ["site_tx_list"],
    description: "List transactions for one site (readonly browse).",
    topics: ["site.commerce"],
    requires_kinds: ["site"],
    requires_capability: "commerce",
    ui_calling_key: "tool.site.tx.list.calling",
    ui_done_key: "tool.site.tx.list.done",
    readonly: true,
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @site when exactly one mentioned)", optional),
        q: (string, "Search description", optional),
        limit: (integer, "Max rows (default 50, max 200)", optional),
        type: (string, "Filter by tx type (sale, purchase, …)", optional),
        state: (string, "Filter by state (ok, draft, …)", optional),
        open_only: (boolean, "Only open sales", optional),
        after_tx_id: (integer, "Pagination cursor", optional),
        time_from_ms: (integer, "Time range start (epoch ms)", optional),
        time_to_ms: (integer, "Time range end (epoch ms)", optional),
        subject_contact_id: (integer, "Filter by contact", optional),
        include_archived: (boolean, "Include archived rows", optional),
    },
    execute: |args, ctx| {
        site_tx_list_exec(ctx, &args).await
    }
}
