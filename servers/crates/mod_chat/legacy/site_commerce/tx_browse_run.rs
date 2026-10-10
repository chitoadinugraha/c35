use anyhow::Result;
use c35_mod_billing::billing_cost_usd;
use c35_mod_file::cas_put;
use c35_mod_site::{site_granted_iids, site_query_run, tx_browse_from_query, TxBrowseReport, TX_EXPORT_CAP};
use serde_json::{json, Value};
use tokio_util::sync::CancellationToken;

use crate::prompt::llm_route::llm_stream_chain;
use crate::prompt::ChatRes;
use crate::stock_report::StockReportFormat;
use crate::stock_report_render::StockReportFile;
use crate::tools::TurnCtx;
use crate::turn_tracer::TurnTracer;
use crate::tx_browse::tx_browse_parse;
use crate::tx_browse_copy::{tx_browse_coach_fallback, tx_browse_plain_error};
use crate::tx_browse_render::{
    tx_browse_blocks, tx_browse_export_headers, tx_browse_export_rows, tx_browse_llm_payload,
};
use crate::site_scope::site_scope_pick;

pub struct TxBrowseBuilt {
    pub blocks_json: String,
    pub llm: Value,
    pub report: TxBrowseReport,
}

pub async fn tx_browse_cluster_turn(
    ctx: &mut TurnCtx<'_>,
    user_text: &str,
    system: &str,
    model: &str,
    thinking: &str,
    contents: &[Value],
    on_delta: &mut (dyn FnMut(bool, String) + Send),
    on_blocks: &mut (dyn FnMut(String) + Send),
    cancel: &CancellationToken,
    tracer: Option<&TurnTracer>,
) -> Result<Option<ChatRes>> {
    let built = match tx_browse_prepare(ctx, user_text).await? {
        Some(b) => b,
        None => return Ok(None),
    };
    on_blocks(built.blocks_json.clone());

    let summarize_system = format!(
        "{system}\n\n[TX LIST] The UI already shows a transaction table block. Reply in the same language as the user's latest message (Indonesian if they wrote Indonesian). Write one to three short sentences: period, site name when known, transaction count, total revenue (use normal IDR grouping in prose). Do not list individual transactions or repeat table rows. If truncated is true or files are attached, mention the file download."
    );
    let llm_json = serde_json::to_string_pretty(&built.llm).unwrap_or_else(|_| "{}".into());
    let mut turn_contents = contents.to_vec();
    turn_contents.push(json!({
        "role": "user",
        "parts": [{ "text": format!("[Server: tx.sales_list loaded for chat UI]\n{llm_json}") }]
    }));

    let hop_started = std::time::Instant::now();
    let (out, _provider, _) = llm_stream_chain(
        model,
        &turn_contents,
        &json!([]),
        thinking,
        &summarize_system,
        "AUTO",
        on_delta,
        cancel,
    )
    .await?;
    let hop_ms = hop_started.elapsed().as_millis() as i64;
    if let Some(tr) = tracer {
        let hop_cost = billing_cost_usd(model, out.in_tok, out.out_tok);
        tr.llm_call(1, model, out.in_tok, out.out_tok, hop_ms, hop_cost, &out.text)
            .await;
    }

    let text = if out.text.trim().is_empty() {
        tx_browse_coach_fallback(&built.report, ctx.locale)
    } else {
        out.text
    };

    Ok(Some(ChatRes {
        text,
        blocks_json: built.blocks_json,
        tokens_in: out.in_tok,
        tokens_out: out.out_tok,
        model_used: format!("tx_browse+{}", model),
        ..ChatRes::default()
    }))
}

pub async fn tx_browse_prepare(ctx: &TurnCtx<'_>, user_text: &str) -> Result<Option<TxBrowseBuilt>> {
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
        _ => return Ok(None),
    };
    let want_pdf = intent.formats.iter().any(|f| *f == StockReportFormat::Pdf);
    let want_xlsx = intent.formats.iter().any(|f| *f == StockReportFormat::Xlsx);
    let export = want_pdf || want_xlsx;
    let limit = if export {
        TX_EXPORT_CAP as i32
    } else {
        intent.limit
    };
    let mut params = json!({
        "range": intent.range,
        "limit": limit,
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
    let Some(report) =
        tx_browse_from_query(intent.query_id, &res.rows, &res.result_json, ctx.locale)
    else {
        return Ok(None);
    };
    let file_json = if export {
        upload_export_files(ctx, &report, want_pdf, want_xlsx).await?
    } else {
        vec![]
    };
    let llm = tx_browse_llm_payload(&report, &file_json);
    let blocks = tx_browse_blocks(&report);
    Ok(Some(TxBrowseBuilt {
        blocks_json: serde_json::to_string(&blocks).unwrap_or_else(|_| "[]".into()),
        llm,
        report,
    }))
}

pub async fn tx_browse_prefetch(ctx: &TurnCtx<'_>, user_text: &str) -> Result<Option<ChatRes>> {
    let mentioned = ctx.mention.site_iids();
    let granted = if mentioned.is_empty() {
        site_granted_iids(ctx.pool, ctx.owner_iid).await.unwrap_or_default()
    } else {
        Vec::new()
    };
    if site_scope_pick(&mentioned, &granted, &[]).ok().filter(|ids| !ids.is_empty()).is_none() {
        if tx_browse_parse(user_text).is_some() {
            let msg = tx_browse_plain_error("no_site", ctx.locale);
            return Ok(Some(plain_res(&msg)));
        }
    }
    Ok(None)
}

async fn upload_export_files(
    ctx: &TurnCtx<'_>,
    report: &TxBrowseReport,
    want_pdf: bool,
    want_xlsx: bool,
) -> Result<Vec<Value>> {
    if report.rows.is_empty() {
        return Ok(vec![]);
    }
    let headers = tx_browse_export_headers(ctx.locale);
    let rows = tx_browse_export_rows(report, ctx.locale);
    let ym = chrono::Utc::now().format("%Y%m");
    let secret = cas_secret();
    let dir = c35_mod_file::cas_dir_default();
    let mut file_json = Vec::new();
    if want_pdf {
        let file = StockReportFile {
            name: format!("tx-sales-{ym}.pdf"),
            mime: "application/pdf".to_string(),
            bytes: c35_mod_file::report_pdf(&report.title, &headers, &rows, report.truncated),
        };
        let put = cas_put(ctx.pool, &dir, &secret, &file.bytes, &file.mime).await?;
        file_json.push(json!({ "hash": put.hash, "name": file.name, "mime": file.mime }));
    }
    if want_xlsx {
        let file = StockReportFile {
            name: format!("tx-sales-{ym}.xlsx"),
            mime: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".to_string(),
            bytes: c35_mod_file::report_xlsx(&headers, &rows),
        };
        let put = cas_put(ctx.pool, &dir, &secret, &file.bytes, &file.mime).await?;
        file_json.push(json!({ "hash": put.hash, "name": file.name, "mime": file.mime }));
    }
    Ok(file_json)
}

fn cas_secret() -> String {
    ["CAS_HMAC_SECRET", "C35_JWT_SECRET", "AGENT_SECRET_KEY"]
        .into_iter()
        .find_map(|k| std::env::var(k).ok())
        .unwrap_or_default()
}

fn plain_res(text: &str) -> ChatRes {
    ChatRes {
        text: text.to_string(),
        model_used: "tx_browse".into(),
        ..ChatRes::default()
    }
}
