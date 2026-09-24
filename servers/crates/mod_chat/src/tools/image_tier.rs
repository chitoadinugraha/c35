//! Server-side image model tier routing (Lite default, Flash on explicit/high signals).

pub const MODEL_FLASH_LITE: &str = "gemini-3.1-flash-lite-image";
pub const MODEL_FLASH: &str = "gemini-3.1-flash-image";
pub const MODEL_IMAGEN: &str = "imagen-3.0-generate-002";
pub const MENTION_IMAGE_HIGH: &str = "image_high";

const HD_PHRASES: &[&str] = &[
    "logo",
    "poster",
    "banner",
    "infographic",
    "typography",
    "text in image",
    "text-in-image",
    "tulisan",
    "teks di gambar",
    "teks pada gambar",
    "4k",
    "2k",
    "high quality",
    "high-quality",
    "professional",
    "marketing",
    "thumbnail",
    "iklan",
    "cover art",
    "headline",
];

const RETRY_PHRASES: &[&str] = &[
    "try again",
    "not good",
    "better quality",
    "more detail",
    "kurang bagus",
    "jelek",
    "ulangi",
    "coba lagi",
    "still wrong",
    "higher quality",
    "doesn't look",
    "does not look",
    "not what i",
];

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ImageTier {
    pub id: &'static str,
    pub quality: &'static str,
    pub primary_model: &'static str,
    pub fallback_models: &'static [&'static str],
    pub image_size: &'static str,
}

impl ImageTier {
    pub fn models(&self) -> Vec<&'static str> {
        let mut out = vec![self.primary_model];
        for m in self.fallback_models {
            if !out.contains(m) {
                out.push(m);
            }
        }
        if !out.contains(&MODEL_IMAGEN) {
            out.push(MODEL_IMAGEN);
        }
        out
    }
}

pub fn image_tier_lite_draft() -> ImageTier {
    ImageTier {
        id: "lite_draft",
        quality: "draft",
        primary_model: MODEL_FLASH_LITE,
        fallback_models: &[MODEL_FLASH, MODEL_IMAGEN],
        image_size: "1K",
    }
}

pub fn image_tier_flash_draft() -> ImageTier {
    ImageTier {
        id: "flash_draft",
        quality: "draft",
        primary_model: MODEL_FLASH,
        fallback_models: &[MODEL_IMAGEN],
        image_size: "1K",
    }
}

pub fn image_tier_flash_hd() -> ImageTier {
    ImageTier {
        id: "flash_hd",
        quality: "hd",
        primary_model: MODEL_FLASH,
        fallback_models: &[MODEL_IMAGEN],
        image_size: "2K",
    }
}

fn text_has_phrase(hay: &str, phrases: &[&str]) -> bool {
    let lower = hay.trim().to_lowercase();
    if lower.is_empty() {
        return false;
    }
    phrases.iter().any(|p| lower.contains(&p.to_lowercase()))
}

pub fn mention_image_high(mention_ids: &[String]) -> bool {
    mention_ids.iter().any(|m| m == MENTION_IMAGE_HIGH)
}

pub fn image_tier_resolve(
    mention_ids: &[String],
    user_text: &str,
    tool_prompt: &str,
    quality_arg: &str,
    is_edit: bool,
) -> ImageTier {
    let q = quality_arg.trim().to_ascii_lowercase();
    let combined = format!("{}\n{}", user_text.trim(), tool_prompt.trim());
    let high = mention_image_high(mention_ids) || q == "hd" || text_has_phrase(&combined, HD_PHRASES);
    if high {
        return image_tier_flash_hd();
    }
    if is_edit {
        return image_tier_flash_draft();
    }
    if text_has_phrase(&combined, RETRY_PHRASES) {
        return image_tier_flash_draft();
    }
    image_tier_lite_draft()
}

pub fn image_tier_retail_usd(tier: &ImageTier) -> f64 {
    c35_mod_billing::image_tool_retail_usd(tier.quality, tier.primary_model)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tier_default_is_lite() {
        let t = image_tier_resolve(&[], "buat gambar kucing lucu", "cute cat", "draft", false);
        assert_eq!(t.id, "lite_draft");
        assert_eq!(t.primary_model, MODEL_FLASH_LITE);
    }

    #[test]
    fn tier_mention_image_high_is_flash_hd() {
        let t = image_tier_resolve(&["image_high".into()], "cat", "cat", "draft", false);
        assert_eq!(t.id, "flash_hd");
    }

    #[test]
    fn tier_logo_phrase_is_flash_hd() {
        let t = image_tier_resolve(&[], "buat logo toko kopi", "coffee shop logo", "draft", false);
        assert_eq!(t.id, "flash_hd");
    }

    #[test]
    fn tier_edit_uses_flash_not_lite() {
        let t = image_tier_resolve(&[], "remove background", "remove background", "draft", true);
        assert_eq!(t.id, "flash_draft");
    }

    #[test]
    fn tier_retry_phrase_escalates_to_flash() {
        let t = image_tier_resolve(&[], "coba lagi lebih bagus", "cat", "draft", false);
        assert_eq!(t.id, "flash_draft");
    }
}
