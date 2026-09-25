//! Server-side image model tier routing (draft default from `image.default_tier`; 2K via @image_high or quality=hd).

pub const CONFIG_KEY_IMAGE_DEFAULT_TIER: &str = "image.default_tier";
/// Env override for draft default: `lite` (Flash-Lite 1K) or `flash` (Flash Image 1K). Wins over `ai.config`.
pub const ENV_IMAGE_DEFAULT_TIER: &str = "C35_IMAGE_DEFAULT_TIER";

pub const MODEL_FLASH_LITE: &str = "gemini-3.1-flash-lite-image";
pub const MODEL_FLASH: &str = "gemini-3.1-flash-image";
pub const MODEL_IMAGEN: &str = "imagen-3.0-generate-002";
pub const MENTION_IMAGE_HIGH: &str = "image_high";

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

pub fn image_default_draft_tier_from_str(raw: &str) -> ImageTier {
    if raw.trim().eq_ignore_ascii_case("flash") {
        image_tier_flash_draft()
    } else {
        image_tier_lite_draft()
    }
}

pub fn image_default_draft_tier_from_config(value: Option<&serde_json::Value>) -> ImageTier {
    let tier = value
        .and_then(|v| v.get("tier").and_then(|t| t.as_str()).or_else(|| v.as_str()))
        .unwrap_or("lite");
    image_default_draft_tier_from_str(tier)
}

pub async fn image_default_draft_tier(pool: &sqlx::PgPool) -> ImageTier {
    if let Ok(raw) = std::env::var(ENV_IMAGE_DEFAULT_TIER) {
        let t = raw.trim();
        if !t.is_empty() {
            return image_default_draft_tier_from_str(t);
        }
    }
    let row = c35_store::db_retry(pool, || async {
        sqlx::query_scalar::<_, serde_json::Value>("SELECT value FROM ai.config WHERE key = $1")
            .bind(CONFIG_KEY_IMAGE_DEFAULT_TIER)
            .fetch_optional(pool)
            .await
    })
    .await;
    let value = match row {
        Ok(v) => v,
        Err(_) => None,
    };
    image_default_draft_tier_from_config(value.as_ref())
}

pub fn image_tier_resolve(
    mention_ids: &[String],
    user_text: &str,
    tool_prompt: &str,
    quality_arg: &str,
    is_edit: bool,
    default_draft: &ImageTier,
) -> ImageTier {
    let q = quality_arg.trim().to_ascii_lowercase();
    if mention_image_high(mention_ids) || q == "hd" {
        return image_tier_flash_hd();
    }
    if is_edit {
        return image_tier_flash_draft();
    }
    let combined = format!("{}\n{}", user_text.trim(), tool_prompt.trim());
    if text_has_phrase(&combined, RETRY_PHRASES) {
        return image_tier_flash_draft();
    }
    default_draft.clone()
}

pub fn image_tier_retail_usd(tier: &ImageTier) -> f64 {
    c35_mod_billing::image_tool_retail_usd(tier.quality, tier.primary_model)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tier_default_follows_config_lite() {
        let lite = image_tier_lite_draft();
        let t = image_tier_resolve(&[], "buat gambar kucing lucu", "cute cat", "draft", false, &lite);
        assert_eq!(t.id, "lite_draft");
        assert_eq!(t.primary_model, MODEL_FLASH_LITE);
    }

    #[test]
    fn tier_default_follows_config_flash() {
        let flash = image_tier_flash_draft();
        let t = image_tier_resolve(&[], "buat gambar kucing lucu", "cute cat", "draft", false, &flash);
        assert_eq!(t.id, "flash_draft");
        assert_eq!(t.primary_model, MODEL_FLASH);
    }

    #[test]
    fn tier_tulisan_stays_draft_not_hd() {
        let lite = image_tier_lite_draft();
        let t = image_tier_resolve(&[], "buat gambar roti dengan tulisan gaya baru", "bread with text", "draft", false, &lite);
        assert_eq!(t.id, "lite_draft");
    }

    #[test]
    fn tier_mention_image_high_is_flash_hd() {
        let lite = image_tier_lite_draft();
        let t = image_tier_resolve(&["image_high".into()], "cat", "cat", "draft", false, &lite);
        assert_eq!(t.id, "flash_hd");
    }

    #[test]
    fn tier_logo_phrase_stays_draft_tier() {
        let lite = image_tier_lite_draft();
        let t = image_tier_resolve(&[], "buat logo toko kopi", "coffee shop logo", "draft", false, &lite);
        assert_eq!(t.id, "lite_draft");
    }

    #[test]
    fn tier_edit_uses_flash_not_lite() {
        let lite = image_tier_lite_draft();
        let t = image_tier_resolve(&[], "remove background", "remove background", "draft", true, &lite);
        assert_eq!(t.id, "flash_draft");
    }

    #[test]
    fn tier_retry_phrase_escalates_to_flash() {
        let lite = image_tier_lite_draft();
        let t = image_tier_resolve(&[], "coba lagi lebih bagus", "cat", "draft", false, &lite);
        assert_eq!(t.id, "flash_draft");
    }

    #[test]
    fn tier_default_from_config_json() {
        let v = serde_json::json!({"tier": "flash"});
        assert_eq!(image_default_draft_tier_from_config(Some(&v)).id, "flash_draft");
        assert_eq!(image_default_draft_tier_from_config(None).id, "lite_draft");
    }
}
