use serde_json::{json, Value};

use super::fingerprint::item_locale_name;
use super::types::{ConsumptionItem, NutritionSummary};

pub fn nutrition_summary_json(s: &NutritionSummary) -> Value {
    json!({
        "calories": s.calories,
        "protein": s.protein,
        "fat": s.fat,
        "carbs": s.carbs,
        "fiber": s.fiber,
        "sugar": s.sugar,
        "sodium": s.sodium,
        "meals_logged": s.meals_logged,
    })
}

pub fn items_compact_for_llm(items: &[ConsumptionItem], locale: &str) -> Vec<Value> {
    items
        .iter()
        .map(|i| {
            let q = if i.qty > 0.0 { i.qty } else { 1.0 };
            json!({
                "name": item_locale_name(i, locale),
                "qty": q,
                "calories": ((i.calories as f32) * q).round() as i32,
                "protein": ((i.protein as f32) * q).round() as i32,
                "fat": ((i.fat as f32) * q).round() as i32,
                "carbs": ((i.carbs as f32) * q).round() as i32,
                "fiber": ((i.fiber as f32) * q).round() as i32,
                "sugar": ((i.sugar as f32) * q).round() as i32,
                "sodium": ((i.sodium as f32) * q).round() as i32,
            })
        })
        .collect()
}

pub fn meal_hints_json(items: &[ConsumptionItem]) -> Value {
    let mut kcal = 0i32;
    let mut fat = 0i32;
    let mut sodium = 0i32;
    let mut sugar = 0i32;
    for i in items {
        let q = if i.qty > 0.0 { i.qty } else { 1.0 };
        kcal += ((i.calories as f32) * q).round() as i32;
        fat += ((i.fat as f32) * q).round() as i32;
        sodium += ((i.sodium as f32) * q).round() as i32;
        sugar += ((i.sugar as f32) * q).round() as i32;
    }
    json!({
        "meal_kcal": kcal,
        "meal_fat_g": fat,
        "meal_sodium_mg": sodium,
        "meal_sugar_g": sugar,
        "high_kcal": kcal >= 700,
        "high_fat": fat >= 25,
        "high_sodium": sodium >= 600,
        "high_sugar": sugar >= 25,
    })
}

pub fn consumption_compact_for_llm(full: &Value) -> Value {
    json!({
        "ok": full.get("ok"),
        "saved": full.get("saved"),
        "duplicate": full.get("duplicate"),
        "consumption_id": full.get("consumption_id"),
        "meal_name": full.get("meal_name"),
        "meal_kcal": full.get("meal_kcal"),
        "headline": full.get("headline"),
        "repeat_food_today": full.get("repeat_food_today"),
        "repeat_count_today": full.get("repeat_count_today"),
        "recent_meal_names": full.get("recent_meal_names"),
        "pct_of_goal": full.get("pct_of_goal"),
        "today": full.get("today"),
        "daily": full.get("daily"),
        "weekly": full.get("weekly"),
        "meal_hints": full.get("meal_hints"),
        "items": full.get("items_compact"),
    })
}

pub fn today_compact_for_llm(full: &Value) -> Value {
    json!({
        "ok": full.get("ok"),
        "day_id": full.get("day_id"),
        "glance": full.get("glance"),
        "meals": full.get("meals").and_then(|v| v.as_array()).map(|a| {
            a.iter().map(|m| json!({
                "id": m.get("id"),
                "note": m.get("note"),
                "meal_kcal": m.get("meal_kcal"),
                "items": m.get("items"),
            })).collect::<Vec<_>>()
        }),
    })
}
