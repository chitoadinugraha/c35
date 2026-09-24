use serde::{Deserialize, Serialize};

pub const DEFAULT_CALORIE_GOAL: i32 = 2000;

#[derive(Debug, Clone, Default)]
pub struct NutritionSummary {
    pub calories: i32,
    pub protein: i32,
    pub fat: i32,
    pub carbs: i32,
    pub fiber: i32,
    pub sugar: i32,
    pub sodium: i32,
    pub meals_logged: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ConsumptionItem {
    pub name: String,
    pub name_id: String,
    pub qty: f32,
    #[serde(default)]
    pub obj_id: i64,
    pub calories: i32,
    pub protein: i32,
    pub fat: i32,
    pub carbs: i32,
    pub fiber: i32,
    pub sugar: i32,
    pub sodium: i32,
    #[serde(default)]
    pub potassium: i32,
    #[serde(default)]
    pub iron: i32,
    #[serde(default)]
    pub cholesterol: i32,
    #[serde(default)]
    pub purines: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ConsumptionFood {
    pub id: String,
    pub note: String,
    pub items: Vec<ConsumptionItem>,
    pub photo_hash: String,
    pub meal_fingerprint: String,
    pub meal_type: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ConsumptionGlance {
    pub calories: i32,
    pub protein: i32,
    pub fat: i32,
    pub carbs: i32,
    pub meals_logged: i32,
    pub calorie_goal: i32,
    pub calories_remaining: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ConsumptionToday {
    pub day_id: String,
    pub glance: ConsumptionGlance,
    pub meals: Vec<ConsumptionFood>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConsumptionCardBody {
    pub consumption_id: String,
    pub headline: String,
    pub coach: String,
    pub photo_hash: String,
    pub meal_kcal: i32,
    pub duplicate: bool,
    pub duplicate_reason: String,
    pub saved: bool,
    pub items: Vec<ConsumptionItem>,
    pub today: ConsumptionTodaySummary,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ConsumptionTodaySummary {
    pub so_far: i32,
    pub after: i32,
    pub goal: i32,
    pub meals_logged: i32,
}
