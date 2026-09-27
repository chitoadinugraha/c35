use anyhow::{bail, Context, Result};
use c35_mod_data_source::{
    data_source_list_for_bot, data_source_sync_invalidate, google_sheet_config_from_row,
    google_sheet_read_csv, google_sheet_write_append, google_sheet_write_update, sheet_tab_name,
    GoogleSheetConfig, SOURCE_KIND_GOOGLE_SHEET,
};
use serde_json::{json, Value};

use crate::tool;
use crate::tools::context::ToolContext;

async fn bot_iid_for_chat(ctx: &ToolContext) -> Result<i64> {
    let bid: Option<i64> = sqlx::query_scalar(
        "SELECT bot_iid FROM ai.chat WHERE id = $1 AND deleted_ts IS NULL",
    )
    .bind(ctx.chat_id)
    .fetch_optional(&ctx.pool)
    .await?;
    bid.filter(|b| *b > 0)
        .ok_or_else(|| anyhow::anyhow!("gsheet tools require a bot_peer chat"))
}

async fn sheet_bindings(ctx: &ToolContext) -> Result<Vec<GoogleSheetConfig>> {
    let bot_iid = bot_iid_for_chat(ctx).await?;
    let rows = data_source_list_for_bot(&ctx.pool, bot_iid).await?;
    rows.iter()
        .filter(|r| r.source_kind == SOURCE_KIND_GOOGLE_SHEET)
        .map(google_sheet_config_from_row)
        .collect()
}

fn binding_resolve<'a>(bindings: &'a [GoogleSheetConfig], spreadsheet_id: Option<&str>) -> Result<&'a GoogleSheetConfig> {
    let want = spreadsheet_id.map(str::trim).filter(|s| !s.is_empty());
    match want {
        Some(id) => bindings
            .iter()
            .find(|b| b.spreadsheet_id == id)
            .with_context(|| format!("no attached Google Sheet for spreadsheet_id={id}")),
        None if bindings.len() == 1 => Ok(&bindings[0]),
        None if bindings.is_empty() => bail!("no Google Sheets attached to this bot"),
        None => bail!("multiple Google Sheets attached — pass spreadsheet_id"),
    }
}

fn row_from_args(args: &Value) -> Result<Vec<String>> {
    let row = args
        .get("row")
        .or_else(|| args.get("values"))
        .context("row (array of strings) is required")?;
    let items = row.as_array().context("row must be a JSON array of strings")?;
    Ok(items
        .iter()
        .map(|v| match v {
            Value::String(s) => s.clone(),
            Value::Number(n) => n.to_string(),
            Value::Bool(b) => b.to_string(),
            Value::Null => String::new(),
            other => other.to_string(),
        })
        .collect())
}

async fn gsheet_read_exec(args: Value, ctx: &ToolContext) -> Result<Value> {
    let bindings = sheet_bindings(ctx).await?;
    let want = args.get("spreadsheet_id").and_then(|v| v.as_str());
    let cfg = binding_resolve(&bindings, want)?;
    let csv = google_sheet_read_csv(&ctx.http_client, cfg).await?;
    Ok(json!({
        "ok": true,
        "spreadsheet_id": cfg.spreadsheet_id,
        "tab": sheet_tab_name(cfg),
        "gid": cfg.gid,
        "csv": csv,
    }))
}

async fn gsheet_append_exec(args: Value, ctx: &ToolContext) -> Result<Value> {
    let bindings = sheet_bindings(ctx).await?;
    let want = args.get("spreadsheet_id").and_then(|v| v.as_str());
    let cfg = binding_resolve(&bindings, want)?;
    let row = row_from_args(&args)?;
    if row.is_empty() {
        bail!("row must not be empty");
    }
    let api_res = google_sheet_write_append(cfg, row).await?;
    data_source_sync_invalidate(&ctx.pool, cfg.data_source_id).await;
    Ok(json!({
        "ok": true,
        "spreadsheet_id": cfg.spreadsheet_id,
        "tab": sheet_tab_name(cfg),
        "result": api_res,
    }))
}

async fn gsheet_update_exec(args: Value, ctx: &ToolContext) -> Result<Value> {
    let bindings = sheet_bindings(ctx).await?;
    let want = args.get("spreadsheet_id").and_then(|v| v.as_str());
    let cfg = binding_resolve(&bindings, want)?;
    let range = args.get("range").and_then(|v| v.as_str()).unwrap_or("").trim();
    if range.is_empty() {
        bail!("range is required");
    }
    let row = row_from_args(&args)?;
    if row.is_empty() {
        bail!("row must not be empty");
    }
    let api_res = google_sheet_write_update(cfg, range, row).await?;
    data_source_sync_invalidate(&ctx.pool, cfg.data_source_id).await;
    Ok(json!({
        "ok": true,
        "spreadsheet_id": cfg.spreadsheet_id,
        "tab": sheet_tab_name(cfg),
        "range": range,
        "result": api_res,
    }))
}

tool! {
    struct: GsheetReadTool,
    name: "gsheet.read",
    aliases: ["gsheet_read"],
    description: "Read a linked Google Sheet as CSV. Uses the bot's attached Google Sheet data source.",
    topics: ["bot"],
    parameters: {
        spreadsheet_id: (string, "Spreadsheet id. Omit when only one sheet is attached.", optional),
    },
    execute: |args, ctx| {
        gsheet_read_exec(args, ctx).await
    }
}

tool! {
    struct: GsheetAppendTool,
    name: "gsheet.append",
    aliases: ["gsheet_append"],
    description: "Append a row to a linked Google Sheet (requires service account + sheet shared as Anyone with the link can edit).",
    topics: ["bot"],
    parameters: {
        spreadsheet_id: (string, "Spreadsheet id. Omit when only one sheet is attached.", optional),
        row: (array, "Cell values for the new row.", required),
    },
    execute: |args, ctx| {
        gsheet_append_exec(args, ctx).await
    }
}

tool! {
    struct: GsheetUpdateTool,
    name: "gsheet.update",
    aliases: ["gsheet_update"],
    description: "Update a cell range on a linked Google Sheet, e.g. A2:B2.",
    topics: ["bot"],
    parameters: {
        spreadsheet_id: (string, "Spreadsheet id. Omit when only one sheet is attached.", optional),
        range: (string, "A1 notation within the tab, e.g. A2 or A2:C2.", required),
        row: (array, "Cell values for the range.", required),
    },
    execute: |args, ctx| {
        gsheet_update_exec(args, ctx).await
    }
}