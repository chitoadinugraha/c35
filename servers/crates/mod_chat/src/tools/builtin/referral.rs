use anyhow::Result;
use c35_mod_referral::{
    normalize_code, referral_code_delete, referral_code_list, referral_code_put, referral_tree_get,
};
use c35_proto::{ReferralCodeDoc, ReferralTreeNode};
use serde_json::{json, Value};

use crate::tool;
use crate::tools::ToolContext;

fn referral_code_json(doc: &ReferralCodeDoc) -> Value {
    json!({
        "code": doc.code,
        "type": doc.r#type,
        "name": doc.name,
        "issued_by": doc.issued_by,
        "price_usd": doc.price_usd,
        "duration_months": doc.duration_months,
        "base_plan_slug": doc.base_plan_slug,
        "max_uses": doc.max_uses,
        "used_count": doc.used_count,
        "expires_at_ms": doc.expires_at_ms,
    })
}

fn referral_tree_node_json(n: &ReferralTreeNode) -> Value {
    json!({
        "identity_id": n.identity_id,
        "name": n.name,
        "handle": n.handle,
        "referred_by": n.referred_by,
        "child_count": n.child_count,
        "is_root": n.is_root,
    })
}

fn code_from_args(args: &Value) -> Result<String, String> {
    if let Some(c) = args
        .get("code")
        .and_then(|v| v.as_str())
        .map(normalize_code)
        .filter(|s| !s.is_empty())
    {
        return Ok(c);
    }
    if let Some(name) = args
        .get("name")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
    {
        let derived = normalize_code(name);
        if !derived.is_empty() {
            return Ok(derived);
        }
    }
    Err("code or name required".into())
}

fn doc_from_args(args: &Value, owner_iid: i64) -> Result<ReferralCodeDoc, String> {
    let code = code_from_args(args)?;
    let name = args
        .get("name")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .unwrap_or("")
        .to_string();
    let r#type = args
        .get("type")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .unwrap_or("referral")
        .to_string();
    Ok(ReferralCodeDoc {
        code,
        r#type,
        name,
        issued_by: owner_iid,
        price_usd: args.get("price_usd").and_then(|v| v.as_f64()).unwrap_or(0.0).max(0.0),
        duration_months: args
            .get("duration_months")
            .and_then(|v| v.as_i64())
            .unwrap_or(0) as i32,
        base_plan_slug: args
            .get("base_plan_slug")
            .and_then(|v| v.as_str())
            .map(str::trim)
            .unwrap_or("")
            .to_string(),
        max_uses: args.get("max_uses").and_then(|v| v.as_i64()).unwrap_or(0) as i32,
        used_count: args.get("used_count").and_then(|v| v.as_i64()).unwrap_or(0) as i32,
        expires_at_ms: args.get("expires_at_ms").and_then(|v| v.as_i64()).unwrap_or(0),
    })
}

pub async fn referral_code_put_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let doc = match doc_from_args(args, ctx.owner_iid) {
        Ok(d) => d,
        Err(e) => {
            return Ok(json!({
                "ok": false,
                "runner": "cluster",
                "tool": "referral.code.put",
                "error": e,
            }));
        }
    };
    match referral_code_put(&ctx.pool, ctx.owner_iid, doc).await {
        Ok(saved) => Ok(json!({
            "ok": true,
            "runner": "cluster",
            "tool": "referral.code.put",
            "code": saved.code,
            "name": saved.name,
            "type": saved.r#type,
            "llm": referral_code_json(&saved),
        })),
        Err(e) => Ok(json!({
            "ok": false,
            "runner": "cluster",
            "tool": "referral.code.put",
            "error": e,
        })),
    }
}

pub async fn referral_code_list_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let q = args
        .get("query")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .unwrap_or("")
        .to_ascii_lowercase();
    let items = referral_code_list(&ctx.pool, ctx.owner_iid).await;
    let filtered: Vec<_> = if q.is_empty() {
        items
    } else {
        items
            .into_iter()
            .filter(|c| {
                c.code.to_ascii_lowercase().contains(&q)
                    || c.name.to_ascii_lowercase().contains(&q)
                    || c.r#type.to_ascii_lowercase().contains(&q)
            })
            .collect()
    };
    let rows: Vec<Value> = filtered.iter().map(referral_code_json).collect();
    Ok(json!({
        "ok": true,
        "runner": "cluster",
        "tool": "referral.code.list",
        "count": rows.len(),
        "items": rows,
        "llm": {
            "count": rows.len(),
            "items": rows,
        },
    }))
}

pub async fn referral_code_delete_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let code = match args.get("code").and_then(|v| v.as_str()).map(normalize_code).filter(|s| !s.is_empty()) {
        Some(c) => c,
        None => {
            return Ok(json!({
                "ok": false,
                "runner": "cluster",
                "tool": "referral.code.delete",
                "error": "code required",
            }));
        }
    };
    match referral_code_delete(&ctx.pool, ctx.owner_iid, &code).await {
        Ok(()) => Ok(json!({
            "ok": true,
            "runner": "cluster",
            "tool": "referral.code.delete",
            "code": code,
        })),
        Err(e) => Ok(json!({
            "ok": false,
            "runner": "cluster",
            "tool": "referral.code.delete",
            "error": e,
        })),
    }
}

pub async fn referral_tree_get_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let root_id = args.get("root_id").and_then(|v| v.as_i64()).unwrap_or(0);
    let depth = args.get("depth").and_then(|v| v.as_i64()).unwrap_or(2) as i32;
    let slice = referral_tree_get(&ctx.pool, ctx.owner_iid, root_id, depth).await;
    let nodes: Vec<Value> = slice.nodes.iter().map(referral_tree_node_json).collect();
    Ok(json!({
        "ok": true,
        "runner": "cluster",
        "tool": "referral.tree.get",
        "node_count": nodes.len(),
        "nodes": nodes,
        "llm": {
            "node_count": nodes.len(),
            "nodes": nodes,
        },
    }))
}

tool! {
    struct: ReferralCodePutTool,
    name: "referral.code.put",
    aliases: [
        "referral_code_put",
        "buat referral code",
        "buat kode referral",
        "create referral code",
        "new referral code",
    ],
    description: "Create or update a referral signup or package code for the caller. Examples: buat referral code untuk Chito, buat kode referral untuk Alice, create referral code named Partner-A, new signup code label VIP. Set name as the display label; code is optional and derived from name when omitted.",
    topics: ["referral", "billing"],
    always: ["general", "referral"],
    ui_calling_key: "tool.referral.code.put.calling",
    ui_done_key: "tool.referral.code.put.done",
    parameters: {
        name: (string, "Display label for the code (e.g. Chito, VIP partner)", optional),
        code: (string, "Alphanumeric code; omit to derive from name", optional),
        type: (string, "referral (signup) or package (paid plan redeem)", optional, default = "referral"),
        price_usd: (number, "Package price in USD when type=package", optional),
        duration_months: (integer, "Package duration in months", optional),
        max_uses: (integer, "Maximum redemption count; 0 = unlimited", optional),
        base_plan_slug: (string, "Billing plan slug for package codes", optional),
        expires_at_ms: (integer, "Expiry unix ms; 0 = no expiry", optional),
    },
    execute: |args, ctx| referral_code_put_exec(ctx, &args).await
}

tool! {
    struct: ReferralCodeListTool,
    name: "referral.code.list",
    aliases: [
        "referral_code_list",
        "daftar referral code",
        "list referral codes",
        "lihat kode referral",
        "referral codes",
    ],
    description: "List referral and package codes issued by the caller. Examples: daftar referral code, list my referral codes, lihat semua kode referral, show referral codes, kode referral saya. Optional query filters by code, name, or type substring.",
    topics: ["referral", "billing"],
    always: ["general", "referral"],
    ui_calling_key: "tool.referral.code.list.calling",
    ui_done_key: "tool.referral.code.list.done",
    readonly: true,
    parameters: {
        query: (string, "Optional filter on code, name, or type", optional),
    },
    execute: |args, ctx| referral_code_list_exec(ctx, &args).await
}

tool! {
    struct: ReferralCodeDeleteTool,
    name: "referral.code.delete",
    aliases: [
        "referral_code_delete",
        "hapus referral code",
        "delete referral code",
    ],
    description: "Delete a referral or package code owned by the caller. Examples: hapus referral code CHITO, delete code VIP2024, remove referral code. Requires the exact code string.",
    topics: ["referral", "billing"],
    always: ["referral"],
    ui_calling_key: "tool.referral.code.delete.calling",
    ui_done_key: "tool.referral.code.delete.done",
    parameters: {
        code: (string, "Referral code to delete", required),
    },
    execute: |args, ctx| referral_code_delete_exec(ctx, &args).await
}

tool! {
    struct: ReferralTreeGetTool,
    name: "referral.tree.get",
    aliases: [
        "referral_tree_get",
        "referral tree",
        "downline referral",
        "pohon referral",
    ],
    description: "Fetch referral downline tree nodes for the caller or a subtree root. Examples: lihat downline, referral tree, pohon referral saya, show my referrals, downline depth 3. Read-only; admins may request the full forest with root_id=0.",
    topics: ["referral"],
    always: ["general", "referral"],
    ui_calling_key: "tool.referral.tree.get.calling",
    ui_done_key: "tool.referral.tree.get.done",
    readonly: true,
    parameters: {
        root_id: (integer, "Subtree root identity id; 0 = caller or admin forest", optional, default = 0),
        depth: (integer, "Max depth 1-8", optional, default = 2),
    },
    execute: |args, ctx| referral_tree_get_exec(ctx, &args).await
}
