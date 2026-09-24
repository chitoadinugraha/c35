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

/// Legacy flat image wholesale (Imagen 3 era). Prefer `image_tool_wholesale_usd`.
pub const IMAGE_GEN_WHOLESALE_USD: f64 = 0.035;
/// Legacy flat image retail. Prefer `image_tool_retail_usd`.
pub const IMAGE_GEN_RETAIL_USD: f64 = IMAGE_GEN_WHOLESALE_USD * RETAIL_MARKUP;

/// Gemini 3.1 Flash-Lite Image @ 1K (~1120 output tokens x $30/M).
pub const IMAGE_GEMINI_LITE_1K_WHOLESALE_USD: f64 = 0.0336;
/// Gemini 3.1 Flash Image @ 1K (~1120 output tokens x $60/M).
pub const IMAGE_GEMINI_1K_WHOLESALE_USD: f64 = 0.067;
/// Gemini 3.1 Flash Image @ 2K (~1680 output tokens x $60/M).
pub const IMAGE_GEMINI_2K_WHOLESALE_USD: f64 = 0.101;
/// Imagen 3 flat fallback.
pub const IMAGE_IMAGEN_WHOLESALE_USD: f64 = 0.035;
/// Grok Imagine draft via CF (`grok-imagine-image`).
pub const IMAGE_GROK_DRAFT_WHOLESALE_USD: f64 = 0.02;
/// Grok Imagine 2.0 via CF.
pub const IMAGE_GROK_2_WHOLESALE_USD: f64 = 0.04;

pub fn billing_to_retail_usd(wholesale_usd: f64) -> f64 { wholesale_usd * RETAIL_MARKUP }

pub fn billing_cost_wholesale_usd(model: &str, tokens_in: i32, tokens_out: i32) -> f64 {
    model_cost_usd(model, tokens_in, tokens_out)
}

pub fn billing_cost_usd(model: &str, tokens_in: i32, tokens_out: i32) -> f64 {
    billing_to_retail_usd(billing_cost_wholesale_usd(model, tokens_in, tokens_out))
}

pub fn image_tool_wholesale_usd(quality: &str, provider_model: &str) -> f64 {
    let q = quality.trim().to_ascii_lowercase();
    let p = provider_model.trim().to_ascii_lowercase();
    if p.contains("grok-imagine-image-quality") {
        return 0.05;
    }
    if p.contains("grok-imagine-image-2.0") || p.contains("grok-imagine-image-2") {
        return IMAGE_GROK_2_WHOLESALE_USD;
    }
    if p.contains("grok-imagine") {
        return IMAGE_GROK_DRAFT_WHOLESALE_USD;
    }
    if p.contains("imagen") {
        return IMAGE_IMAGEN_WHOLESALE_USD;
    }
    if p.contains("flash-lite-image") {
        return IMAGE_GEMINI_LITE_1K_WHOLESALE_USD;
    }
    if q == "hd" {
        IMAGE_GEMINI_2K_WHOLESALE_USD
    } else {
        IMAGE_GEMINI_1K_WHOLESALE_USD
    }
}

pub fn image_tool_retail_usd(quality: &str, provider_model: &str) -> f64 {
    billing_to_retail_usd(image_tool_wholesale_usd(quality, provider_model))
}

pub fn billing_tool_cost_usd(tool_name: &str, ok: bool) -> f64 {
    if !ok {
        return 0.0;
    }
    match tool_name {
        "img.generate" | "image.generate" | "img_generate" | "img.edit" | "image.edit" | "img_edit" => {
            IMAGE_GEN_RETAIL_USD
        }
        _ => 0.0,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn image_tool_wholesale_gemini_tiers() {
        assert_eq!(image_tool_wholesale_usd("draft", "gemini-3.1-flash-lite-image"), 0.0336);
        assert_eq!(image_tool_wholesale_usd("draft", "gemini-3.1-flash-image"), 0.067);
        assert_eq!(image_tool_wholesale_usd("hd", "gemini-3.1-flash-image"), 0.101);
    }

    #[test]
    fn image_tool_wholesale_imagen_and_grok() {
        assert_eq!(image_tool_wholesale_usd("draft", "imagen-3.0-generate-002"), 0.035);
        assert_eq!(image_tool_wholesale_usd("draft", "xai/grok-imagine-image"), 0.02);
        assert_eq!(image_tool_wholesale_usd("hd", "xai/grok-imagine-image-2.0"), 0.04);
    }

    #[test]
    fn image_tool_retail_applies_markup() {
        assert!((image_tool_retail_usd("draft", "gemini-3.1-flash-lite-image") - 0.0504).abs() < 0.0001);
        assert!((image_tool_retail_usd("draft", "gemini-3.1-flash-image") - 0.1005).abs() < 0.0001);
        assert!((image_tool_retail_usd("draft", "xai/grok-imagine-image") - 0.03).abs() < 0.0001);
    }
}
