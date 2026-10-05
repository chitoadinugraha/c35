//! Wholesale rate card for admin / audit (retail = wholesale × RETAIL_MARKUP).

use crate::billing_cost::{
    billing_to_retail_usd, IMAGE_GEMINI_1K_WHOLESALE_USD, IMAGE_GEMINI_2K_WHOLESALE_USD,
    IMAGE_GEMINI_LITE_1K_WHOLESALE_USD, IMAGE_GROK_2_WHOLESALE_USD, IMAGE_GROK_DRAFT_WHOLESALE_USD,
    IMAGE_IMAGEN_WHOLESALE_USD, IMAGE_GEN_WHOLESALE_USD, MUSIC_ELEVENLABS_30S_WHOLESALE_USD,
    MUSIC_LYRIA_CLIP_WHOLESALE_USD, MUSIC_MINIMAX_TRACK_WHOLESALE_USD, RETAIL_MARKUP,
    VIDEO_SEEDANCE_MINI_WHOLESALE_USD, VOICE_STT_HOLD_USD, VOICE_STT_USD_PER_MIN,
    VOICE_TTS_HOLD_USD, VOICE_TTS_USD_PER_1K_CHARS,
};

#[derive(Debug, Clone)]
pub struct RateCardRow {
    pub category: String,
    pub id: String,
    pub label: String,
    pub unit: String,
    pub wholesale_usd: f64,
    pub detail: String,
}

pub fn rate_card_rows() -> Vec<RateCardRow> {
    let mut out = vec![
        RateCardRow {
            category: "voice".into(),
            id: "voice.stt".into(),
            label: "Speech-to-text (cloud)".into(),
            unit: "usd_per_min".into(),
            wholesale_usd: VOICE_STT_USD_PER_MIN / RETAIL_MARKUP,
            detail: format!("Retail ${}/min; hold ${}", VOICE_STT_USD_PER_MIN, VOICE_STT_HOLD_USD),
        },
        RateCardRow {
            category: "voice".into(),
            id: "voice.tts".into(),
            label: "Text-to-speech (cloud)".into(),
            unit: "usd_per_1k_chars".into(),
            wholesale_usd: VOICE_TTS_USD_PER_1K_CHARS / RETAIL_MARKUP,
            detail: format!("Retail ${}/1k chars; hold ${}", VOICE_TTS_USD_PER_1K_CHARS, VOICE_TTS_HOLD_USD),
        },
        RateCardRow {
            category: "image".into(),
            id: "image.gemini_flash_lite_1k".into(),
            label: "Gemini Flash-Lite image 1K".into(),
            unit: "usd_per_image".into(),
            wholesale_usd: IMAGE_GEMINI_LITE_1K_WHOLESALE_USD,
            detail: "gemini-3.1-flash-lite-image".into(),
        },
        RateCardRow {
            category: "image".into(),
            id: "image.gemini_flash_1k".into(),
            label: "Gemini Flash image 1K".into(),
            unit: "usd_per_image".into(),
            wholesale_usd: IMAGE_GEMINI_1K_WHOLESALE_USD,
            detail: "gemini-3.1-flash-image draft".into(),
        },
        RateCardRow {
            category: "image".into(),
            id: "image.gemini_flash_2k".into(),
            label: "Gemini Flash image 2K (HD)".into(),
            unit: "usd_per_image".into(),
            wholesale_usd: IMAGE_GEMINI_2K_WHOLESALE_USD,
            detail: "quality=hd".into(),
        },
        RateCardRow {
            category: "image".into(),
            id: "image.imagen".into(),
            label: "Imagen 3 flat".into(),
            unit: "usd_per_image".into(),
            wholesale_usd: IMAGE_IMAGEN_WHOLESALE_USD,
            detail: "imagen-3".into(),
        },
        RateCardRow {
            category: "image".into(),
            id: "image.grok_draft".into(),
            label: "Grok Imagine draft".into(),
            unit: "usd_per_image".into(),
            wholesale_usd: IMAGE_GROK_DRAFT_WHOLESALE_USD,
            detail: "grok-imagine-image".into(),
        },
        RateCardRow {
            category: "image".into(),
            id: "image.grok_2".into(),
            label: "Grok Imagine 2".into(),
            unit: "usd_per_image".into(),
            wholesale_usd: IMAGE_GROK_2_WHOLESALE_USD,
            detail: "grok-imagine-image-2".into(),
        },
        RateCardRow {
            category: "image".into(),
            id: "image.legacy_flat".into(),
            label: "Legacy image tool flat".into(),
            unit: "usd_per_image".into(),
            wholesale_usd: IMAGE_GEN_WHOLESALE_USD,
            detail: "img.generate fallback".into(),
        },
        RateCardRow {
            category: "video".into(),
            id: "video.seedance_mini".into(),
            label: "Seedance 2.0 mini (CF)".into(),
            unit: "usd_per_clip".into(),
            wholesale_usd: VIDEO_SEEDANCE_MINI_WHOLESALE_USD,
            detail: "vid.generate default".into(),
        },
        RateCardRow {
            category: "video".into(),
            id: "video.gemini_veo".into(),
            label: "Gemini / Veo".into(),
            unit: "usd_per_clip".into(),
            wholesale_usd: 0.18,
            detail: "provider=gemini or model contains veo".into(),
        },
        RateCardRow {
            category: "music".into(),
            id: "music.elevenlabs_30s".into(),
            label: "ElevenLabs music ~30s".into(),
            unit: "usd_per_30s".into(),
            wholesale_usd: MUSIC_ELEVENLABS_30S_WHOLESALE_USD,
            detail: "music.generate default".into(),
        },
        RateCardRow {
            category: "music".into(),
            id: "music.lyria".into(),
            label: "Gemini Lyria clip".into(),
            unit: "usd_per_clip".into(),
            wholesale_usd: MUSIC_LYRIA_CLIP_WHOLESALE_USD,
            detail: "scales with duration".into(),
        },
        RateCardRow {
            category: "music".into(),
            id: "music.minimax".into(),
            label: "MiniMax music track".into(),
            unit: "usd_per_track".into(),
            wholesale_usd: MUSIC_MINIMAX_TRACK_WHOLESALE_USD,
            detail: "minimax provider".into(),
        },
    ];
    out.sort_by(|a, b| a.category.cmp(&b.category).then(a.id.cmp(&b.id)));
    out
}

pub fn rate_card_retail_usd(wholesale: f64) -> f64 {
    billing_to_retail_usd(wholesale)
}
