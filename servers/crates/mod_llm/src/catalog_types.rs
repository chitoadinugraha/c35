#[derive(Debug, Clone)]
pub struct LlmModelRow {
    pub id: String,
    pub provider: String,
    pub label: String,
    pub provider_model: String,
    pub input_micro_per_m: i64,
    pub output_micro_per_m: i64,
    pub supports_thinking: bool,
    pub enabled: bool,
    pub is_default: bool,
    pub sort_order: i32,
    pub family: String,
    pub version_rank: i32,
    pub source: String,
}
