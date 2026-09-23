use serde_json::{json, Value};

pub fn consumption_compact_for_llm(full: &Value) -> Value {
    json!({
        "ok": full.get("ok"),
        "saved": full.get("saved"),
        "duplicate": full.get("duplicate"),
        "consumption_id": full.get("consumption_id"),
        "meal_name": full.get("meal_name"),
        "meal_kcal": full.get("meal_kcal"),
        "headline": full.get("headline"),
        "coach": full.get("coach"),
        "repeat_food_today": full.get("repeat_food_today"),
        "repeat_count_today": full.get("repeat_count_today"),
        "last_meal_name": full.get("last_meal_name"),
        "pct_of_goal": full.get("pct_of_goal"),
        "today": full.get("today"),
        "items": full.get("items").and_then(|v| v.as_array()).map(|a| {
            a.iter().map(|i| json!({
                "name": i.get("name"),
                "name_id": i.get("name_id"),
                "qty": i.get("qty"),
                "calories": i.get("calories"),
                "obj_id": i.get("obj_id"),
            })).collect::<Vec<_>>()
        }),
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
