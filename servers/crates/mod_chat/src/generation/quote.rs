use c35_mod_billing::{billing_to_retail_usd, image_tool_retail_usd, music_tool_wholesale_usd, video_tool_wholesale_usd};

use crate::tools::image_tier::ImageTier;

pub fn image_retail_quote(tier: &ImageTier, provider_model: &str) -> f64 {
    image_tool_retail_usd(tier.quality, provider_model)
}

pub fn video_retail_quote(provider: &str, model: &str) -> f64 {
    billing_to_retail_usd(video_tool_wholesale_usd(provider, model))
}

pub fn music_retail_quote(provider: &str, model: &str, duration_sec: i32) -> f64 {
    billing_to_retail_usd(music_tool_wholesale_usd(provider, model, duration_sec))
}
