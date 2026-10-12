use anyhow::Result;
use c35_mod_admin::{require_referral_staff, require_root_or_director};
use c35_mod_file::{storage_usage_account, storage_usage_scope, SingleScopeUsage, StorageUsageReport};
use serde_json::{json, Value};
use sqlx::PgPool;

use crate::tool;
use crate::tools::builtin::staff::{admin_err_json, arg_i64, arg_str, subject_iid_resolve};
use crate::tools::ToolContext;

fn report_json(report: &StorageUsageReport) -> Value {
    json!({
        "billable_owner_iid": report.billable_owner_iid,
        "total_bytes": report.total_bytes,
        "distinct_blob_count": report.distinct_blob_count,
        "scopes_attributed_sum_bytes": report.scopes_attributed_sum_bytes,
        "personal": report.personal,
        "sites": report.sites,
        "bots": report.bots,
        "mailboxes": report.mailboxes,
    })
}

fn single_scope_json(u: &SingleScopeUsage) -> Value {
    json!({
        "scope_kind": u.scope_kind,
        "scope_iid": u.scope_iid,
        "label": u.label,
        "alien_id": u.alien_id,
        "attributed_bytes": u.attributed_bytes,
        "blob_count": u.blob_count,
    })
}

async fn billable_owner_for_account(
    pool: &PgPool,
    ctx: &ToolContext,
    args: &Value,
) -> Result<i64, Value> {
    let subject_uid = arg_i64(args, "subject_uid");
    let subject_handle = arg_str(args, "subject_handle");
    let target = if subject_uid > 0 {
        subject_uid
    } else if !subject_handle.is_empty() {
        subject_iid_resolve(pool, args)
            .await
            .map_err(|e| json!({ "ok": false, "tool": "storage.usage", "error": e }))?
    } else {
        ctx.owner_iid
    };
    if target == ctx.owner_iid {
        return Ok(target);
    }
    if require_referral_staff(pool, ctx.owner_iid).await.is_ok() {
        return Ok(target);
    }
    match require_root_or_director(pool, ctx.owner_iid).await {
        Ok(()) => Ok(target),
        Err(e) => Err(admin_err_json(e)),
    }
}

pub async fn storage_usage_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let scope_raw = arg_str(args, "scope");
    let scope = if scope_raw.is_empty() { "account" } else { scope_raw.as_str() };

    match scope {
        "account" => {
            let owner = match billable_owner_for_account(&ctx.pool, ctx, args).await {
                Ok(v) => v,
                Err(j) => return Ok(j),
            };
            let include_breakdown = args
                .get("include_breakdown")
                .and_then(|v| v.as_bool())
                .unwrap_or(true);
            let report = match storage_usage_account(&ctx.pool, owner, include_breakdown).await {
                Ok(r) => r,
                Err(e) => {
                    return Ok(json!({ "ok": false, "tool": "storage.usage", "error": e.to_string() }));
                }
            };
            Ok(json!({
                "ok": true,
                "tool": "storage.usage",
                "scope": "account",
                "usage": report_json(&report),
            }))
        }
        "site" | "bot" | "mailbox" => {
            let scope_iid = arg_i64(args, &format!("{scope}_iid"));
            if scope_iid <= 0 {
                return Ok(json!({
                    "ok": false,
                    "tool": "storage.usage",
                    "error": format!("{scope}_iid required"),
                }));
            }
            let usage = match storage_usage_scope(&ctx.pool, scope, scope_iid, ctx.owner_iid).await {
                Ok(u) => u,
                Err(e) => {
                    return Ok(json!({ "ok": false, "tool": "storage.usage", "error": e.to_string() }));
                }
            };
            Ok(json!({
                "ok": true,
                "tool": "storage.usage",
                "scope": scope,
                "usage": single_scope_json(&usage),
            }))
        }
        other => Ok(json!({
            "ok": false,
            "tool": "storage.usage",
            "error": format!("unknown scope: {other}"),
        })),
    }
}

tool! {
    struct: StorageUsageTool,
    name: "storage.usage",
    description: "Report file storage attributed to account, site, bot, or mailbox (distinct CAS bytes). Staff may pass subject_uid or subject_handle for another user account scope.",
    topics: ["general", "account", "staff", "site"],
    always: ["general", "account"],
    rag_phrases: [
        "how much storage do I use",
        "berapa storage",
        "storage usage",
        "penyimpanan saya",
    ],
    readonly: true,
    parameters: {
        scope: (string, "account | site | bot | mailbox", optional, default = "account"),
        subject_uid: (integer, "Target user for account scope; 0 = caller", optional, default = 0),
        subject_handle: (string, "Target alien_id for account scope", optional),
        site_iid: (integer, "Site identity id when scope=site", optional),
        bot_iid: (integer, "Bot identity id when scope=bot", optional),
        mailbox_id: (integer, "Mailbox id when scope=mailbox", optional),
        include_breakdown: (boolean, "Per-scope lines for account scope", optional, default = true),
    },
    execute: |args, ctx| storage_usage_exec(ctx, &args).await
}