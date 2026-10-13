use anyhow::Result;
use c35_mod_billing::{
    billing_package_redeem, billing_voucher_issue, billing_voucher_limit_get, billing_voucher_limit_put,
    billing_voucher_list, billing_voucher_redeem_list, billing_voucher_void,
};
use c35_mod_referral::normalize_code;
use c35_proto::{
    BillingVoucherDoc, BillingVoucherRedeemDoc, ReqBillingVoucherIssue, ReqBillingVoucherLimitGet,
    ReqBillingVoucherLimitPut, ReqBillingVoucherList, ReqBillingVoucherRedeemList, ReqBillingVoucherVoid,
};
use serde_json::{json, Value};

use crate::tool;
use crate::tools::ToolContext;

const TOOL_VOUCHER: &str = "billing.voucher";
const TOOL_REDEEM: &str = "billing.redeem";

fn voucher_public_url(code: &str) -> String {
    format!("https://alienai.id/voucher/{}", code.trim())
}

fn err_json(tool: &str, error: impl Into<String>) -> Value {
    json!({
        "ok": false,
        "runner": "cluster",
        "tool": tool,
        "error": error.into(),
    })
}

fn action_norm(args: &Value) -> String {
    args.get("action")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .unwrap_or("")
        .to_ascii_lowercase()
        .replace('-', "_")
}

fn voucher_doc_json(doc: &BillingVoucherDoc) -> Value {
    json!({
        "code": doc.code,
        "kind": doc.kind,
        "name": doc.name,
        "status": doc.status,
        "face_value_idr": doc.face_value_idr,
        "list_price_idr": doc.list_price_idr,
        "expires_at_ms": doc.expires_at_ms,
        "scope": doc.scope,
        "plan_slug": doc.plan_slug,
        "duration_months": doc.duration_months,
        "credit_idr": doc.credit_idr,
        "redeemed_ts_ms": doc.redeemed_ts_ms,
        "redeemed_by_iid": doc.redeemed_by_iid,
        "redeemed_by_name": doc.redeemed_by_name,
        "used_count": doc.used_count,
        "max_uses": doc.max_uses,
        "billing_period": doc.billing_period,
        "public_url": voucher_public_url(&doc.code),
    })
}

fn redeem_row_json(doc: &BillingVoucherRedeemDoc) -> Value {
    json!({
        "id": doc.id,
        "code": doc.code,
        "buyer_iid": doc.buyer_iid,
        "buyer_name": doc.buyer_name,
        "face_value_idr": doc.face_value_idr,
        "list_price_idr": doc.list_price_idr,
        "redeemed_ts_ms": doc.redeemed_ts_ms,
    })
}

fn issue_req_from_args(args: &Value) -> ReqBillingVoucherIssue {
    let kind = args
        .get("kind")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .unwrap_or("credit")
        .to_string();
    ReqBillingVoucherIssue {
        kind,
        plan_slug: args
            .get("plan_slug")
            .and_then(|v| v.as_str())
            .map(str::trim)
            .unwrap_or("")
            .to_string(),
        duration_months: args.get("duration_months").and_then(|v| v.as_i64()).unwrap_or(1) as i32,
        credit_idr: args.get("credit_idr").and_then(|v| v.as_f64()).unwrap_or(0.0).max(0.0),
        face_value_idr: args
            .get("face_value_idr")
            .and_then(|v| v.as_f64())
            .unwrap_or(0.0)
            .max(0.0),
        max_uses: args.get("max_uses").and_then(|v| v.as_i64()).unwrap_or(1) as i32,
        expires_at_ms: args.get("expires_at_ms").and_then(|v| v.as_i64()).unwrap_or(0),
        payment_ref: args
            .get("payment_ref")
            .and_then(|v| v.as_str())
            .map(str::trim)
            .unwrap_or("")
            .to_string(),
        code: args
            .get("code")
            .and_then(|v| v.as_str())
            .map(normalize_code)
            .unwrap_or_default(),
        name: args
            .get("name")
            .and_then(|v| v.as_str())
            .map(str::trim)
            .unwrap_or("")
            .to_string(),
        scope: args
            .get("scope")
            .and_then(|v| v.as_str())
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .unwrap_or("user")
            .to_string(),
        billing_period: args
            .get("billing_period")
            .and_then(|v| v.as_str())
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .unwrap_or("monthly")
            .to_string(),
        list_price_idr: args.get("list_price_idr").and_then(|v| v.as_f64()).unwrap_or(0.0).max(0.0),
        alien_pool_limit_idr: args
            .get("alien_pool_limit_idr")
            .and_then(|v| v.as_f64())
            .unwrap_or(0.0)
            .max(0.0),
        frontier_pool_limit_idr: args
            .get("frontier_pool_limit_idr")
            .and_then(|v| v.as_f64())
            .unwrap_or(0.0)
            .max(0.0),
        quantity: args.get("quantity").and_then(|v| v.as_i64()).unwrap_or(1).clamp(1, 50) as i32,
    }
}

pub async fn billing_voucher_tool_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let action = action_norm(args);
    if action.is_empty() {
        return Ok(err_json(
            TOOL_VOUCHER,
            "action required: issue | list | void | redeem_history | limit_get | limit_put",
        ));
    }

    match action.as_str() {
        "issue" => {
            let req = issue_req_from_args(args);
            if req.face_value_idr <= 0.0 && req.credit_idr <= 0.0 && req.kind != "package" {
                return Ok(err_json(TOOL_VOUCHER, "face_value_idr or credit_idr required for issue"));
            }
            if req.kind == "package" && req.plan_slug.is_empty() {
                return Ok(err_json(TOOL_VOUCHER, "plan_slug required when kind=package"));
            }
            match billing_voucher_issue(&ctx.pool, ctx.owner_iid, req).await {
                Ok(res) => {
                    let codes: Vec<Value> = if !res.codes.is_empty() {
                        res.codes.iter().map(|c| json!({ "code": c, "public_url": voucher_public_url(c) })).collect()
                    } else {
                        vec![json!({ "code": res.code, "public_url": voucher_public_url(&res.code) })]
                    };
                    Ok(json!({
                        "ok": true,
                        "runner": "cluster",
                        "tool": TOOL_VOUCHER,
                        "action": "issue",
                        "face_value_idr": res.face_value_idr,
                        "codes": codes,
                        "llm": {
                            "action": "issue",
                            "face_value_idr": res.face_value_idr,
                            "codes": codes,
                        },
                    }))
                }
                Err(e) => Ok(err_json(TOOL_VOUCHER, e)),
            }
        }
        "list" => match billing_voucher_list(&ctx.pool, ctx.owner_iid, ReqBillingVoucherList {}).await {
            Ok(res) => {
                let items: Vec<Value> = res.items.iter().map(voucher_doc_json).collect();
                let limit = res.limit.as_ref().map(|l| {
                    json!({
                        "target_iid": l.target_iid,
                        "limit_idr": l.limit_idr,
                        "used_idr": l.used_idr,
                    })
                });
                Ok(json!({
                    "ok": true,
                    "runner": "cluster",
                    "tool": TOOL_VOUCHER,
                    "action": "list",
                    "count": items.len(),
                    "items": items,
                    "limit": limit,
                    "llm": { "action": "list", "count": items.len(), "items": items, "limit": limit },
                }))
            }
            Err(e) => Ok(err_json(TOOL_VOUCHER, e)),
        },
        "void" => {
            let code = args
                .get("code")
                .and_then(|v| v.as_str())
                .map(normalize_code)
                .filter(|s| !s.is_empty());
            let Some(code) = code else {
                return Ok(err_json(TOOL_VOUCHER, "code required for void"));
            };
            match billing_voucher_void(
                &ctx.pool,
                ctx.owner_iid,
                ReqBillingVoucherVoid { code: code.clone() },
            )
            .await
            {
                Ok(res) => Ok(json!({
                    "ok": res.ok,
                    "runner": "cluster",
                    "tool": TOOL_VOUCHER,
                    "action": "void",
                    "code": code,
                    "llm": { "action": "void", "code": code, "voided": res.ok },
                })),
                Err(e) => Ok(err_json(TOOL_VOUCHER, e)),
            }
        }
        "redeem_history" | "redeem_list" | "redemptions" => {
            let limit = args.get("limit").and_then(|v| v.as_i64()).unwrap_or(100) as i32;
            match billing_voucher_redeem_list(
                &ctx.pool,
                ctx.owner_iid,
                ReqBillingVoucherRedeemList { limit },
            )
            .await
            {
                Ok(res) => {
                    let items: Vec<Value> = res.items.iter().map(redeem_row_json).collect();
                    Ok(json!({
                        "ok": true,
                        "runner": "cluster",
                        "tool": TOOL_VOUCHER,
                        "action": "redeem_history",
                        "count": items.len(),
                        "items": items,
                        "llm": { "action": "redeem_history", "count": items.len(), "items": items },
                    }))
                }
                Err(e) => Ok(err_json(TOOL_VOUCHER, e)),
            }
        }
        "limit_get" => {
            let target_iid = args
                .get("target_iid")
                .and_then(|v| v.as_i64())
                .filter(|&id| id > 0)
                .unwrap_or(ctx.owner_iid);
            match billing_voucher_limit_get(
                &ctx.pool,
                ctx.owner_iid,
                ReqBillingVoucherLimitGet { target_iid },
            )
            .await
            {
                Ok(res) => Ok(json!({
                    "ok": true,
                    "runner": "cluster",
                    "tool": TOOL_VOUCHER,
                    "action": "limit_get",
                    "target_iid": res.target_iid,
                    "limit_idr": res.limit_idr,
                    "used_idr": res.used_idr,
                    "llm": {
                        "action": "limit_get",
                        "target_iid": res.target_iid,
                        "limit_idr": res.limit_idr,
                        "used_idr": res.used_idr,
                    },
                })),
                Err(e) => Ok(err_json(TOOL_VOUCHER, e)),
            }
        }
        "limit_put" | "limit_set" => {
            let target_iid = args.get("target_iid").and_then(|v| v.as_i64()).unwrap_or(0);
            if target_iid <= 0 {
                return Ok(err_json(TOOL_VOUCHER, "target_iid required for limit_put"));
            }
            let limit_idr = args.get("limit_idr").and_then(|v| v.as_f64()).unwrap_or(-1.0);
            if limit_idr < 0.0 {
                return Ok(err_json(TOOL_VOUCHER, "limit_idr required for limit_put"));
            }
            match billing_voucher_limit_put(
                &ctx.pool,
                ctx.owner_iid,
                ReqBillingVoucherLimitPut {
                    target_iid,
                    limit_idr,
                },
            )
            .await
            {
                Ok(res) => Ok(json!({
                    "ok": true,
                    "runner": "cluster",
                    "tool": TOOL_VOUCHER,
                    "action": "limit_put",
                    "target_iid": res.target_iid,
                    "limit_idr": res.limit_idr,
                    "used_idr": res.used_idr,
                    "llm": {
                        "action": "limit_put",
                        "target_iid": res.target_iid,
                        "limit_idr": res.limit_idr,
                        "used_idr": res.used_idr,
                    },
                })),
                Err(e) => Ok(err_json(TOOL_VOUCHER, e)),
            }
        }
        _ => Ok(err_json(
            TOOL_VOUCHER,
            format!(
                "unknown action {:?}; use issue | list | void | redeem_history | limit_get | limit_put",
                action
            ),
        )),
    }
}

pub async fn billing_redeem_tool_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let code = args
        .get("code")
        .and_then(|v| v.as_str())
        .map(normalize_code)
        .filter(|s| !s.is_empty());
    let Some(code) = code else {
        return Ok(err_json(TOOL_REDEEM, "code required"));
    };
    match billing_package_redeem(&ctx.pool, ctx.owner_iid, &code).await {
        Ok(res) => Ok(json!({
            "ok": true,
            "runner": "cluster",
            "tool": TOOL_REDEEM,
            "code": code,
            "package_name": res.package_name,
            "plan_tier": res.plan_tier,
            "duration_months": res.duration_months,
            "amount_idr": res.amount_idr,
            "amount_usd": res.amount_usd,
            "balance_idr": res.balance_idr,
            "balance_usd": res.balance_usd,
            "entitlement_id": res.entitlement_id,
            "expires_ts_ms": res.expires_ts_ms,
            "llm": {
                "code": code,
                "package_name": res.package_name,
                "plan_tier": res.plan_tier,
                "duration_months": res.duration_months,
                "amount_idr": res.amount_idr,
                "balance_idr": res.balance_idr,
                "entitlement_id": res.entitlement_id,
                "expires_ts_ms": res.expires_ts_ms,
            },
        })),
        Err(e) => Ok(err_json(TOOL_REDEEM, e)),
    }
}

tool! {
    struct: BillingVoucherTool,
    name: "billing.voucher",
    aliases: [
        "billing_voucher",
        "issue voucher",
        "buat voucher",
        "list vouchers",
        "void voucher",
        "voucher prepaid",
    ],
    description: "Staff prepaid voucher operations for marketing/finance/director roles. action: issue (create prepaid voucher), list (inventory), void (revoke unused), redeem_history (who redeemed), limit_get, limit_put (director sets marketing issue cap). Not for signup referral codes — use referral.code.*. Returns public_url https://alienai.id/voucher/CODE on issue.",
    topics: ["billing", "referral", "staff"],
    always: ["general", "referral"],
    rag_phrases: [
        "buat voucher",
        "issue voucher",
        "daftar voucher",
        "list voucher",
        "void voucher",
        "batalkan voucher",
        "riwayat redeem voucher",
        "marketing voucher",
        "voucher prepaid",
        "batas voucher marketing",
    ],
    ui_calling_key: "tool.billing.voucher.calling",
    ui_done_key: "tool.billing.voucher.done",
    parameters: {
        action: (string, "issue | list | void | redeem_history | limit_get | limit_put", required),
        code: (string, "Voucher code for void", optional),
        name: (string, "Display name on issue", optional),
        kind: (string, "credit | package on issue", optional, default = "credit"),
        face_value_idr: (number, "Face value IDR on issue", optional),
        credit_idr: (number, "Credit top-up IDR when kind=credit", optional),
        plan_slug: (string, "Plan slug when kind=package", optional),
        duration_months: (integer, "Package months on issue", optional, default = 1),
        max_uses: (integer, "Max redemptions", optional, default = 1),
        quantity: (integer, "Batch issue count 1-50", optional, default = 1),
        expires_at_ms: (integer, "Expiry unix ms; 0 = none", optional),
        scope: (string, "user | bot", optional, default = "user"),
        billing_period: (string, "monthly | yearly for package", optional, default = "monthly"),
        list_price_idr: (number, "Optional strikethrough price", optional),
        payment_ref: (string, "Internal payment reference", optional),
        limit: (integer, "Max rows for redeem_history", optional, default = 100),
        target_iid: (integer, "Marketing user for limit_get/limit_put", optional),
        limit_idr: (number, "New marketing issue cap for limit_put", optional),
    },
    execute: |args, ctx| billing_voucher_tool_exec(ctx, &args).await
}

tool! {
    struct: BillingRedeemTool,
    name: "billing.redeem",
    aliases: [
        "billing_redeem",
        "redeem voucher",
        "pakai voucher",
        "redeem code",
        "pakai kode voucher",
    ],
    description: "Redeem a prepaid voucher or package referral code into the signed-in account (same as Plans → Redeem). Prepaid vouchers do not debit wallet balance. Requires code.",
    topics: ["billing", "general"],
    always: ["general", "billing"],
    rag_phrases: [
        "redeem voucher",
        "pakai voucher",
        "pakai kode voucher",
        "redeem code",
        "tukar voucher",
        "klaim voucher",
        "masukkan kode voucher",
    ],
    ui_calling_key: "tool.billing.redeem.calling",
    ui_done_key: "tool.billing.redeem.done",
    parameters: {
        code: (string, "Voucher or package code (from QR, link, or typed)", required),
    },
    execute: |args, ctx| billing_redeem_tool_exec(ctx, &args).await
}
