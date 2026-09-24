use serde_json::{json, Value};

use super::copy::food_log_headline;
use super::fingerprint::meal_kcal_total;
use super::types::{ConsumptionCardBody, ConsumptionFood, ConsumptionItem, ConsumptionTodaySummary};

pub fn consumption_food_block(
    food: &ConsumptionFood,
    locale: &str,
    saved: bool,
    duplicate: bool,
    duplicate_reason: &str,
    so_far: i32,
    after: i32,
    goal: i32,
    meals_logged: i32,
    coach: &str,
) -> Value {
    let meal_kcal = meal_kcal_total(&food.items);
    let headline = food_log_headline(saved, duplicate && !saved, &food.items, meal_kcal, locale);
    let coach = coach.trim().to_string();
    let body = ConsumptionCardBody {
        consumption_id: food.id.clone(),
        headline,
        coach,
        photo_hash: food.photo_hash.clone(),
        meal_kcal,
        duplicate,
        duplicate_reason: duplicate_reason.to_string(),
        saved,
        items: food.items.clone(),
        today: ConsumptionTodaySummary { so_far, after, goal, meals_logged },
    };
    json!({
        "kind": "consumption.food",
        "collapsed": true,
        "body": body,
    })
}

fn meal_summaries(meals: &[ConsumptionFood], locale: &str) -> Vec<Value> {
    meals
        .iter()
        .map(|m| {
            let kcal = meal_kcal_total(&m.items);
            let label = if m.note.trim().is_empty() {
                super::fingerprint::food_name_label(&m.items, locale)
            } else {
                m.note.trim().to_string()
            };
            json!({
                "id": m.id,
                "label": label,
                "kcal": kcal,
                "item_count": m.items.len(),
                "photo_hash": m.photo_hash,
            })
        })
        .collect()
}

pub fn consumption_glance_block(
    day_id: &str,
    glance: &super::types::ConsumptionGlance,
    coach: &str,
    meals: &[ConsumptionFood],
    locale: &str,
    matched_query: &str,
    matched_items: &[ConsumptionItem],
    matched_kcal: i32,
) -> Value {
    let body = json!({
        "day_id": day_id,
        "coach": coach,
        "glance": glance,
        "meals": meal_summaries(meals, locale),
        "matched_query": matched_query,
        "matched_items": matched_items,
        "matched_kcal": matched_kcal,
    });
    json!({
        "kind": "consumption.glance",
        "collapsed": false,
        "body": body,
    })
}

pub fn append_block(blocks_json: &str, block: Value) -> String {
    let mut arr: Vec<Value> = if blocks_json.trim().is_empty() || blocks_json.trim() == "[]" {
        vec![]
    } else {
        serde_json::from_str(blocks_json).unwrap_or_default()
    };
    arr.push(block);
    serde_json::to_string(&arr).unwrap_or_else(|_| "[]".to_string())
}

pub fn replace_consumption_block(blocks_json: &str, consumption_id: &str, block: Value) -> String {
    let mut arr: Vec<Value> = if blocks_json.trim().is_empty() || blocks_json.trim() == "[]" {
        vec![]
    } else {
        serde_json::from_str(blocks_json).unwrap_or_default()
    };
    let mut replaced = false;
    for b in &mut arr {
        let id = b.get("body").and_then(|x| x.get("consumption_id")).and_then(|x| x.as_str()).unwrap_or("");
        if id == consumption_id {
            *b = block.clone();
            replaced = true;
            break;
        }
    }
    if !replaced {
        arr.push(block);
    }
    serde_json::to_string(&arr).unwrap_or_else(|_| "[]".to_string())
}

pub fn food_with_items(id: i64, note: &str, photo_hash: &str, fingerprint: &str, items: Vec<ConsumptionItem>) -> ConsumptionFood {
    ConsumptionFood {
        id: id.to_string(),
        note: note.to_string(),
        items,
        photo_hash: photo_hash.to_string(),
        meal_fingerprint: fingerprint.to_string(),
        meal_type: "other".into(),
    }
}
