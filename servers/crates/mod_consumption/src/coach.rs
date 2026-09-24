use std::collections::HashMap;

use serde_json::json;
use sqlx::PgPool;

use super::copy::food_log_coach;
use super::day::{multi_day_bounds_ms, today_day_id};
use super::detect::gemini_plain_text;
use super::fingerprint::{food_name_label, item_locale_name};
use super::store::{food_list_day, nutrition_sum_range};
use super::types::{ConsumptionFood, ConsumptionItem, NutritionSummary};

const COACH_PROMPT: &str = r#"You are a warm, professional nutrition assistant writing a short coach note on a meal log card.

Write exactly 1-2 conversational sentences in the user's language (see locale in context).
Be specific to this meal — mention what you notice about the food (taste, portion, fat/protein/sodium/sugar when relevant).
If recent_meal_names shows what they ate earlier today, you may reference it naturally.
If the same food appears multiple times today (today_food_counts or repeat_count_today), gently mention it — e.g. "Jangan terlalu banyak makan Indomie, kamu sudah makan 2x Indomie hari ini."
Use daily and weekly macro summaries to spot patterns (high fat/sodium/carb days, protein deficit) — keep it light, never preachy.
If daily calories are near or over calorie_goal, weave in a gentle budget nudge.
If meal_saved is false and duplicate_logged_again is true, the user tried to log something already recorded today — note it gently and do not say it was saved.
Never use robotic phrases like "telah berhasil dicatat", "masih masuk akal", or "logged successfully".
No bullet points, no quotes, no JSON — plain text only."#;

#[derive(Debug, Clone)]
pub struct FoodCoachCtx {
    pub locale: String,
    pub meal_name: String,
    pub meal_kcal: i32,
    pub items: Vec<ConsumptionItem>,
    pub recent_meal_names: Vec<String>,
    pub daily: NutritionSummary,
    pub weekly: NutritionSummary,
    pub calorie_goal: i32,
    pub meal_saved: bool,
    pub duplicate_logged_again: bool,
    pub repeat_count_today: usize,
    pub today_food_counts: Vec<(String, usize)>,
}

pub fn today_food_counts(meals: &[ConsumptionFood], locale: &str) -> Vec<(String, usize)> {
    let mut freq: HashMap<String, usize> = HashMap::new();
    for m in meals {
        for it in &m.items {
            let label = item_locale_name(it, locale);
            if label.is_empty() {
                continue;
            }
            *freq.entry(label).or_insert(0) += 1;
        }
    }
    let mut out: Vec<_> = freq.into_iter().collect();
    out.sort_by(|a, b| b.1.cmp(&a.1).then_with(|| a.0.cmp(&b.0)));
    out
}

fn repeat_count_today(meals: &[ConsumptionFood], items: &[ConsumptionItem], locale: &str) -> usize {
    let primary = items.first();
    let primary_norm = primary
        .map(|i| item_locale_name(i, locale).to_lowercase())
        .unwrap_or_default();
    let primary_obj = primary.map(|i| i.obj_id).unwrap_or(0);
    if primary_norm.is_empty() && primary_obj == 0 {
        return 0;
    }
    let mut count = 0usize;
    for m in meals {
        for it in &m.items {
            let it_norm = item_locale_name(it, locale).to_lowercase();
            if (!primary_norm.is_empty() && it_norm == primary_norm) || (primary_obj > 0 && it.obj_id == primary_obj) {
                count += 1;
            }
        }
    }
    count
}

fn recent_meal_names(meals: &[ConsumptionFood], exclude_id: &str, locale: &str, limit: usize) -> Vec<String> {
    meals
        .iter()
        .filter(|m| m.id != exclude_id)
        .rev()
        .take(limit)
        .map(|m| food_name_label(&m.items, locale))
        .filter(|n| !n.is_empty())
        .collect()
}

pub async fn build_food_coach_ctx(
    pool: &PgPool,
    owner_iid: i64,
    locale: &str,
    food: &ConsumptionFood,
    meal_kcal: i32,
    calorie_goal: i32,
    meal_saved: bool,
    duplicate_logged_again: bool,
    day_start_ms: i64,
    day_end_ms: i64,
) -> FoodCoachCtx {
    let day = today_day_id(locale);
    let day_meals = food_list_day(pool, owner_iid, day_start_ms, day_end_ms).await.unwrap_or_default();
    let daily = nutrition_sum_range(pool, owner_iid, day_start_ms, day_end_ms)
        .await
        .unwrap_or_default();
    let weekly = match multi_day_bounds_ms(&day, 7, locale) {
        Ok((start, end)) => nutrition_sum_range(pool, owner_iid, start, end).await.unwrap_or_default(),
        Err(_) => NutritionSummary::default(),
    };
    FoodCoachCtx {
        locale: locale.to_string(),
        meal_name: food_name_label(&food.items, locale),
        meal_kcal,
        items: food.items.clone(),
        recent_meal_names: recent_meal_names(&day_meals, &food.id, locale, 4),
        daily,
        weekly,
        calorie_goal,
        meal_saved,
        duplicate_logged_again,
        repeat_count_today: repeat_count_today(&day_meals, &food.items, locale),
        today_food_counts: today_food_counts(&day_meals, locale),
    }
}

fn summary_json(s: &NutritionSummary) -> serde_json::Value {
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

fn items_json(items: &[ConsumptionItem], locale: &str) -> Vec<serde_json::Value> {
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

fn coach_prompt(ctx: &FoodCoachCtx) -> String {
    let id = ctx.locale.to_lowercase().starts_with("id");
    let lang = if id { "id" } else { "en" };
    let pct = if ctx.calorie_goal > 0 {
        (ctx.daily.calories as f32 / ctx.calorie_goal as f32 * 100.0).round() as i32
    } else {
        0
    };
    let today_counts = ctx
        .today_food_counts
        .iter()
        .map(|(name, count)| json!({ "name": name, "count": count }))
        .collect::<Vec<_>>();
    let mut daily = summary_json(&ctx.daily);
    if let Some(obj) = daily.as_object_mut() {
        obj.insert("calorie_goal".into(), json!(ctx.calorie_goal));
        obj.insert("pct_of_goal".into(), json!(pct));
    }
    let context = json!({
        "locale": lang,
        "meal": {
            "name": ctx.meal_name,
            "kcal": ctx.meal_kcal,
            "items": items_json(&ctx.items, &ctx.locale),
        },
        "recent_meal_names": ctx.recent_meal_names,
        "daily": daily,
        "weekly": summary_json(&ctx.weekly),
        "meal_saved": ctx.meal_saved,
        "repeat_count_today": ctx.repeat_count_today,
        "duplicate_logged_again": ctx.duplicate_logged_again,
        "today_food_counts": today_counts,
    });
    format!("{COACH_PROMPT}\n\nContext:\n{context}")
}

fn sanitize_coach(raw: &str) -> String {
    let s = raw.trim().trim_matches('"').replace('\n', " ");
    if s.is_empty() {
        return String::new();
    }
    if s.len() > 300 {
        return format!("{}…", s.chars().take(297).collect::<String>());
    }
    s
}

pub async fn food_coach_llm(pool: &PgPool, owner_iid: i64, ctx: &FoodCoachCtx) -> String {
    let fallback = food_log_coach(
        &ctx.items,
        ctx.daily.calories,
        ctx.calorie_goal,
        ctx.duplicate_logged_again,
        &ctx.locale,
    );
    match gemini_plain_text(pool, owner_iid, &coach_prompt(ctx), 0.65).await {
        Ok(raw) => {
            let coach = sanitize_coach(&raw);
            if coach.is_empty() { fallback } else { coach }
        }
        Err(_) => fallback,
    }
}
