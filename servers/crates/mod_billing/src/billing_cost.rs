use c35_mod_llm::model_cost_usd;

/// 50% retail markup over wholesale provider rates.
pub const RETAIL_MARKUP: f64 = 1.50;

pub fn billing_to_retail_usd(wholesale_usd: f64) -> f64 { wholesale_usd * RETAIL_MARKUP }

pub fn billing_cost_wholesale_usd(model: &str, tokens_in: i32, tokens_out: i32) -> f64 {
    model_cost_usd(model, tokens_in, tokens_out)
}

pub fn billing_cost_usd(model: &str, tokens_in: i32, tokens_out: i32) -> f64 {
    billing_to_retail_usd(billing_cost_wholesale_usd(model, tokens_in, tokens_out))
}
