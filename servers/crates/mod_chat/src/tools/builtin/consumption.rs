use crate::tool;
use anyhow::{anyhow, Result};
use c35_mod_consumption::{
    consumption_compact_for_llm, consumption_food_block, consumption_glance_block, consumption_today,
    day_bounds_ms, detect_pic, detect_text, food_delete, food_duplicate_today, food_get,
    food_get_latest_today, food_put, food_update, food_with_items, infer_meal_type, items_from_json,
    items_matching_query, matched_items_kcal, meal_fingerprint, meal_kcal_total, nutrition_sum_day,
    prefs_calorie_goal, resolve_day_id, today_compact_for_llm, today_day_id, today_recap_coach,
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

async fn load_photo(pool: &PgPool, hash: &str) -> Result<(Vec<u8>, String)> {
    if hash.is_empty() {
        return Err(anyhow!("photo required"));
    }
    cas_bytes_get(pool, &cas_dir_default(), hash)
        .await
        .map_err(|e| anyhow!(e.to_string()))
}

pub async fn consumption_add_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
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

    let items = if !photo_hash.is_empty() {
        match load_photo(&ctx.pool, &photo_hash).await {
            Ok((bytes, mime)) => detect_pic(&ctx.pool, ctx.owner_iid, &bytes, &mime, note).await,
            Err(e) => {
                return Ok(json!({ "ok": false, "runner": "cluster", "tool": "consumption.add", "error": e.to_string() }));
            }
        }
    } else if !note.is_empty() {
        detect_text(&ctx.pool, ctx.owner_iid, note).await
    } else {
        Err("photo or note required".into())
    };

    let items = match items {
        Ok(v) => v,
        Err(e) => return Ok(json!({ "ok": false, "runner": "cluster", "tool": "consumption.add", "error": e })),
    };

    let fingerprint = meal_fingerprint(&items);
    let locale = ctx.locale.as_str();
    let day = today_day_id(locale);
    let (start, end) = day_bounds_ms(&day, locale).unwrap_or((0, i64::MAX));
    let goal = prefs_calorie_goal(&ctx.pool, ctx.owner_iid).await.unwrap_or(2000);
    let (so_far_before, _, _, _, meals_before) = nutrition_sum_day(&ctx.pool, ctx.owner_iid, start, end)
        .await
        .unwrap_or((0, 0, 0, 0, 0));
    let meal_kcal = meal_kcal_total(&items);

    let dup = food_duplicate_today(&ctx.pool, ctx.owner_iid, start, end, &photo_hash, &fingerprint)
        .await
        .unwrap_or(None);
    if dup.is_some() && !force {
        let food = food_with_items(0, note, &photo_hash, &fingerprint, items.clone());
        let after = so_far_before;
        let block = consumption_food_block(
            &food,
            locale,
            false,
            true,
            dup.as_ref().map(|(_, r)| r.as_str()).unwrap_or("meal"),
            so_far_before,
            after,
            goal,
            meals_before,
        );
        let full = json!({
            "ok": true,
            "saved": false,
            "duplicate": true,
            "duplicate_reason": dup.map(|(_, r)| r).unwrap_or_default(),
            "consumption_id": "",
            "meal_kcal": meal_kcal,
            "headline": block["body"]["headline"],
            "items": food.items,
            "today": { "so_far": so_far_before, "after": after, "goal": goal, "meals_logged": meals_before },
            "block": block,
            "llm": consumption_compact_for_llm(&json!({ "ok": true, "saved": false, "duplicate": true })),
        });
        return Ok(full);
    }

    let meal_note = if note.is_empty() { "Meal" } else { note };
    let explicit_meal_type = args.get("meal_type").and_then(|v| v.as_str()).unwrap_or("").trim();
    let meal_type = if !explicit_meal_type.is_empty() && explicit_meal_type != "other" {
        explicit_meal_type
    } else {
        infer_meal_type(note, locale)
    };

    let id = match food_put(
        &ctx.pool,
        ctx.owner_iid,
        meal_note,
        &photo_hash,
        &pics,
        &fingerprint,
        meal_type,
        &items,
    )
    .await
    {
        Ok(id) => id,
        Err(e) => return Ok(json!({ "ok": false, "runner": "cluster", "tool": "consumption.add", "error": e })),
    };
    let (so_far, _, _, _, meals_logged) = nutrition_sum_day(&ctx.pool, ctx.owner_iid, start, end)
        .await
        .unwrap_or((0, 0, 0, 0, 0));
    let after = so_far;
    let dup_reason = if dup.is_some() { "meal" } else { "" };
    let food = food_with_items(id, meal_note, &photo_hash, &fingerprint, items);
    let block = consumption_food_block(
        &food,
        locale,
        true,
        dup.is_some(),
        dup_reason,
        so_far_before,
        after,
        goal,
        meals_logged,
    );
    let full = json!({
        "ok": true,
        "saved": true,
        "duplicate": dup.is_some(),
        "duplicate_reason": dup_reason,
        "consumption_id": id.to_string(),
        "meal_kcal": meal_kcal,
        "headline": block["body"]["headline"],
        "coach": block["body"]["coach"],
        "items": food.items,
        "photo_hash": photo_hash,
        "today": { "so_far": so_far, "after": after, "goal": goal, "meals_logged": meals_logged },
        "block": block,
    });
    let compact = consumption_compact_for_llm(&full);
    Ok(json!({ "ok": true, "runner": "cluster", "tool": "consumption.add", "llm": compact, "block": block, "saved": true }))
}

pub async fn consumption_today_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let day_id = args.get("day_id").and_then(|v| v.as_str());
    let item_query = args
        .get("item_query")
        .and_then(|v| v.as_str())
        .filter(|s| !s.trim().is_empty());
    let today = match consumption_today(&ctx.pool, ctx.owner_iid, &ctx.locale, day_id).await {
        Ok(t) => t,
        Err(e) => return Ok(json!({ "ok": false, "runner": "cluster", "tool": "consumption.today", "error": e })),
    };
    let coach = today_recap_coach(&today.glance, &ctx.locale);
    let matched_query = item_query.unwrap_or("").trim();
    let matched = if matched_query.is_empty() {
        vec![]
    } else {
        items_matching_query(&today.meals, matched_query)
    };
    let matched_kcal = matched_items_kcal(&matched);
    let block = consumption_glance_block(
        &today.day_id,
        &today.glance,
        &coach,
        &today.meals,
        &ctx.locale,
        matched_query,
        &matched,
        matched_kcal,
    );
    let full = json!({
        "ok": true,
        "day_id": today.day_id,
        "glance": today.glance,
        "meals": today.meals,
        "coach": coach,
        "block": block,
    });
    let mut compact = today_compact_for_llm(&full);
    compact["coach"] = json!(coach);
    if !matched.is_empty() {
        compact["matched_items"] = serde_json::to_value(&matched).unwrap_or(json!([]));
        compact["matched_kcal"] = json!(matched_kcal);
        compact["matched_query"] = json!(matched_query);
    }
    Ok(json!({ "ok": true, "runner": "cluster", "tool": "consumption.today", "llm": compact, "block": block }))
}

pub async fn consumption_update_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let id_s = args.get("consumption_id").and_then(|v| v.as_str()).unwrap_or("").trim();
    let id = id_s.parse::<i64>().unwrap_or(0);
    if id == 0 {
        return Ok(json!({ "ok": false, "error": "consumption_id required" }));
    }
    let items = match args.get("items_json").map(items_from_json) {
        Some(Ok(v)) => v,
        Some(Err(e)) => return Ok(json!({ "ok": false, "error": e })),
        None => return Ok(json!({ "ok": false, "error": "items_json required" })),
    };
    let fingerprint = meal_fingerprint(&items);
    if let Err(e) = food_update(&ctx.pool, ctx.owner_iid, id, &items, &fingerprint).await {
        return Ok(json!({ "ok": false, "error": e }));
    }
    let food = match food_get(&ctx.pool, ctx.owner_iid, id).await {
        Ok(Some(f)) => f,
        Ok(None) => return Ok(json!({ "ok": false, "error": "not found" })),
        Err(e) => return Ok(json!({ "ok": false, "error": e })),
    };
    let locale = ctx.locale.as_str();
    let day = resolve_day_id("today", locale);
    let (start, end) = day_bounds_ms(&day, locale).unwrap_or((0, i64::MAX));
    let goal = prefs_calorie_goal(&ctx.pool, ctx.owner_iid).await.unwrap_or(2000);
    let (so_far, _, _, _, meals_logged) = nutrition_sum_day(&ctx.pool, ctx.owner_iid, start, end)
        .await
        .unwrap_or((0, 0, 0, 0, 0));
    let block = consumption_food_block(&food, locale, true, false, "", so_far, so_far, goal, meals_logged);
    Ok(json!({ "ok": true, "block": block, "consumption_id": id.to_string() }))
}

pub async fn consumption_delete_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let id_s = args.get("consumption_id").and_then(|v| v.as_str()).unwrap_or("").trim();
    let locale = ctx.locale.as_str();
    let day = today_day_id(locale);
    let (start, end) = day_bounds_ms(&day, locale).unwrap_or((0, i64::MAX));

    let (id, target_food) = if !id_s.is_empty() {
        let parsed = id_s.parse::<i64>().unwrap_or(0);
        if parsed == 0 {
            return Ok(json!({ "ok": false, "error": "invalid consumption_id" }));
        }
        let food = food_get(&ctx.pool, ctx.owner_iid, parsed).await.unwrap_or(None);
        (parsed, food)
    } else {
        match food_get_latest_today(&ctx.pool, ctx.owner_iid, start, end).await {
            Ok(Some(f)) => {
                let pid = f.id.parse::<i64>().unwrap_or(0);
                (pid, Some(f))
            }
            Ok(None) => {
                let id_msg = if locale.to_lowercase().starts_with("id") {
                    "Tidak ada catatan makan yang ditemukan untuk dihapus hari ini."
                } else {
                    "No meals found to delete today."
                };
                return Ok(json!({ "ok": false, "error": id_msg }));
            }
            Err(e) => return Ok(json!({ "ok": false, "error": e })),
        }
    };

    if id == 0 {
        return Ok(json!({ "ok": false, "error": "consumption not found" }));
    }

    match food_delete(&ctx.pool, ctx.owner_iid, id).await {
        Ok(true) => {
            let (so_far, _, _, _, meals_logged) = nutrition_sum_day(&ctx.pool, ctx.owner_iid, start, end)
                .await
                .unwrap_or((0, 0, 0, 0, 0));
            let goal = prefs_calorie_goal(&ctx.pool, ctx.owner_iid).await.unwrap_or(2000);
            let msg = if locale.to_lowercase().starts_with("id") {
                format!("Catatan makan berhasil dihapus. Total hari ini: {} / {} kcal ({} kali makan).", so_far, goal, meals_logged)
            } else {
                format!("Meal deleted. Remaining today: {} / {} kcal ({} meals).", so_far, goal, meals_logged)
            };
            Ok(json!({
                "ok": true,
                "deleted": true,
                "consumption_id": id.to_string(),
                "meal": target_food,
                "message": msg,
                "today": { "so_far": so_far, "goal": goal, "meals_logged": meals_logged }
            }))
        }
        Ok(false) => Ok(json!({ "ok": false, "error": "meal not found or already deleted" })),
        Err(e) => Ok(json!({ "ok": false, "error": e })),
    }
}

tool! {
    struct: ConsumptionAddTool,
    name: "consumption.add",
    aliases: ["consumption_add"],
    description: "Log food consumption from a photo hash and/or meal description. Returns a meal card for the user.",
    topics: ["health"],
    always: ["general", "health"],
    parameters: {
        note: (string, "Meal note or user caption", optional),
        photo_hash: (string, "CAS image hash from attachment", optional),
        meal_type: (string, "Meal type: breakfast, lunch, dinner, snack, dessert, late_night (optional, auto-inferred if omitted)", optional),
        force: (boolean, "Save even if duplicate detected today", optional, default = false),
    },
    execute: |args, ctx| consumption_add_exec(ctx, &args).await
}

tool! {
    struct: ConsumptionTodayTool,
    name: "consumption.today",
    aliases: ["consumption_today"],
    description: "Get today's food consumption summary and logged meals for coaching or stats questions.",
    topics: ["health"],
    always: ["general", "health"],
    ui_calling_key: "tool.consumption.today.calling",
    ui_done_key: "tool.consumption.today.done",
    readonly: true,
    parameters: {
        day_id: (string, "YYYY-MM-DD, today, or yesterday", optional, default = "today"),
        item_query: (string, "Optional food name filter to sum matching items across meals", optional),
    },
    execute: |args, ctx| consumption_today_exec(ctx, &args).await
}

tool! {
    struct: ConsumptionUpdateTool,
    name: "consumption.update",
    aliases: ["consumption_update"],
    description: "Update portions/items on a logged meal.",
    topics: ["health"],
    always: ["general", "health"],
    parameters: {
        consumption_id: (string, "Consumption snowflake id", required),
        items_json: (array, "Updated item array with name, qty, calories, macros", required),
    },
    execute: |args, ctx| consumption_update_exec(ctx, &args).await
}

tool! {
    struct: ConsumptionDeleteTool,
    name: "consumption.delete",
    aliases: ["consumption_delete"],
    description: "Delete or cancel a logged food consumption entry. If consumption_id is omitted, deletes the most recent meal logged today.",
    topics: ["health"],
    always: ["general", "health"],
    parameters: {
        consumption_id: (string, "Consumption snowflake id to delete (optional, defaults to last meal today)", optional),
    },
    execute: |args, ctx| consumption_delete_exec(ctx, &args).await
}
