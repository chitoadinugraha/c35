use serde::{Deserialize, Serialize};

pub const DEFAULT_CURRENCY: &str = "IDR";

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ExpenseItem {
    pub name: String,
    pub name_id: String,
    pub qty: f32,
    #[serde(default)]
    pub obj_id: i64,
    pub price_minor: i64,
    pub total_minor: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ExpenseReceipt {
    pub tx_id: String,
    pub headline: String,
    pub subtitle: String,
    pub coach: String,
    pub total_minor: i64,
    #[serde(default = "default_currency")]
    pub currency: String,
    #[serde(default)]
    pub subtotal_minor: i64,
    #[serde(default)]
    pub tax_minor: i64,
    #[serde(default)]
    pub service_minor: i64,
    #[serde(default)]
    pub discount_minor: i64,
    #[serde(default = "default_true")]
    pub math_verified: bool,
    #[serde(default)]
    pub math_discrepancy_minor: i64,
    #[serde(default)]
    pub is_dining: bool,
    #[serde(default)]
    pub can_log_food: bool,
    #[serde(default)]
    pub linked_consumption_id: Option<i64>,
    pub saved: bool,
    pub duplicate: bool,
    pub duplicate_reason: String,
    pub photo_hash: String,
    pub payment_method: String,
    pub items: Vec<ExpenseItem>,
    pub today: ExpenseTodaySummary,
}

fn default_currency() -> String {
    DEFAULT_CURRENCY.to_string()
}

fn default_true() -> bool {
    true
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ExpenseTodaySummary {
    pub so_far_minor: i64,
    pub after_minor: i64,
    pub tx_count: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ExpenseCategoryBreakdown {
    pub label: String,
    pub path: String,
    pub total_minor: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ExpenseRecent {
    pub tx_id: String,
    pub label: String,
    pub subtitle: String,
    pub total_minor: i64,
    pub photo_hash: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ExpenseGlance {
    pub period_id: String,
    pub period_label: String,
    pub coach: String,
    pub total_minor: i64,
    pub tx_count: i32,
    pub currency: String,
    pub matched_query: String,
    pub matched_total_minor: i64,
    pub category_breakdown: Vec<ExpenseCategoryBreakdown>,
    pub recent: Vec<ExpenseRecent>,
}

#[derive(Debug, Clone, Default)]
pub struct ExpenseDetectResult {
    pub subject: String,
    pub headline: String,
    pub payment_method: String,
    pub currency: String,
    pub subtotal_minor: i64,
    pub tax_minor: i64,
    pub service_minor: i64,
    pub discount_minor: i64,
    pub total_minor: i64,
    pub math_verified: bool,
    pub math_discrepancy_minor: i64,
    pub is_dining: bool,
    pub is_groceries: bool,
    pub can_log_food: bool,
    pub items: Vec<ExpenseItem>,
}
