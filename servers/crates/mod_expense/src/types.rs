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
    pub currency: String,
    pub saved: bool,
    pub duplicate: bool,
    pub duplicate_reason: String,
    pub photo_hash: String,
    pub payment_method: String,
    pub items: Vec<ExpenseItem>,
    pub today: ExpenseTodaySummary,
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
    pub items: Vec<ExpenseItem>,
}
