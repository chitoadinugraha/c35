use c35_mod_llm::model_cost_with_cache_usd;

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

/// Seedance 2.0-mini clip via CF Workers AI.
pub const VIDEO_SEEDANCE_MINI_WHOLESALE_USD: f64 = 0.12;
/// ElevenLabs music-v2 ~30s via CF.
pub const MUSIC_ELEVENLABS_30S_WHOLESALE_USD: f64 = 0.08;
/// Gemini Lyria clip preview.
pub const MUSIC_LYRIA_CLIP_WHOLESALE_USD: f64 = 0.06;
/// MiniMax music-2.6 per track via CF.
pub const MUSIC_MINIMAX_TRACK_WHOLESALE_USD: f64 = 0.15;
/// reCAPTCHA v2/v3 cluster captcha solve fallback (2Captcha list; see mod_captcha billing).
pub const CAPTCHA_RECAPTCHA_V2_WHOLESALE_USD: f64 = 0.002_99;

pub fn billing_to_retail_usd(wholesale_usd: f64) -> f64 { wholesale_usd * RETAIL_MARKUP }

pub fn billing_cost_wholesale_usd(model: &str, tokens_in: i32, tokens_out: i32) -> f64 {
    billing_cost_wholesale_with_cache_usd(model, tokens_in, tokens_out, 0)
}

pub fn billing_cost_wholesale_with_cache_usd(
    model: &str,
    tokens_in: i32,
    tokens_out: i32,
    cached_tokens: i32,
) -> f64 {
    if crate::billing_profile::model_uses_alien_pool(model) {
        let regular_in = (tokens_in - cached_tokens).max(0);
        let cached_in = cached_tokens.min(tokens_in).max(0);
        let cache_rate = 0.075 * 0.25; // 75% discount on cached input tokens for Alien pool wholesale ($0.01875/M)
        (regular_in as f64 * 0.075 + cached_in as f64 * cache_rate + tokens_out as f64 * 0.30)
            / 1_000_000.0
    } else {
        model_cost_with_cache_usd(model, tokens_in, tokens_out, cached_tokens)
    }
}

pub fn billing_cost_usd(model: &str, tokens_in: i32, tokens_out: i32) -> f64 {
    billing_cost_with_cache_usd(model, tokens_in, tokens_out, 0)
}

pub fn billing_cost_with_cache_usd(
    model: &str,
    tokens_in: i32,
    tokens_out: i32,
    cached_tokens: i32,
) -> f64 {
    if crate::billing_profile::model_uses_alien_pool(model) {
        crate::billing_pool::pool_alien_deduct_with_cache_usd(tokens_in, tokens_out, cached_tokens)
    } else {
        billing_to_retail_usd(billing_cost_wholesale_with_cache_usd(
            model,
            tokens_in,
            tokens_out,
            cached_tokens,
        ))
    }
}

/// Embed input retail — charged on cache hit too (avoid cost/timing oracles).
pub fn billing_embed_cost_usd(model: &str, token_in: i32) -> f64 {
    if token_in <= 0 {
        return 0.0;
    }
    let cost = billing_cost_usd(model, token_in, 0);
    if cost > 0.0 {
        return cost;
    }
    // Default embedding rate fallback: $0.15/1M wholesale ($0.00015/1k) * retail markup (1.50)
    let wholesale = (token_in as f64) * (0.15 / 1_000_000.0);
    billing_to_retail_usd(wholesale)
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

pub fn video_tool_wholesale_usd(provider: &str, model: &str) -> f64 {
    let p = provider.trim().to_ascii_lowercase();
    let m = model.trim().to_ascii_lowercase();
    if p == "gemini" || m.contains("veo") {
        return 0.18;
    }
    VIDEO_SEEDANCE_MINI_WHOLESALE_USD
}

pub fn music_tool_wholesale_usd(provider: &str, model: &str, duration_sec: i32) -> f64 {
    let p = provider.trim().to_ascii_lowercase();
    let m = model.trim().to_ascii_lowercase();
    let scale = (duration_sec.max(1) as f64 / 30.0).clamp(0.5, 4.0);
    if p == "gemini" || p == "lyria" || m.contains("lyria") {
        return MUSIC_LYRIA_CLIP_WHOLESALE_USD * scale;
    }
    if p == "minimax" || m.contains("minimax") {
        return MUSIC_MINIMAX_TRACK_WHOLESALE_USD;
    }
    MUSIC_ELEVENLABS_30S_WHOLESALE_USD * scale
}

pub fn media_regenerate_retail_usd(kind: &str, provider: &str, model: &str, quality: &str, duration_sec: i32) -> f64 {
    match kind.trim().to_ascii_lowercase().as_str() {
        "image" => image_tool_retail_usd(quality, model),
        "video" => billing_to_retail_usd(video_tool_wholesale_usd(provider, model)),
        "music" => billing_to_retail_usd(music_tool_wholesale_usd(provider, model, duration_sec)),
        _ => 0.0,
    }
}

pub fn billing_tool_cost_usd(tool_name: &str, ok: bool) -> f64 {
    if !ok {
        return 0.0;
    }
    match tool_name {
        "img.generate" | "image.generate" | "img_generate" | "img.edit" | "image.edit" | "img_edit" => {
            IMAGE_GEN_RETAIL_USD
        }
        "vid.generate" | "video.generate" | "vid_generate" => billing_to_retail_usd(VIDEO_SEEDANCE_MINI_WHOLESALE_USD),
        "music.generate" | "music_generate" => billing_to_retail_usd(MUSIC_ELEVENLABS_30S_WHOLESALE_USD),
        "captcha.solve" | "captcha_solve" => {
            billing_to_retail_usd(CAPTCHA_RECAPTCHA_V2_WHOLESALE_USD)
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
    fn embed_billing_same_on_cache_hit() {
        let model = "gemini-embedding-2@768";
        let cost = billing_embed_cost_usd(model, 100);
        assert!(cost > 0.0);
        assert_eq!(cost, billing_embed_cost_usd(model, 100));
    }

    #[test]
    fn frontier_cached_read_retail_markup() {
        let model = "gemini-2.5-flash";
        let tokens_in = 10_000;
        let cached = 8_000;
        let wholesale =
            billing_cost_wholesale_with_cache_usd(model, tokens_in, 0, cached);
        let retail = billing_cost_with_cache_usd(model, tokens_in, 0, cached);
        if wholesale > 0.0 {
            assert!((retail - wholesale * RETAIL_MARKUP).abs() < 1e-9);
            let no_cache = billing_cost_with_cache_usd(model, tokens_in, 0, 0);
            assert!(retail < no_cache);
        }
    }

    #[test]
    fn image_tool_retail_applies_markup() {
        assert!((image_tool_retail_usd("draft", "gemini-3.1-flash-lite-image") - 0.0504).abs() < 0.0001);
        assert!((image_tool_retail_usd("draft", "gemini-3.1-flash-image") - 0.1005).abs() < 0.0001);
        assert!((image_tool_retail_usd("draft", "xai/grok-imagine-image") - 0.03).abs() < 0.0001);
    }
}
