use sqlx::PgPool;

use super::day::{day_bounds_ms, resolve_day_id, today_day_id};
use super::fingerprint::meal_kcal_total;
use super::store::{food_list_day, nutrition_sum_day, prefs_calorie_goal};
use super::types::{ConsumptionFood, ConsumptionGlance, ConsumptionItem, ConsumptionToday};

pub fn items_matching_query(meals: &[ConsumptionFood], query: &str) -> Vec<ConsumptionItem> {
    let q = query.trim().to_ascii_lowercase();
    if q.is_empty() {
        return vec![];
    }
    meals
        .iter()
        .flat_map(|m| m.items.iter())
        .filter(|i| {
            i.name.to_ascii_lowercase().contains(&q)
                || i.name_id.to_ascii_lowercase().contains(&q)
        })
        .cloned()
        .collect()
}

pub async fn consumption_today(
    pool: &PgPool,
    owner_iid: i64,
    locale: &str,
    day_id: Option<&str>,
) -> Result<ConsumptionToday, String> {
    let day = day_id
        .filter(|s| !s.is_empty())
        .map(|s| resolve_day_id(s, locale))
        .unwrap_or_else(|| today_day_id(locale));
    let (start, end) = day_bounds_ms(&day, locale).map_err(|e| e.to_string())?;
    let (calories, protein, fat, carbs, meals_logged) = nutrition_sum_day(pool, owner_iid, start, end).await?;
    let goal = prefs_calorie_goal(pool, owner_iid).await?;
    let meals = food_list_day(pool, owner_iid, start, end).await?;
    Ok(ConsumptionToday {
        day_id: day,
        glance: ConsumptionGlance {
            calories,
            protein,
            fat,
            carbs,
            meals_logged,
            calorie_goal: goal,
            calories_remaining: (goal - calories).max(0),
        },
        meals,
    })
}

pub fn matched_items_kcal(items: &[ConsumptionItem]) -> i32 {
    meal_kcal_total(items)
}
