mod block;
mod coach;
mod compact;
mod copy;
mod day;
mod events;
mod detect;
mod fingerprint;
mod rpc;
mod store;
mod today;
mod types;

pub use block::{
    append_block, consumption_food_block, consumption_glance_block, food_with_items, replace_consumption_block,
};
pub use compact::{consumption_compact_for_llm, items_compact_for_llm, meal_hints_json, nutrition_summary_json, today_compact_for_llm};
pub use coach::{build_food_coach_ctx, food_coach_llm, today_food_counts, FoodCoachCtx};
pub use copy::{food_chat_title, food_log_coach, food_log_headline, today_recap_coach};
pub use day::{day_bounds_ms, day_id_from_query, infer_meal_type, local_hour, multi_day_bounds_ms, resolve_day_id, today_day_id, timezone_from_locale};
pub use detect::{detect_pic, detect_text, items_from_json};
pub use fingerprint::{food_name_label, item_locale_name, meal_fingerprint, meal_kcal_total};
pub use store::{
    food_delete, food_duplicate_today, food_get, food_get_latest_today, food_list_day, food_put, food_update,
    nutrition_sum_day, nutrition_sum_range, prefs_calorie_goal,
};
pub use events::{consumption_meal_deleted_emit, consumption_meal_emit};
pub use rpc::{consumption_list_rpc, consumption_put_rpc};
pub use today::{consumption_today, items_matching_query, matched_items_kcal};
pub use types::{ConsumptionFood, ConsumptionGlance, ConsumptionItem, ConsumptionToday, DEFAULT_CALORIE_GOAL, NutritionSummary};
