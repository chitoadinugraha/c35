use anyhow::Result;
use c35_mod_admin::{admin_user_search, require_referral_staff, require_root, AdminError};
use c35_mod_billing::{
    billing_topup_list, billing_topup_review, commission_withdraw_list, commission_withdraw_review,
};
use c35_mod_device::{mcp_client_list, mcp_device_list};
use c35_mod_referral::{referral_commission_simulate, referral_user_stats};
use c35_mod_task::task_list_rpc;
use c35_proto::{
    BillingTopupQueueItem, CommissionWithdrawQueueItem, ReferralCommissionLevel,
    ReqAdminUserSearch, ReqBillingTopupList, ReqBillingTopupReview, ReqCommissionWithdrawList,
    ReqCommissionWithdrawReview, ReqReferralUserStats, ReqTaskList, Task,
};
use serde_json::{json, Value};
use sqlx::Row;

use crate::chat_history::{chat_messages, chat_search, ChatHistoryQuery};
use crate::tool;
use crate::tools::ToolContext;

pub(crate) fn arg_str(args: &Value, key: &str) -> String {
    args.get(key)
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .trim()
        .to_string()
}

pub(crate) fn arg_i64(args: &Value, key: &str) -> i64 {
    match args.get(key) {
        Some(Value::String(s)) => s.trim().parse().unwrap_or(0),
        Some(Value::Number(n)) => n.as_i64().unwrap_or(0),
        _ => 0,
    }
}

pub(crate) async fn subject_iid_resolve(pool: &sqlx::PgPool, args: &Value) -> Result<i64, String> {
    let uid = arg_i64(args, "subject_uid");
    if uid > 0 {
        return Ok(uid);
    }
    let handle = arg_str(args, "subject_handle").to_lowercase();
    if handle.is_empty() {
        return Err("subject_uid or subject_handle required".into());
    }
    let row: Option<i64> = sqlx::query_scalar(
        r#"
        SELECT id FROM ai.identity
        WHERE deleted_ts IS NULL AND kind = 'user'
          AND (lower(alien_id) = $1 OR CAST(id AS TEXT) = $1)
        LIMIT 1
        "#,
    )
    .bind(&handle)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    row.ok_or_else(|| format!("user not found: {handle}"))
}

pub(crate) async fn require_root_json(ctx: &ToolContext, tool: &str) -> Result<(), Value> {
    match require_root(&ctx.pool, ctx.owner_iid).await {
        Ok(()) => Ok(()),
        Err(e) => Err(json!({
            "ok": false,
            "tool": tool,
            "error": e.message,
            "status_code": e.status_code,
        })),
    }
}

async fn require_staff_json(ctx: &ToolContext, tool: &str) -> Result<(), Value> {
    match require_referral_staff(&ctx.pool, ctx.owner_iid).await {
        Ok(()) => Ok(()),
        Err(e) => Err(json!({
            "ok": false,
            "tool": tool,
            "error": e.message,
            "status_code": e.status_code,
        })),
    }
}

fn task_doc_json(t: &Task) -> Value {
    json!({
        "id": t.id,
        "device_iid": t.device_iid,
        "name": t.name,
        "skill_id": t.skill_id,
        "model": t.model,
        "is_active": t.is_active,
        "prompt": t.prompt,
        "created_ts_ms": t.created_ts_ms,
        "updated_ts_ms": t.updated_ts_ms,
    })
}

fn admin_chat_history_query(ctx: &ToolContext, args: &Value, subject_iid: i64) -> ChatHistoryQuery {
    ChatHistoryQuery {
        owner_iid: subject_iid,
        current_chat_id: 0,
        query: arg_str(args, "query"),
        since: arg_str(args, "since"),
        until: arg_str(args, "until"),
        chat_id: arg_i64(args, "chat_id"),
        limit: arg_i64(args, "limit"),
        locale: ctx.locale.clone(),
        user_text: ctx.user_text.clone(),
    }
}

pub(crate) fn admin_err_json(e: AdminError) -> Value {
    json!({
        "ok": false,
        "tool": "admin",
        "error": e.message,
        "status_code": e.status_code,
    })
}

fn commission_level_json(l: &ReferralCommissionLevel) -> Value {
    json!({
        "identity_id": l.identity_id,
        "name": l.name,
        "avatar_url": l.avatar_url,
        "percent": l.percent,
        "earn_amount": l.earn_amount,
        "pool_share_percent": l.pool_share_percent,
    })
}

fn billing_topup_queue_json(r: &BillingTopupQueueItem) -> Value {
    json!({
        "request_id": r.request_id,
        "owner_iid": r.owner_iid,
        "amount_idr": r.amount_idr,
        "amount_usd": r.amount_usd,
        "proof_url": r.proof_url,
        "status": r.status,
        "created_ts_ms": r.created_ts_ms,
        "user_name": r.user_name,
        "user_pic": r.user_pic,
        "user_handle": r.user_handle,
        "reject_reason": r.reject_reason,
        "reviewed_by_iid": r.reviewed_by_iid,
        "reviewer_name": r.reviewer_name,
        "reviewer_pic": r.reviewer_pic,
        "receive_bank_id": r.receive_bank_id,
        "receive_account_number": r.receive_account_number,
        "receive_account_name": r.receive_account_name,
    })
}

fn commission_withdraw_queue_json(r: &CommissionWithdrawQueueItem) -> Value {
    json!({
        "request_id": r.request_id,
        "owner_iid": r.owner_iid,
        "amount_usd": r.amount_usd,
        "amount_idr": r.amount_idr,
        "currency": r.currency,
        "payout_method": r.payout_method,
        "bank_id": r.bank_id,
        "bank_short_name": r.bank_short_name,
        "account_number": r.account_number,
        "account_name": r.account_name,
        "note": r.note,
        "transfer_proof_url": r.transfer_proof_url,
        "status": r.status,
        "created_ts_ms": r.created_ts_ms,
        "user_name": r.user_name,
        "user_pic": r.user_pic,
        "decline_reason": r.decline_reason,
        "reviewed_by_iid": r.reviewed_by_iid,
        "reviewer_name": r.reviewer_name,
        "reviewer_pic": r.reviewer_pic,
    })
}

fn finance_err_json(tool: &str, e: c35_mod_billing::FinanceError) -> Value {
    json!({
        "ok": false,
        "tool": tool,
        "error": e.message,
        "status_code": e.status_code,
    })
}

pub async fn admin_user_search_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let query = args
        .get("query")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .trim();
    let limit = args.get("limit").and_then(|v| v.as_i64()).unwrap_or(20) as i32;
    let req = ReqAdminUserSearch {
        query: query.to_string(),
        limit,
    };
    match admin_user_search(&ctx.pool, ctx.owner_iid, req).await {
        Ok(res) => Ok(json!({
            "ok": true,
            "tool": "admin.user.search",
            "users": res.users.iter().map(|u| json!({
                "identity_id": u.identity_id,
                "name": u.name,
                "email": u.email,
                "avatar_url": u.avatar_url,
                "handle": u.handle,
            })).collect::<Vec<_>>(),
        })),
        Err(e) => Ok(admin_err_json(e)),
    }
}

pub async fn referral_user_stats_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let subject_uid = args
        .get("subject_uid")
        .and_then(|v| v.as_i64())
        .unwrap_or(0);
    let req = ReqReferralUserStats {
        subject_uid,
        col_a: None,
        col_b: None,
    };
    match referral_user_stats(&ctx.pool, ctx.owner_iid, req).await {
        Ok(res) => {
            let wallet = res.wallet.map(|w| {
                json!({
                    "balance_idr": w.balance_idr,
                    "balance_usd": w.balance_usd,
                    "commission_available_idr": w.commission_available_idr,
                    "commission_available_usd": w.commission_available_usd,
                    "billing_currency": w.billing_currency,
                })
            });
            Ok(json!({
                "ok": true,
                "tool": "referral.user.stats",
                "subject_uid": if subject_uid > 0 { subject_uid } else { ctx.owner_iid },
                "wallet": wallet,
                "auth_email": res.auth_email,
                "auth_phone": res.auth_phone,
            }))
        }
        Err(e) => Ok(json!({ "ok": false, "tool": "referral.user.stats", "error": e })),
    }
}

pub async fn referral_commission_simulate_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let subject_uid = args
        .get("subject_uid")
        .and_then(|v| v.as_i64())
        .unwrap_or(0);
    let purchase_amount = args
        .get("purchase_amount")
        .and_then(|v| v.as_i64())
        .unwrap_or(0);
    match referral_commission_simulate(&ctx.pool, ctx.owner_iid, subject_uid, purchase_amount).await
    {
        Ok(res) => Ok(json!({
            "ok": true,
            "tool": "referral.commission.simulate",
            "purchase_amount": res.purchase_amount,
            "pool_amount": res.pool_amount,
            "pool_rate": res.pool_rate,
            "levels": res.levels.iter().map(commission_level_json).collect::<Vec<_>>(),
            "total_distributed": res.total_distributed,
            "undistributed": res.undistributed,
        })),
        Err(e) => Ok(json!({ "ok": false, "tool": "referral.commission.simulate", "error": e })),
    }
}

pub async fn billing_topup_list_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let status = args
        .get("status")
        .and_then(|v| v.as_str())
        .unwrap_or("pending")
        .to_string();
    let limit = args.get("limit").and_then(|v| v.as_i64()).unwrap_or(50) as i32;
    let req = ReqBillingTopupList { status, limit };
    match billing_topup_list(&ctx.pool, ctx.owner_iid, req).await {
        Ok(res) => Ok(json!({
            "ok": true,
            "tool": "billing.topup.list",
            "requests": res.requests.iter().map(billing_topup_queue_json).collect::<Vec<_>>(),
        })),
        Err(e) => Ok(finance_err_json("billing.topup.list", e)),
    }
}

pub async fn billing_topup_review_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let request_id = args.get("request_id").and_then(|v| v.as_i64()).unwrap_or(0);
    let action = args
        .get("action")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();
    let reason = args
        .get("reject_reason")
        .or_else(|| args.get("reason"))
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();
    let req = ReqBillingTopupReview {
        request_id,
        action,
        reason,
    };
    match billing_topup_review(&ctx.pool, ctx.owner_iid, req).await {
        Ok(_) => {
            Ok(json!({ "ok": true, "tool": "billing.topup.review", "request_id": request_id }))
        }
        Err(e) => Ok(finance_err_json("billing.topup.review", e)),
    }
}

pub async fn billing_withdraw_list_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let status = args
        .get("status")
        .and_then(|v| v.as_str())
        .unwrap_or("pending")
        .to_string();
    let limit = args.get("limit").and_then(|v| v.as_i64()).unwrap_or(50) as i32;
    let req = ReqCommissionWithdrawList { status, limit };
    match commission_withdraw_list(&ctx.pool, ctx.owner_iid, req).await {
        Ok(res) => Ok(json!({
            "ok": true,
            "tool": "billing.withdraw.list",
            "requests": res.requests.iter().map(commission_withdraw_queue_json).collect::<Vec<_>>(),
        })),
        Err(e) => Ok(finance_err_json("billing.withdraw.list", e)),
    }
}

pub async fn billing_withdraw_review_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let request_id = args.get("request_id").and_then(|v| v.as_i64()).unwrap_or(0);
    let action = args
        .get("action")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();
    let reason = args
        .get("decline_reason")
        .or_else(|| args.get("reason"))
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();
    let transfer_proof_url = args
        .get("transfer_proof_url")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();
    let req = ReqCommissionWithdrawReview {
        request_id,
        action,
        reason,
        transfer_proof_url,
    };
    match commission_withdraw_review(&ctx.pool, ctx.owner_iid, req).await {
        Ok(_) => {
            Ok(json!({ "ok": true, "tool": "billing.withdraw.review", "request_id": request_id }))
        }
        Err(e) => Ok(finance_err_json("billing.withdraw.review", e)),
    }
}

tool! {
    struct: AdminUserSearchTool,
    name: "admin.user.search",
    description: "Search users by name, email, handle, or numeric id (referral staff). Examples: cari user Alice, search user chito, find uid 99000.",
    topics: ["staff", "referral"],
    always: ["general", "staff"],
    requires_global_roles: ["partner", "director"],
    readonly: true,
    parameters: {
        query: (string, "Name, email, handle, or identity id", required),
        limit: (integer, "Max hits 1-50", optional, default = 20),
    },
    execute: |args, ctx| admin_user_search_exec(ctx, &args).await
}

tool! {
    struct: ReferralUserStatsStaffTool,
    name: "referral.user.stats",
    description: "Wallet balance, commission available, and referral counts for a user (self or staff viewing another uid). Examples: cek saldo user 12345, balance for @alice, komisi tersedia uid 99000.",
    topics: ["staff", "referral", "billing"],
    always: ["general", "staff"],
    requires_global_roles: ["partner", "director", "finance"],
    readonly: true,
    parameters: {
        subject_uid: (integer, "Target identity id; 0 = caller", optional, default = 0),
    },
    execute: |args, ctx| referral_user_stats_exec(ctx, &args).await
}

tool! {
    struct: ReferralCommissionSimulateTool,
    name: "referral.commission.simulate",
    description: "Simulate upline commission split for a purchase amount (wide forest staff). Examples: simulasi komisi pembelian 500000 uid 12345, commission simulate purchase 100 USD user 99000.",
    topics: ["staff", "referral", "billing"],
    always: ["general", "staff"],
    requires_global_roles: ["partner", "director"],
    readonly: true,
    parameters: {
        subject_uid: (integer, "Buyer identity id; 0 = caller", optional, default = 0),
        purchase_amount: (integer, "Purchase amount in IDR (or platform unit)", required),
    },
    execute: |args, ctx| referral_commission_simulate_exec(ctx, &args).await
}

tool! {
    struct: BillingTopupListTool,
    name: "billing.topup.list",
    description: "List manual wallet top-up queue (finance staff). status: pending, history, or all.",
    topics: ["staff", "billing"],
    always: ["general", "staff"],
    requires_global_roles: ["finance", "director", "partner", "marketing"],
    readonly: true,
    parameters: {
        status: (string, "pending | history | all", optional, default = "pending"),
        limit: (integer, "Max rows", optional, default = 50),
    },
    execute: |args, ctx| billing_topup_list_exec(ctx, &args).await
}

tool! {
    struct: BillingTopupReviewTool,
    name: "billing.topup.review",
    description: "Approve or reject a manual top-up request (finance review staff). action: approve | reject.",
    topics: ["staff", "billing"],
    always: ["staff"],
    requires_global_roles: ["finance", "director"],
    parameters: {
        request_id: (integer, "Top-up request id", required),
        action: (string, "approve or reject", required),
        reject_reason: (string, "Required when rejecting", optional),
    },
    execute: |args, ctx| billing_topup_review_exec(ctx, &args).await
}

tool! {
    struct: BillingWithdrawListTool,
    name: "billing.withdraw.list",
    description: "List commission withdrawal requests (finance staff). status: pending, history, or all.",
    topics: ["staff", "billing"],
    always: ["general", "staff"],
    requires_global_roles: ["finance", "director", "partner", "marketing"],
    readonly: true,
    parameters: {
        status: (string, "pending | history | all", optional, default = "pending"),
        limit: (integer, "Max rows", optional, default = 50),
    },
    execute: |args, ctx| billing_withdraw_list_exec(ctx, &args).await
}

tool! {
    struct: BillingWithdrawReviewTool,
    name: "billing.withdraw.review",
    description: "Approve or decline a commission withdrawal (finance review). action: approve | decline.",
    topics: ["staff", "billing"],
    always: ["staff"],
    requires_global_roles: ["finance", "director"],
    parameters: {
        request_id: (integer, "Withdrawal request id", required),
        action: (string, "approve or decline", required),
        decline_reason: (string, "Required when declining", optional),
        transfer_proof_url: (string, "Proof URL when approving", optional),
    },
    execute: |args, ctx| billing_withdraw_review_exec(ctx, &args).await
}

pub async fn admin_chat_search_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    if let Err(v) = require_root_json(ctx, "admin.chat.search").await {
        return Ok(v);
    }
    let subject_iid = match subject_iid_resolve(&ctx.pool, args).await {
        Ok(id) => id,
        Err(e) => return Ok(json!({ "ok": false, "tool": "admin.chat.search", "error": e })),
    };
    let q = admin_chat_history_query(ctx, args, subject_iid);
    match chat_search(&ctx.pool, &q).await {
        Ok(mut v) => {
            if let Some(obj) = v.as_object_mut() {
                obj.insert("tool".into(), json!("admin.chat.search"));
                obj.insert("subject_uid".into(), json!(subject_iid));
            }
            Ok(v)
        }
        Err(e) => Ok(json!({ "ok": false, "tool": "admin.chat.search", "error": e })),
    }
}

pub async fn admin_chat_messages_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    if let Err(v) = require_root_json(ctx, "admin.chat.messages").await {
        return Ok(v);
    }
    let subject_iid = match subject_iid_resolve(&ctx.pool, args).await {
        Ok(id) => id,
        Err(e) => return Ok(json!({ "ok": false, "tool": "admin.chat.messages", "error": e })),
    };
    let q = admin_chat_history_query(ctx, args, subject_iid);
    match chat_messages(&ctx.pool, &q).await {
        Ok(mut v) => {
            if let Some(obj) = v.as_object_mut() {
                obj.insert("tool".into(), json!("admin.chat.messages"));
                obj.insert("subject_uid".into(), json!(subject_iid));
            }
            Ok(v)
        }
        Err(e) => Ok(json!({ "ok": false, "tool": "admin.chat.messages", "error": e })),
    }
}

tool! {
    struct: AdminChatSearchTool,
    name: "admin.chat.search",
    aliases: ["admin_chat_search"],
    description: "Root only: search another user's chat threads (title, summary, snippet). For apa chat terakhir Chito: subject_handle chito, empty query, limit 1. Resolve user via subject_uid or subject_handle (alien_id).",
    topics: ["staff"],
    always: ["general", "staff"],
    rag_phrases: [
        "chat terakhir user",
        "obrolan terakhir",
        "last chat of",
        "what did user chat",
        "percakapan terakhir",
        "riwayat chat user",
    ],
    requires_global_roles: ["root"],
    readonly: true,
    parameters: {
        subject_uid: (integer, "Target user identity id", optional),
        subject_handle: (string, "Target alien_id / handle (e.g. chito)", optional),
        query: (string, "Topic keywords; empty = most recent threads", optional, default = ""),
        since: (string, "Start date YYYY-MM-DD in subject timezone", optional, default = ""),
        until: (string, "End date YYYY-MM-DD in subject timezone", optional, default = ""),
        limit: (integer, "Max chats 1-8; use 1 for latest only", optional, default = 5),
    },
    execute: |args, ctx| admin_chat_search_exec(ctx, &args).await
}

tool! {
    struct: AdminChatMessagesTool,
    name: "admin.chat.messages",
    aliases: ["admin_chat_messages"],
    description: "Root only: exact messages from another user's chat. Pass subject_uid or subject_handle plus chat_id from admin.chat.search.",
    topics: ["staff"],
    always: ["staff"],
    requires_global_roles: ["root"],
    readonly: true,
    parameters: {
        subject_uid: (integer, "Target user identity id", optional),
        subject_handle: (string, "Target alien_id / handle", optional),
        chat_id: (string, "Chat id from admin.chat.search", required),
        query: (string, "Words that must appear in message", optional, default = ""),
        since: (string, "Start date YYYY-MM-DD", optional, default = ""),
        until: (string, "End date YYYY-MM-DD", optional, default = ""),
        limit: (integer, "Max messages 1-20", optional, default = 12),
    },
    execute: |args, ctx| admin_chat_messages_exec(ctx, &args).await
}

pub async fn admin_device_list_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    if let Err(v) = require_staff_json(ctx, "admin.device.list").await {
        return Ok(v);
    }
    let subject_iid = match subject_iid_resolve(&ctx.pool, args).await {
        Ok(id) => id,
        Err(e) => return Ok(json!({ "ok": false, "tool": "admin.device.list", "error": e })),
    };
    Ok(mcp_device_list(&ctx.pool, subject_iid).await)
}

pub async fn admin_bot_list_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    if let Err(v) = require_staff_json(ctx, "admin.bot.list").await {
        return Ok(v);
    }
    let subject_iid = match subject_iid_resolve(&ctx.pool, args).await {
        Ok(id) => id,
        Err(e) => return Ok(json!({ "ok": false, "tool": "admin.bot.list", "error": e })),
    };
    let rows = sqlx::query(
        r#"
        SELECT id, name, type, COALESCE(alien_id, '') AS alien_id, COALESCE(meta, '{}'::jsonb) AS meta
        FROM ai.identity
        WHERE owner_iid = $1 AND kind = 'bot' AND deleted_ts IS NULL
        ORDER BY id DESC
        LIMIT 100
        "#,
    )
    .bind(subject_iid)
    .fetch_all(&ctx.pool)
    .await
    .map_err(|e| e.to_string());
    match rows {
        Ok(list) => {
            let bots: Vec<Value> = list
                .iter()
                .map(|r| {
                    let meta: Value = r.try_get("meta").unwrap_or(json!({}));
                    json!({
                        "bot_iid": r.get::<i64, _>("id"),
                        "name": r.get::<String, _>("name"),
                        "type": r.get::<String, _>("type"),
                        "alien_id": r.get::<String, _>("alien_id"),
                        "auto_reply": meta.get("auto_reply"),
                        "web_search": meta.get("web_search"),
                    })
                })
                .collect();
            Ok(json!({
                "ok": true,
                "tool": "admin.bot.list",
                "subject_uid": subject_iid,
                "count": bots.len(),
                "bots": bots,
            }))
        }
        Err(e) => Ok(json!({ "ok": false, "tool": "admin.bot.list", "error": e })),
    }
}

pub async fn admin_client_list_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    if let Err(v) = require_staff_json(ctx, "admin.client.list").await {
        return Ok(v);
    }
    let subject_iid = match subject_iid_resolve(&ctx.pool, args).await {
        Ok(id) => id,
        Err(e) => return Ok(json!({ "ok": false, "tool": "admin.client.list", "error": e })),
    };
    let mut out = mcp_client_list(&ctx.pool, subject_iid).await;
    if let Some(obj) = out.as_object_mut() {
        obj.insert("tool".into(), json!("admin.client.list"));
    }
    Ok(out)
}

pub async fn admin_task_list_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    if let Err(v) = require_root_json(ctx, "admin.task.list").await {
        return Ok(v);
    }
    let subject_iid = match subject_iid_resolve(&ctx.pool, args).await {
        Ok(id) => id,
        Err(e) => return Ok(json!({ "ok": false, "tool": "admin.task.list", "error": e })),
    };
    let device_iid = arg_i64(args, "device_iid");
    let res = task_list_rpc(
        &ctx.pool,
        subject_iid,
        ReqTaskList {
            device_iid,
            include_inactive: args
                .get("include_inactive")
                .and_then(|v| v.as_bool())
                .unwrap_or(false),
        },
    )
    .await;
    let tasks: Vec<Value> = res.tasks.iter().map(task_doc_json).collect();
    Ok(json!({
        "ok": true,
        "tool": "admin.task.list",
        "subject_uid": subject_iid,
        "device_iid": device_iid,
        "count": tasks.len(),
        "tasks": tasks,
    }))
}

tool! {
    struct: AdminDeviceListTool,
    name: "admin.device.list",
    aliases: ["admin_device_list"],
    description: "Staff: list paired remote devices for a user (online, agent version). Pass subject_uid or subject_handle.",
    topics: ["staff", "device"],
    always: ["general", "staff"],
    rag_phrases: ["list devices", "daftar device", "paired devices", "device user", "perangkat user"],
    requires_global_roles: ["partner", "director"],
    readonly: true,
    parameters: {
        subject_uid: (integer, "User identity id", optional),
        subject_handle: (string, "User alien_id", optional),
    },
    execute: |args, ctx| admin_device_list_exec(ctx, &args).await
}

tool! {
    struct: AdminBotListTool,
    name: "admin.bot.list",
    aliases: ["admin_bot_list"],
    description: "Staff: list chat bots owned by a user. Pass subject_uid or subject_handle.",
    topics: ["staff"],
    always: ["general", "staff"],
    rag_phrases: ["list bots", "daftar bot", "bot user", "bots milik"],
    requires_global_roles: ["partner", "director"],
    readonly: true,
    parameters: {
        subject_uid: (integer, "User identity id", optional),
        subject_handle: (string, "User alien_id", optional),
    },
    execute: |args, ctx| admin_bot_list_exec(ctx, &args).await
}

tool! {
    struct: AdminClientListTool,
    name: "admin.client.list",
    aliases: ["admin_client_list"],
    description: "Staff: list Flutter/app client installs for a user (build, last seen). Pass subject_uid or subject_handle.",
    topics: ["staff"],
    requires_global_roles: ["partner", "director"],
    readonly: true,
    parameters: {
        subject_uid: (integer, "User identity id", optional),
        subject_handle: (string, "User alien_id", optional),
    },
    execute: |args, ctx| admin_client_list_exec(ctx, &args).await
}

tool! {
    struct: AdminTaskListTool,
    name: "admin.task.list",
    aliases: ["admin_task_list"],
    description: "Root only: list saved automation tasks (ai.task recipes) for a user. Optional device_iid filter. Includes prompts.",
    topics: ["staff", "device"],
    always: ["staff"],
    rag_phrases: [
        "automation task list", "daftar task otomasi", "saved tasks user",
        "task recipes", "ai.task",
    ],
    requires_global_roles: ["root"],
    readonly: true,
    parameters: {
        subject_uid: (integer, "User identity id", optional),
        subject_handle: (string, "User alien_id", optional),
        device_iid: (integer, "Filter by device; 0 = all", optional, default = 0),
    },
    execute: |args, ctx| admin_task_list_exec(ctx, &args).await
}
