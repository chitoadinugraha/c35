#[derive(Debug, Clone)]
pub struct LlmModelRow {
    pub id: String,
    pub provider: String,
    pub label: String,
    pub provider_model: String,
    pub input_micro_per_m: i64,
    pub input_cache_micro_per_m: i64,
    pub output_micro_per_m: i64,
    pub supports_thinking: bool,
    pub enabled: bool,
    pub is_default: bool,
    pub sort_order: i32,
    pub family: String,
    pub version_rank: i32,
    pub source: String,
    /// Max context tokens; 0 = infer from provider/id at read time.
    pub context_tokens: i32,
}

pub fn context_tokens_infer(provider: &str, id: &str) -> i32 {
    let p = provider.trim().to_ascii_lowercase();
    let s = id.trim().to_ascii_lowercase();
    if p == "alienai" || p == "google" || s.contains("gemini") {
        return 1_048_576;
    }
    if p == "anthropic" || s.contains("claude") {
        return 200_000;
    }
    if p == "openai" {
        if s.contains("gpt-4.1") || s.contains("o1") || s.contains("o3") {
            return 1_047_576;
        }
        return 128_000;
    }
    if p == "deepseek" {
        return 128_000;
    }
    128_000
}

impl LlmModelRow {
    pub fn effective_context_tokens(&self) -> i32 {
        if self.context_tokens > 0 {
            self.context_tokens
        } else {
            context_tokens_infer(&self.provider, &self.id)
        }
    }
}
