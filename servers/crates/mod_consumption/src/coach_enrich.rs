use std::collections::HashMap;

use serde_json::{json, Value};
use sqlx::PgPool;

use super::day::{infer_meal_type, local_hour, multi_day_bounds_ms};
use super::store::food_list_day;
use super::today::consumption_today;

const RECOMMEND_PHRASES: &[&str] = &[
    "enaknya aku makan apa",
    "enaknya makan apa",
    "makan apa ya",
    "mau makan apa",
    "saran makan",
    "rekomendasi makan",
    "food recommendation",
    "what should i eat",
];

pub fn consumption_coach_enrich_days(user_text: &str) -> i32 {
    let t = user_text.trim().to_ascii_lowercase();
    if RECOMMEND_PHRASES.iter().any(|p| t.contains(p)) {
        3
    } else {
        1
    }
}

pub async fn consumption_coach_enrich(
    pool: &PgPool,
    owner_iid: i64,
    locale: &str,
    user_text: &str,
) -> Result<Value, String> {
    let days = consumption_coach_enrich_days(user_text);
    let today = consumption_today(pool, owner_iid, locale, None).await?;
    let current_meal_slot = infer_meal_type("", locale);
    let current_hour = local_hour(locale);
    let protein_target_g = ((today.glance.calorie_goal as f32 * 0.20) / 4.0).round() as i32;
    let protein_deficit_g = (protein_target_g - today.glance.protein).max(0);
    let mut out = json!({
        "day_id": today.day_id,
        "glance": today.glance,
        "calories_remaining": today.glance.calories_remaining,
        "protein_deficit_g": protein_deficit_g,
        "current_meal_slot": current_meal_slot,
        "current_hour": current_hour,
        "days_inspected": days,
    });
    if days > 1 {
        if let Ok((start_ms, end_ms)) = multi_day_bounds_ms(&today.day_id, days, locale) {
            if let Ok(recent_meals) = food_list_day(pool, owner_iid, start_ms, end_ms).await {
                let mut freq: HashMap<String, usize> = HashMap::new();
                for m in &recent_meals {
                    for it in &m.items {
                        let label = if locale.to_lowercase().starts_with("id") && !it.name_id.is_empty() {
                            it.name_id.clone()
                        } else {
                            it.name.clone()
                        };
                        if !label.trim().is_empty() {
                            *freq.entry(label).or_insert(0) += 1;
                        }
                    }
                }
                let mut sorted_freq: Vec<_> = freq.into_iter().collect();
                sorted_freq.sort_by(|a, b| b.1.cmp(&a.1));
                out["recent_frequent_foods"] = json!(sorted_freq.into_iter().take(5).map(|(name, count)| {
                    json!({ "name": name, "count": count })
                }).collect::<Vec<_>>());
            }
        }
    }
    Ok(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn enrich_days_three_for_recommendation_phrase() {
        assert_eq!(consumption_coach_enrich_days("Enaknya aku makan apa?"), 3);
        assert_eq!(consumption_coach_enrich_days("nutrition recap today"), 1);
    }
}