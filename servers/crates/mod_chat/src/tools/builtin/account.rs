use anyhow::Result;
use c35_ctx::Ctx;
use c35_mod_billing::{billing_account_get, billing_history};
use c35_mod_device::{mcp_client_list, mcp_device_list};
use c35_mod_identity::{identity_list, identity_nav_counts, identity_profile_get};
use c35_mod_referral::{referral_ledger_list, referral_user_stats};
use c35_proto::{
    BillingAccount, IdentityListRow, ReferralUserStatColumn, ReferralUserWalletSnapshot, ReqBillingHistory,
    ReqIdentityList, ReqReferralLedgerList, ReqReferralUserStats,
};
use serde_json::{json, Value};
use sqlx::{PgPool, Row};

use crate::tool;
use crate::tools::ToolContext;

fn tool_ctx(ctx: &ToolContext) -> Ctx {
    Ctx {
        pool: ctx.pool.clone(),
        caller_iid: ctx.owner_iid,
    }
}

async fn auth_contact_for_iid(pool: &PgPool, iid: i64) -> (String, String) {
    let rows = sqlx::query(
        r#"
        SELECT kind, identifier
        FROM ai.identity_provider
        WHERE identity_iid = $1 AND deleted_ts IS NULL AND kind IN ('google', 'email', 'phone')
        ORDER BY CASE kind WHEN 'google' THEN 0 WHEN 'email' THEN 1 ELSE 2 END
        "#,
    )
    .bind(iid)
    .fetch_all(pool)
    .await
    .unwrap_or_default();
    let mut email = String::new();
    let mut phone = String::new();
    for r in rows {
        let kind: String = r.get("kind");
        let id: String = r.get("identifier");
        if kind == "phone" {
            if phone.is_empty() {
                phone = id.trim().to_string();
            }
        } else if email.is_empty() {
            email = id.trim().to_string();
        }
    }
    (email, phone)
}

fn wallet_json(w: &ReferralUserWalletSnapshot) -> Value {
    json!({
        "balance_idr": w.balance_idr,
        "balance_usd": w.balance_usd,
        "commission_available_idr": w.commission_available_idr,
        "commission_available_usd": w.commission_available_usd,
        "billing_currency": w.billing_currency,
    })
}

fn stat_col_json(c: &ReferralUserStatColumn) -> Value {
    json!({
        "referral_count": c.referral_count,
        "commission_idr": c.commission_idr,
        "commission_usd": c.commission_usd,
        "tokens_alien": c.tokens_alien,
        "tokens_api": c.tokens_api,
    })
}

fn billing_llm(b: &BillingAccount) -> Value {
    json!({
        "plan_tier": b.plan_tier,
        "billing_currency": b.billing_currency,
        "balance_idr": b.balance_idr,
        "balance_usd": b.balance_usd,
        "alien_allow_5h_used": b.alien_allow_5h_used,
        "alien_allow_5h_limit": b.alien_allow_5h_limit,
        "alien_allow_weekly_used": b.alien_allow_weekly_used,
        "alien_allow_weekly_limit": b.alien_allow_weekly_limit,
        "commission_available_idr": b.commission_available_idr,
        "commission_available_usd": b.commission_available_usd,
        "freemium_active": b.freemium_active,
        "freemium_msgs_used": b.freemium_msgs_used,
        "freemium_msgs_limit": b.freemium_msgs_limit,
        "freemium_tokens_used": b.freemium_tokens_used,
        "freemium_tokens_limit": b.freemium_tokens_limit,
        "plan_expires_ts_ms": b.plan_expires_ts_ms,
        "trial_expires_ts_ms": b.trial_expires_ts_ms,
    })
}

fn identity_row_llm(row: &IdentityListRow) -> Value {
    let id = row.identity.as_ref();
    json!({
        "iid": id.map(|i| i.iid).unwrap_or(0),
        "name": id.map(|i| i.name.as_str()).unwrap_or(""),
        "alien_id": id.map(|i| i.alien_id.as_str()).unwrap_or(""),
        "type": id.map(|i| i.r#type.as_str()).unwrap_or(""),
        "kind": id.map(|i| i.kind.as_str()).unwrap_or(""),
        "archived": row.archived_ts_ms > 0,
    })
}

pub async fn account_get_exec(ctx: &ToolContext, _args: &Value) -> Result<Value> {
    let c = tool_ctx(ctx);
    let profile = identity_profile_get(&c).await.map_err(|e| anyhow::anyhow!(e.to_string()))?;
    let nav = identity_nav_counts(&c).await.map_err(|e| anyhow::anyhow!(e.to_string()))?;
    let (auth_email, auth_phone) = auth_contact_for_iid(&ctx.pool, ctx.owner_iid).await;
    let email = if profile.email.is_empty() { auth_email } else { profile.email.clone() };
    let llm = json!({
        "iid": profile.iid,
        "name": profile.name,
        "alien_id": profile.alien_id,
        "email": email,
        "phone": auth_phone,
        "locale": profile.locale,
        "tz": profile.tz,
        "location_city": profile.location_city,
        "location_region": profile.location_region,
        "location_country": profile.location_country,
        "billing_iid": profile.billing_iid,
        "global_roles": profile.global_roles,
        "nav": { "bots": nav.bots, "devices": nav.devices, "sites": nav.sites },
    });
    Ok(json!({ "ok": true, "tool": "account.get", "profile": llm, "llm": llm }))
}

pub async fn account_billing_get_exec(ctx: &ToolContext, _args: &Value) -> Result<Value> {
    let c = tool_ctx(ctx);
    let profile = identity_profile_get(&c).await.map_err(|e| anyhow::anyhow!(e.to_string()))?;
    let billing_iid = if profile.billing_iid > 0 { profile.billing_iid } else { ctx.owner_iid };
    let billing = billing_account_get(&c, billing_iid).await.map_err(|e| anyhow::anyhow!(e.to_string()))?;
    let llm = billing_llm(&billing);
    Ok(json!({ "ok": true, "tool": "account.billing.get", "billing": llm, "llm": llm }))
}

pub async fn account_billing_history_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let limit = args.get("limit").and_then(|v| v.as_i64()).unwrap_or(10).clamp(1, 50) as i32;
    let mut currency = args.get("currency").and_then(|v| v.as_str()).unwrap_or("").trim().to_uppercase();
    if currency.is_empty() {
        let c = tool_ctx(ctx);
        let profile = identity_profile_get(&c).await.map_err(|e| anyhow::anyhow!(e.to_string()))?;
        let billing_iid = if profile.billing_iid > 0 { profile.billing_iid } else { ctx.owner_iid };
        let billing = billing_account_get(&c, billing_iid).await.map_err(|e| anyhow::anyhow!(e.to_string()))?;
        currency = billing.billing_currency.trim().to_uppercase();
        if currency.is_empty() {
            currency = if billing.balance_idr >= billing.balance_usd { "IDR".into() } else { "USD".into() };
        }
    }
    let hist = billing_history(
        &ctx.pool,
        ctx.owner_iid,
        ReqBillingHistory { limit, currency: currency.clone() },
    )
    .await;
    let rows: Vec<Value> = hist
        .rows
        .iter()
        .map(|r| {
            json!({
                "kind": r.kind,
                "title": r.title,
                "amount": r.amount,
                "currency": r.currency,
                "status": r.status,
                "ts_ms": r.ts_ms,
            })
        })
        .collect();
    Ok(json!({
        "ok": true,
        "tool": "account.billing.history",
        "currency": currency,
        "count": rows.len(),
        "rows": rows,
        "llm": { "currency": currency, "recent": rows },
    }))
}

pub async fn account_referral_stats_exec(ctx: &ToolContext, _args: &Value) -> Result<Value> {
    let req = ReqReferralUserStats {
        subject_uid: 0,
        col_a: None,
        col_b: None,
    };
    match referral_user_stats(&ctx.pool, ctx.owner_iid, req).await {
        Ok(res) => {
            let wallet = res.wallet.as_ref().map(wallet_json).unwrap_or(json!({}));
            let col_a = res.col_a.as_ref().map(stat_col_json).unwrap_or(json!({}));
            let col_b = res.col_b.as_ref().map(stat_col_json).unwrap_or(json!({}));
            let llm = json!({ "wallet": wallet, "col_a": col_a, "col_b": col_b });
            Ok(json!({
                "ok": true,
                "tool": "account.referral.stats",
                "wallet": wallet,
                "col_a": col_a,
                "col_b": col_b,
                "llm": llm,
            }))
        }
        Err(e) => Ok(json!({ "ok": false, "tool": "account.referral.stats", "error": e })),
    }
}


pub async fn account_referral_ledger_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let limit = args
        .get("limit")
        .and_then(|v| v.as_i64())
        .unwrap_or(20)
        .clamp(1, 200) as i32;
    let res = referral_ledger_list(&ctx.pool, ctx.owner_iid, ReqReferralLedgerList { limit }).await;
    let items: Vec<Value> = res
        .items
        .iter()
        .map(|e| {
            json!({
                "id": e.id,
                "entry_type": e.entry_type,
                "amount_usd": e.amount_usd,
                "amount_idr": e.amount_idr,
                "currency": e.currency,
                "status": e.status,
                "event_type": e.event_type,
                "reference_id": e.reference_id,
                "source_iid": e.source_iid,
                "created_ts_ms": e.created_ts_ms,
            })
        })
        .collect();
    Ok(json!({
        "ok": true,
        "tool": "account.referral.ledger",
        "count": items.len(),
        "items": items,
        "llm": { "count": items.len(), "items": items },
    }))
}
pub async fn account_snapshot_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let profile = account_get_exec(ctx, args).await?;
    let billing = account_billing_get_exec(ctx, args).await?;
    let referral = account_referral_stats_exec(ctx, args).await?;
    let history = account_billing_history_exec(ctx, &json!({ "limit": 5 })).await?;
    let llm = json!({
        "profile": profile.get("llm").cloned().unwrap_or(Value::Null),
        "billing": billing.get("llm").cloned().unwrap_or(Value::Null),
        "referral": referral.get("llm").cloned().unwrap_or(Value::Null),
        "billing_history": history.get("llm").cloned().unwrap_or(Value::Null),
    });
    Ok(json!({
        "ok": true,
        "tool": "account.snapshot",
        "profile": profile.get("profile").cloned().unwrap_or(Value::Null),
        "billing": billing.get("billing").cloned().unwrap_or(Value::Null),
        "referral": referral.get("llm").cloned().unwrap_or(Value::Null),
        "billing_history": history.get("rows").cloned().unwrap_or(Value::Null),
        "llm": llm,
    }))
}

pub async fn device_list_exec(ctx: &ToolContext, _args: &Value) -> Result<Value> {
    let out = mcp_device_list(&ctx.pool, ctx.owner_iid).await;
    Ok(json!({
        "ok": out.get("ok").and_then(|v| v.as_bool()).unwrap_or(true),
        "tool": "device.list",
        "devices": out.get("devices").cloned().unwrap_or(json!([])),
        "count": out.get("count").and_then(|v| v.as_i64()).unwrap_or(0),
        "llm": out,
    }))
}

async fn identity_kind_list_exec(ctx: &ToolContext, kinds: &[&str], tool: &str) -> Result<Value> {
    let req = ReqIdentityList {
        kinds: kinds.iter().map(|s| s.to_string()).collect(),
        include_archived: false,
    };
    let res = identity_list(&ctx.pool, ctx.owner_iid, req)
        .await
        .map_err(|e| anyhow::anyhow!(e.to_string()))?;
    let rows: Vec<Value> = res.rows.iter().map(identity_row_llm).collect();
    Ok(json!({
        "ok": true,
        "tool": tool,
        "count": rows.len(),
        "items": rows,
        "llm": { "count": rows.len(), "items": rows },
    }))
}

pub async fn bot_list_exec(ctx: &ToolContext, _args: &Value) -> Result<Value> {
    identity_kind_list_exec(ctx, &["bot"], "bot.list").await
}

pub async fn site_list_exec(ctx: &ToolContext, _args: &Value) -> Result<Value> {
    identity_kind_list_exec(ctx, &["site"], "site.list").await
}

pub async fn client_list_exec(ctx: &ToolContext, _args: &Value) -> Result<Value> {
    let out = mcp_client_list(&ctx.pool, ctx.owner_iid).await;
    Ok(json!({
        "ok": out.get("ok").and_then(|v| v.as_bool()).unwrap_or(true),
        "tool": "client.list",
        "clients": out.get("clients").cloned().unwrap_or(json!([])),
        "count": out.get("count").and_then(|v| v.as_i64()).unwrap_or(0),
        "llm": out,
    }))
}

tool! {
    struct: AccountGetTool,
    name: "account.get",
    aliases: ["account_get", "my profile", "profil saya"],
    description: "Read-only profile for the signed-in user: name, alien_id, email, phone, locale, timezone, location, uid, nav counts.",
    topics: ["general"],
    always: ["general"],
    rag_phrases: ["my profile", "profil saya", "email saya", "phone number", "who am i"],
    ui_calling_key: "tool.account.get.calling",
    ui_done_key: "tool.account.get.done",
    readonly: true,
    parameters: {},
    execute: |args, ctx| account_get_exec(ctx, &args).await
}

tool! {
    struct: AccountBillingGetTool,
    name: "account.billing.get",
    aliases: ["account_billing_get", "my balance", "saldo saya"],
    description: "Wallet balance, plan tier, quota rings, and freemium/trial flags for the signed-in user.",
    topics: ["general", "billing"],
    always: ["general", "billing"],
    rag_phrases: ["berapa saldo", "saldo saya", "my balance", "paket saya", "plan saya", "kuota"],
    ui_calling_key: "tool.account.billing.get.calling",
    ui_done_key: "tool.account.billing.get.done",
    readonly: true,
    parameters: {},
    execute: |args, ctx| account_billing_get_exec(ctx, &args).await
}

tool! {
    struct: AccountBillingHistoryTool,
    name: "account.billing.history",
    aliases: ["account_billing_history", "billing history"],
    description: "Recent billing top-ups and AI usage charges for the signed-in user. Currency defaults to the user's billing currency.",
    topics: ["general", "billing"],
    always: ["general", "billing"],
    rag_phrases: ["billing history", "transaksi terakhir", "riwayat topup", "usage history"],
    ui_calling_key: "tool.account.billing.history.calling",
    ui_done_key: "tool.account.billing.history.done",
    readonly: true,
    parameters: {
        limit: (integer, "Max rows 1-50 (default 10)", optional, default = 10),
        currency: (string, "IDR or USD; omit to use billing currency", optional),
    },
    execute: |args, ctx| account_billing_history_exec(ctx, &args).await
}

tool! {
    struct: AccountReferralStatsTool,
    name: "account.referral.stats",
    aliases: ["account_referral_stats", "my commission"],
    description: "Referral wallet snapshot and commission stats for the signed-in user (self only).",
    topics: ["general", "referral", "billing"],
    always: ["general", "referral"],
    rag_phrases: ["komisi saya", "saldo komisi", "referral stats", "commission balance"],
    ui_calling_key: "tool.account.referral.stats.calling",
    ui_done_key: "tool.account.referral.stats.done",
    readonly: true,
    parameters: {},
    execute: |args, ctx| account_referral_stats_exec(ctx, &args).await
}

tool! {
    struct: AccountReferralLedgerTool,
    name: "account.referral.ledger",
    aliases: ["account_referral_ledger", "commission ledger", "riwayat komisi"],
    description: "Recent commission ledger entries (credits, debits, payouts) for the signed-in user's referral wallet.",
    topics: ["general", "referral", "billing"],
    always: ["general", "referral"],
    rag_phrases: ["riwayat komisi", "commission ledger", "mutasi komisi", "referral transactions"],
    ui_calling_key: "tool.account.referral.ledger.calling",
    ui_done_key: "tool.account.referral.ledger.done",
    readonly: true,
    parameters: {
        limit: (integer, "Max rows 1-200 (default 20)", optional, default = 20),
    },
    execute: |args, ctx| account_referral_ledger_exec(ctx, &args).await
}

tool! {
    struct: AccountSnapshotTool,
    name: "account.snapshot",
    aliases: ["account_snapshot", "ringkasan akun"],
    description: "Combined snapshot: profile, billing, referral stats, and recent billing history for the signed-in user.",
    topics: ["general", "billing", "referral"],
    always: ["general"],
    rag_phrases: ["ringkasan akun", "account summary", "account overview"],
    ui_calling_key: "tool.account.snapshot.calling",
    ui_done_key: "tool.account.snapshot.done",
    readonly: true,
    parameters: {},
    execute: |args, ctx| account_snapshot_exec(ctx, &args).await
}

tool! {
    struct: DeviceListTool,
    name: "device.list",
    aliases: ["device_list", "list devices", "daftar device"],
    description: "List paired remote devices for the signed-in user with online and version hints.",
    topics: ["general", "device"],
    always: ["general", "device"],
    rag_phrases: ["daftar device", "my devices", "paired pc", "list devices"],
    ui_calling_key: "tool.device.list.calling",
    ui_done_key: "tool.device.list.done",
    readonly: true,
    parameters: {},
    execute: |args, ctx| device_list_exec(ctx, &args).await
}

tool! {
    struct: BotListTool,
    name: "bot.list",
    aliases: ["bot_list", "list bots", "daftar bot"],
    description: "List chat bots owned by or granted to the signed-in user.",
    topics: ["general", "bot"],
    always: ["general", "bot"],
    rag_phrases: ["daftar bot", "my bots", "list bots"],
    ui_calling_key: "tool.bot.list.calling",
    ui_done_key: "tool.bot.list.done",
    readonly: true,
    parameters: {},
    execute: |args, ctx| bot_list_exec(ctx, &args).await
}

tool! {
    struct: SiteListTool,
    name: "site.list",
    aliases: ["site_list", "list sites", "daftar site"],
    description: "List sites owned by or granted to the signed-in user.",
    topics: ["general", "site"],
    always: ["general", "site"],
    rag_phrases: ["daftar site", "my sites", "list sites"],
    ui_calling_key: "tool.site.list.calling",
    ui_done_key: "tool.site.list.done",
    readonly: true,
    parameters: {},
    execute: |args, ctx| site_list_exec(ctx, &args).await
}

tool! {
    struct: ClientListTool,
    name: "client.list",
    aliases: ["client_list", "app installs"],
    description: "List Alien AI app client registrations for the signed-in user's devices.",
    topics: ["general", "device"],
    always: ["general"],
    rag_phrases: ["app install", "client list"],
    ui_calling_key: "tool.client.list.calling",
    ui_done_key: "tool.client.list.done",
    readonly: true,
    parameters: {},
    execute: |args, ctx| client_list_exec(ctx, &args).await
}
