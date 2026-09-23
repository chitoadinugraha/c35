use c35_mod_llm::model_cost_usd;

/// 50% retail markup over wholesale provider rates.
pub const RETAIL_MARKUP: f64 = 1.50;

/// Escrow hold while cloud STT is in flight.
pub const VOICE_STT_HOLD_USD: f64 = 0.01;
/// Escrow hold while cloud TTS is in flight.
pub const VOICE_TTS_HOLD_USD: f64 = 0.01;
/// Retail STT rate ($/minute of audio).
pub const VOICE_STT_USD_PER_MIN: f64 = 0.006;
/// Retail TTS rate ($/1k characters).
pub const VOICE_TTS_USD_PER_1K_CHARS: f64 = 0.004;

/// Standard image generation wholesale cost per image ($0.035).
pub const IMAGE_GEN_WHOLESALE_USD: f64 = 0.035;
/// Standard image generation retail cost ($0.0525).
pub const IMAGE_GEN_RETAIL_USD: f64 = IMAGE_GEN_WHOLESALE_USD * RETAIL_MARKUP;

pub fn billing_to_retail_usd(wholesale_usd: f64) -> f64 { wholesale_usd * RETAIL_MARKUP }

pub fn billing_cost_wholesale_usd(model: &str, tokens_in: i32, tokens_out: i32) -> f64 {
    model_cost_usd(model, tokens_in, tokens_out)
}

pub fn billing_cost_usd(model: &str, tokens_in: i32, tokens_out: i32) -> f64 {
    billing_to_retail_usd(billing_cost_wholesale_usd(model, tokens_in, tokens_out))
}

pub fn billing_tool_cost_usd(tool_name: &str, ok: bool) -> f64 {
    if !ok {
        return 0.0;
    }
    match tool_name {
        "img.generate" | "image.generate" | "img_generate" => IMAGE_GEN_RETAIL_USD,
        _ => 0.0,
    }
}
