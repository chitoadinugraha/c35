mod block;
mod compact;
mod copy;
mod day;
mod detect;
mod fingerprint;
mod rpc;
mod store;
mod today;
mod types;

pub use block::{
    append_block, consumption_food_block, consumption_glance_block, food_with_items, replace_consumption_block,
};
pub use compact::{consumption_compact_for_llm, today_compact_for_llm};
pub use copy::{food_log_coach, food_log_headline, today_recap_coach};
pub use day::{day_bounds_ms, resolve_day_id, today_day_id, timezone_from_locale};
pub use detect::{detect_pic, detect_text, items_from_json};
pub use fingerprint::{food_name_label, meal_fingerprint, meal_kcal_total};
pub use store::{
    food_duplicate_today, food_get, food_list_day, food_put, food_update, nutrition_sum_day, prefs_calorie_goal,
};
pub use rpc::{consumption_list_rpc, consumption_put_rpc};
pub use today::{consumption_today, items_matching_query, matched_items_kcal};
pub use types::{ConsumptionFood, ConsumptionGlance, ConsumptionItem, ConsumptionToday, DEFAULT_CALORIE_GOAL};
