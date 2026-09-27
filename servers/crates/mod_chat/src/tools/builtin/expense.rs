use crate::tool;
use anyhow::Result;
use c35_mod_expense::{
    day_bounds_ms, detect_pic, detect_text, expense_compact_for_llm, expense_delete,
    expense_duplicate_today, expense_fingerprint, expense_get, expense_get_latest_today,
    expense_chat_title, expense_glance_block, expense_log_coach, expense_put, expense_receipt_block, expense_summary,
    expense_total_minor, glance_coach_with_match,     receipt_from_detect,
    spending_sum_day, summary_compact_for_llm, today_day_id,
};
use c35_mod_file::{cas_bytes_get, cas_dir_default};
use serde_json::{json, Value};
use sqlx::PgPool;

use crate::tools::ToolContext;

fn photo_hashes_from_attachments(attachments_json: &str) -> Vec<String> {
    let Ok(v) = serde_json::from_str::<Vec<serde_json::Value>>(attachments_json) else {
        return vec![];
    };
    let mut out = Vec::new();
    for a in v.iter() {
        let mime = a.get("mime").and_then(|x| x.as_str()).unwrap_or("");
        let hash = a.get("hash").and_then(|x| x.as_str()).unwrap_or("");
        if mime.starts_with("image/") && !hash.is_empty() && !out.contains(&hash.to_string()) {
            out.push(hash.to_string());
        }
    }
    out
}

async fn load_photo(pool: &PgPool, hash: &str) -> Result<(Vec<u8>, String), String> {
    if hash.is_empty() {
        return Err("photo required".into());
    }
    cas_bytes_get(pool, &cas_dir_default(), hash)
        .await
        .map_err(|e| e.to_string())
}

pub async fn expense_add_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let note = args.get("note").and_then(|v| v.as_str()).unwrap_or("").trim();
    let force = args.get("force").and_then(|v| v.as_bool()).unwrap_or(false);
    let mut photo_hash = args.get("photo_hash").and_then(|v| v.as_str()).unwrap_or("").trim().to_string();
    let attached_pics = photo_hashes_from_attachments(&ctx.attachments_json);
    if photo_hash.is_empty() {
        photo_hash = attached_pics.first().cloned().unwrap_or_default();
    }
    let mut pics = attached_pics;
    if !photo_hash.is_empty() && !pics.contains(&photo_hash) {
        pics.insert(0, photo_hash.clone());
    }

    let detect = if !photo_hash.is_empty() {
        match load_photo(&ctx.pool, &photo_hash).await {
            Ok((bytes, mime)) => detect_pic(&ctx.pool, ctx.owner_iid, &bytes, &mime, note).await,
            Err(e) => {
                return Ok(json!({ "ok": false, "runner": "cluster", "tool": "expense.add", "error": e }));
            }
        }
    } else if !note.is_empty() {
        detect_text(&ctx.pool, ctx.owner_iid, note).await
    } else {
        Err("photo or note required".into())
    };

    let detect = match detect {
        Ok(v) => v,
        Err(e) => return Ok(json!({ "ok": false, "runner": "cluster", "tool": "expense.add", "error": e })),
    };

    let fingerprint = expense_fingerprint(&detect.items);
    let locale = ctx.locale.as_str();
    let day = today_day_id(locale);
    let (start, end) = day_bounds_ms(&day, locale).unwrap_or((0, i64::MAX));
    let (so_far_before, tx_count_before) = spending_sum_day(&ctx.pool, ctx.owner_iid, start, end)
        .await
        .unwrap_or((0, 0));

    let dup = expense_duplicate_today(&ctx.pool, ctx.owner_iid, start, end, &photo_hash, &fingerprint)
        .await
        .unwrap_or(None);
    if dup.is_some() && !force {
        let today = c35_mod_expense::ExpenseTodaySummary {
            so_far_minor: so_far_before,
            after_minor: so_far_before,
            tx_count: tx_count_before,
        };
        let receipt = receipt_from_detect(
            0,
            &detect,
            &photo_hash,
            false,
            true,
            dup.as_ref().map(|(_, r)| r.as_str()).unwrap_or("receipt"),
            today,
            locale,
        );
        let block = expense_receipt_block(&receipt, locale);
        let compact = expense_compact_for_llm(&json!({ "ok": true, "saved": false, "duplicate": true }));
        return Ok(json!({
            "ok": true,
            "runner": "cluster",
            "tool": "expense.add",
            "llm": compact,
            "block": block,
            "saved": false,
        }));
    }

    let tx_id = match expense_put(
        &ctx.pool,
        ctx.owner_iid,
        &detect,
        &photo_hash,
        &pics,
        &fingerprint,
        note,
    )
    .await
    {
        Ok(id) => id,
        Err(e) => return Ok(json!({ "ok": false, "runner": "cluster", "tool": "expense.add", "error": e })),
    };

    let (so_far, tx_count) = spending_sum_day(&ctx.pool, ctx.owner_iid, start, end)
        .await
        .unwrap_or((0, 0));
    let dup_reason = if dup.is_some() { "receipt" } else { "" };
    let today = c35_mod_expense::ExpenseTodaySummary {
        so_far_minor: so_far_before,
        after_minor: so_far,
        tx_count,
    };
    let mut receipt = receipt_from_detect(
        tx_id,
        &detect,
        &photo_hash,
        true,
        dup.is_some(),
        dup_reason,
        today.clone(),
        locale,
    );

    // Food-Expense Bridge:
    // If dining / cafe ready-to-eat meal with <= 5 items (never for bulk groceries), auto-log to nutrition!
    let log_food_requested = args.get("log_food").and_then(|v| v.as_bool()).unwrap_or(true);
    if detect.can_log_food && log_food_requested && !dup.is_some() {
        let meal_type = c35_mod_consumption::infer_meal_type(note, locale);
        let food_items: Vec<c35_mod_consumption::ConsumptionItem> = detect.items.iter().map(|i| {
            c35_mod_consumption::ConsumptionItem {
                name: i.name.clone(),
                name_id: i.name_id.clone(),
                qty: i.qty,
                obj_id: i.obj_id,
                calories: 250,
                protein: 10,
                fat: 8,
                carbs: 25,
                fiber: 2,
                sugar: 4,
                sodium: 300,
                potassium: 150,
                iron: 1,
                cholesterol: 15,
                purines: 20,
                verified: i.obj_id > 0,
                confidence: if i.obj_id > 0 { 0.90 } else { 0.65 },
            }
        }).collect();
        let mfp = c35_mod_consumption::meal_fingerprint(&food_items);
        if let Ok(cid) = c35_mod_consumption::food_put(
            &ctx.pool,
            ctx.owner_iid,
            &receipt.headline,
            &photo_hash,
            &pics,
            &mfp,
            meal_type,
            &food_items,
        ).await {
            receipt.linked_consumption_id = Some(cid);
            let _ = sqlx::query(
                "UPDATE site.tx SET tx_data_json = tx_data_json || $3 WHERE site_iid = $1 AND tx_id = $2"
            )
            .bind(ctx.owner_iid)
            .bind(tx_id)
            .bind(serde_json::json!({ "consumption_id": cid }))
            .execute(&ctx.pool)
            .await;
        }
    }

    let block = expense_receipt_block(&receipt, locale);
    let total = if detect.total_minor > 0 { detect.total_minor } else { expense_total_minor(&detect.items) };
    let coach = expense_log_coach(true, total, so_far, dup.is_some(), &detect.currency, locale);

    let full = json!({
        "ok": true,
        "saved": true,
        "duplicate": dup.is_some(),
        "tx_id": tx_id.to_string(),
        "headline": receipt.headline,
        "coach": coach,
        "total_minor": total,
        "currency": detect.currency,
        "math_verified": detect.math_verified,
        "can_log_food": detect.can_log_food,
        "linked_consumption_id": receipt.linked_consumption_id.map(|id| id.to_string()),
        "payment_method": detect.payment_method,
        "items": detect.items,
        "today": &today,
        "block": block,
    });
    ctx.set_title(expense_chat_title(&detect.items, locale));
    let compact = expense_compact_for_llm(&full);
    Ok(json!({
        "ok": true,
        "runner": "cluster",
        "tool": "expense.add",
        "llm": compact,
        "block": block,
        "saved": true,
    }))
}

pub async fn expense_summary_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let day_id = args.get("day_id").and_then(|v| v.as_str());
    let days = args.get("days").and_then(|v| v.as_i64()).unwrap_or(1).clamp(1, 30) as i32;
    let category_path = args
        .get("category_path")
        .and_then(|v| v.as_str())
        .filter(|s| !s.trim().is_empty());
    let item_query = args
        .get("item_query")
        .and_then(|v| v.as_str())
        .filter(|s| !s.trim().is_empty());

    let glance = match expense_summary(
        &ctx.pool,
        ctx.owner_iid,
        &ctx.locale,
        day_id,
        days,
        category_path,
        item_query,
    )
    .await
    {
        Ok(g) => g,
        Err(e) => return Ok(json!({ "ok": false, "runner": "cluster", "tool": "expense.summary", "error": e })),
    };
    let coach = glance_coach_with_match(&glance, &ctx.locale);
    let glance_with_coach = c35_mod_expense::ExpenseGlance {
        coach: coach.clone(),
        ..glance
    };
    let block = expense_glance_block(&glance_with_coach);
    let period_id = glance_with_coach.period_id.clone();
    let full = json!({
        "ok": true,
        "period_id": period_id,
        "glance": glance_with_coach,
        "coach": &coach,
        "block": block,
    });
    let compact = summary_compact_for_llm(&full);
    Ok(json!({
        "ok": true,
        "runner": "cluster",
        "tool": "expense.summary",
        "llm": compact,
        "block": block,
    }))
}

pub async fn expense_delete_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let id_s = args.get("tx_id").and_then(|v| v.as_str()).unwrap_or("").trim();
    let locale = ctx.locale.as_str();
    let day = today_day_id(locale);
    let (start, end) = day_bounds_ms(&day, locale).unwrap_or((0, i64::MAX));

    let (id, target) = if !id_s.is_empty() {
        let parsed = id_s.parse::<i64>().unwrap_or(0);
        if parsed == 0 {
            return Ok(json!({ "ok": false, "error": "invalid tx_id" }));
        }
        let receipt = expense_get(&ctx.pool, ctx.owner_iid, parsed).await.unwrap_or(None);
        (parsed, receipt)
    } else {
        match expense_get_latest_today(&ctx.pool, ctx.owner_iid, start, end).await {
            Ok(Some(r)) => {
                let pid = r.tx_id.parse::<i64>().unwrap_or(0);
                (pid, Some(r))
            }
            Ok(None) => {
                let id_msg = if locale.to_lowercase().starts_with("id") {
                    "Tidak ada pengeluaran yang ditemukan untuk dihapus hari ini."
                } else {
                    "No expenses found to delete today."
                };
                return Ok(json!({ "ok": false, "error": id_msg }));
            }
            Err(e) => return Ok(json!({ "ok": false, "error": e })),
        }
    };

    if id == 0 {
        return Ok(json!({ "ok": false, "error": "expense not found" }));
    }

    match expense_delete(&ctx.pool, ctx.owner_iid, id).await {
        Ok(true) => {
            let (so_far, tx_count) = spending_sum_day(&ctx.pool, ctx.owner_iid, start, end)
                .await
                .unwrap_or((0, 0));
            let msg = if locale.to_lowercase().starts_with("id") {
                format!("Pengeluaran berhasil dihapus. Total hari ini: {} ({} transaksi).", so_far, tx_count)
            } else {
                format!("Expense deleted. Remaining today: {} ({} purchases).", so_far, tx_count)
            };
            Ok(json!({
                "ok": true,
                "deleted": true,
                "tx_id": id.to_string(),
                "expense": target,
                "message": msg,
                "today": { "so_far_minor": so_far, "tx_count": tx_count }
            }))
        }
        Ok(false) => Ok(json!({ "ok": false, "error": "expense not found or already deleted" })),
        Err(e) => Ok(json!({ "ok": false, "error": e })),
    }
}

tool! {
    struct: ExpenseAddTool,
    name: "expense.add",
    aliases: ["expense_add"],
    description: "Log a personal expense or purchase from a photo hash and/or description. Returns an expense receipt card.",
    topics: ["finance"],
    always: ["general", "finance"],
    ui_calling_key: "tool.expense.add.calling",
    ui_done_key: "tool.expense.add.done",
    parameters: {
        note: (string, "Expense note or user caption", optional),
        photo_hash: (string, "CAS image hash from attachment", optional),
        force: (boolean, "Save even if duplicate detected today", optional, default = false),
    },
    execute: |args, ctx| expense_add_exec(ctx, &args).await
}

tool! {
    struct: ExpenseSummaryTool,
    name: "expense.summary",
    aliases: ["expense_summary"],
    description: "Get personal spending summary for a day or date range with optional category and item filters.",
    topics: ["finance"],
    always: ["general", "finance"],
    ui_calling_key: "tool.expense.summary.calling",
    ui_done_key: "tool.expense.summary.done",
    readonly: true,
    parameters: {
        day_id: (string, "YYYY-MM-DD, today, or yesterday", optional, default = "today"),
        days: (integer, "Number of past days to include (1 to 30, default = 1)", optional, default = 1),
        category_path: (string, "Optional object_normalizer path prefix (e.g. consumable.food)", optional),
        item_query: (string, "Optional item name text filter (ILIKE)", optional),
    },
    execute: |args, ctx| expense_summary_exec(ctx, &args).await
}

tool! {
    struct: ExpenseDeleteTool,
    name: "expense.delete",
    aliases: ["expense_delete"],
    description: "Soft-delete a personal expense. If tx_id is omitted, deletes the most recent purchase logged today.",
    topics: ["finance"],
    always: ["general", "finance"],
    parameters: {
        tx_id: (string, "Transaction snowflake id to delete (optional, defaults to latest today)", optional),
    },
    execute: |args, ctx| expense_delete_exec(ctx, &args).await
}
