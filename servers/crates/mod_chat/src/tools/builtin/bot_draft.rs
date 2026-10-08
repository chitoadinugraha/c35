use anyhow::{anyhow, Result};
use c35_mod_identity::identity_put;
use c35_proto::{DataSourceDoc, ReqDataSourcePut, ReqIdentityPut};
use serde_json::{json, Value};
use sqlx::Row;

use crate::bot_draft::{
    draft_summary, flag_true, plan_bot_draft, purpose_clear, sheet_config, BotDraftInput,
    PlannedSheet, SheetIn,
};
use crate::data_source_put;
use crate::tool;
use crate::tools::ToolContext;

fn arg_str(args: &Value, key: &str) -> String {
    args.get(key)
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .trim()
        .to_string()
}

fn arg_i64(args: &Value, key: &str) -> i64 {
    args.get(key)
        .map(|v| {
            v.as_i64()
                .or_else(|| v.as_f64().map(|n| n as i64))
                .or_else(|| v.as_str().and_then(|s| s.parse().ok()))
        })
        .flatten()
        .unwrap_or(0)
}

fn sheets_from_args(args: &Value) -> Vec<SheetIn> {
    let mut out = Vec::new();
    let raw = args.get("sheets").cloned().or_else(|| {
        args.get("sheets_json")
            .and_then(|v| v.as_str())
            .and_then(|s| serde_json::from_str(s).ok())
    });
    if let Some(arr) = raw.as_ref().and_then(|v| v.as_array()) {
        for item in arr {
            let url = item
                .get("url")
                .and_then(|v| v.as_str())
                .unwrap_or("")
                .trim()
                .to_string();
            if url.is_empty() {
                continue;
            }
            out.push(SheetIn {
                url,
                name: item
                    .get("name")
                    .and_then(|v| v.as_str())
                    .unwrap_or("")
                    .trim()
                    .to_string(),
                tab: item
                    .get("tab")
                    .and_then(|v| v.as_str())
                    .unwrap_or("")
                    .trim()
                    .to_string(),
                access_mode: item
                    .get("access_mode")
                    .and_then(|v| v.as_str())
                    .unwrap_or("")
                    .trim()
                    .to_string(),
            });
        }
    }
    let one = arg_str(args, "sheet_url");
    if !one.is_empty() && out.iter().all(|s| s.url != one) {
        out.push(SheetIn {
            url: one,
            name: arg_str(args, "sheet_name"),
            tab: arg_str(args, "sheet_tab"),
            access_mode: arg_str(args, "sheet_access"),
        });
    }
    out
}

async fn bot_row(ctx: &ToolContext, bot_iid: i64) -> Result<(String, String, String)> {
    let row = sqlx::query(
        r#"
        SELECT name, COALESCE(pic, '') AS pic, COALESCE(meta->>'inst_base', '') AS inst_base
        FROM ai.identity
        WHERE id = $1 AND owner_iid = $2 AND kind = 'bot' AND deleted_ts IS NULL
        "#,
    )
    .bind(bot_iid)
    .bind(ctx.owner_iid)
    .fetch_optional(&ctx.pool)
    .await?
    .ok_or_else(|| anyhow!("bot not found"))?;
    Ok((
        row.try_get::<String, _>("name").unwrap_or_default(),
        row.try_get::<String, _>("pic").unwrap_or_default(),
        row.try_get::<String, _>("inst_base").unwrap_or_default(),
    ))
}

async fn attach_sheet(ctx: &ToolContext, bot_iid: i64, sheet: &PlannedSheet) -> Result<i64> {
    let doc = DataSourceDoc {
        id: 0,
        bot_iid,
        source_kind: sheet.source_kind.clone(),
        name: sheet.name.clone(),
        config_json: sheet_config(sheet).to_string(),
        sync_status: String::new(),
        row_count: 0,
        synced_ts_ms: 0,
        updated_ts_ms: 0,
    };
    let res = data_source_put(
        &ctx.pool,
        ctx.owner_iid,
        ReqDataSourcePut { doc: Some(doc) },
    )
    .await?;
    Ok(res.id)
}

fn bot_draft_args(args: &Value) -> (String, String) {
    let mut purpose = arg_str(args, "purpose");
    let mut name = arg_str(args, "name");
    if !name.is_empty() && purpose.eq_ignore_ascii_case(&name) {
        purpose.clear();
    } else if name.is_empty() && !purpose.is_empty() && !purpose_clear(&purpose) {
        name = purpose.clone();
        purpose.clear();
    }
    (purpose, name)
}

pub async fn bot_draft_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let (purpose, name) = bot_draft_args(args);
    let input = BotDraftInput {
        purpose,
        name,
        inst_base: arg_str(args, "inst_base"),
        bot_iid: arg_i64(args, "bot_iid"),
        channel: arg_str(args, "channel"),
        activate: flag_true(&arg_str(args, "activate")),
        web_search: flag_true(&arg_str(args, "web_search")),
        sheets: sheets_from_args(args),
    };
    let mut plan = plan_bot_draft(&input);
    if !plan.create {
        let summary = draft_summary(&plan, &ctx.locale, &[]);
        return Ok(json!({
            "ok": false,
            "ask": plan.ask,
            "summary": summary,
            "pending_urls": plan.pending_urls,
        }));
    }

    let (name, pic, kept_inst) = if input.bot_iid > 0 {
        bot_row(ctx, input.bot_iid).await?
    } else {
        (String::new(), String::new(), String::new())
    };
    if plan.name.is_empty() {
        plan.name = if name.is_empty() {
            "Bot".into()
        } else {
            name.clone()
        };
    }
    if plan.inst_base.is_empty() {
        plan.inst_base = kept_inst;
    }

    let mut meta = json!({});
    if input.bot_iid <= 0 {
        meta["active"] = json!(plan.active);
        meta["inst_base"] = json!(plan.inst_base);
        meta["channels"] = json!([]);
        meta["web_search"] = json!(plan.web_search);
    } else {
        if plan.active {
            meta["active"] = json!(true);
        }
        if !input.inst_base.trim().is_empty()
            || !input.purpose.trim().is_empty() && !plan.inst_base.is_empty()
        {
            meta["inst_base"] = json!(plan.inst_base);
        }
        if plan.web_search {
            meta["web_search"] = json!(true);
        }
    }

    let saved = identity_put(
        &ctx.pool,
        ctx.nats.as_ref(),
        ctx.owner_iid,
        &ctx.req_id,
        ReqIdentityPut {
            iid: input.bot_iid.max(0),
            kind: "bot".into(),
            r#type: "chat".into(),
            name: plan.name.clone(),
            pic,
            alien_id: String::new(),
            meta_json: meta.to_string(),
        },
    )
    .await?;
    let bot_iid = saved
        .row
        .as_ref()
        .and_then(|r| r.identity.as_ref())
        .map(|i| i.iid)
        .ok_or_else(|| anyhow!("bot save failed"))?;

    let mut attached = Vec::new();
    let mut errors = Vec::new();
    for sheet in &plan.sheets {
        match attach_sheet(ctx, bot_iid, sheet).await {
            Ok(id) => attached.push(json!({
                "id": id,
                "name": sheet.name,
                "access_mode": sheet.access_mode,
                "reason": sheet.reason,
                "source_kind": sheet.source_kind,
            })),
            Err(e) => errors.push(format!("{}: {e}", sheet.name)),
        }
    }
    let summary = draft_summary(&plan, &ctx.locale, &plan.sheets);
    let summary = if errors.is_empty() {
        summary
    } else {
        format!("{summary}\n{}", errors.join("\n"))
    };
    Ok(json!({
        "ok": errors.is_empty(),
        "ask": plan.ask,
        "bot_iid": bot_iid,
        "name": plan.name,
        "active": plan.active,
        "channel": plan.channel,
        "inst_base": plan.inst_base,
        "sheets": attached,
        "summary": summary
    }))
}

tool! {
    struct: BotDraftTool,
    name: "bot.draft",
    aliases: ["bot_draft", "bot.create"],
    description: "Draft a chat bot for the owner. Call when the user wants a new bot, sends a sheet link for that draft, or says to turn it on. Pass purpose in the user's words. Pass bot_iid from an earlier bot.draft result when updating. Pass sheets as {url, name, tab, access_mode} for Google Sheet, Doc, or Slide URLs. Omit access_mode unless the user was explicit. Leave activate empty until they say to turn the bot on. Does not connect WhatsApp or Telegram.",
    topics: ["general"],
    rag_phrases: [
        "buat chat bot",
        "bikin chat bot",
        "buat bot",
        "bikin bot",
        "bot baru",
        "create chat bot",
        "create a bot",
        "new bot",
        "bot untuk",
    ],
    ui_calling_key: "tool.bot.draft.calling",
    ui_done_key: "tool.bot.draft.done",
    parameters: {
        purpose: (string, "What the bot should do, in the user's words. Empty if they have not said.", optional, default = ""),
        name: (string, "Bot display name. Empty to let the server name it.", optional, default = ""),
        inst_base: (string, "Replacement instruction. Empty to let the server write it from purpose.", optional, default = ""),
        bot_iid: (integer, "Existing draft bot id. 0 creates a new bot.", optional, default = 0),
        channel: (string, "whatsapp or telegram when the user named one. Empty otherwise.", optional, default = ""),
        activate: (string, "true only when the user says to turn the bot on.", optional, default = ""),
        web_search: (string, "true only when the user wants answers from the web.", optional, default = ""),
        sheet_url: (string, "One Google Sheet, Doc, or Slide URL.", optional, default = ""),
        sheet_name: (string, "Label for sheet_url.", optional, default = ""),
        sheet_tab: (string, "Tab name for sheet_url.", optional, default = ""),
        sheet_access: (string, "read_only or read_write for sheet_url, or empty.", optional, default = ""),
        sheets: (array, "Several sources: {url, name, tab, access_mode}.", optional),
    },
    execute: |args, ctx| {
        bot_draft_exec(ctx, &args).await
    }
}
